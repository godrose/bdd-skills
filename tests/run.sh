#!/bin/bash
# Runs the scenarios, then the bash test files that have not moved to scenarios yet.
cd "$(dirname "$0")/.." || exit 1
rc=0

RUNNER=node_modules/.bin/cucumber-js
if [ ! -x "$RUNNER" ]; then
  echo "The scenario runner is not installed. Run: npm ci" >&2
  exit 1
fi

echo "== scenarios"
out=$(NODE_OPTIONS="--import tsx" "$RUNNER" 2>&1) || rc=1
printf '%s\n' "$out"
printf '%s\n' "$out" | grep -qE '^[1-9][0-9]* scenarios?' || { echo "No scenario ran. That is not a pass." >&2; rc=1; }

for t in tests/test_*.sh; do
  [ -e "$t" ] || continue
  echo "== $t"
  bash "$t" || rc=1
done
exit $rc
