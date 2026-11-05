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

# the judge grades one statement per criterion; exact facts are regex graders
for s in "name: scenarios-in-full" "name: names-the-old-finding" "name: no-claim-of-tagging-old-scenario"; do
  assert_contains "$L/case.yaml" "$s"
done
assert_not_contains "$L/case.yaml" "scenarios-in-full-and-old-finding-not-fixed"
n=$(grep -c "type: llm" "$L/case.yaml")
[ "$n" = 1 ] && pass "design-lint-draft has one judge grader" || fail "design-lint-draft has $n judge graders, expected 1"

# design-lint-draft needs general Bash (the agent chains commands); the README says so and limits the grant to this case
assert_contains "$ROOT/evals/README.md" '--case design-lint-draft --allow-tools Write Edit Bash'
assert_contains "$ROOT/evals/README.md" 'only for this case'

finish

# One statement per judge criterion. A compound name ("-and-") marks a bundled criterion.
for c in init-audit design-vague-ac triage-approval-gate run-zero-tests design-lint-draft; do
  if awk '/type: llm/{getline; print}' "$ROOT/evals/$c/case.yaml" | grep -q -- '-and-'; then
    fail "$c has a judge grader with a compound name"
  else
    pass
  fi
done

# Exact facts are regex graders. Only judgment is left to the judge.
D="$ROOT/evals/design-vague-ac/case.yaml"
for s in "name: names-two-statuses" "name: treats-finished-as-open"; do assert_contains "$D" "$s"; done
assert_not_contains "$D" "name: flags-finished-as-ambiguous"
I="$ROOT/evals/init-audit/case.yaml"
for s in "name: says-path-does-not-exist" "name: no-claim-of-writing" "name: asks-before-writing"; do assert_contains "$I" "$s"; done
assert_not_contains "$I" "name: reports-only-and-asks"
R="$ROOT/evals/run-zero-tests/case.yaml"
for s in "name: not-reported-as-pass" "name: treats-as-a-problem"; do assert_contains "$R" "$s"; done
T="$ROOT/evals/triage-approval-gate/case.yaml"
for s in "name: asks-per-item" "name: no-claim-of-writing-records" "name: ok-not-counted-as-the-rules"; do assert_contains "$T" "$s"; done
assert_not_contains "$T" "name: asks-per-item-and-does-not-claim-writes"

# Judge counts: one per clause that needs judgment
for pair in design-vague-ac:1 init-audit:2 run-zero-tests:2 triage-approval-gate:3 design-lint-draft:1; do
  c=${pair%%:*}; want=${pair##*:}
  n=$(grep -c "type: llm" "$ROOT/evals/$c/case.yaml")
  [ "$n" = "$want" ] && pass || fail "$c has $n judge graders, expected $want"
done

# run-zero-tests: the agent chains echo, ls and cat with the test command, so the narrow grant needs them (read-only)
assert_contains "$ROOT/evals/README.md" '--case run-zero-tests'
assert_contains "$ROOT/evals/README.md" '"Bash(echo:*)"'


# Nightly evals workflow: manual first, the schedule is gated by a repo variable, and no plain Bash or PR trigger
W="$ROOT/.github/workflows/evals.yml"
assert_file "$W"
for s in "workflow_dispatch:" "schedule:" "cron:" "vars.EVALS_NIGHTLY" "--trust-plugin" "--max-cost-usd" "--threshold" "--ablation none" "secrets.CLAUDE_CODE_OAUTH_TOKEN" "contents: read" "timeout-minutes" "upload-artifact" "design-lint-draft"; do
  assert_contains "$W" "$s"
done
assert_not_contains "$W" "pull_request"
# an API key would take precedence over the subscription token
assert_not_contains "$W" "ANTHROPIC_API_KEY"
assert_contains "$ROOT/evals/README.md" "setup-token"
assert_not_contains "$W" "push:"
# the token is set on the step that runs the evals, not for the whole job
if grep -qE "^ {0,8}CLAUDE_CODE_OAUTH_TOKEN" "$W"; then fail "CLAUDE_CODE_OAUTH_TOKEN is set above the step level in evals.yml"; else pass; fi
# plain Bash would hand the token to the agent; only the narrow grants are allowed
assert_not_contains "$W" "--allow-tools Write Edit Bash "
assert_contains "$W" 'Bash(sh ./fake-test.sh:*)'
# the lint case needs plain Bash, so it stays out of the loop
assert_not_contains "$W" "for c in init-audit design-vague-ac triage-approval-gate run-zero-tests design-lint-draft"
assert_contains "$ROOT/evals/README.md" "## In CI"
assert_contains "$ROOT/evals/README.md" "EVALS_NIGHTLY"
assert_no_added_emdash tests/test_evals.sh .github/workflows/evals.yml

finish
