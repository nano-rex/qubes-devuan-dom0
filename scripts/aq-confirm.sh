#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "deny"
  exit 1
fi

action="$1"
src="$2"
dst="$3"

printf "Allow action %s from %s to %s? [y/N]: " "$action" "$src" "$dst" >&2
read -r answer
case "${answer,,}" in
  y|yes)
    echo "allow"
    exit 0
    ;;
  *)
    echo "deny"
    exit 1
    ;;
esac
