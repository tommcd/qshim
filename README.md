# qshim

> Windows shell to WSL bridge for Amazon Q CLI

## What is this?

The [Amazon Q CLI](https://aws.amazon.com/q/) provides Linux binaries that don't run natively on Windows. **qshim** creates lightweight wrapper scripts that automatically run the WSL version when you type `q`, `qchat`, or `qterm` from your Windows shell—no matter what directory you're in.

**Bonus:** Includes `w` - a reusable WSL wrapper that runs any command in WSL from your current Windows directory!

## Quick Start

**One-line install:**

```bash
curl -fsSL https://raw.githubusercontent.com/tommcd/qshim/main/install.sh | bash
```

That's it! Now you can use `q`, `qchat`, `qterm`, and `w` from your Windows shell.

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

The project includes two types of wrappers:

### `w` - General WSL Wrapper
A reusable command that runs anything in WSL from your current Windows directory:
- Converts Windows path to WSL format (`wslpath` or regex fallback)
- Sets a minimal PATH for fast execution (no slow `.bashrc` loading)
- Preserves TTY for interactive commands
- Works with any WSL command or script

### Q CLI Shims (`q`, `qchat`, `qterm`)
Ultra-simple 3-line scripts that just call: `w q "$@"`, `w qchat "$@"`, `w qterm "$@"`

**Performance note:** Uses explicit PATH setting instead of login shells to avoid slow startup times.

## Examples

### Using Q CLI
```bash
# Navigate to any Windows directory
cd /c/Users/you/my-project

# Run Q commands - they work seamlessly!
q chat "explain this code"
q --help
q                          # Interactive mode

# The command automatically runs in WSL at /mnt/c/users/you/my-project
```

### Using `w` for Other Commands
```bash
# Run any WSL command from Windows Git Bash
w ls -la                   # List files in WSL
w python3 script.py        # Run Python in WSL
w                          # Open interactive bash in WSL
w npm install              # Run npm in current directory

# The 'w' command preserves your Windows directory location
cd /c/Users/you/project
w pwd                      # Shows: /mnt/c/users/you/project
```

## Uninstall

```bash
rm ~/.local/bin/w ~/.local/bin/q ~/.local/bin/qchat ~/.local/bin/qterm
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
