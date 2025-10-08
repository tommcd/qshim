# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `uninstall.sh` for removing official shims from `~/.local/bin`.
- `scripts/` utilities including the relocated test suite for easier tooling expansion.
- `.pre-commit-config.yaml` skeleton for formatting and linting hooks.
- GitHub Actions workflow that runs linting and integration tests on pushes and pull requests.
- `scripts/fix-quality.sh` helper for formatting Bash and Markdown files.

### Changed

- Moved official shims into `src/` while keeping install destinations unchanged.
- Updated installation instructions and tests to reflect the new layout.
- `scripts/check-quality.sh` now requires `shellcheck`, `shfmt`, and `mdformat` to be installed.

## [0.1.0] - 2025-10-08

### Added

- Introduced `CHANGELOG.md` and documented the first public release.
- Added documentation for creating custom shims and clarified installation/test instructions.

### Changed

- Rebranded the project from **qshim** to **wshims** to reflect broader scope.
- Promoted `w` as the core WSL wrapper and updated README messaging.
- Installer now always installs `w` and downgrades missing Q CLI to a warning.
- `w` now escapes single quotes in paths and opens an interactive bash when invoked without arguments.

### Fixed

- Improved shim performance by avoiding slow login shells and handling installer hangs.

[0.1.0]: https://github.com/tommcd/wshims/releases/tag/v0.1.0
[unreleased]: https://github.com/tommcd/wshims/compare/v0.1.0...HEAD
