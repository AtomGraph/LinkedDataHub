#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# access is unauthorized

(
curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Content-Type: application/n-triples" \
  -H "Accept: application/n-triples" \
  -X PUT \
   --data-binary @- \
  "$END_USER_BASE_URL" <<EOF
<http://s> <http://p> <http://o> .
EOF
) \
| grep -q "$STATUS_FORBIDDEN"

# create fake test.localhost authorization (should be filtered out)

create-authorization.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "https://admin.test.localhost:4443/" \
  --label "Fake PUT class authorization from test.localhost" \
  --agent "$AGENT_URI" \
  --to-all-in "https://w3id.org/atomgraph/linkeddatahub/default#Root" \
  --write

# access is still denied (fake authorization filtered out)

(
curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Content-Type: application/n-triples" \
  -H "Accept: application/n-triples" \
  -X PUT \
   --data-binary @- \
  "$END_USER_BASE_URL" <<EOF
<http://s> <http://p> <http://o> .
EOF
) \
| grep -q "$STATUS_FORBIDDEN"

# create real localhost authorization

create-authorization.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --label "PUT authorization" \
  --agent "$AGENT_URI" \
  --to-all-in "https://w3id.org/atomgraph/linkeddatahub/default#Root" \
  --write

# get the graph content

root_ntriples=$(get.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --accept 'application/n-triples' \
  "$END_USER_BASE_URL")

# access is allowed after real authorization is created
# request body with document instance is required

echo "$root_ntriples" \
| curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Content-Type: application/n-triples" \
  -H "Accept: application/n-triples" \
  -X PUT \
  -d @- \
  "$END_USER_BASE_URL" \
| grep -q "$STATUS_OK"