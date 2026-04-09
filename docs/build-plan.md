# Build and Boot Plan

1. **Fetch antiX core**
   - Run `scripts/fetch-antix-core.sh [target-dir]` to download the `antiX-26_x64-core.iso`. The default target directory is `isos/`.
   - The script verifies the SHA256 hash to prevent tampering (see `manifests/antix-core.md`).
   - Keep the ISO read-only; it becomes the backing file for every template overlay.

2. **Prepare overlay storage**
   - Create a storage pool under `/var/lib/antix-qubes/templates/` (or similar) with subdirectories for `overlays/`, `snapshots/`, and `metadata/`.
   - The policy daemon will track active overlay paths and their parents.

3. **Start policy daemon and helpers under runit**
   - `runit` directories live under `/etc/sv/` and `/etc/service/` for `policy-daemon`, `overlay-cleaner`, and `doas-watchdog`.
   - Each service logs to `/var/log/antix-qubes/` and uses `doas` to execute privileged commands (`qemu-system-x86_64`, network bridge setup, etc.).

4. **Booting VMs**
   - Create overlays with `qemu-img create -f qcow2 -b /path/to/isolate core.iso overlay.qcow2`.
   - Launch QEMU with the overlay path, specify `-drive file=overlay.qcow2,format=qcow2` and pin CPUs/memory per policy.
   - Policy daemon enforces qrexec-style rules, controls console sockets, and monitors overlay lifecycle.

5. **Template updates**
   - To refresh a template, stage a new ISO (update `isos/` and `manifests/antix-core.md`), generate new overlays, and rotate running VMs through `doas` commands that clone the new template.
   - Keep the old template archived for auditing.
