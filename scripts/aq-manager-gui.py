#!/usr/bin/env python3
import argparse
import subprocess
import tkinter as tk
from tkinter import ttk
from tkinter import messagebox, simpledialog
from pathlib import Path


class ManagerGui:
    def __init__(self, root, root_dir: Path, service_dir: Path):
        self.root = root
        self.root_dir = root_dir
        self.service_dir = service_dir
        self.manager = Path(__file__).resolve().parent / "aq-manager.py"
        self.token_var = tk.StringVar(value="")
        self.search_var = tk.StringVar(value="")
        self.role_filter_var = tk.StringVar(value="all")
        self.output = None
        self.tree = None
        self.rows = []
        self.build()
        self.refresh_list()
        self.refresh_status()

    def run_manager(self, args):
        cmd = [
            str(self.manager),
            "--root-dir",
            str(self.root_dir),
            "--service-dir",
            str(self.service_dir),
        ] + args
        proc = subprocess.run(cmd, capture_output=True, text=True, check=False)
        out = (proc.stdout or "").strip()
        err = (proc.stderr or "").strip()
        if proc.returncode != 0:
            raise RuntimeError(err or out or "command failed")
        return out

    def log(self, text):
        self.output.configure(state="normal")
        self.output.insert(tk.END, text + "\n")
        self.output.see(tk.END)
        self.output.configure(state="disabled")

    def selected_qube(self):
        row_id = self.tree.focus()
        if not row_id:
            raise RuntimeError("select a qube first")
        vals = self.tree.item(row_id, "values")
        if not vals:
            raise RuntimeError("select a qube first")
        return vals[0]

    def render_rows(self):
        self.tree.delete(*self.tree.get_children())
        needle = self.search_var.get().strip().lower()
        role_filter = self.role_filter_var.get().strip().lower()
        for row in self.rows:
            hay = f"{row['name']} {row['template']} {row['role']}".lower()
            if needle and needle not in hay:
                continue
            if role_filter != "all" and role_filter and role_filter != row["role"].lower():
                continue
            status = row.get("status", "unknown")
            tag = "unknown"
            lower = status.lower()
            if "run:" in lower:
                tag = "running"
            elif "down:" in lower:
                tag = "stopped"
            self.tree.insert("", tk.END, values=(row["name"], row["template"], row["role"], status), tags=(tag,))

    def refresh_list(self):
        out = self.run_manager(["list"])
        lines = out.splitlines()[1:]
        self.rows = []
        for line in lines:
            parts = line.split("\t")
            if len(parts) < 3:
                continue
            self.rows.append(
                {
                    "name": parts[0],
                    "template": parts[1],
                    "role": parts[2],
                    "status": "unknown",
                }
            )
        self.render_rows()

    def refresh_status(self):
        try:
            out = self.run_manager(["status"])
            status_map = {}
            for line in out.splitlines():
                parts = line.split("\t", 1)
                if len(parts) == 2:
                    status_map[parts[0]] = parts[1]
            for row in self.rows:
                row["status"] = status_map.get(row["name"], "unknown")
            self.render_rows()
            self.log("[status] refreshed")
        except Exception as exc:  # noqa: BLE001
            self.log(f"[status error] {exc}")

    def control(self, op):
        try:
            qube = self.selected_qube()
            out = self.run_manager([op, qube])
            self.log(f"[{op} {qube}] {out or 'ok'}")
        except Exception as exc:  # noqa: BLE001
            messagebox.showerror("Error", str(exc))

    def clip_copy(self):
        try:
            qube = self.selected_qube()
            token = self.run_manager(["clip-copy", qube]).strip()
            self.token_var.set(token)
            self.log(f"[clip-copy {qube}] token={token}")
        except Exception as exc:  # noqa: BLE001
            messagebox.showerror("Error", str(exc))

    def clip_paste(self):
        try:
            qube = self.selected_qube()
            token = self.token_var.get().strip()
            if not token:
                token = simpledialog.askstring("Token", "Paste token:")
                if not token:
                    return
            out = self.run_manager(["clip-paste", qube, "--token", token])
            self.log(f"[clip-paste {qube}] {out or 'ok'}")
            self.token_var.set("")
        except Exception as exc:  # noqa: BLE001
            messagebox.showerror("Error", str(exc))

    def file_copy(self, move=False):
        try:
            src = self.selected_qube()
            dst = simpledialog.askstring("Destination Qube", "Destination qube name:")
            if not dst:
                return
            relpath = simpledialog.askstring("Source Path", "Source relative file path (inside qube files/):")
            if not relpath:
                return
            op = "move-to" if move else "copy-to"
            out = self.run_manager([op, src, dst, relpath])
            label = "move" if move else "copy"
            self.log(f"[{label} {src} -> {dst}] {out or 'ok'}")
        except Exception as exc:  # noqa: BLE001
            messagebox.showerror("Error", str(exc))

    def build(self):
        self.root.title("AQ Manager (Minimal)")
        self.root.geometry("860x520")

        top = tk.Frame(self.root)
        top.pack(fill="x", padx=8, pady=8)

        tk.Label(top, text=f"root: {self.root_dir}").pack(side="left")
        tk.Button(top, text="Refresh", command=self.refresh_status).pack(side="right", padx=4)
        tk.Button(top, text="Reload Qubes", command=self.refresh_list).pack(side="right", padx=4)

        filter_row = tk.Frame(self.root)
        filter_row.pack(fill="x", padx=8, pady=2)
        tk.Label(filter_row, text="Search:").pack(side="left")
        search_entry = tk.Entry(filter_row, textvariable=self.search_var)
        search_entry.pack(side="left", fill="x", expand=True, padx=6)
        search_entry.bind("<KeyRelease>", lambda _e: self.render_rows())
        tk.Label(filter_row, text="Role:").pack(side="left", padx=(8, 0))
        role_combo = ttk.Combobox(filter_row, width=18, state="readonly", textvariable=self.role_filter_var)
        role_combo["values"] = ("all", "network bridge", "usb proxy", "firewall", "whonix gateway (netvm)")
        role_combo.current(0)
        role_combo.pack(side="left", padx=6)
        role_combo.bind("<<ComboboxSelected>>", lambda _e: self.render_rows())

        middle = tk.Frame(self.root)
        middle.pack(fill="both", expand=True, padx=8, pady=4)

        self.tree = ttk.Treeview(
            middle,
            columns=("name", "template", "role", "status"),
            show="headings",
            selectmode="browse",
        )
        self.tree.heading("name", text="Qube")
        self.tree.heading("template", text="Template")
        self.tree.heading("role", text="Role")
        self.tree.heading("status", text="Status")
        self.tree.column("name", width=140, anchor="w")
        self.tree.column("template", width=160, anchor="w")
        self.tree.column("role", width=220, anchor="w")
        self.tree.column("status", width=250, anchor="w")
        self.tree.tag_configure("running", background="#d9fbe8")
        self.tree.tag_configure("stopped", background="#fde2e1")
        self.tree.tag_configure("unknown", background="#f1f5f9")
        self.tree.pack(side="left", fill="both", expand=True)

        scroll = ttk.Scrollbar(middle, orient="vertical", command=self.tree.yview)
        self.tree.configure(yscrollcommand=scroll.set)
        scroll.pack(side="left", fill="y")

        buttons = tk.Frame(middle)
        buttons.pack(side="left", fill="y", padx=8)
        tk.Button(buttons, text="Start", width=14, command=lambda: self.control("start")).pack(pady=2)
        tk.Button(buttons, text="Stop", width=14, command=lambda: self.control("stop")).pack(pady=2)
        tk.Button(buttons, text="Restart", width=14, command=lambda: self.control("restart")).pack(pady=2)
        tk.Button(buttons, text="File Copy", width=14, command=lambda: self.file_copy(False)).pack(pady=12)
        tk.Button(buttons, text="File Move", width=14, command=lambda: self.file_copy(True)).pack(pady=2)
        tk.Button(buttons, text="Clip Copy", width=14, command=self.clip_copy).pack(pady=12)
        tk.Button(buttons, text="Clip Paste", width=14, command=self.clip_paste).pack(pady=2)

        token_frame = tk.Frame(self.root)
        token_frame.pack(fill="x", padx=8)
        tk.Label(token_frame, text="Clipboard token:").pack(side="left")
        tk.Entry(token_frame, textvariable=self.token_var).pack(side="left", fill="x", expand=True, padx=6)

        self.output = tk.Text(self.root, height=10, state="disabled")
        self.output.pack(fill="both", expand=False, padx=8, pady=8)


def main():
    parser = argparse.ArgumentParser(description="Minimal AQ manager GUI")
    parser.add_argument("--root-dir", default="/var/lib/antix-qubes")
    parser.add_argument("--service-dir", default=None)
    args = parser.parse_args()

    root_dir = Path(args.root_dir).resolve()
    service_dir = Path(args.service_dir).resolve() if args.service_dir else (root_dir / "runit")

    root = tk.Tk()
    ManagerGui(root, root_dir, service_dir)
    root.mainloop()


if __name__ == "__main__":
    main()
