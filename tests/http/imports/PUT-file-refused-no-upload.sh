#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# An uploaded file is staged and moved to its content-addressed name only once the write it belongs to goes
# ahead. A multipart PUT used to write it before the precondition, the redirect and the constraints were
# checked, so a refused upload still left the file in the upload folder (#455). Whether bytes are on disk
# cannot be told over HTTP - an upload no document describes answers 403 either way - so the folder is read
# directly: the ./uploads bind mount of the platform's docker-compose.yml.

uploads="$(realpath "$PWD/../../uploads")"
echo "DEBUG: upload folder: $uploads"
[ -d "$uploads" ] || exit 1

# add agent to the writers group

ldh admin add agent \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

file_doc=$(ldh create item \
  -c "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --title "Refused upload" \
  --container "$END_USER_BASE_URL" \
  --slug "$(uuidgen | tr '[:upper:]' '[:lower:]')")

test_file=$(mktemp)
head -c 1024 /dev/urandom > "$test_file"
sha1sum=$(shasum -a 1 "$test_file" | awk '{print $1}')
echo "DEBUG: file SHA1: $sha1sum"

# upload <method> <header>: a multipart RDF/POST body with the file, prints the status code
function upload()
{
    curl -k -w "%{http_code}" -o /dev/null -s \
      -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
      -X "$1" \
      -H "Accept: application/n-triples" \
      -H "$2" \
      -F "rdf=" \
      -F "sb=file" \
      -F "pu=http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#fileName" \
      -F "ol=@${test_file};type=application/octet-stream" \
      -F "pu=http://purl.org/dc/terms/title" \
      -F "ol=Refused upload" \
      -F "pu=http://www.w3.org/1999/02/22-rdf-syntax-ns#type" \
      -F "ou=http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#FileDataObject" \
      "$file_doc"
}

function assert_not_stored()
{
    echo "DEBUG: $1"
    [ ! -e "${uploads}/${sha1sum}" ] || exit 1
    if ls -A "$uploads" | grep -q '^\.upload-'; then echo "DEBUG: a staged file was left behind"; exit 1; fi
}

status=$(upload PUT 'If-Match: "bogus"')
echo "DEBUG: multipart PUT with a stale tag. Expected: $STATUS_PRECONDITION_FAILED Got: $status"
[ "$status" = "$STATUS_PRECONDITION_FAILED" ] || exit 1
assert_not_stored "nothing stored after 412"

status=$(upload PUT 'X-No-Precondition: true')
echo "DEBUG: multipart PUT without If-Match. Expected: $STATUS_PRECONDITION_REQUIRED Got: $status"
[ "$status" = "$STATUS_PRECONDITION_REQUIRED" ] || exit 1
assert_not_stored "nothing stored after 428"

status=$(upload POST 'If-Match: "bogus"')
echo "DEBUG: multipart POST with a stale tag. Expected: $STATUS_PRECONDITION_FAILED Got: $status"
[ "$status" = "$STATUS_PRECONDITION_FAILED" ] || exit 1
assert_not_stored "nothing stored after a refused append"

# a PUT to the URI without its trailing slash is answered 308 before anything is written

set +e
ldh add file \
  -c "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --title "Refused upload" \
  --file "$test_file" \
  --content-type application/octet-stream \
  --replace \
  "${file_doc%/}" > /dev/null 2>&1
code=$?
set -e
echo "DEBUG: multipart PUT to the URI without a slash. Expected exit: 1 Got: $code"
[ "$code" = 1 ] || exit 1
assert_not_stored "nothing stored after 308"

# the same upload that goes ahead stores the file under its SHA1

file_uri=$(ldh add file \
  -c "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --title "Accepted upload" \
  --file "$test_file" \
  --content-type application/octet-stream \
  --replace \
  "$file_doc")
echo "DEBUG: upload URI: $file_uri"
[ "$file_uri" = "${END_USER_BASE_URL}uploads/${sha1sum}" ] || exit 1

cmp "$test_file" "${uploads}/${sha1sum}" || exit 1

downloaded=$(curl -k -f -s -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" "$file_uri" | shasum -a 1 | awk '{print $1}')
echo "DEBUG: downloaded SHA1. Expected: $sha1sum Got: $downloaded"
[ "$downloaded" = "$sha1sum" ] || exit 1

if ls -A "$uploads" | grep -q '^\.upload-'; then echo "DEBUG: a staged file was left behind"; exit 1; fi

rm -f "$test_file"
