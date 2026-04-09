#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root." >&2
  exit 1
fi

APT_PACKAGES=(
  curl
  xz-utils
  coreutils
  qemu-system-x86
  qemu-utils
  python3
  python3-tk
  iptables
  iproute2
  runit
)

PACMAN_PACKAGES=(
  curl
  xz
  coreutils
  qemu-base
  python
  tk
  iptables
  iproute2
  runit
)

install_apt() {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y "${APT_PACKAGES[@]}"
}

install_pacman() {
  pacman -Sy --noconfirm --needed "${PACMAN_PACKAGES[@]}"
}

if command -v apt-get >/dev/null 2>&1; then
  install_apt
elif command -v pacman >/dev/null 2>&1; then
  install_pacman
else
  echo "Unsupported distro: neither apt-get nor pacman found." >&2
  exit 1
fi

echo "Dependency installation complete."
