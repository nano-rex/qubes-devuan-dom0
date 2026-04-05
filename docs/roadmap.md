# Roadmap

## Phase 1: Project definition
- define scope and non-goals
- document architecture
- map upstream components
- define dom0 package targets

## Phase 2: Upstream component inventory
- list Qubes repositories required for a minimal system
- identify which components build for dom0
- identify build-time distro assumptions

## Phase 3: antiX dom0 packaging plan
- define package names and dependency strategy
- define `runit` service layout
- define filesystem/service conventions

## Phase 4: Builder adaptation
- create a build orchestration plan for the dom0 target
- define source pinning and patch structure
- define artifact outputs

## Phase 5: Minimal bootable system
- Xen + kernel + dom0 userspace
- earliest viable admin tooling
- serial/logging-oriented boot validation

## Phase 6: Qubes control-plane integration
- qrexec services
- core admin behavior
- GUI integration validation

## Phase 7: Update and maintenance model
- package repository
- signing
- upgrade path
- security maintenance workflow
