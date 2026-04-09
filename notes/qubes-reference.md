# Qubes Reference Notes

These notes record the Qubes behavior we intend to replicate (policy, templates, service ordering) while we implement the antiX/QEMU stack.

- Qubes uses Xen with a strict dom0 which hosts `qubesd`, qrexec, and GUI helpers managed by systemd/runit. Our dom0 will run runit plus a policy daemon to approximate this ordering.
- Template/Disposable qubes behave as read-only bases plus per-qube overlays. On Xen this is implemented with `dvm-template` and `qvm-clone`. On our stack the template will be the antiX ISO and `qemu-img` overlays will stand in.
- qrexec enforces inter-VM RPC and policy. We will need to design a similar RPC layer that talks to QEMU instances (via UNIX sockets) and enforces the same policy semantics.
- Networking uses Xen virtual interfaces and bridges (netvm, sys-net). We'll replace that with bridge/tap management scripts executed under runit; no libvirt daemon.
