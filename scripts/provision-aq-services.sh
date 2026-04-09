#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-/var/lib/antix-qubes}"
RUNIT_OUT_DIR="${RUNIT_OUT_DIR:-$ROOT_DIR/runit}"
POLICY_FILE="${POLICY_FILE:-/etc/antix-qubes/policy.conf}"
SHARED_TOKEN="${AQ_SHARED_TOKEN:-change-me}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$ROOT_DIR" && pwd)"
RUNTIME_DIR="$ROOT_DIR/runtime"
LOG_DIR="$ROOT_DIR/log"
META_FILE="$ROOT_DIR/metadata/service-qubes.json"

mkdir -p "$RUNIT_OUT_DIR" "$RUNTIME_DIR" "$LOG_DIR"

if [[ ! -f "$META_FILE" ]]; then
  printf "Missing metadata file: %s\n" "$META_FILE" >&2
  exit 1
fi

list_qubes() {
  python3 - "$META_FILE" <<'PY'
import json
import sys
from pathlib import Path

meta = Path(sys.argv[1])
data = json.loads(meta.read_text(encoding="utf-8"))
for item in data.get("service_qubes", []):
    name = item.get("name")
    if name:
        print(name)
PY
}

create_svlogd() {
  local service_dir="$1"
  mkdir -p "$service_dir/log"
  cat <<'EOF' >"$service_dir/log/run"
#!/usr/bin/env bash
exec svlogd -tt ./main
EOF
  chmod +x "$service_dir/log/run"
}

create_policyd_service() {
  local service_dir="$RUNIT_OUT_DIR/aq-policyd"
  mkdir -p "$service_dir"
  cat <<EOF >"$service_dir/run"
#!/usr/bin/env bash
set -euo pipefail
export AQ_SHARED_TOKEN='$SHARED_TOKEN'
exec '$SCRIPT_DIR/aq-policyd.py' \\
  --root-dir '$ROOT_DIR' \\
  --policy-file '$POLICY_FILE' \\
  --audit-log '$LOG_DIR/policyd.log'
EOF
  chmod +x "$service_dir/run"
  create_svlogd "$service_dir"
}

create_agent_service() {
  local qube="$1"
  local service_dir="$RUNIT_OUT_DIR/aq-agent-$qube"
  mkdir -p "$service_dir"
  cat <<EOF >"$service_dir/run"
#!/usr/bin/env bash
set -euo pipefail
export AQ_SHARED_TOKEN='$SHARED_TOKEN'
exec '$SCRIPT_DIR/aq-agent.py' --name '$qube' --root-dir '$ROOT_DIR'
EOF
  chmod +x "$service_dir/run"
  create_svlogd "$service_dir"
}

create_policyd_service
while IFS= read -r qube; do
  [[ -n "$qube" ]] || continue
  create_agent_service "$qube"
done < <(list_qubes)

cat <<EOF
Provisioned qrexec phase-1 runit stubs:
  runit dir: $RUNIT_OUT_DIR
  policy: $POLICY_FILE
  audit log: $LOG_DIR/policyd.log
  services: aq-policyd and aq-agent-<qube>
EOF
