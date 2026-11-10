#!/bin/bash
# Run /bdd:discover on a fixture project as a whole conversation, with a small model playing the product manager.
# Counts the rules on the transcript. Gives counts and breaks, no verdict. Run it by hand: it starts real sessions.
#
# Usage: flows/run.sh --fixture a|b [--runs 3] [--turns 12] [--persona pm|founder] [--out DIR]
# Set CLAUDE_BIN to use a different claude binary.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLOWS="$ROOT/flows"
CLAUDE="${CLAUDE_BIN:-claude}"
TURNS=12; RUNS=3; FIXTURE=""; PERSONA=""; OUT=""

while [ $# -gt 0 ]; do
  case "$1" in
    --fixture) FIXTURE="$2"; shift 2 ;;
    --runs) RUNS="$2"; shift 2 ;;
    --turns) TURNS="$2"; shift 2 ;;
    --persona) PERSONA="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

command -v "$CLAUDE" > /dev/null 2>&1 || { echo "claude was not found on the path. Install it, or set CLAUDE_BIN." >&2; exit 1; }
[ -d "$FLOWS/fixtures/$FIXTURE/project" ] || { echo "no such fixture: '$FIXTURE'. Use a or b." >&2; exit 2; }
FX="$FLOWS/fixtures/$FIXTURE"
[ -n "$PERSONA" ] || PERSONA="$(cat "$FX/persona.txt")"
[ -f "$FLOWS/personas/$PERSONA.md" ] || { echo "no such persona: $PERSONA" >&2; exit 2; }
[ -n "$OUT" ] || OUT="$FLOWS/results/$(date +%Y%m%dT%H%M%S)"
BASE="$OUT/$FIXTURE"
mkdir -p "$BASE"

manifest() { (cd "$1" && find . -type f ! -path './docs/discovery/*' -print0 | sort -z | xargs -0 shasum -a 1 2>/dev/null); }
final_message() { grep -qiE '^[#* ]*readiness' "$1" && grep -qiE '\b(not ready|ready)\b' "$1"; }

for i in $(seq 1 "$RUNS"); do
  rd="$BASE/run-$i"; proj="$rd/project"
  mkdir -p "$rd"; cp -R "$FX/project" "$proj"
  sid=$(uuidgen | tr 'A-Z' 'a-z'); story=$(cat "$FX/story.txt")
  start=$(date +%s); cost=0; turns=0; finished=false; reply=""
  for t in $(seq 1 "$TURNS"); do
    tt=$(printf '%02d' "$t")
    if [ "$t" -eq 1 ]; then
      out=$(cd "$proj" && "$CLAUDE" -p "/bdd:discover $story" --plugin-dir "$ROOT/plugin" --allowedTools Read Grep Glob LS Write Edit --output-format json --session-id "$sid" 2> "$rd/stderr-$tt.txt")
    else
      out=$(cd "$proj" && "$CLAUDE" -p "$reply" --plugin-dir "$ROOT/plugin" --allowedTools Read Grep Glob LS Write Edit --output-format json --resume "$sid" 2> "$rd/stderr-$tt.txt")
    fi
    msg=$(printf '%s' "$out" | jq -r '.result // empty' 2> /dev/null)
    [ -n "$msg" ] || { echo "run $i, turn $t: no answer from claude (see $rd/stderr-$tt.txt)" >&2; break; }
    printf '%s\n' "$msg" > "$rd/turn-$tt-assistant.txt"
    cost=$(printf '%s %s' "$cost" "$(printf '%s' "$out" | jq -r '.total_cost_usd // 0')" | awk '{print $1 + $2}')
    turns=$t
    if final_message "$rd/turn-$tt-assistant.txt"; then finished=true; break; fi
    [ "$t" -lt "$TURNS" ] || break
    { cat "$FLOWS/personas/$PERSONA.md"; printf '\nThe assistant just said:\n\n%s\n\nReply as this person, briefly.\n' "$msg"; } > "$rd/pm-prompt-$tt.txt"
    pout=$("$CLAUDE" -p --model haiku --output-format json < "$rd/pm-prompt-$tt.txt" 2> "$rd/pm-stderr-$tt.txt")
    reply=$(printf '%s' "$pout" | jq -r '.result // empty' 2> /dev/null)
    [ -n "$reply" ] || { echo "run $i, turn $t: no reply from the product manager model" >&2; break; }
    printf '%s\n' "$reply" > "$rd/turn-$tt-pm.txt"
    cost=$(printf '%s %s' "$cost" "$(printf '%s' "$pout" | jq -r '.total_cost_usd // 0')" | awk '{print $1 + $2}')
  done
  end=$(date +%s)
  jq -n --argjson turns "$turns" --argjson finished "$finished" --argjson seconds "$((end - start))" --argjson cost "$cost" \
    '{turns: $turns, finished: $finished, seconds: $seconds, cost_usd: $cost}' > "$rd/meta.json"
  diff <(manifest "$FX/project") <(manifest "$proj") | grep '^[<>]' | awk '{print $3}' | sed 's|^\./||' | sort -u > "$rd/project-diff.txt"
  perl "$FLOWS/rules.pl" "$rd" > "$rd/rules.tsv"
done

perl "$FLOWS/report.pl" "$BASE" "$FIXTURE" "$RUNS" "$TURNS" > "$BASE/report.md"
echo "Report: $BASE/report.md"
