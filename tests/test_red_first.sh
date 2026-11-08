#!/bin/bash
# The red-first check in implement, and the known-gaps file
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/tests/lib.sh"

I="$PLUGIN/commands/implement.md"
for s in \
  'red-first check' \
  '#### Phase 2.5: Red-first check' \
  'natural red' \
  'forced red' \
  'An undefined step, a timeout, a setup or auth error, or a compile or type error is not a red.' \
  'Never break a `.feature` file or a data file.' \
  'restore the original text and check that the diff against it is empty' \
  'not seen red' \
  'keeps the unautomated tag' \
  'Red-first:' \
  'a red-first line that is not "not seen red"' \
  'a break left behind by an interrupted run'; do
  assert_contains "$I" "$s"
done
first_line() { grep -nF -- "$2" "$1" 2>/dev/null | head -1 | cut -d: -f1; }
a=$(first_line "$I" '#### Phase 2.5: Red-first check'); b=$(first_line "$I" '#### Phase 3: Full Scenario Verification')
if [ -n "$a" ] && [ -n "$b" ] && [ "$a" -lt "$b" ]; then pass; else fail "Phase 2.5 (line ${a:-none}) is not before Phase 3 (line ${b:-none})"; fi

# the check lives in implement only
for f in "$PLUGIN/commands/run.md" "$PLUGIN/agents/verifier.md" "$PLUGIN/commands/design.md" "$PLUGIN/commands/discover.md"; do
  if grep -qiF 'red-first' "$f"; then fail "$f mentions the red-first check"; else pass; fi
done

# no new config row for it
if grep -qiF 'red_first' "$PLUGIN/bdd-config.template.md"; then fail "the template has a red_first row"; else pass; fi

# the known-gaps file: each gap has an id and four parts
G="$ROOT/docs/known-gaps.md"
assert_file "$G"
n=$(grep -c '^### G[0-9]' "$G" 2>/dev/null)
[ "${n:-0}" -ge 5 ] && pass || fail "known-gaps.md has fewer than 5 gaps ($n)"
for field in '**Not checked.**' '**Why.**' '**Closed when.**'; do
  c=$(grep -cF -- "$field" "$G" 2>/dev/null)
  assert_equals "$n" "$c" "every gap has $field"
done
ids=$(grep -o '^### G[0-9]*' "$G" 2>/dev/null | sort | uniq -d | wc -l | tr -d ' ')
assert_equals 0 "$ids" "gap ids are unique"
assert_contains "$ROOT/README.md" 'docs/known-gaps.md'
assert_contains "$ROOT/docs/README.md" 'known-gaps.md'

finish
