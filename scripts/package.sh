#!/usr/bin/env bash
# package.sh — build a distributable .kwinscript (ZIP) for KWin.
#
# Distro-agnostic: requires only python3 on PATH (stdlib: json, zipfile, xml).
# Does not invoke apt, pacman, dnf, or any package manager.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

OUT="${1:-crosshair.kwinscript}"

if ! command -v python3 >/dev/null 2>&1; then
  echo "error: python3 is required (stdlib only; no pip packages)" >&2
  exit 1
fi

python3 - "$OUT" <<'PY'
import json
import sys
import zipfile
from pathlib import Path

out = Path(sys.argv[1])
root = Path(".")

meta_path = root / "metadata.json"
if not meta_path.is_file():
    raise SystemExit("missing required file: metadata.json")

try:
    meta = json.loads(meta_path.read_text(encoding="utf-8"))
except json.JSONDecodeError as e:
    raise SystemExit(f"metadata.json: invalid JSON: {e}") from e

if meta.get("X-Plasma-API") != "declarativescript":
    raise SystemExit('metadata.json: X-Plasma-API must be "declarativescript"')
if meta.get("KPackageStructure") != "KWin/Script":
    raise SystemExit('metadata.json: KPackageStructure must be "KWin/Script"')

plugin = meta.get("KPlugin") or {}
if not plugin.get("Id"):
    raise SystemExit("metadata.json: KPlugin.Id is required")

main_script = meta.get("X-Plasma-MainScript", "ui/main.qml")
main_path = Path("contents") / main_script
if not main_path.is_file():
    raise SystemExit(f"missing main script from metadata: {main_path}")

required = [
    Path("contents/code/main.js"),
    Path("contents/ui/Crosshair.qml"),
]
for path in required:
    if not path.is_file():
        raise SystemExit(f"missing required file: {path}")

xml_path = Path("contents/config/main.xml")
if xml_path.is_file() and xml_path.stat().st_size > 0:
    import xml.etree.ElementTree as ET

    try:
        ET.parse(xml_path)
    except ET.ParseError as e:
        raise SystemExit(f"contents/config/main.xml: invalid XML: {e}") from e

# Runtime payload only (no agent docs, empty stubs, or VCS noise)
include_files: list[Path] = [
    Path("metadata.json"),
    Path("contents/code/main.js"),
    Path("contents/ui/main.qml"),
    Path("contents/ui/Crosshair.qml"),
]
if xml_path.is_file() and xml_path.stat().st_size > 0:
    include_files.append(xml_path)
ui_path = Path("contents/config/main.ui")
if ui_path.is_file() and ui_path.stat().st_size > 0:
    include_files.append(ui_path)

for path in include_files:
    if not path.is_file():
        raise SystemExit(f"missing required package file: {path}")

if out.exists():
    out.unlink()

with zipfile.ZipFile(out, "w", compression=zipfile.ZIP_DEFLATED) as zf:
    for path in include_files:
        zf.write(path, path.as_posix())

print(f"Created {out} ({out.stat().st_size} bytes)")
for path in include_files:
    print(f"  + {path.as_posix()}")
PY
