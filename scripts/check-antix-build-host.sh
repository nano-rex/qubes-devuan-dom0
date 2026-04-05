#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT_DIR/manifests/antix-build-host-packages.txt"

if [[ ! -f "$MANIFEST" ]]; then
    echo "antiX build host manifest missing: $MANIFEST" >&2
    exit 1
fi

missing=()
while IFS= read -r line; do
    pkg="${line%%#*}"
    pkg="${pkg//[[:space:]]/}"
    if [[ -z "$pkg" ]]; then
        continue
    fi
    status=$(dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null || true)
    if [[ "$status" != "install ok installed" ]]; then
        missing+=("$pkg")
    fi
done < "$MANIFEST"

if [[ ${#missing[@]} -eq 0 ]]; then
    echo "antiX build host package check: OK"
else
    echo "antiX build host package check: missing ${#missing[@]} package(s): ${missing[*]}" >&2
    echo "Install them with: su -c 'apt install ${missing[*]}'" >&2
    exit 1
fi
