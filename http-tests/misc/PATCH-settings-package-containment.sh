#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# Test: a package stylesheet cannot take over more of the page than the open modes.
#
# Package stylesheets are composed into the platform's import tree at the marker - right above the open
# modes' fallbacks (hooks.xsl) and below everything else - and import precedence beats template priority.
# So a package rule in a sealed mode loses however high its priority, while a rule in an open mode wins.
# The probe package (containment-probe.xsl) tries both: it claims ac:Head and ldh:ContentBody at
# priority 100, and fills ldh:ContentColumn. The first two must leave no trace; the third must render.
#
# The package lives on the instance itself: a document describing a lapp:Package whose ac:stylesheet is
# an uploaded file. Both are fetched by the server through its own origin, the way an uploaded ontology
# is (admin/model/ontology-import-upload-no-deadlock.sh).

pwd=$(realpath "$PWD")

app_uri="urn:linkeddatahub:apps/end-user"

stylesheet_file="$pwd/misc/containment-probe.xsl"
stylesheet_type="text/xsl"
sha1sum=$(shasum -a 1 "$stylesheet_file" | awk '{print $1}')
stylesheet_uri="${END_USER_BASE_URL}uploads/${sha1sum}"

package_slug="containment-probe-package"
package_doc="${END_USER_BASE_URL}${package_slug}/"
package_uri="${package_doc}#this"

probe_slug="containment-probe"
probe_doc="${END_USER_BASE_URL}${probe_slug}/"

# XHTML rather than text/html, as in PATCH-settings-package-import.sh: well-formed, so the markers can
# be counted with XPath instead of matched as text

function document()
{
  curl -k -s \
    -H "Accept: application/xhtml+xml" \
    -H "Accept-Language: en" \
    -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
    "$probe_doc"
}

# Counts the three markers from one fetch. The body is read into a variable first: `xmllint -`
# consumes all of it, and with `set -o pipefail` a reader that stopped early would SIGPIPE curl.
function probe()
{
  local body
  body=$(document)
  HEAD=$(xmllint --xpath "count(//*[local-name() = 'meta'][@name = 'containment-probe'])" - <<< "$body" 2> /dev/null || echo "ERR")
  BODY=$(xmllint --xpath "count(//*[@id = 'containment-probe-body'])" - <<< "$body" 2> /dev/null || echo "ERR")
  COLUMN=$(xmllint --xpath "count(//*[@id = 'containment-probe-column'])" - <<< "$body" 2> /dev/null || echo "ERR")
  TITLE=$(xmllint --xpath "count(//*[local-name() = 'title'][. = 'containment probe'])" - <<< "$body" 2> /dev/null || echo "ERR")
}

function assert_markers()
{
  local phase="$1" expected_column="$2"
  probe
  echo "DEBUG: [$phase] head marker: $HEAD (expected 0)  probe title: $TITLE (expected 0)  body marker: $BODY (expected 0)  column marker: $COLUMN (expected $expected_column)"
  if [ "$HEAD" != "0" ] || [ "$TITLE" != "0" ]; then
    echo "DEBUG: [$phase] the package replaced the document head - ac:Head is not sealed" >&2
    exit 1
  fi
  if [ "$BODY" != "0" ]; then
    echo "DEBUG: [$phase] the package replaced the content body - ldh:ContentBody is not sealed" >&2
    exit 1
  fi
  if [ "$COLUMN" != "$expected_column" ]; then
    if [ "$expected_column" = "1" ]; then
      echo "DEBUG: [$phase] the package's ldh:ContentColumn rule did not render - either the package stylesheet did not compose (check the server log for the composition fallback) or the open mode is not reachable" >&2
    else
      echo "DEBUG: [$phase] the package's column is still rendered after the import was removed" >&2
    fi
    exit 1
  fi
}

function patch_settings()
{
  curl -k -w "%{http_code}" -o /dev/null -s \
    -X PATCH \
    -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
    -H "Content-Type: application/sparql-update" \
    -d "$1" \
    "${END_USER_BASE_URL}settings"
}

# The settings live in the in-memory application model, which initialize_dataset does not reset

function remove_import()
{
  patch_settings "DELETE { <${app_uri}> <https://w3id.org/atomgraph/linkeddatahub#import> <${package_uri}> . } WHERE { }" > /dev/null || true
}

trap remove_import EXIT

# the package description: a document whose primary topic is the lapp:Package, naming the uploaded
# stylesheet - the upload URI is content-addressed, so it is known before the file is uploaded

curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -X PUT \
  -H "Content-Type: application/n-triples" \
  --data-binary @- \
  "$package_doc" <<EOT \
| grep -q "$STATUS_CREATED"
<${package_doc}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://www.w3.org/ns/ldt/document-hierarchy#Item> .
<${package_doc}> <http://purl.org/dc/terms/title> "Containment probe package" .
<${package_doc}> <http://rdfs.org/sioc/ns#has_container> <${END_USER_BASE_URL}> .
<${package_doc}> <http://xmlns.com/foaf/0.1/primaryTopic> <${package_uri}> .
<${package_uri}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub/apps#Package> .
<${package_uri}> <http://purl.org/dc/terms/title> "Containment probe package" .
<${package_uri}> <https://w3id.org/atomgraph/client#stylesheet> <${stylesheet_uri}> .
EOT

# the stylesheet, uploaded into the package document

ldh add file \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Containment probe stylesheet" \
  --file "$stylesheet_file" \
  --content-type "$stylesheet_type" \
  "$package_doc" > /dev/null

curl -k -f -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: ${stylesheet_type}" \
  "$stylesheet_uri" > /dev/null

# an ordinary document to render

curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -X PUT \
  -H "Content-Type: application/n-triples" \
  --data-binary @- \
  "$probe_doc" <<EOT \
| grep -q "$STATUS_CREATED"
<${probe_doc}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://www.w3.org/ns/ldt/document-hierarchy#Item> .
<${probe_doc}> <http://purl.org/dc/terms/title> "Containment probe" .
<${probe_doc}> <http://rdfs.org/sioc/ns#has_container> <${END_USER_BASE_URL}> .
EOT

# without the package: no markers at all

assert_markers "before import" 0

# declare the package import

status=$(patch_settings "INSERT { <${app_uri}> <https://w3id.org/atomgraph/linkeddatahub#import> <${package_uri}> . } WHERE { }")

if [[ ! "$status" =~ ^($STATUS_NO_CONTENT)$ ]]; then
  echo "DEBUG: Expected: $STATUS_NO_CONTENT  Got: $status" >&2
  exit 1
fi

# with the package: the open mode renders, the sealed ones do not

assert_markers "after import" 1

# remove the package import

status=$(patch_settings "DELETE { <${app_uri}> <https://w3id.org/atomgraph/linkeddatahub#import> <${package_uri}> . } WHERE { }")

if [[ ! "$status" =~ ^($STATUS_NO_CONTENT)$ ]]; then
  echo "DEBUG: Expected: $STATUS_NO_CONTENT  Got: $status" >&2
  exit 1
fi

# and the column is gone again

assert_markers "after removal" 0
