#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A POST appends to a document, and the document's sioc:has_parent and sioc:has_container are not the payload's to
# assert: the server drops them from the payload and keeps the stored ones, while the rest of the payload is appended.

container=$(ldh create container \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Other" \
  --slug "other" \
  --parent "$END_USER_BASE_URL")

item=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Contained" \
  --slug "post-containment" \
  --container "$END_USER_BASE_URL")

actual=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "If-Match: $(etag "$item" "$OWNER_CERT_FILE" "$OWNER_CERT_PWD" "application/n-triples")" \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  --data-binary @- \
  "$item" <<EOF
<${item}> <http://rdfs.org/sioc/ns#has_container> <${container}> .
<${item}> <http://rdfs.org/sioc/ns#has_parent> <${container}> .
<${item}> <http://example.com/default-predicate> "named object POST" .
EOF
)
echo "DEBUG: POST: Expected: $STATUS_NO_CONTENT"
echo "DEBUG: POST: Got: $actual"
[ "$actual" = "$STATUS_NO_CONTENT" ] || exit 1

item_ntriples=$(ldh get \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --accept 'application/n-triples' \
  "$item")
containment=$(echo "$item_ntriples" | grep -E "^<${item}> <http://rdfs.org/sioc/ns#has_(parent|container)> " || true)
echo "DEBUG: Expected containment: <${item}> <http://rdfs.org/sioc/ns#has_container> <${END_USER_BASE_URL}> ."
echo "DEBUG: Got containment: $containment"
[ "$containment" = "<${item}> <http://rdfs.org/sioc/ns#has_container> <${END_USER_BASE_URL}> ." ] || exit 1

# the rest of the payload was appended

echo "$item_ntriples" | grep -q "<${item}> <http://example.com/default-predicate> \"named object POST\""
