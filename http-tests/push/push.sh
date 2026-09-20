#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

pwd=$(realpath "$PWD")

# add agent to the writers group

ldh admin add agent \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

# the tree is pushed into a container of its own, so its root.ttl replaces that container and never the app root

slug=$(uuidgen | tr '[:upper:]' '[:lower:]')

container=$(ldh create container \
  -f "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Push target" \
  --parent "$END_USER_BASE_URL" \
  --slug "$slug")

# what the tree maps to: root.ttl -> the container, a.ttl -> a/, a/b.ttl -> a/b/, a/image.png -> an upload into a/

sha1sum=$(shasum -a 1 "$pwd/app/a/image.png" | awk '{print $1}')
expected="${container}
${container}a/
${container}a/b/
${END_USER_BASE_URL}uploads/${sha1sum}"

# a dry run prints the plan and writes nothing

planned=$(ldh push --dry-run \
  -b "$END_USER_BASE_URL" \
  --dir "$pwd/app" \
  "$container")

[ "$planned" = "$expected" ]

curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "${container}a/" \
| grep -q "$STATUS_NOT_FOUND"

# push the tree

pushed=$(ldh push \
  -f "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --dir "$pwd/app" \
  "$container")

[ "$pushed" = "$expected" ]

# root.ttl replaced the container's own description

ldh get \
  -f "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  "$container" \
| grep -q "<${container}> <http://purl.org/dc/terms/title> \"Pushed\" ."

# a document lands where its path says, with its relative URIs resolved against the document URL

ldh get \
  -f "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  "${container}a/b/" \
| grep -q "<${container}a/b/> <http://purl.org/dc/terms/title> \"B\" ."

# the file was uploaded into its directory's document; the ignored files were not

a_ntriples=$(ldh get \
  -f "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  "${container}a/")

echo "$a_ntriples" | grep -q "<${END_USER_BASE_URL}uploads/${sha1sum}>"
echo "$a_ntriples" | grep -q '"image.png"'
if echo "$a_ntriples" | grep -q 'ignored.txt'; then exit 1; fi
if echo "$a_ntriples" | grep -q 'notes.md'; then exit 1; fi

curl --head -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: */*" \
  "${END_USER_BASE_URL}uploads/${sha1sum}" \
| grep -q "$STATUS_OK"

# the ignored document was never created

curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "${container}a/c/" \
| grep -q "$STATUS_NOT_FOUND"

# a second push converges: the document is rewritten before its upload is re-appended, so nothing duplicates

ldh push \
  -f "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --dir "$pwd/app" \
  "$container" > /dev/null

file_count=$(ldh get \
  -f "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  "${container}a/" \
| grep -c 'nfo#FileDataObject')

[ "$file_count" = "1" ]
