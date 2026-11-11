#!/bin/bash
# Runs the same steps as the CI job (.github/workflows/ci.yml), in the same order, and names the step that failed.
# Run it before every push. Release pull requests also run tests/check_release.sh in CI.
cd "$(dirname "$0")/.." || exit 1

step() { # <name> <command...>
  local name="$1"; shift
  echo "== $name"
  "$@" || { echo "FAILED at step: $name" >&2; exit 1; }
}

step "validate the plugin" bash -c 'command -v claude > /dev/null 2>&1 || { echo "claude is not installed, so the plugin cannot be validated (CI installs @anthropic-ai/claude-code)." >&2; exit 1; }; claude plugin validate plugin --strict'
step "validate the marketplace" claude plugin validate .
step "install the scenario runner" npm ci
step "run the tests" bash tests/run.sh
echo "All steps passed."
