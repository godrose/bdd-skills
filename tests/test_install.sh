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
assert_equals "# Source: https://github.com/godrose/bdd" "$(sed -n 2p "$T/.claude/commands/bdd-discover.md" | cut -d'(' -f1 | sed 's/ *$//')" "discover source header"

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
finish
