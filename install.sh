#!/bin/bash
# qshim installer - Git Bash to WSL bridge for Amazon Q CLI
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# Check if on Windows (Git Bash/MINGW)
if [[ ! "$(uname)" =~ MINGW|MSYS ]]; then
    log_error "qshim is for Windows Git Bash only."
    exit 1
fi

# Check WSL available
if ! command -v wsl.exe >/dev/null 2>&1; then
    log_error "WSL not found. Install from: https://learn.microsoft.com/en-us/windows/wsl/install"
    exit 1
fi

# Check if q works in WSL
log_info "Checking if 'q' command exists in WSL..."
if ! wsl.exe bash -c "export PATH=\"\$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:\$PATH\"; command -v q >/dev/null 2>&1"; then
    log_error "'q' command not found in WSL."
    log_error "Please install Amazon Q CLI in WSL first:"
    log_error "  wsl"
    log_error "  # Then follow installation instructions for Linux"
    exit 1
fi

log_info "Testing 'q doctor' in WSL (with timeout)..."
if timeout 3 wsl.exe bash -c "export PATH=\"\$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:\$PATH\"; q doctor" >/dev/null 2>&1; then
    log_info "'q doctor' succeeded"
else
    log_warn "'q doctor' timed out or failed. Continuing anyway..."
fi

# Install to ~/.local/bin
INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log_info "Installing shims to $INSTALL_DIR..."
install -m 755 "$SCRIPT_DIR/q" "$INSTALL_DIR/q"
install -m 755 "$SCRIPT_DIR/qchat" "$INSTALL_DIR/qchat"
install -m 755 "$SCRIPT_DIR/qterm" "$INSTALL_DIR/qterm"

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
    log_info "You can now use: q, qchat, qterm"
fi
