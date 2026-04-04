# Devuan Port Notes

## What the first inspection shows

1. `qubes-builderv2` already supports Debian-family package builds through the
   `build_deb` and `chroot_deb` plugins.
2. The builder did not recognize `Devuan` as a distribution before this repo's
   local patch.
3. The imported `dom0` packaging path is still heavily RPM- and `systemd`-based.

## Main blockers identified

### Builder

- `upstream/qubes-builderv2/qubesbuilder/distribution.py`
  - needed a new `Devuan` distribution family entry

### Packaging

- `upstream/qubes-core-admin/rpm_spec/core-dom0.spec.in`
- `upstream/qubes-core-qrexec/rpm_spec/qubes-qrexec-dom0.spec.in`
- `upstream/qubes-gui-daemon/rpm_spec/gui-daemon.spec.in`
- `upstream/qubes-linux-utils/rpm_spec/qubes-utils.spec.in`
- `upstream/qubes-qubes-release/qubes-release.spec.in`
- `upstream/qubes-vmm-xen/xen.spec.in`

These are the main dom0-facing package definitions currently in scope.

### Init / service supervision

Hard `systemd` coupling exists in both package metadata and runtime behavior:

- service units in:
  - `upstream/qubes-core-admin/linux/systemd/`
  - `upstream/qubes-core-qrexec/systemd/`
  - `upstream/qubes-linux-utils/qmemman/`
- `systemctl` calls in:
  - `upstream/qubes-core-admin/qubes/vm/qubesvm.py`

## First milestone target

The first milestone should not try to solve the whole platform.
It should prove:

1. the builder can target `host-daedalus`
2. dom0-critical package set is explicitly identified
3. the first `runit` service map exists
4. `systemctl` assumptions are identified before replacement work starts

## Immediate next code targets

1. add a `Devuan`-oriented builder config
2. draft `runit` service directories for:
   - `qubesd`
   - `qubes-core`
   - `qubes-qmemman`
   - `qubes-qrexec-policy-daemon`
3. isolate autostart logic currently tied to `qubes-vm@.service`
