#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A write evicts the document from the frontend cache, so an anonymous reader sees it at once rather than when the cached
# copy expires

container=$(ldh create container \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Before" \
  --slug "public-$(uuidgen | tr '[:upper:]' '[:lower:]')" \
  --parent "$END_USER_BASE_URL")

ldh admin create authorization \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --label "Public read access" \
  --agent-class 'http://xmlns.com/foaf/0.1/Agent' \
  --to "$container" \
  --read \
  "$ADMIN_BASE_URL" > /dev/null

# read anonymously twice: the second read is answered by the frontend cache

curl -k -s -f -o /dev/null -H "Accept: application/n-triples" "$container"

response=$(curl -k -s -f -D - -H "Accept: application/n-triples" "$container")
ids=$(grep -i '^x-varnish:' <<< "$response" | tr -d '\r' | sed 's/^[^:]*: *//' | wc -w | tr -d ' ')

echo "DEBUG: anonymous GET, second time. Expected X-Varnish ids: 2 (hit)  Got: $ids"
if [ "$ids" != "2" ]; then
  exit 1
fi
if ! grep -q '"Before"' <<< "$response"; then
  echo "DEBUG: the title is not in the cached response"
  exit 1
fi

# change the title as the owner

update=$(cat <<EOF
PREFIX dct: <http://purl.org/dc/terms/>
DELETE { <${container}> dct:title ?title }
INSERT { <${container}> dct:title "After" }
WHERE { <${container}> dct:title ?title }
EOF
)

status=$(curl -k -s -o /dev/null -w "%{http_code}" \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -X PATCH \
  -H "Content-Type: application/sparql-update" \
  -H "Accept: application/n-triples" \
  -H "If-Match: $(etag "$container" "$OWNER_CERT_FILE" "$OWNER_CERT_PWD" "application/n-triples")" \
  --data-binary "$update" \
  "$container")

echo "DEBUG: PATCH Expected: $STATUS_NO_CONTENT  Got: $status"
if [ "$status" != "$STATUS_NO_CONTENT" ]; then
  exit 1
fi

# the anonymous reader sees the change

response=$(curl -k -s -f -H "Accept: application/n-triples" "$container")

echo "DEBUG: anonymous GET after the write. Expected: \"After\"  Got: $(grep 'title' <<< "$response" || true)"
if ! grep -q '"After"' <<< "$response"; then
  exit 1
fi
if grep -q '"Before"' <<< "$response"; then
  exit 1
fi
