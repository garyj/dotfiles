# Gotchas

Hard-won findings about this machine and its tooling: things that cost real
time to work out and would cost it again.

## Docker `default-address-pools` (keep Docker off the LAN)

Docker's built-in default address pool ends with `192.168.0.0/16` (in `/20`
blocks), so once the `172.x` ranges fill up, new bridge networks spill into
`192.168` space. On a LAN that uses `192.168.x` — especially with a router VPN
to a remote subnet — a Docker `/20` can shadow the route and silently black-hole
traffic (e.g. a VPN at `192.168.20.0/24` swallowed by a bridge's `192.168.16.0/20`).

Fix in `/etc/docker/daemon.json` — fence Docker into `172.16/12` + a `10.x`
range, and use `/24` blocks so projects don't burn a `/20` each:

```json
{
  "default-address-pools": [
    { "base": "172.16.0.0/12", "size": 24 },
    { "base": "10.99.0.0/16",  "size": 24 }
  ]
}
```

`sudo systemctl restart docker`, then `docker network prune` to drop the old
`192.168` networks (compose recreates them from the new pool on next `up`).
Docs: [dockerd reference](https://docs.docker.com/reference/cli/dockerd/) ·
[networking overview](https://docs.docker.com/engine/network/).

## Ghostty launch latency (resident instance)

Super+Return runs `ghostty +new-window` against a resident daemon
(`app-com.mitchellh.ghostty.service`), so a slow launch is the daemon failing to
service a D-Bus request, not a cold start. Two distinct causes have turned up.
They look identical from the outside and are told apart only by sampling the
daemon while it stalls.

**Swap (fixed).** Nothing touches the daemon between keypresses, so under memory
pressure the kernel reads it as cold and pages it out. The next keypress then
blocks faulting its own heap back off the encrypted swapfile: worst case 14.2s,
88% of it in `D` state on `folio_wait_bit_common` at 4.5% CPU. Fixed with
`MemorySwapMax=0` in `home/private_dot_config/systemd/user/`. Confirm `VmSwap`
in `/proc/<pid>/status` is 0 before investigating anything else.

**GTK4 server grabs (fixed).** The remaining stall was deterministic once the
swap fix landed: 3.0s per window on kernel 7.0.0-31, 173 `XGrabServer` calls
at ~17ms each. GTK 4.14's X11 backend grabs the server for every
`tooltip-text` set (`gtk_widget_set_tooltip_text` ->
`gtk_widget_trigger_tooltip_query` -> `gdk_device_get_surface_at_position`),
which ghostty's window build does ~173 times and every title change does
twice, and on this NVIDIA setup each grab waits one 60Hz frame while the whole
X server stalls. Per-grab cost tracks the kernel (3ms on -28, 15.5 on -29, 6.5
on -30, 17 on -31), and AllowFlipping does not move it. No ghostty option
avoids the grabs; window-decoration, tab and toolbar settings all leave 173.
Fixed by preloading `~/.local/lib/ghostty/nograb.so` into the daemon (source in
`home/dot_local/lib/ghostty/`, built by `run_onchange_after_build-ghostty-nograb`,
wired by the `nograb.conf` drop-in): `XGrabServer` becomes a no-op, launches
drop to 0.4-0.6s cold, and the per-title-change server stalls go away. The shim
strips `LD_PRELOAD` from its own environment so terminals do not inherit it.
The grab only makes a tooltip pointer query atomic; nothing visible depends on
it. Verify with `gdb -batch -ex 'break XGrabServer'` on an isolated instance
(`--gtk-single-instance=false`), which is traceable where the daemon is not.

`kernel.yama.ptrace_scope=1` means **strace cannot attach to the daemon**. It is
not a descendant of your shell, and the failure is silent: a 0-byte output file
that reads like a clean negative result. Sample `/proc/<pid>/` instead, where
`stat` carries state and `majflt`, and `status` carries `VmSwap` and
`voluntary_ctxt_switches`. The `ghostty +new-window` client is traceable, being
a child of whatever invoked it.

Ignore `procs_blocked` in `/proc/stat`; it reads 40 to 55 on this box while a
full scan finds one or two genuine `D`-state tasks. PSI (`/proc/pressure/io`)
does reflect real swap traffic and is worth reading.

A wrapper that times every keypress and dumps `/proc` samples on any launch over
a second is archived on the `chore/ghostty-latency-probe` branch, with the
captures behind the numbers above. Restore it rather than rewriting it:

```bash
git checkout chore/ghostty-latency-probe -- \
  home/bin/executable_ghostty-new-window \
  home/bin/executable_ghostty-launch-report
```

Remove it again afterwards; it costs about 39ms on every keypress. Editing the
Super+Return binding needs a `custom-list` toggle to take effect, or Cinnamon
silently keeps running the old command.
