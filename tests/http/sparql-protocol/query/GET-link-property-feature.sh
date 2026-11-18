#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A document's response names the dataspace's SPARQL endpoint in a Link header (rel=sd:endpoint), and beside it the
# property functions that endpoint supports (rel=sd:propertyFeature), one Link each, as the dataspace's service
# declares them in config/system.trig. The page reads them off the response the way it reads the endpoint, and asks
# the text index for a search only where the header says there is one. The test end-user service declares
# text:query; the test admin service declares nothing, so its documents carry no such header.

sd="http://www.w3.org/ns/sparql-service-description#"

headers=$(mktemp)
trap 'rm -f "$headers"' EXIT

curl -k -f -s -o /dev/null -D "$headers" \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/rdf+xml" \
  "$END_USER_BASE_URL"

grep -i '^link:' "$headers" | tr ',' '\n' | grep "${sd}endpoint" | grep -q "${END_USER_BASE_URL}sparql"
grep -i '^link:' "$headers" | tr ',' '\n' | grep "${sd}propertyFeature" | grep -q "http://jena.apache.org/text#query"

curl -k -f -s -o /dev/null -D "$headers" \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/rdf+xml" \
  "$ADMIN_BASE_URL"

grep -i '^link:' "$headers" | tr ',' '\n' | grep "${sd}endpoint" | grep -q "${ADMIN_BASE_URL}sparql"
! grep -i '^link:' "$headers" | tr ',' '\n' | grep -q "${sd}propertyFeature"
