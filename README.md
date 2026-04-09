# antiX-QEMU-Runtime

This repository reboots the previous Qubes-derived workspace into a focused antiX-based control plane that manages template-driven virtual machines with pure QEMU. Qubes OS is referenced only for its security model and VM policies; all materials under this tree are written for an antiX host and a KVM/QEMU hypervisor.

## Objectives

1. Download and sandbox the antiX core image that will become the immutable template root.
2. Drive VM lifecycle, clone, and overlay logic with hand-written scripts and policies instead of libvirt or Xen tooling.
3. Document the hardened service architecture (runit, doas, policy helpers) that will sit on top of QEMU overlays.

## Getting the antiX core template

Run `scripts/fetch-antix-core.sh` to download `antiX-26_x64-core.iso` into the `isos/` directory and validate the SHA256 fingerprint. The script can be re-run; it skips re-downloading if the ISO already exists.

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
