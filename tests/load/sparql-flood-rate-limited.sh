#!/usr/bin/env bash
set -uo pipefail

# Test: a flood of cheap queries is shed by the rate limit, not absorbed onto the threads.
#
# Where the heavy-burst test holds a few slow queries open, this sends many trivial ones as fast as it
# can - the shape of a scanner or a runaway client. Each is cheap for the store, so the query timeout
# never comes into it; what has to answer is the request-rate limit. Under the cap most of the flood
# comes back 429, the site keeps answering, and only a trickle reaches the store.

. "$(dirname "$0")/lib/load.sh"

CONC="${CONC:-50}"
DURATION="${DURATION:-20}"
QUERY="$(dirname "$0")/queries/ask.rq"

attack_out=$(mktemp)
probe_out=$(mktemp)
trap 'rm -f "$attack_out" "$probe_out"' EXIT

probe "$DURATION" "$probe_out" &
probe_pid=$!
attack "$CONC" "$DURATION" "$QUERY" "$attack_out"
wait "$probe_pid"

report "flood (${CONC} concurrent trivial queries for ${DURATION}s)" "$attack_out" "$probe_out"

if [ -n "${MEASURE_ONLY:-}" ]; then exit 0; fi

status=0

rejected=$(count_status "$attack_out" '^429$')
accepted=$(count_status "$attack_out" '^200$')
echo "DEBUG: flood responses - 429: ${rejected}, 200: ${accepted}"
if [ "$rejected" -le "$accepted" ]; then
    echo "FAIL: the flood was not rate-limited - ${rejected} rejected vs ${accepted} served" >&2
    status=1
fi

wedged=$(count_status "$probe_out" '^(000|502|503|504)$')
echo "DEBUG: probe wedged responses: ${wedged}"
if [ "$wedged" -ne 0 ]; then
    echo "FAIL: the site stopped answering under the flood - ${wedged} wedged probe responses" >&2
    status=1
fi

exit "$status"
