# Contributing to qshim

Thanks for your interest in contributing! This is a simple project with minimal dependencies.

## How to Contribute

1. **Fork** the repository
2. **Clone** your fork: `git clone https://github.com/YOUR_USERNAME/qshim.git`
3. **Create a branch**: `git checkout -b feature/your-feature-name`
4. **Make your changes**
5. **Test** your changes on Windows Git Bash
6. **Commit**: `git commit -m "Description of changes"`
7. **Push**: `git push origin feature/your-feature-name`
8. **Open a Pull Request**

## Testing

Before submitting, test on Windows Git Bash:

```bash
# Test the installer
./install.sh

# Test each shim works
q doctor
qchat --help
qterm --help
```

## Code Style

- Keep scripts simple and readable
- Use `shellcheck` if possible to catch issues
- Follow existing conventions in the codebase

## Reporting Issues

Found a bug? Please open an issue with:
- Your Windows version
- Git Bash version (`bash --version`)
- WSL version (`wsl --version`)
- Steps to reproduce
- Error messages

## Questions?

Open an issue for discussion—happy to help!
