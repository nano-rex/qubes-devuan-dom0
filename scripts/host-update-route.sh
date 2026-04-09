#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  host-update-route.sh on firewall|whonix
  host-update-route.sh off
  host-update-route.sh status
EOF
}

if [[ "${1:-}" == "" ]]; then
  usage
  exit 1
fi

ACTION="$1"
TARGET="${2:-}"
CONFIG_FILE="${UPDATE_ROUTE_CONFIG:-/etc/antix-qubes/host-update-route.env}"
if [[ ! -f "$CONFIG_FILE" ]]; then
  CONFIG_FILE="$(cd "$(dirname "$0")/.." && pwd)/configs/host-update-route.env.sample"
fi

# shellcheck disable=SC1090
source "$CONFIG_FILE"

ROUTE_TABLE_ID="${ROUTE_TABLE_ID:-300}"
RULE_PRIORITY="${RULE_PRIORITY:-300}"
MARK_HEX="${MARK_HEX:-0x51}"
APT_ONLY="${APT_ONLY:-1}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf "%s is required but not installed\n" "$1" >&2
    exit 1
  fi
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    printf "Run as root.\n" >&2
    exit 1
  fi
}

require_command ip
require_command iptables

get_gateway_vars() {
  case "$1" in
    firewall)
      GW_IP="${FIREWALL_GATEWAY_IP:-}"
      GW_DEV="${FIREWALL_GATEWAY_DEV:-}"
      ;;
    whonix)
      GW_IP="${WHONIX_GATEWAY_IP:-}"
      GW_DEV="${WHONIX_GATEWAY_DEV:-}"
      ;;
    *)
      printf "Unknown target: %s\n" "$1" >&2
      exit 1
      ;;
  esac
  if [[ -z "${GW_IP}" || -z "${GW_DEV}" ]]; then
    printf "Missing gateway config for target %s in %s\n" "$1" "$CONFIG_FILE" >&2
    exit 1
  fi
}

delete_mark_rule() {
  if [[ "${APT_ONLY}" == "1" ]]; then
    iptables -t mangle -D OUTPUT -m owner --uid-owner _apt -p tcp -m multiport --dports 80,443 -j MARK --set-mark "${MARK_HEX}" 2>/dev/null || true
  else
    iptables -t mangle -D OUTPUT -p tcp -m multiport --dports 80,443 -j MARK --set-mark "${MARK_HEX}" 2>/dev/null || true
  fi
}

add_mark_rule() {
  if [[ "${APT_ONLY}" == "1" ]]; then
    if ! id _apt >/dev/null 2>&1; then
      printf "APT_ONLY=1 but user _apt not found.\n" >&2
      exit 1
    fi
    iptables -t mangle -C OUTPUT -m owner --uid-owner _apt -p tcp -m multiport --dports 80,443 -j MARK --set-mark "${MARK_HEX}" 2>/dev/null ||
      iptables -t mangle -A OUTPUT -m owner --uid-owner _apt -p tcp -m multiport --dports 80,443 -j MARK --set-mark "${MARK_HEX}"
  else
    iptables -t mangle -C OUTPUT -p tcp -m multiport --dports 80,443 -j MARK --set-mark "${MARK_HEX}" 2>/dev/null ||
      iptables -t mangle -A OUTPUT -p tcp -m multiport --dports 80,443 -j MARK --set-mark "${MARK_HEX}"
  fi
}

set_route() {
  get_gateway_vars "$1"
  ip route replace default via "${GW_IP}" dev "${GW_DEV}" table "${ROUTE_TABLE_ID}"
  ip rule add fwmark "${MARK_HEX}" priority "${RULE_PRIORITY}" table "${ROUTE_TABLE_ID}" 2>/dev/null || true
  add_mark_rule
}

clear_route() {
  delete_mark_rule
  while ip rule show | grep -q "fwmark ${MARK_HEX}.*lookup ${ROUTE_TABLE_ID}"; do
    ip rule del fwmark "${MARK_HEX}" priority "${RULE_PRIORITY}" table "${ROUTE_TABLE_ID}" 2>/dev/null || true
    ip rule del fwmark "${MARK_HEX}" table "${ROUTE_TABLE_ID}" 2>/dev/null || true
  done
  ip route flush table "${ROUTE_TABLE_ID}" || true
}

status_route() {
  printf "Config: %s\n" "$CONFIG_FILE"
  printf "Rule(s):\n"
  ip rule show | grep "fwmark ${MARK_HEX}" || true
  printf "Table %s:\n" "$ROUTE_TABLE_ID"
  ip route show table "${ROUTE_TABLE_ID}" || true
  printf "Mangle OUTPUT rule(s):\n"
  iptables -t mangle -S OUTPUT | grep "MARK --set-xmark ${MARK_HEX}" || iptables -t mangle -S OUTPUT | grep "MARK --set-mark ${MARK_HEX}" || true
}

case "$ACTION" in
  on)
    if [[ -z "$TARGET" ]]; then
      usage
      exit 1
    fi
    require_root
    clear_route
    set_route "$TARGET"
    printf "Enabled host update routing via %s\n" "$TARGET"
    ;;
  off)
    require_root
    clear_route
    printf "Disabled host update routing\n"
    ;;
  status)
    require_root
    status_route
    ;;
  *)
    usage
    exit 1
    ;;
esac
