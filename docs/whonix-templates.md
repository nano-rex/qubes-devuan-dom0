# Whonix Templates

The Whonix gateway and workstation templates should mirror the upstream Qubes packaging but use the
Devuan + runit base instead of Fedora + systemd. That means:

1. The template builder should install the same runit helpers that the dom0 packages use, so the
   gateway/workstation VMs can be started with expectations compatible with the rest of the system.
2. Packaging should rely on `/usr/bin/doas` for privileged operations inside the template build, matching
   the dom0 workflow.
3. Installer kickstarts that include the Whonix templates must be aware that the template VMs expect the
   Dom0 to provide `runit` services and `doas` helpers.

Until the dom0 packages are fully running under runit, the template work can focus on copying the upstream
Whonix contents into the new Devuan builder layout so the transition is smooth once the base is ready.
