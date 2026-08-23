#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# Federation negative: the same cross-instance delta without an authenticated agent is refused -
# B's access control arbitrates the meeting, not the proxy.

remote_base="https://test.localhost:4443/"

item=$(create-item.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$remote_base" \
  --title "Federation negative target" \
  --slug "federation-403-$(date +%s)" \
  --container "$remote_base")

update=$(cat <<EOF
PREFIX dct: <http://purl.org/dc/terms/>

INSERT
{
  <${item}> dct:description "Should not land" .
}
WHERE {}
EOF
)

curl -k -w "%{http_code}\n" -o /dev/null -s \
  -X PATCH \
  -H 'Content-Type: application/sparql-update' \
  --url-query "uri=${item}" \
  --data-binary "$update" \
  "$END_USER_BASE_URL" \
| grep -qE "$STATUS_UNAUTHORIZED|$STATUS_FORBIDDEN"

# the delta did not land

if curl -k -f -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$item" \
| grep -q "Should not land"; then
  echo "DEBUG: unauthenticated delta landed on the remote document"
  exit 1
fi
