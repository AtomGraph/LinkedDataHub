#!/bin/bash

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"

urlencode()
{
    python2 -c 'import urllib, sys; print urllib.quote(sys.argv[1] if len(sys.argv) > 1 else sys.stdin.read()[0:-1])' "$1"
}

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/model"

# create class

class="${END_USER_BASE_URL}ns/domain#NewClass"

./create-class.sh \
-f "$OWNER_CERT_FILE" \
-p "$OWNER_CERT_PWD" \
-b "$ADMIN_BASE_URL" \
--uri "$class" \
--label "New class" \
--slug new-class \
--sub-class-of "${END_USER_BASE_URL}ns/domain/default#Item"

popd > /dev/null

# check that the class is present in the ontology

curl -k -f -s -N \
  -H "Accept: application/n-quads" \
  "${END_USER_BASE_URL}ns/domain" \
| grep -q "$class"

# clear ontology from memory

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin"

./clear-ontology.sh \
-f "$OWNER_CERT_FILE" \
-p "$OWNER_CERT_PWD" \
"${ADMIN_BASE_URL}model/ontologies/domain/"

popd > /dev/null

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/acl"

# add agent to the writers group to be able to read/write documents (might already be done by another test)

./add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

popd > /dev/null

# attempt to construct an instance of the class

mode=$(urlencode "https://w3id.org/atomgraph/client#ConstructMode")
forClass=$(urlencode "$class")

curl -k -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  "${END_USER_BASE_URL}?forClass=${forClass}&mode=${mode}" \
  -H "Accept: text/turtle"