#!/usr/bin/env bash
set -euo pipefail

if [[ ${SKIP_DOAS_CONFIG_CHECK:-} == "1" ]]; then
    echo "Skipping doas config check (SKIP_DOAS_CONFIG_CHECK=1)"
    exit 0
fi

CONFIG_PATH="${DOAS_CONF:-/etc/doas.conf}"

if [[ ! -r "$CONFIG_PATH" ]]; then
    echo "doas configuration file not found or not readable: $CONFIG_PATH" >&2
    echo "Create one from configs/doas.conf.sample or point DOAS_CONF to your file." >&2
    exit 1
fi

missing=()
check_line() {
    local pattern=$1
    if ! grep -Eq "$pattern" "$CONFIG_PATH"; then
        missing+=("$pattern")
    fi
}

check_line '^[[:space:]]*permit[[:space:]]+persist[[:space:]]+keepenv[[:space:]]+root\b'
check_line '^[[:space:]]*permit[[:space:]]+persist[[:space:]]+keepenv[[:space:]]+:wheel\b'

if [[ ${#missing[@]} -gt 0 ]]; then
    echo "doas configuration at $CONFIG_PATH is missing recommended entries:" >&2
    for pattern in "${missing[@]}"; do
        echo "  - $pattern" >&2
    done
    echo "Refer to configs/doas.conf.sample for an example setup that allows root and wheel escalations." >&2
    echo "Set SKIP_DOAS_CONFIG_CHECK=1 to bypass if you intentionally diverge (not recommended)." >&2
    exit 1
fi
