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
  -X DELETE \
  "$END_USER_BASE_URL" \
| grep -q "$STATUS_FORBIDDEN"

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/acl"

# create group

group_doc=$(./create-group.sh \
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

popd > /dev/null

pushd . > /dev/null && cd "$SCRIPT_ROOT"

# create container

slug="test"

container=$(./create-container.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Test" \
  --slug "$slug" \
  --parent "$END_USER_BASE_URL")

popd > /dev/null

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/acl"

# create authorization

./create-authorization.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --label "DELETE authorization" \
  --agent-group "$group" \
  --to "$container" \
  --write

popd > /dev/null

# access is allowed after authorization is created

curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  -X DELETE \
  "$container" \
| grep -q "$STATUS_NO_CONTENT"