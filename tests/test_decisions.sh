#!/bin/bash
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/tests/lib.sh"
SCRIPT="$ROOT/scripts/decisions.sh"
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

new_project() {
  local p
  p=$(mktemp -d "$T/p.XXXXXX")
  mkdir -p "$p/docs/decisions" "$p/features"
  echo "$p"
}
log_add() { printf '%s\n' "$3" >> "$1/docs/decisions/$2.jsonl"; }
add_feature() {
  cat > "$1/features/export.feature" <<'EOF'
Feature: Export
  @spec-header-row @pending
  Scenario: Header row
    Given an order list
    When I export it
    Then the file has a header row
EOF
}
check_in() {
  local p="$1"
  shift
  OUT=$(cd "$p" && bash "$SCRIPT" check --dir docs/decisions --features features "$@" 2>&1)
  RC=$?
}
has() { printf '%s' "$OUT" | grep -qF -- "$1" && pass || fail "output lacks: $1"; }
lacks() { if printf '%s' "$OUT" | grep -qF -- "$1"; then fail "output has: $1"; else pass; fi; }

D_OK='{"v":1,"id":"S-01","kind":"decision","story":"S","at":"2026-10-31","text":"Header row is exported.","effects":[{"op":"adds","scenario":"spec-header-row","fp":"aaaaaaaa"}]}'
D_OK2='{"v":1,"id":"S-02","kind":"decision","story":"S","at":"2026-11-01","text":"Dates use one format.","effects":[]}'

# valid log
p=$(new_project); add_feature "$p"; log_add "$p" S "$D_OK"
check_in "$p"
assert_equals 0 "$RC" "valid log passes"
has "summary errors=0"

# bad JSON
p=$(new_project); add_feature "$p"; log_add "$p" S "$D_OK"; log_add "$p" S '{not json'
check_in "$p"
assert_equals 1 "$RC" "bad JSON fails"
has "ERROR E-JSON"
has "S.jsonl:2"

# missing field
p=$(new_project); add_feature "$p"
log_add "$p" S '{"v":1,"id":"S-01","kind":"decision","story":"S","at":"2026-10-31"}'
check_in "$p"
has "ERROR E-SCHEMA"
has "missing field text"

# future version
p=$(new_project); add_feature "$p"
log_add "$p" S '{"v":2,"id":"S-01","kind":"decision","story":"S","at":"2026-10-31","text":"x"}'
check_in "$p"
has "ERROR E-VERSION"
has "update the skills"

# bad op
p=$(new_project); add_feature "$p"
log_add "$p" S '{"v":1,"id":"S-01","kind":"decision","story":"S","at":"2026-10-31","text":"x","effects":[{"op":"burns","scenario":"spec-header-row"}]}'
check_in "$p"
has "ERROR E-SCHEMA"

# bad source role
p=$(new_project); add_feature "$p"; log_add "$p" S "$D_OK"
log_add "$p" S '{"v":1,"id":"S-02","kind":"confirms","of":"S-01","at":"2026-11-01","sources":[{"kind":"slack","ref":"x","role":"maybe"}]}'
check_in "$p"
has "ERROR E-SCHEMA"
has "unknown source role"

# id does not match file name
p=$(new_project); add_feature "$p"; log_add "$p" OTHER "$D_OK"
check_in "$p"
has "ERROR E-SCHEMA"
has "must start with OTHER-"

# bad scenario id
p=$(new_project); add_feature "$p"
log_add "$p" S '{"v":1,"id":"S-01","kind":"decision","story":"S","at":"2026-10-31","text":"x","effects":[{"op":"adds","scenario":"Spec_Header","fp":"aaaaaaaa"}]}'
check_in "$p"
has "ERROR E-SCHEMA"
has "Spec_Header"

# duplicate id
p=$(new_project); add_feature "$p"; log_add "$p" S "$D_OK"; log_add "$p" S "$D_OK"
check_in "$p"
has "ERROR E-DUP-ID"

# dangling references
p=$(new_project); add_feature "$p"; log_add "$p" S "$D_OK"
log_add "$p" S '{"v":1,"id":"S-02","kind":"decision","story":"S","at":"2026-11-01","text":"x","supersedes":["S-99"]}'
log_add "$p" S '{"v":1,"id":"S-03","kind":"decision","story":"S","at":"2026-11-01","text":"x","resolves":["S-99"]}'
log_add "$p" S '{"v":1,"id":"S-04","kind":"confirms","of":"S-99","at":"2026-11-01","sources":[]}'
check_in "$p"
assert_equals 3 "$(printf '%s\n' "$OUT" | grep -c 'E-REF')" "three dangling references"

# CRLF, blank lines and no final newline
p=$(new_project); add_feature "$p"
printf '%s\r\n\r\n%s' "$D_OK" "$D_OK2" > "$p/docs/decisions/S.jsonl"
check_in "$p"
assert_equals 0 "$RC" "CRLF, blank line and missing final newline are tolerated"
has "summary errors=0"

# no decisions directory
p=$(new_project); rmdir "$p/docs/decisions"
check_in "$p"
assert_equals 0 "$RC" "missing decisions dir passes"
has "I-EMPTY"

# empty file
p=$(new_project); : > "$p/docs/decisions/S.jsonl"
check_in "$p"
assert_equals 0 "$RC" "empty log file passes"

# no jq
OUT=$(PATH=/nonexistent /bin/bash "$SCRIPT" check 2>&1)
RC=$?
assert_equals 2 "$RC" "missing jq exits 2"
has "jq"

# env fallback, and flags beat env
p=$(new_project); add_feature "$p"; mkdir -p "$p/custom"; printf '%s\n' "$D_OK" > "$p/custom/S.jsonl"
OUT=$(cd "$p" && BDD_DECISIONS_DIR=custom bash "$SCRIPT" check --features features 2>&1)
RC=$?
assert_equals 0 "$RC" "env directory is used"
lacks "I-EMPTY"
OUT=$(cd "$p" && BDD_DECISIONS_DIR=bogus bash "$SCRIPT" check --dir custom --features features 2>&1)
lacks "I-EMPTY"

# default directory when neither flag nor env is given
p=$(new_project); add_feature "$p"
log_add "$p" S '{"v":1,"id":"S-01","kind":"decision","story":"S","at":"2026-10-31"}'
OUT=$(cd "$p" && bash "$SCRIPT" check --features features 2>&1)
has "ERROR E-SCHEMA"


# --- append-only check against a base ref ---
G() {
  local p="$1"
  shift
  git -C "$p" -c user.name=t -c user.email=t@t -c core.autocrlf=false "$@"
}
repo_with_log() {
  local p
  p=$(new_project)
  add_feature "$p"
  log_add "$p" S "$D_OK"
  G "$p" init -q
  G "$p" add -A
  G "$p" commit -q -m base
  echo "$p"
}
T_OK='{"v":1,"id":"T-01","kind":"decision","story":"T","at":"2026-11-01","text":"Other story."}'

p=$(repo_with_log); log_add "$p" S "$D_OK2"
check_in "$p" --base HEAD
assert_equals 0 "$RC" "append passes"

p=$(repo_with_log); printf '%s\n' "${D_OK/exported/exportxd}" > "$p/docs/decisions/S.jsonl"
check_in "$p" --base HEAD
assert_equals 1 "$RC" "edited record fails"
has "ERROR E-APPEND"
has "S.jsonl:1"

p=$(repo_with_log); : > "$p/docs/decisions/S.jsonl"
check_in "$p" --base HEAD
has "ERROR E-APPEND"

p=$(repo_with_log); log_add "$p" S "$D_OK2"; sed -i '' 1d "$p/docs/decisions/S.jsonl"
check_in "$p" --base HEAD
has "ERROR E-APPEND"

p=$(repo_with_log); rm "$p/docs/decisions/S.jsonl"
check_in "$p" --base HEAD
has "ERROR E-APPEND"

p=$(repo_with_log); log_add "$p" T "$T_OK"
check_in "$p" --base HEAD
assert_equals 0 "$RC" "new file passes"

p=$(new_project); add_feature "$p"; rmdir "$p/docs/decisions"
G "$p" init -q; G "$p" add -A; G "$p" commit -q -m base
mkdir -p "$p/docs/decisions"; log_add "$p" S "$D_OK"
check_in "$p" --base HEAD
assert_equals 0 "$RC" "first adoption passes"

p=$(new_project); add_feature "$p"; printf '%s\r\n' "$D_OK" > "$p/docs/decisions/S.jsonl"
G "$p" init -q; G "$p" add -A; G "$p" commit -q -m base
printf '%s\n' "$D_OK" > "$p/docs/decisions/S.jsonl"
check_in "$p" --base HEAD
assert_equals 0 "$RC" "CRLF base against LF working copy passes"

p=$(new_project); add_feature "$p"; log_add "$p" S "$D_OK"
check_in "$p" --base HEAD
assert_equals 2 "$RC" "not a git repository exits 2"

p=$(repo_with_log)
check_in "$p" --base no-such-ref
assert_equals 2 "$RC" "unknown ref exits 2"

# the merge advice in the spec: parallel appends merge cleanly with merge=union
p=$(repo_with_log)
printf 'docs/decisions/*.jsonl merge=union\n' > "$p/.gitattributes"
G "$p" add -A; G "$p" commit -q -m attrs
main_branch=$(G "$p" rev-parse --abbrev-ref HEAD)
G "$p" checkout -q -b a; log_add "$p" S "$D_OK2"; G "$p" commit -q -am a
G "$p" checkout -q -b b "$main_branch"
log_add "$p" S '{"v":1,"id":"S-03","kind":"decision","story":"S","at":"2026-11-01","text":"Third."}'
G "$p" commit -q -am b
G "$p" checkout -q "$main_branch"
G "$p" merge -q a >/dev/null 2>&1
G "$p" merge -q --no-edit b >/dev/null 2>&1
assert_equals 0 "$?" "union merge has no conflict"
assert_equals 3 "$(wc -l < "$p/docs/decisions/S.jsonl" | tr -d ' ')" "union merge keeps all three records"


# --- scenario lookup and fingerprint ---
feat() {
  mkdir -p "$1/features"
  cat > "$1/features/$2"
}
fp_of() {
  OUT=$(cd "$1" && bash "$SCRIPT" fingerprint "$2" --features features 2>&1)
  RC=$?
}
BASE_FEATURE='Feature: Export
  @spec-header-row @pending
  Scenario: Header row
    Given an order list
    When I export it
    Then the file has a header row
'

p=$(new_project); printf '%s' "$BASE_FEATURE" | feat "$p" a.feature
fp_of "$p" spec-header-row
assert_equals 0 "$RC" "fingerprint of a plain scenario"
FP_BASE="$OUT"
assert_equals 8 "${#FP_BASE}" "fingerprint is 8 characters"

p=$(new_project)
printf '# top comment\nFeature: Export\n  @spec-header-row @other-tag @pending\n  # between tags and keyword\n  Scenario:    Header   row\n        Given an order list\n    When I export it\n\n    Then the file has a header row\n' | sed 's/$/\r/' | feat "$p" a.feature
fp_of "$p" spec-header-row
assert_equals "$FP_BASE" "$OUT" "tags, comments, spacing, blank lines and CRLF do not change the fingerprint"

p=$(new_project); printf '%s' "$BASE_FEATURE" | sed 's/ @pending//' | feat "$p" a.feature
fp_of "$p" spec-header-row
assert_equals "$FP_BASE" "$OUT" "flipping a status tag does not change the fingerprint"

p=$(new_project); printf '%s' "$BASE_FEATURE" | sed 's/When I export it/When I export the list/' | feat "$p" a.feature
fp_of "$p" spec-header-row
[ "$OUT" != "$FP_BASE" ] && pass || fail "a reworded step must change the fingerprint"

OUTLINE='Feature: Export
  @spec-header-row
  Scenario Outline: Header row
    Given an order list with <count> orders
    Then the file has a header row

    Examples:
      | count |
      | 0     |
      | 5     |
'
p=$(new_project); printf '%s' "$OUTLINE" | feat "$p" a.feature
fp_of "$p" spec-header-row; FP_OUT="$OUT"
assert_equals 0 "$RC" "scenario outline fingerprint"
p=$(new_project); printf '%s' "$OUTLINE" | sed 's/| 5 /| 6 /' | feat "$p" a.feature
fp_of "$p" spec-header-row
[ "$OUT" != "$FP_OUT" ] && pass || fail "an Examples cell change must change the fingerprint"

p=$(new_project); printf 'Feature: Export\n  # @spec-header-row\n  Scenario: Header row\n    Given an order list\n' | feat "$p" a.feature
fp_of "$p" spec-header-row
assert_equals 1 "$RC" "id in a comment is not a tag"
printf '%s' "$OUT" | grep -qF "not found" && pass || fail "comment: expected not found"

p=$(new_project); printf 'Feature: Export\n  Scenario: Header row\n    Given a note says @spec-header-row\n' | feat "$p" a.feature
fp_of "$p" spec-header-row
assert_equals 1 "$RC" "id in a step is not a tag"

p=$(new_project); printf '@spec-header-row\nFeature: Export\n  Scenario: Header row\n    Given an order list\n' | feat "$p" a.feature
fp_of "$p" spec-header-row
assert_equals 1 "$RC" "id on the Feature line is not a scenario tag"

p=$(new_project)
printf 'Feature: Export\n  @spec-header-row\n  Scenario: One\n    Given a\n  @spec-header-row\n  Scenario: Two\n    Given b\n' | feat "$p" a.feature
fp_of "$p" spec-header-row
assert_equals 1 "$RC" "duplicate id in one file"
printf '%s' "$OUT" | grep -qF "ambiguous" && pass || fail "duplicate: expected ambiguous"

p=$(new_project)
printf '%s' "$BASE_FEATURE" | feat "$p" a.feature
printf '%s' "$BASE_FEATURE" | feat "$p" b.feature
fp_of "$p" spec-header-row
assert_equals 1 "$RC" "duplicate id across files"

p=$(new_project)
printf 'Feature: Export\n  @spec-one @spec-two\n  Scenario: Both\n    Given a\n' | feat "$p" a.feature
fp_of "$p" spec-one; A="$OUT"
fp_of "$p" spec-two; B="$OUT"
assert_equals "$A" "$B" "two ids on one scenario share a fingerprint"

p=$(new_project); printf 'Feature: Export\n  @spec-header-row\n  Scenario: Header row\n    Given an order list' | feat "$p" a.feature
fp_of "$p" spec-header-row
assert_equals 0 "$RC" "no final newline"

# a neighbour's change does not move this scenario's fingerprint
NEIGHBOURS='Feature: Export
  Rule: Headers
    @spec-header-row
    Scenario: Header row
      Given an order list

    @spec-other
    Scenario: Other
      Given STEP
'
p=$(new_project); printf '%s' "$NEIGHBOURS" | sed 's/STEP/one/' | feat "$p" a.feature
fp_of "$p" spec-header-row; A="$OUT"
p=$(new_project); printf '%s' "$NEIGHBOURS" | sed 's/STEP/two/' | feat "$p" a.feature
fp_of "$p" spec-header-row
assert_equals "$A" "$OUT" "a neighbour change does not change the fingerprint"

OUT=$(cd "$(new_project)" && bash "$SCRIPT" fingerprint spec-header-row 2>&1)
assert_equals 2 "$?" "fingerprint without --features exits 2"


# --- live decisions and reconciliation findings ---
real_fp() { (cd "$1" && bash "$SCRIPT" fingerprint "$2" --features features); }
mk() { printf '{"v":1,"id":"%s","kind":"decision","story":"S","at":"%s","text":"Text %s.","effects":%s%s}' "$1" "$2" "$1" "$3" "$4"; }
adds() { printf '[{"op":"adds","scenario":"%s","fp":"%s"}]' "$1" "$2"; }
chg() { printf '[{"op":"changes","scenario":"%s","fp":"%s"}]' "$1" "$2"; }
rew() { printf '[{"op":"rewords","scenario":"%s","fp":"%s"}]' "$1" "$2"; }
RM='[{"op":"removes","scenario":"spec-header-row"}]'

p=$(new_project); add_feature "$p"; FP=$(real_fp "$p" spec-header-row)
log_add "$p" S "$(mk S-01 2026-10-31 "$(adds spec-header-row "$FP")")"
check_in "$p"
assert_equals 0 "$RC" "healthy log passes"
has "summary errors=0 warnings=0"

p=$(new_project)
log_add "$p" S "$(mk S-01 2026-10-31 "$(adds spec-header-row aaaaaaaa)")"
check_in "$p"
assert_equals 1 "$RC" "orphan fails"
has "ERROR E-ORPHAN"

p=$(new_project)
log_add "$p" S "$(mk S-01 2026-10-31 "$(adds spec-header-row aaaaaaaa)")"
log_add "$p" S "$(mk S-02 2026-11-01 "$RM")"
check_in "$p"
assert_equals 0 "$RC" "a removed scenario is not an orphan"
lacks "E-ORPHAN"
lacks "W-UNDECIDED"

p=$(new_project); add_feature "$p"
log_add "$p" S "$(mk S-01 2026-10-31 "$(adds spec-header-row aaaaaaaa)")"
log_add "$p" S "$(mk S-02 2026-11-01 "$RM")"
check_in "$p"
has "WARN W-UNDECIDED"

p=$(new_project); add_feature "$p"; FP=$(real_fp "$p" spec-header-row)
log_add "$p" S "$(mk S-01 2026-10-31 "$(adds spec-header-row "$FP")")"
sed -i '' 's/I export it/I export the list/' "$p/features/export.feature"
check_in "$p"
assert_equals 0 "$RC" "drift is a warning"
has "WARN W-DRIFT"
NEWFP=$(real_fp "$p" spec-header-row)
log_add "$p" S "$(mk S-02 2026-11-01 "$(rew spec-header-row "$NEWFP")")"
check_in "$p"
lacks "W-DRIFT"

p=$(new_project); add_feature "$p"; FP=$(real_fp "$p" spec-header-row)
log_add "$p" S "$(mk S-01 2026-10-31 "$(adds spec-gone aaaaaaaa)")"
log_add "$p" S "$(mk S-02 2026-11-01 "$(chg spec-header-row "$FP")" ',"supersedes":["S-01"]')"
check_in "$p"
assert_equals 0 "$RC" "a superseded decision is not live"
lacks "E-ORPHAN"

p=$(new_project); add_feature "$p"; FP=$(real_fp "$p" spec-header-row)
log_add "$p" S "$(mk S-01 2026-10-31 "$(adds spec-header-row "$FP")")"
log_add "$p" S "$(mk S-02 2026-11-01 "$(chg spec-header-row "$FP")" ',"supersedes":["S-01"]')"
log_add "$p" S "$(mk S-03 2026-11-02 '[]' ',"supersedes":["S-01"]')"
check_in "$p"
has "WARN W-CONFLICT"

p=$(new_project); add_feature "$p"
check_in "$p"
assert_equals 0 "$RC" "an undecided scenario is a warning"
has "WARN W-UNDECIDED"

p=$(new_project)
printf 'Feature: Legacy\n  Scenario: One\n    Given a\n  Scenario: Two\n    Given b\n  @spec-x\n  Scenario: Three\n    Given c\n' | feat "$p" a.feature
check_in "$p"
has "I-LEGACY 2"

p=$(new_project)
printf 'Feature: Export\n  @spec-header-row\n  Scenario: One\n    Given a\n  @spec-header-row\n  Scenario: Two\n    Given b\n' | feat "$p" a.feature
check_in "$p"
assert_equals 1 "$RC" "duplicate scenario tag fails"
has "ERROR E-DUP-SCENARIO"

p=$(new_project)
log_add "$p" S "$(mk S-01 2026-10-31 '[{"op":"excludes","phrase":"partial exports"}]')"
log_add "$p" S "$(mk S-02 2026-10-31 '[{"op":"defers","phrase":"large exports","reason":"later"}]')"
log_add "$p" S "$(mk S-03 2026-10-31 '[]')"
check_in "$p"
assert_equals 0 "$RC" "exclude, defer and rationale decisions pass"
has "summary errors=0 warnings=0"

p=$(new_project)
log_add "$p" S '{"v":1,"id":"S-01","kind":"open","story":"S","at":"2026-10-30","text":"One column or two?"}'
log_add "$p" S "$(mk S-02 2026-10-31 '[]' ',"resolves":["S-01"]')"
check_in "$p"
assert_equals 0 "$RC" "open item with a resolving decision passes"
has "summary errors=0 warnings=0"

# scope with --base
two_stories() {
  local p; p=$(new_project)
  printf 'Feature: A\n  @spec-a\n  Scenario: A\n    Given a\n' > "$p/features/a.feature"
  printf 'Feature: B\n  @spec-b\n  Scenario: B\n    Given b\n' > "$p/features/b.feature"
  FPB=$(real_fp "$p" spec-b)
  printf '%s\n' '{"v":1,"id":"A-01","kind":"decision","story":"A","at":"2026-10-31","text":"A.","effects":[{"op":"adds","scenario":"spec-a","fp":"bbbbbbbb"}]}' > "$p/docs/decisions/A.jsonl"
  printf '%s\n' "{\"v\":1,\"id\":\"B-01\",\"kind\":\"decision\",\"story\":\"B\",\"at\":\"2026-10-31\",\"text\":\"B.\",\"effects\":[{\"op\":\"adds\",\"scenario\":\"spec-b\",\"fp\":\"$FPB\"}]}" > "$p/docs/decisions/B.jsonl"
  G "$p" init -q; G "$p" add -A; G "$p" commit -q -m base
  echo "$p"
}
p=$(two_stories)
printf '%s\n' '{"v":1,"id":"B-02","kind":"decision","story":"B","at":"2026-11-01","text":"More B."}' >> "$p/docs/decisions/B.jsonl"
check_in "$p" --base HEAD
lacks "W-DRIFT"
check_in "$p"
has "WARN W-DRIFT"

p=$(two_stories)
rm "$p/features/a.feature"
check_in "$p" --base HEAD
has "ERROR E-ORPHAN"
printf 'Feature: A\n  @spec-a\n  Scenario: A\n    Given a\n' > "$p/features/a.feature"
printf 'Feature: A\n  @spec-a\n  Scenario: A\n    Given a changed\n' > "$p/features/a.feature"
check_in "$p" --base HEAD
has "WARN W-DRIFT"


# status
status_in() {
  local p="$1"; shift
  OUT=$(cd "$p" && bash "$SCRIPT" status "$@" 2>&1)
  RC=$?
}
sp() {
  local p; p=$(new_project)
  printf '%s' "$1" > "$p/features/s.feature"
  echo "$p"
}
p=$(sp $'Feature: F\n  @spec-x @pending\n  Scenario: X\n    Given x\n')
status_in "$p" spec-x --features features
assert_equals "planned" "$OUT" "default pending is planned"
p=$(sp $'Feature: F\n  @spec-x\n  Scenario: X\n    Given x\n')
status_in "$p" spec-x --features features
assert_equals "automated" "$OUT" "no marker is automated"
p=$(sp $'Feature: F\n  @spec-x @manual-only\n  Scenario: X\n    Given x\n')
status_in "$p" spec-x --features features
assert_equals "manual-only" "$OUT" "manual-only tag"
p=$(sp $'Feature: F\n  @spec-x @pending @manual-only\n  Scenario: X\n    Given x\n')
status_in "$p" spec-x --features features
assert_equals "manual-only" "$OUT" "manual-only wins over pending"
p=$(sp $'Feature: F\n  @spec-x @blocked\n  Scenario: X\n    Given x\n')
status_in "$p" spec-x --features features --blocked-tag @blocked
assert_equals "blocked" "$OUT" "blocked tag"
status_in "$p" spec-x --features features
assert_equals "automated" "$OUT" "blocked tag ignored without the row"
p=$(sp $'Feature: F\n  @spec-x @manual\n  Scenario: X\n    Given x\n')
status_in "$p" spec-x --features features --planned-tag @manual
assert_equals "planned" "$OUT" "custom planned tag"
p=$(sp $'@pending\nFeature: F\n  @spec-x\n  Scenario: X\n    Given x\n')
status_in "$p" spec-x --features features --scope feature
assert_equals "planned" "$OUT" "feature scope reads Feature tags"
status_in "$p" spec-x --features features
assert_equals "automated" "$OUT" "scenario scope ignores Feature tags"
p=$(new_project); mkdir -p "$p/features/formulated"
printf 'Feature: F\n  @spec-x\n  Scenario: X\n    Given x\n' > "$p/features/formulated/s.feature"
status_in "$p" spec-x --features features --scope directory --planned-dir formulated
assert_equals "planned" "$OUT" "directory scope planned"
p=$(new_project); mkdir -p "$p/features/manual/ldap"
printf 'Feature: F\n  @spec-x\n  Scenario: X\n    Given x\n' > "$p/features/manual/ldap/s.feature"
status_in "$p" spec-x --features features --scope directory --manual-only-dir manual
assert_equals "manual-only" "$OUT" "directory scope nested manual-only"
status_in "$p" spec-nope --features features
assert_equals 1 "$RC" "missing scenario exits 1"
printf '%s' "$OUT" | grep -qF "not found" && pass || fail "missing says not found"


# show
show_in() {
  local p="$1"; shift
  OUT=$(cd "$p" && bash "$SCRIPT" show "$@" 2>&1)
  RC=$?
}
dec() { printf '{"v":1,"id":"%s","kind":"decision","story":"S","at":"%s","text":%s%s}' "$1" "$2" "$(printf '%s' "$3" | jq -Rs .)" "${4:+,$4}"; }
line_of() { printf '%s\n' "$OUT" | grep -n -F -- "$1" | head -1 | cut -d: -f1; }

p=$(new_project)
printf 'Feature: F\n  @spec-a @pending\n  Scenario: A\n    Given a\n  @spec-b @manual-only\n  Scenario: B\n    Given b\n  @spec-c\n  Scenario: C\n    Given c\n' > "$p/features/s.feature"
FA=$(real_fp "$p" spec-a); FB_=$(real_fp "$p" spec-b); FC=$(real_fp "$p" spec-c)
log_add "$p" S "$(dec S-01 2026-10-01 'Alpha is exported.' '"effects":[{"op":"adds","scenario":"spec-a","fp":"'$FA'"}],"sources":[{"kind":"slack","ref":"https://s/1","role":"agreed"}]')"
log_add "$p" S "$(dec S-02 2026-10-02 'Bravo is checked.' '"effects":[{"op":"adds","scenario":"spec-b","fp":"'$FB_'"}]')"
log_add "$p" S "$(dec S-03 2026-10-03 'Charlie is exported.' '"effects":[{"op":"adds","scenario":"spec-c","fp":"'$FC'"}]')"
log_add "$p" S "$(dec S-04 2026-10-04 'No audit trail.' '"effects":[{"op":"excludes","phrase":"audit"}]')"
log_add "$p" S '{"v":1,"id":"S-05","kind":"open","story":"S","at":"2026-10-05","text":"Who owns retention?"}'
log_add "$p" S '{"v":1,"id":"S-06","kind":"open","story":"S","at":"2026-10-05","text":"Resolved question?"}'
log_add "$p" S "$(dec S-07 2026-10-06 'Retention is ninety days.' '"resolves":"S-06"')"
log_add "$p" S "$(dec S-08 2026-10-07 'Old wording.')"
log_add "$p" S "$(dec S-09 2026-10-08 'New wording.' '"supersedes":["S-08"]')"
show_in "$p" S --dir docs/decisions --features features
assert_equals 0 "$RC" "show exits 0"
has "# Agreed behavior: S"
a=$(line_of "## What we agreed"); b=$(line_of "## Left out, postponed or accepted"); c=$(line_of "## Still open"); d=$(line_of "## History")
[ -n "$a" ] && [ -n "$b" ] && [ -n "$c" ] && [ -n "$d" ] && [ "$a" -lt "$b" ] && [ "$b" -lt "$c" ] && [ "$c" -lt "$d" ] && pass || fail "section order: $a $b $c $d"
has "Alpha is exported. (planned) ([source](https://s/1))"
has "Bravo is checked. (checked by hand)"
has "Charlie is exported. (automated)"
lacks "S-01"
lacks "$FA"
printf '%s\n' "$OUT" | sed -n "/## Still open/,/## History/p" | grep -qF "Resolved question?" && fail "resolved open still listed" || pass
has "Who owns retention?"
printf '%s\n' "$OUT" | sed -n "/## History/,\$p" | grep -qF "Old wording. (replaced on 2026-10-08)" && pass || fail "superseded in history"
printf '%s\n' "$OUT" | sed -n "1,/## History/p" | grep -qF "Old wording." && fail "old text outside history" || pass
printf '%s\n' "$OUT" | sed -n "/## History/,\$p" | grep -qF "Resolved question? (closed)" && pass || fail "closed open in history"
OUT1="$OUT"; show_in "$p" S --dir docs/decisions --features features
assert_equals "$OUT1" "$OUT" "deterministic output"
has "not in a git repository"
show_in "$p" S --dir docs/decisions --features features --channel https://x/c
has "Discussion: https://x/c"
show_in "$p" NOPE --dir docs/decisions --features features
assert_equals 0 "$RC" "unknown story exits 0"
has "No decisions recorded for NOPE"

p=$(new_project)
log_add "$p" S "$(dec S-01 2026-10-01 'A | B *bold* "q" é 中')"
show_in "$p" S --dir docs/decisions
has 'A | B *bold* "q" é 中'
lacks "## Still open"
lacks "## History"
has "Nothing agreed yet."
G "$p" init -q; G "$p" add -A; G "$p" commit -q -m base
SHA=$(G "$p" rev-parse --short HEAD)
show_in "$p" S --dir docs/decisions
has "Generated from git at commit $SHA"
lacks "uncommitted changes"
log_add "$p" S "$(dec S-02 2026-11-01 'Changed text.' '"supersedes":["S-01"]')"
log_add "$p" S "$(dec S-03 2026-11-01 'Gone thing.' '"effects":[{"op":"removes","scenario":"spec-gone"}]')"
log_add "$p" S "$(dec S-04 2026-11-01 'Skipped thing.' '"effects":[{"op":"excludes","phrase":"x"}]')"
log_add "$p" S "$(dec S-05 2026-11-01 'Later thing.' '"effects":[{"op":"defers","phrase":"y"}]')"
log_add "$p" S "$(dec S-06 2026-11-01 'Plain thing.')"
show_in "$p" S --dir docs/decisions --since HEAD
has "## Changed since you last looked"
has "Changed: Changed text. (was: A | B *bold* \"q\" é 中)"
has "Removed: Gone thing."
has "Left out: Skipped thing."
has "Postponed: Later thing."
has "Added: Plain thing."
has "uncommitted changes"
show_in "$p" S --dir docs/decisions
lacks "Changed since you last looked"

# final review fixes
fp_in() {
  local p="$1"; shift
  OUT=$(cd "$p" && bash "$SCRIPT" fingerprint "$@" --features features 2>&1)
  RC=$?
}
p=$(new_project)
printf 'Feature: A\n  @spec-out\n  Scenario Outline: O\n    Given <x>\n    @smoke\n    Examples:\n      | x |\n      | 1 |\n\n  @spec-next\n  Scenario: N\n    Given n\n' > "$p/features/a.feature"
fp_in "$p" spec-out; BEFORE="$OUT"
sed -i '' 's/| 1 |/| 2 |/' "$p/features/a.feature"
fp_in "$p" spec-out
[ "$BEFORE" != "$OUT" ] && pass || fail "tagged Examples change must change the fingerprint"
fp_in "$p" spec-next
assert_equals 0 "$RC" "scenario after a tagged Examples block keeps its tag"

p=$(new_project)
printf 'Feature: A\n  @spec-doc\n  Scenario: D\n    Given text:\n      """\n      @spec-fake\n      Scenario: not real\n      """\n    Then ok\n' > "$p/features/a.feature"
fp_in "$p" spec-fake
assert_equals 1 "$RC" "tag inside a docstring is not a scenario tag"
fp_in "$p" spec-doc; BEFORE="$OUT"
sed -i '' 's/not real/still not real/' "$p/features/a.feature"
fp_in "$p" spec-doc
[ "$BEFORE" != "$OUT" ] && pass || fail "docstring content belongs to the scenario fingerprint"
OUT=$(cd "$p" && bash "$SCRIPT" check --features features --dir docs/decisions 2>&1)
lacks "spec-fake"
lacks "I-LEGACY"

finish
