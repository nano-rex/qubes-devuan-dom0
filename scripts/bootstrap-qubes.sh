#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-/var/lib/antix-qubes}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ANTIX_FETCH_SCRIPT="$SCRIPT_DIR/fetch-antix-core.sh"
INSTALL_DEPS="${INSTALL_DEPS:-1}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf "%s is required but not installed\n" "$1" >&2
    exit 1
  fi
}

if [[ "$INSTALL_DEPS" == "1" ]]; then
  if [[ "${EUID}" -ne 0 ]]; then
    printf "INSTALL_DEPS=1 but current user is not root; skipping dependency install.\n"
  else
    "$SCRIPT_DIR/install-host-deps.sh"
  fi
fi

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

printf "Initializing antiX/QEMU workspace under %s\n" "$ROOT_DIR"

# Step 1: fetch antiX core ISO
"$ANTIX_FETCH_SCRIPT" "$ISO_DIR"
ANTIX_ISO="$ISO_DIR/antiX-26_x64-core.iso"
if [ ! -f "$ANTIX_ISO" ]; then
  printf "antiX ISO is missing after fetch script\n" >&2
  exit 1
fi

# Step 2: download Whonix templates
WHONIX_BASE_URL="https://download.whonix.org/libvirt/18.1.4.2"
WHONIX_FILES=(
  "Whonix-Gateway-18.1.4.2.Intel_AMD64.qcow2.libvirt.xz"
  "Whonix-Workstation-18.1.4.2.Intel_AMD64.qcow2.libvirt.xz"
)
for file in "${WHONIX_FILES[@]}"; do
  dest="$WHONIX_ISO_DIR/$file"
  if [ -f "$dest" ]; then
    printf "Skipping existing %s\n" "$file"
  else
    printf "Downloading %s\n" "$file"
    curl -L --progress-bar -o "$dest" "$WHONIX_BASE_URL/$file"
  fi

  unzipped="${dest%.xz}"
  if [ ! -f "$unzipped" ]; then
    printf "Decompressing %s\n" "$file"
    xz -dk "$dest"
  fi

  final_template="$(basename "${unzipped%.libvirt}")"
  final_template_path="$TEMPLATES_DIR/$final_template.qcow2"
  if [ ! -f "$final_template_path" ]; then
    mv "$unzipped" "$final_template_path"
  else
    printf "Template already exists at %s\n" "$final_template_path"
  fi
done

# Step 3: verify Whonix checksums
sha_url="$WHONIX_BASE_URL/Whonix-18.1.4.2.sha512sums"
sha_file="$WHONIX_ISO_DIR/Whonix-18.1.4.2.sha512sums"
printf "Downloading Whonix sha512sums\n"
curl -L --progress-bar -o "$sha_file" "$sha_url"
(
  cd "$WHONIX_ISO_DIR"
  if ! sha512sum --strict --check "$(basename "$sha_file")" --ignore-missing; then
    printf "Whonix checksum verification failed\n" >&2
    exit 1
  fi
)

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

printf "Quiescent metadata recorded to %s\n" "$METADATA_DIR"
printf "%s setup completed under %s\n" "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$ROOT_DIR" >"$LOG_DIR/setup.log"
echo "Bootstrap complete. Templates and service qubes are staged at $ROOT_DIR."
