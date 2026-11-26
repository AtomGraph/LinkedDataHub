#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# An empty append through the proxy is answered as it is directly. The proxy forwarded a body only when Jersey reported
# one, which it does not for an empty body, so the POST reached the origin with no Content-Type and was refused with
# 400 (found by formal/acl-conformance-proxied.sh, seed 19908, step 19). The request goes as ?uri= on the admin base:
# one on the document's own dataspace is served as the document, not proxied.

item=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Empty append" \
  --slug "empty-append-$(date +%s)" \
  --container "$END_USER_BASE_URL")

append() # <url arguments...>: an empty N-Triples POST as the owner, with the document's current tag; prints the status
{
  curl -k -s -o /dev/null -w '%{http_code}' \
    -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
    -X POST \
    -H "Content-Type: application/n-triples" \
    -H "Accept: application/n-triples" \
    -H "If-Match: $(etag "$item" "$OWNER_CERT_FILE" "$OWNER_CERT_PWD" 'application/n-triples')" \
    --data-binary @/dev/null \
    "$@"
}

direct=$(append "$item")
echo "DEBUG: empty append directly - Expected: $STATUS_NO_CONTENT  Got: $direct"
[ "$direct" = "$STATUS_NO_CONTENT" ] || exit 1

proxied=$(append --url-query "uri=$item" "$ADMIN_BASE_URL")
echo "DEBUG: empty append through the proxy - Expected: $STATUS_NO_CONTENT  Got: $proxied"
[ "$proxied" = "$STATUS_NO_CONTENT" ] || exit 1
