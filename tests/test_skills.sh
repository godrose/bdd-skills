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
finish
