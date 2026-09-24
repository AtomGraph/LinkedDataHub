#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A write to a document that already exists has to say which state it was written against: the graph store
# applies one by reading the graph, changing it in memory and writing the whole thing back, so two writers
# that name no precondition overwrite each other with nothing to show for it. This pins the three answers
# that rule gives - none, blank, and stale - because each was wrong at some point while it was written.

# add agent to the writers group

ldh admin add agent \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

update=$(cat <<UPDATE
PREFIX  rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

INSERT
{
  <${END_USER_BASE_URL}> rdf:_3 <${END_USER_BASE_URL}#preconditioned>
}
WHERE
{}
UPDATE
)

# no precondition at all

status=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PATCH \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/sparql-update" \
  "$END_USER_BASE_URL" \
  --data-binary "$update")

echo "DEBUG: unconditional PATCH. Expected: $STATUS_PRECONDITION_REQUIRED Got: $status"
[ "$status" = "$STATUS_PRECONDITION_REQUIRED" ] || exit 1

# an empty If-Match is not a validator, and reading it as one would let a client opt out of the rule
# entirely by sending the header with nothing in it

status=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PATCH \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/sparql-update" \
  -H "If-Match: " \
  "$END_USER_BASE_URL" \
  --data-binary "$update")

echo "DEBUG: blank If-Match. Expected: $STATUS_PRECONDITION_REQUIRED Got: $status"
[ "$status" = "$STATUS_PRECONDITION_REQUIRED" ] || exit 1

# a validator that is no longer current

status=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PATCH \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/sparql-update" \
  -H 'If-Match: "0000000000000000"' \
  "$END_USER_BASE_URL" \
  --data-binary "$update")

echo "DEBUG: stale If-Match. Expected: $STATUS_PRECONDITION_FAILED Got: $status"
[ "$status" = "$STATUS_PRECONDITION_FAILED" ] || exit 1

# the current validator, read with the same Accept the write sends: an entity tag identifies a negotiated
# variant rather than the graph, so the same document answers a different tag as N-Triples than as Turtle

status=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PATCH \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/sparql-update" \
  -H "If-Match: $(etag "$END_USER_BASE_URL" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD" "application/n-triples")" \
  "$END_USER_BASE_URL" \
  --data-binary "$update")

echo "DEBUG: current If-Match. Expected: $STATUS_PATCH_SUCCESS Got: $status"
[[ "$status" =~ ^($STATUS_PATCH_SUCCESS)$ ]] || exit 1

# and it landed

curl -k -f -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$END_USER_BASE_URL" \
| grep -q "<${END_USER_BASE_URL}#preconditioned>"
