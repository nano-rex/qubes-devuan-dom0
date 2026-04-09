# Qrexec Phase 1 Runbook

This runbook covers clipboard-only mediation for the Phase 1 stack.

## 1) Policy file

Create policy file:

```bash
sudo mkdir -p /etc/antix-qubes
sudo cp /home/user/github/qubesos-runit/configs/policy.conf.sample /etc/antix-qubes/policy.conf
```

## 2) Start host broker

```bash
cd /home/user/github/qubesos-runit
AQ_SHARED_TOKEN=change-me ./scripts/aq-policyd.py --root-dir /var/lib/antix-qubes --policy-file /etc/antix-qubes/policy.conf
```

## 3) Start one agent per qube

Run once per qube (example names: `sys-firewall`, `sys-whonix`):

```bash
cd /home/user/github/qubesos-runit
AQ_SHARED_TOKEN=change-me ./scripts/aq-agent.py --name sys-firewall --root-dir /var/lib/antix-qubes
AQ_SHARED_TOKEN=change-me ./scripts/aq-agent.py --name sys-whonix --root-dir /var/lib/antix-qubes
```

## 4) Copy and paste clipboard

Copy from source qube to host buffer:

```bash
cd /home/user/github/qubesos-runit
token="$(./scripts/aq-clip-copy.sh sys-firewall /var/lib/antix-qubes)"
echo "$token"
```

Paste to destination qube:

```bash
cd /home/user/github/qubesos-runit
./scripts/aq-clip-paste.sh sys-whonix "$token" /var/lib/antix-qubes
```

Notes:
- Token is one-time and expires (default 30 seconds).
- Phase 1 is text-only clipboard.
- Policy defaults to `ask`, using `scripts/aq-confirm.sh`.

## 5) File copy and move

Place a source file in the source qube path:

```bash
sudo mkdir -p /var/lib/antix-qubes/runtime/qubes/sys-firewall/files/docs
echo "hello file copy" | sudo tee /var/lib/antix-qubes/runtime/qubes/sys-firewall/files/docs/test.txt >/dev/null
```

Copy to destination import folder:

```bash
cd /home/user/github/qubesos-runit
./scripts/aq-copy-to.sh sys-firewall sys-whonix docs/test.txt /var/lib/antix-qubes
```

Move to destination import folder:

```bash
cd /home/user/github/qubesos-runit
./scripts/aq-move-to.sh sys-firewall sys-whonix docs/test.txt /var/lib/antix-qubes
```

## 6) Check broker status

```bash
cd /home/user/github/qubesos-runit
./scripts/aq-client.py --root-dir /var/lib/antix-qubes status
```

## 7) Provision runit stubs for qrexec services

```bash
cd /home/user/github/qubesos-runit
AQ_SHARED_TOKEN=change-me ./scripts/provision-aq-services.sh /var/lib/antix-qubes
sudo ./scripts/install-runit-services.sh /var/lib/antix-qubes
```
