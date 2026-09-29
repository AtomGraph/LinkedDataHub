#!/usr/bin/env bash
set -euo pipefail

# Test: a burst of renders does not deadlock the platform against itself.
#
# Every server-side HTML render calls back into the platform over HTTP: layout.xsl POSTs to the
# dataspace's /sparql and /ns for the labels it puts on the page (ldh:send-request), and in a
# deployment those calls go out through the proxy - nginx, Varnish, and back into this same Tomcat.
# Each callback needs a free request thread to be answered and holds one of the client pool's
# connections while it waits. So once renders outnumber the connector's threads, every thread is a
# render waiting for a callback that no thread is free to serve, and the rest queue on the pool
# behind them: nothing completes until reads time out, and with a steady trickle of new requests
# not even then. linkeddatahub.com wedged exactly so on 2026-09-29 - a scanner probed paths that
# do not exist across the dataspace origins, every 403 and 404 page is a full render, and the 200
# threads filled within a minute. The pages were error pages, the callbacks were not.
#
# The stack runs with a 16-thread connector and a 4-per-route client pool
# (docker-compose.load-tests.yml), production's ratio at a size the runner can saturate: a burst of
# three times the connector is enough. The requests are anonymous GETs of documents that do not
# exist, which is what the scanner sent. The bound is the assertion: once the burst has been
# answered or given up on, a plain request must get an HTTP status within 30 s. curl's 000 and the
# proxy's 502/503/504 are the deadlock, whatever the platform would eventually have answered.
#
# Measured on 6.0.0 with this stack: without a fix the platform answers nothing for as long as its
# reads take to time out (the override sets that to ten minutes). A pool-wait timeout
# (CONNECTION_REQUEST_TIMEOUT=10000) is a mitigation, not a fix - the renders queued on the pool
# fail in ten-second waves and the platform answered again 113 s after the burst began, which this
# bound is right to reject. It passes once a render no longer needs a request thread of its own
# to be answered: the callbacks answered in-process, or through a client of their own that cannot
# take the connector down with it.

burst=$(( HTTP_MAX_THREADS * 3 ))
bound=30

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# the burst: each an error page, each a render with its callbacks. Given a long leash on purpose -
# the test is about the platform afterwards, and a burst that is still hanging when the leash runs
# out is reported below rather than asserted on

for i in $(seq 1 "$burst"); do
  curl -k -s -o /dev/null -w "%{http_code} %{time_total}\n" --max-time 90 \
    -H "Accept: text/html" \
    "${END_USER_BASE_URL}load-burst-${i}-$$/" > "$tmp/$i" 2>/dev/null &
done
wait

cat "$tmp"/* | awk '{print $1}' | sort | uniq -c | while read -r n s; do echo "DEBUG: [burst] $n x HTTP $s"; done
echo "DEBUG: [burst] slowest: $(cat "$tmp"/* | awk '{print $2}' | sort -n | tail -1) s"

# the platform afterwards: any status is an answer - anonymous access to the root is 403 here

start=$(date +%s)
status=$(curl -k -s -o /dev/null -w "%{http_code}" --max-time "$bound" \
  -H "Accept: application/n-triples" \
  "$END_USER_BASE_URL" || true)
elapsed=$(( $(date +%s) - start ))

echo "DEBUG: [after] Expected: an HTTP status within ${bound} s  Got: $status after ${elapsed} s"
case "$status" in
  000|502|503|504)
    echo "DEBUG: [after] the platform did not answer after the burst: its renders are waiting on each other's callbacks" >&2
    exit 1
    ;;
esac
