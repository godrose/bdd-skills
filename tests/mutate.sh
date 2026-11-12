#!/bin/bash
# Mutation check: break the code on purpose, one break at a time, and see that the tests notice.
# A break the tests do not notice is a survivor: a gap in the tests, or a change with no effect.
#
# Usage: tests/mutate.sh [--root DIR] [--jobs N] [--cmd COMMAND] BREAKS_FILE
#   --root  the project to break (default: this repo)
#   --jobs  how many copies run at the same time (default 2)
#   --cmd   the test command, run in each copy, that exits non-zero when a test fails
#           (default: NODE_OPTIONS="--import tsx" npx cucumber-js)
#
# BREAKS_FILE has one break per line, with tabs between the fields. Blank lines and lines that start with # are ignored.
#   name <TAB> file <TAB> perl substitution <TAB> equivalent
# The file is relative to the root. The substitution is run as: perl -0pi -e '<substitution>' <file>.
# The last field is optional. Write "equivalent" for a break that no input can tell from the real code.
#
# Every break runs in a copy of the project, never in the project itself. The copies are deleted at the end.
# The tests must pass before the first break. If they do not, nothing is run.
#
# Output, one line per break: CAUGHT, SURVIVED, NOCHANGE (the substitution did not change the file) or NOFILE.
# Exit status: 0 when every break is caught and every survivor is marked equivalent, 1 when not, 2 for a bad call or failing tests.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$HERE"; JOBS=2; CMD='NODE_OPTIONS="--import tsx" npx cucumber-js'; FILE=""

usage() { echo "usage: tests/mutate.sh [--root DIR] [--jobs N] [--cmd COMMAND] BREAKS_FILE" >&2; exit 2; }
while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || usage; ROOT="$2"; shift 2 ;;
    --jobs) [ $# -ge 2 ] || usage; JOBS="$2"; shift 2 ;;
    --cmd) [ $# -ge 2 ] || usage; CMD="$2"; shift 2 ;;
    -*) usage ;;
    *) [ -z "$FILE" ] || usage; FILE="$1"; shift ;;
  esac
done
[ -n "$FILE" ] || usage
[ -f "$FILE" ] || { echo "no such breaks file: $FILE" >&2; exit 2; }
[ -d "$ROOT" ] || { echo "no such root: $ROOT" >&2; exit 2; }
case "$JOBS" in ''|*[!0-9]*|0) echo "--jobs needs a number above 0" >&2; exit 2 ;; esac
command -v rsync > /dev/null 2>&1 || { echo "rsync is needed to copy the project" >&2; exit 2; }
FILE="$(cd "$(dirname "$FILE")" && pwd)/$(basename "$FILE")"

WORK="$(mktemp -d)"
cleanup() { kill $(jobs -p) 2> /dev/null; rm -rf "$WORK"; }
trap cleanup EXIT
trap 'exit 130' INT TERM

for j in $(seq 1 "$JOBS"); do
  rsync -a --exclude .git --exclude node_modules --exclude flows/results --exclude evals/results "$ROOT/" "$WORK/copy$j/"
  [ ! -d "$ROOT/node_modules" ] || ln -s "$ROOT/node_modules" "$WORK/copy$j/node_modules"
done

if ! (cd "$WORK/copy1" && eval "$CMD") > "$WORK/baseline.log" 2>&1; then
  echo "The tests fail before any break, so no break can be judged. Last lines:" >&2
  tail -8 "$WORK/baseline.log" >&2
  exit 2
fi

grep -v -e '^[[:space:]]*$' -e '^#' "$FILE" | awk -v w="$WORK" -v n="$JOBS" '{ print NR "\t" $0 > (w "/jobs" ((NR - 1) % n + 1)) }'

run_job() { # <job number>
  local j="$1" copy="$WORK/copy$1" idx name file sub flag target
  [ -f "$WORK/jobs$j" ] || return 0
  while IFS=$'\t' read -r idx name file sub flag; do
    target="$copy/$file"
    if [ ! -f "$target" ]; then printf '%s\tNOFILE    %s  (%s)\n' "$idx" "$name" "$file"; continue; fi
    cp "$target" "$WORK/bak$j"
    perl -0pi -e "$sub" "$target"
    if cmp -s "$target" "$WORK/bak$j"; then
      printf '%s\tNOCHANGE  %s\n' "$idx" "$name"
    elif (cd "$copy" && eval "$CMD") > /dev/null 2>&1; then
      if [ "$flag" = equivalent ]; then printf '%s\tSURVIVED  %s  (equivalent, expected)\n' "$idx" "$name"; else printf '%s\tSURVIVED  %s\n' "$idx" "$name"; fi
    else
      if [ "$flag" = equivalent ]; then printf '%s\tCAUGHT    %s  (marked equivalent but caught: remove the mark)\n' "$idx" "$name"; else printf '%s\tCAUGHT    %s\n' "$idx" "$name"; fi
    fi
    cp "$WORK/bak$j" "$target"
  done < "$WORK/jobs$j" > "$WORK/out$j"
}

for j in $(seq 1 "$JOBS"); do run_job "$j" & done
wait

cat "$WORK"/out* 2> /dev/null | sort -n | cut -f2- > "$WORK/all.txt"
cat "$WORK/all.txt"
count() { grep -c "$1" "$WORK/all.txt"; }
stale=$(count 'remove the mark)$')
expected=$(count '(equivalent, expected)$')
bad=$(( $(count '^SURVIVED') - expected + $(count '^NOCHANGE') + $(count '^NOFILE') + stale ))
echo "caught: $(( $(count '^CAUGHT') - stale )), survived as expected: $expected, to look at: $bad"
[ "$bad" -eq 0 ]
