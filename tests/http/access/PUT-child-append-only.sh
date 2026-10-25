#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A PUT with If-None-Match: * can only create a document - the graph store answers 412 when it exists - and
# creating one removes nothing, so it requires acl:Append, which the ACL ontology declares a subclass of acl:Write.
# An agent with only acl:Append on a container may therefore create documents in it, and nothing more: not
# replace the container, not delete it, not overwrite a document that is already there. A grant of acl:Write
# still covers the create, because a write mode covers its subclasses.

put_status() # document, If-None-Match value or empty
{
  local args=(-k -w "%{http_code}" -o /dev/null -s
    -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD"
    -X PUT
    -H "Accept: application/n-triples"
    -H "Content-Type: application/n-triples")
  [ -n "$2" ] && args+=(-H "If-None-Match: $2")

  printf '<%s> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#Item> .\n<%s> <http://purl.org/dc/terms/title> "Dropped" .\n' "$1" "$1" \
  | curl "${args[@]}" --data-binary @- "$1"
}

# the owner creates a container and grants the agent acl:Append on it, and nothing else

container=$(ldh create container \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Drop box" \
  --slug "drop-box" \
  --parent "$END_USER_BASE_URL")

ldh admin create authorization \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --label "Append to the drop box" \
  --agent "$AGENT_URI" \
  --to "$container" \
  --append \
  "$ADMIN_BASE_URL"

# a create-only PUT of a child is an append: 201

child="${container}$(uuidgen | tr '[:upper:]' '[:lower:]')/"
status=$(put_status "$child" "*")
echo "DEBUG: create-only PUT of a child with acl:Append. Expected: $STATUS_CREATED Got: $status"
[ "$status" = "$STATUS_CREATED" ] || exit 1

# the server records the agent as its owner, so the sender of what was dropped is attested

ntriples=$(curl -k -f -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$child")
echo "DEBUG: the child's owner. Expected: <$AGENT_URI>"
echo "$ntriples" | grep -q "<${child}> <http://www.w3.org/ns/auth/acl#owner> <${AGENT_URI}>" || exit 1

# the same create-only PUT again: the document exists, so it is refused rather than overwritten

status=$(put_status "$child" "*")
echo "DEBUG: create-only PUT of an existing child. Expected: $STATUS_PRECONDITION_FAILED Got: $status"
[ "$status" = "$STATUS_PRECONDITION_FAILED" ] || exit 1

# a PUT that is not create-only may replace, which is acl:Write: 403

status=$(put_status "${container}$(uuidgen | tr '[:upper:]' '[:lower:]')/" "")
echo "DEBUG: plain PUT of a child with acl:Append only. Expected: $STATUS_FORBIDDEN Got: $status"
[ "$status" = "$STATUS_FORBIDDEN" ] || exit 1

# a create-only PUT of the container itself cannot replace it: 412, and its title is untouched

status=$(put_status "$container" "*")
echo "DEBUG: create-only PUT of the container. Expected: $STATUS_PRECONDITION_FAILED Got: $status"
[ "$status" = "$STATUS_PRECONDITION_FAILED" ] || exit 1

curl -k -f -s -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$container" \
| grep -q "<${container}> <http://purl.org/dc/terms/title> \"Drop box\"" || exit 1

# deleting the container is acl:Write: 403

status=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X DELETE \
  "$container")
echo "DEBUG: DELETE of the container with acl:Append only. Expected: $STATUS_FORBIDDEN Got: $status"
[ "$status" = "$STATUS_FORBIDDEN" ] || exit 1

# a grant of acl:Write alone covers the create-only PUT, as acl:Append is a subclass of acl:Write

container_write=$(ldh create container \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Writable" \
  --slug "writable" \
  --parent "$END_USER_BASE_URL")

ldh admin create authorization \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --label "Write to the writable container" \
  --agent "$AGENT_URI" \
  --to "$container_write" \
  --write \
  "$ADMIN_BASE_URL"

status=$(put_status "${container_write}$(uuidgen | tr '[:upper:]' '[:lower:]')/" "*")
echo "DEBUG: create-only PUT of a child with acl:Write only. Expected: $STATUS_CREATED Got: $status"
[ "$status" = "$STATUS_CREATED" ] || exit 1
