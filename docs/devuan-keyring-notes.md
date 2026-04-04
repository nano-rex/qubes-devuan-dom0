# Devuan keyring notes

## Why this exists

The imported Debian builder path originally assumed that every supported
distribution family had a matching archive keyring file vendored under:

- `qubesbuilder/plugins/chroot_deb/keys/`

That is not a good default for this project's Devuan target because:

1. no Devuan archive keyring was present in the imported builder tree
2. inventing a fake local keyring file would undermine bootstrap trust

## Approach used in this repo

The builder now supports an explicit config override for the archive keyring:

```yaml
deb:
  archive-keyring:
    devuan: /usr/share/keyrings/devuan-archive-keyring.gpg
```

This keeps the bootstrap path honest:
- use a real Devuan archive keyring from the build environment
- do not pretend an imported placeholder key is trustworthy

## Current implication

The next actual build attempt for a Devuan chroot depends on the build host or
executor image having the referenced keyring available at the configured path.
