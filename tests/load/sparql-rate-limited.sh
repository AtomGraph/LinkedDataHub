#!/usr/bin/env bash
set -uo pipefail

# Test: a high rate of cheap queries is shed by the rate limit, not absorbed onto the request threads.
#
# Where the concurrency test holds a few slow queries open, this sends trivial ones as fast as it can -
# the shape of a scanner or a runaway client. Each is cheap for the store, so the query timeout never
# comes into it; what has to answer is the request-rate limit. Under the limit most requests come back
# 429, the site keeps answering, and only a trickle reaches the store.
#
# One worker per loadgen client: each then has at most one request in flight, and all of them together
# fewer than the total cap, so the concurrency caps can never answer and every 429 is the rate limit's.
# That makes the limit's own arithmetic checkable - nginx lets a client through at most its burst plus
# the rate times the time it kept sending, so no client may have more accepted requests than that.

. "$(dirname "$0")/lib/load.sh"

CONC="${CONC:-$LOADGEN_REPLICAS}"
DURATION="${DURATION:-20}"
# the share of responses that must be 429 for the rate limit to count as engaged (percent)
MIN_REJECTED_PCT="${MIN_REJECTED_PCT:-80}"
# the /sparql rate limit docker-compose.yml gives nginx: NGINX_SPARQL_RATE (r/s or r/m) and the burst, which
# is not configurable there
RATE="${NGINX_SPARQL_RATE:-2r/s}"
BURST="${SPARQL_BURST:-10}"
QUERY="$(dirname "$0")/queries/ask.rq"

load_out=$(mktemp)
probe_out=$(mktemp)
trap 'rm -f "$load_out" "$probe_out"' EXIT

probe "$DURATION" "$probe_out" &
probe_pid=$!
run_load "$CONC" "$DURATION" "$QUERY" "$load_out" 0
wait "$probe_pid"

report "rate limit (${CONC} clients sending trivial queries back-to-back for ${DURATION}s)" "$load_out" "$probe_out"

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

# what got through stayed within the limit, client by client: burst + rate x the client's sending window,
# plus one for a request admitted on the window's edge
accepted_over=$(awk -v rate="$RATE" -v burst="$BURST" '
    BEGIN { r = rate + 0; if (rate ~ /r\/m$/) r = r / 60 }
    NF >= 4 {
        start = $3 - $2
        if (!($4 in first) || start < first[$4]) first[$4] = start
        if ($3 > last[$4]) last[$4] = $3
        if ($1 != "429" && $1 != "000") ok[$4]++
    }
    END {
        for (c in first) {
            bound = int(burst + r * (last[c] - first[c])) + 1
            printf "DEBUG: client %s: %d accepted, bound %d\n", c, ok[c], bound > "/dev/stderr"
            if (ok[c] > bound) printf "%s (%d > %d) ", c, ok[c], bound
        }
    }' "$load_out")
if [ -n "$accepted_over" ]; then
    echo "FAIL: clients got more requests through than the ${RATE} burst ${BURST} limit allows: ${accepted_over}" >&2
    status=1
fi

unavailable=$(count_status "$probe_out" '^(000|502|503|504)$')
echo "DEBUG: probe unavailable responses: ${unavailable}"
if [ "$unavailable" -ne 0 ]; then
    echo "FAIL: the site stopped answering under load - ${unavailable} unavailable probe responses" >&2
    status=1
fi

exit "$status"
