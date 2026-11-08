#!/bin/bash
# Run the plugin evals. The eval tool reads cases from a folder below the plugin, and the plugin folder
# cannot hold them (the directory refuses scripts and fixtures there). So this builds a temporary copy.
#
# Usage: evals/run.sh <claude plugin eval options>
#   evals/run.sh --scaffold --runs 1 --ablation none --model haiku --judge-model sonnet --no-publish --allow-tools Write Edit
# Results are copied to evals/results/.
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cp -R "$ROOT/plugin" "$WORK/plugin"
mkdir -p "$WORK/plugin/evals"
for d in "$ROOT"/evals/*/; do
  [ "$(basename "$d")" = "results" ] && continue
  cp -R "${d%/}" "$WORK/plugin/evals/"
done

status=0
claude plugin eval "$WORK/plugin" "$@" || status=$?

if [ -d "$WORK/plugin/evals/results" ]; then
  mkdir -p "$ROOT/evals/results"
  cp -R "$WORK/plugin/evals/results/." "$ROOT/evals/results/"
fi
exit $status
