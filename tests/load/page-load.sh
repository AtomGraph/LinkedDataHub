#!/usr/bin/env bash
set -uo pipefail

# Test: a visitor's page loads lose nothing to the front door's rate limits, and take no longer for them.
#
# A rich page sends up to ~175 requests, 35-46 of them in its first second, and nginx's limits are sized
# to queue that burst rather than refuse it (#432). Measured on linkeddata.lt and the Northwind demo when
# they were: no load saw a 429, and pages settled as fast as with no limits at all, where the limits
# before had cost 3-8x the load time. This keeps it so as the client changes. A page that grows its
# requests is what outgrows the burst, and a limit tightened past a page's burst is what refuses it -
# either shows up here as a 429, a lost request, or a settle time the limits stretched.
#
# The browser runs in the pageload container (docker-compose.load-tests.yml), which reaches nginx both as
# an exempt address and as a limited one, and alternates the two on every page - see page-load/measure.mjs.
# The verdict and its margins are page-load/evaluate.mjs's; the request counts are compared with
# page-load/baseline.json, which UPDATE_BASELINE=1 rewrites from the measurement.
#
# The fixture is a container with a block of every kind the UI suite's fixture has - view, chart, prose,
# object - over 25 items, seeded as the owner and readable anonymously, which is how the browser loads it.

. "$(dirname "$0")/lib/load.sh"

root=$(cd "$(dirname "$0")/../.." && pwd)
base="${END_USER_BASE_URL:-https://localhost:4443/}"
slug="page-load"
container="${base}${slug}/"
FOAF_AGENT="http://xmlns.com/foaf/0.1/Agent"

export LDH_BASE="$base"
export LDH_CERT_FILE="${OWNER_CERT_KEYSTORE:-${root}/tests/http/ssl/owner/keystore.p12}"
export LDH_CERT_PASSWORD="${OWNER_CERT_PWD:-$(cat "${root}/secrets/owner_cert_password.txt")}"

hash ldh 2>/dev/null || { echo >&2 "ldh not on \$PATH (make cli). Aborting."; exit 1; }

items=()
authorizations=()
teardown() {
    for a in "${authorizations[@]}"; do ldh delete "$a" >/dev/null 2>&1 || true; done
    for i in "${items[@]}"; do ldh delete "$i" >/dev/null 2>&1 || true; done
    ldh delete "$container" >/dev/null 2>&1 || true
    rm -rf "$tmpd"
}
tmpd=$(mktemp -d)
trap teardown EXIT

# a previous run that never reached its teardown
ldh delete "$container" >/dev/null 2>&1 || true

ldh create container --parent "$base" --title "Page load fixtures" --slug "$slug" >/dev/null || exit 1

# a JVM per ldh invocation: six at a time, as the UI suite seeds its items
for n in $(seq 1 25); do printf '%02d\n' "$n"; done \
    | xargs -P 6 -I{} sh -c 'ldh create item --container "$1" --title "Fixture item $2" --description "$3" --slug "item-$2" >/dev/null' \
        _ "$container" {} alpha \
    || exit 1
for n in $(seq -w 1 25); do items+=("${container}item-${n}/"); done

cat > "$tmpd/items.rq" <<EOF
PREFIX  sioc: <http://rdfs.org/sioc/ns#>
PREFIX  dct:  <http://purl.org/dc/terms/>

SELECT DISTINCT  ?item ?title
WHERE
  { GRAPH ?g
      { ?item  sioc:has_container  <${container}> ;
               dct:title           ?title
      }
  }
ORDER BY ?title
EOF
cat > "$tmpd/count.rq" <<EOF
PREFIX  sioc: <http://rdfs.org/sioc/ns#>
PREFIX  dct:  <http://purl.org/dc/terms/>

SELECT  ?kind (COUNT(?item) AS ?items)
WHERE
  { GRAPH ?g
      { ?item  sioc:has_container  <${container}> ;
               dct:description     ?kind
      }
  }
GROUP BY ?kind
EOF

{
    ldh add select --title "Items" --uri "${container}#items-query" --query-file "$tmpd/items.rq" "$container" &&
    ldh add view --title "Items view" --uri "${container}#items-view" --query "${container}#items-query" "$container" &&
    ldh add select --title "Item count" --uri "${container}#count-query" --query-file "$tmpd/count.rq" "$container" &&
    ldh add result-set-chart --title "Items chart" --uri "${container}#items-chart" --query "${container}#count-query" \
        --chart-type "https://w3id.org/atomgraph/client#BarChart" --category-var-name kind --series-var-name items "$container" &&
    ldh add xhtml-block --title "Prose" --uri "${container}#prose-block" \
        --value '<div xmlns="http://www.w3.org/1999/xhtml"><h2 id="section">Section</h2><p>Prose block.</p><pre>ldh --help</pre></div>' "$container" &&
    ldh add object-block --title "Object" --uri "${container}#object-block" --value "${items[0]}" "$container" &&
    ldh add object-block --title "Chart block" --uri "${container}#chart-block" --value "${container}#items-chart" "$container" &&
    ldh add object-block --title "View block" --uri "${container}#view-block" --value "${container}#items-view" "$container"
} >/dev/null || exit 1

# readable anonymously whether or not the dataspace is public: the documents, and the endpoint the
# client queries - append too, since it sends some queries over POST
authorizations+=("$(ldh admin create authorization --label "Page load documents" --slug "${slug}-docs" \
    --agent-class "$FOAF_AGENT" --to "$base" --to "$container" --to "${items[0]}" --read "$base")") || exit 1
authorizations+=("$(ldh admin create authorization --label "Page load SPARQL" --slug "${slug}-sparql" \
    --agent-class "$FOAF_AGENT" --to "${base}sparql" --read --append "$base")") || exit 1

# the authorizations and the new documents must not be outlived by cached 403s and 404s
for cache in varnish-frontend varnish-end-user varnish-admin; do
    dc exec -T "$cache" varnishadm "ban req.url ~ /" >/dev/null 2>&1 || true
done

# run.sh runs each test under bash -e: the deletes above may find nothing to delete, and this may fail
# with the verdict, which must still reach the job summary
status=0
dc run --rm \
    -e PAGES="$base $container ${items[0]}" \
    -e LOADS="${LOADS:-5}" \
    -e MAX_SETTLE_RATIO="${MAX_SETTLE_RATIO:-1.3}" \
    -e MAX_PAGE_SETTLE_RATIO="${MAX_PAGE_SETTLE_RATIO:-1.5}" \
    -e REQUEST_MARGIN="${REQUEST_MARGIN:-0.1}" \
    -e UPDATE_BASELINE="${UPDATE_BASELINE:-}" \
    ${NGINX_EXEMPT:+-e NGINX_EXEMPT="$NGINX_EXEMPT"} \
    ${NGINX_LIMITED:+-e NGINX_LIMITED="$NGINX_LIMITED"} \
    pageload \
    || status=$?

out="${root}/tests/load/out/page-load.md" # where the pageload service mounts /out
if [ -n "${GITHUB_STEP_SUMMARY:-}" ] && [ -f "$out" ]; then
    cat "$out" >> "$GITHUB_STEP_SUMMARY"
fi

exit "$status"
