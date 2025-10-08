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
2. Converts it to WSL format (e.g., `/mnt/c/users/you/project`)
3. Executes the command in WSL with the correct working directory
4. Passes through all arguments and return codes

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

## Contributing

Issues and pull requests welcome! This is a simple project—feel free to fork and modify.

## License

MIT License - see [LICENSE](LICENSE) file for details.
