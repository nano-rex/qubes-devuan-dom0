# AQ Manager CLI and GUI (Minimal)

This is a minimal Qubes-like control surface for the current stack.

## CLI

Script:
- `scripts/aq-manager.py`

Supported commands:
- `list`
- `status`
- `start <qube>`
- `stop <qube>`
- `restart <qube>`
- `clip-copy <src>`
- `clip-paste <dst> --token <token>`
- `copy-to <src> <dst> <source-relative-path>`
- `move-to <src> <dst> <source-relative-path>`

Qubes-like wrappers:
- `scripts/qvm-ls.sh`
- `scripts/qvm-start.sh <qube>`
- `scripts/qvm-shutdown.sh <qube>`
- `scripts/qvm-restart.sh <qube>`
- `scripts/qvm-copy-to-vm.sh <src> <dst> <path>`
- `scripts/qvm-move-to-vm.sh <src> <dst> <path>`
- `scripts/qvm-start-defaults.sh`

Examples:

```bash
cd /home/user/github/qubesos-runit
./scripts/aq-manager.py --root-dir /var/lib/antix-qubes list
./scripts/aq-manager.py --root-dir /var/lib/antix-qubes status
./scripts/aq-manager.py --root-dir /var/lib/antix-qubes start sys-firewall
token="$(./scripts/aq-manager.py --root-dir /var/lib/antix-qubes clip-copy sys-firewall)"
./scripts/aq-manager.py --root-dir /var/lib/antix-qubes clip-paste sys-whonix --token "$token"
./scripts/aq-manager.py --root-dir /var/lib/antix-qubes copy-to sys-firewall sys-whonix docs/test.txt
./scripts/aq-manager.py --root-dir /var/lib/antix-qubes move-to sys-firewall sys-whonix docs/test.txt
```

## GUI

Script:
- `scripts/aq-manager-gui.py`

What it does:
- Lists service qubes from metadata.
- Start/stop/restart selected qube via `sv`.
- Clipboard copy/paste via token workflow.
- File copy/move via prompt (source is selected list row; destination/path requested).
- Shows command output in a local log pane.

Run:

```bash
cd /home/user/github/qubesos-runit
./scripts/aq-manager-gui.py --root-dir /var/lib/antix-qubes
```

## Runit integration

1. Generate VM services:
   `./scripts/provision-service-qubes.sh /var/lib/antix-qubes`
2. Generate qrexec services:
   `AQ_SHARED_TOKEN=change-me ./scripts/provision-aq-services.sh /var/lib/antix-qubes`
3. Install runit symlinks:
   `sudo ./scripts/install-runit-services.sh /var/lib/antix-qubes`

Notes:
- `aq-manager` expects service directories under `/var/lib/antix-qubes/runit` by default.
- `sv` must be available on host.
- Source files are read from each qube root under `runtime/qubes/<qube>/files/`.
- Destination writes land in `runtime/qubes/<qube>/imports/`.

## Desktop launcher

Install user-level desktop entry and icon:

```bash
cd /home/user/github/qubesos-runit
./scripts/install-desktop-entry.sh
```

This installs:
- `~/.local/share/applications/aq-manager.desktop`
- `~/.local/share/applications/aq-qvm-ls.desktop`
- `~/.local/share/applications/aq-start-service-qubes.desktop`
- `~/.local/share/icons/hicolor/scalable/apps/aq-manager.svg`

You can also launch from shell:

```bash
cd /home/user/github/qubesos-runit
./scripts/qubes-manager.sh /var/lib/antix-qubes
```

## Confirmation prompts

`aq-policyd` now defaults to `scripts/aq-confirm-auto.sh`, which uses GUI confirm (`aq-confirm-gui.py`) when `DISPLAY` is available and falls back to terminal confirm (`aq-confirm.sh`) otherwise.
