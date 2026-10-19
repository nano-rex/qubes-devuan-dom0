#!/bin/sh
set -euo pipefail

ROOT_DIR="${1:-/var/lib/antix-qubes}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ANTIX_FETCH_SCRIPT="$SCRIPT_DIR/fetch-antix-core.sh"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf "%s is required but not installed\\n" "$1" >&2
    exit 1
  fi
}

require_command curl
require_command sha512sum
require_command xz
require_command qemu-img
require_command qemu-system-x86_64

mkdir -p "$ROOT_DIR"
ROOT_DIR="$(cd "$ROOT_DIR" && pwd)"
ISO_DIR="$ROOT_DIR/isos"
WHONIX_ISO_DIR="$ISO_DIR/whonix"
TEMPLATES_DIR="$ROOT_DIR/templates"
OVERLAYS_DIR="$ROOT_DIR/overlays"
METADATA_DIR="$ROOT_DIR/metadata"
LOG_DIR="$ROOT_DIR/log"
mkdir -p "$ISO_DIR" "$WHONIX_ISO_DIR" "$TEMPLATES_DIR" "$OVERLAYS_DIR" "$METADATA_DIR" "$LOG_DIR"

printf "Initializing antiX/QEMU workspace under %s\\n" "$ROOT_DIR"

# Step 1: fetch antiX core ISO
"$ANTIX_FETCH_SCRIPT" "$ISO_DIR"
ANTIX_ISO="$ISO_DIR/antiX-26_x64-core.iso"
if [ ! -f "$ANTIX_ISO" ]; then
  printf "antiX ISO is missing after fetch script\\n" >&2
  exit 1
fi

# Step 2: download Whonix templates
WHONIX_BASE_URL="https://download.whonix.org/libvirt/18.1.4.2"
WHONIX_FILES="Whonix-Gateway-18.1.4.2.Intel_AMD64.qcow2.libvirt.xz Whonix-Workstation-18.1.4.2.Intel_AMD64.qcow2.libvirt.xz"
for FILE in $WHONIX_FILES; do
  DEST="$WHONIX_ISO_DIR/$FILE"
  if [ -f "$DEST" ]; then
    printf "Skipping existing %s\\n" "$FILE"
  else
    printf "Downloading %s\\n" "$FILE"
    curl -L --progress-bar -o "$DEST" "$WHONIX_BASE_URL/$FILE"
  fi
  UNZIPPED="${DEST%.xz}"
  if [ ! -f "$UNZIPPED" ]; then
    printf "Decompressing %s\\n" "$FILE"
    xz -dk "$DEST"
  fi
  FINAL_TEMPLATE="$(basename "${UNZIPPED%.libvirt}")"
  FINAL_TEMPLATE_PATH="$TEMPLATES_DIR/$FINAL_TEMPLATE.qcow2"
  if [ ! -f "$FINAL_TEMPLATE_PATH" ]; then
    mv "$UNZIPPED" "$FINAL_TEMPLATE_PATH"
  else
    printf "Template already exists at %s\\n" "$FINAL_TEMPLATE_PATH"
  fi
done

# Step 3: verify Whonix checksums
SHA_URL="$WHONIX_BASE_URL/Whonix-18.1.4.2.sha512sums"
SHA_FILE="$WHONIX_ISO_DIR/Whonix-18.1.4.2.sha512sums"
printf "Downloading Whonix sha512sums\\n"
curl -L --progress-bar -o "$SHA_FILE" "$SHA_URL"
cd "$WHONIX_ISO_DIR"
if ! sha512sum --strict --check "$(basename "$SHA_FILE")" --ignore-missing; then
  printf "Whonix checksum verification failed\\n" >&2
  exit 1
fi
cd - >/dev/null

# Step 4: record metadata
cat <<JSON >"$METADATA_DIR/templates.json"
{
  "templates": [
    {
      "name": "antix-core",
      "source": "isos/antiX-26_x64-core.iso",
      "type": "antiX",
      "description": "Host/template base that boots runit and qemu"
    },
    {
      "name": "whonix-gateway",
      "source": "templates/Whonix-Gateway-18.1.4.2.Intel_AMD64.qcow2",
      "type": "whonix-kvm",
      "description": "Gateway template for sys-whonix network domain"
    },
    {
      "name": "whonix-workstation",
      "source": "templates/Whonix-Workstation-18.1.4.2.Intel_AMD64.qcow2",
      "type": "whonix-kvm",
      "description": "Workstation template used for disposable whonix qubes"
    }
  ]
}
JSON

cat <<JSON >"$METADATA_DIR/service-qubes.json"
{
  "service_qubes": [
    {"name": "sys-net", "template": "antix-core", "role": "network bridge"},
    {"name": "sys-usb", "template": "antix-core", "role": "usb proxy"},
    {"name": "sys-firewall", "template": "antix-core", "role": "firewall"},
    {"name": "sys-whonix", "template": "whonix-gateway", "role": "whonix gateway (netvm)"}
  ]
}
JSON

printf "Quiescent metadata recorded to %s\\n" "$METADATA_DIR"

cat <<EOF >"$LOG_DIR/setup.log"
$(date -u +"%Y-%m-%dT%H:%M:%SZ") setup completed under $ROOT_DIR
EOF

echo "Bootstrap complete. Templates and service qubes are staged at $ROOT_DIR."
