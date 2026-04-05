# antiX+runit dom0 package plan

## Core base
- xen
- dom0 kernel package
- bootloader integration
- minimal shell/coreutils stack
- package manager base

## Qubes-specific dom0 packages
- core admin components
- qrexec dom0 components
- GUI daemon / related dom0 pieces
- policy tooling
- management CLI/UI components

## Service supervision targets
- qrexec-related services
- GUI-related services
- any dom0 management daemons

## Packaging notes
- dom0 should remain intentionally small
- convenience packages are out of scope for the first milestone
- each service must map cleanly to a `runit` supervision model
