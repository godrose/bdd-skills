#!/bin/bash
# Run by CI on pull requests whose title starts with "release:". Not part of tests/run.sh, which runs on every PR.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/tests/lib.sh"

assert_version_higher
assert_version_bumped

finish
