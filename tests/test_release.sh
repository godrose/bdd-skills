#!/bin/bash
# The release checks in tests/lib.sh, run against throwaway Git repos.
REAL="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$REAL"
. "$REAL/tests/lib.sh"

type assert_version_bumped >/dev/null 2>&1 && pass || fail "assert_version_bumped is missing from tests/lib.sh"
type assert_version_higher >/dev/null 2>&1 && pass || fail "assert_version_higher is missing from tests/lib.sh"

# A repo whose main has the given plugin version (empty = no version), then a feature branch with a new version.
# Args: base version, new version, "touch" to change a command file on the branch.
mkrepo() {
  local d g="git -c user.name=t -c user.email=t@t"
  d=$(mktemp -d)
  git -C "$d" init -q -b main
  mkdir -p "$d/plugin/.claude-plugin" "$d/plugin/commands"
  if [ -n "$1" ]; then printf '{"name":"bdd","version":"%s"}\n' "$1" > "$d/plugin/.claude-plugin/plugin.json"; else printf '{"name":"bdd"}\n' > "$d/plugin/.claude-plugin/plugin.json"; fi
  echo a > "$d/plugin/commands/x.md"
  $g -C "$d" add -A && $g -C "$d" commit -q -m base
  $g -C "$d" checkout -q -b feature
  printf '{"name":"bdd","version":"%s"}\n' "$2" > "$d/plugin/.claude-plugin/plugin.json"
  [ "$3" = touch ] && echo b >> "$d/plugin/commands/x.md"
  $g -C "$d" add -A && $g -C "$d" commit -q -m change
  echo "$d"
}

# Runs one check function in the repo and prints its exit status (0 = pass).
check() {
  ( ROOT="$1"; . "$REAL/tests/lib.sh"; "$2" >/dev/null 2>&1; finish >/dev/null 2>&1 ); echo $?
}

expect() { # label, want, got
  [ "$2" = "$3" ] && pass || fail "$1: expected exit $2, got $3"
}

d=$(mkrepo 0.4.0 0.4.0 touch)
expect "same version, command changed: bumped check" 1 "$(check "$d" assert_version_bumped)"
expect "same version: higher check" 1 "$(check "$d" assert_version_higher)"

d=$(mkrepo 0.4.0 0.4.1 touch)
expect "0.4.0 to 0.4.1: bumped check" 0 "$(check "$d" assert_version_bumped)"
expect "0.4.0 to 0.4.1: higher check" 0 "$(check "$d" assert_version_higher)"

d=$(mkrepo 0.4.0 0.3.0 touch)
expect "0.4.0 to 0.3.0: higher check" 1 "$(check "$d" assert_version_higher)"

d=$(mkrepo 0.4.9 0.4.10 touch)
expect "0.4.9 to 0.4.10: higher check (not a text sort)" 0 "$(check "$d" assert_version_higher)"

d=$(mkrepo "" 0.4.0 touch)
expect "base without a version: bumped check" 0 "$(check "$d" assert_version_bumped)"
expect "base without a version: higher check" 0 "$(check "$d" assert_version_higher)"

# A base from before the plugin moved into plugin/: the version is read from the old path.
# Args: base version, new version. The branch moves the files into plugin/ and sets the new version.
mkmoved() {
  local d g="git -c user.name=t -c user.email=t@t"
  d=$(mktemp -d)
  git -C "$d" init -q -b main
  mkdir -p "$d/.claude-plugin" "$d/commands"
  printf '{"name":"bdd","version":"%s"}\n' "$1" > "$d/.claude-plugin/plugin.json"
  echo a > "$d/commands/x.md"
  $g -C "$d" add -A && $g -C "$d" commit -q -m base
  $g -C "$d" checkout -q -b feature
  mkdir -p "$d/plugin"
  git -C "$d" mv .claude-plugin plugin/.claude-plugin && git -C "$d" mv commands plugin/commands
  printf '{"name":"bdd","version":"%s"}\n' "$2" > "$d/plugin/.claude-plugin/plugin.json"
  $g -C "$d" add -A && $g -C "$d" commit -q -m move
  echo "$d"
}

d=$(mkmoved 0.4.0 0.4.0)
expect "old-layout base, same version: higher check" 1 "$(check "$d" assert_version_higher)"
d=$(mkmoved 0.4.0 0.5.0)
expect "old-layout base, 0.4.0 to 0.5.0: higher check" 0 "$(check "$d" assert_version_higher)"
expect "old-layout base, 0.4.0 to 0.5.0: bumped check" 0 "$(check "$d" assert_version_bumped)"

finish
