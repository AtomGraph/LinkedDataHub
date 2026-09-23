#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# Test: importing a package whose description is a document on this very instance does not deadlock.
#
# A package that is neither bundled nor cached used to be resolved over HTTP. When its description
# lives on the instance itself, that request comes back through the application: OntologyFilter,
# finding the ontology just evicted by the settings update, resolves the package descriptions in turn
# and issues the same fetch, and the requests nest until the proxy gives up - the import was written,
# but the PATCH answered 504 after nginx's 60 s, and the first render after it paid the same wait. A
# description that is a document of this instance is now read from the instance's own store instead.
# The same loop admin/model/ontology-import-upload-no-deadlock.sh guards one level down, for an
# ontology import; this one covers the package description.
#
# The bound is the assertion: a PATCH that takes longer than 30 s is the deadlock, whatever status
# it would eventually get (curl reports 000 when it gives up).

pwd=$(realpath "$PWD")

app_uri="urn:linkeddatahub:apps/end-user"

stylesheet_file="$pwd/same-origin-package.xsl"
stylesheet_type="text/xsl"
sha1sum=$(shasum -a 1 "$stylesheet_file" | awk '{print $1}')
stylesheet_uri="${END_USER_BASE_URL}uploads/${sha1sum}"

package_slug="same-origin-package"
package_doc="${END_USER_BASE_URL}${package_slug}/"
package_uri="${package_doc}#this"

function patch_settings()
{
  curl -k -w "%{http_code}" -o /dev/null -s --max-time 30 \
    -X PATCH \
    -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
    -H "Content-Type: application/sparql-update" \
    -d "$1" \
    "${END_USER_BASE_URL}settings" || true
}

# The settings live in the in-memory application model, which initialize_dataset does not reset

function remove_import()
{
  patch_settings "DELETE { <${app_uri}> <https://w3id.org/atomgraph/linkeddatahub#import> <${package_uri}> . } WHERE { }" > /dev/null || true
}

trap remove_import EXIT

# the package description, on this instance, naming an uploaded stylesheet

curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -X PUT \
  -H "Content-Type: application/n-triples" \
  --data-binary @- \
  "$package_doc" <<EOT \
| grep -q "$STATUS_CREATED"
<${package_doc}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://www.w3.org/ns/ldt/document-hierarchy#Item> .
<${package_doc}> <http://purl.org/dc/terms/title> "Same-origin package" .
<${package_doc}> <http://rdfs.org/sioc/ns#has_container> <${END_USER_BASE_URL}> .
<${package_doc}> <http://xmlns.com/foaf/0.1/primaryTopic> <${package_uri}> .
<${package_uri}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub/apps#Package> .
<${package_uri}> <http://purl.org/dc/terms/title> "Same-origin package" .
<${package_uri}> <https://w3id.org/atomgraph/client#stylesheet> <${stylesheet_uri}> .
EOT

ldh add file \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Same-origin package stylesheet" \
  --file "$stylesheet_file" \
  --content-type "$stylesheet_type" \
  "$package_doc" > /dev/null

# the import: written and answered within the request, not after the proxy's timeout

start=$(date +%s)
status=$(patch_settings "INSERT { <${app_uri}> <https://w3id.org/atomgraph/linkeddatahub#import> <${package_uri}> . } WHERE { }")
elapsed=$(( $(date +%s) - start ))

echo "DEBUG: [import] Expected: $STATUS_NO_CONTENT within 30 s  Got: $status after ${elapsed} s"
if [[ ! "$status" =~ ^($STATUS_NO_CONTENT)$ ]]; then
  echo "DEBUG: [import] the settings PATCH did not complete - resolving the package description on this origin recursed through the application" >&2
  exit 1
fi

# and the first request after it, which assembles the ontology with the package, answers too

start=$(date +%s)
status=$(curl -k -w "%{http_code}" -o /dev/null -s --max-time 30 \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/xhtml+xml" \
  "$package_doc" || true)
elapsed=$(( $(date +%s) - start ))

echo "DEBUG: [render] Expected: $STATUS_OK within 30 s  Got: $status after ${elapsed} s"
if [ "$status" != "$STATUS_OK" ]; then
  echo "DEBUG: [render] the first render after the import did not complete" >&2
  exit 1
fi

# remove the import

status=$(patch_settings "DELETE { <${app_uri}> <https://w3id.org/atomgraph/linkeddatahub#import> <${package_uri}> . } WHERE { }")

if [[ ! "$status" =~ ^($STATUS_NO_CONTENT)$ ]]; then
  echo "DEBUG: [removal] Expected: $STATUS_NO_CONTENT  Got: $status" >&2
  exit 1
fi
