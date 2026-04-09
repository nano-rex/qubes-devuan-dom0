#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  cat <<'EOF' >&2
Usage:
  aq-clip-copy.sh <src-qube> [root-dir]
EOF
  exit 1
fi

src="$1"
root="${2:-/var/lib/antix-qubes}"
script_dir="$(cd "$(dirname "$0")" && pwd)"

"$script_dir/aq-client.py" --root-dir "$root" clip-copy "$src"
