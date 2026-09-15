#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# Federation negative: B's access control arbitrates the meeting. The signed-up agent is a
# federation identity that is NOT granted write on B (no authorization is created for it on
# test.localhost). Its delegated cross-instance PATCH is refused - the proxy forwards the
# identity, but B's ACL, not the proxy, decides. A truly anonymous request cannot express this:
# a proxied request with no user certificate rides the server's own credential to the origin.

remote_base="https://test.localhost:4443/"

# create the target on B as the owner (authorized), so only the *writer* differs from the
# positive test

item=$(ldh create item \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  -b "$remote_base" \
  --title "Federation unauthorized target" \
  --slug "federation-unauthorized-$(date +%s)" \
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

# the agent's delegated write is refused by B (401 if B declines the identity, 403 if it is
# recognised but unauthorized - either way not a success)

code=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -X PATCH \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H 'Content-Type: application/sparql-update' \
  --url-query "uri=${item}" \
  --data-binary "$update" \
  "$END_USER_BASE_URL")

if ! echo "$code" | grep -qE "^($STATUS_UNAUTHORIZED|$STATUS_FORBIDDEN)$"; then
  exit 1
fi

# the delta did not land

if curl -k -f -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$item" \
| grep -q "Should not land"; then
  exit 1
fi
