# Runit-based VM autostart

Upstream Qubes uses `qubes-vm@.service` to orchestrate autostarted qubes and to drive orderly shutdowns. In this Devuan+Runit port we need an equivalent that:

1. Starts on boot and reads the `autostart.yml` config from `qubes-core-admin`.
2. Starts the configured VMs via the existing `qubes-core-admin/qubes/qubesvm.py` APIs instead of calling `systemctl`.
3. Monitors runtime state and triggers `qvm-shutdown` for each running VM during shutdown, matching the existing `ExecStop` behavior.

Proposed structure:

- `/etc/sv/qubes-vm-autostart/run`
  - Loop over configured autostart entries, call a helper script that uses `python3 -m qubes.qubesvm` or the `qcli` command to start each VM in the right order.
  - Keep the service running so `runsv` can supervise it.
- `/etc/sv/qubes-vm-autostart/finish`
  - On stop, call a shutdown helper that iterates running VMs and calls `qvm-shutdown --wait`.

The helper scripts should execute privileged operations through `/usr/bin/doas`, matching the rest of the dom0 admin tooling.

Once this service is packaged into `qubes-core-admin-dom0`, we can remove the `systemd` unit references and ensure the runit supervisor starts the service at boot. The builder should install the runit bits under `/etc/sv/qubes-vm-autostart` (including the `run` and `finish` helpers) and list the service in the `service-manager` manifest so dom0 activation scripts can link it into `runsvdir`.
