#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# Revoking public read access takes effect at once: the frontend cache must not go on serving anonymous readers the copy
# it stored while the document was public. The write is to the admin dataspace, nowhere near the document's URL

container=$(ldh create container \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Public" \
  --slug "public-$(uuidgen | tr '[:upper:]' '[:lower:]')" \
  --parent "$END_USER_BASE_URL")

authorization=$(ldh admin create authorization \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --label "Public read access" \
  --agent-class 'http://xmlns.com/foaf/0.1/Agent' \
  --to "$container" \
  --read \
  "$ADMIN_BASE_URL")

# read anonymously twice: the second read is answered by the frontend cache

curl -k -s -f -o /dev/null -H "Accept: application/n-triples" "$container"

ids=$(curl -k -s -f -D - -o /dev/null -H "Accept: application/n-triples" "$container" \
| grep -i '^x-varnish:' | tr -d '\r' | sed 's/^[^:]*: *//' | wc -w | tr -d ' ')

echo "DEBUG: anonymous GET, second time. Expected X-Varnish ids: 2 (hit)  Got: $ids"
if [ "$ids" != "2" ]; then
  exit 1
fi

# revoke the public authorization

status=$(curl -k -s -o /dev/null -w "%{http_code}" \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -X DELETE \
  -H "Accept: application/n-triples" \
  -H "If-Match: $(etag "$authorization" "$OWNER_CERT_FILE" "$OWNER_CERT_PWD" "application/n-triples")" \
  "$authorization")

echo "DEBUG: DELETE <$authorization> Expected: $STATUS_NO_CONTENT  Got: $status"
if [ "$status" != "$STATUS_NO_CONTENT" ]; then
  exit 1
fi

# the anonymous reader is refused

status=$(curl -k -s -o /dev/null -w "%{http_code}" -H "Accept: application/n-triples" "$container")

echo "DEBUG: anonymous GET after the revocation. Expected: $STATUS_FORBIDDEN  Got: $status"
if [ "$status" != "$STATUS_FORBIDDEN" ]; then
  exit 1
fi
