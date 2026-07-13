# Troubleshooting — Infinite Crosshair (infinihair)

Plugin id: `kwin-crosshair` · Live status: [STATUS.md](../STATUS.md)

## Useful commands

```bash
# Is the script loaded?
qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.isScriptLoaded kwin-crosshair

# What body is running? (look for ready build=)
journalctl --user -b --no-pager | rg InfiniteCrosshair | tail -40

# Saved config
grep -A30 '\[Script-kwin-crosshair\]' ~/.config/kwinrc

# Force current package into the session
cd ~/.local/share/kwin/scripts/crosshair   # or your clone
./scripts/reload.sh
```

## Common issues

| Issue | Solution |
|-------|----------|
| **Lines not visible** | Enable the script in System Settings → KWin Scripts. Check journal for `InfiniteCrosshair ready build=`. |
| **Settings / color do nothing** | Confirm `isScriptLoaded` is `true`. Apply only writes `kwinrc` if something is running to read it. |
| **Works after `reload.sh`, broken after disable/re-enable** | Long-lived `kwin_wayland` can keep a stale package-path QML body. Run `./scripts/reload.sh` or restart KWin once after upgrades (`kwin_wayland --replace`). |
| **Many Configure windows** | Upstream KWin Scripts KCM (`Module::configure` always `new KCMultiDialog()`). Affects all configurable scripts. Close extras; one gear click. See [bug-multi-config-dialog.md](../specs/bug-multi-config-dialog.md). |
| **Toggle not working** | Default **Meta+Shift+X**. Rebind: System Settings → Keyboard → Shortcuts → search *Infinite Crosshair*. |
| **Offset guides wrong / vanish on drag** | Keep **Auto-align guides to window borders** checked. Need sticky builds (`offset5`+). Hover a window, then drag — guides should stick for the whole move. Manual: **Meta+Shift+B** / **V** / **H**; **Meta+Shift+C** clears. |
| **Main crosshair stays, guides go away** | Primary is cursor-only (always draws when enabled). Guides need a window target. Mid-drag vanish was a hit-test bug; fixed with sticky + `move`/`resize` tracking in `offset5`+. |
| **Wrong tick scale** | Set **Units** (imperial/metric) and the matching diagonal field. Inches and cm are stored separately and are never auto-converted. |
| **Both diagonal boxes always visible** | Genericscripted Configure UI cannot hide fields when Units changes. Only the field matching the selected units is used. |

## Development reloads

| Path | Behavior |
|---|---|
| `./scripts/reload.sh` | Loads a unique temp QML copy (busts session cache) |
| System Settings enable | Uses package path `…/kwin-crosshair/contents/ui/main.qml` |

If those disagree after an upgrade, restart KWin once so the package path recompiles.

## Related docs

- [STATUS.md](../STATUS.md) — current build / accepted features  
- [offset-line-mode.md](../specs/offset-line-mode.md) — guides  
- [tick-units.md](../specs/tick-units.md) — imperial / metric  
- [bug-multi-config-dialog.md](../specs/bug-multi-config-dialog.md) — Configure stacking  
