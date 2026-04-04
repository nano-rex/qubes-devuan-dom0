# Build bootstrap for Devuan dom0

## Current scope

This repository is not ready for a full ISO build yet.

What it does support today:
- a vendored `qubes-builderv2`
- Devuan distribution recognition
- Devuan mirror support in the Debian builder path
- an explicit Devuan archive keyring override
- first-pass Debian/Devuan packaging scaffolds for the main `dom0` components

What it does not prove yet:
- a successful end-to-end package build
- a bootable `dom0`
- a working installer image

## Host assumptions

The current wrapper script assumes a Linux host with:
- `python3`
- `sudo`
- `pbuilder`
- a real Devuan archive keyring at:
  - `/usr/share/keyrings/devuan-archive-keyring.gpg`

Those assumptions are intentionally strict. The repo should fail early instead
of pretending a bootstrap path exists when the trust root is missing.

Fedora does not normally provide that Devuan keyring path by default. The
expected source for that file is the official Devuan download area:
- `https://files.devuan.org/devuan-archive-keyring.gpg`

## Config used

Default config:
- [`configs/devuan-dom0-runit.yml`](/home/user/github/qubes-devuan-dom0/configs/devuan-dom0-runit.yml)

Important parts of that config:
- host and VM distribution targets:
  - `host-daedalus`
  - `vm-daedalus`
- Devuan mirror:
  - `https://pkgmaster.devuan.org/merged`
- trusted Qubes maintainer fingerprints for source verification:
  - `0064428F455451B3EBE78A7F063938BA42CFA724`
  - `274E12AB03F2FE293765FC06DA0434BC706E1FCF`
- archive keyring override:
  - `/usr/share/keyrings/devuan-archive-keyring.gpg`

## Wrapper script

Use:

```bash
cd /home/user/github/qubes-devuan-dom0
./scripts/run-devuan-builder.sh package init-cache
./scripts/run-devuan-builder.sh package fetch prep build
```

The wrapper:
- exports `PYTHONPATH` for the vendored builder
- uses the local Devuan config
- keeps the local executor scratch directory under:
  - `/home/user/github/qubes-devuan-dom0/artifacts/executor`
- refuses to run if the required host tools are missing
- refuses to run if the Devuan archive keyring is missing

## Alternate config path

If you need a different config file:

```bash
QUBES_DEVUAN_CONFIG=/path/to/custom.yml ./scripts/run-devuan-builder.sh package init-cache
```

## Immediate next build milestone

The next real milestone is narrower than "build Qubes":

1. create a Devuan pbuilder cache
2. attempt a first package build for:
   - `core-admin`
   - `core-qrexec`
   - `linux-utils`
3. capture the first concrete failures
4. port against those actual failures instead of continuing speculative scaffolding
