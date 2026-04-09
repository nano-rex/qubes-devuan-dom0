# System bootstrap for antiX Qubes-like host

This script-driven flow covers everything needed to turn an existing Linux host into the antiX/runit/QEMU stack you described: three immutable templates (antiX core, Whonix gateway, Whonix workstation) and four mandatory service domains (`sys-net`, `sys-usb`, `sys-firewall`, `sys-whonix`).

## Prerequisites

- Basic tools: `curl`, `xz`, `sha512sum`, `qemu-img`, `qemu-system-x86_64`.
- Preferably run as root or via `doas`/`sudo` because the default target path is `/var/lib/antix-qubes`.
- Network access to SourceForge (antiX core) and `download.whonix.org` (the official Whonix KVM images that implement the gateway/workstation templates).

## Running `scripts/bootstrap-qubes.sh`

1. Execute `./scripts/bootstrap-qubes.sh [TARGET_ROOT]` (default target: `/var/lib/antix-qubes`).
   - By default it attempts dependency installation (`INSTALL_DEPS=1`) for apt or pacman hosts when run as root.
   - Set `INSTALL_DEPS=0` to skip package installation.
2. The script calls `scripts/fetch-antix-core.sh` to download `antiX-26_x64-core.iso` and verifies it against the SHA256 listed in `manifests/antix-core.md`.
3. It fetches the Whonix gateway/workstation archives from `download.whonix.org/libvirt/18.1.4.2/`, inflates them into dedicated `templates/` files, and validates both using the shared `Whonix-18.1.4.2.sha512sums` file.
4. Metadata files `metadata/templates.json` and `metadata/service-qubes.json` are created so later automation can enumerate every template and service qube.
5. The bootstrap log is written to `log/setup.log` so you can audit what ran (timestamped in UTC).

## Provisioning service qubes

After bootstrap, run `./scripts/provision-service-qubes.sh [TARGET_ROOT]`.

1. It creates one writable qcow2 overlay per service qube (`sys-net`, `sys-usb`, `sys-firewall`, `sys-whonix`) under `overlays/`.
2. It writes runit service stubs under `runit/<qube>/` with `run` and `log/run` scripts.
3. Each `run` script launches plain QEMU with the overlay, plus monitor and serial UNIX sockets in `runtime/`.
4. You can tune CPU and memory defaults using env vars before running: `CPU_DEFAULT`, `MEM_DEFAULT_MB`, `QEMU_BIN`, and `RUNIT_OUT_DIR`.

## Layout after bootstrap

- `isos/antiX-26_x64-core.iso` remains read-only; every qube overlay uses it as a backing file.
- `isos/whonix/` holds the downloaded `.qcow2.libvirt.xz` archives plus the `.sha512sums` manifest; only the decompressed `.qcow2` images are staged under `templates/`.
- `templates/Whonix-Gateway-18.1.4.2.Intel_AMD64.qcow2` becomes the `whonix-gateway` template, and `templates/Whonix-Workstation-18.1.4.2.Intel_AMD64.qcow2` becomes the `whonix-workstation` template per `manifests/whonix-templates.md`.
- `metadata/service-qubes.json` repeatedly lists the four service VMs that must exist on every host; the `sys-*` qubes are wired to templates as follows:
  - `sys-net`, `sys-usb`, `sys-firewall` all run from the `antix-core` template.
  - `sys-whonix` runs from the `whonix-gateway` template to enforce the Whonix subset of network isolation.

## Extending the setup

Once the bootstrap is complete, the repo already documents in `docs/qemu-overlay.md` how overlays should be created from every template. The policy daemon and runit services described in `docs/architecture.md` can consume `metadata/` to locate each template and start the corresponding `qemu-system-x86_64` instance with the right overlay and network tap sockets. You can also add glue scripts to rotate `whonix-workstation` clones from nightly/bi-weekly template refreshes.

For cross-qube copy/move and clipboard behavior parity, use `docs/qrexec-parity-spec.md` as the implementation contract.

## Optional host update path via service qubes

This repo includes a guarded route toggle so host update traffic can be temporarily routed via `sys-firewall` or `sys-whonix`:

1. Copy `configs/host-update-route.env.sample` to `/etc/antix-qubes/host-update-route.env` and set gateway IP/device values for your host network.
2. Enable temporary route:
   `sudo ./scripts/host-update-route.sh on firewall`
3. Disable route when done:
   `sudo ./scripts/host-update-route.sh off`
4. Prefer the wrapper for safety:
   `sudo ./scripts/host-update-via.sh firewall apt update`

Default behavior is conservative (`APT_ONLY=1`): only `_apt` TCP 80/443 traffic is marked and policy-routed, so your host keeps its normal default route for everything else.
