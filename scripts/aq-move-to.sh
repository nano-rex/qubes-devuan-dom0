#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 || $# -gt 4 ]]; then
  cat <<'EOF' >&2
Usage:
  aq-move-to.sh <src-qube> <dst-qube> <source-relative-path> [root-dir]
EOF
  exit 1
fi

src="$1"
dst="$2"
path="$3"
root="${4:-/var/lib/antix-qubes}"
script_dir="$(cd "$(dirname "$0")" && pwd)"

"$script_dir/aq-client.py" --root-dir "$root" file-move "$src" "$dst" "$path"
