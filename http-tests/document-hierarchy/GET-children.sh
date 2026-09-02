#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# add agent to the writers group

ldh admin acl add-agent-to-group \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

# execute SPARQL query to retrieve children of the end-user base URL to prime the Varnish cache

query="DESCRIBE * WHERE { SELECT DISTINCT ?child ?thing WHERE { GRAPH ?childGraph { { ?child <http://rdfs.org/sioc/ns#has_parent> <${END_USER_BASE_URL}>. } UNION { ?child <http://rdfs.org/sioc/ns#has_container> <${END_USER_BASE_URL}>. } ?child <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ?Type. OPTIONAL { ?child <http://purl.org/dc/terms/title> ?title. } OPTIONAL { ?child <http://xmlns.com/foaf/0.1/primaryTopic> ?thing. } } } ORDER BY (?title) LIMIT 20 }"

# URL-encode query with uppercase hex digits (matching Java's UriComponent.encode())
# Note: We must construct the URL manually instead of using curl's -G --data-urlencode because curl normalizes percent-encoding to lowercase,
# which won't match the uppercase percent-encoding that Java produces in cache invalidation BAN requests
encoded_query=$(python -c "import urllib.parse; print(urllib.parse.quote('''$query''', safe=''))")

curl -k -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "${END_USER_BASE_URL}sparql?query=${encoded_query}" \
  > /dev/null

# create container

slug="test-children-query"

container=$(ldh create-container \
  -f "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Test Children Query" \
  --slug "$slug" \
  --parent "$END_USER_BASE_URL")

# execute SPARQL query again - the new container should appear (verifies cache invalidation)
#
# The assertion reads from a here-string rather than piping curl into `grep -q`: `grep -q`
# closes the pipe on its first match, and with `set -o pipefail` the SIGPIPE'd curl fails
# the whole pipeline whenever it is still writing at that moment.

response=$(curl -k -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "${END_USER_BASE_URL}sparql?query=${encoded_query}")

if ! grep -qF "<${container}>" <<< "$response"; then
  exit 1
fi
