#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# access is unauthorized

curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$END_USER_BASE_URL" \
| grep -q "$STATUS_FORBIDDEN"

# create fake test.localhost authorization (should be filtered out)

create-authorization.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "https://admin.test.localhost:4443/" \
  --label "Fake GET Container authorization from test.localhost" \
  --agent "$AGENT_URI" \
  --to-all-in "https://w3id.org/atomgraph/linkeddatahub/default#Root" \
  --read

# access is still denied (fake authorization filtered out)

curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$END_USER_BASE_URL" \
| grep -q "$STATUS_FORBIDDEN"

# create real localhost authorization

create-authorization.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --label "GET Container authorization" \
  --agent "$AGENT_URI" \
  --to-all-in "https://w3id.org/atomgraph/linkeddatahub/default#Root" \
  --read

# access is allowed after real authorization is created

curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$END_USER_BASE_URL" \
| grep -q "$STATUS_OK"