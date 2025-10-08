#!/bin/bash
# Aggregate quality checks for shell scripts and markdown files
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for tool in shellcheck shfmt mdformat; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "[check-quality] error: required tool '$tool' is not installed" >&2
    echo "Install instructions: https://github.com/tommcd/wshims#quality-checks" >&2
    exit 1
  fi
done

mapfile -t SHELL_FILES < <(cd "$REPO_ROOT" && shfmt -f .)
for i in "${!SHELL_FILES[@]}"; do
  SHELL_FILES[i]="${SHELL_FILES[i]//\\/\/}"
done

if ((${#SHELL_FILES[@]} == 0)); then
  echo "[check-quality] no shell scripts found"
  echo "[check-quality] Markdown formatting check only"
else
  echo "[check-quality] inspecting ${#SHELL_FILES[@]} shell scripts"

  echo "[check-quality] Bash syntax validation"
  (
    cd "$REPO_ROOT"
    for file in "${SHELL_FILES[@]}"; do
      bash -n "$file"
    done
  )

  echo "[check-quality] shellcheck lint"
  (
    cd "$REPO_ROOT"
    shellcheck --severity=error "${SHELL_FILES[@]}"
  )

  echo "[check-quality] shfmt formatting check"
  (
    cd "$REPO_ROOT"
    shfmt -d -i 2 -ci -bn "${SHELL_FILES[@]}"
  )
fi

echo "[check-quality] mdformat check"
(cd "$REPO_ROOT" && mdformat --check README.md CHANGELOG.md CONTRIBUTING.md)

echo "[check-quality] All checks passed."
