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

# PATCH that strips rdf:value from the #select-children block trips ldh:MissingValue
# (ldh:Object requires rdf:value) with spin:violationRoot = #select-children, while the
# document itself stays valid. The whole post-PATCH graph gets validated, but the 422 body
# must describe only the violating resource - not echo the entire would-be document graph.

update=$(cat <<EOF
DELETE WHERE
{
  <${END_USER_BASE_URL}#select-children> <http://www.w3.org/1999/02/22-rdf-syntax-ns#value> ?value
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

# the violation and its root

expected="<http://spinrdf.org/spin#violationRoot> <${END_USER_BASE_URL}#select-children>"
echo "DEBUG: Expected present: $expected"
if ! echo "$ntriples" | grep -qF "$expected"; then
    echo "DEBUG: Violation root missing!"
    exit 1
fi

# the violating resource's post-update description

expected="<${END_USER_BASE_URL}#select-children> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub#Object>"
echo "DEBUG: Expected present: $expected"
if ! echo "$ntriples" | grep -qF "$expected"; then
    echo "DEBUG: Violating resource description missing!"
    exit 1
fi

# the violation source's label, which clients use to discriminate the constraint kind

expected="<https://w3id.org/atomgraph/linkeddatahub#MissingValue> <http://www.w3.org/2000/01/rdf-schema#label>"
echo "DEBUG: Expected present: $expected"
if ! echo "$ntriples" | grep -qF "$expected"; then
    echo "DEBUG: Violation source label missing!"
    exit 1
fi

# the non-violating document description must be scoped out

unexpected="<${END_USER_BASE_URL}> <http://purl.org/dc/terms/title> \"Root\""
echo "DEBUG: Expected absent: $unexpected"
if echo "$ntriples" | grep -qF "$unexpected"; then
    echo "DEBUG: Document description leaked into the 422 body!"
    exit 1
fi

unexpected="<http://www.w3.org/1999/02/22-rdf-syntax-ns#_1>"
echo "DEBUG: Expected absent: $unexpected"
if echo "$ntriples" | grep -qF "$unexpected"; then
    echo "DEBUG: Document membership triple leaked into the 422 body!"
    exit 1
fi
