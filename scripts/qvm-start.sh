#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: qvm-start.sh <qube> [root-dir]" >&2
  exit 1
fi

qube="$1"
root="${2:-/var/lib/antix-qubes}"
script_dir="$(cd "$(dirname "$0")" && pwd)"
exec "$script_dir/aq-manager.py" --root-dir "$root" start "$qube"
