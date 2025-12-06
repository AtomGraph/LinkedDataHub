#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# add agent to the writers group

add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

# create container

slug="test-children-query"

container=$(create-container.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Test Children Query" \
  --slug "$slug" \
  --parent "$END_USER_BASE_URL")

# execute SPARQL query to retrieve children of the end-user base URL

query="DESCRIBE * WHERE { SELECT DISTINCT ?child ?thing WHERE { GRAPH ?childGraph { { ?child <http://rdfs.org/sioc/ns#has_parent> <${END_USER_BASE_URL}>. } UNION { ?child <http://rdfs.org/sioc/ns#has_container> <${END_USER_BASE_URL}>. } ?child <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ?Type. OPTIONAL { ?child <http://purl.org/dc/terms/title> ?title. } OPTIONAL { ?child <http://xmlns.com/foaf/0.1/primaryTopic> ?thing. } } } ORDER BY (?title) LIMIT 20 }"

curl -k -f -s \
  -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H 'Accept: application/n-triples' \
  --data-urlencode "query=$query" \
  "${END_USER_BASE_URL}sparql" \
| grep -q "<${container}>"
