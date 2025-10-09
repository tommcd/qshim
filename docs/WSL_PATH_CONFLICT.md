# WSL PATH Pollution: When Windows Shims Conflict with Linux Commands

## Executive Summary

When installing Windows shell shims to `~/.local/bin` for bridging Git Bash to WSL, those same scripts become visible within WSL itself due to Windows PATH being appended to the Linux `$PATH` (via `appendWindowsPath=true`). Without proper WSL detection, these shims can interfere with WSL shell initialization, causing errors and even preventing WSL from starting.

**The fundamental principle**: Windows shims for WSL should **NEVER** be executed from inside WSL - this makes no sense! A shim designed to *launch* WSL cannot function correctly when already *inside* WSL. Therefore, the PRIMARY fix is to detect the WSL environment and either pass through to the native command or exit gracefully.

**Key insight**: `appendWindowsPath=true` works exactly as designed - Windows paths ARE appended (come last). However, because bash can find executable scripts in multiple PATH locations, and shell initialization scripts may call commands before all PATH setup is complete, Windows shims can still be executed from WSL if they don't explicitly detect and handle this scenario.

______________________________________________________________________

## Quick Fix: Prevent WSL PATH Pollution (Optional)

If you want to **completely avoid** Windows shims being visible in WSL, add this to the **top** of your WSL `~/.bashrc`:

```bash
# Remove all Windows paths from PATH (keep only Linux paths)
if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
  PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "^/mnt/[c-z]" | tr '\n' ':' | sed 's/:$//')
  export PATH
fi
```

**What this does:**

- Filters out all `/mnt/c/*` paths (Windows directories mounted in WSL)
- Keeps only Linux paths (`/usr/bin`, `/home/...`, etc.)
- Runs only in WSL (checks `WSL_DISTRO_NAME`)
- Must be at the TOP of `.bashrc` (before anything else runs)

**Result**: Windows shims at `/mnt/c/Users/.../.local/bin/` become invisible to WSL, even though `appendWindowsPath=true` is still set.

**Trade-off**: You can't run Windows executables by name from WSL (e.g., `notepad.exe` won't work - you'd need the full path `/mnt/c/Windows/System32/notepad.exe`).

**Alternative (more conservative)**: Just remove your Windows `~/.local/bin` specifically:

```bash
# Remove only Windows ~/.local/bin from PATH (more surgical)
if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
  PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "^/mnt/c/Users/$USER/\.local/bin" | tr '\n' ':' | sed 's/:$//')
  export PATH
fi
```

This keeps other Windows paths (for running Windows tools) but removes just the problematic shims directory.

______________________________________________________________________

## The Bugs in Detail

### Initial Setup

The `wshims` project provides lightweight wrapper scripts to run Linux tools from Windows shells (Git Bash, PowerShell, CMD) via WSL. These shims are installed to `~/.local/bin` on the Windows side:

```bash
# ~/.local/bin/w (Windows)
#!/bin/bash
WIN_DIR="$(pwd -W 2>/dev/null || pwd)"
WSL_PATH=$(echo "$WIN_DIR" | sed -e 's|^\([A-Za-z]\):|/mnt/\L\1|' ...)
exec wsl.exe bash -c "cd '$WSL_PATH' && $ARGS"
```

```bash
# ~/.local/bin/q (Windows)
#!/bin/bash
exec w q "$@"
```

When installed, these become visible in WSL at `/mnt/c/Users/<user>/.local/bin/`.

### Bug #1: Startup Error Messages

**Symptom**: After installing shims, WSL login shells produced this error twice:

```
w: unrecognized option '--rcfile'

Usage:
 w [options] [user]

Options:
 -h, --no-header     do not print header
 -u, --no-current    ignore current process username
 ...
```

**Root Cause**: Amazon Q's shell initialization (`~/.bashrc` → `bashrc.post.bash`) runs:

```bash
eval "$(q init bash post --rcfile bashrc)"
```

The chain of events:

1. WSL starts bash, sources `~/.bashrc`
1. Amazon Q init runs `q init bash post --rcfile bashrc`
1. WSL finds `/home/<user>/.local/bin/q` (correct WSL binary) first in PATH
1. **However**, the Windows shim at `/mnt/c/Users/<user>/.local/bin/q` *also* exists
1. Without WSL detection, the Windows `q` shim executes: `exec w q "$@"`
1. This calls `w q init bash post --rcfile bashrc`
1. The Linux `/usr/bin/w` command (who is logged on) receives these arguments
1. Linux `w` doesn't understand `--rcfile` → error

**How the Windows shim got executed from WSL** (the critical question):

The Windows shim at `/mnt/c/Users/<user>/.local/bin/q` became visible in WSL's PATH because:

1. **WSL default behavior**: `appendWindowsPath=true` in `/etc/wsl.conf` (default setting)
1. **Windows PATH includes**: `C:\Users\<user>\.local\bin` (where we installed shims)
1. **Result**: `/mnt/c/Users/<user>/.local/bin` appears in WSL's `$PATH`

When Amazon Q's bashrc runs `command -v q`, bash searches PATH and CAN find the Windows shim at `/mnt/c/.../q`, even though the real WSL binary exists at `/home/<user>/.local/bin/q`.

**Why didn't the WSL binary win?**

- The user's `~/.bashrc` adds `/home/<user>/.local/bin` to PATH at line 238
- Amazon Q's post script is sourced at line 260 (AFTER the local bin is added)
- Amazon Q's script adds `/home/<user>/.local/bin` AGAIN to the end if not found
- Under some conditions (timing, shell type, or PATH manipulation), `command -v q` could find the Windows shim
- More importantly: **even when the WSL binary is found, if it's called from a script that later calls other commands, those subsequent calls might find the Windows shims**

**The fundamental flaw**: The Windows shims had NO WSL detection. When executed inside WSL (regardless of how they got there), they tried to launch WSL-from-within-WSL, causing the chain of errors.

### Bug #2: WSL Won't Start (Critical)

**Symptom**: After initial fixes, typing `wsl` to start an interactive shell failed:

```bash
❯ wsl
Error: qterm not found in WSL

❯ wsl
(exits immediately with no error - silent failure)
```

**Root Cause**: Amazon Q Terminal (`qterm`) launch logic in bashrc:

- When WSL starts interactively, Amazon Q tries to launch `qterm` wrapper
- Without WSL detection, Windows `qterm` shim at `/mnt/c/.../qterm` executes
- Early fix: shim exited with error → broke WSL startup completely
- Second fix: shim exited silently (status 0) → WSL appeared to start but exited immediately
- `qterm` is supposed to be a long-running interactive wrapper, not exit immediately

**Solution**: The `qterm` shim must:

1. Detect it's running in WSL
1. Find the real WSL `qterm` binary at `/home/<user>/.local/bin/qterm`
1. Execute that instead of trying to launch WSL-from-within-WSL
1. If real `qterm` doesn't exist, fall back to `bash` (not exit)

### Bug #3: Git Bash Path Format

**Symptom**: Paths in Git Bash format (`/c/Users/...`) weren't converted to WSL format (`/mnt/c/Users/...`).

**Root Cause**: The `w` script gets the current directory via:

```bash
WIN_DIR="$(pwd -W 2>/dev/null || pwd)"
```

- `pwd -W` returns `C:/Users/...` (Windows format) ✓
- `pwd` returns `/c/Users/...` (Git Bash format) ← fallback case

The sed pattern only matched `C:` (with colon), not `/c/` (without colon):

```bash
# BROKEN: only converts C: format
sed -e 's|^\([A-Za-z]\):|/mnt/\L\1|'

# FIXED: also converts /c/ format
sed -e 's|^\([A-Za-z]\):|/mnt/\L\1|' -e 's|^/\([a-z]\)/|/mnt/\1/|'
```

## Understanding `appendWindowsPath`

### The Setting is NOT Misleading

The `/etc/wsl.conf` setting works exactly as documented:

```ini
[interop]
appendWindowsPath = true  # Append Windows PATH to Linux $PATH (DEFAULT)
```

**Verification in WSL**:

```bash
$ echo $PATH | tr ':' '\n' | head -5
/home/<user>/.local/bin    # Linux (FIRST)
/usr/local/bin              # Linux
/usr/bin                    # Linux
...

$ echo $PATH | tr ':' '\n' | tail -5
...
/mnt/c/Windows/system32     # Windows (LAST)
/mnt/c/Users/.../bin        # Windows (APPENDED ✓)
```

Windows paths truly ARE appended (added to the end). The confusion arises from:

1. Multiple commands with the same name existing in both environments
1. Scripts calling other scripts, creating resolution chains
1. Shell initialization running complex eval commands
1. Without WSL detection, Windows shims don't know they shouldn't run in WSL

## The Fixes Applied

### Core Principle: Windows Shims Must NEVER Run Inside WSL

**The most important fix** is NOT adjusting PATH order or WSL configuration - it's making the shims themselves WSL-aware.

**Why this is the right approach:**

1. **Portable** - works regardless of user's WSL configuration
1. **Defensive** - handles all scenarios where the shim might be invoked from WSL
1. **Explicit** - the shim knows its purpose and refuses to run in the wrong environment
1. **Graceful** - passes through to native commands or exits cleanly

**The pattern**: Every Windows→WSL shim MUST start with:

```bash
# Detect if running inside WSL
if [[ -n "${WSL_DISTRO_NAME:-}" ]] || [[ "$(uname -r)" == *microsoft* ]]; then
  # Find and execute the real native command, OR exit gracefully
  # NEVER try to launch WSL from within WSL!
fi
```

This is **more important** than any PATH manipulation because:

- PATH order can change based on shell type, initialization order, and user configuration
- Scripts can be invoked directly by full path, bypassing PATH entirely
- Shell initialization can run in complex orders
- **Bottom line**: If a Windows shim CAN be executed from WSL, it eventually WILL be

______________________________________________________________________

### Fix 1: WSL Detection in `w` Shim

**File**: `src/w` (lines 8-19)

```bash
#!/bin/bash
# WSL wrapper - runs commands in WSL from current Windows directory

# If already running inside WSL, pass through to the real w command
if [[ -n "${WSL_DISTRO_NAME:-}" ]] || [[ "$(uname -r)" == *microsoft* ]]; then
  # We're inside WSL - this script shouldn't run here
  # Try to find and execute the real 'w' command (Linux who command)
  real_w=$(PATH="${PATH#/mnt/c*}" command -v w 2>/dev/null | grep -v "\.local/bin/w" | head -1)
  if [[ -n "$real_w" ]]; then
    exec "$real_w" "$@"
  else
    echo "Error: 'w' shim should only run from Windows, not from within WSL" >&2
    exit 1
  fi
fi

# Continue with Windows → WSL bridging logic
WIN_DIR="$(pwd -W 2>/dev/null || pwd)"
...
```

**Detection Methods**:

1. `WSL_DISTRO_NAME` environment variable (set by WSL)
1. `uname -r` contains "microsoft" (WSL kernel signature)

**Behavior**: When invoked from within WSL, passes through to Linux `/usr/bin/w`.

### Fix 2: WSL Detection in `q` Shim with Graceful Degradation

**File**: `src/q` (lines 4-21)

```bash
#!/bin/bash
# Git Bash shim for Amazon Q CLI - runs via WSL using 'w' wrapper

# If running inside WSL, execute the real q command instead of the shim
if [[ -n "${WSL_DISTRO_NAME:-}" ]] || [[ "$(uname -r)" == *microsoft* ]]; then
  # Find the real q binary in WSL (check common locations)
  if [[ -x "$HOME/.local/bin/q" ]] && [[ ! "$HOME/.local/bin/q" -ef "$0" ]]; then
    exec "$HOME/.local/bin/q" "$@"
  elif [[ -x "$HOME/q/bin/q" ]]; then
    exec "$HOME/q/bin/q" "$@"
  else
    # Try to find it in PATH, excluding Windows paths
    real_q=$(PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "^/mnt/c" | tr '\n' ':') command -v q 2>/dev/null)
    if [[ -n "$real_q" ]]; then
      exec "$real_q" "$@"
    fi
    # If q doesn't exist in WSL, exit silently (don't break shell startup)
    exit 0
  fi
fi

exec w q "$@"
```

**Strategy**:

- Check explicit paths first (faster, more reliable)
- Verify found file is not itself (using `-ef` test)
- Fall back to PATH search with `/mnt/c` filtered out
- Exit silently (status 0) if not found (won't break shell initialization)

### Fix 3: WSL Detection in `qterm` Shim with Interactive Fallback

**File**: `src/qterm` (lines 4-14)

```bash
#!/bin/bash
# Git Bash shim for Amazon Q Terminal - runs via WSL using 'w' wrapper

# If running inside WSL, this shim should not run
if [[ -n "${WSL_DISTRO_NAME:-}" ]] || [[ "$(uname -r)" == *microsoft* ]]; then
  # Check common WSL qterm locations (must be in Linux filesystem, not /mnt/c)
  for qterm_path in "$HOME/.local/bin/qterm" "/usr/local/bin/qterm" "$HOME/q/bin/qterm"; do
    if [[ -x "$qterm_path" && "$qterm_path" != "$0" && "$qterm_path" != /mnt/c/* ]]; then
      exec "$qterm_path" "$@"
    fi
  done
  # qterm doesn't exist in WSL - start a regular shell instead (don't exit!)
  exec bash "$@"
fi

exec w qterm "$@"
```

**Critical difference**: Unlike `q`, the `qterm` command is expected to be a **long-running interactive process**.

**Why fallback to bash**: When Amazon Q's initialization tries to launch `qterm` and it's not installed in WSL:

- **Wrong**: `exit 0` → shell exits immediately, user sees nothing
- **Wrong**: `exit 1` → error breaks WSL startup
- **Right**: `exec bash "$@"` → user gets a regular bash shell

### Fix 4: Git Bash Path Format Support

**File**: `src/w` (lines 14-16)

```bash
# Before (BROKEN for Git Bash paths)
WSL_PATH=$(echo "$WIN_DIR" | sed -e 's|^\([A-Za-z]\):|/mnt/\L\1|' -e 's|\\|/|g')

# After (handles all three formats)
WSL_PATH=$(echo "$WIN_DIR" | sed \
  -e 's|^\([A-Za-z]\):|/mnt/\L\1|' \     # C: → /mnt/c
  -e 's|^/\([a-z]\)/|/mnt/\1/|' \        # /c/ → /mnt/c/ (NEW)
  -e 's|\\|/|g')                          # \ → /
```

**Handles three path formats**:

1. `C:\Users\test` → `/mnt/c/Users/test` (Windows backslash)
1. `C:/Users/test` → `/mnt/c/Users/test` (Windows forward slash)
1. `/c/Users/test` → `/mnt/c/Users/test` (Git Bash format - **fixed**)

### Fix 5: Corrected Test Suite

**File**: `scripts/test.sh` (lines 67-74)

```bash
# Before (WRONG TEST - verified the bug!)
log_info "Test 5: Forward slashes (Git Bash /c/ style)"
RESULT=$(printf '%s' "/c/Users/test" | sed ...)
if [ "$RESULT" = "/c/Users/test" ]; then
  log_pass "Forward slashes pass through unchanged"  # WRONG
fi

# After (CORRECT TEST)
log_info "Test 5: Git Bash path format (/c/ -> /mnt/c/)"
RESULT=$(printf '%s' "/c/Users/test" | sed ...)
if [ "$RESULT" = "/mnt/c/Users/test" ]; then
  log_pass "Git Bash path converts correctly"  # CORRECT
fi
```

## Results

### Before Fixes

```bash
# WSL startup
$ wsl bash -l
w: unrecognized option '--rcfile'
w: unrecognized option '--rcfile'
<user>@machine:~$

# Interactive WSL completely broken
$ wsl
Error: qterm not found in WSL
```

### After Fixes

```bash
# WSL startup - clean
$ wsl bash -l
<user>@machine:~$

# Interactive WSL works
$ wsl
<user>@machine:~$  # Interactive shell starts correctly
```

### Verification

**From Windows Git Bash** (shims work as intended):

```bash
$ cd /c/Users/<user>/project
$ w pwd
/mnt/c/Users/<user>/project

$ q --version
Amazon Q version x.y.z
```

**From WSL** (native commands work, shims pass through):

```bash
$ w  # Calls /usr/bin/w (Linux who command)
 08:20:19 up 12:41,  1 user,  load average: 0.99, 0.58, 0.23
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU  WHAT
<user>  pts/1    -                Wed16   15:25m  1.43s  1.30s bash (qterm)

$ q --version  # Calls /home/<user>/.local/bin/q (WSL binary)
Amazon Q version x.y.z

$ qterm  # Launches real qterm or falls back to bash
(interactive terminal)
```

**All tests pass**:

```bash
$ ./scripts/test.sh
✓ C: drive path converts correctly
✓ Lowercase drive letter converts correctly
✓ D: drive path converts correctly
✓ Path with spaces converts correctly
✓ Git Bash path converts correctly (NEW FIX)
✓ WSL is available
✓ Q CLI found in WSL

Passed: 7
Failed: 0
```

______________________________________________________________________

## Addendum: Alternative WSL Configuration Approaches

While the fixes above make the shims robust, users could alternatively configure WSL to prevent Windows PATH pollution. Here are two approaches:

### Option A: Disable Windows PATH Appending

**File**: `/etc/wsl.conf`

```ini
[automount]
enabled = true        # Still mount C:\ as /mnt/c
root = /mnt/

[interop]
enabled = true        # Still allow running .exe files
appendWindowsPath = false  # DON'T add Windows PATH to $PATH
```

**Activate**:

```bash
# Edit the file
sudo nano /etc/wsl.conf

# Restart WSL
wsl --shutdown
```

**Pros**:

- Completely eliminates Windows PATH pollution
- Linux environment is "pure" - only Linux paths in `$PATH`
- No chance of Windows scripts interfering with Linux commands

**Cons**:

- Can't run Windows executables by name alone: `code.exe` won't work, must use full path `/mnt/c/Program Files/Microsoft VS Code/bin/code.exe`
- Breaks workflows that depend on seamless Windows/Linux tool mixing
- Users must explicitly add needed Windows paths to their `~/.bashrc`:
  ```bash
  # If you need specific Windows tools
  export PATH="$PATH:/mnt/c/Program Files/Git/cmd"
  export PATH="$PATH:/mnt/c/Windows/System32"
  ```

**When to use**: If you primarily work in Linux and rarely invoke Windows tools from WSL, or you're willing to manage Windows paths explicitly.

### Option B: Reorder PATH to Guarantee Linux-First

Keep `appendWindowsPath=true` but use shell initialization to ensure Linux paths always take precedence and Windows paths are deduplicated to the end.

**File**: `/etc/profile.d/99-wsl-repath.sh` (create new)

```bash
#!/bin/bash
# Reorder PATH: Linux entries first, Windows last, no duplicates

reorder_wsl_path() {
  IFS=: read -r -a parts <<<"$PATH"
  linux=(); win=()

  # Detect Windows paths
  is_win() {
    case "$1" in
      /mnt/[c-zC-Z]/*|[A-Za-z]:\\*) return 0 ;;
      *) return 1 ;;
    esac
  }

  # Split into Linux vs Windows, dedup
  seen=''
  for p in "${parts[@]}"; do
    [ -n "$p" ] || continue
    case ":$seen:" in *":$p:"*) continue ;; esac  # Skip duplicates
    seen="${seen:+$seen:}$p"
    if is_win "$p"; then
      win+=("$p")
    else
      linux+=("$p")
    fi
  done

  # Rebuild: Linux first, then Windows
  PATH="$(IFS=:; printf '%s' "${linux[*]}")"
  [ ${#linux[@]} -gt 0 ] && [ ${#win[@]} -gt 0 ] && PATH="$PATH:"
  PATH="$PATH$(IFS=:; printf '%s' "${win[*]}")"
  export PATH
}

reorder_wsl_path
```

**Install**:

```bash
# Create the script
sudo tee /etc/profile.d/99-wsl-repath.sh >/dev/null <<'EOF'
#!/bin/bash
reorder_wsl_path() {
  IFS=: read -r -a parts <<<"$PATH"
  linux=(); win=()
  is_win() { case "$1" in /mnt/[c-zC-Z]/*|[A-Za-z]:\\*) return 0;; *) return 1;; esac; }
  seen=''
  for p in "${parts[@]}"; do
    [ -n "$p" ] || continue
    case ":$seen:" in *":$p:"*) continue;; esac
    seen="${seen:+$seen:}$p"
    if is_win "$p"; then win+=("$p"); else linux+=("$p"); fi
  done
  PATH="$(IFS=:; printf '%s' "${linux[*]}")"
  [ ${#linux[@]} -gt 0 ] && [ ${#win[@]} -gt 0 ] && PATH="$PATH:"
  PATH="$PATH$(IFS=:; printf '%s' "${win[*]}")"
  export PATH
}
reorder_wsl_path
EOF

# Make executable
sudo chmod 0644 /etc/profile.d/99-wsl-repath.sh

# Source from ~/.bashrc for non-login shells
grep -qxF '[ -r /etc/profile.d/99-wsl-repath.sh ] && . /etc/profile.d/99-wsl-repath.sh' ~/.bashrc || \
  sed -i '1i [ -r /etc/profile.d/99-wsl-repath.sh ] && . /etc/profile.d/99-wsl-repath.sh' ~/.bashrc

# Ensure ~/.bashrc is sourced from login shells
if [ ! -f ~/.bash_profile ]; then
  echo 'if [ -f ~/.bashrc ]; then . ~/.bashrc; fi' >> ~/.bash_profile
fi
```

**What it does**:

1. Splits `$PATH` into Linux entries and Windows entries
1. Removes duplicates (common with multiple `~/.local/bin` entries)
1. Rebuilds `$PATH` with Linux first, Windows last
1. Runs on every shell start (login, interactive, SSH)

**Pros**:

- Keep `appendWindowsPath=true` for convenience
- Windows executables still work by name (e.g., `code.exe`, `notepad.exe`)
- Guarantees Linux commands take precedence
- Cleans up duplicate path entries
- Works across login shells, terminals, and SSH

**Cons**:

- Adds overhead to shell startup (minimal, ~10ms)
- More complex than simply disabling `appendWindowsPath`
- Need to maintain the script if WSL PATH behavior changes

**When to use**: If you want the best of both worlds - seamless Windows tool access AND guaranteed Linux command precedence.

### Comparison: Fix vs. Configure

| Approach | Pros | Cons | Complexity |
|----------|------|------|------------|
| **Fix shims** (implemented) | Works anywhere, no WSL config needed, portable | Requires fixing every shim | Low |
| **Option A: `appendWindowsPath=false`** | Simple, clean Linux environment | Breaks Windows tool access by name | Very Low |
| **Option B: PATH reorder script** | Best of both worlds, comprehensive | Most complex, shell startup overhead | Medium |

### Recommendation

**For the `wshims` project**: The implemented shim fixes are the right choice because:

1. They work regardless of user's WSL configuration
1. Users don't need to modify their WSL settings
1. Shims are explicitly designed for cross-boundary operation
1. The fixes make shims "WSL-aware" which is more robust

**For individual users** experiencing similar issues with other tools:

- **Simple setups**: Use Option A (`appendWindowsPath=false`) if you rarely need Windows tools
- **Advanced setups**: Use Option B (PATH reorder) if you need seamless Windows/Linux integration
- **Custom shims**: Adopt the WSL detection pattern from the wshims fixes

## Key Takeaways

1. **`appendWindowsPath=true` works as documented** - Windows paths ARE appended (come last)
1. **PATH order alone doesn't prevent all conflicts** - scripts visible in multiple locations can interfere with shell initialization
1. **WSL detection is essential** for any Windows→WSL bridge script that might be visible in both environments
1. **Interactive vs non-interactive matters** - commands like `qterm` that should stay running need special handling (fallback to `bash`, not `exit`)
1. **Test what you think you fixed** - the original test was verifying the bug existed, not testing the fix
1. **Graceful degradation** - shims should handle missing commands without breaking the user's environment

## Lessons Learned

### The Diagnostic Journey

The debugging process revealed several layers:

1. **Initial symptom**: Error messages on WSL startup
1. **First diagnosis**: PATH pollution (partially correct)
1. **Second diagnosis**: "Broken WSL q binary" (INCORRECT - the binary was fine!)
1. **Real issue**: Shims didn't detect WSL environment
1. **Critical discovery**: `qterm` shim broke `wsl` command itself
1. **Final understanding**: Interactive commands need different handling than non-interactive ones

### What Made This Tricky

1. **Multiple commands with same name** (`w`, `q`, `qterm`) in different environments
1. **Shell initialization complexity** - Amazon Q's bashrc running eval commands
1. **Non-obvious failures** - `qterm` exiting silently made WSL appear to start then immediately exit
1. **PATH behavior** - Windows paths appended correctly, but shims still caused issues
1. **Testing challenges** - needed to test from both Windows and WSL contexts

### Best Practices for Cross-Boundary Shims

1. **Always detect the target environment** using `WSL_DISTRO_NAME` or kernel version
1. **Check explicit paths first** instead of relying solely on PATH
1. **Exit gracefully** - non-critical commands should exit silently (status 0)
1. **Fallback for interactive commands** - use `exec bash` instead of exit
1. **Avoid self-execution** - use `-ef` test to ensure you're not finding yourself
1. **Filter out cross-mounted paths** - exclude `/mnt/c` when searching for native binaries
1. **Test both directions** - verify shim works from Windows AND doesn't break WSL

______________________________________________________________________

## Quick Reference: How to Avoid This Issue

### For Users Installing wshims

**Option 1: Use the fixed shims** (recommended)

- Install wshims version with WSL detection (the fixes in this article)
- No WSL configuration changes needed
- Shims detect WSL and pass through to native commands

**Option 2: Filter Windows PATH in WSL**
Add to the **top** of `~/.bashrc` in WSL:

```bash
# Remove Windows ~/.local/bin from WSL PATH
if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
  PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "^/mnt/c/Users/$USER/\.local/bin" | tr '\n' ':' | sed 's/:$//')
  export PATH
fi
```

**Option 3: Disable appendWindowsPath** (most aggressive)
Edit `/etc/wsl.conf` in WSL:

```ini
[interop]
enabled = true
appendWindowsPath = false
```

Then: `wsl --shutdown` (from Windows) to restart WSL.

### For Developers Creating Cross-Boundary Shims

**Every Windows→WSL shim MUST start with:**

```bash
#!/bin/bash
# Detect if running inside WSL
if [[ -n "${WSL_DISTRO_NAME:-}" ]] || [[ "$(uname -r)" == *microsoft* ]]; then
  # Option 1: Pass through to native command
  real_cmd=$(PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "^/mnt/c" | tr '\n' ':') command -v COMMAND_NAME)
  [[ -n "$real_cmd" ]] && exec "$real_cmd" "$@"

  # Option 2: Exit gracefully (for non-critical commands)
  exit 0

  # Option 3: Fallback to bash (for interactive commands like qterm)
  exec bash "$@"
fi

# Normal Windows→WSL shim logic follows...
```

**Replace `COMMAND_NAME`** with your actual command (e.g., `q`, `qterm`, etc.)

### Quick Checklist

- [ ] Shims have WSL detection at the top
- [ ] Shims pass through to native commands when in WSL
- [ ] Interactive shims (like `qterm`) fallback to `bash`, not `exit`
- [ ] Non-critical shims `exit 0` silently if not found in WSL
- [ ] Critical shims (like `w`) error if they shouldn't run in WSL
- [ ] Tested from both Windows (Git Bash) AND WSL

______________________________________________________________________

## References

- [Advanced settings configuration in WSL - Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/wsl-config)
- [Working across file systems - Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/filesystems)
- [bash(1) - Linux manual page](https://www.man7.org/linux/man-pages/man1/bash.1.html)
- [wshims GitHub Repository](https://github.com/tommcd/wshims)
