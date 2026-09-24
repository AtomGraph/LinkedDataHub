#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# The data LDH writes is blank-node-free: every write through the document resource skolemizes before
# persisting. PATCH and PUT have tests; POST did not. The invariant is load-bearing beyond tidiness -
# the entity tag is a digest over a sorted N-Triples serialization, which is canonical only while it
# holds, because Jena's _:bN labels are not stable across reads. A stored blank node would therefore
# give a document a different tag on every read, and no conditional request against it could succeed.

# add agent to the writers group

ldh admin add agent \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

# POST a body that introduces a blank node, both as an object and as a subject.
# rdf:_98 avoids colliding with the rdf:_1..rdf:_8 the test dataset already carries.

curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X POST \
  -H "Accept: application/n-triples" \
  -H "If-Match: $(etag "$END_USER_BASE_URL" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD" "application/n-triples")" \
  -H "Content-Type: application/n-triples" \
  --data-binary @- \
  "$END_USER_BASE_URL" <<EOT \
| grep -qE "^(${STATUS_POST_SUCCESS})$"
<${END_USER_BASE_URL}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#_98> _:appended .
_:appended <http://purl.org/dc/terms/title> "Appended blank node" .
EOT

response=$(curl -k -f -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$END_USER_BASE_URL")

# the triple is there

rdf_98_line=$(echo "$response" | grep -E "^<${END_USER_BASE_URL}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#_98>" || true)
[ -n "$rdf_98_line" ] || { echo "DEBUG: the POSTed triple is missing" >&2; exit 1; }

# and its object is a URI, not a blank node label

if echo "$rdf_98_line" | grep -qE '_:[A-Za-z0-9]+ \.$'; then
    echo "DEBUG: rdf:_98 object was persisted as a blank node: $rdf_98_line" >&2
    exit 1
fi

# nor is the blank node left as a subject anywhere in the document

if echo "$response" | grep -qE '^_:'; then
    echo "DEBUG: a blank node survived POST as a subject" >&2
    echo "$response" | grep -E '^_:' >&2
    exit 1
fi
