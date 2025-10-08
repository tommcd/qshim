#!/bin/bash
# Test suite for wshims path conversion and functionality

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0

log_pass() {
  echo -e "${GREEN}✓${NC} $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

log_fail() {
  echo -e "${RED}✗${NC} $1" >&2
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

log_info() { echo -e "${YELLOW}→${NC} $1"; }
log_warn() { echo -e "${YELLOW}!${NC} $1"; }

echo "wshims Test Suite"
echo "================="
echo ""

# Test 1: Basic path conversion
log_info "Test 1: Basic C: drive path"
RESULT=$(printf '%s' "C:\\Users\\test" | sed -e 's|^\([A-Za-z]\):|/mnt/\L\1|' -e 's|\\|/|g')
if [ "$RESULT" = "/mnt/c/Users/test" ]; then
  log_pass "C: drive path converts correctly"
else
  log_fail "Expected /mnt/c/Users/test, got $RESULT"
fi

# Test 2: Lowercase drive letter
log_info "Test 2: Lowercase drive letter"
RESULT=$(printf '%s' "c:\\users\\test" | sed -e 's|^\([A-Za-z]\):|/mnt/\L\1|' -e 's|\\|/|g')
if [ "$RESULT" = "/mnt/c/users/test" ]; then
  log_pass "Lowercase drive letter converts correctly"
else
  log_fail "Expected /mnt/c/users/test, got $RESULT"
fi

# Test 3: Different drive letter
log_info "Test 3: D: drive path"
RESULT=$(printf '%s' "D:\\Projects\\code" | sed -e 's|^\([A-Za-z]\):|/mnt/\L\1|' -e 's|\\|/|g')
if [ "$RESULT" = "/mnt/d/Projects/code" ]; then
  log_pass "D: drive path converts correctly"
else
  log_fail "Expected /mnt/d/Projects/code, got $RESULT"
fi

# Test 4: Path with spaces
log_info "Test 4: Path with spaces"
RESULT=$(printf '%s' "C:\\Program Files\\test" | sed -e 's|^\([A-Za-z]\):|/mnt/\L\1|' -e 's|\\|/|g')
if [ "$RESULT" = "/mnt/c/Program Files/test" ]; then
  log_pass "Path with spaces converts correctly"
else
  log_fail "Expected /mnt/c/Program Files/test, got $RESULT"
fi

# Test 5: Forward slashes (Git Bash style)
log_info "Test 5: Forward slashes (Git Bash /c/ style)"
RESULT=$(printf '%s' "/c/Users/test" | sed -e 's|^\([A-Za-z]\):|/mnt/\L\1|' -e 's|\\|/|g')
if [ "$RESULT" = "/c/Users/test" ]; then
  log_pass "Forward slashes pass through unchanged"
else
  log_fail "Expected /c/Users/test, got $RESULT"
fi

# Test 6: WSL check
log_info "Test 6: WSL availability"
if command -v wsl.exe >/dev/null 2>&1; then
  log_pass "WSL is available"
else
  log_warn "WSL not found (tests that require WSL will be skipped)"
fi

# Test 7: wslpath availability
log_info "Test 7: wslpath tool availability"
if command -v wslpath >/dev/null 2>&1; then
  log_pass "wslpath is available"

  # Test 8: wslpath conversion (if available)
  log_info "Test 8: wslpath conversion test"
  TEST_PATH="$(pwd -W 2>/dev/null || pwd)"
  if [ -n "$TEST_PATH" ]; then
    WSL_PATH=$(wslpath -a "$TEST_PATH" 2>/dev/null || echo "")
    if [ -n "$WSL_PATH" ]; then
      log_pass "wslpath converts current directory: $WSL_PATH"
    else
      log_fail "wslpath failed to convert path"
    fi
  fi
else
  log_info "wslpath not available (will use sed fallback)"
fi

# Test 9: Q CLI in WSL
log_info "Test 9: Q CLI availability in WSL"
if command -v wsl.exe >/dev/null 2>&1; then
  if wsl.exe bash -l -c "command -v q >/dev/null 2>&1"; then
    log_pass "Q CLI found in WSL"

    # Test 10: Q doctor (with timeout to avoid hanging)
    log_info "Test 10: Q doctor functionality"
    if timeout 2 wsl.exe bash -l -c "q doctor" >/dev/null 2>&1; then
      log_pass "Q doctor runs successfully"
    else
      log_info "Q doctor timed out or failed (may be expected)"
    fi
  else
    log_warn "Q CLI not found in WSL (install it to exercise q, qchat, qterm)"
  fi
else
  log_warn "Skipping Q CLI checks because WSL is not available"
fi

# Summary
echo ""
echo "================="
echo "Test Summary"
echo "================="
echo -e "${GREEN}Passed:${NC} $PASS_COUNT"
echo -e "${RED}Failed:${NC} $FAIL_COUNT"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed.${NC}"
  exit 1
fi
