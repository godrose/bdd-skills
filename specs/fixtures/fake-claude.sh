#!/bin/bash
# A stand-in for `claude -p` in the flow tests. It plays a script of messages from $FAKE_DIR.
# A call with `--model haiku` is the product manager (prompt on stdin). Any other call is the assistant.
D="${FAKE_DIR:?FAKE_DIR is not set}"
case " $* " in *" --model haiku "*) kind=pm ;; *) kind=assistant ;; esac
n=$(cat "$D/.$kind" 2>/dev/null || echo 0); n=$((n + 1)); echo "$n" > "$D/.$kind"
echo "$*" > "$D/$kind-args-$n.txt"
if [ "$kind" = pm ]; then cat > "$D/pm-prompt-$n.txt"; fi
if [ "$kind" = assistant ] && [ "${FAKE_WRITE_AT:-0}" = "$n" ]; then mkdir -p "$(dirname "$FAKE_WRITE_FILE")"; echo changed > "$FAKE_WRITE_FILE"; fi
f="$D/$kind-$n.txt"
[ -f "$f" ] || { echo "fake claude: no $kind message $n" >&2; exit 1; }
jq -Rs '{result: ., total_cost_usd: 0.01}' < "$f"
