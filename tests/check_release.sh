#!/bin/bash
# Run by CI on pull requests whose title starts with "release:". Not part of tests/run.sh, which runs on every PR.
# The release-version scenarios source this file and call one check at a time, so the checks run only when it is run directly.
PASSES=0
FAILS=0

pass() { PASSES=$((PASSES + 1)); }
fail() { FAILS=$((FAILS + 1)); echo "FAIL: $1"; }
finish() { echo "passed=$PASSES failed=$FAILS"; [ "$FAILS" -eq 0 ]; }

# Print the plugin manifest as it was at a base commit. Reads the current location first and the one before the plugin moved into plugin/ second.
base_manifest() {
  local b="$1" p
  for p in plugin/.claude-plugin/plugin.json .claude-plugin/plugin.json; do
    git -C "$ROOT" show "$b:$p" 2>/dev/null && return 0
  done
  return 1
}

# Fail if plugin files changed since the merge-base with main but the plugin version did not.
# The cache is keyed by version, so a change without a bump never reaches installed users.
# A base without a plugin manifest is the first release and needs no bump.
assert_version_bumped() {
  local base old new changed
  base=$(git -C "$ROOT" merge-base HEAD main 2>/dev/null || git -C "$ROOT" merge-base HEAD origin/main 2>/dev/null)
  if [ -z "$base" ]; then
    fail "no main or origin/main to diff against"
    return
  fi
  old=$(base_manifest "$base" | jq -r .version 2>/dev/null)
  if [ -z "$old" ]; then
    pass
    return
  fi
  changed=$(git -C "$ROOT" diff --name-only "$base" -- plugin/commands plugin/agents plugin/scripts plugin/schemas plugin/bdd-config.template.md commands agents scripts schemas bdd-config.template.md)
  if [ -z "$changed" ]; then
    pass
    return
  fi
  new=$(jq -r .version "$ROOT/plugin/.claude-plugin/plugin.json" 2>/dev/null)
  if [ "$old" = "$new" ]; then
    fail "plugin files changed but the version is still $old: $(echo "$changed" | tr '\n' ' ')"
  else
    pass
  fi
}

# Fail unless the plugin version is higher than the one on main. Used for release PRs only.
# A base without a version is the first pinned release and passes.
assert_version_higher() {
  local base old new higher
  base=$(git -C "$ROOT" merge-base HEAD main 2>/dev/null || git -C "$ROOT" merge-base HEAD origin/main 2>/dev/null)
  if [ -z "$base" ]; then
    fail "no main or origin/main to diff against"
    return
  fi
  old=$(base_manifest "$base" | jq -r '.version // empty' 2>/dev/null)
  if [ -z "$old" ]; then
    pass
    return
  fi
  new=$(jq -r '.version // empty' "$ROOT/plugin/.claude-plugin/plugin.json" 2>/dev/null)
  higher=$(printf '%s\n%s\n' "$old" "$new" | awk -F. 'NR==1{a1=$1;a2=$2;a3=$3} NR==2{b1=$1;b2=$2;b3=$3} END{if (b1>a1 || (b1==a1 && (b2>a2 || (b2==a2 && b3>a3)))) print "yes"; else print "no"}')
  if [ "$higher" = yes ]; then
    pass
  else
    fail "version $new is not higher than $old on main"
  fi
}

sha256_of() { if command -v shasum >/dev/null; then shasum -a 256 | cut -d' ' -f1; else sha256sum | cut -d' ' -f1; fi; }

# Fail unless init's guard pin fits this release. init downloads scripts/examples.sh at the pinned tag and checks the pinned SHA-256.
# The pin must be the script in this release, at a tag that already holds it or at the tag of the new version.
# A plugin with no pin passes.
assert_guard_pinned() {
  local init="$ROOT/plugin/commands/init.md" tag sha here new
  tag=$(grep -o 'pinned to tag `[^`]*`' "$init" 2>/dev/null | head -1 | cut -d'`' -f2)
  sha=$(grep -oE 'Its SHA-256 at that tag is `[0-9a-f]{64}`' "$init" 2>/dev/null | head -1 | cut -d'`' -f2)
  if [ -z "$tag" ] && [ -z "$sha" ]; then
    pass
    return
  fi
  here=$(sha256_of < "$ROOT/scripts/examples.sh")
  if [ "$sha" != "$here" ]; then
    fail "init pins the guard script at $tag with $sha, but scripts/examples.sh is $here: move the pin to v<new version>"
    return
  fi
  new=$(jq -r '.version // empty' "$ROOT/plugin/.claude-plugin/plugin.json" 2>/dev/null)
  if [ "$tag" = "v$new" ] || [ "$(git -C "$ROOT" show "$tag:scripts/examples.sh" 2>/dev/null | sha256_of)" = "$sha" ]; then
    pass
  else
    fail "init pins the guard script to $tag, which neither holds this script nor is the new version v$new"
  fi
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  ROOT="$(cd "$(dirname "$0")/.." && pwd)"
  assert_version_higher
  assert_version_bumped
  assert_guard_pinned
  finish
fi
