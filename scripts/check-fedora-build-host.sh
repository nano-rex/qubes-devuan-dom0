#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_FILE="$ROOT_DIR/manifests/fedora-build-host-packages.txt"

if [[ ! -f "$PACKAGE_FILE" ]]; then
    echo "Missing package manifest: $PACKAGE_FILE" >&2
    exit 1
fi

if ! command -v rpm >/dev/null 2>&1; then
    echo "This checker expects an rpm-based host." >&2
    exit 1
fi

missing=()
while IFS= read -r package; do
    [[ -z "$package" ]] && continue
    if ! rpm -q "$package" >/dev/null 2>&1; then
        missing+=("$package")
    fi
done < "$PACKAGE_FILE"

if [[ ${#missing[@]} -eq 0 ]]; then
    echo "Fedora host package check: OK"
    exit 0
fi

echo "Fedora host package check: missing ${#missing[@]} package(s)"
for package in "${missing[@]}"; do
    echo " - $package"
done
echo
echo "Install them with:"
echo "sudo dnf install $(tr '\n' ' ' < "$PACKAGE_FILE")"
