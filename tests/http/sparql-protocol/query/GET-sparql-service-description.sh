#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# GET /sparql with no ?query= returns the SPARQL 1.1 Service Description of the endpoint:
# https://www.w3.org/TR/sparql11-service-description/#accessing
# It names the endpoint it describes and advertises queries only - writes go through the Graph Store Protocol

sd="http://www.w3.org/ns/sparql-service-description#"

for endpoint in "${END_USER_BASE_URL}sparql" "${ADMIN_BASE_URL}sparql"
do
    response=$(curl -k -f -s \
      -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
      -H "Accept: application/n-triples" \
      "$endpoint")

    echo "DEBUG: $endpoint service description:"
    echo "$response"

    # here-strings rather than pipes: grep -q closing the pipe early would SIGPIPE the echo under `set -o pipefail`

    grep -q "<${sd}endpoint> <${endpoint}> \." <<< "$response"
    grep -q "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <${sd}Service> \." <<< "$response"
    grep -q "<${sd}supportedLanguage> <${sd}SPARQL11Query> \." <<< "$response"
    ! grep -q "<${sd}SPARQL11Update>" <<< "$response"
    grep -q "<${sd}resultFormat> <http://www.w3.org/ns/formats/SPARQL_Results_XML> \." <<< "$response"
done
