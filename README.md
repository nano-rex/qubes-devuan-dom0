# antiX-QEMU-Runtime

This repository reboots the previous Qubes-derived workspace into a focused antiX-based control plane that manages template-driven virtual machines with pure QEMU. Qubes OS is referenced only for its security model and VM policies; all materials under this tree are written for an antiX host and a KVM/QEMU hypervisor.

## Objectives

1. Download and sandbox the antiX core image that will become the immutable template root.
2. Drive VM lifecycle, clone, and overlay logic with hand-written scripts and policies instead of libvirt or Xen tooling.
3. Document the hardened service architecture (runit, doas, policy helpers) that will sit on top of QEMU overlays.

## Getting the antiX core template

Run `scripts/fetch-antix-core.sh` to download `antiX-26_x64-core.iso` into the `isos/` directory and validate the SHA256 fingerprint. The script can be re-run; it skips re-downloading if the ISO already exists.

## Quick start

Requirements: a Linux host with KVM (Devuan/antiX/Debian with `apt`, or Arch with
`pacman`), root access, and runit for the service layer. `bootstrap-qubes.sh` installs
the QEMU and helper packages itself when run as root (`INSTALL_DEPS=0` to skip).
Nothing is compiled; everything is shell and Python scripts.

```bash
git clone https://github.com/nano-rex/qubes-devuan-dom0.git
cd qubes-devuan-dom0

sudo scripts/bootstrap-qubes.sh                 # antiX core ISO + Whonix images, verified, into /var/lib/antix-qubes
sudo scripts/provision-service-qubes.sh         # overlays + runit stubs: sys-net, sys-usb, sys-firewall, sys-whonix
sudo AQ_SHARED_TOKEN=change-me scripts/provision-aq-services.sh
sudo scripts/install-runit-services.sh          # clipboard/file-copy (qrexec phase 1) services
scripts/install-desktop-entry.sh                # optional: "AQ Manager" in the app menu
```

Both provisioning scripts accept a different root as their first argument
(default `/var/lib/antix-qubes`).

## Example

Start the firewall qube, then move clipboard text and a file from it to the Whonix qube
through the mediated (policy-checked) channel:

```bash
R=/var/lib/antix-qubes
scripts/aq-manager.py --root-dir $R list
scripts/aq-manager.py --root-dir $R start sys-firewall
scripts/aq-manager.py --root-dir $R status

token="$(scripts/aq-manager.py --root-dir $R clip-copy sys-firewall)"
scripts/aq-manager.py --root-dir $R clip-paste sys-whonix --token "$token"

scripts/aq-manager.py --root-dir $R copy-to sys-firewall sys-whonix docs/test.txt
```

Qubes-style shortcuts do the same: `scripts/qvm-ls.sh`, `scripts/qvm-start.sh sys-firewall`,
`scripts/qvm-copy-to-vm.sh sys-firewall sys-whonix docs/test.txt`. The GUI is
`scripts/aq-manager-gui.py`. Route host updates through a service qube with
`scripts/host-update-via.sh whonix apt-get update` (rolled back on exit). Full details:
[`docs/manager-ui.md`](docs/manager-ui.md) and
[`docs/qrexec-phase1-runbook.md`](docs/qrexec-phase1-runbook.md).

## Repository layout

- `docs/`: design notes, architecture, and planning for the antiX host plus the QEMU template workflow.
- `docs/qrexec-parity-spec.md`: Qubes-parity design for file transfer and clipboard mediation.
- `docs/qrexec-phase1-runbook.md`: how to run the first clipboard mediation implementation.
- `docs/manager-ui.md`: minimal Qubes-like manager CLI and GUI usage.
- `scripts/`: helper scripts such as the antiX downloader and future automation.
- `manifests/`: metadata about the antiX core assets, verification data, and environment requirements.
- `notes/`: brainstorming, reference summaries (including the Qubes architecture we keep in mind).
- `isos/`: downloaded images and other bulky assets (not checked into git).

## First-phase focus

1. Nail down how the antiX base boots, which services run under runit, and how `doas` intercepts privileged actions.
2. Design the overlay cloning pattern so every qube boots from an antiX template and cannot mutate it.
3. Build tooling (scripts, configs) that orchestrates template updates, overlay pruning, and policy enforcement without upstream Qubes components.

## Host bootstrap

Run `scripts/bootstrap-qubes.sh [TARGET_ROOT]` from this repo to download the antiX core ISO plus the Whonix gateway/workstation KVM images, verify them, and lay out the `templates/`, `overlays/`, and `metadata/` state described in `docs/system-setup.md`. Once the bootstrap completes, deploy your runit services and policy daemon on top of the generated `metadata/` so they can start the four service qubes (`sys-net`, `sys-usb`, `sys-firewall`, `sys-whonix`) from the intended templates.
`bootstrap-qubes.sh` now supports dependency installation on apt and pacman hosts by default (`INSTALL_DEPS=1` when run as root).

After bootstrap, run `scripts/provision-service-qubes.sh [TARGET_ROOT]` to create per-qube overlays and runit service stubs under `runit/` for the four service qubes.
Then run `AQ_SHARED_TOKEN=change-me scripts/provision-aq-services.sh [TARGET_ROOT]` and `sudo scripts/install-runit-services.sh [TARGET_ROOT]` to provision and install qrexec phase-1 runit services.
Use `scripts/aq-manager.py` (or `scripts/aq-manager-gui.py`) for minimal qube control plus clipboard and file copy/move actions.
Use `scripts/install-desktop-entry.sh` to install an app-menu launcher and icon for `AQ Manager`.

For host updates through a service qube, configure `configs/host-update-route.env.sample`, then use:
- `scripts/host-update-route.sh on firewall|whonix`
- `scripts/host-update-route.sh off`
- `scripts/host-update-via.sh firewall|whonix <command...>` (auto rollback on exit)

Armed with these artifacts we can iterate toward a minimal antiX-plus-QEMU control plane that mirrors Qubes semantics without depending on Xen or libvirt.
