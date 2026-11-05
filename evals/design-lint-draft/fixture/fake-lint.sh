#!/bin/sh
# House rule: every scenario carries a ticket tag such as @TKT-42 on the line above it.
status=0
for f in $(find features -name '*.feature' | sort); do
  awk -v file="$f" '
    /^[ \t]*Scenario/ { if (prev !~ /@TKT-[0-9]+/) { printf "%s:%d: scenario needs a @TKT-<n> tag\n", file, NR; bad = 1 } }
    { prev = $0 }
    END { exit bad }
  ' "$f" || status=1
done
[ "$status" -eq 0 ] && echo "lint: no findings"
exit $status
