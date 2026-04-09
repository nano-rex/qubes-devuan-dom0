#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  cat <<'EOF'
Usage:
  host-update-via.sh firewall|whonix <command...>

Example:
  host-update-via.sh firewall apt update
EOF
  exit 1
fi

TARGET="$1"
shift

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROUTE_SCRIPT="$SCRIPT_DIR/host-update-route.sh"

if [[ ! -x "$ROUTE_SCRIPT" ]]; then
  printf "Missing executable route script: %s\n" "$ROUTE_SCRIPT" >&2
  exit 1
fi

cleanup() {
  "$ROUTE_SCRIPT" off || true
}
trap cleanup EXIT INT TERM

"$ROUTE_SCRIPT" on "$TARGET"
"$@"
