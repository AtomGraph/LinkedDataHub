#!/usr/bin/env bash
set -euo pipefail

uuid=$(uuidgen | tr '[:upper:]' '[:lower:]')
email="${uuid}@example.com" # randomize email so we don't get an exception because it already exists
given_name="John"
family_name="Doe"
password="$AGENT_CERT_PWD"
title="whatever"

curl -k -s -f \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "rdf=" \
  --data-urlencode "sb=agent" \
  --data-urlencode "pu=http://www.w3.org/1999/02/22-rdf-syntax-ns#type" \
  --data-urlencode "ou=http://xmlns.com/foaf/0.1/Person" \
  --data-urlencode "pu=http://xmlns.com/foaf/0.1/primaryTopic" \
  --data-urlencode "ob=agent" \
  --data-urlencode "pu=http://xmlns.com/foaf/0.1/based_near" \
  --data-urlencode "ou=http://www.wikidata.org/entity/Q35" \
  --data-urlencode "pu=http://xmlns.com/foaf/0.1/mbox" \
  --data-urlencode "ol=${email}" \
  --data-urlencode "pu=http://xmlns.com/foaf/0.1/familyName" \
  --data-urlencode "ol=${family_name}" \
  --data-urlencode "lt=http://www.w3.org/2001/XMLSchema#string" \
  --data-urlencode "pu=http://xmlns.com/foaf/0.1/givenName" \
  --data-urlencode "ol=${given_name}" \
  --data-urlencode "lt=http://www.w3.org/2001/XMLSchema#string" \
  --data-urlencode "pu=http://www.w3.org/ns/auth/cert#key" \
  --data-urlencode "ob=key" \
  --data-urlencode "sb=key" \
  --data-urlencode "pu=https://w3id.org/atomgraph/linkeddatahub/admin/acl#password" \
  --data-urlencode "ol=${password}" \
  --data-urlencode "pu=https://w3id.org/atomgraph/linkeddatahub/admin/acl#password" \
  --data-urlencode "ol=${password}" \
  --data-urlencode "sb=agent" \
  --data-urlencode "sb=doc" \
  --data-urlencode "pu=http://www.w3.org/1999/02/22-rdf-syntax-ns#type" \
  --data-urlencode "ou=https://www.w3.org/ns/ldt/document-hierarchy#Item" \
  --data-urlencode "pu=http://purl.org/dc/terms/description" \
  --data-urlencode "lt=http://www.w3.org/2001/XMLSchema#string" \
  --data-urlencode "pu=http://rdfs.org/sioc/ns#has_container" \
  --data-urlencode "ou=${ADMIN_BASE_URL}acl/agents/" \
  --data-urlencode "pu=http://purl.org/dc/terms/title" \
  --data-urlencode "ol=${title}" \
  --data-urlencode "lt=http://www.w3.org/2001/XMLSchema#string" \
  --data-urlencode "pu=https://www.w3.org/ns/ldt/document-hierarchy#slug" \
  --data-urlencode "ol=${uuid}" \
  --data-urlencode "pu=http://xmlns.com/foaf/0.1/primaryTopic" \
  --data-urlencode "ob=agent" \
  "${ADMIN_BASE_URL}sign%20up?download=true" \
> "$AGENT_CERT_KEYSTORE"

# the signup download is already the PKCS12 keystore ldh reads; derive the PEM the curl
# assertions and webid-uri.sh need

openssl pkcs12 \
  -in "$AGENT_CERT_KEYSTORE" \
  -out "$AGENT_CERT_FILE" \
  -passin pass:"$AGENT_CERT_PWD" \
  -passout pass:"$AGENT_CERT_PWD"