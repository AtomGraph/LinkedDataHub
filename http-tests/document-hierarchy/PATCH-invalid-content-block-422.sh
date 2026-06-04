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

# PATCH the root with an rdf:_N pointing at a block explicitly typed as sp:Construct
# (neither ldh:Object nor ldh:XHTML). Expected: rejected by ldh:InvalidContentBlockType with 422.
# Use rdf:_99 to avoid colliding with existing rdf:_1..rdf:_8 in the test dataset.

update=$(cat <<EOF
PREFIX  rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX  sp:   <http://spinrdf.org/sp#>
PREFIX  dct:  <http://purl.org/dc/terms/>

INSERT
{
  <${END_USER_BASE_URL}> rdf:_99 <${END_USER_BASE_URL}#bad-block> .
  <${END_USER_BASE_URL}#bad-block> a sp:Construct ;
    dct:title "Not a valid content block" ;
    sp:text "CONSTRUCT WHERE {}"
}
WHERE
{}
EOF
)

curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PATCH \
  -H "Content-Type: application/sparql-update" \
  "$END_USER_BASE_URL" \
   --data-binary "$update" \
| grep -q "$STATUS_UNPROCESSABLE_ENTITY"
