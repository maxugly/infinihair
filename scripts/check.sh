#!/usr/bin/env bash
# check.sh — static validation for CI and local use.
#
# Distro-agnostic: uses tools if they are already on PATH.
# Does not invoke apt, pacman, dnf, or any package manager.
#
# Required:  python3, bash
# Optional:  shellcheck, kpackagetool6
#            set CHECK_REQUIRE_KPACKAGE=1 to hard-fail without kpackagetool6
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail=0

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: required command not found: $1" >&2
    fail=1
    return 1
  fi
}

have() {
  command -v "$1" >/dev/null 2>&1
}

echo "==> required tools"
need python3 || true
need bash || true
if [[ "$fail" -ne 0 ]]; then
  exit 1
fi

echo "==> package (metadata + layout + .kwinscript)"
./scripts/package.sh
ARTIFACT="${ROOT}/crosshair.kwinscript"

echo "==> optional: shellcheck"
if have shellcheck; then
  mapfile -t sh_files < <(find scripts -maxdepth 1 -type f -name '*.sh' ! -empty | sort)
  if ((${#sh_files[@]})); then
    shellcheck -x "${sh_files[@]}"
  fi
else
  echo "skip: shellcheck not on PATH"
fi

echo "==> optional: kpackagetool6 install probe"
if have kpackagetool6; then
  # Never install from a tree that already lives under share/kwin/scripts —
  # kpackagetool treats that path specially and often fails. Use a temp copy.
  STAGE="$(mktemp -d "${TMPDIR:-/tmp}/infinihair-check.XXXXXX")"
  cleanup() { rm -rf "$STAGE"; }
  trap cleanup EXIT

  python3 - "$ARTIFACT" "$STAGE" <<'PY'
import sys
import zipfile
from pathlib import Path

artifact = Path(sys.argv[1])
stage = Path(sys.argv[2])
with zipfile.ZipFile(artifact) as zf:
    zf.extractall(stage)
PY

  PLUGIN_ID="$(python3 -c 'import json; print(json.load(open("metadata.json"))["KPlugin"]["Id"])')"

  if kpackagetool6 --type=KWin/Script --list 2>/dev/null | grep -qF "$PLUGIN_ID"; then
    # Already present (e.g. this repo is the live install tree): validate by
    # upgrading from the staged package directory.
    kpackagetool6 --type=KWin/Script --upgrade "$STAGE" \
      || kpackagetool6 --type=KWin/Script --install "$STAGE"
  else
    kpackagetool6 --type=KWin/Script --install "$STAGE"
  fi
  kpackagetool6 --type=KWin/Script --list | grep -E "$PLUGIN_ID|Infinite Crosshair"
else
  if [[ "${CHECK_REQUIRE_KPACKAGE:-0}" == "1" ]]; then
    echo "error: kpackagetool6 not on PATH (unset CHECK_REQUIRE_KPACKAGE to skip)" >&2
    exit 1
  fi
  echo "skip: kpackagetool6 not on PATH"
fi

echo "OK: all requested checks passed"
