#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# PATCH /settings without a certificate should return 401
# Only owners have acl:Write access to /settings

curl -k -w "%{http_code}\n" -o /dev/null -s \
  -X PATCH \
  -H "Content-Type: application/sparql-update" \
  -d "PREFIX dct: <http://purl.org/dc/terms/>
DELETE { ?app dct:title ?title }
INSERT { ?app dct:title \"Unauthorized\" }
WHERE { ?app dct:title ?title }" \
  "${END_USER_BASE_URL}settings" \
| grep -q "$STATUS_UNAUTHORIZED"
