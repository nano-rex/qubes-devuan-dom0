# Whonix 18.1.4.2 KVM templates

We pull two official Whonix KVM images as the immutable templates for the Whonix-based qubes. The download links and integrity checks follow the guidance on the Whonix Download and verification pages.

| Template | Variant | Source | Verification |
| --- | --- | --- | --- |
| `whonix-gateway` | `Whonix-Gateway-18.1.4.2.Intel_AMD64.qcow2.libvirt.xz` | `https://download.whonix.org/libvirt/18.1.4.2/Whonix-Gateway-18.1.4.2.Intel_AMD64.qcow2.libvirt.xz` | Download the companion `.sha512sums` file and run `sha512sum --check`. |
| `whonix-workstation` | `Whonix-Workstation-18.1.4.2.Intel_AMD64.qcow2.libvirt.xz` | `https://download.whonix.org/libvirt/18.1.4.2/Whonix-Workstation-18.1.4.2.Intel_AMD64.qcow2.libvirt.xz` | Same as above; keep the `.sha512sums` file next to the downloads and verify before inflating the templates. |

When the bootstrap script decompresses these archives (they expand into `.qcow2` images inside `templates/`), it already runs the `sha512sum` check against `Whonix-18.1.4.2.sha512sums`, so you only need to rerun the script after updating to a new Whonix point release.
