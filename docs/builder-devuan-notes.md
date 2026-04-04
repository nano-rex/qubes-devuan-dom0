# Builder Devuan Notes

## Scope

This note tracks the minimum builder changes needed so the imported Debian
build pipeline can recognize and provision a `Devuan` target.

## Changes made in this repo

1. `QubesDistribution` now recognizes:
- `chimaera`
- `daedalus`
- `excalibur`
- `freia`

2. `chroot_deb/pbuilder/pbuilderrc` now maps those names to:
- `DIST_VENDOR=devuan`
- `MIRRORSITE=https://pkgmaster.devuan.org/merged`
- `COMPONENTS=main`

3. `publish_deb/scripts/create-skeleton` now supports:
- `fullname=devuan`

## Remaining builder work

1. validate whether the selected Devuan mirror and keyring approach are enough
   for `pbuilder create`
2. add Devuan archive keyrings to the builder key directory if current
   debootstrap verification expects them by filename
3. test publish skeleton generation for the Devuan release tree

## Practical implication

The builder path is no longer blocked at the first distribution-family check.
The next blocker is likely keyring/bootstrap behavior during actual chroot
creation.
