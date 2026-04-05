# Research Notes

## Current assumptions
- upstream Qubes architecture remains the base model
- the first serious target is antiX+runit dom0
- Artix/OpenRC is deferred because it is a less stable starting point for a Qubes fork

## Open questions
1. Which upstream builder steps are hardest to decouple from RPM-style dom0 assumptions?
2. Which dom0 services need deeper init integration versus plain packaging?
3. What is the smallest bootable milestone that still proves the fork direction is viable?
4. How should update/signing be handled before there is a full release pipeline?

## Immediate next work
- inventory upstream Qubes repositories
- identify dom0-facing components
- draft a package/service mapping matrix
