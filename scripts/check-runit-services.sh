#!/usr/bin/env bash
set -euo pipefail

SERVICE_DIR=${SERVICE_DIR:-/etc/sv}
SERVICE_LINK_DIR=${SERVICE_LINK_DIR:-/etc/service}

services=(
  qubesd
  qubes-core
  qubes-preload-dispvm
  qubes-qrexec-policy-daemon
  qubes-meminfo-writer-dom0
  qubes-qmemman
  qubes-vm-autostart
)

missing=()
for svc in "${services[@]}"; do
  svc_dir="$SERVICE_DIR/$svc"
  svc_link="$SERVICE_LINK_DIR/$svc"
  if [[ ! -d "$svc_dir" ]]; then
    missing+=("$svc (missing $svc_dir)")
    continue
  fi
  if [[ ! -e "$svc_link" ]]; then
    missing+=("$svc (missing link $svc_link)")
  fi
  if [[ ! -x "$svc_dir/run" ]]; then
    missing+=("$svc (run script missing or not executable)")
  fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "Some runit services are missing or incomplete:" >&2
  for entry in "${missing[@]}"; do
    echo "  - $entry" >&2
  done
  exit 1
fi

echo "All dom0 runit services appear installed and linked."
