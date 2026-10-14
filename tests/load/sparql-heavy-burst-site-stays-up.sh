#!/usr/bin/env bash
set -uo pipefail

# Test: heavy /sparql queries arriving together do not take the site down with them.
#
# Each proxied /sparql request holds one of the platform's request threads for as long as the query
# runs (here until the 60 s store timeout). The load stack has 16 threads (HTTP_MAX_THREADS). Send
# more long queries at once than there are threads and, without the concurrency cap, every thread is
# busy on a query and an ordinary page render has nowhere to run - the site stops answering. The cap
# bounds how many /sparql requests are in flight at once, leaving threads for everything else, and
# turns the overflow into 429s. So while 24 heavy queries (1.5x the threads) run for 90 s, a visitor
# fetching the public root must still get an answer within the probe bound.

. "$(dirname "$0")/lib/load.sh"

THREADS="${HTTP_MAX_THREADS:-16}"
CONC=$(( THREADS * 3 / 2 ))
DURATION="${DURATION:-90}"
QUERY="$(dirname "$0")/queries/cpu-heavy.rq"

attack_out=$(mktemp)
probe_out=$(mktemp)
trap 'rm -f "$attack_out" "$probe_out"' EXIT

probe "$DURATION" "$probe_out" &
probe_pid=$!
attack "$CONC" "$DURATION" "$QUERY" "$attack_out"
wait "$probe_pid"

report "heavy burst (${CONC} concurrent for ${DURATION}s)" "$attack_out" "$probe_out"

if [ -n "${MEASURE_ONLY:-}" ]; then exit 0; fi

status=0

# the site stayed up: no probe saw the platform wedged
wedged=$(count_status "$probe_out" '^(000|502|503|504)$')
echo "DEBUG: probe wedged responses (000/502/503/504): ${wedged}"
if [ "$wedged" -ne 0 ]; then
    echo "FAIL: the site stopped answering under the query burst - ${wedged} wedged probe responses" >&2
    status=1
fi

# the probe was served promptly throughout
slowest=$(pctl "$probe_out" 100)
echo "DEBUG: slowest probe: ${slowest}s"
if awk -v s="$slowest" 'BEGIN { exit !(s+0 >= 30) }'; then
    echo "FAIL: a probe took ${slowest}s - the site was not answering promptly" >&2
    status=1
fi

# the cap engaged: the overflow was rejected rather than queued onto the threads
rejected=$(count_status "$attack_out" '^429$')
echo "DEBUG: 429 responses to the burst: ${rejected}"
if [ "$rejected" -eq 0 ]; then
    echo "FAIL: no query was rejected - the concurrency cap did not engage, so nothing bounded the burst" >&2
    status=1
fi

exit "$status"
