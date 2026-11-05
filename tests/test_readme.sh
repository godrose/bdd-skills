#!/bin/bash
# README structure: the way in comes first, reference material is folded away
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/tests/lib.sh"

R="$ROOT/README.md"
line() { grep -n -m1 -F -- "$1" "$R" | cut -d: -f1; }
before() { local a b; a=$(line "$1"); b=$(line "$2"); [ -n "$a" ] && [ -n "$b" ] && [ "$a" -lt "$b" ] && pass || fail "README: '$1' ($a) must come before '$2' ($b)"; }

assert_equals 0 "$(grep -c "$(printf '\xe2\x80\x94')" "$R")" "em-dashes in README"

for s in '## Contents' '## Quick start' '## The flow' '## Modes' '## Install' '## Configure' '## Decision log' '## Update'; do
  assert_contains "$R" "$s"
done

before '## Contents' '## Quick start'
before '## Quick start' '## The flow'
before '/plugin marketplace add godrose/bdd' '## The flow'
before '/bdd:init' '## The flow'
before '/bdd:discover <story>' '## The flow'
before '## The flow' '## Install'
before '## Install' '## What'"'"'s included'
before '## What'"'"'s included' '## Update'

# Reference material is folded
n=$(grep -c '^<details>' "$R")
[ "$n" -ge 5 ] && pass || fail "README has $n <details> blocks, expected at least 5"
assert_equals "$(grep -c '^<details>' "$R")" "$(grep -c '^</details>' "$R")" "unbalanced <details> blocks"
for s in '<summary><b>Files</b></summary>' '<summary><b>Architecture</b></summary>' '<summary><b>Optional config rows</b></summary>'; do
  assert_contains "$R" "$s"
done

# Every Contents link points at a heading that exists
grep -o '](#[a-z0-9-]*)' "$R" | sed 's/](#\(.*\))/\1/' | sort -u | while read -r a; do
  grep -E '^#{2,3} ' "$R" | tr 'A-Z' 'a-z' | sed -E 's/^#+ //; s/[^a-z0-9 -]//g; s/ /-/g' | grep -qx -- "$a" || echo "BADLINK $a"
done > "${TMPDIR:-/tmp}/readme-badlinks.$$"
[ -s "${TMPDIR:-/tmp}/readme-badlinks.$$" ] && fail "README Contents links with no heading: $(tr '\n' ' ' < "${TMPDIR:-/tmp}/readme-badlinks.$$")" || pass
rm -f "${TMPDIR:-/tmp}/readme-badlinks.$$"


# The prepare row is listed with the other optional rows
assert_contains "$R" '| `prepare` | none |'


# The .NET typecheck example must force a recompile, or it passes after generate without judging warnings
assert_contains "$R" 'dotnet build -c ServerWithFake -warnaserror --no-incremental'


# License and contributing: the copyright line is filled in, the README says how to contribute
assert_contains "$ROOT/LICENSE" 'Copyright 2026 Gennady Verdel'
assert_not_contains "$ROOT/LICENSE" '[yyyy]'
assert_not_contains "$ROOT/LICENSE" '[name of copyright owner]'
for s in '## Contributing' '## License' '- [Contributing](#contributing)' '- [License](#license)' \
  'bash tests/run.sh' 'docs/discovery/' 'Apache License 2.0' 'good first issue'; do
  assert_contains "$R" "$s"
done
before '## Update' '## Contributing'
before '## Contributing' '## License'

finish
