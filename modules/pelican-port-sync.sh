#!/usr/bin/env bash
# pelican-port-sync — keep host firewall + VyOS NAT in sync with Pelican
# game-server port allocations.
#
# Reads the current allocations for this node from the Pelican panel DB
# (running in k3s), then:
#   1. Opens every allocated port (TCP+UDP) in a dedicated iptables chain
#      (jumped from nixos-fw by the NixOS module).
#   2. Pushes two grouped rules to VyOS over SSH:
#        - one `nat destination` rule (public -> this host, same port)
#        - one `firewall ipv4 name WAN_IN` allow rule (its default-action is drop)
#
# Idempotent: re-running it reconciles to the current allocation set.
# Safe to run before k3s/mysql is up — it just logs and exits 0.
#
# Usage:  pelican-port-sync [firewall-only]
set -uo pipefail

log() { echo "[pelican-port-sync] $*" >&2; }

# ── Config (all overridable via environment) ───────────────────────
NODE_ID="${NODE_ID:-7}"
NAMESPACE="${NAMESPACE:-pelican}"
MYSQL_DEPLOY="${MYSQL_DEPLOY:-pelican-mysql}"
DB_NAME="${DB_NAME:-pelican}"
IPT_CHAIN="${IPT_CHAIN:-PELICAN-PORTS}"

VYOS_ENABLE="${VYOS_ENABLE:-1}"
VYOS_HOST="${VYOS_HOST:-10.0.0.1}"
VYOS_USER="${VYOS_USER:-vyos}"
VYOS_KEY="${VYOS_KEY:-/persist/pelican/vyos/ssh_key}"
VYOS_WAN_IF="${VYOS_WAN_IF:-eth1}"
VYOS_TARGET="${VYOS_TARGET:-10.0.0.7}"
VYOS_NAT_RULE="${VYOS_NAT_RULE:-400}"
VYOS_FW_RULE="${VYOS_FW_RULE:-400}"

MODE="${1:-}"

# ── 1. Read allocations from the panel DB ──────────────────────────
sql="SELECT DISTINCT port FROM allocations WHERE node_id=${NODE_ID} AND port > 0 ORDER BY port;"
if ! raw=$(k3s kubectl -n "$NAMESPACE" exec -i "deploy/$MYSQL_DEPLOY" -- \
    sh -c "mysql -N -uroot -p\"\$MYSQL_ROOT_PASSWORD\" '${DB_NAME}'" 2>/dev/null <<<"$sql"); then
  log "cannot read allocations from ${NAMESPACE}/${MYSQL_DEPLOY} (k3s/mysql not ready?) — nothing to do"
  exit 0
fi

ports=$(printf '%s\n' "$raw" | grep -E '^[0-9]+$' | sort -un)
if [ -z "$ports" ]; then
  log "node ${NODE_ID} has no allocations; clearing firewall/NAT"
fi
mapfile -t PARRAY <<<"$ports"
portlist=$(IFS=,; echo "${PARRAY[*]}")

# ── 2. Firewall: reconcile the iptables chain ──────────────────────
if ! iptables -N "$IPT_CHAIN" 2>/dev/null; then
  iptables -F "$IPT_CHAIN"
fi

group=""
count=0
add_group() {
  [ -z "$group" ] && return
  iptables -A "$IPT_CHAIN" -p tcp -m multiport --dports "$group" -j ACCEPT
  iptables -A "$IPT_CHAIN" -p udp -m multiport --dports "$group" -j ACCEPT
}
for p in "${PARRAY[@]}"; do
  group="${group}${group:+,}${p}"
  count=$((count + 1))
  if [ "$count" -eq 15 ]; then
    add_group
    group=""
    count=0
  fi
done
add_group
log "firewall: ${#PARRAY[@]} port(s) open in chain ${IPT_CHAIN}"

# ── 3. VyOS: reconcile NAT + firewall rules ────────────────────────
if [ "$MODE" = "firewall-only" ]; then
  exit 0
fi
if [ "$VYOS_ENABLE" != "1" ]; then
  exit 0
fi
if [ ! -f "$VYOS_KEY" ]; then
  log "vyos: ssh key ${VYOS_KEY} missing — skipping NAT sync"
  exit 0
fi

# Empty port list → write an explicit drop/absent state rather than a
# malformed empty port list. Use a sentinel port of 0 so VyOS validation
# still passes while forwarding nothing real.
if [ -z "$portlist" ]; then
  portlist="0"
fi

if {
  echo "configure"
  # DNAT: public -> this host, preserving the destination port.
  echo "delete nat destination rule ${VYOS_NAT_RULE}"
  echo "set nat destination rule ${VYOS_NAT_RULE} description 'pelican-auto'"
  echo "set nat destination rule ${VYOS_NAT_RULE} destination port '${portlist}'"
  echo "set nat destination rule ${VYOS_NAT_RULE} protocol 'tcp_udp'"
  echo "set nat destination rule ${VYOS_NAT_RULE} inbound-interface name '${VYOS_WAN_IF}'"
  echo "set nat destination rule ${VYOS_NAT_RULE} translation address '${VYOS_TARGET}'"
  # WAN_IN allow (its default-action is drop).
  echo "delete firewall ipv4 name WAN_IN rule ${VYOS_FW_RULE}"
  echo "set firewall ipv4 name WAN_IN rule ${VYOS_FW_RULE} action 'accept'"
  echo "set firewall ipv4 name WAN_IN rule ${VYOS_FW_RULE} description 'pelican-auto'"
  echo "set firewall ipv4 name WAN_IN rule ${VYOS_FW_RULE} destination address '${VYOS_TARGET}'"
  echo "set firewall ipv4 name WAN_IN rule ${VYOS_FW_RULE} destination port '${portlist}'"
  echo "set firewall ipv4 name WAN_IN rule ${VYOS_FW_RULE} protocol 'tcp_udp'"
  echo "commit"
  echo "exit"
  echo "exit"
} | timeout 30 ssh -tt -i "$VYOS_KEY" \
  -o BatchMode=yes \
  -o ConnectTimeout=8 \
  -o StrictHostKeyChecking=accept-new \
  "${VYOS_USER}@${VYOS_HOST}" >/dev/null 2>&1; then
  log "vyos: synced NAT+firewall rules for ${#PARRAY[@]} port(s) (commit-only; timer re-applies after VyOS reboot)"
else
  log "vyos: SSH sync FAILED (host ${VYOS_HOST} unreachable / key rejected?)"
fi
