#!/bin/bash
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/tests/lib.sh"

for f in "$PLUGIN"/commands/*.md "$PLUGIN"/agents/*.md; do
  assert_equals "---" "$(head -1 "$f" | tr -d '\r')" "frontmatter in $f"
  grep -qE '^(description|name):' "$f" && pass || fail "$f lacks description or name"
done

CFG="$PLUGIN/bdd-config.template.md"
for key in workflow_mode glossary_file discovery_dir '| lint |' discoverer; do
  assert_contains "$CFG" "$key"
done
ROLE_NAMES=$(grep -o '`bdd:[a-z-]*`' "$CFG" | tr -d '`' | sed 's/^bdd://' | sort -u)
[ -n "$ROLE_NAMES" ] && pass || fail "no skill roles found in the config template"
for name in $ROLE_NAMES; do
  if [ -f "$PLUGIN/commands/$name.md" ] || [ -f "$PLUGIN/agents/$name.md" ]; then pass; else fail "role bdd:$name has no skill file"; fi
done

D="$PLUGIN/commands/discover.md"
assert_file "$D"
for h in Story 'Open questions' 'Candidate examples' 'Edge and negative cases' 'Vocabulary check' 'Candidate exclusions' Readiness; do
  assert_contains "$D" "## $h"
done
for s in 'Defaults when config rows are absent' 'stop and ask' 'requirements-sync' 'nothing to mine' 'size gate' 'one question at a time'; do
  assert_contains "$D" "$s"
done
assert_not_contains "$D" "$(printf '\xe2\x80\x94')"

G="$PLUGIN/commands/design.md"
for s in '--specify-only' 'specify-only' 'specify-and-implement' 'discovery pack' 'does not invoke the implementer' 'unautomated tag' 'If `workflow_mode` is absent'; do
  assert_contains "$G" "$s"
done
for h in 'Story to scenarios' 'Cases included' 'Cases deliberately excluded' 'New terms' 'Step status'; do
  assert_contains "$G" "$h"
done

I="$PLUGIN/commands/implement.md"
for s in 'approved spec' 'Step status' 'remove the unautomated tag'; do
  assert_contains "$I" "$s"
done

R="$ROOT/README.md"
for s in 'bdd-discover' 'specify-only' 'workflow_mode' '## The flow'; do
  assert_contains "$R" "$s"
done

# Final review fixes
for s in 'undefined steps' 'existing (not yet automated)' '.spec-summary.md' 'unautomated_tag'; do
  assert_contains "$G" "$s"
done
# Reversed: the generate row no longer gets a tag filter, because implement needs the scenario being implemented. The hint names the framework setting instead.
assert_not_contains "$G" 'excluding the unautomated tag'
for s in 'missingSteps' 'fail-on-run' 'Do not add a tag filter to the generate row' 'defers'; do
  assert_contains "$G" "$s"
done
for s in 'existing (not yet automated)' '.spec-summary.md' 'unautomated_tag' 'automated_tag' 'Do this only after the verifier'; do
  assert_contains "$I" "$s"
done
assert_not_contains "$I" 'When a scenario from an approved spec passes, remove the unautomated tag'
for s in unautomated_tag automated_tag; do
  assert_contains "$CFG" "$s"
done

# Deferred minors
assert_no_added_emdash .claude plugin .claude-plugin README.md install.sh tests docs
for s in 'size gate once you have read the story' 'ask the builder to paste the story' 'counts as empty'; do
  assert_contains "$D" "$s"
done
for s in 'Readiness says it is not ready' 'there are no results to push' 'stop at the approved spec'; do
  assert_contains "$G" "$s"
done
for s in '<summary><b>Optional config rows</b></summary>' '--specify-and-implement' 'prints a note for each newer row' 'bdd:discover (optional first step' 'stops after the scenarios'; do
  assert_contains "$R" "$s"
done
assert_file "$ROOT/docs/superpowers/dry-runs/2026-10-24-discover-and-specify-only.md"

RC_="$PLUGIN/commands/reconcile.md"
FB="$PLUGIN/commands/triage.md"
assert_file "$RC_"; assert_file "$FB"
for s in 'decisions.sh check' 'decisions.sh show' '--base' 'report, not a sync' 'never edits' 'contradict' 'audit' 'jq' 'legacy' 'decision_log'; do
  assert_contains "$RC_" "$s"
done
for s in 'approve' 'change' 'question' 'unclear' 'Unclear never counts as approval' 'confirms' 'supersedes' 'channel' 'writes nothing until' 'rewords' 'decisions.sh fingerprint' 'decision_log' 'Nothing is committed without being asked' 'objected' 'open'; do
  assert_contains "$FB" "$s"
done
for f in "$RC_" "$FB"; do assert_not_contains "$f" "$(printf '\xe2\x80\x94')"; done
for s in reconciler feedback-intake; do assert_contains "$CFG" "$s"; done

for k in decisions_dir scenario_id_prefix status_scope manual_only_tag blocked_tag planned_dir manual_only_dir decision_log; do
  assert_contains "$CFG" "$k"
done
assert_contains "$CFG" '| unautomated_tag | `@pending`'
assert_not_contains "$CFG" '| unautomated_tag | `@manual`'
for s in 'manual_only_tag' 'status_scope' 'decision_log' 'decisions.sh fingerprint' 'scenario_id_prefix' 'size gate' 'Decisions' 'decisions.sh check'; do
  assert_contains "$G" "$s"
done
for s in 'manual_only_tag' 'stays manual' 'fingerprint' 'rewords' 'default `@pending`'; do
  assert_contains "$I" "$s"
done
assert_not_contains "$I" 'default `@manual`'
assert_not_contains "$G" 'default `@manual`'

for s in 'decision log' 'bdd-triage' 'bdd-reconcile' 'jq' '@pending' 'story page'; do
  assert_contains "$R" "$s"
done
assert_not_contains "$R" 'tagged `@manual`'

for s in '"op":"adds"' '"scenario":"spec-' '"role":"agreed"' '"kind":"slack"' '"ref":' 'YYYY-MM-DD'; do
  assert_contains "$FB" "$s"
done

for s in '--planned-tag' '--manual-only-tag' '--blocked-tag' '--scope' '--planned-dir' '--manual-only-dir'; do
  assert_contains "$RC_" "$s"
done

for s in 'E-JSON' 'E-SCHEMA' 'E-VERSION' 'E-DUP-ID' 'E-REF' 'I-EMPTY' 'decisions.sh status' 'never fails on status'; do
  assert_contains "$RC_" "$s"
done
for s in 'manual_only_dir' 'default `scenario`'; do
  assert_contains "$G" "$s"
done

for f in "$PLUGIN/commands/run.md" "$PLUGIN/agents/verifier.md"; do
  for s in 'unautomated_tag' 'manual_only_tag' 'never an error'; do
    assert_contains "$f" "$s"
  done
done

for s in 'skip scenarios tagged' 'checked by hand or waiting on the product' 'reconciler' 'feedback-intake'; do
  assert_contains "$R" "$s"
done


# A missing config file stops the skills that need tooling or paths
for f in "$PLUGIN"/commands/{design,implement,run,triage,reconcile,deliver}.md "$PLUGIN/agents/verifier.md"; do
  assert_contains "$f" 'does not exist, say so and stop'
  assert_contains "$f" '`bdd-config.template.md`'
done
assert_not_contains "$PLUGIN/commands/discover.md" 'does not exist, say so and stop'


# Install docs: plugin first, project files second
for s in '### As a plugin' '/plugin marketplace add godrose/bdd-skills' '/plugin install bdd@gennadyverdel-plugins' \
  '<summary><b>As project files</b></summary>' 'use a hyphen' '`/bdd-design`' \
  '<summary><b>Moving from project files to the plugin</b></summary>' 'claude plugin update bdd@gennadyverdel-plugins' \
  '`/bdd:discover <story>`' '`/bdd:design`' '`/bdd:implement`'; do
  assert_contains "$R" "$s"
done
assert_not_contains "$R" '`/bdd-discover <story>` asks'


# /bdd:init copies the template and nothing more
for s in '`/bdd:init`' 'never overwrites' 'does not fill in' 'init.md' 'may ask you to approve'; do
  assert_contains "$R" "$s"
done
assert_not_contains "$R" 'mkdir -p .claude && curl'


# A generate row with no command is skipped, not run (godog and similar need no generation)
for f in "$PLUGIN/commands/run.md" "$PLUGIN/agents/verifier.md"; do
  assert_contains "$f" '_(not needed)_'
  assert_contains "$f" 'skip this step'
  assert_contains "$f" 'not a failure'
done
assert_contains "$PLUGIN/bdd-config.template.md" 'empty if the framework reads .feature files directly'


# /bdd:init --detect is documented
for s in '`/bdd:init --detect`' 'writes only the rows you approve' 'never changes a row that already has a value' 'never runs your commands' 'unknown'; do
  assert_contains "$R" "$s"
done
assert_contains "$ROOT/docs/superpowers/specs/2026-11-01-plugin-packaging-design.md" '/bdd:init --detect'

# Migration must not tell users to delete the bdd-* glob (it matches their own skills)
assert_not_contains "$R" '.claude/commands/bdd-*.md'
for s in 'bdd-discover' 'bdd-reconcile' '`.claude/agents/bdd-verifier.md`' 'bdd-<project>-knowledge' 'Keep your own' 'older installs'; do
  assert_contains "$R" "$s"
done

# The repo is private for now: the README says who can install and which route needs a public repo
for s in 'The repository is private for now' 'read access' 'gh auth setup-git' 'ssh-agent' 'only works once the repository is public'; do
  assert_contains "$R" "$s"
done


# prepare row: build what the tests launch, before generate and test
line_of() { grep -nF -m1 -- "$2" "$1" | cut -d: -f1; }
assert_before() {
  local a b
  a=$(line_of "$1" "$2"); b=$(line_of "$1" "$3")
  if [ -n "$a" ] && [ -n "$b" ] && [ "$a" -lt "$b" ]; then pass; else fail "$1: '$2' (line ${a:-none}) is not before '$3' (line ${b:-none})"; fi
}
for f in "$PLUGIN/commands/run.md" "$PLUGIN/agents/verifier.md" "$PLUGIN/commands/implement.md"; do
  assert_contains "$f" '**prepare**'
  assert_contains "$f" 'If the row is absent, empty'
  assert_contains "$f" 'If **prepare** fails, report the error and stop'
  assert_contains "$f" 'Do not run generate or test'
done
assert_contains "$PLUGIN/commands/run.md" '- **prepare** command'
assert_before "$PLUGIN/commands/run.md" 'run the **prepare** command' 'run the **generate** command'
assert_before "$PLUGIN/agents/verifier.md" 'Run the **prepare** command' 'Run the **generate** command'
assert_before "$PLUGIN/commands/implement.md" 'Run the **prepare** command' 'Ensure the **generate** command'
assert_contains "$PLUGIN/commands/implement.md" 'the **prepare** command, then the **generate** command, then the **test** command'
assert_contains "$PLUGIN/agents/verifier.md" 'Do not retry it'
assert_contains "$CFG" '| prepare |'
grep -qE '^\| prepare \| `` \(optional' "$CFG" && pass || fail "template prepare row must be empty with an (optional ...) note, not <...> form"


# run.md must not point at an install command that no row defines; prepare is where installing belongs
assert_not_contains "$PLUGIN/commands/run.md" 'Run the install command if missing'
assert_contains "$PLUGIN/commands/run.md" 'step 2 (**prepare**)'


# Then-step assertion check: a reused Then step must make the claim the scenario needs
G="$PLUGIN/commands/design.md"
I="$PLUGIN/commands/implement.md"
for s in "Pass C" "assertion check" "| Asserts |" "assertion unknown" "assertion not checkable yet" "The person chooses" "never changes fixture data" "Same words means same claim"; do
  assert_contains "$G" "$s"
done
assert_before "$G" "Pass B" "Pass C"
assert_contains "$I" "assertion does not fit"
assert_contains "$I" "Do not edit approved scenario data"

# Pass D: a scenario must assert what its title claims (docs/discovery/2026-11-10-design-title-check.md)
for s in "Pass D" "title check" "| Claims |" "claim unchecked" "names an exact value" "narrow the title" "only for the scenarios drafted in this run" "never changes a title" "Asserting less than the title claims"; do
  assert_contains "$G" "$s"
done
assert_before "$G" "Pass C" "Pass D"
assert_contains "$ROOT/docs/known-gaps.md" "### G10"
assert_contains "$ROOT/docs/known-gaps.md" "### G12"


# Zero tests ran is never a pass
RUN="$PLUGIN/commands/run.md"
V="$PLUGIN/agents/verifier.md"
I="$PLUGIN/commands/implement.md"
for f in "$RUN" "$V" "$I"; do
  assert_contains "$f" "no tests ran"
done
for f in "$RUN" "$V"; do
  assert_contains "$f" "nothing to run"
  assert_contains "$f" "Skipped tests do not count as executed"
done
assert_contains "$V" "executed count unknown"
assert_contains "$V" "- Executed:"
assert_contains "$V" "at least one test executed"
assert_contains "$I" "at least one executed test"
assert_before "$RUN" "Count what ran" "On success"


# Verifier selection by tag, name, file or all, and tag defaults in implement
V="$PLUGIN/agents/verifier.md"
I="$PLUGIN/commands/implement.md"
for s in "By: tag | name | file | all" "Select:" "**Selection:**" "unknown field Tag" "name matched"; do
  assert_contains "$V" "$s"
done
assert_not_contains "$V" "**Tag:**"
assert_contains "$I" "By: tag"
assert_contains "$I" "Select: <scenario-tag>"
assert_not_contains "$I" "Tag: <scenario-tag>"
for s in "Defaults when config rows are absent" "no tag changes" "Add the automated tag only when the unautomated tag was removed" "which tags changed"; do
  assert_contains "$I" "$s"
done


# implement is framework neutral: UI and language advice is gated by the config
I="$PLUGIN/commands/implement.md"
for s in "apply when the config sets" "visual-debug flag" "page objects or helpers" "explicit file extensions" "UI projects only" "the system under test" "no UI evidence"; do
  assert_contains "$I" "$s"
done
for s in "explore UI, discover selectors" "exploring the actual UI state" "plus \`--headed\`" "(without \`--headed\`)" "Which advice applies"; do
  assert_not_contains "$I" "$s"
done


# step_batch: group steps by risk so the implement loop needs fewer runs
I="$PLUGIN/commands/implement.md"
for s in "Plan the groups" "step_batch" "classify it high" "A high step closes the group" "split the rest of that group in half" "does not wait for approval" "existing, no work"; do
  assert_contains "$I" "$s"
done
assert_before "$I" "Plan the groups" "##### 2a. Run the test"
assert_contains "$CFG" "| step_batch |"
grep -qE '^\| step_batch \| `` \(optional' "$CFG" && pass || fail "template step_batch row must be empty with an (optional ...) note, not <...> form"
assert_contains "$ROOT/README.md" "| \`step_batch\` |"


# step_batch classification is by what needs a run to know, not by what code is new
for s in "you can write by reading the repo" "knowledge you cannot get by reading the repo" "the state of a rendered page"; do
  assert_contains "$I" "$s"
done
assert_not_contains "$I" "needs a new element, endpoint, client method or fixture"


# the group plan reaches the person in the final report, which the model reliably writes
assert_contains "$I" "add a **Groups** section"
assert_contains "$I" "the number of test runs"
assert_not_contains "$I" "write the plan as a message"
assert_not_contains "$I" "Print one line per step before the first run"


# Vague ACs: the designer lists its assumptions instead of choosing silently
G="$PLUGIN/commands/design.md"
for s in "List assumptions" "more than one distinct value" "Do not stop to ask" "values unknown, please confirm" "Assumptions: none" "Omit this section when there are none" "Silently picking one meaning"; do
  assert_contains "$G" "$s"
done
assert_not_contains "$G" "flag it for the user before designing scenarios"
assert_contains "$G" "do not list it"
assert_before "$G" "List assumptions" "Assumptions: none"
assert_before "$G" "Assumptions: none" "Omit this section when there are none"
assert_contains "$PLUGIN/commands/discover.md" "stop and ask"
assert_no_added_emdash commands/design.md tests/test_skills.sh

# bdd:feedback was renamed bdd:triage; no command may point at the old name
for f in "$PLUGIN"/commands/*.md "$PLUGIN"/agents/*.md; do
  assert_not_contains "$f" "bdd:feedback"
done

# design lints the draft before showing it (docs/discovery/2026-11-05-lint-in-design-and-layered-steps.md)
for s in 'before it is shown' '.bdd-draft-' 'deleted before' 'lint did not run' 'The scenarios are unchecked' \
  'findings in existing files, not touched' 'ask the user for the value' 'two rounds' 'leftover' 'its own name'; do
  assert_contains "$G" "$s"
done

# steps_dir takes several paths, comma-separated
for f in "$G" "$I" "$PLUGIN/commands/discover.md" "$PLUGIN/commands/init.md" "$CFG" "$ROOT/README.md"; do
  assert_contains "$f" 'comma-separated'
done
assert_contains "$PLUGIN/commands/init.md" 'each entry'

# generate: IDE-generated frameworks get unknown, never "not needed"
assert_contains "$PLUGIN/commands/init.md" 'generates code in the IDE'
assert_contains "$PLUGIN/commands/init.md" 'only for a framework that reads .feature files directly'

# no new rows for these changes
for row in required_tags adapters_dir domain_dir; do
  assert_not_contains "$CFG" "$row"
done
assert_no_added_emdash tests/test_skills.sh docs/discovery/2026-11-05-lint-in-design-and-layered-steps.md

# the audit's closing line is printed word for word and is the last line (the init-audit eval checks it)
assert_contains "$PLUGIN/commands/init.md" 'word for word'
assert_contains "$PLUGIN/commands/init.md" 'Nothing follows it'

# an ambiguous locator is scoped, not settled with .first()
assert_not_contains "$PLUGIN/commands/implement.md" 'Use `.first()` on locators that may match multiple elements'
assert_contains "$PLUGIN/commands/implement.md" 'Scope the locator to the element you mean'
assert_contains "$PLUGIN/commands/implement.md" 'Use `.first()` only when the first match is part of the behavior being tested'
assert_contains "$PLUGIN/commands/implement.md" 'hide the ambiguity'

# deliver: the hooks in the existing commands, and the config row it reads
assert_contains "$PLUGIN/commands/discover.md" 'out_of_scope_file'
assert_contains "$PLUGIN/commands/discover.md" 'git log --diff-filter=D'
assert_contains "$PLUGIN/commands/discover.md" 'Agreed examples'
assert_contains "$PLUGIN/commands/discover.md" 'E1'
assert_contains "$PLUGIN/commands/discover.md" 'No **out_of_scope_file**: use `docs/out-of-scope.md`'

# Step 0: discover looks first (docs/discovery/2026-11-10-discover-look-first.md)
for s in "Step 0: Look first" "before the first question" "For the developer:" "found nothing" "not looked at:" "Shown values and their source" "## What exists" "Where is this set" "without the user doing it in the same moment" "only about what it means for them"; do
  assert_contains "$D" "$s"
done
assert_before "$D" "Step 0: Look first" "#### Step 1: Understand the story"

for s in "Write the whole pack in plain words" "except Vocabulary check" "paths go on one \"For the developer\" line"; do
  assert_contains "$D" "$s"
done
for s in "try the words nearby" "Say which words you tried" "Keep field names, status names and log names out of these sentences" "are roles" "nobody can check it" "record the unknown as an assumption" "Put one question to the product manager in a message"; do
  assert_contains "$D" "$s"
done
assert_before "$D" "#### Step 1: Understand the story" "#### Step 3b"

# Outline against separate scenarios is offered by name (handoff suggestion 4, a copy edit under the size gate)
for s in "Outline + Examples against separate scenarios" "by those names" "let the person choose" "never merge cases into one scenario"; do
  assert_contains "$G" "$s"
done
assert_contains "$PLUGIN/commands/deliver.md" 'No **out_of_scope_file**: use `docs/out-of-scope.md`'
assert_contains "$PLUGIN/commands/design.md" 'counts as the approval of the examples'
assert_contains "$PLUGIN/commands/design.md" 'Decision (YYYY-MM-DD)'
assert_contains "$PLUGIN/commands/design.md" 'go-ahead'
assert_contains "$PLUGIN/commands/implement.md" 'Open decision:'
assert_contains "$PLUGIN/commands/implement.md" 'Found:'
assert_contains "$PLUGIN/commands/implement.md" 'Options:'
assert_not_contains "$PLUGIN/commands/run.md" 'deliver'
assert_not_contains "$PLUGIN/agents/verifier.md" 'deliver'
assert_contains "$CFG" '| out_of_scope_file | `docs/out-of-scope.md`'
assert_contains "$ROOT/README.md" 'out_of_scope_file'
finish
