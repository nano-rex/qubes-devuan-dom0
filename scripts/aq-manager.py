#!/usr/bin/env python3
import argparse
import json
import subprocess
import sys
from pathlib import Path


def load_service_qubes(root_dir: Path):
    meta = root_dir / "metadata" / "service-qubes.json"
    if not meta.exists():
        raise RuntimeError(f"missing metadata file: {meta}")
    data = json.loads(meta.read_text(encoding="utf-8"))
    result = []
    for item in data.get("service_qubes", []):
        name = item.get("name")
        if not name:
            continue
        result.append(
            {
                "name": name,
                "template": item.get("template", ""),
                "role": item.get("role", ""),
            }
        )
    return result


def run_sv(cmd, service_dir: Path, service_name: str):
    service_path = service_dir / service_name
    proc = subprocess.run(
        ["sv", cmd, str(service_path)],
        capture_output=True,
        text=True,
        check=False,
    )
    output = (proc.stdout + proc.stderr).strip()
    return proc.returncode, output


def command_list(root_dir: Path):
    rows = load_service_qubes(root_dir)
    print("name\ttemplate\trole")
    for row in rows:
        print(f"{row['name']}\t{row['template']}\t{row['role']}")


def command_status(root_dir: Path, service_dir: Path):
    rows = load_service_qubes(root_dir)
    for row in rows:
        code, output = run_sv("status", service_dir, row["name"])
        status = output if output else ("ok" if code == 0 else "unknown")
        print(f"{row['name']}\t{status}")


def command_control(root_dir: Path, service_dir: Path, op: str, qube: str):
    _ = load_service_qubes(root_dir)
    code, output = run_sv(op, service_dir, qube)
    if output:
        print(output)
    if code != 0:
        raise RuntimeError(f"sv {op} failed for {qube}")


def command_clip(root_dir: Path, op: str, src_or_dst: str, token: str):
    script_dir = Path(__file__).resolve().parent
    client = script_dir / "aq-client.py"
    base = [str(client), "--root-dir", str(root_dir)]
    if op == "copy":
        proc = subprocess.run(base + ["clip-copy", src_or_dst], capture_output=True, text=True, check=False)
        if proc.returncode != 0:
            raise RuntimeError((proc.stderr or proc.stdout).strip() or "clip-copy failed")
        print(proc.stdout.strip())
    else:
        proc = subprocess.run(
            base + ["clip-paste", src_or_dst, "--token", token],
            capture_output=True,
            text=True,
            check=False,
        )
        if proc.returncode != 0:
            raise RuntimeError((proc.stderr or proc.stdout).strip() or "clip-paste failed")
        print(proc.stdout.strip())


def command_file(root_dir: Path, src: str, dst: str, relpath: str, move: bool):
    script_dir = Path(__file__).resolve().parent
    client = script_dir / "aq-client.py"
    base = [str(client), "--root-dir", str(root_dir)]
    cmd = "file-move" if move else "file-copy"
    proc = subprocess.run(base + [cmd, src, dst, relpath], capture_output=True, text=True, check=False)
    if proc.returncode != 0:
        raise RuntimeError((proc.stderr or proc.stdout).strip() or f"{cmd} failed")
    print(proc.stdout.strip())


def main():
    parser = argparse.ArgumentParser(description="Minimal Qubes-like manager CLI")
    parser.add_argument("--root-dir", default="/var/lib/antix-qubes")
    parser.add_argument("--service-dir", default=None)
    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("list")
    sub.add_parser("status")

    p_start = sub.add_parser("start")
    p_start.add_argument("qube")
    p_stop = sub.add_parser("stop")
    p_stop.add_argument("qube")
    p_restart = sub.add_parser("restart")
    p_restart.add_argument("qube")

    p_copy = sub.add_parser("clip-copy")
    p_copy.add_argument("src")
    p_paste = sub.add_parser("clip-paste")
    p_paste.add_argument("dst")
    p_paste.add_argument("--token", required=True)

    p_copy_to = sub.add_parser("copy-to")
    p_copy_to.add_argument("src")
    p_copy_to.add_argument("dst")
    p_copy_to.add_argument("path")

    p_move_to = sub.add_parser("move-to")
    p_move_to.add_argument("src")
    p_move_to.add_argument("dst")
    p_move_to.add_argument("path")

    args = parser.parse_args()
    root_dir = Path(args.root_dir).resolve()
    service_dir = Path(args.service_dir).resolve() if args.service_dir else (root_dir / "runit")

    try:
        if args.cmd == "list":
            command_list(root_dir)
        elif args.cmd == "status":
            command_status(root_dir, service_dir)
        elif args.cmd in {"start", "stop", "restart"}:
            command_control(root_dir, service_dir, args.cmd, args.qube)
        elif args.cmd == "clip-copy":
            command_clip(root_dir, "copy", args.src, "")
        elif args.cmd == "clip-paste":
            command_clip(root_dir, "paste", args.dst, args.token)
        elif args.cmd == "copy-to":
            command_file(root_dir, args.src, args.dst, args.path, move=False)
        elif args.cmd == "move-to":
            command_file(root_dir, args.src, args.dst, args.path, move=True)
        else:
            raise RuntimeError("unknown command")
    except Exception as exc:  # noqa: BLE001
        print(str(exc), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
