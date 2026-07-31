#!/bin/bash

# Format all C++ sources in the tree. Build directories, worktrees and
# vendored copies are excluded so the formatter only touches real sources.

astyle --options='astylerc' --suffix=none \
    $(find . -name '*.cpp' -o -name '*.h' \
        | grep -vE '^\./(build|build-|cmake-build|\.claude|\.git)/')
