#!/bin/bash
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/tests/lib.sh"

PJ="$ROOT/.claude-plugin/plugin.json"
MK="$ROOT/.claude-plugin/marketplace.json"
assert_file "$PJ"
assert_file "$MK"

assert_equals bdd "$(jq -r .name "$PJ" 2>/dev/null)" "plugin name"
# The version is pinned and set in both manifests. Only release PRs change it (see Releasing in CLAUDE.md).
VER=$(jq -r .version "$PJ" 2>/dev/null)
echo "$VER" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' && pass || fail "plugin.json version is not semver: $VER"
assert_equals "$VER" "$(jq -r '.plugins[0].version' "$MK" 2>/dev/null)" "marketplace version matches plugin.json"
[ -n "$(jq -r '.description // empty' "$MK" 2>/dev/null)" ] && pass || fail "marketplace.json needs a description"
assert_contains "$ROOT/CHANGELOG.md" "## $VER"
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
  if sed -e 's/bdd-implement-scenario//g' -e 's/bdd-scenario-design//g' "$f" | grep -qE 'bdd-(discover|design|implement|run|triage|reconcile|verifier)'; then fail "$f has a project-install skill name"; else pass; fi
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
for s in '### Leftovers' '# Source: https://github.com/godrose/bdd-skills' 'bdd-<name>.md' 'your own' 'Do not delete' 'duplicate commands' 'bdd:'; do
  assert_contains "$INIT" "$s"
done
assert_contains "$ROOT/install.sh" '# Source: $REPO_URL'
assert_contains "$ROOT/README.md" 'lists leftover'
assert_contains "$ROOT/README.md" 'proposes your own skills'


# /bdd:init --detect: search the feature files for tag rows, say what was searched, check paths, label defaults low
for s in 'count how often each tag is used' 'in the `.feature` files' 'Do not report a tag row as unknown without searching' \
  'name the files you searched' 'does not exist' \
  'not found in a project file is your own suggestion' 'literal glob' 'never a value in `<...>` form'; do
  assert_contains "$INIT" "$s"
done


# Step 1 counts the two role rows too, so a config with only those placeholders still gets proposals
assert_contains "$INIT" 'or the two placeholder roles in the Skill Roles table'

# Leftovers: only files that exist on disk count
for s in 'only if it exists on disk' 'git shows as deleted is not a leftover'; do
  assert_contains "$INIT" "$s"
done


# /bdd:init --detect: propose the domain-knowledge and requirements-sync roles from the project's own skills
for s in '### Skill roles' 'domain-knowledge' 'requirements-sync' '.claude/skills/' 'one-line description' \
  'runners-up' 'no local skill found' 'never a candidate' '# Source:'; do
  assert_contains "$INIT" "$s"
done

# feedback was renamed to triage (verb form, like the other commands)
assert_file "$ROOT/commands/triage.md"
[ -e "$ROOT/commands/feedback.md" ] && fail "commands/feedback.md still exists" || pass
assert_contains "$ROOT/bdd-config.template.md" '| feedback-intake | `bdd:triage`'
assert_contains "$ROOT/commands/triage.md" '## BDD Triage'
assert_not_contains "$ROOT/commands/triage.md" '## BDD Feedback'
assert_contains "$INIT" 'run, triage or reconcile'

# design shows every scenario in full before approval; discover looks for existing behavior in the code
for s in 'Write every scenario out in full' 'Do not abbreviate' 'Abbreviating scenarios in the proposal'; do
  assert_contains "$ROOT/commands/design.md" "$s"
done
for s in 'Look for existing behavior' 'unit tests' 'from code' 'acceptance scenarios for existing behavior'; do
  assert_contains "$ROOT/commands/discover.md" "$s"
done

# /bdd:init --detect audits existing values (paths and skill roles), read-only, always
for s in '### Audit' 'Always run the audit' 'one line' 'not checked' 'header text' 'test filters' \
  'does not resolve' 'Skill Roles' 'Never edit a value in the audit'; do
  assert_contains "$INIT" "$s"
done
assert_not_contains "$INIT" 'If no row is a placeholder, say so and stop.'

# Leftovers: old install names count by name alone, unknown origin is not "your own", .gitignore is a hint only
for s in 'bdd-scenario-design' 'bdd-implement-scenario' 'test-feature' 'origin unknown, left alone' \
  '.claude/.gitignore' 'hint only'; do
  assert_contains "$INIT" "$s"
done
assert_not_contains "$INIT" 'is your own skill: say it stays'
assert_not_contains "$ROOT/README.md" 'Your own `bdd-*` skills are told apart'
assert_contains "$ROOT/README.md" 'origin unknown'
assert_contains "$ROOT/README.md" 'audits'


# the template is copied into user projects, so it must not carry an em-dash
assert_not_contains "$ROOT/bdd-config.template.md" "$(printf '\xe2\x80\x94')"

# README says headless runs may need the .claude/ write approved by hand
assert_contains "$ROOT/README.md" "claude -p"
assert_contains "$ROOT/README.md" "approve the write"


# /bdd:init --detect: a hint for generate failing on scenarios with no steps, and the decision_log question
for s in '### Hints' 'playwright-bdd' 'missingSteps' 'fail-on-run' 'Never edit project code' \
  'only when the setting is absent' 'no decision files' 'Turn the decision log on?' \
  'The one exception to never changing a filled row' 'only with approval' 'Do not remember a refusal'; do
  assert_contains "$INIT" "$s"
done


# No em-dash anywhere in the plugin, installer or tests (the older guard only checked added lines)
n=$(grep -rIl "$(printf '\xe2\x80\x94')" "$ROOT" --exclude-dir=.git --exclude-dir=docs --exclude-dir=results --exclude=test_plugin.sh --exclude=test_readme.sh --exclude=lib.sh --exclude=test_lib.sh | wc -l | tr -d ' ')
assert_equals 0 "$n" "files with an em-dash outside docs"

finish
