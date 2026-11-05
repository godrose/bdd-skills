#!/bin/bash
# Structure of the eval spike (evals/). The evals themselves are run by hand with `claude plugin eval`.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/tests/lib.sh"

assert_contains "$ROOT/.gitignore" "evals/results/"

for c in init-audit design-vague-ac triage-approval-gate run-zero-tests; do
  d="$ROOT/evals/$c"
  assert_file "$d/case.yaml"
  assert_file "$d/scaffold.sh"
  [ -d "$d/fixture" ] && pass || fail "missing $d/fixture"
  assert_contains "$d/case.yaml" 'schema_version: "1.0"'
  assert_contains "$d/case.yaml" "scaffold_script: scaffold.sh"
  assert_contains "$d/case.yaml" "graders:"
  assert_contains "$d/case.yaml" "type: llm"
  n=$(grep -c '^  - type:' "$d/case.yaml")
  [ "$n" -ge 2 ] && pass || fail "$c has $n graders, expected at least 2"
done

# The installer must not copy evals into a user's project
assert_not_contains "$ROOT/install.sh" "evals"

# Fixtures hold what each case needs
assert_file "$ROOT/evals/init-audit/fixture/.claude/bdd-config.md"
[ -e "$ROOT/evals/init-audit/fixture/src/step-defs" ] && fail "init-audit fixture must lack src/step-defs" || pass
assert_file "$ROOT/evals/run-zero-tests/fixture/fake-test.sh"
assert_contains "$ROOT/evals/run-zero-tests/fixture/fake-test.sh" "No test matches"

# Cost-aware defaults live in the README of the folder
assert_file "$ROOT/evals/README.md"
for s in "claude plugin eval" "--scaffold" "--no-publish" "--ablation none" "--runs 1" "usage" "--judge-model sonnet" "## What the spike found" "Not measured"; do
  assert_contains "$ROOT/evals/README.md" "$s"
done

finish
