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

# Probe /ns with a query in one shot. Sets NS_STATUS, NS_BODY, NS_COUNT. Never fails the shell
# (no -f), so even a 5xx from a broken closure still yields diagnostics instead of aborting.
ns_probe() {
  local body
  body=$(curl -k -s -G -w $'\n%{http_code}' \
    -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
    -H "Accept: application/sparql-results+xml" \
    "${END_USER_BASE_URL}ns" \
    --data-urlencode "query=${1}") || true
  NS_STATUS="${body##*$'\n'}"
  NS_BODY="${body%$'\n'*}"
  NS_COUNT=$(printf '%s' "$NS_BODY" | xmllint --xpath "count(//*[local-name() = 'result'])" - 2>/dev/null || echo "ERR")
}

# assert NS_COUNT for a phase; on mismatch dump the raw response and exit 1
assert_count() {
  local phase="$1" q="$2" expected="$3" note="$4"
  ns_probe "$q"
  echo "DEBUG: [$phase] Expected: $expected  Got: $NS_COUNT  (HTTP $NS_STATUS)"
  if [ "$NS_COUNT" != "$expected" ]; then
    echo "DEBUG: [$phase] $note" >&2
    echo "DEBUG: [$phase] raw /ns response body:" >&2
    printf '%s\n' "$NS_BODY" >&2
    exit 1
  fi
}

# PATCH /settings and assert no-content; on mismatch report the status
patch_settings() {
  local phase="$1" update="$2" status
  status=$(curl -k -w "%{http_code}" -o /dev/null -s \
    -X PATCH \
    -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
    -H "Content-Type: application/sparql-update" \
    -d "$update" \
    "${END_USER_BASE_URL}settings")
  echo "DEBUG: [$phase] Expected: $STATUS_NO_CONTENT  Got: $status"
  if ! grep -qE "^(${STATUS_NO_CONTENT})$" <<< "$status"; then
    echo "DEBUG: [$phase] PATCH of ldh:import did not return no-content" >&2
    exit 1
  fi
}

# the skos:Concept constructor / views are not in the app ontology closure initially
assert_count "pre-import constructor"  "$query"      0 "package leaked into closure before import?"
assert_count "pre-import views"        "$view_query" 0 "package leaked into closure before import?"

# declare the package import
patch_settings "import PATCH" \
  "INSERT { <${app_uri}> <https://w3id.org/atomgraph/linkeddatahub#import> <${package_uri}> . } WHERE { }"

# the /ns query URL is identical across the phases, so evict any cached response
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# the package ontology joined the closure - no restart, no sleep
assert_count "post-import constructor" "$query"      1 "constructor missing - package ontology (${package_uri}) did not join the closure"
assert_count "post-import views"       "$view_query" 2 "views missing - ldh:view declarations did not join the closure"

# remove the package import
patch_settings "remove PATCH" \
  "DELETE { <${app_uri}> <https://w3id.org/atomgraph/linkeddatahub#import> <${package_uri}> . } WHERE { }"

purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# the package ontology left the closure
assert_count "post-remove views"       "$view_query" 0 "views still present - package ontology did not leave the closure"
assert_count "post-remove constructor" "$query"      0 "constructor still present - package ontology did not leave the closure"
