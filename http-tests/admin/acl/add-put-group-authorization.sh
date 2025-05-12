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

# create group

group_doc=$(create-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --name "Test group" \
  --member "$AGENT_URI")

group=$(curl -s -k \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  "$group_doc" \
  -H "Accept: application/n-triples" \
  | cat \
  | sed -rn "s/<${group_doc//\//\\/}> <http:\/\/xmlns.com\/foaf\/0.1\/primaryTopic> <(.*)> \./\1/p")

# create authorization

create-authorization.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --label "DELETE authorization" \
  --agent-group "$group" \
  --to "$END_USER_BASE_URL" \
  --write

# get the graph content

root_ntriples=$(get.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --accept 'application/n-triples' \
  "$END_USER_BASE_URL")

# access is allowed after authorization is created
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