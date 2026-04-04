# qrexec and linux-utils port notes

## qubes-core-qrexec

Changes introduced in this repo:

1. added a new Debian binary package target:
   - `qubes-core-qrexec-dom0`
2. removed the `dh --with systemd` packaging assumption
3. kept the shared source package model
4. added installation of the `runit` service directory for:
   - `qubes-qrexec-policy-daemon`

Current limitation:
- the source tree still contains VM-side `systemd` service files
- those are not the first dom0 blocker, but they remain to be revisited later

## qubes-linux-utils

Changes introduced in this repo:

1. removed the `dh --with=systemd` packaging assumption
2. removed the packaged `qubes-meminfo-writer.service` unit from the Debian
   install path
3. replaced it with the `runit` service directory for:
   - `qubes-meminfo-writer-dom0`

Current limitation:
- this is still a packaging scaffold, not a validated build artifact
- VM-side and non-dom0 service assumptions remain elsewhere in the source tree
