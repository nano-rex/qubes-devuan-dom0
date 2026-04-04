#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILDER_DIR="$ROOT_DIR/upstream/qubes-builderv2"
CONFIG_FILE="${QUBES_DEVUAN_CONFIG:-$ROOT_DIR/configs/devuan-dom0-runit.yml}"
CLI="$BUILDER_DIR/qubesbuilder-cli"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Missing builder config: $CONFIG_FILE" >&2
    exit 1
fi

if [[ ! -x "$CLI" ]]; then
    echo "Missing builder CLI: $CLI" >&2
    exit 1
fi

missing=()
for cmd in python3 sudo pbuilder; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        missing+=("$cmd")
    fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Missing required host commands: ${missing[*]}" >&2
    echo "See docs/build-devuan-dom0.md for the expected bootstrap environment." >&2
    exit 1
fi

if [[ ! -f /usr/share/keyrings/devuan-archive-keyring.gpg ]]; then
    echo "Missing /usr/share/keyrings/devuan-archive-keyring.gpg" >&2
    echo "The Devuan builder config expects a real Devuan archive keyring on the host." >&2
    echo "Set QUBES_DEVUAN_CONFIG to an alternate config if you need a different keyring path." >&2
    exit 1
fi

export PYTHONPATH="$BUILDER_DIR${PYTHONPATH:+:$PYTHONPATH}"

cd "$BUILDER_DIR"
exec ./qubesbuilder-cli --builder-conf "$CONFIG_FILE" "$@"
