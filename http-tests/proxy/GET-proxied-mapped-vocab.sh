#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# add agent to the readers group to be able to read documents

add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/readers/"

# well-known vocab terms that are statically prefix-mapped to bundled documents
# (src/main/resources/prefix-mapping.ttl), so the proxy serves them straight from
# that cache (isMapped branch) instead of dereferencing the network.

# dct:title - slash-based namespace (http://purl.org/dc/terms/); the proxy request
# URI equals the term URI itself

dct_response=$(curl -k -f -s \
  -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  --data-urlencode "uri=http://purl.org/dc/terms/title" \
  "$END_USER_BASE_URL")

echo "$dct_response" | grep -q '<http://purl.org/dc/terms/title> <http://www.w3.org/2000/01/rdf-schema#label> "Title"'

# foaf:Person - also slash-based (http://xmlns.com/foaf/0.1/)

foaf_response=$(curl -k -f -s \
  -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  --data-urlencode "uri=http://xmlns.com/foaf/0.1/Person" \
  "$END_USER_BASE_URL")

echo "$foaf_response" | grep -q '<http://xmlns.com/foaf/0.1/Person> <http://www.w3.org/2000/01/rdf-schema#label> "Person"'

# skos:Concept - hash-based namespace (http://www.w3.org/2004/02/skos/core#); the
# request carries a #fragment that ProxyRequestFilter strips before matching the
# mapped prefix, and the bundled document declares terms as relative (#Concept)
# under its own xml:base, so this also confirms that base resolves back to the
# full hash URI rather than leaking a bare fragment or the classpath location

skos_response=$(curl -k -f -s \
  -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  --data-urlencode "uri=http://www.w3.org/2004/02/skos/core#Concept" \
  "$END_USER_BASE_URL")

echo "$skos_response" | grep -q '<http://www.w3.org/2004/02/skos/core#Concept> <http://www.w3.org/2000/01/rdf-schema#label> "Concept"'
