#!/usr/bin/env python3
import argparse
import sys
import tkinter as tk
from tkinter import messagebox


def main():
    parser = argparse.ArgumentParser(description="GUI confirmation for aq-policyd")
    parser.add_argument("action")
    parser.add_argument("src")
    parser.add_argument("dst")
    args = parser.parse_args()

    root = tk.Tk()
    root.withdraw()
    ok = messagebox.askyesno(
        title="AQ Policy Confirmation",
        message=f"Allow action?\n\nAction: {args.action}\nSource: {args.src}\nDestination: {args.dst}",
        icon="warning",
    )
    root.destroy()
    if ok:
        print("allow")
        return 0
    print("deny")
    return 1


if __name__ == "__main__":
    sys.exit(main())
