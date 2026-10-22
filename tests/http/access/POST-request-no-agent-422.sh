#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# a requested authorization without acl:agent cannot be processed

actual=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: text/turtle" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "rdf=" \
  --data-urlencode "sb=request" \
  --data-urlencode "pu=http://www.w3.org/1999/02/22-rdf-syntax-ns#type" \
  --data-urlencode "ou=http://www.w3.org/ns/auth/acl#Authorization" \
  --data-urlencode "pu=http://www.w3.org/ns/auth/acl#accessToClass" \
  --data-urlencode "ou=https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#Item" \
  --data-urlencode "pu=http://www.w3.org/ns/auth/acl#mode" \
  --data-urlencode "ou=http://www.w3.org/ns/auth/acl#Read" \
  "${END_USER_BASE_URL}access/request")
expected="$STATUS_UNPROCESSABLE_ENTITY"
echo "DEBUG: Expected: $expected"
echo "DEBUG: Got: $actual"
[ "$actual" = "$expected" ]
