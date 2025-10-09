# GitHub Workflow Guide

This guide shows how to submit changes to GitHub using two different approaches: creating a Pull Request (PR) or pushing directly to the main branch.

## Prerequisites

- Git installed and configured
- GitHub CLI (`gh`) installed (for PR workflow)
- Repository cloned locally
- Changes committed locally

## Workflow 1: Creating a Pull Request (Recommended)

This is the recommended workflow for collaborative projects. It allows for code review before merging changes.

### Step 1: Create a feature branch

```bash
git checkout -b fix/my-feature-name
```

### Step 2: Make your changes and commit

```bash
# Stage all changes
git add .

# Or stage specific files
git add src/file1.sh src/file2.sh

# Commit with a descriptive message
git commit -m "fix: Add feature description

Detailed explanation of what was fixed/added.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

### Step 3: Push the branch to GitHub

```bash
git push -u origin fix/my-feature-name
```

Output will show:

```
branch 'fix/my-feature-name' set up to track 'origin/fix/my-feature-name'.
remote:
remote: Create a pull request for 'fix/my-feature-name' on GitHub by visiting:
remote:      https://github.com/username/repo/pull/new/fix/my-feature-name
```

### Step 4: Create the Pull Request

```bash
gh pr create --title "Fix: Brief description" --body "$(cat <<'EOF'
## Summary

Brief overview of changes.

## Changes

- Change 1
- Change 2
- Change 3

## Test Plan

- [x] Tests pass
- [x] Feature works as expected

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Output will show the PR URL:

```
https://github.com/username/repo/pull/3
```

### Step 5: Review and Merge (on GitHub)

1. Open the PR URL in your browser
1. Review the changes
1. Request reviews from collaborators (if needed)
1. Address any feedback by pushing additional commits to the same branch
1. Once approved, click "Merge pull request" on GitHub
1. Delete the branch (optional but recommended)

### Step 6: Clean up locally

```bash
# Switch back to main branch
git checkout main

# Pull the merged changes
git pull origin main

# Delete the local feature branch (optional)
git branch -d fix/my-feature-name
```

### When to use PR workflow

- ✅ Working on a team project
- ✅ Want code review before merging
- ✅ Need to run CI/CD checks before merging
- ✅ Want a clear history of what was changed and why
- ✅ Making significant or potentially breaking changes

______________________________________________________________________

## Workflow 2: Direct Push to Main

This workflow pushes changes directly to the main branch without a PR. Use with caution.

### Step 1: Ensure you're on the main branch

```bash
git checkout main

# Pull latest changes first
git pull origin main
```

### Step 2: Make your changes and commit

```bash
# Stage changes
git add .

# Commit
git commit -m "fix: Brief description of changes

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

### Step 3: Push directly to main

```bash
git push origin main
```

### When to use direct push

- ✅ You're the sole maintainer
- ✅ Making trivial changes (typos, README updates)
- ✅ Hotfix for production that needs to go out immediately
- ⚠️ **Not recommended for collaborative projects**

______________________________________________________________________

## Comparison Table

| Aspect | Pull Request | Direct Push |
|--------|--------------|-------------|
| **Review** | Yes - team can review before merge | No - changes go live immediately |
| **CI/CD** | Runs on PR branch before merge | Runs after push to main |
| **Rollback** | Easy - just close PR or revert merge | Harder - need to revert commit |
| **History** | Clean - each PR is a logical unit | Can be messy if many small commits |
| **Speed** | Slower - requires review/approval | Fast - immediate |
| **Safety** | Safer - catches issues before merge | Riskier - no safety net |
| **Best for** | Team projects, significant changes | Solo projects, trivial fixes |

______________________________________________________________________

## Common Commands Reference

### Check current status

```bash
git status
```

### See recent commits

```bash
git log --oneline -5
```

### See what branch you're on

```bash
git branch
```

### Create and switch to new branch

```bash
git checkout -b new-branch-name
```

### Switch to existing branch

```bash
git checkout branch-name
```

### See all branches (local and remote)

```bash
git branch -a
```

### Delete local branch

```bash
git branch -d branch-name
```

### Update local main from remote

```bash
git checkout main
git pull origin main
```

### Check if branch has been pushed

```bash
git branch -vv
```

### See remote URL

```bash
git remote -v
```

______________________________________________________________________

## GitHub PR Best Practices

1. **Use descriptive branch names**: `fix/wsl-detection`, `feature/add-logging`, `docs/update-readme`
1. **Write clear commit messages**: Start with type (fix/feat/docs/refactor) and be specific
1. **Keep PRs focused**: One logical change per PR
1. **Test before pushing**: Run tests locally first
1. **Update documentation**: Include doc changes in the same PR
1. **Link issues**: Reference issue numbers in PR description (`Fixes #123`)
1. **Respond to reviews**: Address feedback promptly
1. **Keep branch up to date**: Merge main into your branch if it's behind

______________________________________________________________________

## Troubleshooting

### PR shows unrelated commits

- Your branch is out of date with main
- Solution: `git checkout main && git pull && git checkout your-branch && git rebase main`

### Can't push - rejected

- Someone else pushed to the branch
- Solution: `git pull --rebase origin branch-name` then `git push`

### Want to undo last commit (not pushed yet)

```bash
git reset --soft HEAD~1  # Keep changes, undo commit
# or
git reset --hard HEAD~1  # Discard changes and commit
```

### Want to undo pushed commit

```bash
git revert HEAD  # Creates new commit that undoes the last one
git push origin branch-name
```

______________________________________________________________________

## Example: Complete PR Workflow

Here's the exact sequence of commands used to create PR #3 in this repository:

```bash
# 1. Create feature branch
git checkout -b fix/wsl-detection-and-path-conversion

# 2. Make changes to files (via editor or other tools)
# ... edit src/w, src/q, src/qchat, src/qterm, scripts/test.sh ...
# ... create docs/WSL_PATH_CONFLICT.md ...

# 3. Stage all changes
git add .

# 4. Commit with detailed message
git commit -m "$(cat <<'EOF'
fix: Add WSL detection to prevent shims from running inside WSL

This commit fixes critical issues where Windows shims were being executed
from within WSL, causing errors and preventing WSL from starting.

## Issues Fixed

1. **WSL Startup Errors**: Windows shims executed during WSL shell initialization
   caused "w: unrecognized option '--rcfile'" errors

2. **WSL Won't Start**: qterm shim broke interactive WSL startup, causing
   immediate exit without error messages

3. **Git Bash Path Conversion**: Paths in /c/Users/... format weren't converted
   to /mnt/c/Users/... for WSL

## Changes

### Shim Files (src/)
- **w**: Added WSL detection, Git Bash path format support (/c/ -> /mnt/c/)
- **q**: Added WSL detection with graceful degradation (exit 0 if not found)
- **qchat**: Added WSL detection with silent exit if not found
- **qterm**: Added WSL detection with bash fallback for interactive sessions

All shims now detect WSL environment via WSL_DISTRO_NAME or kernel signature
and either pass through to native commands or exit gracefully.

### Test Suite (scripts/test.sh)
- Fixed Test 5: Now correctly verifies Git Bash path conversion instead of
  testing that paths pass through unchanged (which was testing the bug!)

### Documentation (docs/)
- Added WSL_PATH_CONFLICT.md: Comprehensive analysis of the issue, root causes,
  fixes applied, and quick reference guide for users and developers

## Key Principle

Windows shims designed to launch WSL should NEVER execute from inside WSL.
The primary fix is WSL detection in the shims themselves, not PATH manipulation.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"

# 5. Push branch to GitHub
git push -u origin fix/wsl-detection-and-path-conversion

# 6. Create pull request
gh pr create --title "Fix WSL detection to prevent shims from running inside WSL" --body "$(cat <<'EOF'
## Summary

This PR fixes critical issues where Windows shims were being executed from within WSL, causing errors and preventing WSL from starting.

## Issues Fixed

- **WSL Startup Errors**: Windows shims executed during WSL shell initialization caused "w: unrecognized option '--rcfile'" errors
- **WSL Won't Start**: qterm shim broke interactive WSL startup, causing immediate exit without error messages
- **Git Bash Path Conversion**: Paths in /c/Users/... format weren't converted to /mnt/c/Users/... for WSL

## Changes

### Shim Files (src/)
- **w**: Added WSL detection, Git Bash path format support (/c/ -> /mnt/c/)
- **q**: Added WSL detection with graceful degradation (exit 0 if not found)
- **qchat**: Added WSL detection with silent exit if not found
- **qterm**: Added WSL detection with bash fallback for interactive sessions

All shims now detect WSL environment via WSL_DISTRO_NAME or kernel signature and either pass through to native commands or exit gracefully.

### Test Suite (scripts/test.sh)
- Fixed Test 5: Now correctly verifies Git Bash path conversion instead of testing that paths pass through unchanged (which was testing the bug!)

### Documentation (docs/)
- Added WSL_PATH_CONFLICT.md: Comprehensive analysis of the issue, root causes, fixes applied, and quick reference guide for users and developers

## Key Principle

**Windows shims designed to launch WSL should NEVER execute from inside WSL.** The primary fix is WSL detection in the shims themselves, not PATH manipulation.

## Test Plan

- [x] All tests pass (7/7 in scripts/test.sh)
- [x] WSL starts successfully without errors
- [x] Git Bash paths (/c/...) convert correctly to WSL paths (/mnt/c/...)
- [x] Shims work correctly from Windows (Git Bash)
- [x] Shims detect WSL and pass through to native commands
- [x] No personal information in documentation

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"

# Result: https://github.com/tommcd/wshims/pull/3

# 7. After PR is reviewed and merged on GitHub, clean up:
git checkout main
git pull origin main
git branch -d fix/wsl-detection-and-path-conversion
```

______________________________________________________________________

## Handling Pull Request Review Comments

When reviewers (human or AI) leave comments on your PR, you need to address them by making changes to the same branch.

### Step 1: View review comments

```bash
# View PR with all comments
gh pr view 3 --comments

# View PR in browser for easier reading
gh pr view 3 --web

# Get inline code review comments as JSON
gh api repos/owner/repo/pulls/3/comments
```

### Step 2: Ensure you're on the PR branch

```bash
# Check current branch
git branch --show-current

# If not on PR branch, switch to it
git checkout fix/my-feature-name

# Make sure branch is up to date
git pull origin fix/my-feature-name
```

### Step 3: Make changes to address comments

```bash
# Edit files manually in your editor
# OR use command-line tools

# Example: If reviewer suggests changing grep pattern
# Edit the file, save changes
```

### Step 4: Test your changes

```bash
# Run test suite
bash scripts/test.sh

# Or run specific tests
npm test  # for Node.js projects
pytest    # for Python projects
```

### Step 5: Commit and push changes

```bash
# Stage the modified files
git add src/file1.sh src/file2.sh

# Commit with reference to review feedback
git commit -m "refactor: Address review feedback - improve robustness

Implemented suggestions from code review:
- Fixed PATH filtering to handle all drives
- Added file identity checks to prevent recursion
- Applied consistent patterns across all files

Addresses: PR #3 review comments

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Push to the same branch (automatically updates the PR)
git push origin fix/my-feature-name
```

**Important**: Pushing to the same branch automatically updates the PR - no need to create a new PR!

### Step 6: Respond to reviewers (optional)

```bash
# Add a comment thanking reviewers and summarizing changes
gh pr comment 3 --body "Thanks for the thorough review! I've addressed all the feedback:

- ✅ Updated PATH filtering to handle all Windows drives
- ✅ Changed to use \`-ef\` for file identity comparison
- ✅ Applied consistent patterns across all shims

Ready for another look!"
```

### Step 7: Request re-review (if needed)

```bash
# Request specific reviewer to look again
gh pr review 3 --request @username

# Or mark PR as ready for review
gh pr ready 3
```

### Common scenarios

**Multiple rounds of feedback**: Repeat steps 3-6 for each round of feedback. Each push updates the PR.

**Responding to specific comments**: Use GitHub web UI to reply directly to inline comments, explaining your changes.

**Disagreeing with feedback**: Politely explain your reasoning in a comment:

```bash
gh pr comment 3 --body "Thanks for the suggestion about X. I considered this but decided to keep the current approach because Y. Let me know if you'd like to discuss further!"
```

**Accepting some, rejecting others**: Address the ones you accept, explain why you're not addressing others.

______________________________________________________________________

## Summary

- **Pull Request workflow**: Create branch → Commit → Push branch → Create PR → Review → Merge on GitHub
- **Direct push workflow**: Commit on main → Push main
- **Recommendation**: Use PR workflow for all but the most trivial changes
- **Key difference**: PRs allow review before changes go to main; direct push is immediate
- **Handling reviews**: Make changes on same branch, push to update PR automatically
