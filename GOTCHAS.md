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

**Main loop parked (open).** Remaining 1 to 2s stalls show the opposite
signature: no major faults, no swap, ample free memory, and
`voluntary_ctxt_switches` frozen for the whole stall, meaning the GTK main loop
sleeps in `poll()` and is never woken, then serves the request in milliseconds.

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
