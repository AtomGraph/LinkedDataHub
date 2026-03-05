#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# POST /generate with a signed-up agent not in any group should return 403
# The write-append authorization grants acl:Append to owners and writers groups only

(
curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X POST \
  -H "Content-Type: text/turtle" \
  --data-binary @- \
  "${END_USER_BASE_URL}generate" <<EOF
@prefix sioc: <http://rdfs.org/sioc/ns#> .
[] sioc:has_parent <${END_USER_BASE_URL}> .
EOF
) \
| grep -q "$STATUS_FORBIDDEN"
