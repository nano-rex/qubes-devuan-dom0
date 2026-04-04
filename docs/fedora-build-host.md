# Fedora build host notes

## Why this document exists

The current workstation is Fedora-based, while the first target package path is
Devuan `dom0`.

That means the immediate job is not "install Devuan". It is:
- make the Fedora host capable of running the vendored builder
- create Devuan pbuilder caches from that host
- then hit real package failures

## Package manifest

Reference package list:
- [`manifests/fedora-build-host-packages.txt`](/home/user/github/qubes-devuan-dom0/manifests/fedora-build-host-packages.txt)

This list is derived from the imported upstream builder dependency files, plus
the Debian-side tools that are specifically required by this repo's current
Devuan path.

## Host checker

Use:

```bash
cd /home/user/github/qubes-devuan-dom0
./scripts/check-fedora-build-host.sh
```

That checker reports which Fedora packages are still missing for the current
local-executor path.

## Install command

When ready, the expected install shape is:

```bash
sudo dnf install $(tr '\n' ' ' < manifests/fedora-build-host-packages.txt)
```

## Important distinction

This only bootstraps the build host.

It does **not** mean:
- the package scaffolds are correct
- the Devuan pbuilder setup is proven
- the resulting `dom0` build is valid

It only gets the environment to the point where the first real package build
attempt becomes possible.

## Devuan keyring requirement

Even after the Fedora package set is installed, the Devuan builder path still
needs a real Devuan archive keyring at:
- `/usr/share/keyrings/devuan-archive-keyring.gpg`

That file is not normally provided by Fedora packages. For this project, the
expected source is the official Devuan file:
- `https://files.devuan.org/devuan-archive-keyring.gpg`
