# qubesos-runit

A standalone project workspace that builds a Qubes-derived system using antiX + runit + doas in dom0.

## Scope

This is a brand new project workspace.
It is not a contribution branch for the upstream Qubes OS repositories.
Official Qubes sources are imported locally as vendor snapshots and will be modified here as needed.

Primary target:
- `dom0`: antiX with `runit` and `doas`

Non-goals for the first milestone:
- Artix / OpenRC dom0
- production-ready installer
- production-ready update infrastructure
- security claims beyond upstream Qubes parity

## Project goals

1. Define a custom `dom0` distro target.
2. Adapt the Qubes build workflow needed to build a bootable system.
3. Rework the Qubes core components for a antiX-based `dom0`.
4. Prove a minimal boot path with Xen and core admin services.

## Why antiX first

Compared with Artix/OpenRC, antiX is closer to Debian-family packaging and a more realistic base for a first Qubes-style dom0 fork.

## Planned phases

1. Architecture and repository layout
2. Build manifests and source tracking
3. Dom0 package mapping
4. Minimal builder pipeline
5. Bootable test image
6. Core admin and qrexec integration
7. Update/signing pipeline

## Repository layout

-- `docs/architecture.md`: system design and trust boundaries
-- `docs/roadmap.md`: phased implementation plan
-- `docs/component-map.md`: upstream Qubes components and required adaptations
-- `docs/build-antix-dom0.md`: current antiX build bootstrap path and host requirements
-- `docs/whonix-templates.md`: plan for the Whonix gateway/workstation templates
-- `docs/runit-vm-autostart.md`: proposal for replacing `qubes-vm@.service` with runit
-- `docs/service-manager.md`: explains the runit service wiring for dom0
-- `docs/antix-build-host.md`: antiX host bootstrap path for local builder execution
-- `manifests/dom0-packages.md`: antiX+runit dom0 package plan
-- `manifests/antix-build-host-packages.txt`: antiX build host prerequisites
-- `manifests/dom0-service-map.md`: dom0 services that must be ported to runit
-- `notes/research.md`: current assumptions and unresolved questions
- `upstream/`: imported upstream Qubes source snapshots tracked directly in this repo
- `configs/`: local build/config scaffolding for this standalone project
- `scripts/run-devuan-builder.sh`: local wrapper for the vendored builder
- `scripts/check-antix-build-host.sh`: checks the current antiX host against required packages

## Imported upstream sources

These directories were imported from official Qubes repositories and are now tracked as part of this standalone project:
- `qubes-builderv2`
- `qubes-core-admin`
- `qubes-core-qrexec`
- `qubes-gui-daemon`
- `qubes-gui-agent-linux`
- `qubes-core-agent-linux`
- `qubes-linux-kernel`
- `qubes-linux-utils`
- `qubes-vmm-xen`
- `qubes-linux-template-builder`
- `qubes-installer-qubes-os`
- `qubes-manager`
- `qubes-qubes-release`
- `qubes-doc`

## Current status

Planning scaffold plus imported source trees, initial antiX-aware builder patches,
first packaging scaffolds, and a concrete local builder wrapper.

## Build workflow

Use the local wrapper to run both the package build pipeline and the installer flow.

```bash
cd /home/user/github/qubesos-runit
. ./scripts/run-devuan-builder.sh package init-cache
. ./scripts/run-devuan-builder.sh package fetch prep build
. ./scripts/run-devuan-builder.sh installer init-cache
```

The installer stages are required before an ISO can be generated, and they rely on
the antiX-aware mock configuration added under `upstream/qubes-builderv2/qubesbuilder/plugins/installer/mock/`.

- Detail and assumptions:
- [`docs/build-antix-dom0.md`](/home/user/github/qubesos-runit/docs/build-antix-dom0.md)
- [`docs/antix-build-host.md`](/home/user/github/qubesos-runit/docs/antix-build-host.md)

Before attempting package or installer stages, run the local validation pass:

```bash
cd /home/user/github/qubesos-runit
./scripts/validate-antix-dom0.sh
```

That script checks shell/Python syntax, verifies the packaged runit assets are
executable, and smoke-tests the `qubes-vm-autostart` service logic against a
temporary `qubes.xml` fixture.

## Host validation

Before running the builder, make sure the workstation satisfies the antiX host manifest.
Read [`docs/antix-build-host.md`](/home/user/github/qubesos-runit/docs/antix-build-host.md)
for the recommended packages and use `scripts/check-antix-build-host.sh` to verify the current state.
It enumerates the packages listed in `manifests/antix-build-host-packages.txt`
and suggests an `apt install` command when something is missing.

## Service manager setup

See `docs/service-manager.md` for how this fork configures the dom0 service manager
and runit wiring so the builder/autostart helpers talk to the expected controller.

Run `scripts/check-runit-services.sh` inside an installed dom0 to ensure the
packaging produced `/etc/sv/<service>` directories and `/etc/service` symlinks
for every core dom0 daemon before booting `runsvdir`.

## Privilege escalation

The dom0 services and builder workflow expect `doas` as the privileged runner.
`scripts/run-devuan-builder.sh` prepends `tools` (which now contains the `tools/doas-shim`
helper and a compatibility `tools/sudo` link) so every upstream `sudo` invocation flows through
the shim and executes via `doas`.

Make sure `/usr/bin/doas` is owned by `root` and marked `setuid` before running the installer stages:

```bash
su -c 'chown root:root /usr/bin/doas'
su -c 'chmod 4755 /usr/bin/doas'
```

The wrapper now runs `scripts/check-doas.sh` and the new `scripts/check-doas-config.sh` before any
`installer` stage so you get an upfront error message if either the `doas` binary or its configuration
is missing or out of sync with the recommended entries. Use `configs/doas.conf.sample` as a starting
point, and adjust the `root`/`:wheel` lines to match your personal `wheel` group if needed.

## Whonix templates

The Whonix gateway and workstation templates will also ride on the antiX + runit foundation.
Each template should reuse the dom0 runit assets wherever possible and rely on the `doas`-based root helpers
rather than the upstream init stack. The long-term plan is to mirror the upstream Whonix packaging
while swapping the backend distro and init stack; once the dom0 packages are running under runit we can extend
the template builder to use the same `doas` shim in the installer stages.
