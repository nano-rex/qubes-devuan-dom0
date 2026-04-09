#!/usr/bin/env python3
import argparse
import base64
import hashlib
import json
import os
import socket
import sys
from pathlib import Path


def recv_json_line(conn):
    buf = b""
    while True:
        chunk = conn.recv(4096)
        if not chunk:
            break
        buf += chunk
        if b"\n" in buf:
            line, _rest = buf.split(b"\n", 1)
            return json.loads(line.decode("utf-8"))
    raise RuntimeError("empty request")


def send_json_line(conn, obj):
    conn.sendall((json.dumps(obj, separators=(",", ":")) + "\n").encode("utf-8"))


def resolve_safe_relative(base_dir: Path, relative_path: str):
    candidate = (base_dir / relative_path).resolve()
    if not str(candidate).startswith(str(base_dir.resolve()) + os.sep):
        raise RuntimeError("path_escape")
    return candidate


def handle_request(req, clipboard_file, shared_token, qube_root):
    if req.get("auth") != shared_token:
        return {"status": "error", "error": "auth_failed"}

    op = req.get("op")
    if op == "hello":
        return {"status": "ok", "agent": "aq-agent"}

    if op == "ping":
        return {"status": "ok", "pong": True}

    if op == "get_clipboard":
        if clipboard_file.exists():
            text = clipboard_file.read_text(encoding="utf-8", errors="replace")
        else:
            text = ""
        return {"status": "ok", "text": text}

    if op == "set_clipboard":
        text = req.get("text", "")
        if not isinstance(text, str):
            return {"status": "error", "error": "invalid_text"}
        clipboard_file.parent.mkdir(parents=True, exist_ok=True)
        clipboard_file.write_text(text, encoding="utf-8")
        return {"status": "ok"}

    if op == "read_file":
        relpath = req.get("path", "")
        if not isinstance(relpath, str) or not relpath:
            return {"status": "error", "error": "invalid_path"}
        files_dir = qube_root / "files"
        files_dir.mkdir(parents=True, exist_ok=True)
        src = resolve_safe_relative(files_dir, relpath)
        if not src.exists() or not src.is_file():
            return {"status": "error", "error": "source_not_found"}
        raw = src.read_bytes()
        digest = hashlib.sha256(raw).hexdigest()
        return {
            "status": "ok",
            "name": src.name,
            "bytes": len(raw),
            "sha256": digest,
            "data_b64": base64.b64encode(raw).decode("ascii"),
        }

    if op == "write_import":
        filename = req.get("name", "")
        data_b64 = req.get("data_b64", "")
        if not isinstance(filename, str) or not filename:
            return {"status": "error", "error": "invalid_name"}
        if not isinstance(data_b64, str):
            return {"status": "error", "error": "invalid_data"}
        # Keep file name simple to avoid host path confusion.
        name = Path(filename).name
        imports_dir = qube_root / "imports"
        imports_dir.mkdir(parents=True, exist_ok=True)
        raw = base64.b64decode(data_b64.encode("ascii"), validate=True)
        dst = resolve_safe_relative(imports_dir, name)
        dst.write_bytes(raw)
        digest = hashlib.sha256(raw).hexdigest()
        return {"status": "ok", "path": str(dst), "bytes": len(raw), "sha256": digest}

    if op == "delete_file":
        relpath = req.get("path", "")
        if not isinstance(relpath, str) or not relpath:
            return {"status": "error", "error": "invalid_path"}
        files_dir = qube_root / "files"
        files_dir.mkdir(parents=True, exist_ok=True)
        target = resolve_safe_relative(files_dir, relpath)
        if not target.exists() or not target.is_file():
            return {"status": "error", "error": "source_not_found"}
        target.unlink()
        return {"status": "ok"}

    return {"status": "error", "error": "unknown_op"}


def main():
    parser = argparse.ArgumentParser(description="aq-agent clipboard service")
    parser.add_argument("--name", required=True, help="qube name")
    parser.add_argument("--root-dir", default="/var/lib/antix-qubes")
    parser.add_argument("--clipboard-file", default=None)
    parser.add_argument("--qube-root", default=None)
    parser.add_argument("--token", default=os.environ.get("AQ_SHARED_TOKEN", "change-me"))
    args = parser.parse_args()

    root_dir = Path(args.root_dir)
    socket_dir = root_dir / "runtime" / "agents"
    socket_dir.mkdir(parents=True, exist_ok=True)
    socket_path = socket_dir / f"{args.name}.sock"

    if args.clipboard_file:
        clipboard_file = Path(args.clipboard_file)
    else:
        clipboard_file = root_dir / "runtime" / "clips" / f"{args.name}.txt"

    if args.qube_root:
        qube_root = Path(args.qube_root)
    else:
        qube_root = root_dir / "runtime" / "qubes" / args.name

    try:
        socket_path.unlink()
    except FileNotFoundError:
        pass

    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as server:
        server.bind(str(socket_path))
        os.chmod(socket_path, 0o660)
        server.listen(64)
        while True:
            conn, _ = server.accept()
            with conn:
                try:
                    req = recv_json_line(conn)
                    resp = handle_request(req, clipboard_file, args.token, qube_root)
                except Exception as exc:  # noqa: BLE001
                    resp = {"status": "error", "error": str(exc)}
                send_json_line(conn, resp)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(0)
