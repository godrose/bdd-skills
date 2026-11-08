#!/bin/bash
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/tests/lib.sh"
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

g() { git -C "$T/$1" -c user.name=t -c user.email=t@t "${@:2}"; }
mk() {
  mkdir -p "$T/$1"
  git -C "$T/$1" init -q -b "$2"
  echo a > "$T/$1/f.md"
  g "$1" add f.md
  g "$1" commit -q -m base
}
delta() {
  local b=$FAILS
  assert_no_added_emdash f.md > /dev/null 2>&1
  echo $((FAILS - b))
}
SAVED_ROOT=$ROOT

mk dashed main
g dashed switch -q -c work
printf 'b \xe2\x80\x94 c\n' >> "$T/dashed/f.md"
g dashed commit -q -am dash
ROOT="$T/dashed"
assert_equals 1 "$(FAILS=0; delta)" "an added em-dash is detected"

mk nobase other
ROOT="$T/nobase"
assert_equals 1 "$(FAILS=0; delta)" "a missing base ref fails loudly"

mk clean main
g clean switch -q -c work
echo plain >> "$T/clean/f.md"
g clean commit -q -am plain
ROOT="$T/clean"
assert_equals 0 "$(FAILS=0; delta)" "a clean diff passes"

mk moved main
printf 'old \xe2\x80\x94 line\n' >> "$T/moved/f.md"
g moved commit -q -am olddash
g moved switch -q -c work
mkdir -p "$T/moved/sub"
g moved mv f.md sub/f.md
g moved commit -q -m move
ROOT="$T/moved"
delta_paths() {
  local b=$FAILS
  assert_no_added_emdash f.md sub > /dev/null 2>&1
  echo $((FAILS - b))
}
assert_equals 0 "$(FAILS=0; delta_paths)" "a moved file keeps its old em-dash without a finding"
printf 'new \xe2\x80\x94 line\n' >> "$T/moved/sub/f.md"
g moved commit -q -am newdash
assert_equals 1 "$(FAILS=0; delta_paths)" "a new em-dash in a moved file is still found"

mkp() {
  mkdir -p "$T/$1/plugin/commands" "$T/$1/plugin/.claude-plugin"
  git -C "$T/$1" init -q -b main
  echo a > "$T/$1/plugin/commands/x.md"
  echo '{"name":"bdd","version":"0.1.0"}' > "$T/$1/plugin/.claude-plugin/plugin.json"
  g "$1" add -A
  g "$1" commit -q -m base
  g "$1" switch -q -c work
}
vdelta() {
  local b=$FAILS
  assert_version_bumped > /dev/null 2>&1
  echo $((FAILS - b))
}

mkp vb-nobump
echo b >> "$T/vb-nobump/plugin/commands/x.md"
g vb-nobump commit -q -am edit
ROOT="$T/vb-nobump"
assert_equals 1 "$(FAILS=0; vdelta)" "a changed command without a version bump fails"

mkp vb-bump
echo b >> "$T/vb-bump/plugin/commands/x.md"
echo '{"name":"bdd","version":"0.1.1"}' > "$T/vb-bump/plugin/.claude-plugin/plugin.json"
g vb-bump commit -q -am edit
ROOT="$T/vb-bump"
assert_equals 0 "$(FAILS=0; vdelta)" "a changed command with a version bump passes"

mkp vb-docs
echo b > "$T/vb-docs/README.md"
g vb-docs add README.md
g vb-docs commit -q -m docs
ROOT="$T/vb-docs"
assert_equals 0 "$(FAILS=0; vdelta)" "a docs-only change needs no bump"

mk vb-first main
g vb-first switch -q -c work
mkdir -p "$T/vb-first/plugin/commands" "$T/vb-first/plugin/.claude-plugin"
echo a > "$T/vb-first/plugin/commands/x.md"
echo '{"name":"bdd","version":"0.1.0"}' > "$T/vb-first/plugin/.claude-plugin/plugin.json"
g vb-first add -A
g vb-first commit -q -m plugin
ROOT="$T/vb-first"
assert_equals 0 "$(FAILS=0; vdelta)" "the first release needs no bump"

ROOT=$SAVED_ROOT
finish
