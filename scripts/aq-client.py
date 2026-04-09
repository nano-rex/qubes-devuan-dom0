#!/usr/bin/env python3
import argparse
import json
import socket
import sys
from pathlib import Path


def send_recv(sock_path, payload):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
        client.connect(str(sock_path))
        client.sendall((json.dumps(payload, separators=(",", ":")) + "\n").encode("utf-8"))
        data = b""
        while True:
            chunk = client.recv(4096)
            if not chunk:
                break
            data += chunk
            if b"\n" in data:
                line, _rest = data.split(b"\n", 1)
                return json.loads(line.decode("utf-8"))
    raise RuntimeError("no response")


def main():
    parser = argparse.ArgumentParser(description="aq client")
    parser.add_argument("--root-dir", default="/var/lib/antix-qubes")
    parser.add_argument("--socket-path", default=None)
    parser.add_argument("--json", action="store_true")

    sub = parser.add_subparsers(dest="cmd", required=True)
    copy_p = sub.add_parser("clip-copy")
    copy_p.add_argument("src")

    paste_p = sub.add_parser("clip-paste")
    paste_p.add_argument("dst")
    paste_p.add_argument("--token", required=True)

    file_copy = sub.add_parser("file-copy")
    file_copy.add_argument("src")
    file_copy.add_argument("dst")
    file_copy.add_argument("path")

    file_move = sub.add_parser("file-move")
    file_move.add_argument("src")
    file_move.add_argument("dst")
    file_move.add_argument("path")

    sub.add_parser("status")

    args = parser.parse_args()
    if args.socket_path:
        sock = Path(args.socket_path)
    else:
        sock = Path(args.root_dir) / "runtime" / "aq-policyd.sock"

    if args.cmd == "clip-copy":
        req = {"op": "clip_copy", "src": args.src}
    elif args.cmd == "clip-paste":
        req = {"op": "clip_paste", "dst": args.dst, "token": args.token}
    elif args.cmd == "file-copy":
        req = {"op": "file_copy", "src": args.src, "dst": args.dst, "path": args.path}
    elif args.cmd == "file-move":
        req = {"op": "file_move", "src": args.src, "dst": args.dst, "path": args.path}
    else:
        req = {"op": "status"}

    resp = send_recv(sock, req)
    if args.json:
        print(json.dumps(resp))
    else:
        if resp.get("status") != "ok":
            print(resp.get("error", "error"), file=sys.stderr)
            sys.exit(1)
        if args.cmd == "clip-copy":
            print(resp.get("token", ""))
        elif args.cmd == "clip-paste":
            print(f"pasted to {resp.get('dst')}")
        elif args.cmd == "file-copy":
            print(resp.get("imported_path", ""))
        elif args.cmd == "file-move":
            print(resp.get("imported_path", ""))
        else:
            print("ok")


if __name__ == "__main__":
    main()
