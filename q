#!/bin/bash
# Git Bash shim for Amazon Q CLI - runs via WSL
WIN_DIR="$(pwd -W 2>/dev/null || pwd)"
WSL_PATH=$(echo "$WIN_DIR" | sed -e 's|^\([A-Za-z]\):|/mnt/\L\1|' -e 's|\\|/|g')
wsl.exe bash -c "cd '$WSL_PATH' && q $(printf '%q ' "$@")"
