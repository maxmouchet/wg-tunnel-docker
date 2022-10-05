#!/bin/bash
set -euo pipefail

: "${WG_FWMARK:=1234}"
: "${WG_INTERFACE:=wg0}"
: "${WG_PEER_ALLOWED_IPS:=0.0.0.0/0,::0/0}"
: "${WG_TABLE:=2468}"

wireguard "${WG_INTERFACE}"

wg set "${WG_INTERFACE}" fwmark "${WG_FWMARK}"
wg set "${WG_INTERFACE}" peer "${WG_PEER_PUBLIC_KEY}" allowed-ips "${WG_PEER_ALLOWED_IPS}" endpoint "${WG_PEER_ENDPOINT}"
wg set "${WG_INTERFACE}" private-key <(echo "${WG_PRIVATE_KEY}")

for addr in ${WG_ADDR}; do
    ip addr add "${addr}" dev "${WG_INTERFACE}"
done

ip link set "${WG_INTERFACE}" up

# Route all non-local traffic through WireGuard, except for WireGuard itself.
# https://www.wireguard.com/netns/
ip route add default dev "${WG_INTERFACE}" table "${WG_TABLE}"
ip rule add not fwmark "${WG_FWMARK}" table "${WG_TABLE}"
ip rule add table main suppress_prefixlength 0

tail --pid="$(pgrep wireguard)" -f /dev/null
