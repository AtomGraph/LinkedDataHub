#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# add agent to the writers group

ldh admin add agent \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

# PATCH that strips the document's dct:title trips def:MissingTitle with the document itself
# as spin:violationRoot. The 422 body must describe the violating document but not its
# non-violating #select-children block.

update=$(cat <<EOF
DELETE WHERE
{
  <${END_USER_BASE_URL}> <http://purl.org/dc/terms/title> ?title
}
EOF
)

response=$(curl -k -w "%{http_code}\n" -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PATCH \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/sparql-update" \
  "$END_USER_BASE_URL" \
  --data-binary "$update")

status=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

echo "DEBUG: Expected status: $STATUS_UNPROCESSABLE_ENTITY"
echo "DEBUG: Got status: $status"
if [ "$status" != "$STATUS_UNPROCESSABLE_ENTITY" ]; then
    echo "DEBUG: Status mismatch!"
    exit 1
fi

ntriples=$(echo "$body" | rapper -q --input ntriples --output ntriples /dev/stdin -)
echo "DEBUG: Response body as N-Triples:"
echo "$ntriples"

# the violation rooted in the document

expected="<http://spinrdf.org/spin#violationRoot> <${END_USER_BASE_URL}>"
echo "DEBUG: Expected present: $expected"
if ! echo "$ntriples" | grep -qF "$expected"; then
    echo "DEBUG: Violation root missing!"
    exit 1
fi

# the violating document's post-update description

expected="<${END_USER_BASE_URL}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#_1> <${END_USER_BASE_URL}#select-children>"
echo "DEBUG: Expected present: $expected"
if ! echo "$ntriples" | grep -qF "$expected"; then
    echo "DEBUG: Violating document description missing!"
    exit 1
fi

# the non-violating block's description must be scoped out (it may appear as the object of the
# document's rdf:_1 triple, but not as a subject)

unexpected="^<${END_USER_BASE_URL}#select-children> "
echo "DEBUG: Expected absent as subject: <${END_USER_BASE_URL}#select-children>"
if echo "$ntriples" | grep -q "$unexpected"; then
    echo "DEBUG: Block description leaked into the 422 body!"
    exit 1
fi
