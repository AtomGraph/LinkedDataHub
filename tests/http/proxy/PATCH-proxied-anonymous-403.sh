#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# Regression: ProxyRequestFilter runs before AuthorizationFilter and aborts the request, so no
# local ACL check ever sees a proxied request - by design, the origin's ACL decides. But the
# upstream request carried the platform's own client certificate whether or not the caller was
# authenticated, with On-Behalf-Of only for a caller who was. An anonymous write therefore reached
# the origin as the secretary, a member of every dataspace's writers group, and was applied.
#
# Anyone could edit any document the platform's own certificate may edit, in any dataspace the
# proxy reaches, by writing to ?uri= without a certificate. The origin has to see the caller as
# what it is - nobody - and refuse.

# a document only the owner may edit

item=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Proxied write target" \
  --slug "proxied-write-target-$(date +%s)" \
  --container "$END_USER_BASE_URL")

update=$(cat <<EOF
PREFIX dct: <http://purl.org/dc/terms/>

INSERT
{
  <${item}> dct:description "Written by nobody" .
}
WHERE {}
EOF
)

# the validator the write has to quote is read as the owner: the claim is about the write being
# refused for lack of an agent, not for lack of a precondition

tag=$(etag "$item" "$OWNER_CERT_FILE" "$OWNER_CERT_PWD" "application/n-triples")

# through the admin origin's proxy, so the request crosses origins and is forwarded

status=$(curl -k -s \
  -o /dev/null \
  -w "%{http_code}" \
  -X PATCH \
  -H "Accept: application/n-triples" \
  -H "If-Match: $tag" \
  -H 'Content-Type: application/sparql-update' \
  --url-query "uri=${item}" \
  --data-binary "$update" \
  "$ADMIN_BASE_URL")

if ! echo "$status" | grep -qE "^($STATUS_UNAUTHORIZED|$STATUS_FORBIDDEN)$"; then
    echo "Expected $STATUS_UNAUTHORIZED or $STATUS_FORBIDDEN for an anonymous proxied write, got $status"
    exit 1
fi

# and the delta did not land

if curl -k -f -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$item" \
| grep -q "Written by nobody"; then
    echo "The anonymous proxied write was applied"
    exit 1
fi
