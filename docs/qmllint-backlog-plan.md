# QML Lint Backlog — Phased Execution Plan

This document is the executable plan for burning down the qmllint deep-lint
backlog. It is written to be self-contained: an AI coding agent (or human)
with no prior session context must be able to pick up any task below and
execute it safely. Read this file top to bottom before starting.

Authoritative repo rules live in `AGENTS.md` (no auto-commit/push without
approval, English only, no AI attribution in commits, zero compiler warnings
on GCC and Clang, no functional regressions). This plan inherits them.

---

## 1. How to measure

The measurement tool is `scripts/qmllint-deep.sh` (added together with this
plan). It requires a configured and built build tree:

```bash
cmake -B build-autotests-gcc && cmake --build build-autotests-gcc --parallel $(nproc) \
    && cmake --build build-autotests-gcc --target latte-autotests --parallel $(nproc)
./scripts/qmllint-deep.sh build-autotests-gcc
```

Output: gate verdict (errors / module artifacts / latte import failures) plus
a per-category histogram. Full log: `<build-dir>/qmllint-deep.log`.

To extract the file:line list for one category:

```bash
grep -E '\[<category>\]$' build-autotests-gcc/qmllint-deep.log | sort -u
```

Note: `unused-imports` is emitted at `Info:` level by current qmllint; the
histogram includes both `Warning:` and `Info:` lines. Counts shift slightly
between Qt minor versions — always re-measure before and after your change
and record both numbers.

## 2. Baseline (commit a32bf583b, Qt 6.11.1, 235 QML files)

| Category | Count | Class | Phase |
|---|---|---|---|
| unqualified | 6956 | M (mechanical, manual) | 3 |
| missing-property | 1736 | A (architectural blindness) | 3 |
| unresolved-type | 590 | A | 3 |
| Quick.property-changes-parsed | 32 | M (rewrite) | 2 |
| unused-imports | 5 | M (trivial) | 1 |
| import | 11 | W (understood runtime/qmltypes gaps, see §5) | — |
| unreachable-code | 0 | M (dead code) | 2 |
| Quick.anchor-combinations | 18 | W (waived, see §5) | — |
| property-override | 0 | R (reviewed; scoped waiver) | — |
| Quick.layout-positioning | 0 | R (reviewed) | — |
| unresolved-alias | 1 | A (runtime context properties) | 3 |
| prefixed-import-type | 0 | R (reviewed; scoped waiver) | — |
| incompatible-type | 6 | W (waived, see §5) | — |
| stale-property-read | 2 | W (waived, see §5) | — |
| signal-handler-parameters | 0 | R (likely real bug) | 1 |
| missing-type | 0 | R (reviewed; scoped waiver) | — |

unqualified distribution by directory (batching input for task T3.3):

| Directory | Count (baseline) |
|---|---|
| containment/package | 2794 |
| shell/package | 1610 |
| plasmoid/package | 1610 |
| declarativeimports | 886 |
| indicators | 148 |
| separator/package | 22 |
| compat | 1 |

## 3. Mandatory verification loop for every batch

No batch is done until all of these pass, in order:

1. **Re-measure** deep lint; record before/after per category.
2. **Build, both compilers, zero warnings**:
   ```bash
   cd build-autotests-gcc && cmake --build . --parallel $(nproc) \
       && cmake --build . --target latte-autotests --parallel $(nproc)
   # repeat in build-autotests-clang
   ```
3. **Tests**: `ctest --output-on-failure` in both build trees (currently
   40/40 must pass).
4. **Runtime**: follow the AGENTS.md debug & retest workflow
   (`bash install.sh --user Debug`, `pkill -x latte-dock-ng`, relaunch via
   `/tmp/launch-latte.sh`, inspect `/tmp/latte-ng.log`). Zero new errors or
   warnings. Batches touching visible behavior (animations, tooltips,
   edit mode) additionally need a human retest — say so in the PR/commit.
5. **Commit + push** (after user approval per AGENTS.md): conventional
   commit message, English, no AI attribution. Update the baseline table
   (§2) and append a progress-log row (§9) in the same commit.

Keep diffs minimal. Never mass-reformat. One batch = one commit.

## 4. Promotion protocol

`scripts/qmllint-deep.sh` contains `PROMOTED_ERROR_CATEGORIES`. Once a
category measures **zero on two consecutive full runs with green CI**, append
it there; the gate then fails on any new occurrence. If a promoted category
regresses, fix the code — removing a promotion requires a waiver entry in §5.

## 5. Waivers (never promote)

- `Quick.anchor-combinations` — the codebase intentionally uses conditional
  anchors (`anchors.left: cond ? parent.left : undefined`) which statically
  look like conflicts; Qt resolves them at runtime. Restructuring would risk
  layout regressions for no gain.
- `import` — the remaining 25 diagnostics are understood runtime/qmltypes
  gaps: the `org.kde.latte.private.app` registrations are deferred to T3.1;
  `LatteCore.IconItem` (5) and `LatteCore.Dialog` (2) are registered runtime
  types whose generated qmltypes lack usable version/base metadata; the
  compat task backend (1) is runtime-registered; and Plasma volume's
  `SinkModel`/`SinkInputModel` (2) are private runtime types. Adding
  `QML_ADDED_IN_VERSION(0, 2)` was tested for the Latte core types but reverted
  because qmltyperegistrar emitted a `PlasmaQuick::Dialog` base-type warning.
- `unused-imports` — five remaining diagnostics are intentional runtime
  dependencies that current qmllint cannot resolve reliably: the registered
  `LatteTasks.ContextMenuActionsBackend` in `compat/.../Backend.qml`,
  `LatteCore.Dialog` in `declarativeimports/.../ThinTooltip.qml`, the local
  `Private` components in `declarativeimports/components/ComboBox.qml`,
  `PlasmaCore.Types` in `plasmoid/.../RealRemovalAnimation.qml`, and
  `LatteCore.IconItem` in `shell/.../InfoView.qml`.
- `incompatible-type` — all six remaining instances are intentional dynamic
  boundaries: `Loader.item` values used as `Item` objects in the containment
  communicator, preview and task icon paths; the containment layout manager
  used as a `Connections.target`; and the runtime bridge's
  `QQmlListProperty<QObject>` resources. The runtime objects satisfy these
  contracts, and narrowing them statically would change loader/bridge behavior.
- `stale-property-read` — both remaining reads are from the indicators ability
  wrapper's runtime bridge (`resources` in `client/Indicators.qml` and
  `items/IndicatorObject.qml`). The wrapper deliberately supports both a local
  QML fallback and a dynamically supplied bridge, so a static NOTIFY contract
  cannot represent both paths without changing behavior.
- `property-override` — all 17 remaining declarations intentionally preserve
  Latte's public API names while shadowing inherited Qt Quick properties, or
  intentionally redefine implicit sizing for custom controls. Each instance is
  enclosed by a source-level `qmllint disable/enable property-override` scope
  with an English justification comment.

## 6. Phase 1 — quick wins (est. 1–2 sessions)

### T1.1 `signal-handler-parameters` (1) — likely real bug
`containment/package/contents/ui/main.qml:751`: the `onAppletAdded` handler
declares more formal parameters than the Plasma signal provides, so the
extra parameter is always `undefined`. Compare the handler with the
Plasma 6 `Plasma::Containment::appletAdded` / Plasmoid attached signal
signature, fix the handler, and verify applet drag-and-drop still works in
edit mode. Done = count 0 + runtime verified → promote.

### T1.2 `unused-imports` (202)
Remove unused imports directory by directory (batch per directory, one
commit per batch). Removal is load-time only, but a single wrong removal
can break type resolution — the qmllint gate (syntax errors) plus runtime
smoke covers it. Caution: an import that looks unused may exist for an
attached-property namespace (`import org.kde.plasma.plasmoid` provides the
`plasmoid` context object; `Kirigami` provides `Kirigami.Theme` attached
properties) — qmllint already accounts for attached usage, trust it but
spot-check each batch's diff. Done = count 0 → promote.

### T1.3 Manual review set (16 instances total)
`incompatible-type` (6), `prefixed-import-type` (7), `stale-property-read`
(2), `missing-type` (1). Extract instances from the log (§1), then per
instance:
- incompatible-type: property declared as a wider type than the runtime
  value (`QtObject` receiving a `QQuickItem`). Prefer typing the property
  correctly (`property Item`), but first check every consumer of the
  property for assignments of the wider type. If typing is impossible
  without behavior change, keep `var`/`QtObject` and add a line-scoped
`// qmllint disable incompatible-type` with a one-line justification.
  The six current dynamic-boundary instances are documented in §5.
- prefixed-import-type: the seven accesses to Plasma's QVariant-backed
  activity model data in `plasmoid/.../ContextMenu.qml` are covered by a
  scoped source directive with an inline justification.
- stale-property-read: both indicator bridge reads are documented in §5;
  adding a static NOTIFY contract would invalidate the local fallback path.
- missing-type: the external Plasma private `WidgetExplorer.containment`
  property is covered by a scoped source directive because its qmltypes file
  is incomplete while the runtime property is valid.
- stale-property-read: binding reads a non-notifiable property; either add
  the missing `NOTIFY`/`CONSTANT` on the declaring type (C++ side) or
  disable line-scoped with justification.
- prefixed-import-type / missing-type: inspect individually; fix the import
  or the type usage.
Done = reviewed all instances, count 0 (or documented line-scoped disables)
→ promote.

### T1.4 `import` triage (25)
Breakdown at baseline:
- 10 × `org.kde.latte.private.app` (formerly runtime-registered by
  `Latte::Corona::qmlRegisterTypes()`) — resolved by the T3.1 module
  extraction below.
- 7 × `LatteCore.IconItem was not found` (5) + `LatteCore.Dialog` (2) —
  hypothesis: types are exported at revision 0.0 because the declarative
  registration omits `QML_ADDED_IN_VERSION`. Test adding
  `QML_ADDED_IN_VERSION(0, 2)` to `IconItem`/`Dialog` in
  `declarativeimports/core/` and check whether the resolution warnings
  disappear. Verify ctest + runtime afterwards.
- 1 × `LatteTasks.ContextMenuActionsBackend` in
  `compat/qml/org/kde/latte/compat/taskmanager/Backend.qml` — the compat
  qmldir already declares `depends org.kde.latte.private.tasks`; if qmllint
  still fails, investigate its `depends` handling; otherwise acceptable.
- `LatteApp.*`, `LatteContainment.LayoutManager` instances: same root cause
  class as above (runtime module / revision).
Done = all non-private.app instances understood; fix what is fixable;
document the rest in this file.

All 25 baseline import diagnostics have been classified above; the private.app
subset is resolved by T3.1, while the remaining fixes require upstream or
generated qmltypes metadata changes.

## 7. Phase 2 — mechanical rewrites (est. 2–4 sessions)

### T2.1 `Quick.property-changes-parsed` (0)
Legacy `PropertyChanges { target: x; anchors.left: ... }` blocks rely on the
custom parser. Rewrite to the value-source form:

```qml
// old
PropertyChanges {
    target: taskIcon
    anchors.leftMargin: root.edgeMargin
}
// new
PropertyChanges {
    taskIcon.anchors.leftMargin: root.edgeMargin
}
```

There is no qmllint auto-fix for this category; it is manual but mechanical.
Remove the now-unused `target:` line only when all other properties in the
block were rewritten. Concentrate runtime verification on animation-heavy
files (parabolic zoom, launcher/task animations, tooltips, edit-mode
transitions). Batch per directory.

### T2.2 `unreachable-code` (0)
Remove the dead branches. qmllint's static analysis is reliable for pure JS
logic, but read each case: code reachable only through dynamic calls
(`Qt.callLater`, signal-driven re-entry) must not be removed — when in
doubt, keep the code and disable line-scoped with justification.

### T2.3 `property-override` (0) and `Quick.layout-positioning` (0)
Decision tree per instance: intentional override that documents a
deliberate deviation → line-scoped disable with justification; accidental
(re-declaring an existing base property) → fix. layout-positioning: verify
the actual layout at runtime before changing anything.

Done criteria per category: count 0 (or all remaining instances carry
documented disables) → promote.

## 8. Phase 3 — architecture (multi-week, one module per PR)

### T3.1 Extract `org.kde.latte.private.app` into a real module
Move the runtime-registered types (`Latte::Interfaces`,
`Latte::BackgroundTracker`, `Latte::ContextMenuLayerQuickItem`) into a
`qt_add_qml_module` plugin, following the established core/containment/tasks
pattern. The plugin exports generated `qmldir` and qmltypes metadata to both
QML roots; the host executable exports the application-owned symbols required
by the plugin, while `Settings` remains runtime-registered until its consumers
are migrated. This removes the 10 private.app import warnings and shrinks
`missing-property`/`unresolved-type`.

### T3.2 Runtime context properties → registered singletons
`unresolved-alias` (1) and the bulk of `missing-property` (1740) /
`unresolved-type` (590) come from names injected at runtime as QML context
properties (`latteView`, `layoutsManager`, `themeExtended`,
`shortcutsEngine`, ... — trace them with
`grep -rn "setContextProperty" app/`). Migrate them to registered
singletons or `required property` wiring, module by module. This is the
prerequisite for the final unqualified promotion.

### T3.3 `unqualified` (7059)
Work through the directories smallest-first to validate the process:

compat (1) → separator (22) → indicators (148) → declarativeimports (886)
→ plasmoid (1610) → shell (1610) → containment (2794)

Rules:
- Preferred fix is manual qualification (`root.width`, `item.id`, ...).
- `qmllint --fix` may only be used on leaf, self-contained files: its
  suggestion inserts `pragma ComponentBehavior: Bound`, which changes
  scoping semantics for dynamically created components (`createObject`
  patterns are used heavily) and for files that rely on runtime context
  properties. Do not use it on containment/shell files until T3.2 is done.
  Review every auto-fixed diff line.
- Every batch requires the full §3 loop; animation and tooltip behavior
  must be retested by a human.

## 9. Phase 4 — lock-in

Promote `unqualified` (and any remaining Phase 2/3 categories) per §4.
Optional afterwards: enable `QT_QML_GENERATE_QMLLS_INI` for qml-language-
server support and revisit the waived categories if their root causes
disappear.

## 10. Known traps (learned the hard way)

- `qmllint -D all` disables the core syntax verifier too — never use it.
- A system latte-dock in `/usr/lib64/qt6/qml` silently masks resolution
  failures of locally built modules; that is why the deep script gates on
  module artifacts, not only on import messages.
- Autotests are `EXCLUDE_FROM_ALL`: build `--target latte-autotests` or you
  run stale test binaries and see phantom failures.
- `qt_add_qml_module`'s generated registration resolves headers via
  `__has_include(<header.h>)` from the target's include dirs: when headers
  live in a `plugin/` subdirectory, add it with
  `target_include_directories(<target> PRIVATE <dir>)`.
- moc's metatype helpers require complete types for pointer-returning
  Q_PROPERTY/Q_INVOKABLE members — include the real header instead of
  forward-declaring.
- The `coretypes.h.in` template is configured into three headers; only the
  `org.kde.latte.core` copy may carry QML declarations (the QML name
  "Types" must stay exclusive to that module).
- "Zero warnings" applies to compiler warnings; `qmltyperegistrar` notes
  (e.g. "PlasmaQuick::Dialog is used as base type but cannot be found")
  are tooling-level and currently accepted.

## 11. Progress log (append after every batch)

| Date | Commit | Task | Category delta | Notes |
|---|---|---|---|---|
| (example) | abc1234 | T1.2 | unused-imports 202 → 0 | promoted |
| 2026-08-28 | this commit | T1.1 | signal-handler-parameters 1 → 0 | Plasma 6 handler now matches `appletAdded(Plasma::Applet*, const QRectF&)`; manual runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 202 → 199 | Removed three unused imports from the indicator package; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 199 → 173 | Removed unused imports from `declarativeimports/abilities`; retained the runtime-required `LatteCore` import in `host/ThinTooltip.qml`; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 173 → 150 | Removed unused imports from `declarativeimports/components`; retained the `ComboBox` private component import required at runtime; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 150 → 147 | Removed unused `PlasmaComponents` imports from `plasmoid/.../config`; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 147 → 143 | Removed unused imports from the plasmoid root components; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 143 → 142 | Removed the unused `PlasmaComponents` import from `shell/.../applet`; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 142 → 141 | Removed the unused `PlasmaCore` import from `shell/.../configuration/canvas/controls`; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 141 → 138 | Removed unused imports from `shell/.../configuration/canvas/maxlength`; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 138 → 131 | Removed unused imports from `shell/.../configuration/pages`; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 131 → 125 | Removed unused imports from `shell/.../views`; retained the runtime-required `LatteCore` import in `InfoView.qml`; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 125 → 115 | Removed unused imports from `shell/.../configuration`; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 115 → 109 | Removed unused imports from `shell/.../controls`; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 109 → 109 | Removed the redundant `PlasmaCore` import from `shell/.../configuration/canvas/controls/StickIcon.qml`; its file-level warning disappeared while the aggregate histogram remained stable; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 109 → 109 | Removed the redundant `QtQuick.Layouts` import from `shell/.../configuration/canvas/maxlength/Ruler.qml`; its file-level warning disappeared while the aggregate histogram remained stable; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 109 → 104 | Removed unused imports from `plasmoid/.../abilities/launchers`; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 104 → 99 | Removed unused imports from `plasmoid/.../taskslayout`; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 99 → 89 | Removed unused imports from `plasmoid/.../task/animations`; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 89 → 84 | Removed unused imports from `plasmoid/.../task`; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 84 → 77 | Removed unused imports from `plasmoid/.../previews`; retained `QtQuick.Effects` because it provides the runtime-used `MultiEffect` type; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 77 → 61 | Removed unused imports from `containment/.../abilities`; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 61 → 54 | Removed unused imports from `containment/.../abilities/privates`; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 54 → 44 | Removed unused imports from `containment/.../applet`; retained `QtQuick.Effects` for the runtime-used `MultiEffect` type; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 44 → 36 | Removed unused imports from `containment/.../background`; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 36 → 30 | Removed unused imports from `containment/.../colorizer`; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 30 → 24 | Removed unused imports from `containment/.../layouts`; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 24 → 16 | Removed unused imports from `containment/package/contents/ui`; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 16 → 14 | Removed unused imports from `containment/package/contents/ui/main.qml`; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 14 → 13 | Removed the unused Plasma Plasmoid import from `indicators/default/package/ui/main.qml`; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 13 → 10 | Removed unused imports from `plasmoid/package/contents/ui/main.qml`; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 10 → 6 | Removed unused imports from `plasmoid/package/contents/ui/previews` and `plasmoid/package/contents/ui/task`; retained runtime-used `PlasmaCore` in `RealRemovalAnimation.qml`; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 6 → 5 | Removed the unused `PlasmaCore` import from `shell/.../configuration/pages/EffectsConfig.qml`; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.2 | unused-imports 5 → 5 | Removed the redundant Plasma Plasmoid import from `declarativeimports/abilities/client/MyView.qml`; the remaining five diagnostics are documented runtime dependencies; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.3 | incompatible-type 6 → 6 | Reviewed all six instances; each is a documented dynamic Loader/bridge boundary and is retained to preserve runtime behavior |
| 2026-08-28 | this commit | T1.3 | prefixed-import-type 7 → 0 | Added a justified scoped qmllint waiver for the seven QVariant-backed activity model accesses in `ContextMenu.qml`; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.3 | stale-property-read 2 → 2 | Reviewed both indicator bridge reads; they are intentional local-fallback/runtime-bridge boundaries and are documented in §5 |
| 2026-08-28 | this commit | T1.3 | missing-type 1 → 0 | Added a justified scoped qmllint waiver for the external Plasma private `WidgetExplorer.containment` property; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T1.4 | import 25 → 11 | Classified the remaining import diagnostics after the private app module extraction as runtime registrations or incomplete external qmltypes; the Latte core version-metadata experiment was reverted because it introduced a qmltyperegistrar base-type warning |
| 2026-08-28 | this commit | T3.2 | runtime context injection reduced by one isolated property; histogram stable | Replaced the global `infoWindow` context property with an explicit root property in `InfoView.qml`; GCC/Clang builds and 40/40 tests passed, and deep lint remained green at 7059 unqualified, 1740 missing-property, 590 unresolved-type, and 1 unresolved-alias |
| 2026-08-28 | this commit | T3.2 | unqualified 7059 → 7054 | Replaced the WidgetExplorer-specific `containmentFromView` context property with an explicit root property; GCC/Clang builds and 40/40 tests passed, and deep lint remained green |
| 2026-08-28 | this commit | T3.2 | unqualified 7054 → 7049 | Declared and injected WidgetExplorer's `viewConfig`, `themeExtended`, and `latteView` dependencies on the root object, completing that page's explicit dependency surface; GCC/Clang builds and 40/40 tests passed, and deep lint remained green |
| 2026-08-28 | this commit | T3.3 | unqualified 7049 → 7027; missing-property 1740 → 1736 | Qualified the static separator representation with bound component behavior, retained a documented Plasma theme-context boundary, and qualified the compatibility backend connection; GCC/Clang builds, 40/40 tests, deep lint, and user Debug installation passed |
| 2026-08-28 | this commit | T3.2 | unqualified 7027 → 7013 | Added explicit root-object dependency properties for the primary configuration page (`viewConfig`, `latteView`, `universalSettings`, `layoutsManager`, and `themeExtended`), covering the Loader and its source component; GCC/Clang builds, 40/40 tests, and deep lint passed |
| 2026-08-28 | this commit | T3.2 | Canvas configuration dependency wiring corrected; histogram stable | Injected the explicitly declared `latteView` into the Canvas configuration root so its Loader remains active with the same runtime behavior; GCC/Clang builds, 40/40 tests, and deep lint passed |
| 2026-08-28 | this commit | T3.3 | unqualified 7013 → 6989 | Qualified Indexer bridge, readiness, layout, separator, hidden-item, and visible-item references; retained dynamic bridge boundaries where static metadata is incomplete; GCC/Clang builds, 40/40 tests, and deep lint passed |
| 2026-08-28 | this commit | T3.3 | unqualified 6989 → 6956 | Qualified parent-owned properties throughout `ComboBoxButton.qml` while preserving dynamic control boundaries; GCC/Clang builds, 40/40 tests, and deep lint passed |
| 2026-08-28 | this commit | T3.3 | unqualified 6956 → 6914 | Qualified safe root bindings in `AddItem.qml`, `BadgeText.qml`, `ComboBox.qml`, and `GlowPoint.qml`; GCC/Clang builds, 40/40 tests, and deep lint passed |
| 2026-08-28 | this commit | T3.3 | unqualified 6914 → 6855; missing-property 1737 → 1768 | Qualified the self-contained indicator configuration and rendering bindings; retained the indicator API's runtime-backed type boundary; GCC/Clang builds, 40/40 tests, and deep lint passed |
| 2026-08-28 | this commit | T3.2/T3.3 | unqualified 6855 → 6701 | Added explicit `dialog` and `latteView` dependencies to `TasksConfig.qml`, then qualified its nested bindings; GCC/Clang builds, 40/40 tests, and deep lint passed |
| 2026-08-28 | this commit | T3.2/T3.3 | unqualified 6701 → 6601 | Added explicit configuration dependencies to `BehaviorConfig.qml` and `EffectsConfig.qml`, then qualified nested bindings; GCC/Clang builds, 40/40 tests, and deep lint passed |
| 2026-08-28 | this commit | T3.2/T3.3 | unqualified 6601 → 6315; net diagnostics reduced by more than 200 | Added explicit dependencies to `AppearanceConfig.qml` and qualified safe bindings across the configuration, task, context-menu, visibility, and background QML paths; restored the source-contract expression required by the modern shadow test; GCC/Clang builds, 40/40 tests, and deep lint passed |
| 2026-08-28 | this commit | T3.2/T3.3 | unqualified 6205 → 5983; unresolved-type 591 → 572 | Added explicit outer-context dependencies to `ItemWrapper.qml` and `BindingsExternal.qml`, including their instantiation sites; GCC/Clang builds, 40/40 tests, and deep lint passed |
| 2026-08-28 | this commit | T3.2/T3.3 | unqualified 5983 → 5756 | Added explicit outer-context dependencies to the containment layout container and task/context-menu components; GCC/Clang builds, 40/40 tests, and deep lint passed |
| 2026-08-28 | this commit | T3.2/T3.3 | unqualified 5756 → 5702 | Added explicit dependencies through the Canvas configuration, settings overlay, header, ruler, and ruler mouse-area chain; GCC/Clang builds, 40/40 tests, and deep lint passed |
| 2026-08-28 | this commit | T3.2/T3.3 | unqualified 5702 → 5700 | Corrected the Canvas ruler bindings to target the component's own `rulerItem` ID instead of an external instance name; GCC/Clang builds, 40/40 tests, and deep lint passed |
| 2026-08-28 | this commit | T3.2/T3.3 | unqualified 5700 → 5684 | Added explicit `latteView` and `settingsRoot` dependencies to the Canvas button and visibility-mode controls; GCC/Clang builds, 40/40 tests, and deep lint passed |
| 2026-08-28 | this commit | T3.2/T3.3 | unqualified 5684 → 5667 | Added explicit `latteView` and `viewConfig` dependencies to the custom indicator control and qualified its nested indicator operations; GCC/Clang builds, 40/40 tests, and deep lint passed |
| 2026-08-28 | this commit | T3.2/T3.3 | unqualified 5667 → 5658 | Qualified nested visibility-mode signal handlers through the control's explicit `latteView` dependency; GCC/Clang builds, 40/40 tests, and deep lint passed |
| 2026-08-28 | this commit | T3.2/T3.3 | unqualified 5658 → 5647 | Qualified safe nested canvas and indicator-control bindings and corrected the missing ComboBox button metrics reference; GCC/Clang builds, 40/40 tests, and deep lint passed |
| 2026-08-28 | this commit | T3.2/T3.3 | unqualified 5647 → 5623 | Qualified both Ruler position-binding blocks through the explicit `rulerItem.root` and `rulerItem.plasmoid` dependencies; GCC/Clang builds, 40/40 tests, and deep lint passed |
| 2026-08-28 | this commit | T3.2/T3.3 | unqualified 5623 → 5606 | Qualified Ruler animation and grid bindings, and replaced the stale animation guard with the component's actual animations; GCC/Clang builds, 40/40 tests, and deep lint passed |
| 2026-08-28 | this commit | T3.2/T3.3 | unqualified 5606 → 5602 | Exposed the dialog-provided `units` object explicitly on all four configuration pages; GCC/Clang builds, 40/40 tests, and deep lint passed |
| 2026-08-28 | this commit | T3.2/T3.3 | unqualified 5602 → 5556 | Qualified the Ruler grid's nested line, spacer, label, and arrow bindings through `rulerItem`; GCC/Clang builds, 40/40 tests, and deep lint passed |
| 2026-08-28 | this commit | T3.2/T3.3 | unqualified 5556 → 5551 | Qualified the nested Canvas button's visual and layout bindings through its explicit `button` ID; GCC/Clang builds, 40/40 tests, and deep lint passed |
| 2026-08-28 | this commit | T3.2/T3.3 | unqualified 5551 → 5546 | Qualified the Ruler grid's edge offsets and free-space orientation through `rulerItem`; GCC/Clang builds, 40/40 tests, and deep lint passed |
| 2026-08-28 | this commit | T3.2/T3.3 | unqualified 5546 → 5531 | Added the explicit `settingsRoot` dependency to HeaderSettings and qualified its nested stick controls through `headerSettings`; GCC/Clang builds, 40/40 tests, and deep lint passed |
| 2026-08-28 | this commit | T3.2/T3.3 | unqualified 5531 → 5530 | Removed the dead RulerMouseArea tooltip visibility handler, which referenced a nonexistent dynamic tooltip object; GCC/Clang builds, 40/40 tests, and deep lint passed |
| 2026-08-28 | this commit | T3.2/T3.3 | unqualified 5530 → 5527 | Qualified RearrangeIcon's nested icon-root handoff through the stable parent chain; GCC/Clang builds, 40/40 tests, and deep lint passed |
| 2026-08-28 | this commit | T3.2/T3.3 | unqualified 5527 → 5526; aggregate histogram stable | Removed the unused MarginsArea `iconSize` property, which referenced a nonexistent `_metrics` object; the file-level warning disappeared while another aggregate diagnostic was reclassified; GCC/Clang builds, 40/40 tests, and deep lint passed |
| 2026-08-28 | this commit | profiling-free safe optimization | GenericLayout view and data ordering now use stable sort instead of quadratic bubble-sort passes; GCC/Clang builds and 40/40 tests passed |
| 2026-08-28 | this commit | T2.3 | property-override 17 → 0 | Reviewed all inherited API-name and implicit-size overrides; added narrowly scoped, justified qmllint waivers; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T2.1 | Quick.property-changes-parsed 268 → 264 | Rewrote both `PropertyChanges` blocks in `containment/.../colorizer/CustomBackground.qml` to explicit target-property bindings; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T2.1 | Quick.property-changes-parsed 264 → 256 | Rewrote four `PropertyChanges` blocks in `containment/.../applet/ItemWrapper.qml` to explicit target-property bindings; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T2.1 | Quick.property-changes-parsed 256 → 248 | Rewrote four `PropertyChanges` blocks in `declarativeimports/components/AddingArea.qml` to explicit target-property bindings; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T2.1 | Quick.property-changes-parsed 248 → 240 | Rewrote four `PropertyChanges` blocks in `declarativeimports/components/ExternalShadow.qml` to explicit target-property bindings; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T2.1 | Quick.property-changes-parsed 240 → 232 | Rewrote four `PropertyChanges` blocks in `containment/package/contents/ui/main.qml` to explicit target-property bindings; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T2.1 | Quick.property-changes-parsed 232 → 224 | Rewrote four `PropertyChanges` blocks in `declarativeimports/abilities/client/indicators/LatteIndicator.qml` to explicit target-property bindings; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T2.1 | Quick.property-changes-parsed 224 → 216 | Rewrote four `PropertyChanges` blocks in `indicators/default/package/ui/main.qml` to explicit target-property bindings; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T2.1 | Quick.property-changes-parsed 216 → 208 | Rewrote four `PropertyChanges` blocks in `plasmoid/package/contents/ui/main.qml` to explicit target-property bindings; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T2.1 | Quick.property-changes-parsed 208 → 200 | Rewrote four `PropertyChanges` blocks in `plasmoid/package/contents/ui/taskslayout/ScrollEdgeShadows.qml` to explicit target-property bindings; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T2.1 | Quick.property-changes-parsed 200 → 191 | Rewrote three `PropertyChanges` blocks in `declarativeimports/components/private/TextFieldFocus.qml` to explicit target-property bindings; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T2.1 | Quick.property-changes-parsed 191 → 171 | Rewrote eight `PropertyChanges` blocks in `declarativeimports/components/private/RoundShadow.qml` to explicit target-property bindings; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T2.1 | Quick.property-changes-parsed 171 → 151 | Rewrote eight `PropertyChanges` blocks in `declarativeimports/components/private/ButtonShadow.qml` to explicit target-property bindings; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T2.1 | Quick.property-changes-parsed 151 → 141 | Rewrote five `PropertyChanges` blocks in `indicators/org.kde.latte.plasmatabstyle/package/ui/BackLayer.qml` to explicit target-property bindings; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T2.1 | Quick.property-changes-parsed 141 → 128 | Rewrote five `PropertyChanges` blocks in `plasmoid/package/contents/ui/task/AudioStream.qml` to explicit target-property bindings; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T2.1 | Quick.property-changes-parsed 128 → 104 | Rewrote twelve `PropertyChanges` blocks in `plasmoid/package/contents/ui/taskslayout/ScrollableList.qml` to explicit target-property bindings; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T2.1 | Quick.property-changes-parsed 104 → 80 | Rewrote twelve `PropertyChanges` blocks in `declarativeimports/abilities/client/appletabilities/ContainerGridBindings.qml` to explicit target-property bindings; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T2.1 | Quick.property-changes-parsed 80 → 32 | Rewrote twelve `PropertyChanges` blocks in `containment/package/contents/ui/layouts/AppletsContainer.qml` to explicit target-property bindings; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T2.1 | Quick.property-changes-parsed 32 → 0 | Rewrote sixteen `PropertyChanges` blocks in `containment/package/contents/ui/background/MultiLayered.qml` to explicit target-property bindings; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T2.2 | unreachable-code 20 → 0 | Removed redundant `break` statements after `return` in `containment/package/contents/ui/debugger/DebugWindow.qml`; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T2.3 | Quick.layout-positioning 15 → 13 | Replaced separator `width`/`height` bindings in `declarativeimports/components/ItemDelegate.qml` with `Layout.fillWidth`/`Layout.preferredHeight`; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T2.3 | Quick.layout-positioning 13 → 10 | Replaced `ConfigInteraction` title anchoring with `Layout.alignment` and converted the `Button` icon Loader dimensions to `Layout.preferredWidth`/`Layout.preferredHeight`; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T2.3 | Quick.layout-positioning 10 → 0 | Converted configuration window, behavior/effects controls, and applet delegate dimensions to layout-managed properties; GCC/Clang lint, builds, tests, and themed runtime retest passed |
| 2026-08-28 | this commit | T3.1 | import 25 → 11 | Extracted `Interfaces`, `BackgroundTracker`, and `ContextMenuLayer` into the generated private.app QML plugin; GCC/Clang builds and 40/40 tests passed, and nohup runtime retest loaded the `kite-light` theme |
