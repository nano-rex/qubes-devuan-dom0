#!/usr/bin/env python3
import argparse
import base64
import hashlib
import json
import os
import secrets
import socket
import subprocess
import time
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


def load_policy(policy_file):
    rules = []
    with policy_file.open("r", encoding="utf-8") as fh:
        for raw in fh:
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split()
            if len(parts) != 4:
                continue
            action, src, dst, decision = parts
            if decision not in {"allow", "ask", "deny"}:
                continue
            rules.append((action, src, dst, decision))
    return rules


def matches(rule_val, real_val):
    return rule_val == "@any" or rule_val == real_val


def evaluate_policy(rules, action, src, dst):
    for rule_action, rule_src, rule_dst, decision in rules:
        if rule_action != action:
            continue
        if not matches(rule_src, src):
            continue
        if not matches(rule_dst, dst):
            continue
        return decision
    return "deny"


def ask_confirm(confirm_cmd, action, src, dst):
    proc = subprocess.run(
        [confirm_cmd, action, src, dst],
        capture_output=True,
        text=True,
        check=False,
    )
    output = (proc.stdout or "").strip().lower()
    if proc.returncode == 0 and output in {"allow", "yes", "y"}:
        return True
    return False


def agent_call(agent_sock, token, payload):
    req = dict(payload)
    req["auth"] = token
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
        client.connect(str(agent_sock))
        send_json_line(client, req)
        resp = recv_json_line(client)
    if resp.get("status") != "ok":
        raise RuntimeError(f"agent_error:{resp.get('error', 'unknown')}")
    return resp


class ClipboardBuffer:
    def __init__(self):
        self.token = None
        self.src = None
        self.text = ""
        self.expires_at = 0.0
        self.used = True

    def set(self, src, text, ttl_seconds):
        self.token = secrets.token_hex(16)
        self.src = src
        self.text = text
        self.expires_at = time.time() + ttl_seconds
        self.used = False
        return self.token

    def consume(self, expected_token):
        if self.used:
            raise RuntimeError("clipboard_already_used")
        if time.time() > self.expires_at:
            self.used = True
            raise RuntimeError("clipboard_expired")
        if expected_token != self.token:
            raise RuntimeError("clipboard_token_mismatch")
        self.used = True
        return self.src, self.text


def build_response_ok(**kwargs):
    payload = {"status": "ok"}
    payload.update(kwargs)
    return payload


def build_response_error(error):
    return {"status": "error", "error": error}


def log_event(log_path, action, src, dst, decision, result, details=None):
    entry = {
        "ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "action": action,
        "src": src,
        "dst": dst,
        "decision": decision,
        "result": result,
    }
    if details:
        entry["details"] = details
    log_path.parent.mkdir(parents=True, exist_ok=True)
    with log_path.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(entry, separators=(",", ":")) + "\n")


def main():
    parser = argparse.ArgumentParser(description="aq-policyd clipboard broker")
    parser.add_argument("--root-dir", default="/var/lib/antix-qubes")
    parser.add_argument("--policy-file", default="/etc/antix-qubes/policy.conf")
    parser.add_argument("--socket-path", default=None)
    parser.add_argument("--token", default=os.environ.get("AQ_SHARED_TOKEN", "change-me"))
    parser.add_argument("--ttl-seconds", type=int, default=30)
    parser.add_argument("--max-bytes", type=int, default=1024 * 1024)
    parser.add_argument("--confirm-cmd", default=None)
    parser.add_argument("--audit-log", default=None)
    parser.add_argument("--max-file-bytes", type=int, default=512 * 1024 * 1024)
    args = parser.parse_args()

    root = Path(args.root_dir)
    runtime = root / "runtime"
    runtime.mkdir(parents=True, exist_ok=True)
    staging_dir = runtime / "staging"
    staging_dir.mkdir(parents=True, exist_ok=True)
    audit_log = Path(args.audit_log) if args.audit_log else (root / "log" / "policyd.log")

    policy_path = Path(args.policy_file)
    if not policy_path.exists():
        fallback = Path(__file__).resolve().parent.parent / "configs" / "policy.conf.sample"
        policy_path = fallback

    if args.socket_path:
        socket_path = Path(args.socket_path)
    else:
        socket_path = runtime / "aq-policyd.sock"

    confirm_cmd = args.confirm_cmd
    if not confirm_cmd:
        confirm_cmd = str(Path(__file__).resolve().parent / "aq-confirm-auto.sh")

    try:
        socket_path.unlink()
    except FileNotFoundError:
        pass

    clip = ClipboardBuffer()

    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as server:
        server.bind(str(socket_path))
        os.chmod(socket_path, 0o660)
        server.listen(64)

        while True:
            conn, _ = server.accept()
            with conn:
                try:
                    req = recv_json_line(conn)
                    op = req.get("op")
                    rules = load_policy(policy_path)

                    if op == "clip_copy":
                        src = req["src"]
                        decision = evaluate_policy(rules, "clip.copy", src, "@host")
                        if decision == "deny":
                            resp = build_response_error("policy_deny")
                            log_event(audit_log, "clip.copy", src, "@host", decision, "deny")
                        else:
                            if decision == "ask" and not ask_confirm(confirm_cmd, "clip.copy", src, "@host"):
                                resp = build_response_error("policy_ask_denied")
                                log_event(audit_log, "clip.copy", src, "@host", decision, "ask-deny")
                            else:
                                agent_sock = runtime / "agents" / f"{src}.sock"
                                data = agent_call(agent_sock, args.token, {"op": "get_clipboard"})
                                text = data.get("text", "")
                                text_bytes = text.encode("utf-8")
                                if len(text_bytes) > args.max_bytes:
                                    resp = build_response_error("clipboard_too_large")
                                    log_event(
                                        audit_log,
                                        "clip.copy",
                                        src,
                                        "@host",
                                        decision,
                                        "error",
                                        {"error": "clipboard_too_large", "bytes": len(text_bytes)},
                                    )
                                else:
                                    token = clip.set(src, text, args.ttl_seconds)
                                    resp = build_response_ok(token=token, bytes=len(text_bytes), src=src, ttl=args.ttl_seconds)
                                    result = "ok" if decision == "allow" else "ask-allow"
                                    log_event(
                                        audit_log,
                                        "clip.copy",
                                        src,
                                        "@host",
                                        decision,
                                        result,
                                        {"bytes": len(text_bytes)},
                                    )

                    elif op == "clip_paste":
                        dst = req["dst"]
                        token = req["token"]
                        src, text = clip.consume(token)
                        decision = evaluate_policy(rules, "clip.paste", src, dst)
                        if decision == "deny":
                            resp = build_response_error("policy_deny")
                            log_event(audit_log, "clip.paste", src, dst, decision, "deny")
                        else:
                            if decision == "ask" and not ask_confirm(confirm_cmd, "clip.paste", src, dst):
                                resp = build_response_error("policy_ask_denied")
                                log_event(audit_log, "clip.paste", src, dst, decision, "ask-deny")
                            else:
                                agent_sock = runtime / "agents" / f"{dst}.sock"
                                agent_call(agent_sock, args.token, {"op": "set_clipboard", "text": text})
                                resp = build_response_ok(dst=dst, bytes=len(text.encode("utf-8")))
                                result = "ok" if decision == "allow" else "ask-allow"
                                log_event(
                                    audit_log,
                                    "clip.paste",
                                    src,
                                    dst,
                                    decision,
                                    result,
                                    {"bytes": len(text.encode("utf-8"))},
                                )

                    elif op == "file_copy":
                        src = req["src"]
                        dst = req["dst"]
                        relpath = req["path"]
                        decision = evaluate_policy(rules, "file.copy", src, dst)
                        if decision == "deny":
                            resp = build_response_error("policy_deny")
                            log_event(
                                audit_log,
                                "file.copy",
                                src,
                                dst,
                                decision,
                                "deny",
                                {"path": relpath},
                            )
                        else:
                            if decision == "ask" and not ask_confirm(confirm_cmd, "file.copy", src, dst):
                                resp = build_response_error("policy_ask_denied")
                                log_event(
                                    audit_log,
                                    "file.copy",
                                    src,
                                    dst,
                                    decision,
                                    "ask-deny",
                                    {"path": relpath},
                                )
                            else:
                                src_agent = runtime / "agents" / f"{src}.sock"
                                src_data = agent_call(src_agent, args.token, {"op": "read_file", "path": relpath})
                                byte_count = int(src_data["bytes"])
                                if byte_count > args.max_file_bytes:
                                    resp = build_response_error("file_too_large")
                                    log_event(
                                        audit_log,
                                        "file.copy",
                                        src,
                                        dst,
                                        decision,
                                        "error",
                                        {"path": relpath, "error": "file_too_large", "bytes": byte_count},
                                    )
                                else:
                                    raw = base64.b64decode(src_data["data_b64"].encode("ascii"), validate=True)
                                    calc_src = hashlib.sha256(raw).hexdigest()
                                    if calc_src != src_data["sha256"]:
                                        resp = build_response_error("source_checksum_mismatch")
                                        log_event(
                                            audit_log,
                                            "file.copy",
                                            src,
                                            dst,
                                            decision,
                                            "error",
                                            {"path": relpath, "error": "source_checksum_mismatch"},
                                        )
                                    else:
                                        stage_name = secrets.token_hex(8) + "-" + src_data["name"]
                                        stage_path = staging_dir / stage_name
                                        stage_path.write_bytes(raw)
                                        dst_agent = runtime / "agents" / f"{dst}.sock"
                                        dst_data = agent_call(
                                            dst_agent,
                                            args.token,
                                            {
                                                "op": "write_import",
                                                "name": src_data["name"],
                                                "data_b64": src_data["data_b64"],
                                            },
                                        )
                                        stage_path.unlink(missing_ok=True)
                                        if dst_data["sha256"] != calc_src:
                                            resp = build_response_error("dest_checksum_mismatch")
                                            log_event(
                                                audit_log,
                                                "file.copy",
                                                src,
                                                dst,
                                                decision,
                                                "error",
                                                {"path": relpath, "error": "dest_checksum_mismatch"},
                                            )
                                        else:
                                            resp = build_response_ok(
                                                src=src,
                                                dst=dst,
                                                path=relpath,
                                                imported_path=dst_data["path"],
                                                bytes=byte_count,
                                                sha256=calc_src,
                                            )
                                            result = "ok" if decision == "allow" else "ask-allow"
                                            log_event(
                                                audit_log,
                                                "file.copy",
                                                src,
                                                dst,
                                                decision,
                                                result,
                                                {
                                                    "path": relpath,
                                                    "imported_path": dst_data["path"],
                                                    "bytes": byte_count,
                                                },
                                            )

                    elif op == "file_move":
                        src = req["src"]
                        dst = req["dst"]
                        relpath = req["path"]
                        decision = evaluate_policy(rules, "file.move", src, dst)
                        if decision == "deny":
                            resp = build_response_error("policy_deny")
                            log_event(
                                audit_log,
                                "file.move",
                                src,
                                dst,
                                decision,
                                "deny",
                                {"path": relpath},
                            )
                        else:
                            if decision == "ask" and not ask_confirm(confirm_cmd, "file.move", src, dst):
                                resp = build_response_error("policy_ask_denied")
                                log_event(
                                    audit_log,
                                    "file.move",
                                    src,
                                    dst,
                                    decision,
                                    "ask-deny",
                                    {"path": relpath},
                                )
                            else:
                                src_agent = runtime / "agents" / f"{src}.sock"
                                src_data = agent_call(src_agent, args.token, {"op": "read_file", "path": relpath})
                                byte_count = int(src_data["bytes"])
                                if byte_count > args.max_file_bytes:
                                    resp = build_response_error("file_too_large")
                                    log_event(
                                        audit_log,
                                        "file.move",
                                        src,
                                        dst,
                                        decision,
                                        "error",
                                        {"path": relpath, "error": "file_too_large", "bytes": byte_count},
                                    )
                                else:
                                    raw = base64.b64decode(src_data["data_b64"].encode("ascii"), validate=True)
                                    calc_src = hashlib.sha256(raw).hexdigest()
                                    if calc_src != src_data["sha256"]:
                                        resp = build_response_error("source_checksum_mismatch")
                                        log_event(
                                            audit_log,
                                            "file.move",
                                            src,
                                            dst,
                                            decision,
                                            "error",
                                            {"path": relpath, "error": "source_checksum_mismatch"},
                                        )
                                    else:
                                        stage_name = secrets.token_hex(8) + "-" + src_data["name"]
                                        stage_path = staging_dir / stage_name
                                        stage_path.write_bytes(raw)
                                        dst_agent = runtime / "agents" / f"{dst}.sock"
                                        dst_data = agent_call(
                                            dst_agent,
                                            args.token,
                                            {
                                                "op": "write_import",
                                                "name": src_data["name"],
                                                "data_b64": src_data["data_b64"],
                                            },
                                        )
                                        stage_path.unlink(missing_ok=True)
                                        if dst_data["sha256"] != calc_src:
                                            resp = build_response_error("dest_checksum_mismatch")
                                            log_event(
                                                audit_log,
                                                "file.move",
                                                src,
                                                dst,
                                                decision,
                                                "error",
                                                {"path": relpath, "error": "dest_checksum_mismatch"},
                                            )
                                        else:
                                            try:
                                                agent_call(src_agent, args.token, {"op": "delete_file", "path": relpath})
                                            except Exception as delete_exc:  # noqa: BLE001
                                                resp = build_response_error("move_partial_delete_failed")
                                                log_event(
                                                    audit_log,
                                                    "file.move",
                                                    src,
                                                    dst,
                                                    decision,
                                                    "partial",
                                                    {
                                                        "path": relpath,
                                                        "imported_path": dst_data["path"],
                                                        "error": str(delete_exc),
                                                    },
                                                )
                                            else:
                                                resp = build_response_ok(
                                                    src=src,
                                                    dst=dst,
                                                    path=relpath,
                                                    imported_path=dst_data["path"],
                                                    bytes=byte_count,
                                                    sha256=calc_src,
                                                )
                                                result = "ok" if decision == "allow" else "ask-allow"
                                                log_event(
                                                    audit_log,
                                                    "file.move",
                                                    src,
                                                    dst,
                                                    decision,
                                                    result,
                                                    {
                                                        "path": relpath,
                                                        "imported_path": dst_data["path"],
                                                        "bytes": byte_count,
                                                    },
                                                )

                    elif op == "status":
                        resp = build_response_ok(policy_file=str(policy_path), socket=str(socket_path), audit_log=str(audit_log))
                    else:
                        resp = build_response_error("unknown_op")

                except KeyError as exc:
                    resp = build_response_error(f"missing_field:{exc}")
                    log_event(audit_log, "request", "unknown", "unknown", "n/a", "error", {"error": str(resp["error"])})
                except Exception as exc:  # noqa: BLE001
                    resp = build_response_error(str(exc))
                    log_event(audit_log, "request", "unknown", "unknown", "n/a", "error", {"error": str(exc)})

                send_json_line(conn, resp)


if __name__ == "__main__":
    main()
