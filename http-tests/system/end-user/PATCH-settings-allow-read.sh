#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# lapp:allowRead is load-bearing: when true, AuthorizationFilter skips authorization for ALL GET/HEAD requests
# (apps/model isReadAllowed -> the read short-circuit in AuthorizationFilter). It is off by default and set in no
# fixture, so this test toggles it on via PATCH /settings, verifies the effect, and always removes it again (EXIT
# trap) so the read-open state cannot leak into other tests.

# reset runs on every exit (success or failure); cleanup must not itself abort, so no -f here
reset_allow_read()
{
    curl -k -s -o /dev/null \
      -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
      -X PATCH \
      -H "Content-Type: application/sparql-update" \
      -d "PREFIX lapp: <https://w3id.org/atomgraph/linkeddatahub/apps#>
DELETE { ?app lapp:allowRead ?value } WHERE { ?app lapp:allowRead ?value }" \
      "${END_USER_BASE_URL}settings"
    purge_cache "$END_USER_VARNISH_SERVICE"
    purge_cache "$FRONTEND_VARNISH_SERVICE"
}
trap reset_allow_read EXIT

# baseline: without allowRead, a certless GET of the owner-only /settings is denied (403)
before=$(curl -k -w "%{http_code}" -o /dev/null -s -H "Accept: application/n-triples" "${END_USER_BASE_URL}settings")
echo "DEBUG: baseline certless GET /settings - Expected: $STATUS_FORBIDDEN Got: $before"
echo "$before" | grep -qE "^($STATUS_FORBIDDEN)$"

# owner enables allowRead on the end-user application
curl -k -s -f -o /dev/null \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -X PATCH \
  -H "Content-Type: application/sparql-update" \
  -d "PREFIX lapp: <https://w3id.org/atomgraph/linkeddatahub/apps#>
INSERT { ?app lapp:allowRead true } WHERE { ?app a lapp:EndUserApplication }" \
  "${END_USER_BASE_URL}settings"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# with allowRead=true, the same certless GET now skips authorization and succeeds (200)
after=$(curl -k -w "%{http_code}" -o /dev/null -s -H "Accept: application/n-triples" "${END_USER_BASE_URL}settings")
echo "DEBUG: allowRead certless GET /settings - Expected: $STATUS_OK Got: $after"
echo "$after" | grep -qE "^($STATUS_OK)$"

# allowRead only affects GET/HEAD: a certless write (PATCH) is still denied (403)
write=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -X PATCH \
  -H "Content-Type: application/sparql-update" \
  -d "PREFIX lapp: <https://w3id.org/atomgraph/linkeddatahub/apps#>
INSERT { ?app lapp:allowRead true } WHERE { ?app a lapp:EndUserApplication }" \
  "${END_USER_BASE_URL}settings")
echo "DEBUG: allowRead certless PATCH /settings - Expected: $STATUS_FORBIDDEN Got: $write"
echo "$write" | grep -qE "^($STATUS_FORBIDDEN)$"
