# Runit-based VM autostart

Upstream Qubes uses `qubes-vm@.service` to orchestrate autostarted qubes and to drive orderly shutdowns. In this antiX+Runit port we need an equivalent that:

1. Starts on boot and reads the `autostart.yml` config from `qubes-core-admin`.
2. Starts the configured VMs via the existing `qubes-core-admin/qubes/qubesvm.py` APIs instead of calling `systemctl`.
3. Monitors runtime state and triggers `qvm-shutdown` for each running VM during shutdown, matching the existing `ExecStop` behavior.

Proposed structure:

- `/etc/sv/qubes-vm-autostart/run`
  - Loop over configured autostart entries, parse `/var/lib/qubes/qubes.xml`, and call `qvm-start --skip-if-running` for each autostarted VM.
  - Keep the service running so `runsv` can supervise it.
- `/etc/sv/qubes-vm-autostart/finish`
  - On stop, parse the same XML and call `qvm-shutdown --wait` for each autostarted VM.

The helper scripts should execute privileged operations through `/usr/bin/doas`, matching the rest of the dom0 admin tooling.

Current repo status:

- `upstream/qubes-core-admin/debian/runit/dom0/qubes-vm-autostart/run`
  - waits for `qubes.xml`, starts each autostart VM, then stays alive under `runsv`
- `upstream/qubes-core-admin/debian/runit/dom0/qubes-vm-autostart/finish`
  - shuts down those same VMs on service stop
- both helpers accept `QUBES_XML` overrides for testing, plus `QVM_START_CMD` /
  `QVM_SHUTDOWN_CMD` overrides for local smoke tests

Once this service is packaged into `qubes-core-admin-dom0`, we can remove the remaining `systemd` unit references and ensure the runit supervisor starts the service at boot. The builder installs the runit bits under `/etc/sv/qubes-vm-autostart` and links the service into `/etc/service`.
