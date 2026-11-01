#!/bin/bash
PASSES=0
FAILS=0

pass() { PASSES=$((PASSES + 1)); }
fail() { FAILS=$((FAILS + 1)); echo "FAIL: $1"; }

assert_file() { [ -f "$1" ] && pass || fail "missing file $1"; }
assert_contains() { grep -qF -- "$2" "$1" 2>/dev/null && pass || fail "$1 lacks: $2"; }
assert_not_contains() { if grep -qF -- "$2" "$1" 2>/dev/null; then fail "$1 has: $2"; else pass; fi; }
assert_equals() { [ "$1" = "$2" ] && pass || fail "$3: expected '$1' got '$2'"; }

finish() { echo "passed=$PASSES failed=$FAILS"; [ "$FAILS" -eq 0 ]; }

# In-place edit that works on BSD and GNU sed. The last argument is the file.
sedi() { local f="${!#}"; sed -i.bak "$@" && rm -f "$f.bak"; }

# Fail if lines added since the merge-base with main contain an em-dash (U+2014).
# Fails loudly when there is no base ref, so a shallow checkout cannot pass vacuously.
assert_no_added_emdash() {
  local base n
  base=$(git -C "$ROOT" merge-base HEAD main 2>/dev/null || git -C "$ROOT" merge-base HEAD origin/main 2>/dev/null)
  if [ -z "$base" ]; then
    fail "no main or origin/main to diff against"
    return
  fi
  n=$(git -C "$ROOT" diff "$base" -- "$@" | grep '^+' | grep -v '^+++' | grep -c "$(printf '\xe2\x80\x94')")
  assert_equals 0 "$n" "em-dashes added in $*"
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
  old=$(git -C "$ROOT" show "$base:.claude-plugin/plugin.json" 2>/dev/null | jq -r .version 2>/dev/null)
  if [ -z "$old" ]; then
    pass
    return
  fi
  changed=$(git -C "$ROOT" diff --name-only "$base" -- commands agents scripts schemas bdd-config.template.md)
  if [ -z "$changed" ]; then
    pass
    return
  fi
  new=$(jq -r .version "$ROOT/.claude-plugin/plugin.json" 2>/dev/null)
  if [ "$old" = "$new" ]; then
    fail "plugin files changed but the version is still $old: $(echo "$changed" | tr '\n' ' ')"
  else
    pass
  fi
}
