#!/usr/bin/env bash
set -euo pipefail

root="${1:-/var/lib/antix-qubes}"
script_dir="$(cd "$(dirname "$0")" && pwd)"

for qube in sys-net sys-usb sys-firewall sys-whonix; do
  "$script_dir/qvm-start.sh" "$qube" "$root" || true
done
