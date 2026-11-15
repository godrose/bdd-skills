#!/bin/bash
# BDD examples guard. Subcommands: check, source-hash, scenario-hash.
# An examples file `X.examples.md` sits beside `X.feature`. Each example is a line that starts with its id, such as `E2.`.
# A scenario generated from an example carries @example-E2, @src-<hash> and @gen-<hash>.
# The checks are mechanical: the ids, the concrete values and two hashes. No model judges them.

usage() {
  echo "usage: examples.sh check [--features F]" >&2
  echo "       examples.sh source-hash EXAMPLES_FILE ID" >&2
  echo "       examples.sh scenario-hash FEATURE_FILE ID" >&2
  exit 2
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

FEATURES="${BDD_FEATURES_DIR:-}"
CMD="${1:-}"
[ -n "$CMD" ] && shift
ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --features) [ $# -ge 2 ] || usage; FEATURES="$2"; shift 2 ;;
    -*) usage ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

sha256_8() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256; else sha256sum; fi | cut -c1-8
}

# Examples of a file, one row each, tab separated: id, line number, text.
# The text is trimmed and its spaces are collapsed.
examples_of() {
  awk '{
    sub(/\r$/, "")
    if (match($0, /^E[0-9]+\.[ \t]+/)) {
      id = $0; sub(/\..*/, "", id)
      text = substr($0, RLENGTH + 1)
      gsub(/^[ \t]+|[ \t]+$/, "", text); gsub(/[ \t]+/, " ", text)
      printf "%s\t%d\t%s\n", id, NR, text
    }
  }' "$1"
}

# Scenarios of a feature file, one row each, tab separated: start line, end line, tags.
# Tags are the tag lines directly above the keyword line. Comments and blank lines in between are skipped.
scenarios_of() {
  awk '
    function flush(endline) {
      if (open) { printf "%d\t%d\t%s\n", start, endline, (stags == "" ? "-" : stags); open = 0 }
    }
    BEGIN { pending = ""; open = 0; indoc = 0; tagline = 0 }
    {
      line = $0
      sub(/\r$/, "", line)
      t = line
      gsub(/^[ \t]+|[ \t]+$/, "", t)
      if (t ~ /^("""|```)/) { indoc = !indoc; pending = ""; next }
      if (indoc) next
      if (t ~ /^@/) { if (pending == "") tagline = NR; pending = pending " " t; next }
      if (t ~ /^#/ || t == "") next
      endl = (pending != "") ? tagline - 1 : NR - 1
      if (t ~ /^(Scenario Outline|Scenario Template|Scenario|Example):/) {
        flush(endl)
        open = 1; start = NR; stags = pending; pending = ""
      } else if (t ~ /^Feature:/) {
        flush(endl); pending = ""
      } else if (t ~ /^(Rule|Background):/) {
        flush(endl); pending = ""
      } else {
        pending = ""
      }
    }
    END { flush(NR) }
  ' "$1"
}

# The text of a scenario from its keyword line to its end: no tags, comments or blank lines, spaces collapsed.
body_of() {
  sed -n "${2},${3}p" "$1" \
    | awk '{ sub(/\r$/, ""); gsub(/^[ \t]+|[ \t]+$/, ""); gsub(/[ \t]+/, " "); if ($0 != "" && $0 !~ /^[@#]/) print }'
}

# Prints "start<TAB>end<TAB>tags" of the first scenario of a feature file that carries @example-ID.
scenario_row() {
  scenarios_of "$1" | awk -F'\t' -v tag="@example-$2" '{ n = split($3, a, /[ \t]+/); for (i = 1; i <= n; i++) if (a[i] == tag) { print; exit } }'
}

tag_value() {
  # tag_value TAGS PREFIX: the hash after PREFIX in a tag, or nothing.
  local t
  for t in $1; do
    case "$t" in "$2"*) printf '%s' "${t#"$2"}"; return ;; esac
  done
}

cmd_source_hash() {
  [ ${#ARGS[@]} -eq 2 ] || usage
  [ -f "${ARGS[0]}" ] || { echo "examples file not found: ${ARGS[0]}" >&2; exit 1; }
  local text
  text=$(examples_of "${ARGS[0]}" | awk -F'\t' -v id="${ARGS[1]}" '$1 == id { print $3; exit }')
  [ -n "$text" ] || { echo "${ARGS[1]}: not found in ${ARGS[0]}" >&2; exit 1; }
  printf '%s' "$text" | sha256_8
}

cmd_scenario_hash() {
  [ ${#ARGS[@]} -eq 2 ] || usage
  [ -f "${ARGS[0]}" ] || { echo "feature file not found: ${ARGS[0]}" >&2; exit 1; }
  local row start end
  row=$(scenario_row "${ARGS[0]}" "${ARGS[1]}")
  [ -n "$row" ] || { echo "${ARGS[1]}: no scenario tagged @example-${ARGS[1]} in ${ARGS[0]}" >&2; exit 1; }
  IFS=$'\t' read -r start end _ <<< "$row"
  body_of "${ARGS[0]}" "$start" "$end" | sha256_8
}

# The id in the first @example- tag of a tag list, or nothing.
example_id_of() {
  local t
  for t in $1; do
    case "$t" in
      @example-*) printf '%s' "${t#@example-}"; return ;;
    esac
  done
}

ERRORS=0
finding() { echo "ERROR $1 $2 $3"; ERRORS=$((ERRORS + 1)); }

# Values of an example text, one per row: Q<TAB>quoted text, or N<TAB>number.
values_of() {
  awk '{
    t = $0
    while (match(t, /"[^"]*"/)) { print "Q\t" substr(t, RSTART + 1, RLENGTH - 2); t = substr(t, 1, RSTART - 1) " " substr(t, RSTART + RLENGTH) }
    while (match(t, /[0-9]+(\.[0-9]+)?/)) { print "N\t" substr(t, RSTART, RLENGTH); t = substr(t, RSTART + RLENGTH) }
  }'
}

check_values() {
  local feature="$1" start="$2" end="$3" id="$4" text="$5" body kind v pat
  body=$(body_of "$feature" "$start" "$end")
  while IFS=$'\t' read -r kind v; do
    [ -n "$v" ] || continue
    if [ "$kind" = "Q" ]; then
      v=$(printf '%s' "$v" | awk '{ gsub(/^[ \t]+|[ \t]+$/, ""); gsub(/[ \t]+/, " "); print }')
      printf '%s\n' "$body" | grep -qF -- "$v" || finding E-VALUE "$feature:$start" "$id value \"$v\" is missing from the scenario"
    else
      pat="(^|[^0-9.])${v//./\\.}(\$|[^0-9]|\\.(\$|[^0-9]))"
      printf '%s\n' "$body" | grep -Eq -- "$pat" || finding E-VALUE "$feature:$start" "$id value $v is missing from the scenario"
    fi
  done < <(printf '%s\n' "$text" | values_of)
}

check_file() {
  local ex="$1" feature ids id line text row start end tags src gen want seen=" "
  feature="${ex%.examples.md}.feature"
  if [ ! -f "$feature" ]; then
    finding E-NOFEATURE "$ex:1" "no feature file beside the examples file: $feature"
    return
  fi
  examples_of "$ex" > "$TMP/examples.tsv"
  scenarios_of "$feature" > "$TMP/scenarios.tsv"
  while IFS=$'\t' read -r id line text; do
    case "$seen" in *" $id "*) finding E-DUP "$ex:$line" "$id is used twice in the examples file"; continue ;; esac
    seen="$seen$id "
    row=$(scenario_row "$feature" "$id")
    if [ -z "$row" ]; then
      finding E-MISSING "$ex:$line" "$id has no scenario tagged @example-$id"
      continue
    fi
    IFS=$'\t' read -r start end tags <<< "$row"
    check_values "$feature" "$start" "$end" "$id" "$text"
    src=$(tag_value "$tags" "@src-")
    gen=$(tag_value "$tags" "@gen-")
    if [ -z "$src" ]; then
      finding E-NOHASH "$feature:$start" "$id has no @src- tag"
    elif [ "$src" != "$(printf '%s' "$text" | sha256_8)" ]; then
      finding E-SRC "$ex:$line" "$id changed after its scenario was generated"
    fi
    if [ -z "$gen" ]; then
      finding E-NOHASH "$feature:$start" "$id has no @gen- tag"
    elif [ "$gen" != "$(body_of "$feature" "$start" "$end" | sha256_8)" ]; then
      finding E-GEN "$feature:$start" "$id scenario was edited by hand, change the example instead"
    fi
  done < "$TMP/examples.tsv"
  # A generated scenario whose example is not in the file, and an id on two scenarios.
  local tagged=" "
  while IFS=$'\t' read -r start end tags; do
    id=$(example_id_of "$tags")
    [ -n "$id" ] || continue
    case "$tagged" in *" $id "*) finding E-DUP "$feature:$start" "$id is tagged on more than one scenario" ;; esac
    tagged="$tagged$id "
    awk -F'\t' -v id="$id" '$1 == id { f = 1 } END { exit !f }' "$TMP/examples.tsv" || finding E-ORPHAN "$feature:$start" "$id is tagged on a scenario and is not in $ex"
  done < "$TMP/scenarios.tsv"
}

cmd_check() {
  [ ${#ARGS[@]} -eq 0 ] || usage
  [ -n "$FEATURES" ] || { echo "--features (or BDD_FEATURES_DIR) is required" >&2; exit 2; }
  [ -d "$FEATURES" ] || { echo "features directory not found: $FEATURES" >&2; exit 2; }
  local f found=0
  while IFS= read -r f; do
    found=1
    check_file "$f"
  done < <(find "$FEATURES" -name '*.examples.md' | sort)
  [ "$found" -eq 1 ] || echo "INFO I-NONE no examples files under $FEATURES"
  echo "summary errors=$ERRORS"
  [ "$ERRORS" -eq 0 ]
}

case "$CMD" in
  check) cmd_check ;;
  source-hash) cmd_source_hash ;;
  scenario-hash) cmd_scenario_hash ;;
  *) usage ;;
esac
