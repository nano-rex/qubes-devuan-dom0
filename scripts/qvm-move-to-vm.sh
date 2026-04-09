#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 || $# -gt 4 ]]; then
  echo "Usage: qvm-move-to-vm.sh <src> <dst> <path> [root-dir]" >&2
  exit 1
fi

src="$1"
dst="$2"
path="$3"
root="${4:-/var/lib/antix-qubes}"
script_dir="$(cd "$(dirname "$0")" && pwd)"
exec "$script_dir/aq-manager.py" --root-dir "$root" move-to "$src" "$dst" "$path"
