#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# An ID token cookie is only evidence of an identity once its signature verifies against the provider's keys, and
# nothing it claims - subject, audience, issuer, expiry - is acted upon before that. An unsigned token carrying a
# past expiry must leave the caller anonymous: no authentication, and no refresh on the subject's behalf.
# Needs no OAuth provider: without one the cookie is not read at all, and the outcome is the same.

base64url()
{
    printf '%s' "$1" | openssl base64 -A | tr '+/' '-_' | tr -d '='
}

# the client ID is in the authorization redirect when Google sign-in is configured; any value otherwise
client_id="test-client-id"
location=$(curl -k -s -o /dev/null -w "%{redirect_url}" "${END_USER_BASE_URL}oauth2/authorize/google" || true)
if [[ "$location" == *"client_id="* ]]; then
    client_id=$(echo "$location" | sed -E 's/.*[?&]client_id=([^&]*).*/\1/')
fi
echo "DEBUG: client_id: $client_id"

header=$(base64url '{"alg":"none","typ":"JWT","kid":"forged"}')
payload=$(base64url "{\"iss\":\"https://accounts.google.com\",\"aud\":\"${client_id}\",\"sub\":\"forged-subject-$(date +%s)\",\"iat\":1000000000,\"exp\":1000003600}")
forged_token="${header}.${payload}."
echo "DEBUG: forged token: $forged_token"

# a document nobody but the owner may read

item=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Owner-only document" \
  --slug "forged-id-token-$(date +%s)" \
  --container "$END_USER_BASE_URL")

echo "DEBUG: item: $item"

response_headers=$(mktemp)

status=$(curl -k -s \
  -o /dev/null \
  -w "%{http_code}" \
  -D "$response_headers" \
  -H "Accept: application/n-triples" \
  -H "Cookie: LinkedDataHub.id_token=${forged_token}" \
  "$item")

echo "DEBUG: expected: $STATUS_UNAUTHORIZED or $STATUS_FORBIDDEN"
echo "DEBUG: got: $status"
cat "$response_headers"

if ! echo "$status" | grep -qE "^($STATUS_UNAUTHORIZED|$STATUS_FORBIDDEN)$"; then
    echo "DEBUG: a forged ID token was not treated as anonymous"
    exit 1
fi

# an authenticated response names its agent in a Link header; an anonymous one does not

if grep -qi "rel=\"http://www.w3.org/ns/auth/acl#agent\"" "$response_headers"; then
    echo "DEBUG: the response asserts an agent for the forged ID token"
    exit 1
fi

rm "$response_headers"
