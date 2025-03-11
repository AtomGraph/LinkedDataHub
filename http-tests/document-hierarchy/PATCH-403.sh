#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# check that write access without authorization is forbidden

update=$(cat <<EOF
PREFIX  rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

INSERT
{
  <${END_USER_BASE_URL}> rdf:_2 <${END_USER_BASE_URL}#whateverest>
}
WHERE
{}
EOF
)

curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PATCH \
  -H "Content-Type: application/sparql-update" \
  "$END_USER_BASE_URL" \
   --data-binary "$update" \
| grep -q "$STATUS_FORBIDDEN"