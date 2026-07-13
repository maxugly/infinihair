#!/usr/bin/env bash
# reload.sh — force the on-disk package body into the running KWin session.
#
# Why a temp copy? KWin can keep a stale QML body bound to a plugin id / path
# for the life of the kwin_wayland process. Disable+re-enable in System Settings
# often reuses that cache (black crosshair / dead config). Loading a fresh temp
# path busts the association without restarting KWin.
set -euo pipefail

PLUGIN_ID="kwin-crosshair"
PKG_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/kwin/scripts/${PLUGIN_ID}"
MAIN_QML="${PKG_DIR}/contents/ui/main.qml"
DEV_MAIN="$(cd "$(dirname "$0")/.." && pwd)/contents/ui/main.qml"

QD=""
for c in qdbus6 qdbus-qt6 qdbus; do
  if command -v "$c" >/dev/null 2>&1; then
    QD="$c"
    break
  fi
done
if [[ -z "$QD" ]]; then
  echo "error: qdbus6/qdbus-qt6/qdbus not found" >&2
  exit 1
fi

# Prefer package path; fall back to dev tree (scripts/crosshair).
if [[ ! -f "$MAIN_QML" && -f "$DEV_MAIN" ]]; then
  echo "warn: package main.qml missing; using dev tree" >&2
  MAIN_QML="$DEV_MAIN"
fi
if [[ ! -f "$MAIN_QML" ]]; then
  echo "error: package main.qml missing: $MAIN_QML" >&2
  exit 1
fi

# Keep installed package in sync with dev tree when both exist.
if [[ -f "$DEV_MAIN" && -d "$PKG_DIR/contents/ui" && "$DEV_MAIN" -nt "$MAIN_QML" ]]; then
  cp "$DEV_MAIN" "$MAIN_QML"
  echo "synced package main.qml from dev tree"
fi

if command -v kwriteconfig6 >/dev/null 2>&1; then
  kwriteconfig6 --file kwinrc --group Plugins --key "${PLUGIN_ID}Enabled" --type bool true
fi

"$QD" org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript "$PLUGIN_ID" >/dev/null 2>&1 || true
sleep 0.15

TMP="$(mktemp "${TMPDIR:-/tmp}/infinihair-live-XXXXXX.qml")"
# Keep temp for the life of the script process (inode must stay readable).
# Previous versions deleted on exit and risked races; leave the file.
cp "$MAIN_QML" "$TMP"

ID="$("$QD" org.kde.KWin /Scripting org.kde.kwin.Scripting.loadDeclarativeScript "$TMP" "$PLUGIN_ID")"
"$QD" org.kde.KWin /Scripting org.kde.kwin.Scripting.start >/dev/null

SUM="$(command -v sha256sum >/dev/null && sha256sum "$MAIN_QML" | awk '{print $1}' | cut -c1-12 || echo unknown)"
echo "reloaded ${PLUGIN_ID} (load id=${ID}, via ${TMP}, sha=${SUM})"
"$QD" org.kde.KWin /Scripting org.kde.kwin.Scripting.isScriptLoaded "$PLUGIN_ID" | awk '{print "isScriptLoaded="$0}'
