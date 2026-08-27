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
| unqualified | 7071 | M (mechanical, manual) | 3 |
| missing-property | 1692 | A (architectural blindness) | 3 |
| unresolved-type | 661 | A | 3 |
| Quick.property-changes-parsed | 268 | M (rewrite) | 2 |
| unused-imports | 202 | M (trivial) | 1 |
| import | 25 | A (10 = runtime-registered module) + I (investigate) | 1/3 |
| unreachable-code | 20 | M (dead code) | 2 |
| Quick.anchor-combinations | 18 | W (waived, see §5) | — |
| property-override | 17 | R (review) | 2 |
| Quick.layout-positioning | 15 | R (review) | 2 |
| unresolved-alias | 7 | A (runtime context properties) | 3 |
| prefixed-import-type | 7 | R (review) | 1 |
| incompatible-type | 6 | R (possible real bugs) | 1 |
| stale-property-read | 2 | R (review) | 1 |
| signal-handler-parameters | 1 | R (likely real bug) | 1 |
| missing-type | 1 | R (review) | 1 |

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
- `import` — includes org.kde modules that are not installed in the tooling
  environment (external) and `org.kde.latte.private.app` until task T3.1
  extracts it into a real module.

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
- stale-property-read: binding reads a non-notifiable property; either add
  the missing `NOTIFY`/`CONSTANT` on the declaring type (C++ side) or
  disable line-scoped with justification.
- prefixed-import-type / missing-type: inspect individually; fix the import
  or the type usage.
Done = reviewed all instances, count 0 (or documented line-scoped disables)
→ promote.

### T1.4 `import` triage (25)
Breakdown at baseline:
- 10 × `org.kde.latte.private.app` (runtime-registered by
  `Latte::Corona::qmlRegisterTypes()`, no module on disk) — deferred to
  T3.1, do not fix here.
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

## 7. Phase 2 — mechanical rewrites (est. 2–4 sessions)

### T2.1 `Quick.property-changes-parsed` (268)
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

### T2.2 `unreachable-code` (20)
Remove the dead branches. qmllint's static analysis is reliable for pure JS
logic, but read each case: code reachable only through dynamic calls
(`Qt.callLater`, signal-driven re-entry) must not be removed — when in
doubt, keep the code and disable line-scoped with justification.

### T2.3 `property-override` (17) and `Quick.layout-positioning` (15)
Decision tree per instance: intentional override that documents a
deliberate deviation → line-scoped disable with justification; accidental
(re-declaring an existing base property) → fix. layout-positioning: verify
the actual layout at runtime before changing anything.

Done criteria per category: count 0 (or all remaining instances carry
documented disables) → promote.

## 8. Phase 3 — architecture (multi-week, one module per PR)

### T3.1 Extract `org.kde.latte.private.app` into a real module
Move the runtime-registered types (`Latte::Interfaces`,
`Latte::BackgroundTracker`, `Latte::ContextMenuLayerQuickItem`, registered
in `app/lattecorona.cpp` `Corona::qmlRegisterTypes()` into
`App::PRIVATEQMLURI`) into a `qt_add_qml_module` plugin, following the
established pattern from the core/containment/tasks migrations (see commits
6e9d45f53 and 8371eccc5: generated plugin class, QML_NAMED_ELEMENT
declarations, generated qmldir + plugins.qmltypes installed to both QML
roots, registration tests staging the module into a temporary import path).
This kills the 10 private.app `import` warnings and shrinks
`missing-property`/`unresolved-type`.

### T3.2 Runtime context properties → registered singletons
`unresolved-alias` (7) and the bulk of `missing-property` (1692) /
`unresolved-type` (661) come from names injected at runtime as QML context
properties (`latteView`, `layoutsManager`, `themeExtended`,
`shortcutsEngine`, ... — trace them with
`grep -rn "setContextProperty" app/`). Migrate them to registered
singletons or `required property` wiring, module by module. This is the
prerequisite for the final unqualified promotion.

### T3.3 `unqualified` (7071)
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
