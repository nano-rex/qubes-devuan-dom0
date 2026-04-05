# Dom0 Service Map

This file identifies the first `dom0` services that need explicit `runit`
ports for a `antiX + runit` target.

## Priority 1

These services are directly referenced by the imported `dom0` packaging and
service ordering logic.

1. `qubesd` (runit version already packaged)
- upstream source: `upstream/qubes-core-admin/linux/runit/qubesd`
- role: core admin daemon
- notes:
  - startup ordering currently references:
    - `qubes-db-dom0.service`
    - `libvirtd.service`
    - `virtxend.service`
    - `virtnodedevd.service`
    - `qubes-qmemman.service`

2. `qubes-core`
- upstream source: `upstream/qubes-core-admin/debian/runit/dom0/qubes-core`
- role: core dom0 helper/service wrapper
- notes:
  - currently ordered after `qubesd` and `qubes-qmemman`
  - currently references Xen/libvirt-related legacy units

3. `qubes-qmemman`
- upstream source:
  - packaged from `upstream/qubes-core-admin/debian/runit/dom0/qubes-qmemman`
  - related writer unit in `upstream/qubes-linux-utils/qmemman/qubes-meminfo-writer-dom0.service`
- role: memory management coordination

4. `qubes-preload-dispvm`
- upstream source: `upstream/qubes-core-admin/debian/runit/dom0/qubes-preload-dispvm`
- role: preload disposable VMs

5. `qubes-qrexec-policy-daemon`
- upstream source: `upstream/qubes-core-qrexec/debian/runit/qubes-qrexec-policy-daemon`
- role: qrexec policy daemon

## Priority 2

These are not the first blockers, but they are coupled to the above services.

1. `qubes-vm@`
- upstream source: `upstream/qubes-core-admin/debian/runit/dom0/qubes-vm-autostart`
- role: autostart template/service model for VM startup
- blocker:
  - current Python code in `qubes-core-admin` still carries legacy autostart hooks
  - this needs a direct `runit` replacement path

2. `qubes-meminfo-writer-dom0`
- upstream source: `upstream/qubes-linux-utils/qmemman/qubes-meminfo-writer-dom0.service`
- role: dom0 memory info writer service

3. `qubes-vm-autostart`
- upstream source: `ups` (this runit helper is newly added inside `debian/runit/dom0`)
- role: monitors `/var/lib/qubes/qubes.xml`, starts autostart VMs via `qvm-start`, and shuts them down via `qvm-shutdown`.

4. `qubes-guid`
- upstream source: `upstream/qubes-gui-daemon/gui-daemon/qubes-guid`
- role: GUI virtualization helper that speaks the Qubes GUI protocol and must run in dom0 under runit to keep GUI threads alive.

## Immediate porting implications

1. The Debian packages already install runit directories for the priority-1 services, so the next step is wiring them into dom0’s `runsvdir` layout (via `/etc/qubes/service-manager` or similar).
2. Remove the remaining legacy init macros from the dom0 packages and ensure the runit assets end up under `/etc/sv`.
3. Isolate legacy service-controller usage inside `qubes-core-admin` so those modules can orchestrate runit instead.
4. Provide a runit-friendly replacement for `qubes-vm@.service` that still supports the existing autostart/shutdown behaviors.
5. Confirm dom0 packages install the `qubes-guid` runit service and link it into `/etc/service`, and provide doc guidance for enabling it.
