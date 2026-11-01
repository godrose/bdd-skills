#!/bin/bash
# Repo protection files: CI runs the suite as a job named "check", the PR template asks the repo's own questions
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/tests/lib.sh"

CI="$ROOT/.github/workflows/ci.yml"
assert_file "$CI"
for s in 'pull_request:' 'push:' '  check:' 'bash tests/run.sh' 'actions/checkout@'; do
  assert_contains "$CI" "$s"
done

TPL="$ROOT/.github/pull_request_template.md"
assert_file "$TPL"
for s in '## Summary' 'bash tests/run.sh' 'Tests failed before the change' 'Plugin version bumped' 'No project names' 'No session links'; do
  assert_contains "$TPL" "$s"
done

assert_file "$ROOT/.github/CODEOWNERS"
assert_contains "$ROOT/.github/CODEOWNERS" '* @godrose'

DB="$ROOT/.github/dependabot.yml"
assert_file "$DB"
assert_contains "$DB" 'package-ecosystem: github-actions'
assert_contains "$DB" 'interval: weekly'

# GNU sed reads the empty string after -i as a file name, so CI on Linux fails. Use sedi from tests/lib.sh.
n=$(grep -n -F --exclude=test_repo.sh "sed -i ''" "$ROOT"/tests/test_*.sh "$ROOT"/scripts/*.sh "$ROOT"/install.sh | wc -l | tr -d " ")
assert_equals 0 "$n" "sed -i with an empty suffix"

finish
