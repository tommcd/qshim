#!/bin/bash
# Remove wshims-installed commands from ~/.local/bin
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

if [[ ! "$(uname)" =~ MINGW|MSYS ]]; then
  log_error "wshims uninstall script is intended for Windows Git Bash."
  exit 1
fi

INSTALL_DIR="$HOME/.local/bin"
SHIMS=(w q qchat qterm)
REMOVED=0

for shim in "${SHIMS[@]}"; do
  TARGET="$INSTALL_DIR/$shim"
  if [[ -e "$TARGET" ]]; then
    rm -f "$TARGET"
    log_info "Removed $TARGET"
    REMOVED=1
  else
    log_warn "$TARGET not found"
  fi
done

if [[ $REMOVED -eq 0 ]]; then
  log_warn "No wshims-installed files were found in $INSTALL_DIR."
else
  log_info "Uninstall complete."
fi
