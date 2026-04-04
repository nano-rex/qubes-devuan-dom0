# Dom0 Service Map

This file identifies the first `dom0` services that need explicit `runit`
ports for a `Devuan + runit` target.

## Priority 1

These services are directly referenced by the imported `dom0` packaging and
service ordering logic.

1. `qubesd`
- upstream source: `upstream/qubes-core-admin/linux/systemd/qubesd.service`
- role: core admin daemon
- notes:
  - startup ordering currently references:
    - `qubes-db-dom0.service`
    - `libvirtd.service`
    - `virtxend.service`
    - `virtnodedevd.service`
    - `qubes-qmemman.service`

2. `qubes-core`
- upstream source: `upstream/qubes-core-admin/linux/systemd/qubes-core.service`
- role: core dom0 helper/service wrapper
- notes:
  - currently ordered after `qubesd` and `qubes-qmemman`
  - currently references Xen/libvirt-related systemd units

3. `qubes-qmemman`
- upstream source:
  - packaged from `upstream/qubes-core-admin/linux/systemd/qubes-qmemman.service`
  - related writer unit in `upstream/qubes-linux-utils/qmemman/qubes-meminfo-writer-dom0.service`
- role: memory management coordination

4. `qubes-preload-dispvm`
- upstream source: `upstream/qubes-core-admin/linux/systemd/qubes-preload-dispvm.service`
- role: preload disposable VMs

5. `qubes-qrexec-policy-daemon`
- upstream source: `upstream/qubes-core-qrexec/systemd/qubes-qrexec-policy-daemon.service`
- role: qrexec policy daemon

## Priority 2

These are not the first blockers, but they are coupled to the above services.

1. `qubes-vm@`
- upstream source: `upstream/qubes-core-admin/linux/systemd/qubes-vm@.service`
- role: autostart template/service model for VM startup
- blocker:
  - current Python code in `qubes-core-admin` calls `systemctl`
  - this needs an abstraction layer or a direct `runit` replacement path

2. `qubes-meminfo-writer-dom0`
- upstream source: `upstream/qubes-linux-utils/qmemman/qubes-meminfo-writer-dom0.service`
- role: dom0 memory info writer service

## Immediate porting implications

1. We need a `runit` service directory layout for each priority-1 service.
2. We need to remove `systemd` macros from dom0 packaging.
3. We need to isolate hardcoded `systemctl` usage in Python code.
4. We need a replacement for the `qubes-vm@.service` autostart model.
