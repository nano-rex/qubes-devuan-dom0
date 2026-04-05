#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILDER_DIR="$ROOT_DIR/upstream/qubes-builderv2"
TOOLS_DIR="$ROOT_DIR/tools"
PATH="$TOOLS_DIR:$PATH"
export PATH
CONFIG_FILE="${QUBES_DEVUAN_CONFIG:-$ROOT_DIR/configs/devuan-dom0-runit.yml}"
CLI="$BUILDER_DIR/qubesbuilder-cli"

if [[ $# -ge 1 && "$1" == "installer" ]]; then
    "$ROOT_DIR/scripts/check-doas.sh"
    "$ROOT_DIR/scripts/check-doas-config.sh"
fi

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

sudo_output=""
if ! sudo_output="$(sudo -n true 2>&1)"; then
    first_line="${sudo_output%%$'\n'*}"
    if [[ -z "$first_line" ]]; then
        first_line="<no output>"
    fi
    echo "Unable to run sudo: $first_line" >&2
    if [[ "$sudo_output" == *"no new privileges"* ]]; then
        echo "The build host is using the 'no new privileges' flag, so sudo cannot elevate to root." >&2
        echo "Run the builder on a host that allows sudo (or doas) to execute commands as root." >&2
    elif [[ "$sudo_output" == *"password is required"* ]] || [[ "$sudo_output" == *"Authentication is required"* ]] || [[ "$sudo_output" == *"a password is required"* ]]; then
        echo "Configure passwordless sudo (or install doas) so the builder can create pbuilder chroots without interactive prompts." >&2
    fi
    exit 1
fi

if [[ ! -f /usr/share/keyrings/devuan-archive-keyring.gpg ]]; then
    echo "Missing /usr/share/keyrings/devuan-archive-keyring.gpg" >&2
    echo "The Devuan builder config expects a real Devuan archive keyring on the host." >&2
    echo "Set QUBES_DEVUAN_CONFIG to an alternate config if you need a different keyring path." >&2
    exit 1
fi

PYTHONPATH="$BUILDER_DIR${PYTHONPATH:+:$PYTHONPATH}"
export PYTHONPATH
export QUBES_SERVICE_MANAGER=${QUBES_SERVICE_MANAGER:-runit}

cd "$BUILDER_DIR"
exec ./qubesbuilder-cli --builder-conf "$CONFIG_FILE" "$@"
