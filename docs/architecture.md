# Architecture

## Objective

Build a Qubes-derived platform that preserves the core security model while replacing the default `dom0` userspace base with `antiX + runit`.

## Security model

The target system keeps the upstream Qubes model:
- Xen hypervisor as the isolation foundation
- `dom0` as the administrative domain
- application qubes for user workloads
- service domains for network and USB isolation
- GUI virtualization and qrexec for controlled inter-domain interaction

## Major subsystems

1. Hypervisor and boot
- Xen
- dom0 kernel
- bootloader and early userspace

2. Dom0 base system
- antiX userspace
- `runit` as init/service supervision
- `/usr/bin/doas` as the privilege escalator for dom0 and builder scripts
- Qubes admin tooling packaged for the dom0 base

3. Qubes control plane
- `core-admin`
- qrexec policy and services
- qube lifecycle tooling

4. GUI stack
- GUI daemon and agent interfaces
- secure desktop integration across domains

5. Service domains
- network domain
- USB domain
- update and management helpers as needed

## Main divergence from upstream

The key divergence is not Xen or the qube model. It is the dom0 distro and init stack.

Required work:
- replace upstream dom0 packaging assumptions
- replace service management assumptions with `runit`
- keep Qubes control-plane behavior intact

## Hard constraints

1. Dom0 must stay minimal.
2. Dom0 should not become a normal desktop distro with broad package sprawl.
3. Service supervision must be explicit and auditable.
4. Any change that weakens Qubes isolation semantics is unacceptable.

## First milestone definition

A successful first milestone means:
- custom build metadata exists for antiX+runit dom0
- required Qubes components are mapped to packages/services
- boot path and service startup order are defined
- initial builder pipeline tasks are identified

## Risks

1. Upstream builder assumptions may be RPM-oriented in places that resist straightforward adaptation.
2. `runit` migration may require service-level rewrites, not simple packaging changes.
3. Installer and upgrade paths are likely to be harder than the initial package build.
4. Security regressions are easy to introduce if dom0 convenience is prioritized over isolation.
