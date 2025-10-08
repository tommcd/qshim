#!/bin/bash
# wshims installer - Git Bash to WSL bridge for running Linux tools via WSL
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

WSL_ENV_SETUP="export PATH=\"\$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:\$PATH\";"

# Check if on Windows (Git Bash/MINGW)
if [[ ! "$(uname)" =~ MINGW|MSYS ]]; then
  log_error "wshims is for Windows Git Bash only."
  exit 1
fi

# Check WSL available
if ! command -v wsl.exe >/dev/null 2>&1; then
  log_error "WSL not found. Install from: https://learn.microsoft.com/en-us/windows/wsl/install"
  exit 1
fi

# Check if q works in WSL (optional)
log_info "Checking if 'q' command exists in WSL..."
if wsl.exe bash -c "${WSL_ENV_SETUP} command -v q >/dev/null 2>&1"; then
  Q_AVAILABLE=1
  log_info "Found 'q' in WSL"
  log_info "Testing 'q doctor' in WSL (with timeout)..."
  if timeout 3 wsl.exe bash -c "${WSL_ENV_SETUP} q doctor" >/dev/null 2>&1; then
    log_info "'q doctor' succeeded"
  else
    log_warn "'q doctor' timed out or failed. Continuing..."
  fi
else
  Q_AVAILABLE=0
  log_warn "'q' not found in WSL. Q shims will be installed but require Q CLI in WSL."
fi

# Install to ~/.local/bin
INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHIMS=(w q qchat qterm)
SHIM_SOURCE_DIR="$SCRIPT_DIR/src"

cleanup_tmp() {
  if [[ -n "${TMP_SHIM_DIR:-}" && -d "$TMP_SHIM_DIR" ]]; then
    rm -rf "$TMP_SHIM_DIR"
  fi
}

if [[ ! -d "$SHIM_SOURCE_DIR" ]]; then
  log_warn "Local shim sources not found. Downloading from GitHub..."
  if ! command -v curl >/dev/null 2>&1; then
    log_error "curl is required to download shims. Please install curl or clone the repository."
    exit 1
  fi
  TMP_SHIM_DIR="$(mktemp -d)"
  trap cleanup_tmp EXIT

  BASE_URL="${WSHIMS_BASE_URL:-https://raw.githubusercontent.com/tommcd/wshims/main/src}"
  for shim in "${SHIMS[@]}"; do
    curl -fsSL "$BASE_URL/$shim" -o "$TMP_SHIM_DIR/$shim"
    chmod +x "$TMP_SHIM_DIR/$shim"
  done
  SHIM_SOURCE_DIR="$TMP_SHIM_DIR"
fi

log_info "Installing shims to $INSTALL_DIR..."
for shim in "${SHIMS[@]}"; do
  install -m 755 "$SHIM_SOURCE_DIR/$shim" "$INSTALL_DIR/$shim"
done

log_info "Installation complete!"

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  log_warn "$HOME/.local/bin is not in your PATH."
  echo ""
  echo "Add this to your $HOME/.bashrc:"
  echo ""
  echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
  echo ""
else
  if [[ $Q_AVAILABLE -eq 1 ]]; then
    log_info "You can now use: w (WSL wrapper), q, qchat, qterm"
  else
    log_info "You can now use: w (WSL wrapper)"
    log_warn "Install Amazon Q CLI in WSL to use q, qchat, qterm"
  fi
fi
