#!/bin/bash
set -e

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_backend_cache "$END_USER_VARNISH_SERVICE"
purge_backend_cache "$ADMIN_VARNISH_SERVICE"

# owner access

curl --head -k -w "%{http_code}\n" -f -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: text/turtle" \
  "${ADMIN_BASE_URL}model/ontologies/namespace/" \
| grep -q "$STATUS_OK"

# authenticated agent access

curl --head -k -w "%{http_code}\n" -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: text/turtle" \
  "${ADMIN_BASE_URL}model/ontologies/namespace/" \
| grep -q "$STATUS_OK"

# public access

curl --head -k -w "%{http_code}\n" -f -s \
  -H "Accept: text/turtle" \
  "${ADMIN_BASE_URL}model/ontologies/namespace/" \
| grep -q "$STATUS_OK"