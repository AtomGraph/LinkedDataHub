#!/usr/bin/env bash
set -uo pipefail

# Test: many concurrent /sparql queries arriving at once must not make the rest of the site unavailable.
#
# Each proxied /sparql request holds one of the platform's request threads for as long as the query
# runs (here until the 60 s store timeout). The load stack has 16 threads (HTTP_MAX_THREADS). Send more
# long queries at once than there are threads and, without the concurrency cap, every thread is busy on
# a query and an ordinary page render has nowhere to run - the site stops answering. The cap bounds how
# many /sparql requests are in flight at once, leaving threads for everything else, and turns the
# surplus into 429s. So while 24 concurrent queries (1.5x the threads) run for 90 s, a visitor fetching
# the public root must still get an answer within the probe bound.
#
# The site staying up proves nothing if the queries never held their slots, so the test also rebuilds,
# from each response's start and end, how many queries were in flight at once: the total must reach the
# cap (the load really pressed against it) and never pass it, and no single client may pass its own cap.
# A rejected worker backs off a second before retrying, like a client honouring the 429, so the
# rejections come from the concurrency caps, not from a spin that trips the rate limit.

. "$(dirname "$0")/lib/load.sh"

THREADS="${HTTP_MAX_THREADS:-16}"
CONC="${CONC:-$(( THREADS * 3 / 2 ))}"
DURATION="${DURATION:-90}"
# a visitor's request must get an answer within this many seconds for the site to count as available
PROBE_BOUND="${PROBE_BOUND:-30}"
BACKOFF="${BACKOFF:-1}"
QUERY="$(dirname "$0")/queries/cpu-bound.rq"

load_out=$(mktemp)
probe_out=$(mktemp)
trap 'rm -f "$load_out" "$probe_out"' EXIT

probe "$DURATION" "$probe_out" &
probe_pid=$!
run_load "$CONC" "$DURATION" "$QUERY" "$load_out" "$BACKOFF"
wait "$probe_pid"

report "concurrency (${CONC} concurrent for ${DURATION}s)" "$load_out" "$probe_out"

if [ -n "${MEASURE_ONLY:-}" ]; then exit 0; fi

status=0

# the site stayed available: no probe saw the platform down
unavailable=$(count_status "$probe_out" '^(000|502|503|504)$')
echo "DEBUG: probe unavailable responses (000/502/503/504): ${unavailable}"
if [ "$unavailable" -ne 0 ]; then
    echo "FAIL: the site stopped answering while the queries ran - ${unavailable} unavailable probe responses" >&2
    status=1
fi

# the probe was served within the bound throughout
slowest=$(pctl "$probe_out" 100)
echo "DEBUG: slowest probe: ${slowest}s (bound ${PROBE_BOUND}s)"
if awk -v s="$slowest" -v b="$PROBE_BOUND" 'BEGIN { exit !(s+0 >= b) }'; then
    echo "FAIL: a probe took ${slowest}s (>= ${PROBE_BOUND}s) - the site was not answering promptly" >&2
    status=1
fi

# the cap engaged: the surplus was rejected rather than queued onto the threads
rejected=$(count_status "$load_out" '^429$')
echo "DEBUG: 429 responses: ${rejected}"
if [ "$rejected" -eq 0 ]; then
    echo "FAIL: nothing was rejected - the concurrency cap did not engage, so nothing bounded the load" >&2
    status=1
fi

# the total cap held, and the load actually reached it: fewer in flight means the queries were too cheap to
# hold a request open, and the site staying up says nothing about the cap
inflight=$(max_inflight "$load_out")
echo "DEBUG: most queries in flight at once: ${inflight} (NGINX_SPARQL_CONN_TOTAL=${SPARQL_CONN_TOTAL})"
if [ "$inflight" -gt "$SPARQL_CONN_TOTAL" ]; then
    echo "FAIL: ${inflight} queries were in flight at once, past the cap of ${SPARQL_CONN_TOTAL}" >&2
    status=1
elif [ "$inflight" -lt "$SPARQL_CONN_TOTAL" ]; then
    echo "FAIL: at most ${inflight} queries were in flight at once, never the cap of ${SPARQL_CONN_TOTAL} - the load did not press against it" >&2
    status=1
fi

# and so did the per-client cap
per_client=$(max_inflight_per_client "$load_out")
echo "DEBUG: most queries in flight at once from one client: ${per_client} (NGINX_SPARQL_CONN_PER_CLIENT=${SPARQL_CONN_PER_CLIENT})"
if [ "$per_client" -gt "$SPARQL_CONN_PER_CLIENT" ]; then
    echo "FAIL: one client had ${per_client} queries in flight at once, past the per-client cap of ${SPARQL_CONN_PER_CLIENT}" >&2
    status=1
fi

exit "$status"
