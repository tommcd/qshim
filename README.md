# qshim

> Windows shell to WSL bridge for Amazon Q CLI

## What is this?

The [Amazon Q CLI](https://aws.amazon.com/q/) provides Linux binaries that don't run natively on Windows. **qshim** creates lightweight wrapper scripts that automatically run the WSL version when you type `q`, `qchat`, or `qterm` from your Windows shell—no matter what directory you're in.

## Quick Start

**One-line install:**

```bash
curl -fsSL https://raw.githubusercontent.com/tommcd/qshim/main/install.sh | bash
```

That's it! Now you can use `q`, `qchat`, and `qterm` from your Windows shell.

## Requirements

- **Windows** with a shell environment (Git Bash, PowerShell, or CMD)
- **WSL** (Windows Subsystem for Linux) - [Install WSL](https://learn.microsoft.com/en-us/windows/wsl/install)
- **Amazon Q CLI** installed in WSL (not in Windows)

> **Note:** Currently supports Git Bash (MINGW/MSYS). PowerShell and CMD support coming soon!

## Installation Options

### Option 1: One-line install (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/tommcd/qshim/main/install.sh | bash
```

### Option 2: Manual install

```bash
git clone https://github.com/tommcd/qshim.git
cd qshim
./install.sh
```

The installer will:
- ✅ Check that WSL is available
- ✅ Verify `q` command works in WSL
- ✅ Install shims to `~/.local/bin/`
- ✅ Warn you if `~/.local/bin` is not in your PATH

If you see a PATH warning, add this to your `~/.bashrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## How it Works

Each shim script:
1. Captures your current Windows directory (e.g., `C:\Users\you\project`)
2. Converts it to WSL format using `wslpath` (if available) or regex fallback
3. Sets a minimal PATH in WSL (including `~/.local/bin`) for fast execution
4. Executes the command in WSL with the correct working directory
5. Preserves all arguments, exit codes, and environment context

**Performance note:** Shims avoid using login shells to prevent slow `.bashrc` loading. They set PATH explicitly for speed.

## Example

```bash
# Navigate to any Windows directory
cd /c/Users/you/my-project

# Run q - it works seamlessly!
q chat "explain this code"

# The command automatically runs in WSL at /mnt/c/users/you/my-project
```

## Uninstall

```bash
rm ~/.local/bin/q ~/.local/bin/qchat ~/.local/bin/qterm
```

## Troubleshooting

**Q: "WSL not found"**
A: Install WSL: `wsl --install` in PowerShell (as admin)

**Q: "'q' command not found in WSL"**
A: Install Amazon Q CLI in WSL first:
```bash
wsl
# Then follow the Linux installation instructions for Q
```

**Q: "command not found: q" after install**
A: Add `~/.local/bin` to your PATH (see Installation section)

**Q: Issues with paths containing spaces or special characters?**
A: The shims use proper quoting and escaping. If you encounter issues, please report them with details.

**Q: Shims are slow or hang**
A: If Q CLI is installed in a non-standard location, edit the shims to include your custom path in the PATH export statement.

## Testing

Run the test suite to verify your installation:

```bash
./test.sh
```

The test suite checks:
- Path conversion for various drive letters and formats
- Handling of spaces in paths
- WSL availability and Q CLI detection
- Exit code preservation

## Known Limitations

- **Network paths** (`\\server\share`) are not supported
- **Non-standard WSL mount points**: Assumes default `/mnt/` prefix
- **Multiple WSL distros**: Uses your default WSL distribution (configurable via `wsl -d`)

## Contributing

Issues and pull requests welcome! This is a simple project—feel free to fork and modify.

## License

MIT License - see [LICENSE](LICENSE) file for details.
