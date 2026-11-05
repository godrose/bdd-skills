#!/bin/bash
# Structure of the eval spike (evals/). The evals themselves are run by hand with `claude plugin eval`.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/tests/lib.sh"

assert_contains "$ROOT/.gitignore" "evals/results/"

for c in init-audit design-vague-ac triage-approval-gate run-zero-tests design-lint-draft; do
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
for s in "claude plugin eval" "--scaffold" "--no-publish" "--ablation none" "--runs 1" "usage" "--judge-model sonnet" "## What the spike found" "Not measured" "Full run: 4 cases" "Baseline run" "Baseline with plugin-only graders" "A rubric must state the property"; do
  assert_contains "$ROOT/evals/README.md" "$s"
done


# design-vague-ac also grades what only the plugin does (from design.md), so the baseline arm can differ
for s in "name: has-step-reuse-audit" "name: audit-has-asserts-column" "name: tags-unautomated-in-specify-only"; do
  assert_contains "$ROOT/evals/design-vague-ac/case.yaml" "$s"
done


# design-lint-draft: a lint row, an old finding in an existing file, and a draft that must pass the lint
L="$ROOT/evals/design-lint-draft"
assert_file "$L/case.yaml"
assert_file "$L/scaffold.sh"
assert_file "$L/fixture/fake-lint.sh"
assert_file "$L/fixture/features/reports.feature"
assert_contains "$L/fixture/.claude/bdd-config.md" 'fake-lint.sh'
assert_contains "$L/fixture/fake-lint.sh" '@TKT-'
assert_not_contains "$L/fixture/features/reports.feature" '@TKT-'
for s in "name: runs-the-lint-row" "name: draft-passes-lint" "name: reports-old-findings-untouched" "name: no-edit-of-existing-files" "name: no-draft-file-left" ".bdd-draft-"; do
  assert_contains "$L/case.yaml" "$s"
done
assert_contains "$ROOT/evals/README.md" "design-lint-draft"

# design-lint-draft needs general Bash (the agent chains commands); the README says so and limits the grant to this case
assert_contains "$ROOT/evals/README.md" '--case design-lint-draft --allow-tools Write Edit Bash'
assert_contains "$ROOT/evals/README.md" 'only for this case'

finish
