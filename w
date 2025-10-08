#!/bin/bash
# WSL wrapper - runs commands in WSL from current Windows directory
# Usage: w [command] [args...]
# Example: w ls -la
#          w q chat "hello"
#          w  (opens interactive bash)

WIN_DIR="$(pwd -W 2>/dev/null || pwd)"

# Use wslpath if available, otherwise fall back to sed conversion
if command -v wslpath >/dev/null 2>&1; then
    WSL_PATH=$(wslpath -a "$WIN_DIR")
else
    WSL_PATH=$(echo "$WIN_DIR" | sed -e 's|^\([A-Za-z]\):|/mnt/\L\1|' -e 's|\\|/|g')
fi

# Escape single quotes by replacing ' with '"'"' for safe use inside single-quoted cd command
WSL_PATH_ESCAPED=$(printf "%s" "$WSL_PATH" | sed "s/'/'\"'\"'/g")

# Build args string - handle empty args case for interactive mode
if [ $# -eq 0 ]; then
    ARGS=""
else
    ARGS=$(printf '%q ' "$@")
fi

# Run in WSL with common PATH locations to avoid slow login shell
# Use exec to preserve TTY for interactive mode
if [ -z "$ARGS" ]; then
    WSL_COMMAND="exec bash"
else
    WSL_COMMAND="exec $ARGS"
fi

exec wsl.exe bash -c "export PATH=\"\$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:\$PATH\"; cd '$WSL_PATH_ESCAPED' && $WSL_COMMAND"
