#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# Test: the ldh:import declaration alone puts the package ontology into the application's
# ontology imports closure - the SKOS package's spin:constructor for skos:Concept becomes
# visible on the /ns endpoint after the PATCH and disappears again after removal.

app_uri="urn:linkeddatahub:apps/end-user"
package_uri="https://packages.linkeddatahub.com/skos/#this"

query='SELECT ?text WHERE { <http://www.w3.org/2004/02/skos/core#Concept> <http://spinrdf.org/spin#constructor> ?constructor . ?constructor <http://spinrdf.org/sp#text> ?text . }'

# the ldh:view declarations are what render the Broader/Narrower concept blocks - the user-facing
# feature of the package, and the thing that goes silent if the import stops being composed
view_query='SELECT ?view WHERE { VALUES ?property { <http://www.w3.org/2004/02/skos/core#broader> <http://www.w3.org/2004/02/skos/core#narrower> } ?property <https://w3id.org/atomgraph/linkeddatahub#view> ?view . }'

ns_result_count() {
  curl -k -f -s -G \
    -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
    -H "Accept: application/sparql-results+xml" \
    "${END_USER_BASE_URL}ns" \
    --data-urlencode "query=${1}" \
  | xmllint --xpath "count(//*[local-name() = 'result'])" -
}

constructor_count() {
  ns_result_count "$query"
}

view_count() {
  ns_result_count "$view_query"
}

# the skos:Concept constructor is not in the app ontology closure initially
count=$(constructor_count)
if [ "$count" != "0" ]; then
  echo "DEBUG: Expected 0 skos:Concept constructors before import, got: $count"
  exit 1
fi

views=$(view_count)
if [ "$views" != "0" ]; then
  echo "DEBUG: Expected 0 ldh:view declarations before import, got: $views"
  exit 1
fi

# declare the package import
(
curl -k -w "%{http_code}\n" -o /dev/null -s \
  -X PATCH \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Content-Type: application/sparql-update" \
  -d "INSERT { <${app_uri}> <https://w3id.org/atomgraph/linkeddatahub#import> <${package_uri}> . } WHERE { }" \
  "${END_USER_BASE_URL}settings"
) \
| grep -q "$STATUS_NO_CONTENT"

# the /ns query URL is identical across the phases, so evict any cached response
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# the package ontology joined the closure - no restart, no sleep
count=$(constructor_count)
if [ "$count" != "1" ]; then
  echo "DEBUG: Expected 1 skos:Concept constructor after import, got: $count"
  exit 1
fi

views=$(view_count)
if [ "$views" != "2" ]; then
  echo "DEBUG: Expected 2 ldh:view declarations (skos:broader, skos:narrower) after import, got: $views"
  exit 1
fi

# remove the package import
(
curl -k -w "%{http_code}\n" -o /dev/null -s \
  -X PATCH \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Content-Type: application/sparql-update" \
  -d "DELETE { <${app_uri}> <https://w3id.org/atomgraph/linkeddatahub#import> <${package_uri}> . } WHERE { }" \
  "${END_USER_BASE_URL}settings"
) \
| grep -q "$STATUS_NO_CONTENT"

purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# the package ontology left the closure
views=$(view_count)
if [ "$views" != "0" ]; then
  echo "DEBUG: Expected 0 ldh:view declarations after removal, got: $views"
  exit 1
fi

count=$(constructor_count)
if [ "$count" != "0" ]; then
  echo "DEBUG: Expected 0 skos:Concept constructors after removal, got: $count"
  echo "DEBUG: does /settings still carry the ldh:import triple after the DELETE?"
  curl -k -s \
    -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
    -H "Accept: application/n-triples" \
    "${END_USER_BASE_URL}settings" \
  | grep -c "linkeddatahub#import" | sed 's/^/DEBUG: ldh:import triple count in settings = /'
  exit 1
fi
