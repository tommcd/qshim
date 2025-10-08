# Contributing to wshims

Thanks for your interest in contributing! This is a simple project with minimal dependencies.

## How to Contribute

1. **Fork** the repository
1. **Clone** your fork: `git clone https://github.com/YOUR_USERNAME/wshims.git`
1. **Create a branch**: `git checkout -b feature/your-feature-name`
1. **Make your changes**
1. **Test** your changes on Windows Git Bash
1. **Commit**: `git commit -m "Description of changes"`
1. **Push**: `git push origin feature/your-feature-name`
1. **Open a Pull Request**

## Testing

Before submitting, test on Windows Git Bash:

```bash
# Test the installer
./install.sh

# Run integration tests
./scripts/test.sh

# Test each shim works
q doctor
qchat --help
qterm --help
```

## Code Style

- Keep scripts simple and readable
- Run `./scripts/check-quality.sh` (requires optional dev tools like shellcheck/shfmt/mdformat)
- Follow existing conventions in the codebase

## Tooling

- Install pre-commit hooks (optional but recommended): `pip install pre-commit && pre-commit install`
- Install quality tools locally (`shellcheck`, `shfmt`, `mdformat`) so `./scripts/check-quality.sh` passes.
- Use `./scripts/fix-quality.sh` to auto-format Bash and Markdown files after making changes.
- GitHub Actions runs `scripts/check-quality.sh` and `scripts/test.sh` on every push and pull request.

## Reporting Issues

Found a bug? Please open an issue with:

- Your Windows version
- Git Bash version (`bash --version`)
- WSL version (`wsl --version`)
- Steps to reproduce
- Error messages

## Questions?

Open an issue for discussion—happy to help!
