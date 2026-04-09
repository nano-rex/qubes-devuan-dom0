#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ICON_SRC="$REPO_DIR/icons/aq-manager.svg"

if [[ ! -d "$REPO_DIR/assets" || ! -f "$ICON_SRC" ]]; then
  printf "Missing desktop assets or icon in repository.\n" >&2
  exit 1
fi

APP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
ICON_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/scalable/apps"
mkdir -p "$APP_DIR" "$ICON_DIR"

ICON_DST="$ICON_DIR/aq-manager.svg"

cp "$ICON_SRC" "$ICON_DST"
chmod 0644 "$ICON_DST"

for tpl in "$REPO_DIR"/assets/*.desktop; do
  [[ -f "$tpl" ]] || continue
  name="$(basename "$tpl")"
  dst="$APP_DIR/$name"
  sed "s|__REPO__|$REPO_DIR|g" "$tpl" >"$dst"
  chmod 0644 "$dst"
done

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -q "${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor" >/dev/null 2>&1 || true
fi

cat <<EOF
Installed desktop launcher:
  desktops: $APP_DIR/aq-*.desktop
  icon:    $ICON_DST
EOF
