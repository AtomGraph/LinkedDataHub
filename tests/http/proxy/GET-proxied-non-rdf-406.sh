#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# add agent to the readers group to be able to read documents

ldh admin add agent \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/readers/"

# Regression: when an upstream proxied URI returns a non-RDF body (an image) regardless of Accept,
# ProxyRequestFilter must answer 406 to a client that asked for RDF, as it does for HTML without
# JSON-LD. Relaying the image bytes as 200 made the object block decode a PNG as RDF/XML and fail
# instead of embedding the URI. A client that accepts the upstream type still gets the bytes.

target_uri='https://www.w3.org/Icons/w3c_home.png'

# 1. Accept: RDF only -> 406

status=$(curl -k -s -G -w "%{http_code}" -o /dev/null \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/rdf+xml" \
  --data-urlencode "uri=${target_uri}" \
  "$END_USER_BASE_URL")

if [ "$status" != "406" ]; then
    echo "DEBUG: GET Accept: application/rdf+xml expected 406, got $status"
    exit 1
fi

# 2. HEAD answers the same as GET

status=$(curl -k -s -G --head -w "%{http_code}" -o /dev/null \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/rdf+xml" \
  --data-urlencode "uri=${target_uri}" \
  "$END_USER_BASE_URL")

if [ "$status" != "406" ]; then
    echo "DEBUG: HEAD Accept: application/rdf+xml expected 406, got $status"
    exit 1
fi

# 3. Accept: image/png -> the bytes, as the upstream typed them (the upstream redirects, which the proxy follows)

content_type=$(curl -k -f -s -G -w "%{content_type}" -o /dev/null \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: image/png" \
  --data-urlencode "uri=${target_uri}" \
  "$END_USER_BASE_URL")

if [ "$content_type" != "image/png" ]; then
    echo "DEBUG: GET Accept: image/png expected image/png, got $content_type"
    exit 1
fi
