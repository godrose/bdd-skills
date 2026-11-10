#!/bin/bash
# The flow harness for discover (flows/). A fake claude plays the scripted messages.
# The real run, with a real model, is done by hand and is what measures time, usage and variance.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/tests/lib.sh"

F="$ROOT/flows"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
mkdir -p "$T/bin"; cp "$ROOT/tests/fixtures/fake-claude.sh" "$T/bin/claude"; chmod +x "$T/bin/claude"
export PATH="$T/bin:$PATH"

READY='## Readiness
Not ready. Still needed:
- Your answer to the open question.'

# fresh_script <name> <assistant messages...>: a script dir with assistant-N.txt and a pm-N.txt per turn
fresh_script() {
  local d="$T/$1"; shift; rm -rf "$d"; mkdir -p "$d"; local i=1
  for m in "$@"; do printf '%s\n' "$m" > "$d/assistant-$i.txt"; printf 'A. reply %s\n' "$i" > "$d/pm-$i.txt"; i=$((i + 1)); done
  echo "$d"
}
# harness <script dir> [options]: runs fixture a once into $T/out-<name>
harness() {
  local d="$1"; shift
  FAKE_DIR="$d" bash "$F/run.sh" --fixture a --runs 1 --out "$T/out-$(basename "$d")" "$@" > "$d/stdout.txt" 2> "$d/stderr.txt"
}
RUN() { echo "$T/out-$1/a/run-1"; }

# S1 every reply and message is saved in turn order
d=$(fresh_script s1 "What exists: nothing. Q one?" "$READY"); harness "$d"
assert_equals "$(cat "$d/assistant-1.txt")" "$(cat "$(RUN s1)/turn-01-assistant.txt")" "first assistant message saved"
assert_equals "A. reply 1" "$(cat "$(RUN s1)/turn-01-pm.txt")" "first reply saved"
assert_file "$(RUN s1)/turn-02-assistant.txt"

# S2 a readiness line ends the run
assert_contains "$(RUN s1)/meta.json" '"finished": true'
assert_contains "$(RUN s1)/meta.json" '"turns": 2'

# S3 no readiness: stops at the turn cap and says it did not finish
d=$(fresh_script s3 "What exists: x. One?" "More?" "Again?" "Again2?"); harness "$d" --turns 3
assert_contains "$(RUN s3)/meta.json" '"finished": false'
assert_contains "$(RUN s3)/meta.json" '"turns": 3'
assert_contains "$T/out-s3/a/report.md" "did not finish"
assert_contains "$F/run.sh" "TURNS=12"

# S4 the persona card is passed to the small model, and its reply is the next prompt
d=$(fresh_script s4 "What exists: x. One?" "$READY"); harness "$d"
assert_contains "$d/pm-prompt-1.txt" "$(head -1 "$F/personas/$(cat "$F/fixtures/a/persona.txt").md")"
assert_contains "$d/assistant-args-2.txt" "A. reply 1"

# S5 to S8 one table: a message, the rule, held or broken
rule_case() { # <rule> <expected held|broken> <message> [<message>...]  (the last message is the final one)
  local rule="$1" exp="$2"; shift 2
  local d; d=$(fresh_script "r$RANDOM" "$@"); harness "$d" --turns 8
  local got; got=$(awk -F'\t' -v r="$rule" '$1==r {print $2}' "$(RUN "$(basename "$d")")/rules.tsv")
  assert_equals "$exp" "$got" "rule $rule"
}
FIRST_OK='What exists: one scenario covers part of it.
Is that right?'
FIRST_BAD='Is it a monthly or a yearly rule?
What exists: nothing found.'
rule_case look-first held   "$FIRST_OK" "$READY"
rule_case look-first broken "$FIRST_BAD" "$READY"
rule_case look-first held   "What I found:
- A nightly check already marks it.
Is that right?" "$READY"
rule_case one-question held   "$FIRST_OK" "$READY"
rule_case one-question broken "What exists: nothing.
Is it monthly?
Is it yearly?" "$READY"
rule_case one-question held   "What exists: nothing.
Is it monthly?
For the developer:
- Where is the date set?
- Is there a job?

Done." "$READY"
rule_case plain-words held   "$FIRST_OK" "$READY"
rule_case plain-words held   "$FIRST_OK" 'Here is the pack. Save it to `docs/discovery/`?
## Readiness
Ready for `bdd:design`.'
rule_case plain-words broken "What exists: a check in src/loans/overdue.js.
Is that right?" "$READY"
rule_case plain-words broken 'What exists: the `OVERDUE_STATUS` is set.
Is that right?' "$READY"
rule_case plain-words held   'What exists: a status is set.
Is that right?
For the developer:
- src/loans/overdue.js:12' "$READY"
rule_case pack-end held   "$FIRST_OK" "$READY"
rule_case pack-end broken "$FIRST_OK" "Here is the pack. Thanks."
rule_case pack-end held   "$FIRST_OK" "## Readiness
Ready for design."
rule_case pack-end broken "$FIRST_OK" "## Readiness
Not ready."

# S9 and S10 the project stays as it was, except the pack folder
d=$(fresh_script s9 "$FIRST_OK" "$READY"); FAKE_WRITE_AT=1 FAKE_WRITE_FILE=src/new.txt harness "$d"
assert_equals broken "$(awk -F'\t' '$1=="project-untouched" {print $2}' "$(RUN s9)/rules.tsv")" "a new file outside the pack folder"
assert_contains "$(RUN s9)/rules.tsv" "src/new.txt"
d=$(fresh_script s10 "$FIRST_OK" "$READY"); FAKE_WRITE_AT=1 FAKE_WRITE_FILE=docs/discovery/pack.md harness "$d"
assert_equals held "$(awk -F'\t' '$1=="project-untouched" {print $2}' "$(RUN s10)/rules.tsv")" "a file in the pack folder"

# S11 and S12 the report: counts out of the runs, breaks listed, turns and time, no verdict
d=$(fresh_script s11 "What exists: nothing.
One?
Two?" "$READY"); harness "$d" --runs 1
R="$T/out-s11/a/report.md"
assert_contains "$R" "one-question"
assert_contains "$R" "0 of 1"
assert_contains "$R" "run-1"
assert_contains "$R" "message 1"
assert_contains "$R" "turns"
assert_contains "$R" "seconds"
for w in "pass" "fail" "PASS" "FAIL"; do assert_not_contains "$R" "$w"; done

# S13 the fixtures: A has one scenario that covers part of the story, B has none and no screens
na=$(find "$F/fixtures/a" -name '*.feature' | wc -l | tr -d ' '); assert_equals 1 "$na" "fixture a feature files"
ns=$(cat "$F"/fixtures/a/project/features/*.feature | grep -c "^ *Scenario"); assert_equals 1 "$ns" "fixture a scenarios"
nb=$(find "$F/fixtures/b" \( -name '*.feature' -o -name '*.html' -o -name '*.tsx' -o -name '*.vue' \) | wc -l | tr -d ' '); assert_equals 0 "$nb" "fixture b scenarios and screens"
assert_file "$F/fixtures/a/story.txt"
assert_file "$F/fixtures/b/story.txt"
assert_file "$F/personas/founder.md"
assert_file "$F/personas/pm.md"

# S14 no claude: says so, stops, writes nothing
rm -rf "$T/out-none"
CLAUDE_BIN=no-such-claude-binary bash "$F/run.sh" --fixture a --runs 1 --out "$T/out-none" > "$T/none.txt" 2>&1; rc=$?
[ "$rc" -ne 0 ] && pass || fail "run.sh succeeded without claude"
assert_contains "$T/none.txt" "claude"
[ -e "$T/out-none" ] && fail "run.sh wrote output without claude" || pass

# S15 the guard rails: not started by the test run or the nightly
assert_not_contains "$ROOT/tests/run.sh" "flows"
for w in "$ROOT"/.github/workflows/*.yml; do assert_not_contains "$w" "flows/"; done
assert_not_contains "$ROOT/install.sh" "flows"
assert_contains "$ROOT/.gitignore" "flows/results/"

finish
