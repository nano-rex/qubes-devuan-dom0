# Next Packaging Steps

## Phase target

Create the first antiX-oriented dom0 package path for `qubes-core-admin` and
prepare the existing Debian packages to stop assuming a specific init manager.

## Concrete tasks

1. Draft `upstream/qubes-core-admin/debian/control`
- define the dom0 package name
- define build dependencies for antiX
- strip RPM-specific assumptions

2. Draft `upstream/qubes-core-admin/debian/rules`
- build/install core admin files
- install `runit` service assets from `porting/runit/`
- avoid `dh --with=` wrappers that tie the package to a specific init manager

3. Audit Debian package installs for:
- `qubes-core-qrexec`
- `qubes-linux-utils`
- `qubes-gui-daemon`

4. Replace package-level legacy init hooks with:
- neutral install logic where possible
- explicit `runit` service installation where needed

## Packaging principle

Do not try to solve every imported package at once.
The correct first package is `qubes-core-admin`, because it is the center of the
`dom0` control plane.
