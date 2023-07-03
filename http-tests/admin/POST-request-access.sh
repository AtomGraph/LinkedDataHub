#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"

curl -w "%{http_code}\n" -o /dev/null -k -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: text/turtle" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "rdf=" \
  --data-urlencode "sb=request" \
  --data-urlencode "pu=http://www.w3.org/1999/02/22-rdf-syntax-ns#type" \
  --data-urlencode "ou=https://w3id.org/atomgraph/linkeddatahub/admin/acl#AuthorizationRequest" \
  --data-urlencode "pu=https://w3id.org/atomgraph/linkeddatahub/admin/acl#requestAccessTo" \
  --data-urlencode "ou=${END_USER_BASE_URL}sparql" \
  --data-urlencode "pu=https://w3id.org/atomgraph/linkeddatahub/admin/acl#requestAccessToClass" \
  --data-urlencode "ou=https://w3id.org/atomgraph/linkeddatahub/default#Root" \
  --data-urlencode "ou=https://www.w3.org/ns/ldt/document-hierarchy#Container" \
  --data-urlencode "ou=https://www.w3.org/ns/ldt/document-hierarchy#Item" \
  --data-urlencode "ou=http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#FileDataObject" \
  --data-urlencode "pu=https://w3id.org/atomgraph/linkeddatahub/admin/acl#requestMode" \
  --data-urlencode "ou=http://www.w3.org/ns/auth/acl#Read" \
  --data-urlencode "ou=http://www.w3.org/ns/auth/acl#Write" \
  --data-urlencode "pu=http://www.w3.org/2000/01/rdf-schema#label" \
  --data-urlencode "ol=Access request by Test Agent" \
  --data-urlencode "pu=https://w3id.org/atomgraph/linkeddatahub/admin/acl#requestAgent" \
  --data-urlencode "ou=${AGENT_URI}" \
  --data-urlencode "sb=request-item" \
  --data-urlencode "pu=http://www.w3.org/1999/02/22-rdf-syntax-ns#type" \
  --data-urlencode "ou=https://www.w3.org/ns/ldt/document-hierarchy#Item" \
  --data-urlencode "pu=http://rdfs.org/sioc/ns#has_container" \
  --data-urlencode "ou=${ADMIN_BASE_URL}acl/authorization-requests/" \
  --data-urlencode "pu=http://xmlns.com/foaf/0.1/primaryTopic" \
  --data-urlencode "ob=request" \
  "${ADMIN_BASE_URL}request%20access" \
| grep -q "$STATUS_OK"