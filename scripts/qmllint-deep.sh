#!/usr/bin/env bash
# Type-resolution QML lint against a configured/built build tree.
#
# Unlike scripts/qmllint.sh (syntax-only gate, no build required), this
# script feeds qmllint the module import paths it needs to actually resolve
# types:
#   - <build-dir>/qml/                          the three generated latte QML
#                                               modules (core, containment,
#                                               tasks) with plugins.qmltypes
#   - a staged import root for the pure-QML     org.kde.latte.abilities,
#     modules installed as loose files          org.kde.latte.components and
#                                               the org.kde.latte.compat shim
#   - the system QML directory (default)        Qt and Plasma modules
#
# Gate (deliberately narrow, see README notes in the repository):
#   1. qmllint errors (syntax/type errors) fail the run.
#   2. Failed imports of the three org.kde.latte.* modules WE build fail the
#      run: a broken qmldir, plugin or install layout must not slip through.
# Everything else (7k+ legacy warnings inherited from upstream latte-dock:
# unqualified access, missing properties, runtime-registered
# org.kde.latte.private.app imports that can never resolve on disk, ...)
# is summarized per category and written to <build-dir>/qmllint-deep.log
# for triage, but does not fail the run.
#
# Usage: scripts/qmllint-deep.sh [build-dir]   (default: ./build)

set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="${1:-$root/build}"

qmllint=""
for candidate in qmllint-qt6 qmllint /usr/lib/qt6/bin/qmllint /usr/lib64/qt6/bin/qmllint; do
    if command -v "$candidate" >/dev/null 2>&1; then
        qmllint="$candidate"
        break
    fi
done
if [[ -z "$qmllint" ]]; then
    echo "error: qmllint not found (install qt6-declarative-dev / qt6-declarative)" >&2
    exit 1
fi

module_dir="$build_dir/qml/org/kde/latte"
if [[ ! -d "$module_dir/core" ]]; then
    echo "error: $module_dir/core not found — configure and build the QML modules first (cmake -B <dir> && cmake --build <dir> --target lattecoreplugin)" >&2
    exit 1
fi

# Stage the loose-file latte modules under one import root.
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
mkdir -p "$stage/org/kde/latte/compat"
ln -sfn "$root/declarativeimports/abilities" "$stage/org/kde/latte/abilities"
ln -sfn "$root/declarativeimports/components" "$stage/org/kde/latte/components"
ln -sfn "$root/compat/qml/org/kde/latte/compat/taskmanager" "$stage/org/kde/latte/compat/taskmanager"

mapfile -t files < <(git -C "$root" ls-files '*.qml')
if [[ ${#files[@]} -eq 0 ]]; then
    echo "qmllint-deep: no QML files found"
    exit 0
fi

log="$build_dir/qmllint-deep.log"
: > "$log"

echo "qmllint-deep: linting ${#files[@]} QML files with import resolution ($qmllint)"
echo "qmllint-deep: import roots: $build_dir/qml, staged latte modules, system qml"

failed=0
chunk=200
total=${#files[@]}
for ((start = 0; start < total; start += chunk)); do
    batch=("${files[@]:start:chunk}")
    "$qmllint" --ignore-settings --max-warnings -1 -I "$build_dir/qml" -I "$stage" "${batch[@]}" >>"$log" 2>&1
    rc=$?
    if [[ $rc -ne 0 ]]; then
        failed=1
    fi
done

# Gate 2: the three generated modules must be complete in the build tree.
# (Do NOT rely on import-failure greps alone: on machines with a system
# latte-dock installed, qmllint silently falls back to the system module.)
for module in core private/containment private/tasks; do
    module_dir_abs="$build_dir/qml/org/kde/latte/$module"
    for artifact in qmldir; do
        if [[ ! -f "$module_dir_abs/$artifact" ]]; then
            echo "qmllint-deep: FAILED — missing $module_dir_abs/$artifact (run the build first)" >&2
            failed=1
        fi
    done
    plugin_line=$(grep -E '^plugin ' "$module_dir_abs/qmldir" 2>/dev/null | awk '{print $2}')
    if [[ -z "$plugin_line" ]]; then
        echo "qmllint-deep: FAILED — no plugin line in $module_dir_abs/qmldir" >&2
        failed=1
    elif [[ ! -f "$module_dir_abs/$plugin_line.so" && ! -f "$module_dir_abs/lib$plugin_line.so" ]]; then
        echo "qmllint-deep: FAILED — plugin library for $plugin_line not found in $module_dir_abs" >&2
        failed=1
    fi
done

# Gate 3: when no system latte-dock masks resolution (e.g. CI containers),
# a latte-generated module failing to import means the build tree is broken.
if grep -qE 'Failed to import org\.kde\.latte\.(core|private\.(containment|tasks))\b' "$log"; then
    echo "qmllint-deep: FAILED — latte-generated QML modules did not resolve:" >&2
    grep -E 'Failed to import org\.kde\.latte\.(core|private\.(containment|tasks))\b' "$log" | sort -u | head >&2
    failed=1
fi

echo "qmllint-deep: warning categories (full log: $log):"
grep -oE '\[[A-Za-z][A-Za-z0-9.-]*\]$' "$log" | sort | uniq -c | sort -rn | sed 's/^/  /'

if [[ $failed -ne 0 ]]; then
    echo "qmllint-deep: FAILED (see $log)" >&2
    exit 1
fi
echo "qmllint-deep: OK"
