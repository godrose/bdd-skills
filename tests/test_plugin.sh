#!/bin/bash
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/tests/lib.sh"

PJ="$ROOT/.claude-plugin/plugin.json"
MK="$ROOT/.claude-plugin/marketplace.json"
assert_file "$PJ"
assert_file "$MK"

assert_equals bdd "$(jq -r .name "$PJ" 2>/dev/null)" "plugin name"
V=$(jq -r .version "$PJ" 2>/dev/null)
printf '%s' "$V" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$' && pass || fail "plugin version is not semver: $V"
assert_equals "$V" "$(jq -r '.plugins[0].version' "$MK" 2>/dev/null)" "marketplace version matches plugin version"
assert_equals bdd "$(jq -r '.plugins[0].name' "$MK" 2>/dev/null)" "marketplace plugin name"
assert_equals "./" "$(jq -r '.plugins[0].source' "$MK" 2>/dev/null)" "marketplace plugin source"
assert_equals godrose-plugins "$(jq -r .name "$MK" 2>/dev/null)" "marketplace name"

for c in discover design implement run triage reconcile init; do
  assert_file "$ROOT/commands/$c.md"
done
assert_file "$ROOT/agents/verifier.md"
assert_contains "$ROOT/agents/verifier.md" "name: verifier"
assert_file "$ROOT/schemas/decision.schema.json"
assert_file "$ROOT/bdd-config.template.md"
[ -x "$ROOT/scripts/decisions.sh" ] && pass || fail "scripts/decisions.sh is not executable"

n=$(ls "$ROOT"/commands "$ROOT"/agents 2>/dev/null | grep -c '^bdd-')
assert_equals 0 "$n" "files with a bdd- prefix in commands and agents"
[ -d "$ROOT/.claude/commands" ] && fail ".claude/commands still holds source" || pass
[ -d "$ROOT/.claude/agents" ] && fail ".claude/agents still holds source" || pass

PLUGIN_TEXT=("$ROOT"/commands/*.md "$ROOT"/agents/*.md "$ROOT/bdd-config.template.md")
for f in "${PLUGIN_TEXT[@]}"; do
  if grep -qE '\.claude/(scripts|schemas)/' "$f"; then fail "$f has a project-install path"; else pass; fi
  if grep -qE 'bdd-(discover|design|implement|run|triage|reconcile|verifier)' "$f"; then fail "$f has a project-install skill name"; else pass; fi
done
for c in design triage reconcile; do
  assert_contains "$ROOT/commands/$c.md" '"${CLAUDE_PLUGIN_ROOT}"/scripts/decisions.sh'
done

for c in design triage reconcile; do
  assert_contains "$ROOT/commands/$c.md" "> Plugin note:"
  assert_contains "$ROOT/commands/$c.md" "say the plugin root was not set"
done

for c in design implement run triage reconcile; do
  assert_contains "$ROOT/commands/$c.md" "> Plugin note: if \`.claude/bdd-config.md\` is missing, tell the user to run \`/bdd:init\`"
done

INIT="$ROOT/commands/init.md"
assert_contains "$INIT" '"${CLAUDE_PLUGIN_ROOT}"/bdd-config.template.md'
assert_contains "$INIT" "never overwrite"
assert_contains "$INIT" "does not fill in"

assert_contains "$ROOT/.gitattributes" "*.sh text eol=lf"



# /bdd:init --detect: read-only proposals, approval before any write
assert_contains "$INIT" '--detect'
assert_contains "$INIT" '"AskUserQuestion"'
assert_contains "$INIT" '"Edit"'
for s in 'never change a row that already has a value' 'still in `<...>` form' 'Do not run the project'"'"'s commands' \
  'writes nothing until' 'evidence' 'confidence' 'unknown' 'full path' 'never an abbreviation' \
  'ask which' 'CI workflow' 'another platform' '_(not needed' 'Do not guess'; do
  assert_contains "$INIT" "$s"
done


# /bdd:init reports leftover project-file copies, report only
for s in '### Leftovers' '# Source: https://github.com/godrose/bdd' 'bdd-<name>.md' 'your own' 'Do not delete' 'duplicate commands' 'bdd:'; do
  assert_contains "$INIT" "$s"
done
assert_contains "$ROOT/install.sh" '# Source: $REPO_URL'
assert_contains "$ROOT/README.md" 'lists leftover'


# /bdd:init --detect: search the feature files for tag rows, say what was searched, check paths, label defaults low
for s in 'count how often each tag is used' 'in the `.feature` files' 'Do not report a tag row as unknown without searching' \
  'name the files you searched' 'does not exist' \
  'not found in a project file is your own suggestion' 'literal glob' 'never a value in `<...>` form'; do
  assert_contains "$INIT" "$s"
done


# Leftovers: only files that exist on disk count
for s in 'only if it exists on disk' 'git shows as deleted is not a leftover'; do
  assert_contains "$INIT" "$s"
done


# feedback was renamed to triage (verb form, like the other commands)
assert_file "$ROOT/commands/triage.md"
[ -e "$ROOT/commands/feedback.md" ] && fail "commands/feedback.md still exists" || pass
assert_contains "$ROOT/bdd-config.template.md" '| feedback-intake | `bdd:triage`'
assert_contains "$INIT" 'run, triage or reconcile'

assert_version_bumped

finish
