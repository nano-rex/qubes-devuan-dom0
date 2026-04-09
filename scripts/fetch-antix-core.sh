#!/usr/bin/env bash
set -euo pipefail

ISO_URL="https://downloads.sourceforge.net/project/antix-linux/Final/antiX-26/antiX-26_x64-core.iso"
SHA256="de0dc55dea576c897eba345a0a0f1d8695fc1c4db5990b46efebe08bfbce9e22"
TARGET_DIR="${1:-isos}"
ISO_NAME="${ISO_URL##*/}"
TARGET_PATH="$TARGET_DIR/$ISO_NAME"
TMP_PATH="$TARGET_PATH.part"

mkdir -p "$TARGET_DIR"

if [ -f "$TARGET_PATH" ]; then
  echo "Found existing $ISO_NAME; skipping download."
else
  echo "Downloading antiX core from $ISO_URL"
  curl -L --progress-bar -o "$TMP_PATH" "$ISO_URL"
  mv "$TMP_PATH" "$TARGET_PATH"
fi

printf "%s  %s\n" "$SHA256" "$TARGET_PATH" | sha256sum --check -
