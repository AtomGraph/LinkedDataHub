#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# Like rmdir, only an empty container can be deleted: a DELETE of a container with a child is refused with 409 and
# leaves both in place, and so is a PATCH that empties it, which completes as a DELETE. Once the child is gone, the
# container can be deleted.

container=$(ldh create container \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Non-empty" \
  --slug "non-empty" \
  --parent "$END_USER_BASE_URL")

item=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Child" \
  --slug "child" \
  --container "$container")

# send a DELETE as the owner and assert the status

delete()
{
    local label="$1" uri="$2" expected="$3" actual

    actual=$(curl -k -w "%{http_code}" -o /dev/null -s \
      -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
      -X DELETE \
      -H "Accept: application/n-triples" \
      -H "If-Match: $(etag "$uri" "$OWNER_CERT_FILE" "$OWNER_CERT_PWD" "application/n-triples")" \
      "$uri")
    echo "DEBUG: ${label}: Expected: $expected"
    echo "DEBUG: ${label}: Got: $actual"
    [ "$actual" = "$expected" ] || exit 1
}

# assert the status a GET of the document answers

get()
{
    local label="$1" uri="$2" expected="$3" actual

    actual=$(curl -k -w "%{http_code}" -o /dev/null -s \
      -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
      -H "Accept: application/n-triples" \
      "$uri")
    echo "DEBUG: ${label}: Expected: $expected"
    echo "DEBUG: ${label}: Got: $actual"
    [ "$actual" = "$expected" ] || exit 1
}

delete "DELETE of the container with a child" "$container" "$STATUS_CONFLICT"
get "the container after the refused DELETE" "$container" "$STATUS_OK"
get "the child after the refused DELETE" "$item" "$STATUS_OK"

# a PATCH that empties the container completes as a DELETE, and is refused the same way

actual=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -X PATCH \
  -H "Accept: application/n-triples" \
  -H "If-Match: $(etag "$container" "$OWNER_CERT_FILE" "$OWNER_CERT_PWD" "application/n-triples")" \
  -H "Content-Type: application/sparql-update" \
  --data-binary "DELETE { ?s ?p ?o } WHERE { ?s ?p ?o }" \
  "$container")
echo "DEBUG: PATCH emptying the container with a child: Expected: $STATUS_CONFLICT"
echo "DEBUG: PATCH emptying the container with a child: Got: $actual"
[ "$actual" = "$STATUS_CONFLICT" ] || exit 1

get "the container after the refused PATCH" "$container" "$STATUS_OK"

# the child goes first, then the container

delete "DELETE of the child" "$item" "$STATUS_NO_CONTENT"
delete "DELETE of the emptied container" "$container" "$STATUS_NO_CONTENT"
# a document that does not exist matches no authorization, so even its former owner is answered 403 rather than 404
get "the container after its DELETE" "$container" "$STATUS_FORBIDDEN"
