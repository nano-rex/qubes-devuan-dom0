# Whonix Templates

The Whonix gateway and workstation templates should mirror the upstream Qubes packaging but start from
the antiX + runit base so they end up running under the same init stack as dom0. That means:

1. The template builder should reuse the dom0 runit helpers (`qubes-guid`, `qrexec-policy-daemon`,
   etc.) so the Whonix VMs assume an antiX + runit host.
2. Template packaging must invoke `/usr/bin/doas` for privileged operations and ship `/etc/qubes/service-manager`
   containing `runit`, so the watchdog code inside each VM can switch over to runit without extra patches.
3. Installer kickstarts that include Whonix templates need to know that `runsvdir` will bring up GUI/qrexec
   helpers and autostarted gateways/workstations via the same scripts as dom0.

Until the dom0 packages are fully stable under runit, the template work can target copying the upstream
Whonix sources into the antiX builder layout, adding runit service directories under
`debian/runit/dom0/{qubes-guid,qubes-qrexec-policy-daemon,...}`, and keeping the installer aware of the
doas/runlist requirements so the transition is smooth once the base is ready.
