#!/bin/bash
# Guard for the repo rename to bdd-skills. Drop this file once the old name is no longer a risk.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/tests/lib.sh"

old=$(cd "$ROOT" && grep -rIEn 'godrose/bdd($|[^-A-Za-z0-9]|-[^s])' . --exclude-dir=.git --exclude-dir=docs --exclude=test_rename.sh | cut -c1-120)
[ -z "$old" ] && pass || fail "old repo name outside docs/:
$old"

assert_contains "$ROOT/README.md" 'The repo is `bdd-skills`. The plugin is `bdd`, so its commands are `/bdd:*`.'
assert_contains "$ROOT/README.md" '/plugin marketplace add godrose/bdd-skills'
assert_contains "$ROOT/install.sh" 'REPO_URL="https://github.com/godrose/bdd-skills"'
assert_contains "$PLUGIN/.claude-plugin/plugin.json" '"repository": "https://github.com/godrose/bdd-skills"'
assert_contains "$PLUGIN/commands/init.md" '# Source: https://github.com/godrose/bdd-skills'

finish
