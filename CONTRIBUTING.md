# 🤖 Agent Workflow Protocol

**DO NOT** start coding immediately. Follow this strict sequence for every task:

## Phase 1: Analysis
1.  **Read Context**: Load `constitution.md`, `spec.md`, and the relevant `agents.md` for the target directory.
2.  **Verify Scope**: Confirm the task fits within the `spec.md` functional requirements.
3.  **Plan**: Outline the files to be changed and the logic flow in a comment block or chat response *before* making changes.

## Phase 2: Implementation
1.  **Pattern Match**: Refer to `docs/IMPLEMENTATION_PATTERN.md` for the approved code structure.
2.  **Atomic Commits**: Make changes in small, logical chunks.
3.  **No Hardcoding**: Ensure all visual values are routed through `KWin.readConfig()`.

## Phase 3: Verification
1.  **Self-Correction**: Check your code against `constitution.md` (e.g., "Did I use a Timer? If yes, DELETE IT.").
2.  **Command Run**: Execute `./scripts/reload.sh` to verify the script loads without crashing KWin.
3.  **Log Check**: Confirm `journalctl` shows no QML errors.

## 🚫 Forbidden Actions
-   **Never** modify `metadata.json` without explicit user approval (breaks installation).
-   **Never** use `console.log` in production QML (use `console.debug` sparingly).
-   **Never** assume single-monitor geometry.
