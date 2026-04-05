## Tools

This directory contains small helpers that augment the builder workflow for the Devuan domain.

- `sudo`: shim invoked via `scripts/run-devuan-builder.sh` before every `sudo` call. It propagates `--preserve-env`
  arguments by exporting the requested variables (or the entire environment when `-E` is used), then
  attempts to run `/usr/bin/doas`. If `doas` is unavailable or not setuid, the shim falls back to the
  system `sudo` so the build can still proceed (albeit without the final dom0 `doas` experience).

When running the installer stages you must install `doas` and mark it setuid-root:

```bash
sudo apt install doas
sudo chown root:root /usr/bin/doas
sudo chmod 4755 /usr/bin/doas
```
