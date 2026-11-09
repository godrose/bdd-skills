#!/bin/bash
# /bdd:deliver: one conversation from a description to verified scenarios, built on the existing commands
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/tests/lib.sh"

D="$PLUGIN/commands/deliver.md"
first_line() { tr -d '\r' < "$1" | grep -nF -- "$2" | head -1 | cut -d: -f1; }
before() { # file, first, second: the first phrase appears on an earlier line than the second
  local a b; a=$(first_line "$1" "$2"); b=$(first_line "$1" "$3")
  if [ -n "$a" ] && [ -n "$b" ] && [ "$a" -lt "$b" ]; then pass; else fail "$1: '$2' is not before '$3' ($a, $b)"; fi
}

# 1 the command exists, has a description and pre-approves nothing
assert_file "$D"
assert_contains "$D" 'description: "'
assert_not_contains "$D" 'allowed-tools'
assert_not_contains "$D" "$(printf '\xe2\x80\x94')"

# 2 the four steps, in order
before "$D" '#### Step 1: Discover' '#### Step 2: Design'
before "$D" '#### Step 2: Design' '#### Step 3: Implement'
before "$D" '#### Step 3: Implement' '#### Step 4: Run'
for r in 'bdd:discover' 'bdd:design' 'bdd:implement' 'bdd:run'; do assert_contains "$D" "$r"; done

# 3 the config, and the same stop as the other commands
assert_contains "$D" 'does not exist, say so and stop'
assert_contains "$D" '`bdd-config.template.md`'
assert_contains "$D" '> Plugin note: if `.claude/bdd-config.md` is missing, tell the user to run `/bdd:init`'

# 4 the size gate
assert_contains "$D" 'size gate'
assert_contains "$D" 'say so in one sentence'

# 5 and 6 two light gates
assert_contains "$D" 'Do not go on until the product manager has approved the checklist'
assert_contains "$D" 'No `.feature` file is written before the go-ahead'
assert_contains "$D" 'either person'
before "$D" 'approved the checklist' 'No `.feature` file is written before the go-ahead'

# 7 and 8 the two kinds of stop
assert_contains "$D" 'A product decision is asked at once'
assert_contains "$D" 'one question'
assert_contains "$D" 'record the answer'
assert_contains "$D" 'A technical stop is parked'
assert_contains "$D" 'three'
assert_contains "$D" 'independent examples go on'
assert_contains "$D" 'developer note'

# 9 approved scenarios are not edited to make a check pass
assert_contains "$D" 'never change an approved scenario or its expected values'

# 10 and 11 the final report
assert_contains "$D" 'passed'
assert_contains "$D" 'failed'
assert_contains "$D" "couldn't be checked"
assert_contains "$D" 'regression line'
assert_contains "$D" 'pull request description'
for s in '@pending' 'manual-only' 'not seen red' 'zero tests'; do assert_contains "$D" "$s"; done
assert_contains "$D" 'a step whose code the increment changed'

# 12 specify-only
assert_contains "$D" 'specify-only'
assert_contains "$D" 'specified and not implemented'

# 13 where records go
assert_contains "$D" 'Decision (YYYY-MM-DD)'
assert_contains "$D" 'out_of_scope_file'
assert_contains "$D" 'revisit when'
assert_contains "$D" 'excluded:'
assert_contains "$D" 'removed:'
assert_contains "$D" 'Never rewrite a line that is already there'
assert_contains "$D" 'leave the old entry'

# 14 deleted features, local git only
assert_contains "$D" 'git log --diff-filter=D'
assert_contains "$D" 'shallow'

# 15 the decision log without its script
assert_contains "$D" 'Nothing was recorded'

# 16 a tracker key with no requirements-sync skill
assert_contains "$D" 'requirements-sync'
assert_contains "$D" 'ask for the text'

# 17 behavior that already exists
assert_contains "$D" 'from code'
assert_contains "$D" 'already works'

# 18 permissions, no resume file, nothing written on an early end
assert_contains "$D" 'pre-approves nothing'
assert_contains "$D" 'a developer must'
assert_contains "$D" 'There is no resume file'
assert_contains "$D" 'If the session ends before the examples are approved, nothing is written'

# the project text rules the other commands follow
if grep -qE '\.claude/(scripts|schemas)/' "$D" 2>/dev/null; then fail "deliver.md has a project-install path"; else pass; fi
if grep -qE 'bdd-(discover|design|implement|run|triage|reconcile|verifier)' "$D" 2>/dev/null; then fail "deliver.md has a project-install skill name"; else pass; fi

# the listings name it
assert_contains "$ROOT/README.md" '/bdd:deliver'
assert_contains "$PLUGIN/README.md" '/bdd:deliver'
assert_contains "$ROOT/docs/README.md" '2026-11-09-deliver.md'

finish
