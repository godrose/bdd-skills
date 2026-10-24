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

ROOT=$SAVED_ROOT
finish
