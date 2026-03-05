#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# POST /add with a reader should return 403
# The write-append authorization grants acl:Append to owners and writers groups only;
# readers only have acl:Read on dh:Item/Container and /sparql, not on /add

add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/readers/"

curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "rdf=" \
  --data-urlencode "sb=clone" \
  --data-urlencode "pu=http://purl.org/dc/terms/source" \
  --data-urlencode "ou=https://orcid.org/0000-0003-1750-9906" \
  --data-urlencode "pu=http://www.w3.org/ns/sparql-service-description#name" \
  --data-urlencode "ou=${END_USER_BASE_URL}" \
  "${END_USER_BASE_URL}add" \
| grep -q "$STATUS_FORBIDDEN"
