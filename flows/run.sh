#!/bin/bash
# Run /bdd:discover or /bdd:deliver on a fixture project as a whole conversation, with a small model playing the product manager.
# Counts the rules on the transcript. Gives counts and breaks, no verdict. Run it by hand: it starts real sessions.
#
# Usage: flows/run.sh --fixture a|b|c|d [--command discover|deliver] [--story N] [--runs 3] [--turns N] [--persona NAME] [--out DIR]
#        flows/run.sh --compare REPORT REPORT
# Set CLAUDE_BIN or NPM_BIN to use a different binary. FLOWS_CACHE moves the installed-runner cache.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLOWS="$ROOT/flows"
CLAUDE="${CLAUDE_BIN:-claude}"
NPM="${NPM_BIN:-npm}"
CACHE="${FLOWS_CACHE:-$FLOWS/results/cache}"
COMMAND=discover; TURNS=""; RUNS=3; FIXTURE=""; PERSONA=""; OUT=""; STORY=""

if [ "$1" = "--compare" ]; then
  [ -f "$2" ] && [ -f "$3" ] || { echo "usage: flows/run.sh --compare REPORT REPORT (both must exist)" >&2; exit 2; }
  exec perl "$FLOWS/compare.pl" "$2" "$3"
fi

while [ $# -gt 0 ]; do
  case "$1" in
    --fixture) FIXTURE="$2"; shift 2 ;;
    --command) COMMAND="$2"; shift 2 ;;
    --story) STORY="$2"; shift 2 ;;
    --runs) RUNS="$2"; shift 2 ;;
    --turns) TURNS="$2"; shift 2 ;;
    --persona) PERSONA="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

case "$COMMAND" in discover|deliver) ;; *) echo "no such command: '$COMMAND'. Use discover or deliver." >&2; exit 2 ;; esac
[ -n "$TURNS" ] || { [ "$COMMAND" = deliver ] && TURNS=30 || TURNS=12; }
TOOLS=(Read Grep Glob LS Write Edit)
[ "$COMMAND" = deliver ] && TOOLS+=("Bash(npm test)" "Bash(node src/show.js)" "Bash(node src/show.js data/*)")

command -v "$CLAUDE" > /dev/null 2>&1 || { echo "claude was not found on the path. Install it, or set CLAUDE_BIN." >&2; exit 1; }
[ -d "$FLOWS/fixtures/$FIXTURE/project" ] || { echo "no such fixture: '$FIXTURE'. Use a, b, c or d." >&2; exit 2; }
FX="$FLOWS/fixtures/$FIXTURE"
if [ -n "$STORY" ]; then STORYFILE="$FX/story-$STORY.txt"; else STORYFILE="$FX/story.txt"; fi
[ -f "$STORYFILE" ] || { echo "no such story file: $STORYFILE" >&2; exit 2; }
[ -n "$PERSONA" ] || PERSONA="$(tr -d '\r' < "$FX/persona.txt")"
[ -f "$FLOWS/personas/$PERSONA.md" ] || { echo "no such persona: $PERSONA" >&2; exit 2; }
[ -n "$OUT" ] || OUT="$FLOWS/results/$(date +%Y%m%dT%H%M%S)"
BASE="$OUT/$FIXTURE"
[ -z "$STORY" ] || BASE="$OUT/$FIXTURE-story-$STORY"

# The runner is installed by the harness, once, into a cache keyed on the lockfile. The model never installs.
LOCK="$FX/project/package-lock.json"
DEPS=""
if [ -f "$LOCK" ]; then
  key=$(shasum -a 256 "$LOCK" | cut -c1-16); DEPS="$CACHE/$key"
  if [ ! -d "$DEPS/node_modules" ]; then
    tmp="$DEPS.tmp"; rm -rf "$tmp"; mkdir -p "$tmp"; cp "$FX/project/package.json" "$LOCK" "$tmp/"
    if ! (cd "$tmp" && "$NPM" ci --ignore-scripts > "$tmp/install.log" 2>&1); then
      echo "the install of the test runner failed (it needs the network the first time):" >&2; tail -5 "$tmp/install.log" >&2; rm -rf "$tmp"; rmdir "$CACHE" 2> /dev/null
      exit 1
    fi
    rm -rf "$DEPS"; mv "$tmp" "$DEPS"
  fi
fi

mkdir -p "$BASE"; OUT="$(cd "$OUT" && pwd)"; BASE="$(cd "$BASE" && pwd)"

manifest() { (cd "$1" && find . -type f ! -path './docs/discovery/*' ! -path './node_modules/*' -print0 | sort -z | xargs -0 shasum -a 1 2>/dev/null); }
final_message() {
  if [ "$COMMAND" = deliver ]; then grep -qE '^[#* ]*Delivered:' "$1"
  else grep -qiE '^[#* ]*readiness' "$1" && grep -qiE '\b(not ready|ready)\b' "$1"; fi
}

for i in $(seq 1 "$RUNS"); do
  rd="$BASE/run-$i"; proj="$rd/project"
  mkdir -p "$rd"; cp -R "$FX/project" "$proj"
  [ -z "$DEPS" ] || cp -R "$DEPS/node_modules" "$proj/node_modules"
  sid=$(uuidgen | tr 'A-Z' 'a-z'); story=$(tr -d '\r' < "$STORYFILE")
  start=$(date +%s); cost=0; turns=0; finished=false; reply=""
  for t in $(seq 1 "$TURNS"); do
    tt=$(printf '%02d' "$t")
    if [ "$t" -eq 1 ]; then
      out=$(cd "$proj" && "$CLAUDE" -p "/bdd:$COMMAND $story" --plugin-dir "$ROOT/plugin" --allowedTools "${TOOLS[@]}" --output-format json --session-id "$sid" 2> "$rd/stderr-$tt.txt")
    else
      out=$(cd "$proj" && "$CLAUDE" -p "$reply" --plugin-dir "$ROOT/plugin" --allowedTools "${TOOLS[@]}" --output-format json --resume "$sid" 2> "$rd/stderr-$tt.txt")
    fi
    msg=$(printf '%s' "$out" | jq -r '.result // empty' 2> /dev/null)
    [ -n "$msg" ] || { echo "run $i, turn $t: no answer from claude (see $rd/stderr-$tt.txt)" >&2; break; }
    printf '%s\n' "$msg" > "$rd/turn-$tt-assistant.txt"
    manifest "$proj" | diff <(manifest "$FX/project") - | grep '^[<>]' | awk '{print $3}' | sed 's|^\./||' | grep '\.feature$' | sort -u > "$rd/turn-$tt-features.txt"
    cost=$(printf '%s %s' "$cost" "$(printf '%s' "$out" | jq -r '.total_cost_usd // 0')" | awk '{print $1 + $2}')
    turns=$t
    if final_message "$rd/turn-$tt-assistant.txt"; then finished=true; break; fi
    [ "$t" -lt "$TURNS" ] || break
    { tr -d '\r' < "$FLOWS/personas/$PERSONA.md"; printf '\nThe assistant just said:\n\n%s\n\nReply as this person, briefly.\n' "$msg"; } > "$rd/pm-prompt-$tt.txt"
    pout=$("$CLAUDE" -p --model haiku --output-format json < "$rd/pm-prompt-$tt.txt" 2> "$rd/pm-stderr-$tt.txt")
    reply=$(printf '%s' "$pout" | jq -r '.result // empty' 2> /dev/null)
    [ -n "$reply" ] || { echo "run $i, turn $t: no reply from the product manager model" >&2; break; }
    printf '%s\n' "$reply" > "$rd/turn-$tt-pm.txt"
    cost=$(printf '%s %s' "$cost" "$(printf '%s' "$pout" | jq -r '.total_cost_usd // 0')" | awk '{print $1 + $2}')
  done
  end=$(date +%s)
  jq -n --argjson turns "$turns" --argjson finished "$finished" --argjson seconds "$((end - start))" --argjson cost "$cost" \
    '{turns: $turns, finished: $finished, seconds: $seconds, cost_usd: $cost}' > "$rd/meta.json"
  # The real test output, taken by the harness, is what the report is checked against.
  [ "$COMMAND" != deliver ] || [ "$turns" -eq 0 ] || (cd "$proj" && "$NPM" test > "$rd/test-output.txt" 2>&1)
  diff <(manifest "$FX/project") <(manifest "$proj") | grep '^[<>]' | awk '{print $3}' | sed 's|^\./||' | sort -u > "$rd/project-diff.txt"
  perl "$FLOWS/rules.pl" "$rd" "$COMMAND" > "$rd/rules.tsv"
done

perl "$FLOWS/report.pl" "$BASE" "$FIXTURE" "$RUNS" "$TURNS" "$COMMAND" "$STORY" > "$BASE/report.md"
echo "Report: $BASE/report.md"
