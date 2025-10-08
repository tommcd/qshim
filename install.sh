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

WSL_ENV_SETUP='export PATH="\$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:\$PATH";'

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

log_info "Installing shims to $INSTALL_DIR..."
install -m 755 "$SCRIPT_DIR/w" "$INSTALL_DIR/w"
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
    if [[ $Q_AVAILABLE -eq 1 ]]; then
        log_info "You can now use: w (WSL wrapper), q, qchat, qterm"
    else
        log_info "You can now use: w (WSL wrapper)"
        log_warn "Install Amazon Q CLI in WSL to use q, qchat, qterm"
    fi
fi
