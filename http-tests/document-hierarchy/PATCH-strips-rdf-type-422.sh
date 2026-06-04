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

# Reproduce the document-edit modal PATCH that strips rdf:type along with most
# user-editable properties (preserving only system properties + rdf:_N container
# membership). The root document is a def:Root instance, and def:Root carries
# the :MissingTitle SPIN constraint. After this PATCH the resource would be
# left untyped and titleless, which must be rejected with 422.

update=$(cat <<EOF
DELETE { <${END_USER_BASE_URL}> ?p ?o . }
INSERT {}
WHERE
{
  <${END_USER_BASE_URL}> ?p ?o .
  FILTER(?p NOT IN(
    <http://purl.org/dc/terms/created>,
    <http://purl.org/dc/terms/modified>,
    <http://rdfs.org/sioc/ns#has_parent>,
    <http://rdfs.org/sioc/ns#has_container>,
    <http://purl.org/dc/terms/creator>,
    <http://www.w3.org/ns/auth/acl#owner>
  ))
  FILTER(!(STRSTARTS(STR(?p), CONCAT(STR(<http://www.w3.org/1999/02/22-rdf-syntax-ns#>), "_"))))
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
