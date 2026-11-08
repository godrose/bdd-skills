#!/bin/bash
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/tests/lib.sh"
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

bash "$ROOT/install.sh" "$T" > "$T/out.txt" 2>&1
for f in commands/bdd-design.md commands/bdd-implement.md commands/bdd-run.md agents/bdd-verifier.md bdd-config.md; do
  assert_file "$T/.claude/$f"
done

echo SENTINEL >> "$T/.claude/bdd-config.md"
bash "$ROOT/install.sh" "$T" > /dev/null 2>&1
assert_contains "$T/.claude/bdd-config.md" SENTINEL

assert_file "$T/.claude/commands/bdd-discover.md"
assert_equals "# Source: https://github.com/godrose/bdd-skills" "$(sed -n 2p "$T/.claude/commands/bdd-discover.md" | cut -d'(' -f1 | sed 's/ *$//')" "discover source header"

mkdir -p "$T/old/.claude"
printf 'SENTINEL\n' > "$T/old/.claude/bdd-config.md"
bash "$ROOT/install.sh" "$T/old" > "$T/old-out.txt" 2>&1
assert_equals SENTINEL "$(cat "$T/old/.claude/bdd-config.md")" "old config untouched"
assert_contains "$T/old-out.txt" "workflow_mode"

mkdir -p "$T/twice"
bash "$ROOT/install.sh" "$T/twice" > /dev/null 2>&1
cp "$T/twice/.claude/bdd-config.md" "$T/first-config.md"
bash "$ROOT/install.sh" "$T/twice" > /dev/null 2>&1
assert_equals 0 "$(cmp -s "$T/first-config.md" "$T/twice/.claude/bdd-config.md"; echo $?)" "config identical after second install"
assert_contains "$T/old-out.txt" "unautomated_tag"
assert_contains "$T/old-out.txt" "automated_tag"

mkdir -p "$T/prose/.claude"
printf 'we discuss workflow_mode here\n|lint|x|\n' > "$T/prose/.claude/bdd-config.md"
bash "$ROOT/install.sh" "$T/prose" > "$T/prose-out.txt" 2>&1
assert_contains "$T/prose-out.txt" "no 'workflow_mode' row"
assert_not_contains "$T/prose-out.txt" "no 'lint' row"

mkdir -p "$T/fresh"
bash "$ROOT/install.sh" "$T/fresh" > "$T/fresh-out.txt" 2>&1
assert_file "$T/fresh/.claude/commands/bdd-triage.md"
assert_file "$T/fresh/.claude/commands/bdd-reconcile.md"
assert_file "$T/fresh/.claude/schemas/decision.schema.json"
[ -x "$T/fresh/.claude/scripts/decisions.sh" ] && pass || fail "decisions.sh not executable"
assert_contains "$T/fresh-out.txt" "merge=union"
assert_contains "$T/fresh-out.txt" "jq"
OUT=$(cd "$T/fresh" && bash .claude/scripts/decisions.sh check 2>&1); RC=$?
assert_equals 0 "$RC" "installed decisions.sh check exits 0"
printf '%s' "$OUT" | grep -qF "I-EMPTY" && pass || fail "installed check prints I-EMPTY: $OUT"
for k in decision_log decisions_dir scenario_id_prefix status_scope manual_only_tag blocked_tag reconciler feedback-intake prepare step_batch '@pending'; do
  assert_contains "$T/old-out.txt" "$k"
done
assert_contains "$T/old-out.txt" "planned_dir"
assert_contains "$T/old-out.txt" "manual_only_dir"

# The project copy is the plugin text converted back to project names and paths
for f in "$T"/fresh/.claude/commands/*.md "$T"/fresh/.claude/agents/*.md "$T/fresh/.claude/bdd-config.md"; do
  assert_not_contains "$f" 'CLAUDE_PLUGIN_ROOT'
  if grep -qE 'bdd:(discover|design|implement|run|triage|reconcile|verifier)' "$f"; then fail "$f has a plugin-style skill name"; else pass; fi
done
assert_contains "$T/fresh/.claude/agents/bdd-verifier.md" "name: bdd-verifier"
assert_contains "$T/fresh/.claude/commands/bdd-reconcile.md" '.claude/scripts/decisions.sh check'
assert_contains "$T/fresh/.claude/bdd-config.md" '`bdd-design`'
for c in design triage reconcile; do
  assert_not_contains "$T/fresh/.claude/commands/bdd-$c.md" "Plugin note"
  assert_not_contains "$T/fresh/.claude/commands/bdd-$c.md" "plugin root"
done
for c in design implement run triage reconcile; do
  assert_contains "$T/fresh/.claude/commands/bdd-$c.md" 'does not exist, say so and stop'
  assert_not_contains "$T/fresh/.claude/commands/bdd-$c.md" 'template is at'
done
[ -e "$T/fresh/.claude/commands/bdd-init.md" ] && fail "project install has an init command" || pass
[ -e "$T/fresh/.claude/commands/init.md" ] && fail "project install has an init command" || pass

# The installer says what went wrong when it cannot get the plugin files (a stub git keeps this offline).
B="$T/nogit"; mkdir -p "$B/bin" "$B/proj"
cp "$ROOT/install.sh" "$B/install.sh"
printf '#!/bin/sh\necho "Cloning into stub"\nexit 1\n' > "$B/bin/git"; chmod +x "$B/bin/git"
out=$(cd "$B" && PATH="$B/bin:$PATH" bash install.sh proj 2>&1); st=$?
[ "$st" -ne 0 ] && pass || fail "a failed clone exits 0"
echo "$out" | grep -qF "could not clone" && pass || fail "a failed clone does not say so: $out"
echo "$out" | grep -qF "no plugin/ folder" && fail "a failed clone is reported as a missing plugin folder" || pass
[ -e "$B/proj/.claude" ] && fail "a failed clone left files in the project" || pass

printf '#!/bin/sh\necho "Cloning into stub"\nexit 0\n' > "$B/bin/git"
out=$(cd "$B" && PATH="$B/bin:$PATH" bash install.sh proj 2>&1); st=$?
[ "$st" -ne 0 ] && pass || fail "a source without plugin/ exits 0"
echo "$out" | grep -qF "no plugin/ folder" && pass || fail "a source without plugin/ does not say so: $out"
[ -e "$B/proj/.claude" ] && fail "a source without plugin/ left files in the project" || pass

finish
