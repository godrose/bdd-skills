#!/bin/bash
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/tests/lib.sh"

for f in "$ROOT"/commands/*.md "$ROOT"/agents/*.md; do
  assert_equals "---" "$(head -1 "$f" | tr -d '\r')" "frontmatter in $f"
  grep -qE '^(description|name):' "$f" && pass || fail "$f lacks description or name"
done

CFG="$ROOT/bdd-config.template.md"
for key in workflow_mode glossary_file discovery_dir '| lint |' discoverer; do
  assert_contains "$CFG" "$key"
done
ROLE_NAMES=$(grep -o '`bdd:[a-z-]*`' "$CFG" | tr -d '`' | sed 's/^bdd://' | sort -u)
[ -n "$ROLE_NAMES" ] && pass || fail "no skill roles found in the config template"
for name in $ROLE_NAMES; do
  if [ -f "$ROOT/commands/$name.md" ] || [ -f "$ROOT/agents/$name.md" ]; then pass; else fail "role bdd:$name has no skill file"; fi
done

D="$ROOT/commands/discover.md"
assert_file "$D"
for h in Story 'Open questions' 'Candidate examples' 'Edge and negative cases' 'Vocabulary check' 'Candidate exclusions' Readiness; do
  assert_contains "$D" "## $h"
done
for s in 'Defaults when config rows are absent' 'stop and ask' 'requirements-sync' 'nothing to mine' 'size gate' 'one question at a time'; do
  assert_contains "$D" "$s"
done
assert_not_contains "$D" "$(printf '\xe2\x80\x94')"

G="$ROOT/commands/design.md"
for s in '--specify-only' 'specify-only' 'specify-and-implement' 'discovery pack' 'does not invoke the implementer' 'unautomated tag' 'If `workflow_mode` is absent'; do
  assert_contains "$G" "$s"
done
for h in 'Story to scenarios' 'Cases included' 'Cases deliberately excluded' 'New terms' 'Step status'; do
  assert_contains "$G" "$h"
done

I="$ROOT/commands/implement.md"
for s in 'approved spec' 'Step status' 'remove the unautomated tag'; do
  assert_contains "$I" "$s"
done

R="$ROOT/README.md"
for s in 'bdd-discover' 'specify-only' 'workflow_mode' '## The flow'; do
  assert_contains "$R" "$s"
done

# Final review fixes
for s in 'undefined steps' 'excluding the unautomated tag' 'existing (not yet automated)' '.spec-summary.md' 'unautomated_tag'; do
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
assert_no_added_emdash .claude commands agents scripts schemas .claude-plugin bdd-config.template.md README.md install.sh tests docs
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

RC_="$ROOT/commands/reconcile.md"
FB="$ROOT/commands/triage.md"
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

for f in "$ROOT/commands/run.md" "$ROOT/agents/verifier.md"; do
  for s in 'unautomated_tag' 'manual_only_tag' 'never an error'; do
    assert_contains "$f" "$s"
  done
done

for s in 'skip scenarios tagged' 'checked by hand or waiting on the product' 'reconciler' 'feedback-intake'; do
  assert_contains "$R" "$s"
done


# A missing config file stops the skills that need tooling or paths
for f in "$ROOT"/commands/{design,implement,run,triage,reconcile}.md "$ROOT/agents/verifier.md"; do
  assert_contains "$f" 'does not exist, say so and stop'
  assert_contains "$f" '`bdd-config.template.md`'
done
assert_not_contains "$ROOT/commands/discover.md" 'does not exist, say so and stop'


# Install docs: plugin first, project files second
for s in '### As a plugin' '/plugin marketplace add godrose/bdd' '/plugin install bdd@godrose-plugins' \
  '<summary><b>As project files</b></summary>' 'use a hyphen' '`/bdd-design`' \
  '<summary><b>Moving from project files to the plugin</b></summary>' 'claude plugin update bdd@godrose-plugins' \
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
for f in "$ROOT/commands/run.md" "$ROOT/agents/verifier.md"; do
  assert_contains "$f" '_(not needed)_'
  assert_contains "$f" 'skip this step'
  assert_contains "$f" 'not a failure'
done
assert_contains "$ROOT/bdd-config.template.md" 'empty if the framework reads .feature files directly'


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
for f in "$ROOT/commands/run.md" "$ROOT/agents/verifier.md" "$ROOT/commands/implement.md"; do
  assert_contains "$f" '**prepare**'
  assert_contains "$f" 'If the row is absent, empty'
  assert_contains "$f" 'If **prepare** fails, report the error and stop'
  assert_contains "$f" 'Do not run generate or test'
done
assert_contains "$ROOT/commands/run.md" '- **prepare** command'
assert_before "$ROOT/commands/run.md" 'run the **prepare** command' 'run the **generate** command'
assert_before "$ROOT/agents/verifier.md" 'Run the **prepare** command' 'Run the **generate** command'
assert_before "$ROOT/commands/implement.md" 'Run the **prepare** command' 'Ensure the **generate** command'
assert_contains "$ROOT/commands/implement.md" 'the **prepare** command, then the **generate** command, then the **test** command'
assert_contains "$ROOT/agents/verifier.md" 'Do not retry it'
assert_contains "$CFG" '| prepare |'
grep -qE '^\| prepare \| `` \(optional' "$CFG" && pass || fail "template prepare row must be empty with an (optional ...) note, not <...> form"


# run.md must not point at an install command that no row defines; prepare is where installing belongs
assert_not_contains "$ROOT/commands/run.md" 'Run the install command if missing'
assert_contains "$ROOT/commands/run.md" 'step 2 (**prepare**)'


# Then-step assertion check: a reused Then step must make the claim the scenario needs
G="$ROOT/commands/design.md"
I="$ROOT/commands/implement.md"
for s in "Pass C" "assertion check" "| Asserts |" "assertion unknown" "assertion not checkable yet" "The person chooses" "never changes fixture data" "Same words means same claim"; do
  assert_contains "$G" "$s"
done
assert_before "$G" "Pass B" "Pass C"
assert_contains "$I" "assertion does not fit"
assert_contains "$I" "Do not edit approved scenario data"

finish
