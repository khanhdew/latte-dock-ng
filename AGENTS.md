# Latte Dock NG — Project Instructions & Memory

This file is loaded by pi at startup (context file) and holds the project's
rules and workflow, migrated from Claude Code's project memory
(`~/.claude/projects/-data-projects-latte-dock-ng/memory/`).

The Codex-facing durable memory is now maintained in `CODEX.md`. Read it first
for optimization work; `CLAUDE.md` remains as the historical compatibility
copy when detailed VM or release context is needed.

**Full memory details** (test-VM quirks, release workflow, known bugs & fixes):
read `CLAUDE.md` in the project root when relevant. The rules below are
always in effect.

## User Rules (always apply)

1. **No auto-commit / no auto-push** — Never commit or push git changes
   without explicit user approval. Commit and push are two SEPARATE approvals:
   after committing, ask "push?". "commit" alone never implies "push".
   Only use git read operations (diff, log, status) unless explicitly asked.
2. **English only** — All codebase content in English: commit messages,
   release notes/GitHub descriptions, code comments, documentation.
3. **No AI attribution** — Commit messages must NOT include `Co-Authored-By`,
   `Signed-off-by`, or similar AI attribution lines.
4. **Zero warnings on GCC and Clang** — Every build (debug, development,
   pre-commit, release) must compile with zero warnings and zero errors on
   BOTH compilers. When adding warning suppressions to
   `LatteCompilerWarnings.cmake`, document why.
5. **No regressions when removing dead code** — Trace all consumers before
   removal; keep working features intact even if they share code; verify
   compilation AND runtime behavior afterwards; check the debug log for new
   errors/warnings.
6. **Release requires autotest** — Before every release run
   `cd build && ctest --output-on-failure` (60+ source contract tests cover
   digital clock, systray, volume, appmenu, clipboard, separator/spacer,
   middle-click close, auto-pin on drag, scroll minimize).

## Development Debug & Retest Workflow

When testing changes to latte-dock-ng, follow this exact workflow:

1. **User-mode install modified code**
   ```bash
   cd /data/projects/latte-dock-ng && bash install.sh --user Debug >/tmp/latte-install-user.log 2>&1; tail -n 80 /tmp/latte-install-user.log
   ```

2. **Kill old latte-dock-ng process** (CAUTION: never use `pkill -f` in a
   command line that also contains "latte-dock-ng" elsewhere — it matches the
   shell's own command line and kills the shell; prefer `pkill -x latte-dock-ng`)
   ```bash
   pkill -f latte-dock-ng || true
   ```

3. **Remove old log file**
   ```bash
   rm -f /tmp/latte-ng.log
   ```

4. **Source user-mode environment variables**
   ```bash
   source ~/.config/latte-dock-ng/dev-env.sh
   ```

5. **Launch the USER-MODE Debug binary (~/.local/bin), NOT the system
   /usr/bin binary** (user explicitly corrected this; the dev-env.sh sourcing
   enables locally-built QML module overrides). Must survive shell timeout —
   use script + nohup + exec:
   ```bash
   cat > /tmp/launch-latte.sh << 'SCRIPT'
   #!/bin/bash
   source ~/.config/latte-dock-ng/dev-env.sh
   exec ~/.local/bin/latte-dock-ng --replace --debug > /tmp/latte-ng.log 2>&1
   SCRIPT
   chmod +x /tmp/launch-latte.sh
   nohup /tmp/launch-latte.sh > /dev/null 2>&1 &
   sleep 5
   ps aux | grep latte-dock-ng | grep -v grep || echo "DOCK FAILED TO START"
   ```

   Note: `bash install.sh --user Debug` already installs all plasmoid QML to
   ~/.local/share/plasma/plasmoids/ — a manual `cp` overlay of QML files is
   usually not needed. (If DESTDIR causes prefix duplication like
   ~/.local/home/user/.local/..., install directly with
   `cmake --install build --prefix ~/.local`.)

6. **Wait for user retest feedback**, then automatically analyze debug log for warnings/errors

7. **Analyze debug log** (`/tmp/latte-ng.log`) for warning/error entries. If found, record them as issues that need fixing.

8. **Do NOT commit or push** unless the user explicitly confirms. No auto-commit/push allowed without user permission.

## Quick references

- **Debug logging**: latte discards ALL output unless launched with `-d`
  (`--debug`). On the Fedora VM also pass `--log-file /tmp/latte-ng.log`
  plus `QT_LOGGING_RULES='latte*=true'` for latte's own qCDebug.
- **GitHub proxy**: if git push/ls-remote hangs, retry with
  `git -c http.proxy=http://127.0.0.1:10808 <cmd>` (try direct first).
- **Detailed memory**: VM environments (Debian 13 / Fedora 44 / Fedora docker),
  full release workflow (version bump → tag → GitHub release → overlay ebuild,
  Manifest generation rules), and known issues (appmenu empty slot,
  knscompat Badge qmldir, blur ghosting fix, hover-preview stutter research)
  are in `CLAUDE.md` — read it when working on releases, VM testing, or those
  areas.
