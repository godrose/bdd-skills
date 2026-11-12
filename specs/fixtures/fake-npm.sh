#!/bin/bash
# A stand-in for npm in the flow tests. `ci` makes a node_modules folder. `test` prints $FAKE_NPM_OUT.
echo "$*" >> "${FAKE_NPM_LOG:?FAKE_NPM_LOG is not set}"
case "$1" in
  ci) [ -z "$FAKE_NPM_FAIL" ] || { echo "network down" >&2; exit 1; }
      mkdir -p node_modules/.bin; echo ok > node_modules/.bin/cucumber-js ;;
  test) cat "${FAKE_NPM_OUT:?FAKE_NPM_OUT is not set}" ;;
esac
