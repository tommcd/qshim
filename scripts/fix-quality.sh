#!/bin/bash
# Auto-format shell scripts and Markdown docs
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for tool in shfmt mdformat; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "[fix-quality] error: required tool '$tool' is not installed" >&2
    echo "Install instructions: https://github.com/tommcd/wshims#quality-checks" >&2
    exit 1
  fi
done

mapfile -t SHELL_FILES < <(cd "$REPO_ROOT" && shfmt -f .)
for i in "${!SHELL_FILES[@]}"; do
  SHELL_FILES[i]="${SHELL_FILES[i]//\\/\/}"
done

if ((${#SHELL_FILES[@]} == 0)); then
  echo "[fix-quality] no shell scripts found"
else
  echo "[fix-quality] Formatting ${#SHELL_FILES[@]} shell scripts with shfmt"
  (
    cd "$REPO_ROOT"
    shfmt -w -i 2 -ci -bn "${SHELL_FILES[@]}"
  )
fi

echo "[fix-quality] Formatting Markdown with mdformat"
(cd "$REPO_ROOT" && mdformat README.md CHANGELOG.md CONTRIBUTING.md)

echo "[fix-quality] Done"
