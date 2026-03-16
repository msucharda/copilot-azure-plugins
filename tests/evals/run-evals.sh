#!/usr/bin/env bash
set -euo pipefail

# Deterministic Content Eval Runner
# Checks agent/skill markdown for required and forbidden patterns.
# Each assertion encodes a lesson learned from real deployment failures.

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PASS=0
FAIL=0

# --- Assert helpers ---

assert_contains() {
  local plugin="$1" file_pattern="$2" pattern="$3" reason="$4"
  local found=0
  for f in "$REPO_ROOT/plugins/$plugin"/$file_pattern; do
    [ -f "$f" ] || continue
    if grep -qi "$pattern" "$f" 2>/dev/null; then
      found=1
      break
    fi
  done
  if [ $found -eq 1 ]; then
    PASS=$((PASS + 1))
  else
    echo "  ❌ FAIL: '$pattern' not found in $plugin/$file_pattern"
    echo "     Reason: $reason"
    FAIL=$((FAIL + 1))
  fi
}

assert_not_contains() {
  local plugin="$1" file_pattern="$2" pattern="$3" reason="$4"
  local found=0
  for f in "$REPO_ROOT/plugins/$plugin"/$file_pattern; do
    [ -f "$f" ] || continue
    if grep -qi "$pattern" "$f" 2>/dev/null; then
      found=1
      echo "  ❌ FAIL: '$pattern' found in $plugin/$file_pattern (should NOT be there)"
      echo "     Reason: $reason"
      FAIL=$((FAIL + 1))
      break
    fi
  done
  if [ $found -eq 0 ]; then
    PASS=$((PASS + 1))
  fi
}

echo "=== Content Evals ==="
echo ""

# Source plugin-specific eval files (exclude this file)
for eval_file in "$REPO_ROOT/tests/evals/"*-evals.sh; do
  [ -f "$eval_file" ] || continue
  [ "$(basename "$eval_file")" = "run-evals.sh" ] && continue
  echo "📋 Running $(basename "$eval_file")..."
  source "$eval_file"
  echo ""
done

echo "=== Results ==="
echo "✅ $PASS passed, ❌ $FAIL failed"
if [ $FAIL -eq 0 ]; then
  exit 0
else
  exit 1
fi
