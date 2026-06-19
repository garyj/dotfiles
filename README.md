# Dotfiles

My personal dotfiles, managed with [chezmoi](https://www.chezmoi.io/).

## Notes

### Docker `default-address-pools` (keep Docker off the LAN)

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

## Inspiration

- <https://github.com/jefftriplett/dotfiles>
- <https://github.com/twpayne/dotfiles>
