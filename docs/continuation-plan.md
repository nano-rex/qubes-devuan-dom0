# Continuation plan for antiX+runit

This document turns the "next" checklist in this repository into a concrete work list for the remaining components that the user asked to finish: Xen, dom0, templates, the service domains, and the live installer.

## 1. Xen and the dom0 hypervisor path
- `upstream/qubes-vmm-xen` is still authored for RPM building via `xen.spec.in` and `hpdk` macros; the Debian scaffolding under `upstream/qubes-core-admin/debian` only packages dom0 services and does not cover the hypervisor. We need to:
  - create Debian `rules` that mirror the upstream patch stack (`upstream/qubes-vmm-xen/*.patch` and `rpm_spec/xen.spec.in`) so `qubes-builderv2` can invoke `dpkg-buildpackage` under the antiX base.
  - ensure `docs/release-xen-port-notes.md` documents the new dependency mappings and that the builder config points at the Debianized `xen-qubes-dom0` tree (`configs/devuan-dom0-runit.yml` currently references the RPM tree at `upstream/qubes-vmm-xen`).
  - consider reusing the Debian kernels/libraries from the existing `linux-kernel` component so the Xen package produces modules compiled against the antiX dom0 kernel while still consuming the Qubes patch set.
- The dom0-package gap manifest reiterates the same blockers: `qubes-vmm-xen` and `qubes-qubes-release` remain RPM-only and the Debian path has to be finished once `qubes-core-admin` stabilizes (`manifests/dom0-package-gap.md:33-60`).

## 2. The dom0 base and runit service stack
- The first full `qubes-core-admin` Debian package must:
  - declare only the dependencies required for dom0 (`qubes-core-admin-dom0` already depends on `python3`, `python3-libvirt`, `pciutils`, `socat`, `runit`, etc., in `upstream/qubes-core-admin/debian/control`).
  - install the runit directories (`/etc/sv/qubesd`, `/etc/sv/qubes-core`, `/etc/sv/qubes-qrexec-policy-daemon`, `/etc/sv/qubes-qmemman`) and symlink them under `/etc/service` so `runsvdir` can supervise them (`debian/rules`, `scripts/check-runit-services.sh`, `docs/service-manager.md`).
  - ship `/etc/qubes/service-manager` containing `runit` and ensure the builder inserts the service directories when the package is installed into the dom0 image.
- The dom0 service map already highlights the services that need attention (`manifests/dom0-service-map.md:6-72`). On the code side, we must:
  - replace any lingering legacy service-controller calls inside `qubes-core-admin` (e.g., `qubes/utils.py`) with abstraction helpers that call the runit wrappers or the new `qubes-vm-autostart` scripts.
  - ensure dom0 configuration files (qrexec policy, vm autostart lists) are paired with the runit services that manage them; `scripts/validate-antix-dom0.sh` already checks runit permissions/autostart behavior and should be re-run after each change.
- The `tools/doas-shim` helper (which prepends environment preservation and the `doas` invocation) must continue to work for every privileged step executed by the builder and installer (`tools/README.md` describes the expectation).

## 3. Templates and service domains (sys-usb, sys-net, sys-firewall, sys-whonix)
- **Whonix templates:** they should reuse the dom0 runit helpers and the `doas` shim. The template packages must drop any antiX-incompatible assumptions, install `/etc/qubes/service-manager` with `runit`, and ensure `runsvdir` controls the GUI/qrexec helpers inside `upstream/qubes-linux-template-builder`. The current plan is described in `docs/whonix-templates.md:3-16`.
- **Service domains:** four service VMs are part of the default layout:
  - `sys-net` and `sys-usb` host network/USB controllers and need sysfs PCI configuration plus runit-managed autostart logic (the `qubes-vm-autostart` service, `upstream/qubes-core-admin/qubes/qubesvm.py`, and `manifests/dom0-service-map.md` all touch this area).
  - `sys-firewall` mediates app qube traffic and its firewall rules live under `/rw/config/qubes-firewall-user-script` inside the VM (`upstream/qubes-doc/user/security-in-qubes/firewall.rst` describes the stateful flows).
  - `sys-whonix` acts as the Torified update proxy and is driven through qrexec policy lines such as `qubes.UpdatesProxy` in `upstream/qubes-core-admin/qubes-rpc-policy/90-default.policy`.
- The runit autostart helpers (`docs/runit-vm-autostart.md:3-27`) must be hardened so they can later be packaged inside dom0 and reused by the service domains. That includes ensuring `qvm-start` and `qvm-shutdown` are invoked via `/usr/bin/doas` and that the helper reads `/var/lib/qubes/qubes.xml` for the proper autostart set.
- As work progresses, we should annotate this document or `manifests/dom0-service-map.md` with the current status of each service (e.g., `qubesd` runit script present, `qubes-vm-autostart` packaged, `manifests` updated).

## 4. Live installer and builder pipeline
- `scripts/run-devuan-builder.sh` prefixes `tools/doas-shim` and the antiX config before calling `qubesbuilder-cli`. The installer/former `devuan` documentation now points to `docs/build-antix-dom0.md:5-117` as the authoritative guide.
- The installer sources (`upstream/qubes-installer-qubes-os/live`, `conf`, `meta-packages`) still expect the old RPM/init stack for `dom0` packages. Each installer stub (kickstart, livecd-tools) must be ported to the antiX/runit world so that PXE/ISO builds reference `xen-qubes-dom0`, `qubes-core-admin-dom0`, and the `doas` shim rather than the old package set.
- Until the installer knows how to find the new Debian package tree and the `runit` service manager, we cannot produce a working live ISO. Finishing the `qubes-core-admin` path, adding the service domains, and generating a Debian-friendly `xen-qubes-dom0` are the immediate prerequisites before the installer pipeline can run.

## Next logical steps
1. Finish `qubes-core-admin` packaging, making sure the runit service directories are installed and the Python helpers in `qubes-core-admin/qubes` call the runit helper scripts; rerun `scripts/validate-antix-dom0.sh` after every change so the autostart smoke test keeps passing (`manifests/dom0-package-gap.md:35-53`, `docs/next-packaging-steps.md:10-27`, `scripts/validate-antix-dom0.sh:36-112`).
2. Replace the remaining legacy init references in `qubes-core-qrexec`, `qubes-linux-utils`, and `qubes-gui-daemon` with explicit runit wiring, and keep `manifests/dom0-service-map.md` in sync so the installer knows which runit directories to ship (`manifests/dom0-service-map.md:6-75`, `docs/service-manager.md:10-34`).
3. Extend the Whonix template flow by adding the runit helpers, `doas` treatment, and any extra template-specific hooks described in `docs/whonix-templates.md` so those templates can boot under antiX/runit.
4. Finish the Debian `xen-qubes-dom0` package, wire it into `configs/devuan-dom0-runit.yml`, and document how the installer is supposed to pick up the new hypervisor artifacts (`docs/release-xen-port-notes.md:19-35`).
5. Iterate on the live installer builder stages (`scripts/run-devuan-builder.sh`, the `tools` helpers, and `upstream/qubes-installer-qubes-os`) so the pipeline produces an ISO that boots into the antiX+runit dom0 instead of stopping at validation (`docs/build-antix-dom0.md:7-117`, `tools/doas-shim:8-71`).
