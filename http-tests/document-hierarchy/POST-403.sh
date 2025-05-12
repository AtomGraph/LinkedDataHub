#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# check that append access without authorization is forbidden

(
curl -k -w "%{http_code}\n" -o /dev/null -s \
  -X POST \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Content-Type: application/n-triples" \
   --data-binary @- \
  "$END_USER_BASE_URL" <<EOF
<http://s> <http://p> <http://o> .
EOF
) \
| grep -q "$STATUS_FORBIDDEN"