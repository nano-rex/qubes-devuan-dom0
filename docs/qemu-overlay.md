# QEMU Overlay Strategy

1. **Template retention**
   - Keep `isos/antiX-26_x64-core.iso` untouched and inaccessible to guest writes.
   - Snapshot metadata in `/var/lib/antix-qubes/templates/template.meta` references the ISO path, version, and generation ID.

2. **Overlay creation**
   - To launch a qube, run:

     ```sh
     qemu-img create -f qcow2 -b /path/to/isos/antiX-26_x64-core.iso /var/lib/antix-qubes/overlays/qube-1234-root.qcow2
     ```

   - Record the overlay path, backing file, and policy ID in the daemon's registry file.

3. **QEMU invocation**
   - Start QEMU with the overlay as the only writable disk:

     ```sh
     qemu-system-x86_64 \
       -machine accel=kvm -cpu host -smp 2 -m 2048 \
       -drive file=/var/lib/antix-qubes/overlays/qube-1234-root.qcow2,if=virtio,format=qcow2 \
       -netdev tap,id=tap0,script=/usr/local/lib/antix-qubes/net-setup.sh \
       -device virtio-net-pci,netdev=tap0 \
       -display none -daemonize
     ```

   - The policy daemon adds `-monitor unix:/var/run/antix-qubes/qube-1234.monitor,server,nowait` and any qrexec-style sockets.

4. **Overlay cleanup and template updates**
   - When a qube is destroyed, the daemon unlinks its overlay but records the metadata for auditing.
   - Template refreshes create a new ISO, update `manifests/antix-core.md`, and trigger the daemon to regenerate overlays for critical services.
