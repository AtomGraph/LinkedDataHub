#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# POST /generate without a certificate should return 401
# Only owners and writers have acl:Append access to /generate via write-append authorization

(
curl -k -w "%{http_code}\n" -o /dev/null -s \
  -X POST \
  -H "Content-Type: text/turtle" \
  --data-binary @- \
  "${END_USER_BASE_URL}generate" <<EOF
@prefix sioc: <http://rdfs.org/sioc/ns#> .
[] sioc:has_parent <${END_USER_BASE_URL}> .
EOF
) \
| grep -q "$STATUS_UNAUTHORIZED"
