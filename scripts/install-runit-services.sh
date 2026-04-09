#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  printf "Run as root.\n" >&2
  exit 1
fi

ROOT_DIR="${1:-/var/lib/antix-qubes}"
SRC_DIR="${2:-$ROOT_DIR/runit}"
DEST_DIR="${3:-/etc/service}"

if [[ ! -d "$SRC_DIR" ]]; then
  printf "Missing runit source dir: %s\n" "$SRC_DIR" >&2
  exit 1
fi

mkdir -p "$DEST_DIR"

for svc in "$SRC_DIR"/*; do
  [[ -d "$svc" ]] || continue
  name="$(basename "$svc")"
  link="$DEST_DIR/$name"
  if [[ -L "$link" || -e "$link" ]]; then
    printf "Skipping existing %s\n" "$link"
    continue
  fi
  ln -s "$svc" "$link"
  printf "Linked %s -> %s\n" "$link" "$svc"
done
