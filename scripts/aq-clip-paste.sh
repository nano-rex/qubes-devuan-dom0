#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  cat <<'EOF' >&2
Usage:
  aq-clip-paste.sh <dst-qube> <token> [root-dir]
EOF
  exit 1
fi

dst="$1"
token="$2"
root="${3:-/var/lib/antix-qubes}"
script_dir="$(cd "$(dirname "$0")" && pwd)"

"$script_dir/aq-client.py" --root-dir "$root" clip-paste "$dst" --token "$token"
