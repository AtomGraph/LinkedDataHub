#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A grant that lets the agent read a document over the Graph Store Protocol lets it read the document through the
# SPARQL endpoint too: acl:accessTo the document, and acl:default on the container above another one

suffix=$(uuidgen | tr '[:upper:]' '[:lower:]')
named_title="Named $suffix"
contained_title="Contained $suffix"

named=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "$named_title" \
  --slug "named-$suffix" \
  --container "$END_USER_BASE_URL")

container=$(ldh create container \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Container $suffix" \
  --slug "container-$suffix" \
  --parent "$END_USER_BASE_URL")

contained=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "$contained_title" \
  --slug "contained-$suffix" \
  --container "$container")

# titles: the titles the agent's GRAPH ?g query returns
titles()
{
  curl -k -f -s -G \
    -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
    -H "Accept: application/sparql-results+xml" \
    "${END_USER_BASE_URL}sparql" \
    --data-urlencode "query=SELECT ?title { GRAPH ?g { ?s <http://purl.org/dc/terms/title> ?title } }"
}

result=$(titles)
echo "DEBUG: before the grants. Expected: neither title Got: '$(echo "$result" | grep -oE "(Named|Contained) $suffix" | tr '\n' ' ')'"
if echo "$result" | grep -qE "(Named|Contained) $suffix"; then exit 1; fi

ldh admin create authorization \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --label "Agent reads the named document" \
  --agent "$AGENT_URI" \
  --to "$named" \
  --read \
  "$ADMIN_BASE_URL"

ldh admin create authorization \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --label "Agent reads below the container" \
  --agent "$AGENT_URI" \
  --default "$container" \
  --read \
  "$ADMIN_BASE_URL"

purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"

result=$(titles)
echo "DEBUG: after the grants. Expected: both titles Got: '$(echo "$result" | grep -oE "(Named|Contained) $suffix" | tr '\n' ' ')'"
echo "$result" | grep -qF "$named_title"
echo "$result" | grep -qF "$contained_title"

# acl:default reaches what is below the container, not the container itself, as for GET

status=$(curl -k -s -o /dev/null -w "%{http_code}" \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$container")
echo "DEBUG: GET of the container by the agent. Expected: $STATUS_FORBIDDEN Got: $status"
[ "$status" = "$STATUS_FORBIDDEN" ] || exit 1

if echo "$result" | grep -qF "Container $suffix"; then
    echo "DEBUG: the container's title was read through the query"
    exit 1
fi
