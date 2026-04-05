#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"
}

require_cmd bash
require_cmd python3

echo "== Shell syntax =="
bash -n "$ROOT_DIR"/scripts/*.sh

echo "== Python syntax =="
python3 -m py_compile \
    "$ROOT_DIR/tools/sudo" \
    "$ROOT_DIR/upstream/qubes-builderv2/qubesbuilder/plugins/build_deb/__init__.py"

echo "== Runit asset permissions =="
while IFS= read -r path; do
    if [[ ! -x "$path" ]]; then
        fail "runit helper is not executable: ${path#$ROOT_DIR/}"
    fi
done < <(find \
    "$ROOT_DIR/upstream/qubes-core-admin/debian/runit" \
    "$ROOT_DIR/upstream/qubes-core-qrexec/debian/runit" \
    -type f \( -name run -o -name finish \) | sort)

echo "== Runit asset presence =="
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/bin" "$tmpdir/services" "$tmpdir/links"
for svc in \
    qubesd \
    qubes-core \
    qubes-preload-dispvm \
    qubes-qrexec-policy-daemon \
    qubes-meminfo-writer-dom0 \
    qubes-qmemman \
    qubes-vm-autostart
do
    ln -s "$ROOT_DIR/upstream/qubes-core-admin/debian/runit/dom0/$svc" "$tmpdir/links/$svc"
done

SERVICE_DIR="$ROOT_DIR/upstream/qubes-core-admin/debian/runit/dom0" \
SERVICE_LINK_DIR="$tmpdir/links" \
    "$ROOT_DIR/scripts/check-runit-services.sh"

echo "== Autostart smoke test =="
cat >"$tmpdir/qubes.xml" <<'EOF'
<qubes>
  <domain>
    <name>work</name>
    <autostart>true</autostart>
  </domain>
  <domain>
    <name>vault</name>
    <autostart>no</autostart>
  </domain>
  <domain>
    <name>sys-net</name>
    <autostart>1</autostart>
  </domain>
</qubes>
EOF

cat >"$tmpdir/bin/qvm-start" <<'EOF'
#!/usr/bin/env bash
printf 'start:%s\n' "$*" >>"$QUBES_AUTOSTART_LOG"
EOF

cat >"$tmpdir/bin/qvm-shutdown" <<'EOF'
#!/usr/bin/env bash
printf 'shutdown:%s\n' "$*" >>"$QUBES_AUTOSTART_LOG"
EOF

chmod 0755 "$tmpdir/bin/qvm-start" "$tmpdir/bin/qvm-shutdown"
autostart_log="$tmpdir/autostart.log"
touch "$autostart_log"

PATH="$tmpdir/bin:$PATH" \
QUBES_XML="$tmpdir/qubes.xml" \
QUBES_AUTOSTART_DELAY=0 \
QUBES_AUTOSTART_ONESHOT=1 \
QUBES_AUTOSTART_LOG="$autostart_log" \
QVM_START_CMD="$tmpdir/bin/qvm-start" \
    "$ROOT_DIR/upstream/qubes-core-admin/debian/runit/dom0/qubes-vm-autostart/run"

PATH="$tmpdir/bin:$PATH" \
QUBES_XML="$tmpdir/qubes.xml" \
QUBES_AUTOSTART_LOG="$autostart_log" \
QVM_SHUTDOWN_CMD="$tmpdir/bin/qvm-shutdown" \
    "$ROOT_DIR/upstream/qubes-core-admin/debian/runit/dom0/qubes-vm-autostart/finish"

grep -Fx 'start:--skip-if-running work' "$autostart_log" >/dev/null || fail "missing autostart for work"
grep -Fx 'start:--skip-if-running sys-net' "$autostart_log" >/dev/null || fail "missing autostart for sys-net"
grep -Fx 'shutdown:--wait work' "$autostart_log" >/dev/null || fail "missing shutdown for work"
grep -Fx 'shutdown:--wait sys-net' "$autostart_log" >/dev/null || fail "missing shutdown for sys-net"

if grep -Fq 'vault' "$autostart_log"; then
    fail "non-autostart VM was incorrectly started or stopped"
fi

echo "Validation passed."
