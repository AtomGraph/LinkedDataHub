#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# Public OAuth2 login must stay reachable without a certificate. The oauth2-login authorization (admin.trig)
# grants foaf:Agent Read to the login endpoints via acl:accessTo.
# This is the regression guard for the authorization fix: the $Type sentinel that disables acl:accessToClass
# for typeless resources (AuthorizationFilter) must NOT also block these endpoints, which is why oauth2-login
# had to move from acl:accessToClass to acl:accessTo in lockstep. A permitted request reaches the resource,
# which returns 400 (missing OAuth 'state' query param); an ACL denial would be 403.

for provider in google orcid
do
    actual=$(curl -k -w "%{http_code}" -o /dev/null -s \
      -H "Accept: application/xhtml+xml" \
      "${END_USER_BASE_URL}oauth2/login/${provider}")
    expected="$STATUS_BAD_REQUEST"
    echo "DEBUG: ${provider} Expected: $expected"
    echo "DEBUG: ${provider} Got: $actual"
    echo "$actual" | grep -qE "^(${expected})$"
done
