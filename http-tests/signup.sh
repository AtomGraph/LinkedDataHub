#!/bin/bash
set -euxo pipefail

email="john@doe.com"
given_name="John"
family_name="Doe"
password="$AGENT_CERT_PWD"
title="whatever"
uuid=$(uuidgen | tr '[:upper:]' '[:lower:]')
agent_p12_cert=$(mktemp)

curl -k -s \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "rdf=" \
  --data-urlencode "sb=agent" \
  --data-urlencode "pu=http://www.w3.org/1999/02/22-rdf-syntax-ns#type" \
  --data-urlencode "ou=https://w3id.org/atomgraph/linkeddatahub/admin#Person" \
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
  --data-urlencode "pu=https://w3id.org/atomgraph/linkeddatahub/admin/acl/domain#password" \
  --data-urlencode "ol=${password}" \
  --data-urlencode "pu=https://w3id.org/atomgraph/linkeddatahub/admin/acl/domain#password" \
  --data-urlencode "ol=${password}" \
  --data-urlencode "sb=agent" \
  --data-urlencode "sb=doc" \
  --data-urlencode "pu=http://www.w3.org/1999/02/22-rdf-syntax-ns#type" \
  --data-urlencode "ou=https://w3id.org/atomgraph/linkeddatahub/admin#Item" \
  --data-urlencode "pu=http://purl.org/dc/terms/description" \
  --data-urlencode "lt=http://www.w3.org/2001/XMLSchema#string" \
  --data-urlencode "pu=http://rdfs.org/sioc/ns#has_container" \
  --data-urlencode "ou=${ADMIN_BASE_URL}acl/agents/" \
  --data-urlencode "pu=http://purl.org/dc/terms/title" \
  --data-urlencode "ol=${title}" \
  --data-urlencode "lt=http://www.w3.org/2001/XMLSchema#string" \
  --data-urlencode "pu=https://www.w3.org/ns/ldt/document-hierarchy/domain#slug" \
  --data-urlencode "ol=${uuid}" \
  --data-urlencode "pu=http://xmlns.com/foaf/0.1/primaryTopic" \
  --data-urlencode "ob=agent" \
  "${ADMIN_BASE_URL}sign%20up?forClass=https%3A%2F%2Fw3id.org%2Fatomgraph%2Flinkeddatahub%2Fadmin%23Person&download=true" \
> "$agent_p12_cert"

# https://w3id.org/atomgraph/linkeddatahub/admin#Person - include this here so we get a match when replacing namespace URIs

# convert PKCS12 to PEM

openssl pkcs12 \
  -in "$agent_p12_cert" \
  -out "$AGENT_CERT_FILE" \
  -passin pass:"$AGENT_CERT_PWD" \
  -passout pass:"$AGENT_CERT_PWD"

rm "$agent_p12_cert"