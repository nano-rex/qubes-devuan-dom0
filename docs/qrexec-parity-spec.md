# Qrexec Parity Spec (QEMU Stack)

## Scope

This document defines a Qubes-like inter-qube transfer model for this project:

- File copy and move across qubes
- Clipboard copy and paste across qubes
- Policy-based mediation and user confirmation

The implementation target is pure QEMU with host-side mediation. No Xen dependency.

## Security goals

1. No direct qube-to-qube trust channel.
2. All transfers are host mediated.
3. All cross-qube actions are policy checked (`allow`, `ask`, `deny`).
4. Clipboard sync is explicit only, never automatic.
5. Move is not a primitive: it is copy + verify + delete.

## Components

1. `aq-policyd` (host runit service)
- Central policy engine and transfer broker.
- Maintains active qube sessions and action logs.

2. `aq-agent` (guest agent in each template)
- Runs in each qube.
- Handles local file read/write and clipboard requests.
- Talks only to `aq-policyd`.

3. `aq-confirm` (host confirmation helper)
- Minimal prompt utility for `ask` policy actions.
- Returns `allow` or `deny` to `aq-policyd`.

4. CLI tools (host-side)
- `aq-copy-to <src> <dst> <path>`
- `aq-move-to <src> <dst> <path>`
- `aq-clip-copy <src>`
- `aq-clip-paste <dst>`

## Transport

Primary:
- `virtio-vsock` between host and each qube.

Fallback:
- `virtio-serial` UNIX socket endpoints.

Protocol requirements:
- Length-delimited frames.
- Request id + nonce per operation.
- Authenticated session handshake.
- Chunked payload transfer with SHA256 per object.

## Policy model

Policy file:
- `/etc/antix-qubes/policy.conf`

Rule format:
- `<action> <src> <dst> <decision>`
- `action`: `file.copy`, `file.move`, `clip.copy`, `clip.paste`
- `src` and `dst`: qube name, `@any`, or tag selector
- `decision`: `allow`, `ask`, `deny`

Example:

```text
file.copy work @any ask
file.move work vault deny
clip.copy work @any ask
clip.paste work personal ask
```

## File copy flow

1. User runs `aq-copy-to src dst /path/item`.
2. `aq-policyd` loads policy and evaluates `file.copy src dst`.
3. If `ask`, `aq-confirm` prompts user with source, destination, path, size.
4. `aq-agent(src)` streams file to host staging area.
5. Host validates stream checksum and limits.
6. Host streams payload to `aq-agent(dst)` for final write.
7. `aq-policyd` records audit entry and returns status.

## File move flow

1. Perform full copy flow.
2. Verify destination checksum equals source checksum.
3. Send delete request to `aq-agent(src)` only after successful verify.
4. Write explicit move audit entry with copy and delete result.

If delete fails, operation is marked `partial`, never silently ignored.

## Clipboard flow

Clipboard rules:
- Text only in phase 1 (`text/plain`).
- Max size default 1 MiB.
- Buffer TTL default 30 seconds.
- One-time paste token per copy operation.

Copy flow:
1. User runs `aq-clip-copy src`.
2. Policy check for `clip.copy`.
3. Agent reads source clipboard text and sends to host buffer.
4. Host stores encrypted in-memory buffer with TTL.

Paste flow:
1. User runs `aq-clip-paste dst`.
2. Policy check for `clip.paste`.
3. Host prompts if rule is `ask`.
4. Host sends buffer to destination agent and invalidates token.

## Hard limits

- File size ceiling (default 512 MiB, configurable).
- Transfer timeout per chunk and total operation timeout.
- Path sanitization: reject `..`, symlink escape, device nodes.
- Destination writes only under agent-approved import directory by default.

## Auditing

Audit log:
- `/var/log/antix-qubes/policyd.log`

Log fields:
- timestamp
- action
- src
- dst
- object path/id
- size
- decision (`allow`, `ask-allow`, `ask-deny`, `deny`)
- result (`ok`, `partial`, `error`)

## Runit services

Host:
- `/etc/sv/aq-policyd`
- `/etc/sv/aq-confirm`

Guest templates:
- `/etc/sv/aq-agent`

Each service must log via `svlogd` and have deterministic restart behavior.

## Phased implementation

Phase 1:
- `aq-policyd` + `aq-agent` transport handshake
- `clip.copy` and `clip.paste` text-only path

Phase 2:
- `file.copy` for single files
- policy and confirmation prompts

Phase 3:
- `file.move` with checksum verify and delete-ack
- directory copy support

Phase 4:
- richer clipboard formats (optional, policy guarded)
- UX improvements and integration with desktop notifications
