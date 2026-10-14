#!/usr/bin/env bash
set -uo pipefail

# Test: a query that exhausts the store's heap takes the store down cleanly and it comes back.
#
# The 60 s query timeout bounds a query's time, not its memory. A query that materialises a large
# intermediate result (the five-way self-join, sorted) reaches OutOfMemoryError against the load
# stack's small Fuseki heap before the timeout fires. A JVM that keeps running past an
# OutOfMemoryError is in an undefined state and may answer every later query with a 500. The guard is
# -XX:+ExitOnOutOfMemoryError plus restart: on-failure: the JVM exits and the container restarts, so
# within seconds the store answers again. So after the heavy queries stop, the store must serve a
# trivial query 200 again within the recovery window.

. "$(dirname "$0")/lib/load.sh"

CONC="${CONC:-4}"
DURATION="${DURATION:-60}"
RECOVERY="${RECOVERY:-60}"
QUERY="$(dirname "$0")/queries/memory-heavy.rq"

attack_out=$(mktemp)
probe_out=$(mktemp)
trap 'rm -f "$attack_out" "$probe_out"' EXIT

restarts_before=$(fuseki_restart_count)
echo "DEBUG: fuseki restarts before: ${restarts_before}"

probe "$DURATION" "$probe_out" &
probe_pid=$!
attack "$CONC" "$DURATION" "$QUERY" "$attack_out"
wait "$probe_pid"

# give the store the recovery window to exit and come back, then check it answers
recovered=0
deadline=$(( $(now_s) + RECOVERY ))
while [ "$(now_s)" -lt "$deadline" ]; do
    if fuseki_answers; then recovered=1; break; fi
    sleep 3
done

restarts_after=$(fuseki_restart_count)

report "heap exhaustion (${CONC} concurrent for ${DURATION}s)" "$attack_out" "$probe_out"
echo "DEBUG: fuseki restarts after: ${restarts_after} (delta $(( restarts_after - restarts_before )))"
echo "DEBUG: store answers a trivial query again: $([ "$recovered" = 1 ] && echo yes || echo no)"

if [ -n "${MEASURE_ONLY:-}" ]; then exit 0; fi

if [ "$recovered" -ne 1 ]; then
    echo "FAIL: the store did not answer a trivial query within ${RECOVERY}s of the load stopping - it did not recover" >&2
    exit 1
fi
