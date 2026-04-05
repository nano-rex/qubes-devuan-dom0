#!/usr/bin/env bash
set -euo pipefail

check_doas() {
    if ! command -v doas >/dev/null 2>&1; then
        echo "doas binary not found in PATH." >&2
        return 1
    fi

    doas_bin="$(command -v doas)"
    mode="$(stat -c "%a" "$doas_bin")"
    owner="$(stat -c "%u" "$doas_bin")"

    # require setuid bit (4xxx) and owned by root (uid 0)
    case "$mode" in
    4*|5*|6*|7*)
        ;;
    *)
        echo "doas at $doas_bin is not setuid (mode $mode)." >&2
        return 1
        ;;
    esac

    if [ "$owner" -ne 0 ]; then
        echo "doas at $doas_bin is not owned by root (uid $owner)." >&2
        return 1
    fi
    return 0
}

if ! check_doas; then
    echo "Please install doas and mark it setuid-root." >&2
    echo "  sudo chown root:root /usr/bin/doas" >&2
    echo "  sudo chmod 4755 /usr/bin/doas" >&2
    exit 1
fi
