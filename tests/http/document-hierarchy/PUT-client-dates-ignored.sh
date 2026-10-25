#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# dct:created and dct:modified on the document are server-managed: Last-Modified is derived from them, so a
# client that could set them could pin Last-Modified anywhere, including in the future. The ones a PUT (create
# and update) or a POST carries are dropped: created is set on create and kept after, modified is set by every
# update.

# add agent to the writers group

ldh admin add agent \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

uuid=$(uuidgen | tr '[:upper:]' '[:lower:]')
document="${END_USER_BASE_URL}${uuid}/"

dates="<${document}> <http://purl.org/dc/terms/created> \"2001-01-01T00:00:00Z\"^^<http://www.w3.org/2001/XMLSchema#dateTime> .
<${document}> <http://purl.org/dc/terms/modified> \"2099-01-01T00:00:00Z\"^^<http://www.w3.org/2001/XMLSchema#dateTime> ."

# stored: prints the stored document

function stored()
{
    curl -k -f -s -G \
      -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
      -H "Accept: application/n-triples" \
      "$document"
}

# count <dct local name> <n-triples>: counts the document's values of that property

function count()
{
    echo "$2" | grep -c "<${document}> <http://purl.org/dc/terms/$1> " || true
}

# write <method> <precondition header> <body>: prints the status code

function write()
{
    printf '%s' "$3" | curl -k -w "%{http_code}" -o /dev/null -s \
      -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
      -X "$1" \
      -H "Accept: application/n-triples" \
      -H "Content-Type: application/n-triples" \
      -H "$2" \
      --data-binary @- \
      "$document"
}

# create

status=$(write PUT "If-None-Match: *" "<${document}> <http://purl.org/dc/terms/title> \"Dated\" .
${dates}")
echo "DEBUG: create. Expected: $STATUS_CREATED Got: $status"
[ "$status" = "$STATUS_CREATED" ] || exit 1

created=$(stored)
echo "DEBUG: after create: $created"
if echo "$created" | grep -q '"2001-\|"2099-'; then echo "DEBUG: a client-supplied date was kept on create"; exit 1; fi
echo "DEBUG: dct:created count. Expected: 1 Got: $(count created "$created")"
[ "$(count created "$created")" -eq 1 ] || exit 1
echo "DEBUG: dct:modified count. Expected: 0 Got: $(count modified "$created")"
[ "$(count modified "$created")" -eq 0 ] || exit 1

created_date=$(echo "$created" | grep "<${document}> <http://purl.org/dc/terms/created> ")

# update

status=$(write PUT "If-Match: $(etag "$document" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD")" "<${document}> <http://purl.org/dc/terms/title> \"Redated\" .
${dates}")
echo "DEBUG: update. Expected: $STATUS_NO_CONTENT Got: $status"
[ "$status" = "$STATUS_NO_CONTENT" ] || exit 1

updated=$(stored)
echo "DEBUG: after update: $updated"
if echo "$updated" | grep -q '"2001-\|"2099-'; then echo "DEBUG: a client-supplied date was kept on update"; exit 1; fi
echo "DEBUG: dct:created. Expected: $created_date"
echo "$updated" | grep -qF "$created_date" || exit 1
echo "DEBUG: dct:created count. Expected: 1 Got: $(count created "$updated")"
[ "$(count created "$updated")" -eq 1 ] || exit 1
echo "DEBUG: dct:modified count. Expected: 1 Got: $(count modified "$updated")"
[ "$(count modified "$updated")" -eq 1 ] || exit 1

# append

status=$(write POST "If-Match: $(etag "$document" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD")" "$dates")
echo "DEBUG: append. Expected: $STATUS_NO_CONTENT Got: $status"
[ "$status" = "$STATUS_NO_CONTENT" ] || exit 1

appended=$(stored)
echo "DEBUG: after append: $appended"
if echo "$appended" | grep -q '"2001-\|"2099-'; then echo "DEBUG: a client-supplied date was kept on append"; exit 1; fi
echo "$appended" | grep -qF "$created_date" || exit 1
echo "DEBUG: dct:created count. Expected: 1 Got: $(count created "$appended")"
[ "$(count created "$appended")" -eq 1 ] || exit 1
echo "DEBUG: dct:modified count. Expected: 1 Got: $(count modified "$appended")"
[ "$(count modified "$appended")" -eq 1 ] || exit 1

# and Last-Modified is not in the future

last_modified=$(curl -k -s -I \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$document" \
| grep -i '^last-modified:' | tr -d '\r')
echo "DEBUG: $last_modified"
if echo "$last_modified" | grep -q "2099"; then exit 1; fi
