#!/usr/bin/env bash
# reload.sh — force the on-disk package body into the running KWin session.
#
# Why a temp copy? loadDeclarativeScript can keep a stale QML body bound to a
# plugin id / path for the life of the kwin_wayland process (e.g. after a
# debug load of a different file under the same id). Loading a fresh temp path
# busts that association.
set -euo pipefail

PLUGIN_ID="kwin-crosshair"
PKG_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/kwin/scripts/${PLUGIN_ID}"
MAIN_QML="${PKG_DIR}/contents/ui/main.qml"

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

if [[ ! -f "$MAIN_QML" ]]; then
  echo "error: package main.qml missing: $MAIN_QML" >&2
  exit 1
fi

if command -v kwriteconfig6 >/dev/null 2>&1; then
  kwriteconfig6 --file kwinrc --group Plugins --key "${PLUGIN_ID}Enabled" --type bool true
fi

"$QD" org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript "$PLUGIN_ID" >/dev/null 2>&1 || true

TMP="$(mktemp "${TMPDIR:-/tmp}/infinihair-live-XXXXXX.qml")"
cleanup() { rm -f "$TMP"; }
trap cleanup EXIT
cp "$MAIN_QML" "$TMP"

ID="$("$QD" org.kde.KWin /Scripting org.kde.kwin.Scripting.loadDeclarativeScript "$TMP" "$PLUGIN_ID")"
"$QD" org.kde.KWin /Scripting org.kde.kwin.Scripting.start >/dev/null

echo "reloaded ${PLUGIN_ID} (load id=${ID}, via ${TMP})"
"$QD" org.kde.KWin /Scripting org.kde.kwin.Scripting.isScriptLoaded "$PLUGIN_ID" | awk '{print "isScriptLoaded="$0}'
