## Tools

This directory contains small helpers that augment the builder workflow for the antiX domain.

- `doas-shim`: invoked via `scripts/run-devuan-builder.sh` before every privileged call. It propagates
  `--preserve-env` arguments by exporting the requested variables (or the entire environment when `-E` is used)
  and then executes the command through `/usr/bin/doas`. A compatibility link at `tools/sudo` keeps the
  legacy `sudo` program name available for upstream scripts without exposing a separate tool.

When running the installer stages you must install `doas` and mark it setuid-root. If `doas` is not yet
available you can bootstrap it from root with the following commands:

```bash
su -c 'apt install doas'
su -c 'chown root:root /usr/bin/doas'
su -c 'chmod 4755 /usr/bin/doas'
```
