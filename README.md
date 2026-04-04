# qubes-devuan-dom0

A standalone research and engineering workspace for a Qubes-derived system with a `Devuan + runit` `dom0`.

## Scope

This is a brand new project workspace.
It is not a contribution branch for the upstream Qubes OS repositories.
Official Qubes sources are imported locally as vendor snapshots and will be modified here as needed.

Primary target:
- `dom0`: Devuan with `runit`

Non-goals for the first milestone:
- Artix / OpenRC dom0
- production-ready installer
- production-ready update infrastructure
- security claims beyond upstream Qubes parity

## Project goals

1. Define a custom `dom0` distro target.
2. Adapt the Qubes build workflow needed to build a bootable system.
3. Rework the Qubes core components for a Devuan-based `dom0`.
4. Prove a minimal boot path with Xen and core admin services.

## Why Devuan first

Compared with Artix/OpenRC, Devuan is closer to Debian-family packaging and a more realistic base for a first Qubes-style dom0 fork.

## Planned phases

1. Architecture and repository layout
2. Build manifests and source tracking
3. Dom0 package mapping
4. Minimal builder pipeline
5. Bootable test image
6. Core admin and qrexec integration
7. Update/signing pipeline

## Repository layout

- `docs/architecture.md`: system design and trust boundaries
- `docs/roadmap.md`: phased implementation plan
- `docs/component-map.md`: upstream Qubes components and required adaptations
- `docs/build-devuan-dom0.md`: current build bootstrap path and host requirements
- `docs/devuan-port-notes.md`: first-pass builder and init blockers
- `manifests/dom0-packages.md`: Devuan+runit dom0 package plan
- `manifests/dom0-service-map.md`: dom0 services that must be ported to runit
- `notes/research.md`: current assumptions and unresolved questions
- `upstream/`: imported upstream Qubes source snapshots tracked directly in this repo
- `configs/`: local build/config scaffolding for this standalone project
- `scripts/run-devuan-builder.sh`: local wrapper for the vendored builder

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

Planning scaffold plus imported source trees, initial Devuan-aware builder patches,
first packaging scaffolds, and a concrete local builder wrapper.

## Current build entrypoint

```bash
cd /home/user/github/qubes-devuan-dom0
./scripts/run-devuan-builder.sh package init-cache
./scripts/run-devuan-builder.sh package fetch prep build
```

Details and assumptions:
- [`docs/build-devuan-dom0.md`](/home/user/github/qubes-devuan-dom0/docs/build-devuan-dom0.md)
