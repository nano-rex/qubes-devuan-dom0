# Service manager configuration

`/etc/qubes/service-manager` selects the dom0 service controller that the Qubes
Python modules and helper scripts expect. The resolution order is:

1. `QUBES_SERVICE_MANAGER` environment variable
2. `/etc/qubes/service-manager` file contents
3. Defaults to `runit`

For the antiX + runit dom0 this repository installs:

- `/etc/qubes/service-manager` containing the string `runit`
- runit directories under `/etc/sv/` for:
  - `qubesd`
  - `qubes-core`
  - `qubes-preload-dispvm`
  - `qubes-qrexec-policy-daemon`
  - `qubes-meminfo-writer-dom0`
  - `qubes-qmemman`
  - `qubes-vm-autostart`

Each of those service directories also has a symbolic link under `/etc/service`
so `runsvdir` brings them online automatically. `qubes-vm-autostart` exposes
both `run` and `finish` helpers so all autostarted VMs are started during boot
and gracefully shut down when the service stops.

The autostart helpers in `qubes-core-admin/qubes/utils.py` consult
`get_service_manager()` before invoking the runit helper scripts, so having the
service manager configured consistently ensures the right control path runs in dom0.

When running the builder or installer, set `QUBES_SERVICE_MANAGER=runit` if you
want the tooling to exercise the runit-specific code paths; otherwise the
default `runit` flow will be executed.
