# Build bootstrap for antiX dom0

## Current scope

This repository is not ready for a full ISO build yet.

What it does support today:
- a vendored `qubes-builderv2`
- antiX distribution recognition
- antiX mirror support in the Debian builder path
- an explicit antiX archive keyring override
- first-pass Debian/antiX packaging scaffolds for the main `dom0` components

What it does not prove yet:
- a successful end-to-end package build
- a bootable `dom0`
- a working installer image

## Host assumptions

- `python3`
- `doas` (the repo ships `tools/doas-shim` so privileged helper calls go through `doas`)
- `pbuilder`
- a real antiX archive keyring at:
  - `/usr/share/keyrings/devuan-archive-keyring.gpg`

The wrapper now runs `doas -n true` before any builder stages to verify the current user can escalate to root. If the host enforces the `no new privileges` flag or still requires an interactive password, the wrapper exits immediately and asks you to move to a machine where `doas` can run as root so that `pbuilder` can create its chroots.

The builder also expects `doas` to be installed and marked `setuid` so that the installer stage
can run inside the restricted container (there is no fallback to other helpers, so the build fails early
when `doas` is missing or misconfigured). On many hosts you can install and configure it with:

```bash
su -c 'apt install doas'
su -c 'chown root:root /usr/bin/doas'
su -c 'chmod 4755 /usr/bin/doas'
```

- If `doas` is not setuid, the build log will print `doas: not installed setuid` and the installer stage
  still terminates with a clear error.

This wrapper also executes `scripts/check-doas.sh` before the `installer` stages to raise the same
error early, so you see the instructions without waiting for `mock` to fail.


Those assumptions are intentionally strict. The repo should fail early instead
of pretending a bootstrap path exists when the trust root is missing.

Most hosts do not normally provide that antiX keyring path out of the box. The
expected source for that file is the official antiX download area:
- `https://files.devuan.org/devuan-archive-keyring.gpg`

## Config used

Default config:
- [`configs/devuan-dom0-runit.yml`](/home/user/github/qubesos-runit/configs/devuan-dom0-runit.yml)

This config wires in the antiX mirror, the runit service manager, and the local components that
have been ported from the upstream repository. `runit` service definitions for the first dom0 services
(`qubesd`, `qubes-core`, `qubes-qmemman`, `qubes-qrexec-policy-daemon`, `qubes-preload-dispvm`) already exist
inside `upstream/qubes-core-admin/debian/runit/dom0/`, and the `qubes-core-admin` packaging installs them under `/etc/sv`.

Important parts of that config:
- host and VM distribution targets:
  - `host-daedalus`
  - `vm-daedalus`
- antiX mirror:
  - `https://pkgmaster.devuan.org/merged`
- trusted Qubes maintainer fingerprints for source verification:
  - `0064428F455451B3EBE78A7F063938BA42CFA724`
  - `274E12AB03F2FE293765FC06DA0434BC706E1FCF`
- archive keyring override:
  - `/usr/share/keyrings/devuan-archive-keyring.gpg`

## Wrapper script

Use:

```bash
cd /home/user/github/qubesos-runit
./scripts/validate-antix-dom0.sh
./scripts/run-devuan-builder.sh package init-cache
./scripts/run-devuan-builder.sh package fetch prep build
```

The wrapper:
- exports `PYTHONPATH` for the vendored builder
- uses the local antiX config
- keeps the local executor scratch directory under:
  - `/home/user/github/qubesos-runit/artifacts/executor`
- refuses to run if the required host tools are missing
- refuses to run if the antiX archive keyring is missing

The validation script is the fastest preflight check before a real builder run.
It does not prove package builds, but it does catch obvious repo-local problems
in the runit service assets and helper scripts before `pbuilder` is involved.

## Alternate config path

If you need a different config file:

```bash
QUBES_DEVUAN_CONFIG=/path/to/custom.yml ./scripts/run-devuan-builder.sh package init-cache
```

## Immediate next build milestone

The next real milestone is narrower than "build Qubes":

1. create a antiX pbuilder cache
2. attempt a first package build for:
   - `core-admin`
   - `core-qrexec`
   - `linux-utils`
3. capture the first concrete failures
4. port against those actual failures instead of continuing speculative scaffolding
