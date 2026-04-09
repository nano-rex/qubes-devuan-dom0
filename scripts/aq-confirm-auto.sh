#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
gui="$script_dir/aq-confirm-gui.py"
tty_confirm="$script_dir/aq-confirm.sh"

if [[ -n "${DISPLAY:-}" ]] && command -v python3 >/dev/null 2>&1; then
  exec "$gui" "$@"
fi

exec "$tty_confirm" "$@"
