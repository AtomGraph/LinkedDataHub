#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# The HTML is the graph rendered with the dataspace's stylesheet and the packages it imports. Importing a package
# changes the HTML of a document whose graph did not change, so its entity tag has to change too: with a tag taken
# from the graph alone, a cache revalidating its copy was answered 304 and kept the page rendered without the package.
# The RDF representations are not rendered, and keep their tag.

package_uri="${PACKAGES_BASE_URL}editor/taxonomy/#this" # the fixture registry, tests/packages

# The settings live in the in-memory application model, which initialize_dataset does not reset - an import left
# behind by a failed assertion would stay for the rest of the suite

function remove_import()
{
  ldh packages remove \
    -c "$OWNER_CERT_KEYSTORE" \
    -p "$OWNER_CERT_PWD" \
    --package "$package_uri" \
    "$END_USER_BASE_URL" > /dev/null || true
}

trap remove_import EXIT

html_before=$(etag "$END_USER_BASE_URL" "$OWNER_CERT_FILE" "$OWNER_CERT_PWD" "text/html")
rdf_before=$(etag "$END_USER_BASE_URL" "$OWNER_CERT_FILE" "$OWNER_CERT_PWD" "application/n-triples")

ldh packages add \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --package "$package_uri" \
  "$END_USER_BASE_URL"

html_after=$(etag "$END_USER_BASE_URL" "$OWNER_CERT_FILE" "$OWNER_CERT_PWD" "text/html")
rdf_after=$(etag "$END_USER_BASE_URL" "$OWNER_CERT_FILE" "$OWNER_CERT_PWD" "application/n-triples")

echo "DEBUG: HTML ETag before: $html_before  after: $html_after"
echo "DEBUG: N-Triples ETag before: $rdf_before  after: $rdf_after"

[ -n "$html_before" ] && [ -n "$html_after" ]
[ "$html_before" != "$html_after" ]
[ "$rdf_before" = "$rdf_after" ]

# revalidating the copy rendered without the package gets the new page, not a 304

status=$(
curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: text/html" \
  -H "If-None-Match: $html_before" \
  "$END_USER_BASE_URL")

echo "DEBUG: If-None-Match: $html_before  Expected: $STATUS_OK  Got: $status"
[ "$status" = "$STATUS_OK" ]
