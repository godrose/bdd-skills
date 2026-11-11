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
printf '%s\n' "$PASS_OUT" > "$T/pass.txt"; printf '%s\n' "$SOME_OUT" > "$T/some.txt"
rule_of() { awk -F'\t' -v r="$2" '$1==r {print $2}' "$(DRUN "$1")/rules.tsv"; }

# D1 the fixture: a runner pinned by a lockfile, two stories, a persona that gives approvals
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

# D2 the run starts /bdd:deliver with the story, and the model gets the test command and no install command
d=$(dscript d2 "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"); dharness "$d" "$T/pass.txt"
assert_contains "$d/assistant-args-1.txt" "/bdd:deliver When a loan is overdue"
assert_contains "$d/assistant-args-1.txt" "Bash(npm test)"
assert_contains "$d/assistant-args-1.txt" "Bash(node src/show.js)"
assert_not_contains "$d/assistant-args-1.txt" "npm install"
assert_not_contains "$d/assistant-args-1.txt" "npm ci"
assert_contains "$d/assistant-args-2.txt" "Approved"

# D3 a report starting with Delivered ends the run, and the cap is larger than for discover
assert_contains "$(DRUN d2)/meta.json" '"finished": true'
assert_contains "$(DRUN d2)/meta.json" '"turns": 3'
assert_contains "$F/run.sh" "TURNS=30"

# D4 the runner is installed by the harness, once, into a cache keyed on the lockfile
n=$(grep -c '^ci' "$T/npm.log"); assert_equals 1 "$n" "one install for the first run"
key=$(shasum -a 256 "$F/fixtures/c/project/package-lock.json" | cut -c1-16)
assert_file "$T/cache/$key/node_modules/.bin/cucumber-js"
assert_file "$(DRUN d2)/project/node_modules/.bin/cucumber-js"
d=$(dscript d4 "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"); dharness "$d" "$T/pass.txt"
n=$(grep -c '^ci' "$T/npm.log"); assert_equals 1 "$n" "no second install when the lockfile is the same"

# D5 a changed lockfile is a new cache
mkdir -p "$T/lk"; cp -R "$F" "$T/lk/flows"; rm -rf "$T/lk/flows/results"; echo '{"x":1}' >> "$T/lk/flows/fixtures/c/project/package-lock.json"
d=$(dscript d5 "$CHECKLIST" "$SCEN" "$REPORT_CLEAN")
FAKE_DIR="$d" FAKE_NPM_OUT="$T/pass.txt" bash "$T/lk/flows/run.sh" --command deliver --fixture c --story 1 --runs 1 --out "$T/out-d5" > /dev/null 2>&1
n=$(grep -c '^ci' "$T/npm.log"); assert_equals 2 "$n" "a changed lockfile installs again"

# D6 an install that fails stops the harness, says why and starts no session
rm -rf "$T/cache"; : > "$T/npm.log"
d=$(dscript d6 "$CHECKLIST" "$SCEN" "$REPORT_CLEAN")
FAKE_NPM_FAIL=1 dharness "$d" "$T/pass.txt"; rc=$?
[ "$rc" -ne 0 ] && pass || fail "run.sh succeeded when the install failed"
assert_contains "$d/stderr.txt" "install"
[ -e "$d/assistant-args-1.txt" ] && fail "a session was started without a runner" || pass
[ -d "$T/cache" ] && [ -n "$(ls "$T/cache" 2> /dev/null)" ] && fail "a failed install left a cache behind" || pass

# D7 the real test output is saved in the run folder
d=$(dscript d7 "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"); dharness "$d" "$T/pass.txt"
assert_contains "$(DRUN d7)/test-output.txt" "2 scenarios (2 passed)"

# D8 a feature file written before the second approval is a break
d=$(dscript d8a "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"); FAKE_WRITE_AT=3 FAKE_WRITE_FILE=features/late.feature dharness "$d" "$T/pass.txt"
assert_equals held "$(rule_of d8a no-feature-before-go-ahead)" "written after two approvals"
d=$(dscript d8b "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"); FAKE_WRITE_AT=2 FAKE_WRITE_FILE=features/early.feature dharness "$d" "$T/pass.txt"
assert_equals broken "$(rule_of d8b no-feature-before-go-ahead)" "written after one approval"
assert_contains "$(DRUN d8b)/rules.tsv" "features/early.feature"

# D9 an approval asked a third time is a break
d=$(dscript d9a "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"); dharness "$d" "$T/pass.txt"
assert_equals held "$(rule_of d9a approval-asked-once)" "two asks"
d=$(dscript d9b "$CHECKLIST" "$SCEN" 'Please approve the checklist once more?' "$REPORT_CLEAN"); dharness "$d" "$T/pass.txt"
assert_equals broken "$(rule_of d9b approval-asked-once)" "three asks"

# D10 the report has one line per agreed example, and the Not checked section exactly when something was parked
d=$(dscript d10a "$CHECKLIST" "$SCEN" "$REPORT_PARKED"); dharness "$d" "$T/some.txt"
assert_equals held "$(rule_of d10a report-shape)" "parked report with the section"
d=$(dscript d10b "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"); dharness "$d" "$T/pass.txt"
assert_equals held "$(rule_of d10b report-shape)" "clean report without the section"
d=$(dscript d10c "$CHECKLIST" "$SCEN" "${REPORT_PARKED%%Not checked*}"); dharness "$d" "$T/some.txt"
assert_equals broken "$(rule_of d10c report-shape)" "parked report without the section"
d=$(dscript d10d "$CHECKLIST" "$SCEN" "${REPORT_CLEAN}

Not checked, and what it risks:
- E1 Something. For the developer: x."); dharness "$d" "$T/pass.txt"
assert_equals broken "$(rule_of d10d report-shape)" "section with nothing parked"
d=$(dscript d10e "$CHECKLIST" "$SCEN" 'Delivered: A late loan shows its days late.

E1 A late loan shows how many days late it is: passed'); dharness "$d" "$T/pass.txt"
assert_equals broken "$(rule_of d10e report-shape)" "no line for E2"

# D11 an example that was not checked is never reported as passed, judged on the saved test output
d=$(dscript d11a "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"); dharness "$d" "$T/some.txt"
assert_equals broken "$(rule_of d11a never-reported-passed)" "a pending scenario and every example passed"
d=$(dscript d11b "$CHECKLIST" "$SCEN" "$REPORT_PARKED"); dharness "$d" "$T/some.txt"
assert_equals held "$(rule_of d11b never-reported-passed)" "a pending scenario and one example parked"
d=$(dscript d11c "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"); dharness "$d" "$T/pass.txt"
assert_equals held "$(rule_of d11c never-reported-passed)" "all scenarios passed"
printf '0 scenarios\n0 steps\n' > "$T/zero.txt"
d=$(dscript d11d "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"); dharness "$d" "$T/zero.txt"
assert_equals broken "$(rule_of d11d never-reported-passed)" "zero tests ran and every example passed"

# D12 plain words judge the whole report, but the developer line and the developer note are left out
d=$(dscript d12a "$CHECKLIST" "$SCEN" "$REPORT_PARKED"); dharness "$d" "$T/some.txt"
assert_equals held "$(rule_of d12a plain-words)" "parked report with a developer line"
d=$(dscript d12b "$CHECKLIST" "$SCEN" "${REPORT_CLEAN}

Developer note: the steps live in steps/loans.steps.js."); dharness "$d" "$T/pass.txt"
assert_equals held "$(rule_of d12b plain-words)" "developer note names a file"
d=$(dscript d12c "$CHECKLIST" "$SCEN" 'Delivered: the notice in `src/pages/loans.html`.

E1 A late loan shows how many days late it is: passed
E2 The notice stays in view when the member scrolls: passed'); dharness "$d" "$T/pass.txt"
assert_equals broken "$(rule_of d12c plain-words)" "a path in the plain report"

# D12b the Readiness rule belongs to discover: a deliver run does not count it
d=$(dscript d12d "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"); dharness "$d" "$T/pass.txt"
assert_equals "" "$(rule_of d12d pack-end)" "no Readiness rule for deliver"
assert_equals held "$(rule_of d12d look-first)" "the shared rules are still counted"

# D13 only what the change needs may be written: features, steps, product code, the out-of-scope list and decisions
d=$(dscript d13a "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"); FAKE_WRITE_AT=3 FAKE_WRITE_FILE=steps/new.steps.js dharness "$d" "$T/pass.txt"
assert_equals held "$(rule_of d13a project-untouched)" "a step file"
d=$(dscript d13b "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"); FAKE_WRITE_AT=3 FAKE_WRITE_FILE=package.json dharness "$d" "$T/pass.txt"
assert_equals broken "$(rule_of d13b project-untouched)" "the package file"
d=$(dscript d13d "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"); FAKE_WRITE_AT=3 FAKE_WRITE_FILE=data/loans.json dharness "$d" "$T/pass.txt"
assert_equals held "$(rule_of d13d project-untouched)" "the sample data"
d=$(dscript d13c "$CHECKLIST" "$SCEN" "$REPORT_CLEAN"); dharness "$d" "$T/pass.txt"
assert_equals held "$(rule_of d13c project-untouched)" "the installed runner is not a change"

# D14 compare: two reports side by side, what moved marked, no verdict
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

# D15 the report names the command and the story
assert_contains "$(DRUN d2)/../report.md" "deliver, fixture c, story 1"

# D16 the guard rails: the cache sits in the ignored results folder, and the harness is still not started by tests or the nightly
assert_contains "$ROOT/.gitignore" "flows/results/"
assert_contains "$F/run.sh" "results/cache"
assert_not_contains "$ROOT/tests/run.sh" "flows"
for w in "$ROOT"/.github/workflows/*.yml; do assert_not_contains "$w" "flows/"; done

# D17 the discover harness is unchanged by the new options
assert_contains "$F/run.sh" "TURNS=12"
assert_contains "$F/README.md" "--command deliver"

finish
