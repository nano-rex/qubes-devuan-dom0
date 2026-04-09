#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-/var/lib/antix-qubes}"
CPU_DEFAULT="${CPU_DEFAULT:-2}"
MEM_DEFAULT_MB="${MEM_DEFAULT_MB:-2048}"
RUNIT_OUT_DIR="${RUNIT_OUT_DIR:-$ROOT_DIR/runit}"
QEMU_BIN="${QEMU_BIN:-qemu-system-x86_64}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf "%s is required but not installed\n" "$1" >&2
    exit 1
  fi
}

require_command qemu-img
require_command "$QEMU_BIN"

ROOT_DIR="$(cd "$ROOT_DIR" && pwd)"
OVERLAYS_DIR="$ROOT_DIR/overlays"
RUNTIME_DIR="$ROOT_DIR/runtime"
LOG_DIR="$ROOT_DIR/log"
mkdir -p "$OVERLAYS_DIR" "$RUNIT_OUT_DIR" "$RUNTIME_DIR" "$LOG_DIR"

resolve_template_path() {
  case "$1" in
    antix-core)
      printf "%s\n" "$ROOT_DIR/isos/antiX-26_x64-core.iso"
      ;;
    whonix-gateway)
      printf "%s\n" "$ROOT_DIR/templates/Whonix-Gateway-18.1.4.2.Intel_AMD64.qcow2"
      ;;
    whonix-workstation)
      printf "%s\n" "$ROOT_DIR/templates/Whonix-Workstation-18.1.4.2.Intel_AMD64.qcow2"
      ;;
    *)
      printf "Unsupported template: %s\n" "$1" >&2
      exit 1
      ;;
  esac
}

create_overlay() {
  local qube="$1"
  local template_name="$2"
  local template_path
  local backing_format
  local overlay_path
  template_path="$(resolve_template_path "$template_name")"
  overlay_path="$OVERLAYS_DIR/$qube.qcow2"

  if [ ! -f "$template_path" ]; then
    printf "Template path not found for %s: %s\n" "$qube" "$template_path" >&2
    exit 1
  fi

  if [ -f "$overlay_path" ]; then
    printf "Overlay exists for %s: %s\n" "$qube" "$overlay_path"
  else
    if [[ "$template_path" == *.iso ]]; then
      backing_format="raw"
    else
      backing_format="qcow2"
    fi
    printf "Creating overlay for %s from %s\n" "$qube" "$template_name"
    qemu-img create -f qcow2 -F "$backing_format" -b "$template_path" "$overlay_path" >/dev/null
  fi
}

create_runit_service() {
  local qube="$1"
  local service_dir="$RUNIT_OUT_DIR/$qube"
  local overlay_path="$OVERLAYS_DIR/$qube.qcow2"
  local monitor_sock="$RUNTIME_DIR/$qube.monitor.sock"
  local serial_sock="$RUNTIME_DIR/$qube.serial.sock"

  mkdir -p "$service_dir/log"
  cat <<EOF >"$service_dir/run"
#!/usr/bin/env bash
set -euo pipefail
exec $QEMU_BIN \\
  -name $qube \\
  -machine accel=kvm \\
  -cpu host \\
  -smp $CPU_DEFAULT \\
  -m $MEM_DEFAULT_MB \\
  -drive file=$overlay_path,if=virtio,format=qcow2 \\
  -monitor unix:$monitor_sock,server,nowait \\
  -serial unix:$serial_sock,server,nowait \\
  -nographic
EOF

  cat <<'EOF' >"$service_dir/log/run"
#!/usr/bin/env bash
exec svlogd -tt ./main
EOF

  chmod +x "$service_dir/run" "$service_dir/log/run"
}

SERVICE_QUBES=(
  "sys-net:antix-core"
  "sys-usb:antix-core"
  "sys-firewall:antix-core"
  "sys-whonix:whonix-gateway"
)

for entry in "${SERVICE_QUBES[@]}"; do
  qube="${entry%%:*}"
  template="${entry##*:}"
  create_overlay "$qube" "$template"
  create_runit_service "$qube"
done

cat <<EOF
Provisioned overlays and runit service stubs:
  root: $ROOT_DIR
  overlays: $OVERLAYS_DIR
  runit services: $RUNIT_OUT_DIR
EOF
