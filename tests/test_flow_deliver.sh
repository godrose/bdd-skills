#!/bin/bash
# The flow harness for deliver (flows/). A fake claude plays the scripted messages and a fake npm stands in for the install.
# The real run, with a real model, is done by hand and is what measures time, usage and variance.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/tests/lib.sh"

F="$ROOT/flows"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
mkdir -p "$T/bin"; cp "$ROOT/tests/fixtures/fake-claude.sh" "$T/bin/claude"; chmod +x "$T/bin/claude"
cp "$ROOT/tests/fixtures/fake-npm.sh" "$T/bin/npm"; chmod +x "$T/bin/npm"
export PATH="$T/bin:$PATH" NPM_BIN="$T/bin/npm" FAKE_NPM_LOG="$T/npm.log" FLOWS_CACHE="$T/cache"
: > "$T/npm.log"

CHECKLIST='What exists: one scenario covers part of it.

E1. A late loan shows how many days late it is.
E2. The notice stays in view when the member scrolls.

Do you approve this checklist?'
SCEN='Here are the scenarios in plain words.

Do you approve these scenarios?'
PASS_OUT='2 scenarios (2 passed)
6 steps (6 passed)'
SOME_OUT='2 scenarios (1 pending, 1 passed)
6 steps (1 pending, 5 passed)'
REPORT_PARKED='Delivered: A late loan shows its days late.

E1 A late loan shows how many days late it is: passed
E2 The notice stays in view when the member scrolls: couldn'"'"'t be checked - needs a real browser

Regression: 1 earlier scenario still passes.
Seen: opened the loans page on the same data.

Not checked, and what it risks:
- E2 Members may scroll past the notice and miss it. For the developer: needs a real browser to check.'
REPORT_CLEAN='Delivered: A late loan shows its days late.

E1 A late loan shows how many days late it is: passed
E2 The notice stays in view when the member scrolls: passed

Regression: 1 earlier scenario still passes.
Seen: opened the loans page on the same data.'

# A scenario is described in plain steps, then played with `play`, then checked.
#
#   scenario "a feature file written after one approval is a break"
#   assistant_says "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"      # the messages, in order
#   product_manager_replies 2 "Hmm, not sure yet."           # replaces the reply to message 2 (the default is "Approved" to the first two)
#   assistant_writes features/late.feature in_message 3      # a file the assistant writes during that message
#   test_output_is "$SOME_OUT"                               # what `npm test` prints at the end
#   play
#   the_rule no-feature-before-go-ahead is broken
N=0
scenario() { N=$((N + 1)); SC="s$N"; SC_NAME="$1"; SC_MSGS=(); SC_PMN=(); SC_PMT=(); SC_FILE=""; SC_AT=""; SC_TEST="$T/pass.txt"; }
assistant_says() { SC_MSGS+=("$@"); }
product_manager_replies() { SC_PMN+=("$1"); SC_PMT+=("$2"); }
assistant_writes() { SC_FILE="$1"; SC_AT="$3"; }
test_output_is() { SC_TEST="$1"; }
play() {
  SC_DIR=$(dscript "$SC" "${SC_MSGS[@]}")
  local i=0
  while [ "$i" -lt "${#SC_PMN[@]}" ]; do echo "${SC_PMT[$i]}" > "$SC_DIR/pm-${SC_PMN[$i]}.txt"; i=$((i + 1)); done
  FAKE_WRITE_AT="$SC_AT" FAKE_WRITE_FILE="$SC_FILE" dharness "$SC_DIR" "$SC_TEST"
}
the_rule() { assert_equals "$3" "$(rule_of "$SC" "$1")" "$SC_NAME"; }   # the_rule <rule> is held|broken
the_rule_is_not_counted() { assert_equals "" "$(rule_of "$SC" "$1")" "$SC_NAME"; }
the_rules_say() { assert_contains "$(DRUN "$SC")/rules.tsv" "$1"; }
the_first_run_file_says() { assert_contains "$(DRUN "$RUN_OK")/$1" "$2"; }
the_run_file_says() { assert_contains "$(DRUN "$SC")/$1" "$2"; }
the_first_call_has() { assert_contains "$SC_DIR/assistant-args-1.txt" "$1"; }
the_first_call_lacks() { assert_not_contains "$SC_DIR/assistant-args-1.txt" "$1"; }
installs_so_far() { assert_equals "$1" "$(grep -c '^ci' "$T/npm.log")" "$2"; }

# dscript <name> <message>...: messages 1..n, with "Approved" as the reply to the first two
dscript() {
  local d="$T/$1"; shift; rm -rf "$d"; mkdir -p "$d"; local i=1
  for m in "$@"; do
    printf '%s\n' "$m" > "$d/assistant-$i.txt"
    if [ "$i" -le 2 ]; then echo Approved > "$d/pm-$i.txt"; else echo "A. reply $i" > "$d/pm-$i.txt"; fi
    i=$((i + 1))
  done
  echo "$d"
}
# dharness <script dir> <npm output file> [options]: one run of fixture c, story 1
dharness() {
  local d="$1" out="$2"; shift 2
  FAKE_DIR="$d" FAKE_NPM_OUT="$out" bash "$F/run.sh" --command deliver --fixture c --story 1 --runs 1 --out "$T/out-$(basename "$d")" "$@" > "$d/stdout.txt" 2> "$d/stderr.txt"
}
DRUN() { echo "$T/out-$1/c-story-1/run-1"; }
printf '%s\n' "$PASS_OUT" > "$T/pass.txt"; printf '%s\n' "$SOME_OUT" > "$T/some.txt"; printf '0 scenarios\n0 steps\n' > "$T/zero.txt"
rule_of() { awk -F'\t' -v r="$2" '$1==r {print $2}' "$(DRUN "$1")/rules.tsv"; }

# --- the fixture ---

# D1 a runner pinned by a lockfile, two stories, a persona that gives approvals
assert_file "$F/fixtures/c/project/package-lock.json"
assert_contains "$F/fixtures/c/project/package.json" '"@cucumber/cucumber": "11.3.0"'
assert_file "$F/fixtures/c/story-1.txt"
assert_file "$F/fixtures/c/story-2.txt"
assert_contains "$F/personas/approver.md" "Approved"
assert_contains "$F/fixtures/c/story-2.txt" "stays in view"
ns=$(cat "$F"/fixtures/c/project/features/*.feature | grep -c "^ *Scenario"); assert_equals 1 "$ns" "fixture c scenarios"

# D1b the fixture can show its page: a script prints the page built from the loans data
assert_file "$F/fixtures/c/project/src/show.js"
assert_file "$F/fixtures/c/project/data/loans.json"
assert_not_contains "$F/fixtures/c/project/.claude/bdd-config.md" "loans.html"
[ -e "$F/fixtures/c/project/src/pages/loans.html" ] && fail "a fixed page is left next to the script" || pass
if command -v node > /dev/null; then
  shown=$(cd "$F/fixtures/c/project" && node src/show.js 2>&1)
  printf "%s" "$shown" | grep -q "My loans" && pass || fail "the script does not print the loans page"
  printf "%s" "$shown" | grep -q "Dune" && pass || fail "the page does not show the loan"
  printf "%s" "$shown" | grep -q "overdue" && pass || fail "the page does not show the status"
fi

# D1c show.js takes a loans file under data/ and refuses any other path
if command -v node > /dev/null; then
  P="$F/fixtures/c/project"
  echo '[{"id":1,"book":"Emma","borrowedDaysAgo":3,"status":"open"}]' > "$P/data/_t.json"
  other=$(cd "$P" && node src/show.js data/_t.json 2>&1)
  rm -f "$P/data/_t.json"
  printf "%s" "$other" | grep -q "Emma" && pass || fail "show.js ignored the path it was given"
  printf "%s" "$other" | grep -q "overdue" && fail "a 3 day loan shows overdue" || pass
  (cd "$P" && node src/show.js ../../../package.json > "$T/outside.txt" 2>&1); rc=$?
  [ "$rc" -ne 0 ] && pass || fail "show.js read a file outside data/"
  assert_contains "$T/outside.txt" "data"
fi

# --- the run ---

scenario "the run starts /bdd:deliver with the story, and the model gets the test command and the page script, and no install command"
assistant_says "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"
play
the_first_call_has "/bdd:deliver When a loan is overdue"
the_first_call_has "Bash(npm test)"
the_first_call_has "Bash(node src/show.js)"
the_first_call_has "Bash(node src/show.js data/*)"
the_first_call_lacks "npm install"
the_first_call_lacks "npm ci"
assert_contains "$SC_DIR/assistant-args-2.txt" "Approved"
RUN_OK="$SC"

scenario "a report starting with Delivered ends the run, and the turn cap is larger than for discover"
the_first_run_file_says meta.json '"finished": true'
the_first_run_file_says meta.json '"turns": 3'
assert_contains "$F/run.sh" "TURNS=30"

scenario "the runner is installed by the harness, once, into a cache keyed on the lockfile"
installs_so_far 1 "one install for the first run"
key=$(shasum -a 256 "$F/fixtures/c/project/package-lock.json" | cut -c1-16)
assert_file "$T/cache/$key/node_modules/.bin/cucumber-js"
assert_file "$(DRUN "$RUN_OK")/project/node_modules/.bin/cucumber-js"
assistant_says "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"
play
installs_so_far 1 "no second install when the lockfile is the same"

scenario "a changed lockfile is a new cache"
mkdir -p "$T/lk"; cp -R "$F" "$T/lk/flows"; rm -rf "$T/lk/flows/results"; echo '{"x":1}' >> "$T/lk/flows/fixtures/c/project/package-lock.json"
d=$(dscript "$SC" "$CHECKLIST" "$SCEN" "$REPORT_CLEAN")
FAKE_DIR="$d" FAKE_NPM_OUT="$T/pass.txt" bash "$T/lk/flows/run.sh" --command deliver --fixture c --story 1 --runs 1 --out "$T/out-$SC" > /dev/null 2>&1
installs_so_far 2 "a changed lockfile installs again"

scenario "an install that fails stops the harness, says why and starts no session"
rm -rf "$T/cache"; : > "$T/npm.log"
d=$(dscript "$SC" "$CHECKLIST" "$SCEN" "$REPORT_CLEAN")
FAKE_NPM_FAIL=1 dharness "$d" "$T/pass.txt"; rc=$?
[ "$rc" -ne 0 ] && pass || fail "run.sh succeeded when the install failed"
assert_contains "$d/stderr.txt" "install"
[ -e "$d/assistant-args-1.txt" ] && fail "a session was started without a runner" || pass
[ -d "$T/cache" ] && [ -n "$(ls "$T/cache" 2> /dev/null)" ] && fail "a failed install left a cache behind" || pass

scenario "the real test output is saved in the run folder"
assistant_says "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"
play
the_run_file_says test-output.txt "2 scenarios (2 passed)"

# --- the approvals ---

scenario "written after two approvals"
assistant_says "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"
assistant_writes features/late.feature in_message 3
play
the_rule no-feature-before-go-ahead is held

scenario "written after one approval"
assistant_says "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"
assistant_writes features/early.feature in_message 2
play
the_rule no-feature-before-go-ahead is broken
the_rules_say "features/early.feature"

scenario "go ahead counts as the second approval"
assistant_says "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"
product_manager_replies 2 "Fix the wording. Then yes, go ahead."
assistant_writes features/late.feature in_message 3
play
the_rule no-feature-before-go-ahead is held

scenario "a reply that is not an approval"
assistant_says "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"
product_manager_replies 2 "Hmm, not sure yet."
assistant_writes features/late.feature in_message 3
play
the_rule no-feature-before-go-ahead is broken

scenario "two asks"
assistant_says "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"
play
the_rule approval-asked-once is held

scenario "three asks"
assistant_says "$CHECKLIST" "$SCEN" 'Please approve the checklist once more?' "$REPORT_CLEAN"
play
the_rule approval-asked-once is broken

# --- the report ---

scenario "parked report with the section"
assistant_says "$CHECKLIST" "$SCEN" "$REPORT_PARKED"
test_output_is "$T/some.txt"
play
the_rule report-shape is held

scenario "clean report without the section"
assistant_says "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"
play
the_rule report-shape is held

scenario "parked report without the section"
assistant_says "$CHECKLIST" "$SCEN" "${REPORT_PARKED%%Not checked*}"
test_output_is "$T/some.txt"
play
the_rule report-shape is broken

scenario "section with nothing parked"
assistant_says "$CHECKLIST" "$SCEN" "${REPORT_CLEAN}

Not checked, and what it risks:
- E1 Something. For the developer: x."
play
the_rule report-shape is broken

scenario "no line for E2"
assistant_says "$CHECKLIST" "$SCEN" 'Delivered: A late loan shows its days late.

E1 A late loan shows how many days late it is: passed'
play
the_rule report-shape is broken

# an example that was not checked is never reported as passed, judged on the saved test output

scenario "a pending scenario and every example passed"
assistant_says "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"
test_output_is "$T/some.txt"
play
the_rule never-reported-passed is broken

scenario "a pending scenario and one example parked"
assistant_says "$CHECKLIST" "$SCEN" "$REPORT_PARKED"
test_output_is "$T/some.txt"
play
the_rule never-reported-passed is held

scenario "all scenarios passed"
assistant_says "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"
play
the_rule never-reported-passed is held

scenario "zero tests ran and every example passed"
assistant_says "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"
test_output_is "$T/zero.txt"
play
the_rule never-reported-passed is broken

# an example listed in the Not checked section is never marked passed

BAD_PARKED='Delivered: A late loan shows its days late.

E1 A late loan shows how many days late it is: passed
E2 The notice stays in view when the member scrolls: couldn'"'"'t be checked - needs a real browser
E3 Two late loans show two notices: passed

Regression: 1 earlier scenario still passes.
Seen: the page for E1 only.

Not checked, and what it risks:
- E2 Members may miss the notice. For the developer: needs a real browser.
- E3 was seen only through the scenarios. For the developer: print the page.'
RANGE='Delivered: x.

E1 A: couldn'"'"'t be checked - x
E2 B: passed

Not checked, and what it risks:
- E1-E2 Members may see nothing. For the developer: look.'

scenario "E3 is listed as not checked and marked passed"
assistant_says "$CHECKLIST" "$SCEN" "$BAD_PARKED"
test_output_is "$T/some.txt"
play
the_rule parked-not-passed is broken
the_rules_say "E3"

scenario "the parked example is not passed"
assistant_says "$CHECKLIST" "$SCEN" "$REPORT_PARKED"
test_output_is "$T/some.txt"
play
the_rule parked-not-passed is held

scenario "no section, nothing to contradict"
assistant_says "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"
play
the_rule parked-not-passed is held

scenario "a range E1-E2 covers E2, which is passed"
assistant_says "$CHECKLIST" "$SCEN" "$RANGE"
test_output_is "$T/some.txt"
play
the_rule parked-not-passed is broken

# --- plain words: the whole report, but not the developer line or the developer note ---

scenario "parked report with a developer line"
assistant_says "$CHECKLIST" "$SCEN" "$REPORT_PARKED"
test_output_is "$T/some.txt"
play
the_rule plain-words is held

scenario "developer note names a file"
assistant_says "$CHECKLIST" "$SCEN" "${REPORT_CLEAN}

Developer note: the steps live in steps/loans.steps.js."
play
the_rule plain-words is held

scenario "a path in the plain report"
assistant_says "$CHECKLIST" "$SCEN" 'Delivered: the notice in `src/pages/loans.html`.

E1 A late loan shows how many days late it is: passed
E2 The notice stays in view when the member scrolls: passed'
play
the_rule plain-words is broken

scenario "no Readiness rule for deliver, and the shared rules are still counted"
assistant_says "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"
play
the_rule_is_not_counted pack-end
the_rule look-first is held

# --- what may be written: features, steps, product code, sample data, the out-of-scope list and decisions ---

scenario "a step file"
assistant_says "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"
assistant_writes steps/new.steps.js in_message 3
play
the_rule project-untouched is held

scenario "the package file"
assistant_says "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"
assistant_writes package.json in_message 3
play
the_rule project-untouched is broken

scenario "the sample data"
assistant_says "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"
assistant_writes data/loans.json in_message 3
play
the_rule project-untouched is held

scenario "the installed runner is not a change"
assistant_says "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"
play
the_rule project-untouched is held

# --- compare: two reports side by side, what moved marked, no verdict ---

mkdir -p "$T/cmp"
printf '| Rule | Runs that held it |\n|---|---|\n| one-question | 1 of 1 |\n| plain-words | 1 of 1 |\n' > "$T/cmp/a.md"
printf '| Rule | Runs that held it |\n|---|---|\n| one-question | 1 of 1 |\n| plain-words | 0 of 1 |\n' > "$T/cmp/b.md"
bash "$F/run.sh" --compare "$T/cmp/a.md" "$T/cmp/b.md" > "$T/cmp/out.txt" 2>&1
assert_contains "$T/cmp/out.txt" "plain-words"
assert_contains "$T/cmp/out.txt" "1 of 1"
assert_contains "$T/cmp/out.txt" "0 of 1"
grep -i 'plain-words' "$T/cmp/out.txt" | grep -q 'moved' && pass || fail "the rule that moved is not marked"
grep -i 'one-question' "$T/cmp/out.txt" | grep -q 'moved' && fail "a rule that did not move is marked" || pass
for w in "pass" "fail" "regress" "better" "worse"; do assert_not_contains "$T/cmp/out.txt" "$w"; done
bash "$F/run.sh" --compare "$T/cmp/a.md" "$T/cmp/none.md" > /dev/null 2>&1; rc=$?
[ "$rc" -ne 0 ] && pass || fail "compare succeeded with a missing report"

# --- the report names the command and the story, and the guard rails hold ---

assert_contains "$(DRUN "$RUN_OK")/../report.md" "deliver, fixture c, story 1"
assert_contains "$ROOT/.gitignore" "flows/results/"
assert_contains "$F/run.sh" "results/cache"
assert_not_contains "$ROOT/tests/run.sh" "flows"
for w in "$ROOT"/.github/workflows/*.yml; do assert_not_contains "$w" "flows/"; done
assert_contains "$F/run.sh" "TURNS=12"
assert_contains "$F/README.md" "--command deliver"

finish
