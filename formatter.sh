#!/usr/bin/env bash
# Format C++ sources with clang-format using the repo-root .clang-format
# configuration (Mozilla-based; transcribed from the historical astyle setup).
#
# clang-format does not reproduce the old astyle output byte-for-byte, so a
# whole-tree reformat is deliberately NOT supported: pass the files you
# touched and commit those reformats with your change, keeping diffs
# reviewable and git blame intact. The legacy astyle config remains in git
# history (astylerc).
#
# Usage: formatter.sh <file.cpp|file.h> [more files...]

set -euo pipefail

clang_format=""
for candidate in clang-format clang-format-20 clang-format-19 clang-format-18 clang-format-17 clang-format-16 clang-format-15; do
    if command -v "$candidate" >/dev/null 2>&1; then
        clang_format="$candidate"
        break
    fi
done
if [[ -z "$clang_format" ]]; then
    echo "error: clang-format not found (install the clang tools package)" >&2
    exit 1
fi

if [[ $# -eq 0 ]]; then
    echo "usage: $0 <file.cpp|file.h> [more files...]" >&2
    echo "       format only the files you touched; whole-tree reformats are not supported" >&2
    exit 1
fi

exec "$clang_format" -i "$@"
