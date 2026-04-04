# Dom0 Package Gap

This file tracks the current packaging state of the imported sources for a
`Devuan + runit` dom0 target.

## Already has Debian packaging

### qubes-core-qrexec
- path: `upstream/qubes-core-qrexec/debian/`
- status:
  - Debian packaging exists
  - still contains `systemd` integration in `rules` and installed unit files
- implication:
  - adapt existing Debian packaging instead of creating from scratch

### qubes-linux-utils
- path: `upstream/qubes-linux-utils/debian/`
- status:
  - Debian packaging exists
  - still uses `dh --with=systemd`
  - installs `qubes-meminfo-writer*.service`
- implication:
  - adapt existing Debian packaging and replace `systemd` unit handling

### qubes-gui-daemon
- path: `upstream/qubes-gui-daemon/debian/`
- status:
  - Debian packaging exists
  - GUI/Audio VM oriented package path is present
- implication:
  - reuse as base where relevant, but dom0-specific path still needs review

## Missing Debian packaging for dom0-critical path

### qubes-core-admin
- current dom0 package path:
  - `upstream/qubes-core-admin/rpm_spec/core-dom0.spec.in`
- Debian packaging:
  - absent before this repo's local scaffold
- implication:
  - this is the main packaging gap for Devuan dom0

### qubes-vmm-xen
- current packaging path is RPM-oriented
- implication:
  - likely needs dedicated Debian/Devuan package adaptation or reuse from an
    external Debian Xen package base plus Qubes patches

### qubes-qubes-release
- current packaging path is RPM-oriented
- implication:
  - Devuan release/repository metadata path must be redesigned

## Recommended packaging order

1. `qubes-core-admin`
2. `qubes-core-qrexec`
3. `qubes-linux-utils`
4. `qubes-vmm-xen`
5. `qubes-qubes-release`
