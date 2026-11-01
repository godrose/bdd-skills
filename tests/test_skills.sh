#!/bin/bash
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/tests/lib.sh"

for f in "$ROOT"/.claude/commands/*.md "$ROOT"/.claude/agents/*.md; do
  assert_equals "---" "$(head -1 "$f" | tr -d '\r')" "frontmatter in $f"
  grep -qE '^(description|name):' "$f" && pass || fail "$f lacks description or name"
done

CFG="$ROOT/.claude/bdd-config.template.md"
for key in workflow_mode glossary_file discovery_dir '| lint |' discoverer; do
  assert_contains "$CFG" "$key"
done

for name in $(grep -o '`bdd-[a-z-]*`' "$CFG" | tr -d '`' | sort -u); do
  if [ -f "$ROOT/.claude/commands/$name.md" ] || [ -f "$ROOT/.claude/agents/$name.md" ]; then pass; else fail "role $name has no skill file"; fi
done

D="$ROOT/.claude/commands/bdd-discover.md"
assert_file "$D"
for h in Story 'Open questions' 'Candidate examples' 'Edge and negative cases' 'Vocabulary check' 'Candidate exclusions' Readiness; do
  assert_contains "$D" "## $h"
done
for s in 'Defaults when config rows are absent' 'stop and ask' 'requirements-sync' 'nothing to mine' 'size gate' 'one question at a time'; do
  assert_contains "$D" "$s"
done
assert_not_contains "$D" "$(printf '\xe2\x80\x94')"

G="$ROOT/.claude/commands/bdd-design.md"
for s in '--specify-only' 'specify-only' 'specify-and-implement' 'discovery pack' 'does not invoke the implementer' 'unautomated tag' 'If `workflow_mode` is absent'; do
  assert_contains "$G" "$s"
done
for h in 'Story to scenarios' 'Cases included' 'Cases deliberately excluded' 'New terms' 'Step status'; do
  assert_contains "$G" "$h"
done

I="$ROOT/.claude/commands/bdd-implement.md"
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
assert_no_added_emdash .claude README.md install.sh tests
for s in 'size gate once you have read the story' 'ask the builder to paste the story' 'counts as empty'; do
  assert_contains "$D" "$s"
done
for s in 'Readiness says it is not ready' 'there are no results to push' 'stop at the approved spec'; do
  assert_contains "$G" "$s"
done
for s in '## Optional config rows' '--specify-and-implement' 'prints a note for each newer row' 'bdd-discover (optional first step' 'stops after the scenarios'; do
  assert_contains "$R" "$s"
done
assert_file "$ROOT/docs/superpowers/dry-runs/2026-10-24-discover-and-specify-only.md"

RC_="$ROOT/.claude/commands/bdd-reconcile.md"
FB="$ROOT/.claude/commands/bdd-feedback.md"
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

for s in 'decision log' 'bdd-feedback' 'bdd-reconcile' 'jq' '@pending' 'story page'; do
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

for f in "$ROOT/.claude/commands/bdd-run.md" "$ROOT/.claude/agents/bdd-verifier.md"; do
  for s in 'unautomated_tag' 'manual_only_tag' 'never an error'; do
    assert_contains "$f" "$s"
  done
done

for s in 'skip scenarios tagged' 'checked by hand or waiting on the product' 'reconciler' 'feedback-intake'; do
  assert_contains "$R" "$s"
done

finish
