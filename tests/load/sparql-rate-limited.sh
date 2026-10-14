#!/usr/bin/env bash
set -uo pipefail

# Test: a high rate of cheap queries is shed by the rate limit, not absorbed onto the request threads.
#
# Where the concurrency test holds a few slow queries open, this sends many trivial ones as fast as it
# can - the shape of a scanner or a runaway client. Each is cheap for the store, so the query timeout
# never comes into it; what has to answer is the request-rate limit. Under the cap most requests come
# back 429, the site keeps answering, and only a trickle reaches the store.

. "$(dirname "$0")/lib/load.sh"

CONC="${CONC:-50}"
DURATION="${DURATION:-20}"
# the share of responses that must be 429 for the rate limit to count as engaged (percent)
MIN_REJECTED_PCT="${MIN_REJECTED_PCT:-80}"
QUERY="$(dirname "$0")/queries/ask.rq"

load_out=$(mktemp)
probe_out=$(mktemp)
trap 'rm -f "$load_out" "$probe_out"' EXIT

probe "$DURATION" "$probe_out" &
probe_pid=$!
run_load "$CONC" "$DURATION" "$QUERY" "$load_out"
wait "$probe_pid"

report "rate limit (${CONC} concurrent trivial queries for ${DURATION}s)" "$load_out" "$probe_out"

if [ -n "${MEASURE_ONLY:-}" ]; then exit 0; fi

status=0

rejected=$(count_status "$load_out" '^429$')
total=$(grep -c . "$load_out")
pct=$(( total > 0 ? rejected * 100 / total : 0 ))
echo "DEBUG: rejected ${rejected}/${total} (${pct}%), threshold ${MIN_REJECTED_PCT}%"
if [ "$pct" -lt "$MIN_REJECTED_PCT" ]; then
    echo "FAIL: only ${pct}% of requests were rejected - the rate limit did not shed the load" >&2
    status=1
fi

unavailable=$(count_status "$probe_out" '^(000|502|503|504)$')
echo "DEBUG: probe unavailable responses: ${unavailable}"
if [ "$unavailable" -ne 0 ]; then
    echo "FAIL: the site stopped answering under load - ${unavailable} unavailable probe responses" >&2
    status=1
fi

exit "$status"
