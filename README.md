# wg-tunnel-docker

[![Docker Status](https://img.shields.io/github/workflow/status/maxmouchet/wg-tunnel-docker/Docker?logo=github&label=docker)](https://github.com/maxmouchet/wg-tunnel-docker/actions/workflows/docker.yml)

A Docker container to route other containers traffic to a WireGuard tunnel.
It uses the [wireguard-go](https://github.com/WireGuard/wireguard-go) userspace implementation so that it can easily be run on Synology DSM or other platforms where kernel modules are not readily available.

## Example

```yml
# docker-compose.yml
services:
  vpn:
    image: ghcr.io/maxmouchet/wg-tunnel-docker:main
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun
    environment:
      # Whitespace-delimited list of IP addresses.
      WG_ADDR: "1.2.3.4/32 dead::beef/128"
      WG_PEER_ENDPOINT: 10.20.30.40:51820
      WG_PEER_PUBLIC_KEY: ...
      WG_PRIVATE_KEY: ...
    sysctls:
      net.ipv6.conf.all.disable_ipv6: 0

  # Example container that will share the same network namespace as the VPN container.
  transmission:
    image: lscr.io/linuxserver/transmission:latest
    network_mode: service:vpn
```
