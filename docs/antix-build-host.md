# antiX build host notes

## Why this document exists

This project now targets antiX throughout the dom0 and builder stack, so the
workstation that drives the build should also run antiX.

That keeps the toolchain, package manager, and helper scripts aligned with the
runtime target instead of translating between RPM conventions and Debian/antiX expectations.

One immediate goal is to make the workstation capable of running the vendored
builder and creating pbuilder caches for the `dom0` packages.

## Package manifest

Reference package list:
- [`manifests/antix-build-host-packages.txt`](/home/user/github/qubesos-runit/manifests/antix-build-host-packages.txt)

The list is derived from the upstream builder dependencies plus the Debian/antiX
helpers that this repo currently exercises. It focuses on the tools needed to
run the antiX-targeted builder workflows without dragging in RPM-specific
artifacts.

## Host checker

Use:

```bash
cd /home/user/github/qubesos-runit && ./scripts/check-antix-build-host.sh
```

The checker reports any missing antiX packages from the manifest and prints
a suggested `apt` command when something is absent.

## Install command

When you need to install or refresh the host dependencies:

```bash
su -c "apt install $(tr '\n' ' ' < manifests/antix-build-host-packages.txt)"
```

If `doas` is already available, you can also prefix the command with `doas`
instead of `su`.

## Keyring requirement

The builder still expects a real antiX archive keyring at:
- `/usr/share/keyrings/devuan-archive-keyring.gpg`

You can download it from the official antiX archive if your host does not
provide it out of the box.

## Privilege escalation and configuration

The scripts in this repo expect `doas` to perform privileged operations. Run:

```bash
./scripts/check-doas.sh
./scripts/check-doas-config.sh
```

before starting the installer stages to verify that `doas` is installed, owned
by root, marked setuid, and configured to grant the builder user access.  If you
need to install `doas`, run `su -c 'apt install doas'`, then run the helper
checks above so you get a clear error if something is still missing.
