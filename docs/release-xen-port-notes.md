# release and xen port notes

## qubes-qubes-release

The imported package is RPM-centric.
Main replacements needed for a antiX dom0 path:
- yum/dnf repo definitions -> apt repository definitions
- rpm GPG key import flow -> apt trust/signing flow
- upstream release identity -> project-specific antiX dom0 identity
- rpm macros/sysusers assumptions -> Debian/antiX equivalents or removals

This repo now includes a minimal Debian package scaffold for:
- `qubes-release-dom0`

Current limitation:
- it is metadata-only scaffolding
- repository signing and update flow are not implemented yet

## qubes-vmm-xen

The imported Xen package path is heavily RPM-oriented and much larger in scope
than the other dom0 packages.

Main challenges:
- large patch stack
- RPM-centric spec and dependency model
- dom0/runtime assumptions mixed with hypervisor build logic

This repo now includes a Debian package scaffold for:
- `xen-qubes-dom0`

Current limitation:
- it is intentionally only a placeholder
- real Debian build rules still need to be authored against the imported Xen
  source tree and patch set
