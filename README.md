# qubes-devuan-dom0

A research and engineering workspace for a Qubes-derived system with a `Devuan + runit` `dom0`.

## Scope

This is not a post-install conversion script for an existing Linux distribution.
It is a source-level fork project intended to adapt the Qubes OS architecture to a custom `dom0` base.

Primary target:
- `dom0`: Devuan with `runit`

Non-goals for the first milestone:
- Artix / OpenRC dom0
- production-ready installer
- production-ready update infrastructure
- security claims beyond upstream Qubes parity

## Project goals

1. Define a custom `dom0` distro target.
2. Fork the Qubes build workflow needed to build a bootable system.
3. Package the Qubes core components for a Devuan-based `dom0`.
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
- `manifests/dom0-packages.md`: Devuan+runit dom0 package plan
- `notes/research.md`: current assumptions and unresolved questions

## Current status

Planning scaffold only.

## Upstream repositories included

The workspace tracks these official upstream repositories as git submodules under `upstream/`:
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

These are tracked directly from `QubesOS/*`, not forked mirrors.
