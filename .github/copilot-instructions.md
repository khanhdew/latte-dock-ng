# Latte Dock NG contribution instructions

## Project context

- Latte Dock NG is a Qt 6, KDE Frameworks 6, Plasma 6 C++17 application.
- The main branch is `main`; do not push directly to it.
- Read `CODEX.md` and the relevant source, test, packaging, and workflow files before changing behavior.

## Required engineering standards

- Keep repository text, comments, and commit messages in English.
- Preserve existing Qt/KDE compatibility and trace consumers before removing code.
- Prefer focused changes with a clear issue or user-facing rationale.
- Add or update tests for behavior changes.
- Do not claim a test passed unless it was actually run.
- Do not add AI attribution to commits or pull requests.

## Validation

- Configure with `cmake -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON`.
- Build with `cmake --build build --parallel 8`.
- Run `ctest --test-dir build --output-on-failure`.
- Release work must run the test suite before changing the version or creating a tag.
- Packaging changes must consider the Fedora, Debian, Debian sid, and Arch jobs in `.github/workflows/release.yml`.

## Change safety

- Agents may create branches and pull requests, but must not merge pull requests, push to `main`, create release tags, or publish releases.
- Ask for clarification when acceptance criteria or compatibility requirements are ambiguous.
- Report limitations, skipped tests, and remaining manual Wayland validation explicitly.
