# Latte Dock NG — Codex Project Memory

This file is the Codex-facing project memory migrated from `CLAUDE.md` and
the historical Claude Code project memory. `CLAUDE.md` remains available for
backward compatibility; new Codex work should update this file when durable
project knowledge changes.

## Working rules

- Keep all repository text in English, including comments and commit messages.
- Do not add AI attribution to commits.
- GCC and Clang builds must complete with zero warnings and zero errors.
- Before removing code, trace all consumers and verify build plus runtime behavior.
- Release work requires `cd build && ctest --output-on-failure` before versioning.
- The active optimization branch is `perf/memory-cpu-optimization-v2`, not
  `main`. For this user-requested optimization run, completed steps may be
  committed and pushed automatically. This is an explicit exception to the
  normal approval rule in `AGENTS.md`.

## Baseline and architecture

- Project: Latte Dock NG, Qt 6 / KDE Frameworks 6 / Plasma 6, C++17.
- The application is still one large executable assembled by `app/CMakeLists.txt`.
- Large runtime sources include `layoutmanager.cpp`, `containmentinterface.cpp`,
  `view.cpp`, `storage.cpp`, and `AppletItem.qml`.
- A host baseline of the system release binary measured approximately 553 MiB
  RSS, 373 MiB PSS, 281 MiB anonymous memory, seven threads, and 67 file
  descriptors. The largest mapping was an approximately 175 MiB anonymous
  region. Re-measure after installing a debug build before claiming runtime
  memory improvements.
- The current system Latte is the latest release ebuild, not this branch. Do
  not restart it automatically for branch validation.
- Use `-j8` for project builds unless a command has a specific resource limit.
- User configuration intentionally disables window previews and keeps only the
  normal tooltip. Treat preview-window rendering as an inactive path unless
  the user explicitly enables it for a regression check.

## Completed optimization steps

- Deferred callback lambdas now use QObject context objects; applet hit
  testing guards null quick items.
- Indicator package import/removal is asynchronous and non-blocking.
- CI covers GCC and Clang and applies a 120-second autotest timeout.
- PulseAudio PID matches expire, idle cleanup timers stop, and stream lookups
  use indexes for exact PID/application keys.
- Headless QML smoke tests avoid synchronous icon-loader and PlasmaCore
  initialization; fake PlasmaCore components cover the required smoke paths.
- Offscreen/minimal environments defer KIconLoader, KDirWatch, KWindowShadow,
  KApplicationTrader, and SVG desktop integration. QML tests use writable
  temporary XDG directories and skip PlasmaQuick dialogs that require a real
  desktop platform.
- High-resolution wheel task activation reuses the task index list for all
  increments in one wheel event.
- Task edit-mode polling is one root timer instead of one repeating timer per
  task delegate.
- Idle task mouse moves return before drag coordinate mapping and reorder work.
- Disabled preview/highlight configurations skip inactive preview-state checks
  during task hover while retaining tooltip and auto-scroll behavior.
- Layout ID allocation builds a `QSet` once instead of repeatedly scanning two
  `QStringList` instances.
- The task preview delegate is now loaded only when `showPreviews` is enabled;
  null guards preserve the disabled-preview path. This needs real Wayland
  validation for preview toggling and hover behavior.
- Full GCC and Clang autotest suites currently contain 39 tests and pass 39/39.

Recent optimization commits are on the active branch; inspect `git log` for
the exact commit list and push status.

## Remaining optimization queue

### Requires manual Wayland retest

1. Replace the separate preview `QQuickWindow`/`LatteCore.Dialog` with an
   inline panel-window preview. This is the largest known UI stutter source:
   mapping a Wayland surface can block the Qt Quick render pipeline. Current
   thumbnail preview behavior is intentionally suppressed while Plasma 6
   thumbnail support is unstable. Candidate files are
   `plasmoid/package/contents/ui/main.qml`, `TaskItem.qml`,
   `app/view/parabolic.cpp`, and `app/view/parabolic.h`.
   The preview delegate itself is now lazy-loaded. This remains deferred while
   the user's normal configuration keeps previews disabled.
2. Revisit the bounce-end zoom micro-stutter. A safe fix needs a layout-change
   hook that re-triggers the existing parabolic calculation without re-entering
   the removal-animation relay.
3. Consider lazy creation of the hidden group-dialog compatibility object and
   preview delegate only after measuring startup RSS and verifying task-manager
   backend behavior.

### Requires profiling before code changes

1. Split the monolithic application target into focused libraries or object
   libraries; this is primarily a build/architecture optimization and must be
   benchmarked for incremental build and link costs.
2. Evaluate Release-only LTO/IPO after recording binary size, startup time,
   RSS, and package build time on GCC and Clang.
3. Add model-level caching only after profiling task-model updates; avoid
   caching grouped task indexes without reliable invalidation for rowsInserted,
   rowsRemoved, modelReset, and layoutChanged.

## Known behavior and compatibility notes

- Empty appmenu slots with no menu-bearing window are expected HiddenStatus
  behavior, not a regression.
- The KNS compat `Badge` qmldir generation fix is already present; preserve
  compatibility with both old and merged Kirigami module layouts.
- Blur ghosting defaults and gates are intentionally conservative; retain the
  existing source-contract tests.
- Debian Plasma 6.3 lacks a filesystem `org.kde.plasma.plasmoid` QML module.
  Register the module lazily and never use an attached-type stub that breaks
  Behavior resolution.
- Fedora Wayland runs natively even with a minimal environment. Use
  `--log-file` and `QT_LOGGING_RULES='latte*=true'` for useful logs.
- In test VMs use `pkill -x latte-dock-ng`; never use a broad `pkill -f`.

## Manual retest handoff

For a branch runtime check, install user Debug code, source
`~/.config/latte-dock-ng/dev-env.sh`, launch `~/.local/bin/latte-dock-ng --replace
--debug`, and inspect `/tmp/latte-ng.log`. Validate task hover/drag, wheel task
cycling, edit mode, previews, launcher bounce, panel shadows, and layout import.
After feedback, analyze new warnings/errors before applying the next risky
change.
