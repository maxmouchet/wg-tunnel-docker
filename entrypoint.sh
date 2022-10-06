#!/bin/bash
set -euo pipefail

: "${EXCLUDED_NETWORK_V4:=172.16.0.0/12}"
: "${EXCLUDED_NETWORK_V6:=}"
: "${IPTABLES:=iptables-legacy}"
: "${IP6TABLES:=ip6tables-legacy}"
: "${WG_FWMARK:=1234}"
: "${WG_INTERFACE:=wg0}"
: "${WG_PEER_ALLOWED_IPS:=0.0.0.0/0,::0/0}"
: "${WG_TABLE:=2468}"

# Block non-local and non-wireguard as early as possible to prevent leaks.
# Drop everything by default.
${IPTABLES}  --policy OUTPUT DROP
${IP6TABLES} --policy OUTPUT DROP

# Allow traffic going towards an IP address assigned to this host (e.g. 127.0.0.1, ::1).
${IPTABLES}  --append OUTPUT --match addrtype --dst-type LOCAL --jump ACCEPT
${IP6TABLES} --append OUTPUT --match addrtype --dst-type LOCAL --jump ACCEPT

# Allow encrypted WireGuard traffic.
${IPTABLES}  --append OUTPUT --match mark --mark "${WG_FWMARK}" --jump ACCEPT
${IP6TABLES} --append OUTPUT --match mark --mark "${WG_FWMARK}" --jump ACCEPT

# Allow traffic going through the WireGuard interface.
${IPTABLES}  --append OUTPUT --out-interface "${WG_INTERFACE}" --jump ACCEPT
${IP6TABLES} --append OUTPUT --out-interface "${WG_INTERFACE}" --jump ACCEPT

# Allow traffic towards Docker internal networks, or any custom networks.
for network in ${EXCLUDED_NETWORK_V4}; do
    ${IPTABLES} --append OUTPUT --dst "${network}" --jump ACCEPT
done
for network in ${EXCLUDED_NETWORK_V6}; do
    ${IP6TABLES} --append OUTPUT --dst "${network}" --jump ACCEPT
done

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
