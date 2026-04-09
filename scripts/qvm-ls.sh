#!/usr/bin/env bash
set -euo pipefail

root="${1:-/var/lib/antix-qubes}"
script_dir="$(cd "$(dirname "$0")" && pwd)"
exec "$script_dir/aq-manager.py" --root-dir "$root" list
