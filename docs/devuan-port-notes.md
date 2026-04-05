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
- Wrapper hitch
  - `scripts/run-devuan-builder.sh` now prepends `tools` exposing a `sudo` shim that delegates to `/usr/bin/doas`.
  - The installer `mock` stages now rely on `doas` being setuid/root; the shim falls back to the host `sudo` if it is not available.
  - `scripts/check-doas.sh` is executed before installer stages too, so build courses fail fast if `doas` isn't configured.

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

- `systemd` service files in:
  - `upstream/qubes-core-admin/linux/systemd/`
  - `upstream/qubes-core-qrexec/systemd/`
  - `upstream/qubes-linux-utils/qmemman/`
- `systemctl` calls in:
  - `upstream/qubes-core-admin/qubes/vm/qubesvm.py`

We already include runit service assets under the Debian packaging directories (`upstream/qubes-core-admin/debian/runit/dom0/` etc.), and the initial `qubes-core-admin-dom0` package deploys:

```
etc/sv/qubesd
etc/sv/qubes-core
etc/sv/qubes-preload-dispvm
etc/sv/qubes-qrexec-policy-daemon
etc/sv/qubes-meminfo-writer-dom0
```

The immediate tasks are:

1. Replace remaining `systemd` packages with runit equivalents, starting with the priority-1 services from `manifests/dom0-service-map.md`.
2. Update `qubes-core-admin`’s Python modules to stop invoking `systemctl`; they should either talk directly to `runit` or call the packaged helper scripts.
3. Provide a replacement for `qubes-vm@.service` that recreates the autostart/autoshutdown flow with runit-level recipes or an equivalent supervisor.
4. See `docs/runit-vm-autostart.md` for a concrete plan on the VM autostart/shutdown helper.

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

## Newly closed gaps

- `qubes-vm-autostart`
  - the packaged `run` / `finish` helpers now parse `qubes.xml` correctly instead of embedding the literal shell variable name into Python
  - both helpers are now testable via `QUBES_XML`, `QVM_START_CMD`, and `QVM_SHUTDOWN_CMD` overrides
- Debian packaging
  - `upstream/qubes-core-admin/debian/rules` now forces executable mode on every installed runit `run` / `finish` helper so package output does not depend on worktree file modes
- repository validation
  - `scripts/validate-devuan-dom0.sh` provides a single preflight command for syntax checks, runit asset checks, and a smoke test of the VM autostart service
