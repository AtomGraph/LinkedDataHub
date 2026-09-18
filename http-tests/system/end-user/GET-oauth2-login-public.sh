#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# Public OAuth2 login must stay reachable without a certificate. The end-user oauth2 authorization
# (namespace-ontology.trig.template) grants foaf:Agent Read to the login endpoints via acl:accessTo.
# This is the regression guard for the fail-closed default that disables acl:accessToClass for typeless
# resources: it must NOT also block these endpoints. The guard is simply that authorization does not DENY
# the request - any status other than 403 means the ACL let it through. The exact code varies with config
# (400 missing OAuth 'state' when the provider is configured; 404 when it is not, since the endpoint then
# falls through to the document handler), so we only assert it is not the 403 an ACL denial would produce.

for provider in google orcid
do
    actual=$(curl -k -w "%{http_code}" -o /dev/null -s \
      -H "Accept: application/xhtml+xml" \
      "${END_USER_BASE_URL}oauth2/login/${provider}")
    echo "DEBUG: ${provider} Got: $actual (must not be $STATUS_FORBIDDEN)"
    [ "$actual" != "$STATUS_FORBIDDEN" ]
done
