#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# PATCH /settings with a writer (not owner) should return 403
# /settings is only in the full-control authorization which is restricted to owners

add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PATCH \
  -H "Content-Type: application/sparql-update" \
  -d "PREFIX dct: <http://purl.org/dc/terms/>
DELETE { ?app dct:title ?title }
INSERT { ?app dct:title \"Unauthorized\" }
WHERE { ?app dct:title ?title }" \
  "${END_USER_BASE_URL}settings" \
| grep -q "$STATUS_FORBIDDEN"
