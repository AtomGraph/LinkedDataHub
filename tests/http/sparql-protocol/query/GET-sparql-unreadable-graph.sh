#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A document the agent may not read over the Graph Store Protocol is not read through the SPARQL endpoint either,
# however the query names its graph (#570). The signed-up agent may use the endpoint (acl:AuthenticatedAgent), and no
# grant reaches the owner's document

title="Owner only $(uuidgen)"

item=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "$title" \
  --slug "$(uuidgen | tr '[:upper:]' '[:lower:]')" \
  --container "$END_USER_BASE_URL")

status=$(curl -k -s -o /dev/null -w "%{http_code}" \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$item")
echo "DEBUG: GET of the document by the agent. Expected: $STATUS_FORBIDDEN Got: $status"
[ "$status" = "$STATUS_FORBIDDEN" ] || exit 1

# query <ARG...>: the agent's query, given as curl --data-urlencode arguments; prints the results
query()
{
  local args=()
  for arg in "$@"; do args+=(--data-urlencode "$arg"); done
  curl -k -f -s -G \
    -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
    -H "Accept: application/sparql-results+xml" \
    "${END_USER_BASE_URL}sparql" \
    "${args[@]}"
}

# refute_title <description> <results>
refute_title()
{
  echo "DEBUG: $1. Expected: no '$title' Got: $(echo "$2" | grep -c "$title" || true) match(es)"
  if echo "$2" | grep -qF "$title"; then exit 1; fi
}

# refute_graph <description> <results>
refute_graph()
{
  echo "DEBUG: $1. Expected: no <$item> Got: $(echo "$2" | grep -c "$item" || true) match(es)"
  if echo "$2" | grep -qF "<uri>${item}</uri>"; then exit 1; fi
}

refute_title "GRAPH <document>" "$(query "query=SELECT ?title { GRAPH <${item}> { ?s <http://purl.org/dc/terms/title> ?title } }")"
refute_title "GRAPH ?g" "$(query "query=SELECT ?title { GRAPH ?g { ?s <http://purl.org/dc/terms/title> ?title } }")"
refute_graph "graph names" "$(query "query=SELECT ?g { GRAPH ?g { } }")"
refute_graph "graphs counted" "$(query "query=SELECT DISTINCT ?g { GRAPH ?g { ?s ?p ?o } }")"
refute_title "FROM <document>" "$(query "query=SELECT ?title FROM <${item}> { ?s <http://purl.org/dc/terms/title> ?title }")"
refute_title "default-graph-uri" "$(query "query=SELECT ?title { ?s <http://purl.org/dc/terms/title> ?title }" "default-graph-uri=${item}")"
refute_title "named-graph-uri" "$(query "query=SELECT ?title { GRAPH ?g { ?s <http://purl.org/dc/terms/title> ?title } }" "named-graph-uri=${item}")"
refute_title "FILTER EXISTS" "$(query "query=SELECT ?title { VALUES ?title { \"${title}\" } FILTER EXISTS { GRAPH ?g { ?s <http://purl.org/dc/terms/title> ?title } } }")"

# the union graph has no one graph to check: refused

status=$(curl -k -s -o /dev/null -w "%{http_code}" -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/sparql-results+xml" \
  "${END_USER_BASE_URL}sparql" \
  --data-urlencode "query=SELECT ?title { GRAPH <urn:x-arq:UnionGraph> { ?s <http://purl.org/dc/terms/title> ?title } }")
echo "DEBUG: GRAPH <urn:x-arq:UnionGraph>. Expected: $STATUS_BAD_REQUEST Got: $status"
[ "$status" = "$STATUS_BAD_REQUEST" ] || exit 1

# the owner reads it through the same query

result=$(curl -k -f -s -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/sparql-results+xml" \
  "${END_USER_BASE_URL}sparql" \
  --data-urlencode "query=SELECT ?title { GRAPH <${item}> { ?s <http://purl.org/dc/terms/title> ?title } }")
echo "DEBUG: GRAPH <document> by the owner. Expected: '$title' Got: $(echo "$result" | grep -c "$title" || true) match(es)"
echo "$result" | grep -qF "$title"
