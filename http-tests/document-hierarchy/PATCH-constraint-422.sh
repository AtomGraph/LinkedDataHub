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

# append query triples to the graph

(
curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  --data-binary @- \
  "$END_USER_BASE_URL" <<EOF
<${END_USER_BASE_URL}#spin-query> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://spinrdf.org/sp#Select> .
<${END_USER_BASE_URL}#spin-query> <http://purl.org/dc/terms/title> "Whateverest" .
<${END_USER_BASE_URL}#spin-query> <http://spinrdf.org/sp#text> "SELECT * { ?s ?p ?o }" .
EOF
) \
| grep -q "$STATUS_NO_CONTENT"

# attempting to patch the document in a way that produces a constraint violation (sp:Select must have sp:text)

update=$(cat <<EOF
DELETE WHERE
{
  <${END_USER_BASE_URL}#spin-query> <http://spinrdf.org/sp#text> ?text
}
EOF
)

curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PATCH \
  -H "Content-Type: application/sparql-update" \
  "$END_USER_BASE_URL" \
   --data-binary "$update" \
| grep -q "$STATUS_UNPROCESSABLE_ENTITY"
