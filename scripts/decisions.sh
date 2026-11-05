#!/bin/bash
# BDD decision log tooling. Subcommands: check.

if ! command -v jq >/dev/null 2>&1; then
  echo "decisions.sh needs jq. Install it, for example with: brew install jq" >&2
  exit 2
fi

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
SCHEMA="$SELF_DIR/../schemas/decision.schema.json"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

DIR="${BDD_DECISIONS_DIR:-docs/decisions}"
FEATURES="${BDD_FEATURES_DIR:-}"
PREFIX="${BDD_ID_PREFIX:-spec-}"
BASE=""
ARG=""
SCOPE="scenario"
PLANNED_TAG="@pending"
MANUAL_TAG="@manual-only"
BLOCKED_TAG=""
PLANNED_DIR=""
MANUAL_DIR=""
SINCE=""
CHANNEL=""

usage() {
  echo "usage: decisions.sh check [--dir D] [--features F] [--prefix P] [--base REF]" >&2
  echo "       decisions.sh fingerprint ID --features F" >&2
  echo "       decisions.sh status ID --features F [--scope scenario|feature|directory] [--planned-tag T] [--manual-only-tag T] [--blocked-tag T] [--planned-dir N] [--manual-only-dir N]" >&2
  echo "       decisions.sh show STORY [--dir D] [--features F] [--since REF] [--channel URL] (plus the status flags)" >&2
  exit 2
}

CMD="${1:-}"
[ -n "$CMD" ] && shift
while [ $# -gt 0 ]; do
  case "$1" in
    --dir) [ $# -ge 2 ] || usage; DIR="$2"; shift 2 ;;
    --features) [ $# -ge 2 ] || usage; FEATURES="$2"; shift 2 ;;
    --prefix) [ $# -ge 2 ] || usage; PREFIX="$2"; shift 2 ;;
    --base) [ $# -ge 2 ] || usage; BASE="$2"; shift 2 ;;
    --scope) [ $# -ge 2 ] || usage; SCOPE="$2"; shift 2 ;;
    --planned-tag) [ $# -ge 2 ] || usage; PLANNED_TAG="$2"; shift 2 ;;
    --manual-only-tag) [ $# -ge 2 ] || usage; MANUAL_TAG="$2"; shift 2 ;;
    --blocked-tag) [ $# -ge 2 ] || usage; BLOCKED_TAG="$2"; shift 2 ;;
    --planned-dir) [ $# -ge 2 ] || usage; PLANNED_DIR="$2"; shift 2 ;;
    --manual-only-dir) [ $# -ge 2 ] || usage; MANUAL_DIR="$2"; shift 2 ;;
    --since) [ $# -ge 2 ] || usage; SINCE="$2"; shift 2 ;;
    --channel) [ $# -ge 2 ] || usage; CHANNEL="$2"; shift 2 ;;
    -*) usage ;;
    *) [ -z "$ARG" ] || usage; ARG="$1"; shift ;;
  esac
done

# Every record from DIR/*.jsonl as [{file, line, raw, rec}] in $TMP/records.json.
# rec is null when the line is not valid JSON. Blank lines are skipped.
load_records() {
  local files=() f
  for f in "$DIR"/*.jsonl; do
    [ -f "$f" ] && files+=("$f")
  done
  if [ ${#files[@]} -eq 0 ]; then
    echo '[]' > "$TMP/records.json"
    return
  fi
  jq -nRc '
    [inputs | {file: input_filename, raw: sub("\r$"; "")}]
    | group_by(.file)
    | map(. as $g | [range(0; ($g | length))]
          | map({file: $g[.].file, line: (. + 1), raw: $g[.].raw}))
    | add // []
    | map(select(.raw | test("^\\s*$") | not))
    | map(. + {rec: (try (.raw | fromjson) catch null)})
  ' "${files[@]}" > "$TMP/records.json"
}

CHECK_PROG=$(cat <<'EOF'
def arr($v): if ($v | type) == "array" then $v else [] end;
def msg($lvl; $code; $r; $m): "\($lvl) \($code) \($r.file):\($r.line) \($m)";

. as $all
| $schema[0] as $S
| ($all | map(select((.rec | type) == "object" and (.rec.id | type) == "string") | .rec.id)) as $ids
| ($ids | map({(.): true}) | add // {}) as $idset
| (
    ( $all[]
      | . as $r
      | if ($r.rec | type) != "object" then
          msg("ERROR"; "E-JSON"; $r; "line is not a valid JSON object")
        else
          $r.rec as $x
          | ($r.file | split("/") | last | sub("\\.jsonl$"; "")) as $base
          | (
              ( if $x.v != null and (($S.supported_versions | map(. == $x.v) | any) | not)
                then msg("ERROR"; "E-VERSION"; $r; "record version \($x.v) is not supported; update the skills")
                else empty end ),
              ( if $S.kinds[($x.kind | tostring)] == null
                then msg("ERROR"; "E-SCHEMA"; $r; "unknown kind \($x.kind)")
                else ( $S.kinds[($x.kind | tostring)].required[] | . as $k | select($x[$k] == null)
                       | msg("ERROR"; "E-SCHEMA"; $r; "missing field \($k)") )
                end ),
              ( if ($x.id | type) == "string" and (($x.id | startswith($base + "-")) | not)
                then msg("ERROR"; "E-SCHEMA"; $r; "id \($x.id) must start with \($base)-")
                else empty end ),
              ( ["effects", "sources", "supersedes", "resolves", "decided_by"][] | . as $f
                | select($x[$f] != null and ($x[$f] | type) != "array")
                | msg("ERROR"; "E-SCHEMA"; $r; "\($f) must be a list") ),
              ( arr($x.effects)[] | . as $e
                | if ($e | type) != "object" then
                    msg("ERROR"; "E-SCHEMA"; $r; "effect must be an object")
                  else
                    ( if ($S.enums.effect_op | map(. == $e.op) | any) | not
                      then msg("ERROR"; "E-SCHEMA"; $r; "unknown effect op \($e.op)")
                      else ( $S.effect_required[$e.op][] | . as $k | select($e[$k] == null)
                             | msg("ERROR"; "E-SCHEMA"; $r; "effect \($e.op) is missing \($k)") )
                      end ),
                    ( if ($e.scenario | type) == "string"
                         and ((($e.scenario | startswith($prefix))
                               and ($e.scenario[($prefix | length):] | test("^[a-z0-9-]+$"))) | not)
                      then msg("ERROR"; "E-SCHEMA"; $r; "scenario id \($e.scenario) must be \($prefix) followed by lowercase letters, digits and hyphens")
                      else empty end )
                  end ),
              ( arr($x.sources)[] | . as $s
                | if ($s | type) != "object" then
                    msg("ERROR"; "E-SCHEMA"; $r; "source must be an object")
                  else
                    ( if $s.kind != null and (($S.enums.source_kind | map(. == $s.kind) | any) | not)
                      then msg("ERROR"; "E-SCHEMA"; $r; "unknown source kind \($s.kind)") else empty end ),
                    ( if $s.role != null and (($S.enums.source_role | map(. == $s.role) | any) | not)
                      then msg("ERROR"; "E-SCHEMA"; $r; "unknown source role \($s.role)") else empty end )
                  end ),
              ( [ (arr($x.supersedes)[] | {k: "supersedes", v: .}),
                  (arr($x.resolves)[] | {k: "resolves", v: .}),
                  (if $x.of != null then {k: "of", v: $x.of} else empty end) ][]
                | select(($idset[(.v | tostring)]) | not)
                | msg("ERROR"; "E-REF"; $r; "\(.k) names unknown id \(.v)") )
            )
        end
    ),
    ( foreach ($all[] | select((.rec | type) == "object" and (.rec.id | type) == "string")) as $r
        ({seen: {}, hit: null};
         if .seen[$r.rec.id] then .hit = $r else (.seen[$r.rec.id] = true | .hit = null) end;
         .hit | select(. != null) | msg("ERROR"; "E-DUP-ID"; .; "duplicate id \(.rec.id)"))
    )
  )
EOF
)

require_base() {
  git rev-parse --git-dir >/dev/null 2>&1 || { echo "--base needs a git repository" >&2; exit 2; }
  git rev-parse --verify --quiet "$BASE^{commit}" >/dev/null || { echo "unknown ref for --base: $BASE" >&2; exit 2; }
}

# Lines of a file without CR, each ending in a newline.
normalized() { awk '{ sub(/\r$/, ""); print }' "$1"; }

# Each log file at BASE must be an exact line prefix of the working-tree file.
check_append() {
  local f bn wn first
  while IFS= read -r f; do
    case "$f" in *.jsonl) ;; *) continue ;; esac
    git show "$BASE:./$f" > "$TMP/base.raw" 2>/dev/null || continue
    normalized "$TMP/base.raw" > "$TMP/base.n"
    if [ ! -f "$f" ]; then
      echo "ERROR E-APPEND $f:1 log file was deleted since $BASE"
      continue
    fi
    normalized "$f" > "$TMP/work.n"
    bn=$(wc -l < "$TMP/base.n" | tr -d ' ')
    wn=$(wc -l < "$TMP/work.n" | tr -d ' ')
    if [ "$wn" -lt "$bn" ] || ! head -n "$bn" "$TMP/work.n" | cmp -s - "$TMP/base.n"; then
      first=$(awk 'NR == FNR { b[NR] = $0; next } FNR <= length(b) && $0 != b[FNR] { print FNR; exit }' "$TMP/base.n" "$TMP/work.n")
      [ -z "$first" ] && first=$((wn + 1))
      echo "ERROR E-APPEND $f:$first records on $BASE were changed or removed; add a new record instead"
    fi
  done < <(git ls-tree -r --name-only "$BASE" -- "$DIR")
}

cmd_check() {
  [ -n "$BASE" ] && require_base
  load_records
  jq -r --slurpfile schema "$SCHEMA" --arg prefix "$PREFIX" "$CHECK_PROG" "$TMP/records.json" > "$TMP/findings"
  [ -n "$BASE" ] && check_append >> "$TMP/findings"
  reconcile >> "$TMP/findings"
  if [ "$(jq 'length' "$TMP/records.json")" = "0" ]; then
    echo "INFO I-EMPTY no decision records" >> "$TMP/findings"
  fi
  cat "$TMP/findings"
  local errors warnings
  errors=$(grep -c '^ERROR' "$TMP/findings")
  warnings=$(grep -c '^WARN' "$TMP/findings")
  echo "summary errors=$errors warnings=$warnings"
  [ "$errors" -eq 0 ]
}

require_features() {
  [ -n "$FEATURES" ] || { echo "--features (or BDD_FEATURES_DIR) is required" >&2; exit 2; }
  [ -d "$FEATURES" ] || { echo "features directory not found: $FEATURES" >&2; exit 2; }
}

# One row per scenario in $TMP/scenarios.tsv, tab separated:
# file, start line, end line, name, scenario tags, feature tags.
# Tags are the tag lines, comment lines and blank lines directly above a keyword line.
scan_scenarios() {
  [ -f "$TMP/scenarios.tsv" ] && return
  : > "$TMP/scenarios.tsv"
  local f
  while IFS= read -r f; do
    awk -v file="$f" '
      function flush(endline) {
        if (open) { printf "%s\t%d\t%d\t%s\t%s\t%s\n", file, start, endline, name, stags, ftags; open = 0 }
      }
      BEGIN { pending = ""; ftags = ""; open = 0; indoc = 0; tagline = 0 }
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
          open = 1; start = NR; name = t; stags = pending; pending = ""
        } else if (t ~ /^Feature:/) {
          flush(endl); ftags = pending; pending = ""
        } else if (t ~ /^(Rule|Background):/) {
          flush(endl); pending = ""
        } else if (t ~ /^(Examples|Scenarios):/) {
          pending = ""
        } else {
          pending = ""
        }
      }
      END { flush(NR) }
    ' "$f" | sed 's/\t\t/\t-\t/g; s/\t$/\t-/' >> "$TMP/scenarios.tsv"
  done < <(find "$FEATURES" -name '*.feature' | sort)
}

sha256_8() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256; else sha256sum; fi | cut -c1-8
}

block_fp() {
  sed -n "${2},${3}p" "$1" \
    | awk '{ sub(/\r$/, ""); gsub(/^[ \t]+|[ \t]+$/, ""); gsub(/[ \t]+/, " "); if ($0 != "" && $0 !~ /^[@#]/) print }' \
    | sha256_8
}

cmd_fingerprint() {
  [ -n "$ARG" ] || usage
  require_features
  scan_scenarios
  local id="${ARG#@}" rows count file start end
  rows=$(awk -F'\t' -v id="@$id" '{ n = split($5, a, /[ \t]+/); for (i = 1; i <= n; i++) if (a[i] == id) { print; break } }' "$TMP/scenarios.tsv")
  if [ -z "$rows" ]; then
    echo "scenario $id: not found under $FEATURES" >&2
    exit 1
  fi
  count=$(printf '%s\n' "$rows" | wc -l | tr -d ' ')
  if [ "$count" -gt 1 ]; then
    echo "scenario $id: ambiguous, it tags $count scenarios" >&2
    exit 1
  fi
  IFS=$'\t' read -r file start end _ <<< "$rows"
  block_fp "$file" "$start" "$end"
}

# Prints automated, planned, manual-only or blocked for a scenario id. Returns 1 when absent.
status_of() {
  local id="${1#@}" row file stags ftags tags dir comp
  scan_scenarios
  row=$(awk -F"\t" -v id="@$id" '{ n = split($5, a, /[ \t]+/); for (i = 1; i <= n; i++) if (a[i] == id) { print; exit } }' "$TMP/scenarios.tsv")
  [ -n "$row" ] || return 1
  IFS=$'\t' read -r file _ _ _ stags ftags <<< "$row"
  case "$SCOPE" in
    scenario) tags="$stags" ;;
    feature) tags="$ftags" ;;
    directory) tags="" ;;
    *) echo "unknown --scope $SCOPE" >&2; exit 2 ;;
  esac
  local is_manual=0 is_blocked=0 is_planned=0 t
  for t in $tags; do
    [ "$t" = "$MANUAL_TAG" ] && is_manual=1
    [ -n "$BLOCKED_TAG" ] && [ "$t" = "$BLOCKED_TAG" ] && is_blocked=1
    [ "$t" = "$PLANNED_TAG" ] && is_planned=1
  done
  if [ "$SCOPE" = directory ]; then
    dir=$(dirname "${file#$FEATURES/}")
    local IFS=/
    for comp in $dir; do
      [ -n "$MANUAL_DIR" ] && [ "$comp" = "$MANUAL_DIR" ] && is_manual=1
      [ -n "$PLANNED_DIR" ] && [ "$comp" = "$PLANNED_DIR" ] && is_planned=1
    done
  fi
  if [ $is_manual = 1 ]; then echo manual-only
  elif [ $is_blocked = 1 ]; then echo blocked
  elif [ $is_planned = 1 ]; then echo planned
  else echo automated; fi
}

cmd_status() {
  [ -n "$ARG" ] || usage
  require_features
  if ! status_of "$ARG"; then
    echo "scenario ${ARG#@}: not found under $FEATURES" >&2
    exit 1
  fi
}

# Spec-tagged scenarios as [{id, file, line, fp}] in $TMP/present.json.
build_present() {
  scan_scenarios
  : > "$TMP/present.tsv"
  local file start end name tags ftags tok fp
  while IFS=$'\t' read -r file start end name tags ftags; do
    case " $tags " in *" @$PREFIX"*) ;; *) continue ;; esac
    fp=$(block_fp "$file" "$start" "$end")
    for tok in $tags; do
      case "$tok" in
        "@$PREFIX"*) printf '%s\t%s\t%s\t%s\n' "${tok#@}" "$file" "$start" "$fp" >> "$TMP/present.tsv" ;;
      esac
    done
  done < "$TMP/scenarios.tsv"
  jq -Rn '[inputs | split("\t") | {id: .[0], file: .[1], line: (.[2] | tonumber), fp: .[3]}]' "$TMP/present.tsv" > "$TMP/present.json"
}

# With --base: which scenario ids and record ids this change touches.
# $TMP/scope.json is {touched: [...] or null, newids: [...]}. null means everything.
compute_scope() {
  if [ -z "$BASE" ]; then
    echo '{"touched":null,"newids":[]}' > "$TMP/scope.json"
    return
  fi
  local f
  : > "$TMP/base_ids.txt"
  while IFS= read -r f; do
    case "$f" in
      *.jsonl) git show "$BASE:./$f" | tr -d '\r' | jq -R -r 'try (fromjson | .id // empty) catch empty' >> "$TMP/base_ids.txt" ;;
    esac
  done < <(git ls-tree -r --name-only "$BASE" -- "$DIR")
  : > "$TMP/changed_features.txt"
  : > "$TMP/base_spec_ids.txt"
  if [ -n "$FEATURES" ]; then
    { git diff --name-only --relative "$BASE" -- "$FEATURES"; git ls-files --others --exclude-standard -- "$FEATURES"; } \
      | sed 's|^\./||' > "$TMP/changed_features.txt"
    git grep -h -o -E "@${PREFIX}[a-z0-9-]+" "$BASE" -- "$FEATURES" 2>/dev/null | sed 's/^@//' | sort -u > "$TMP/base_spec_ids.txt"
  fi
  jq -n --rawfile baseids "$TMP/base_ids.txt" --rawfile changed "$TMP/changed_features.txt" \
    --rawfile basespec "$TMP/base_spec_ids.txt" --slurpfile recs "$TMP/records.json" --slurpfile present "$TMP/present.json" '
    ($baseids | split("\n") | map(select(length > 0))) as $b
    | ($recs[0] | map(select((.rec | type) == "object" and (.rec.id | type) == "string"))) as $all
    | [$all[] | select(.rec.id as $i | (any($b[]; . == $i) | not))] as $new
    | ($new | map(.rec.effects // [] | if type == "array" then .[] else empty end
                  | select(type == "object") | .scenario | select(type == "string"))) as $a
    | ($changed | split("\n") | map(select(length > 0))) as $cf
    | ($present[0] | map(select(.file as $f | any($cf[]; . == ($f | sub("^\\./"; "")))) | .id)) as $bb
    | ($present[0] | map(.id)) as $pids
    | ($basespec | split("\n") | map(select(length > 0 and (. as $s | (any($pids[]; . == $s) | not))))) as $cc
    | {touched: ($a + $bb + $cc | unique), newids: ($new | map(.rec.id))}
  ' > "$TMP/scope.json"
}

STATE_PROG=$(cat <<'EOF'
def arr($v): if ($v | type) == "array" then $v else [] end;
def msg($lvl; $code; $file; $line; $m): "\($lvl) \($code) \($file):\($line) \($m)";

(map(select((.rec | type) == "object" and (.rec.id | type) == "string" and (.rec.kind | type) == "string"))
 | sort_by([(.rec.at // ""), .file, .line])
 | to_entries | map(.value + {ord: .key})) as $recs
| ($recs | map(select(.rec.kind == "decision"))) as $decs
| ($decs | map(arr(.rec.supersedes)[]) | map({(tostring): true}) | add // {}) as $superseded
| ($decs | map(. as $d | arr($d.rec.effects)[] | select(type == "object")
     | {op, scenario, fp, ord: $d.ord, id: $d.rec.id, file: $d.file, line: $d.line})) as $effs
| def removed($s; $o): any($effs[]; .op == "removes" and .scenario == $s and .ord > $o);
  def scen_op: (.op | IN("adds", "changes", "rewords"));
  ($decs | map(. as $d
     | select(($superseded[$d.rec.id] // false) | not)
     | select(
         ([arr($d.rec.effects)[] | select(type == "object")] | length) == 0
         or any(arr($d.rec.effects)[] | select(type == "object");
                if scen_op then (removed(.scenario; $d.ord) | not) else true end)))) as $live
| ($live | map(. as $d | arr($d.rec.effects)[] | select(type == "object")
     | select(scen_op and (.scenario | type) == "string")
     | select(removed(.scenario; $d.ord) | not)
     | {scenario, id: $d.rec.id, file: $d.file, line: $d.line})) as $liveeff
EOF
)

RECON_TAIL=$(cat <<'EOF'
| $present[0] as $P
| ($P | map({(.id): true}) | add // {}) as $pset
| def in_scope($s): ($scope[0].touched == null) or any($scope[0].touched[]; . == $s);
  (
    ( if $have then
        ($liveeff[] | select($pset[.scenario] | not) | select(in_scope(.scenario))
         | msg("ERROR"; "E-ORPHAN"; .file; .line; "scenario \(.scenario) (decision \(.id)) is not in \($features); restore it or record a removes decision"))
      else empty end ),
    ( if $have then
        ($P | group_by(.id)[] | select(length > 1) | .[1:][]
         | msg("ERROR"; "E-DUP-SCENARIO"; .file; .line; "spec id \(.id) tags more than one scenario"))
      else empty end ),
    ( if $have then
        ($P | group_by(.id)[] | select(length == 1) | .[0] as $p
         | select(in_scope($p.id))
         | (any($liveeff[]; .scenario == $p.id)) as $decided
         | if $decided then
             ([$effs[] | select(scen_op and .scenario == $p.id)] | max_by(.ord)) as $last
             | if $last.fp != $p.fp
               then msg("WARN"; "W-DRIFT"; $p.file; $p.line; "scenario \($p.id) changed since decision \($last.id); record rewords or changes")
               else empty end
           else msg("WARN"; "W-UNDECIDED"; $p.file; $p.line; "scenario \($p.id) has no live decision") end)
      else empty end ),
    ( $live | map(. as $d | arr($d.rec.supersedes)[] | {x: ., d: $d}) | group_by(.x)[] | select(length > 1)
      | . as $g | $g[1:][] | . as $o
      | select(($scope[0].touched == null)
               or any($g[0], $o; . as $q | any($scope[0].newids[]; . == $q.d.rec.id)))
      | msg("WARN"; "W-CONFLICT"; $o.d.file; $o.d.line; "decisions \($g[0].d.rec.id) and \($o.d.rec.id) both supersede \($g[0].x)") )
  )
EOF
)

reconcile() {
  local have=false
  if [ -n "$FEATURES" ] && [ -d "$FEATURES" ]; then
    have=true
    build_present
  else
    echo '[]' > "$TMP/present.json"
  fi
  compute_scope
  jq -r --slurpfile present "$TMP/present.json" --slurpfile scope "$TMP/scope.json" \
    --argjson have "$have" --arg features "$FEATURES" "$STATE_PROG
$RECON_TAIL" "$TMP/records.json"
  if [ "$have" = true ]; then
    local legacy
    legacy=$(awk -F'\t' -v p="@$PREFIX" '{ n = split($5, a, /[ \t]+/); has = 0; for (i = 1; i <= n; i++) if (index(a[i], p) == 1) has = 1; if (!has) c++ } END { print c + 0 }' "$TMP/scenarios.tsv")
    [ "$legacy" -gt 0 ] && echo "INFO I-LEGACY $legacy scenarios have no spec tag (not tracked)"
  fi
  return 0
}

SHOW_TAIL=$(cat <<'JQ'
| def mine: select(.rec.story == $story);
  def txt: (.rec.text // "" | tostring | gsub("\\s*\\n\\s*"; " "));
  def srcs($id): (([$recs[] | select(.rec.id == $id) | arr(.rec.sources)] + [$recs[] | select(.rec.kind == "confirms" and .rec.of == $id) | arr(.rec.sources)]) | add // []) | map(select(type == "object"));
  def link($id): srcs($id) as $s
    | (($s | map(select(.role == "agreed")) | .[0]) // $s[0]) as $x
    | if ($x | type) == "object" and ($x.ref | type) == "string" then (if ($x.ref | test("^https?://")) then " ([source](\($x.ref)))" else " (source: \($x.ref))" end) else "" end;
  def sec($h; $lines): if ($lines | length) == 0 then empty else "", $h, "", $lines[] end;
  def words($id): ([$liveeff[] | select(.id == $id) | $status[0][.scenario] // empty]) as $w
    | ["automated", "planned", "checked by hand", "waiting on the product"] | map(select(. as $o | any($w[]; . == $o)));
  def tag($id): words($id) | if length == 0 then "" else " (\(join(", ")))" end;
  ($live | map(mine)) as $lm
| ($lm | map(select(. as $d | any($liveeff[]; .id == $d.rec.id)))) as $agreed
| ($lm | map(select(. as $d | any($agreed[]; .rec.id == $d.rec.id) | not))) as $left
| ([$recs[] | select(.rec.resolves | type == "string") | .rec.resolves]) as $resolved
| ($recs | map(select(.rec.kind == "open" and .rec.story == $story and (.rec.id as $i | any($resolved[]; . == $i) | not)))) as $open
| ($decs | map(mine)) as $mine
| ($mine | map(select($superseded[.rec.id] // false))) as $replaced
| ($mine | map(select((($superseded[.rec.id] // false) | not) and (. as $d | any($live[]; .rec.id == $d.rec.id) | not)))) as $closed
| ($recs | map(select(.rec.kind == "open" and .rec.story == $story and (.rec.id as $i | any($resolved[]; . == $i))))) as $closedopen
| ($mine | map(select(.rec.id as $i | any($baseids[]; . == $i) | not))) as $new
| (
    ( if $hassince then
        sec("## Changed since you last looked";
          [$new[] | . as $d
           | if (arr($d.rec.supersedes) | length) > 0 then
               "- Changed: \($d | txt)" + ([$recs[] | select(.rec.id == arr($d.rec.supersedes)[0]) | txt] | if length > 0 then " (was: \(.[0]))" else "" end)
             elif any(arr($d.rec.effects)[]; type == "object" and .op == "removes") then "- Removed: \($d | txt)"
             elif any(arr($d.rec.effects)[]; type == "object" and .op == "excludes") then "- Left out: \($d | txt)"
             elif any(arr($d.rec.effects)[]; type == "object" and .op == "defers") then "- Postponed: \($d | txt)"
             else "- Added: \($d | txt)" end])
      else empty end ),
    "", "## What we agreed", "",
    ( if ($agreed | length) == 0 then "- Nothing agreed yet."
      else ($agreed[] | "- \(txt)\(tag(.rec.id))\(link(.rec.id))") end ),
    sec("## Left out, postponed or accepted"; [$left[] | "- \(txt)\(link(.rec.id))"]),
    sec("## Still open"; [$open[] | "- \(txt)\(link(.rec.id))"]),
    sec("## History";
      [ $replaced[] | . as $d | "- \(txt) (replaced on \([$decs[] | select(arr(.rec.supersedes) | any(. == $d.rec.id))] | .[0].rec.at))" ]
      + [ $closed[] | "- \(txt) (closed)" ]
      + [ $closedopen[] | "- \(txt) (closed)" ])
  )
JQ
)

# ids of records present at REF, one per line.
ids_at() {
  local ref="$1" f
  while IFS= read -r f; do
    case "$f" in
      *.jsonl) git show "$ref:./$f" | tr -d '\r' | jq -R -r 'try (fromjson | .id // empty) catch empty' ;;
    esac
  done < <(git ls-tree -r --name-only "$ref" -- "$DIR")
}

cmd_show() {
  [ -n "$ARG" ] || usage
  load_records
  local n
  n=$(jq --arg s "$ARG" '[.[] | select(.rec | type == "object") | select(.rec.story == $s)] | length' "$TMP/records.json")
  if [ "$n" = "0" ]; then
    echo "No decisions recorded for $ARG"
    return 0
  fi
  : > "$TMP/status.tsv"
  if [ -n "$FEATURES" ] && [ -d "$FEATURES" ]; then
    local sid st word
    for sid in $(jq -r '[.[].rec | objects | .effects | arrays[] | objects | .scenario | strings] | unique[]' "$TMP/records.json"); do
      st=$(status_of "$sid") || continue
      case "$st" in
        automated) word="automated" ;;
        planned) word="planned" ;;
        manual-only) word="checked by hand" ;;
        blocked) word="waiting on the product" ;;
      esac
      printf '%s\t%s\n' "$sid" "$word" >> "$TMP/status.tsv"
    done
  fi
  jq -Rn '[inputs | split("\t") | {(.[0]): .[1]}] | add // {}' "$TMP/status.tsv" > "$TMP/status.json"
  echo '{"touched":null,"newids":[]}' > "$TMP/scope.json"
  echo '[]' > "$TMP/present.json"
  : > "$TMP/since_ids.txt"
  local hassince=false
  if [ -n "$SINCE" ]; then
    hassince=true
    ids_at "$SINCE" > "$TMP/since_ids.txt"
  fi
  printf '# Agreed behavior: %s\n\n' "$ARG"
  if git rev-parse --verify -q HEAD >/dev/null 2>&1; then
    local sha date dirty=""
    sha=$(git rev-parse --short HEAD)
    date=$(git log -1 --format=%cs)
    [ -n "$(git status --porcelain)" ] && dirty=" (uncommitted changes)"
    echo "> Generated from git at commit $sha ($date)$dirty. Read-only: do not discuss here."
  else
    echo "> Generated from files, not in a git repository. Read-only: do not discuss here."
  fi
  [ -n "$CHANNEL" ] && echo "> Discussion: $CHANNEL"
  jq -r --arg story "$ARG" --argjson hassince "$hassince" \
    --slurpfile status "$TMP/status.json" --slurpfile present "$TMP/present.json" --slurpfile scope "$TMP/scope.json" \
    --rawfile sinceraw "$TMP/since_ids.txt" \
    "def baseids_: (\$sinceraw | split(\"\\n\") | map(select(length > 0)));
     baseids_ as \$baseids
     | $STATE_PROG
     $SHOW_TAIL" "$TMP/records.json"
}

case "$CMD" in
  check) cmd_check ;;
  fingerprint) cmd_fingerprint ;;
  status) cmd_status ;;
  show) cmd_show ;;
  *) usage ;;
esac
