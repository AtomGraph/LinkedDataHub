#!/usr/bin/env bash
# Shared helpers for the SPARQL load tests. Sourced by the tests/load/*.sh that drive query load
# through the front door and watch what it does to the platform.
#
# The front door caps /sparql per client address and exempts RFC 1918 callers (its own self-calls).
# A curl on the runner reaches nginx as the Docker bridge or Docker Desktop VM address, both of which
# the caps skip - so the query load comes from the `loadgen` containers on the 100.64.0.0/24 network
# (carrier-grade NAT, neither RFC 1918 nor site-local), each a distinct external client to nginx. The
# containers are idle; these helpers drive them with `docker compose exec`. The site probe, measuring
# what an ordinary visitor sees meanwhile, runs from the host (exempt, like real internal health checks).

set -uo pipefail

# The compose invocation that owns the running stack. compare.sh and the CI workflow export COMPOSE_CMD;
# a developer running one test by hand gets the default built from this file's location.
if [ -z "${COMPOSE_CMD:-}" ]; then
    _root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
    COMPOSE_CMD="docker compose -p ${LOAD_PROJECT:-ldh-load} \
-f ${_root}/docker-compose.yml \
-f ${_root}/tests/http/docker-compose.http-tests.yml \
-f ${_root}/tests/load/docker-compose.load-tests.yml \
--env-file ${_root}/tests/http/.env"
fi
dc() { $COMPOSE_CMD "$@"; }

# how many loadgen containers the override starts (deploy.replicas); workers are spread across them
LOADGEN_REPLICAS="${LOADGEN_REPLICAS:-6}"
# the public name the stack answers to; the loadgen reaches nginx by service name but keeps this Host/SNI
SPARQL_HOST="${SPARQL_HOST:-localhost:4443}"

now_s() { date +%s; }

# send_query <index> <query_file>: one anonymous POST of the query from loadgen container <index>,
# printing "<http_status> <seconds>". --connect-to keeps Host and SNI at the public name while the
# connection goes to nginx on the shared network. One-shot, for the recovery check - the sustained load
# is driven by run_load() below, which loops inside the container instead.
send_query() {
    local idx="$1" qfile="$2" q
    q=$(cat "$qfile")
    dc exec -T --index "$idx" loadgen \
        curl -k -s -o /dev/null -w '%{http_code} %{time_total}\n' --max-time 120 \
        --connect-to "${SPARQL_HOST}:nginx:8443" \
        -H 'Accept: application/sparql-results+json' \
        --data-urlencode "query=${q}" \
        "https://${SPARQL_HOST}/sparql" 2>/dev/null || echo "000 0"
}

# the body each load worker runs INSIDE its loadgen container: curl the query back-to-back until
# DUR seconds have passed, one result line per request. The loop runs in the container so each worker
# costs one `docker compose exec` for the whole run, not one per request - a per-request exec overwhelmed
# the runner with compose-CLI launches and starved the stack being measured. DUR, Q and HOST come in as
# env so this stays a fixed single-quoted string on the host side (no query text to quote through).
_LOAD_LOOP='end=$(( $(date +%s) + DUR )); while [ "$(date +%s)" -lt "$end" ]; do curl -k -s -o /dev/null -w "%{http_code} %{time_total}\n" --max-time 120 --connect-to "$HOST:nginx:8443" -H "Accept: application/sparql-results+json" --data-urlencode "query=$Q" "https://$HOST/sparql" || echo "000 0"; done'

# run_load <concurrency> <duration_s> <query_file> <out_file>: hold <concurrency> anonymous queries in
# flight for <duration_s>, one in-container worker per slot looping back-to-back, spread across the
# loadgen replicas. Every response's "<status> <seconds>" lands in <out_file>. Returns when all workers
# have stopped (bounded by <duration_s> plus one in-flight query).
run_load() {
    local conc="$1" dur="$2" qfile="$3" out="$4" q
    q=$(cat "$qfile")
    : > "$out"
    local tmpd; tmpd=$(mktemp -d)
    local i idx pids=()
    for i in $(seq 1 "$conc"); do
        idx=$(( (i - 1) % LOADGEN_REPLICAS + 1 ))
        # each worker writes its own file, so result lines never interleave; concatenated at the end
        dc exec -T -e DUR="$dur" -e Q="$q" -e HOST="$SPARQL_HOST" --index "$idx" loadgen \
            sh -c "$_LOAD_LOOP" > "$tmpd/$i" 2>/dev/null &
        pids+=("$!")
    done
    # wait only on this function's own workers, so a probe running in the caller's background is left alone
    wait "${pids[@]}"
    cat "$tmpd"/* > "$out" 2>/dev/null
    rm -rf "$tmpd"
}

# probe <duration_s> <out_file>: once a second for <duration_s>, fetch the public root from the host and
# record "<status> <seconds>". This is the visitor's view of the site while the query load runs: an
# answer within the bound is a healthy site, a 000/502/503/504 is the platform unavailable.
probe() {
    local dur="$1" out="$2"
    : > "$out"
    local deadline=$(( $(now_s) + dur ))
    while [ "$(now_s)" -lt "$deadline" ]; do
        curl -k -s -o /dev/null -w '%{http_code} %{time_total}\n' --max-time 30 \
            -H 'Accept: text/html' "https://${SPARQL_HOST}/" >> "$out" 2>/dev/null || echo "000 0" >> "$out"
        sleep 1
    done
}

# fuseki_restart_count: how many times the fuseki container has been restarted by its restart policy
fuseki_restart_count() {
    docker inspect -f '{{.RestartCount}}' "$(dc ps -q fuseki)" 2>/dev/null || echo 0
}

# fuseki_answers: 0 if the store answers a trivial query 200, non-zero otherwise
fuseki_answers() {
    local code
    code=$(send_query 1 "$(dirname "${BASH_SOURCE[0]}")/../queries/ask.rq" | awk '{print $1}')
    [ "$code" = 200 ]
}

# histogram <file>: prints "<count> x HTTP <status>" per status seen, most common first
histogram() {
    awk '{print $1}' "$1" | sort | uniq -c | sort -rn | while read -r n s; do echo "  ${n} x HTTP ${s}"; done
}

# pXX <file> <percentile>: the given percentile of the time column, in seconds
pctl() {
    awk '{print $2}' "$1" | sort -n | awk -v p="$2" '{a[NR]=$1} END {if (NR==0) {print "n/a"; exit} i=int((p/100)*NR); if (i<1) i=1; print a[i]}'
}

# count_status <file> <regex>: how many rows have a status matching the regex
count_status() { awk -v re="$2" '$1 ~ re {n++} END {print n+0}' "$1"; }

# report <label> <load_out> <probe_out>: the standard block both the asserting tests and compare.sh print
report() {
    local label="$1" aout="$2" pout="$3"
    echo "=== ${label} ==="
    echo "query responses:"; histogram "$aout"
    echo "  p50=$(pctl "$aout" 50)s p95=$(pctl "$aout" 95)s max=$(pctl "$aout" 100)s"
    echo "site probe while under load:"; histogram "$pout"
    echo "  p50=$(pctl "$pout" 50)s p95=$(pctl "$pout" 95)s max=$(pctl "$pout" 100)s"
    echo "fuseki restarts: $(fuseki_restart_count)"
}
