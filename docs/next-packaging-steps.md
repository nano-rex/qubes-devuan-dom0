# Next Packaging Steps

## Phase target

Create the first Devuan-oriented dom0 package path for `qubes-core-admin` and
prepare the existing Debian packages to stop assuming `systemd`.

## Concrete tasks

1. Draft `upstream/qubes-core-admin/debian/control`
- define the dom0 package name
- define build dependencies for Devuan
- strip Fedora/RPM assumptions

2. Draft `upstream/qubes-core-admin/debian/rules`
- build/install core admin files
- install `runit` service assets from `porting/runit/`
- avoid `dh --with=systemd`

3. Audit Debian package installs for:
- `qubes-core-qrexec`
- `qubes-linux-utils`
- `qubes-gui-daemon`

4. Replace package-level `systemd` hooks with:
- neutral install logic where possible
- explicit `runit` service installation where needed

## Packaging principle

Do not try to solve every imported package at once.
The correct first package is `qubes-core-admin`, because it is the center of the
`dom0` control plane.
