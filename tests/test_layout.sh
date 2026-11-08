#!/bin/bash
# The plugin lives in plugin/, so the directory scan reads only what users install.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/tests/lib.sh"

assert_equals "$ROOT/plugin" "$PLUGIN" "lib.sh sets PLUGIN"

# the manifest moved, the marketplace file did not
assert_file "$PLUGIN/.claude-plugin/plugin.json"
assert_file "$ROOT/.claude-plugin/marketplace.json"
[ -e "$ROOT/.claude-plugin/plugin.json" ] && fail "the root still holds a plugin manifest" || pass
assert_equals "./plugin" "$(jq -r '.plugins[0].source' "$ROOT/.claude-plugin/marketplace.json" 2>/dev/null)" "marketplace source"

# what goes inside, and what must not stay at the root
for d in commands agents scripts schemas evals; do
  [ -d "$PLUGIN/$d" ] && pass || fail "plugin/$d is missing"
  [ -e "$ROOT/$d" ] && fail "$d is still at the repo root" || pass
done
assert_file "$PLUGIN/bdd-config.template.md"
[ -e "$ROOT/bdd-config.template.md" ] && fail "bdd-config.template.md is still at the repo root" || pass

# what stays at the root
for p in tests docs .github install.sh CLAUDE.md CHANGELOG.md README.md LICENSE; do
  [ -e "$ROOT/$p" ] && pass || fail "$p is missing at the repo root"
done
for p in tests docs .github install.sh CLAUDE.md CHANGELOG.md; do
  [ -e "$PLUGIN/$p" ] && fail "$p must not be inside plugin/" || pass
done

# the listing README: at least 40 words outside code, and it links the full README
R="$PLUGIN/README.md"
assert_file "$R"
words=$(awk '/^```/{c=!c;next} !c' "$R" 2>/dev/null | wc -w | tr -d ' ')
[ "${words:-0}" -ge 40 ] && pass || fail "plugin/README.md has $words words outside code, need 40"
assert_contains "$R" "https://github.com/godrose/bdd-skills"

# users get only the plugin folder, so it carries its own licence copy
if cmp -s "$ROOT/LICENSE" "$PLUGIN/LICENSE"; then pass; else fail "plugin/LICENSE differs from LICENSE or is missing"; fi

# the eval results folder stays ignored
assert_contains "$ROOT/.gitignore" "plugin/evals/results/"

# how to run, check and evaluate the plugin
assert_contains "$ROOT/CLAUDE.md" 'claude --plugin-dir <this repo>/plugin'
assert_contains "$ROOT/README.md" 'claude --plugin-dir <clone>/plugin'
assert_contains "$ROOT/README.md" 'claude plugin validate plugin'
assert_contains "$ROOT/.github/workflows/evals.yml" 'claude plugin eval plugin'
assert_contains "$PLUGIN/evals/README.md" 'claude plugin eval plugin'

# CI keeps the layout from regressing
CI="$ROOT/.github/workflows/ci.yml"
assert_contains "$CI" 'claude plugin validate plugin'
assert_contains "$CI" '@anthropic-ai/claude-code@'

# the project-file installer reads from plugin/ and says so when it is missing
assert_contains "$ROOT/install.sh" 'PLUGIN_DIR="$SOURCE_DIR/plugin"'
assert_contains "$ROOT/install.sh" 'no plugin/ folder'

# the listing icon: a square PNG, 512 to 2048 px on each side, under 2 MB. The portal fixes it at the first save or submit.
ICON="$PLUGIN/.claude-plugin/icon.png"
assert_file "$ICON"
sig=$(od -An -tu1 -N8 "$ICON" 2>/dev/null | tr -s " " | sed "s/^ //; s/ $//")
assert_equals "137 80 78 71 13 10 26 10" "$sig" "icon.png is a PNG"
dims=$(od -An -tu1 -j16 -N8 "$ICON" 2>/dev/null)
set -- $dims
iw=$((${1:-0} * 16777216 + ${2:-0} * 65536 + ${3:-0} * 256 + ${4:-0})); ih=$((${5:-0} * 16777216 + ${6:-0} * 65536 + ${7:-0} * 256 + ${8:-0}))
assert_equals "$iw" "$ih" "icon.png is square"
[ "$iw" -ge 512 ] && [ "$iw" -le 2048 ] && pass || fail "icon.png is ${iw}px, need 512 to 2048"
[ "$(wc -c < "$ICON" 2>/dev/null || echo 99999999)" -lt 2097152 ] && pass || fail "icon.png is 2 MB or more, or missing"

# the directory scan pairs a token note with a case regex as a credential leaving the machine, so CI setup lives outside plugin/
if grep -rIlE "setup-token|CLAUDE_CODE_OAUTH_TOKEN" "$PLUGIN" --exclude-dir=results 2>/dev/null | grep -q .; then fail "plugin/ names the CI token setup"; else pass; fi
assert_file "$ROOT/docs/evals-ci.md"
assert_contains "$PLUGIN/evals/README.md" "docs/evals-ci.md"
assert_contains "$ROOT/docs/README.md" "evals-ci.md"

# the grants are broad on purpose, and the listing says why
assert_contains "$PLUGIN/README.md" "## Tool permissions"
assert_contains "$PLUGIN/README.md" "bdd-config.md"
assert_contains "$PLUGIN/README.md" "known-gaps.md"
assert_contains "$ROOT/docs/README.md" "allowed-tools-decision.md"

# the older packs stay as written, and the index says their paths follow the earlier layout
assert_contains "$ROOT/docs/README.md" 'earlier layout'

finish
