# antiX + QEMU Architecture

## Vision

The control plane lives entirely on an antiX host that boots a minimal systemd-free stack managed by `runit`. Every virtual machine (qube) expresses its filesystem as a thin writable overlay above a locked-down template image. Xen is not part of this graph: KVM/QEMU is the sole virtualization layer, and the project owns the tooling that orchestrates template cloning, policy enforcement, and network isolation.

## Layers

1. **Host base** - antiX (Debian derivative) with a slim kernel, runit supervision, `doas` for privilege escalation, and only those packages needed to drive KVM/QEMU and the policy daemon. No `libvirt`, no Xen-specific packages.
2. **Template layer** - the antiX core ISO (currently antiX-26_x64-core) becomes the canonical template. We keep it unchanged, mount it read-only, and expose it through `qemu-img` backing files. Template updates are handled by a separate workflow that rebuilds base overlays and marks old templates as archived.
3. **QEMU layer** - each qube boots from a writable qcow2 overlay that uses the template image as its backing file. The overlay lives on disk owned by the policy daemon, and the daemon starts and stops QEMU instances with overlays assigned according to the desired disposition.
4. **Service layer** - runit launches the policy daemon, aux scripts for cloning/updating templates, and helpers for network isolation. All privileged operations run via `doas` so root access is auditable and limited to the necessary commands.

## Enforcement goals

- Templates cannot be mutated; every qube gets its own overlay.
- The policy daemon orchestrates `qemu-system-x86_64` instances directly (no libvirt daemon). It tracks overlays, VNC console sockets, PCI device assignments, and qrexec-equivalent policy rules.
- Networking and USB isolation are handled by dedicated helpers started under runit; they manage bridges, tap devices, and firewall rules.

## Reference to Qubes

Qubes OS remains a touchstone for what the policy daemon must replicate - template/dispvm workflows, qrexec RPC, and strict service ordering - but no Xen components or RPM packages travel into this workspace. The repo contains notes (`notes/qubes-reference.md`) that remind us of the relevant concepts without enforcing any upstream code paths.
