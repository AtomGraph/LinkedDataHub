#!/bin/bash

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"

curl -w "%{http_code}\n" -k -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "rdf=" \
  --data-urlencode "sb=request" \
  --data-urlencode "pu=http://www.w3.org/1999/02/22-rdf-syntax-ns#type" \
  --data-urlencode "ou=https://localhost:4443/admin/ns#AuthorizationRequest" \
  --data-urlencode "pu=http://rdfs.org/sioc/ns#has_container" \
  --data-urlencode "ou=https://localhost:4443/admin/acl/authorization-requests/" \
  --data-urlencode "pu=https://w3id.org/atomgraph/linkeddatahub/admin/acl/domain#requestAccessTo" \
  --data-urlencode "ou=https://localhost:4443/" \
  --data-urlencode "pu=https://w3id.org/atomgraph/linkeddatahub/admin/acl/domain#requestMode" \
  --data-urlencode "ou=http://www.w3.org/ns/auth/acl#Read" \
  --data-urlencode "ou=http://www.w3.org/ns/auth/acl#Write" \
  --data-urlencode "pu=https://w3id.org/atomgraph/linkeddatahub/admin/acl/domain#requestAgent" \
  --data-urlencode "ou=${AGENT_URI}" \
  "${ADMIN_BASE_URL}request%20access?forClass=https%3A%2F%2Flocalhost%3A4443%2Fadmin%2Fns%23AuthorizationRequest" \
| grep -q "${STATUS_OK}"