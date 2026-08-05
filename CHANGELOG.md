## [v1.2.37] - 2026-08-05

### Fixed
- The animation speed setting (Effects > Animations, x1/x2/x3) is now
  actually perceptible: the containment maps x1/x2/x3 to 1x/2x/3x
  animation durations matching the plasmoid's standalone semantics, and
  the inverted EffectsConfig buttons were corrected (issue #39).
- Transparent icons (e.g. the Colloid theme) no longer show a ghost of
  the original-size icon while a widget zooms: the applet drop shadow
  now fades out smoothly during the zoom instead of rendering a
  duplicated copy behind the scaled applet (issue #38).
- Widgets whose zoom is disabled no longer participate in the parabolic
  wave, so the task icon at the widget boundary restores its size
  immediately when the mouse leaves.
- Release builds no longer emit an unused-variable warning in the debug
  message filter.

### Added
- New "Zoom widgets on hovering" option (Behavior > Items): when
  disabled, external widgets keep their original size on hover so their
  icons stay sharp, while task icons and launchers still zoom.
- The default layout templates no longer include the mail (Thunderbird)
  launcher.

### Changed
- The durationTime config default is now x1 (normal) instead of x2.

### Tests
- New source-contract tests cover the animation speed mapping, the
  EffectsConfig button values, the applet shadow fade, the widget-zoom
  option scope, and the default template launchers.

# Changelog

All notable changes to Latte Dock NG are documented in this file.

## [v1.2.36] - 2026-08-02

### Fixed
- Autostart no longer breaks silently when the XDG autostart desktop
  file disappears (e.g. removed by a package uninstall, depclean or a
  failed update): startup now restores it and logs a warning instead of
  leaving the dock unlaunched on every login.
- Autostart updates are staged: the replacement file is copied next to
  the working entry and swapped in only after a successful copy, so a
  failed copy can never delete the existing entry.
- Autostart failures (missing system desktop file, failed copy) now log
  warnings instead of failing silently.

### Tests
- New importer-logic and source-contract tests cover the autostart
  self-heal and staged-update behavior.

## [v1.2.35] - 2026-08-02

### Fixed
- Fixed logout, reboot and shutdown hanging on Plasma 6.7: KWin's
  session shutdown waits for every xdg_toplevel window to close, and the
  dock views ignored the compositor close request until the
  session-ending flag was set. The views are now unmapped as soon as the
  logout is announced and restored if the user cancels.
- Filtered cosmetic Plasma theme SVG warnings from the debug log.
- Mirrored system Kirigami template qmldir files in the KNS compat
  overrides.

### Build
- CI now builds and runs the full autotest suite (ctest) on every push,
  pull request and release tag.
- The Debian 13 (trixie) deb now carries the `+deb13u1` revision marker,
  per the Debian convention for stable-specific builds; the testing/sid
  build keeps the plain `-1` name.
- Documented the two deb variants in the README and installation docs.

## [v1.2.34] - 2026-08-01

### Fixed
- Lowered the minimum Plasma version from 6.5.0 to 6.3.0; Plasma 6.3
  (Debian 13 trixie) is now verified as the minimum supported version,
  development happens on Plasma 6.5+ / Qt 6.11.
- Fixed dock indicators disappearing on Plasma 6.3: the
  org.kde.plasma.plasmoid QML module is only registered lazily by
  PlasmaQuick on that version, so indicator components are now created on
  first access instead of at View construction.
- Fixed the latte_indicator package structure plugin shipping without
  embedded metadata on Qt 6.8 (moc macro expansion through the compat
  forwarding header), which made KPackage unable to resolve the
  "Latte/Indicator" structure.
- Fixed KNS dialog compatibility overrides never being created on
  Kirigami 6.12+ where org.kde.kirigami.controls was merged into the
  main module.
- Added infinite-loop and recursion guards across the codebase; made the
  guards regression-safe and repaired distro install contracts.
- Restored synchronous deletion in layout unload paths; added contracts
  keeping the behavior stable.
- Restored KDE compiler enforcement (-Wall, QT_NO_CAST_*, QT_NO_KEYWORDS)
  and fixed all norm violations; both GCC and Clang build warning-free.
- Fixed the latte-dock icon reference to the name installed by ECM.
- Removed a set-but-unused variable that triggered -Wunused-but-set-variable.

### Changed
- Concurrent parabolic zoom and launcher bounce animation.
- Bounce animation replaced with a parabolic bounce.

### Build
- The release .deb is now built on Debian 13 (trixie) with
  dpkg-shlibdeps versioned dependencies, so the package installs on
  Debian 13 stable, testing, sid and Ubuntu 26.04+.
- Linked Qt6::Quick in toolsunittest so tests build on distros with
  arch-triplet Qt header layouts.

### Test
- Added contract tests for the infinite-loop guard follow-ups and the
  layout unload deletion behavior; registered the plasmoid module stub
  for the smoke tests on Plasma 6.3; forced KConfigGui linkage in
  schemecolorsunittest for --as-needed linkers. Full ctest suite passes
  on Plasma 6.3 (Debian 13) and Plasma 6.5+ with both GCC and Clang.

## [v1.2.17] - 2026-06-28

### Fixed
- Fixed third-party clocks (e.g. Colorful Digital Clock) still overflowing
  after the v1.2.16 cap increase.  Clock detection now matches any plugin
  name containing "clock" (excluding "analogclock") instead of only
  "digitalclock".  The natural-width cap is further increased from 5× to
  8× maxIconSize for the widest clock representations.
- Added signal-driven slot width updates via onImplicitWidthChanged and
  onChildrenRectChanged so the slot resizes immediately when clock text
  content changes (no more 2 s polling delay).
- Added a height cap (3× maxIconSize) to guard against runaway compact
  representation heights (e.g. h=1352 from Colorful Digital Clock).
- Fixed "Unable to assign [undefined] to int" startup warning from
  MyView.qml:37 with a safeInt() helper.

### Test
- Added 15 boundary regression tests covering previously untested
  special-cased logic: indicator factory builtin exclusion, wayland
  window whitelist, context menu wiring, layout manager cleanup,
  separator plugin constants, export model applet list, latte package
  branching, indicator type remapping, message suppression, internal
  view splitter guards, fallback tracked windows, constraint hints,
  launcher/drag-drop detection, plasmoid wheel bypass, and compact
  applet fallback sizing.  Test suite: 61 → 76.

## [v1.2.16] - 2026-06-28

### Fixed
- Fixed digital clock widget overflowing past the dock edge and overlapping
  neighboring icons when using long date formats.  The natural-width cap was
  increased from 3× to 5× maxIconSize to accommodate formats like "Saturday,
  June 27, 2026 10:30 AM".
- Fixed "Unable to assign [undefined] to int" startup warning from
  MyView.qml:37.  Added a safeInt() helper that validates bridge-host
  property values before assignment, preventing undefined from reaching
  int-typed properties during initialization and bridge transitions.
- Guarded LayerShellQt::Window::setScreen with CMake feature detection to
  prevent build failures when the LayerShellQt version lacks the method.

### Test
- Added 60+ source contract regression tests covering widget-specific
  special handling: digital clock sizing, middle-click close active window,
  auto-pin on drag, scroll minimize/unmaximize, system tray guards, volume
  and application menu popup sizing, clipboard/digital-clock error
  suppression, applet insertion boundaries, separator/spacer detection,
  and MyView int property guard.

## [v1.2.15] - 2026-06-27

### Fixed
- Fixed systemsettings and other KDE applications crashing on startup due to KNS compat QML import paths leaking into child processes via environment variables. All QML and plugin import paths are now engine-scoped using `addImportPath()` and `addLibraryPath()` instead of `qputenv()`.
- Fixed `uninstall.sh` to clean up KNS compat QML overrides from both old (`~/.local/lib*/qt6/qml/`) and new private paths during uninstall.

## [v1.2.14] - 2026-06-26

### Fixed
- Fixed middle-click close active window not working on empty dock areas.
- Fixed scroll-down minimize not working for ScrollToggleMinimized action.
- Fixed auto-pin when dragging non-pinned tasks into launcher area.
- Fixed drag-and-drop icon reordering stability and visual feedback.

## [v1.2.13] - 2026-06-26

### Fixed
- Fixed KNS dialog compatibility QML overrides being written to Qt's global user QML path (`~/.local/lib*/qt6/qml/`), which could crash incompatible KDE applications like systemsettings on startup.
- Fixed `uninstall.sh` to clean up KNS compat overrides from both old (global QML) and new (private) paths during uninstall.

## [v1.2.12] - 2026-06-25

### Fixed
- Fixed widget hide/show synchronization across all screens during removal and undo.
- Fixed Plasma panel overlap for vertical docks on multi-screen Wayland setups.

## [v1.2.11] - 2026-06-23

### Fixed
- Fixed all-screens dock synchronization for widget removal, widget add, drag-and-drop widget placement, applet ordering, and launcher/menu-backed applets.
- Fixed Wayland always-visible dock strut reservations so cloned docks reserve space on their own screen instead of affecting the primary screen.
- Refined session shutdown handling so Latte quits after committed shutdown blockers close while still surviving cancelled logout attempts.
- Fixed duplicate instance handling to exit cleanly with return 0 instead of calling qGuiApp->exit(), and moved SharedQmlEngine creation after the single-instance guard to avoid unnecessary teardown.

## [v1.2.10] - 2026-06-21

### Fixed
- Session shutdown handling now stays alive when logout is cancelled while still quitting cleanly after blocking windows close during committed shutdown.
- Modern dock background shadows now default to the same compact 6px effect as explicitly setting Appearance > Background > Shadow to 6px.

## [v1.2.9] - 2026-06-19

### Fixed
- Task icons now refresh immediately when the system icon theme changes, including switching back to the default Breeze icon theme.
- Audio stream badges now scale with task icon zoom while preserving their relative position.

## [v1.1.26] - 2026-06-14

### Fixed
- Analog clock widget no longer produces extra empty space on both sides when added to the dock. The clock was incorrectly classified as a text-heavy applet alongside the digital clock, causing an oversized slot allocation.

### Changed
- Wrap global-scope classes in namespace Latte to prevent symbol collisions
- Replace string-based SIGNAL()/SLOT() macros with type-safe &Class::method syntax
- Add override keyword to 46 virtual destructors for compiler-enforced signature checking
- Replace [&] lambda captures with [this] in connect callbacks to prevent dangling references
- Replace C-style casts with static_cast<> for type safety
- Centralize scattered plugin name strings into shared app/pluginids.h header
- Add required keyword to critical QML properties for clear runtime errors
- Create Constants.qml documenting shared visual-proportion values
- Replace const T return-by-value with T to enable move semantics in GenericTable
- Use concrete QML types (point, Instantiator) instead of var where applicable


## [v1.1.23] - 2026-06-13

### Fixed
- Volume widget and systray volume icon no longer show incorrect muted state when first added to a dock. PulseAudio output device subscription is primed at startup and a repeating safety timer forces plasma-pa's PreferredDevice to read the initial default sink state.
- Updating/reinstalling no longer silently deletes user custom dock configurations. The pre-clean step now preserves `~/.config/latte/` and saved layouts unless `--purge-user-data` is explicitly passed.

## [v1.1.22] - 2026-06-13

### Fixed
- Volume widget and systray volume icon no longer show incorrect muted state when first added after a cold system boot. PulseAudio output device (SinkModel) subscription is now primed at startup alongside the existing stream subscription.

## [v1.1.22] - 2026-06-13

### Fixed
- Updating/reinstalling no longer silently deletes user custom dock configurations. The pre-clean step now preserves `~/.config/latte/` and saved layouts unless `--purge-user-data` is explicitly passed.

## [v1.1.21] - 2026-06-13

### Added
- Automatic QML disk cache clearing on version change, preventing stale compiled QML from masking fixes after upgrades.

### Fixed
- Default background thickness in new docks now correctly defaults to 6% (was 10% due to stale template values).

### Changed
- Project license upgraded from GPL-2.0-or-later to GPL-3.0-or-later.

## [v1.1.20] - 2026-06-13

### Fixed
- Eliminated binding loop on `inNormalState` property in visibility controller.
- Prevented false muted icon when no audio stream exists.

## [v1.1.19] - 2026-06-13

### Changed
- Moved taskmanager fallback QML module from `org.kde.plasma.private.taskmanager` to `org.kde.latte.compat.taskmanager`, so latte no longer installs or removes files in Plasma's namespace.
- Removed dead `TaskManagerApplet` import from `TaskItem.qml`.

### Fixed
- Wheel events now pass through to all external applets, not just systray.
- Wayland no longer destroys applet popups on open.
- Widget explorer now uses single-click to add widgets instead of double-click.
- External C++ plasmoids that request `fillWidth` now render correctly.
- Widget explorer places new applets before systray/tasks, not at dock end.
- Systray drag-and-drop reorder works without breaking layout.
- Suppressed benign KDE framework property override warnings and KIO teardown errors.

## [v1.0.14] - 2026-05-15

### Added
- Added the modern dock style screenshot to README.
- Added modern/classic dock style switching support with preserved parabolic animation behavior.

### Fixed
- Fixed Justify alignment for both modern and classic dock styles by removing the legacy splitter-based layout path from dock-style views.
- Fixed widget/task spacing, separator placement, widget drag ordering, and style-specific indicator behavior across classic and modern dock styles.
- Cleaned temporary debug logs after validation so startup logs stay focused on actionable warnings/errors.

## [v1.0.8] - 2026-05-04

### Fixed
- Refined task icon highlight behavior to avoid stale clicked-highlight regression while preserving hover feedback behavior.
- Improved task-state indicator contrast logic against panel light/dark themes, while keeping audio mute/unmute corner badge color independent.
- Fixed task drag sorting policy:
  - dragging a non-pinned running app into pinned area now auto-pins it and reorders into the target position;
  - dragging a pinned launcher into non-pinned area remains blocked.

## [v1.0.6] - 2026-05-03

### Fixed
- Fixed mixed install/runtime import-path regression: system installs no longer force-load `~/.local` Qt6 QML paths by default.
- Prevented stale user-local QML trees from overriding packaged system modules when launching `/usr/bin/latte-dock-ng`.
- Added explicit env toggles for diagnostics:
  - `LATTE_FORCE_USER_LOCAL_QML_IMPORTS=1`
  - `LATTE_DISABLE_USER_LOCAL_QML_IMPORTS=1`

## [v1.0.5] - 2026-05-03

### Fixed
- Fixed logout/session shutdown blocking by adding a reliable Wayland session-end path:
  - detect KDE session shutdown via `org.kde.ksmserver.isShuttingDown()`
  - mark fast teardown state consistently
  - quit Latte promptly when shutdown is detected.
- Fixed indicator-record removal crash path during teardown (`removeAt(-1)` guard in `Indicator::Factory::removeIndicatorRecords`).

## [v1.0.4] - 2026-05-03

### Fixed
- Fixed context-menu callback lifecycle for "More Places" to avoid stale-object warnings in `ContextMenu.qml`.
- Fixed audio badge interaction so clicking the mute indicator no longer leaves a stuck selected/highlight state.

### Changed
- Aligned the audio badge input model with Plasma 6 task-manager behavior (`HoverHandler`/`TapHandler` for click/hover state, wheel handling isolated).

## [v1.0.3] - 2026-05-03

### Added
- Added fallback app-name hover tooltip for dock task items when thin-tooltip is unavailable.
- Replaced README screenshot with the latest Latte Dock NG screenshot asset.

### Changed
- Bumped runtime/application version to `1.0.3` to keep About dialog aligned with release tag.

## [v1.0.2] - 2026-05-03

### Notes
- Baseline public release tag.
