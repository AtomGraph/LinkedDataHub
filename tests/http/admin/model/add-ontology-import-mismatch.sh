#!/usr/bin/env bash
set -euo pipefail

# An owl:imports of a document that declares another ontology than the imported URI is rejected:
# the document is imported by its location while naming an ontology elsewhere

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

pwd=$(realpath "$PWD")

ldh admin add agent \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

# upload a document whose ontology header names <https://example.org/test#>

file_content_type="text/turtle"
slug=$(uuidgen | tr '[:upper:]' '[:lower:]')

file_doc=$(ldh create item \
  -c "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --title "Test ontology that names itself elsewhere" \
  --container "$END_USER_BASE_URL" \
  --slug "$slug")

ldh add file \
  -c "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --title "Test ontology that names itself elsewhere" \
  --file "$pwd/test-ontology-import-mismatch.ttl" \
  --content-type "${file_content_type}" \
  "$file_doc"

sha1sum=$(shasum -a 1 "$pwd/test-ontology-import-mismatch.ttl" | awk '{print $1}')
upload_uri="${END_USER_BASE_URL}uploads/${sha1sum}"

namespace_doc="${END_USER_BASE_URL}ns"
namespace="${namespace_doc}#"
ontology_doc="${ADMIN_BASE_URL}ontologies/namespace/"

# importing the upload by its location is rejected

if ldh admin add ontology-import \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --import "$upload_uri" \
  "$ontology_doc"; then
  echo "DEBUG: importing <${upload_uri}>, which declares <https://example.org/test#>, was accepted"
  exit 1
fi

# and the namespace ontology does not carry the import

ldh admin clear ontology \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --ontology "$namespace" \
  "$ADMIN_BASE_URL"

if curl -k -f -s -N \
  -H "Accept: application/n-triples" \
  "$namespace_doc" \
| grep "<${namespace}> <http://www.w3.org/2002/07/owl#imports> <${upload_uri}>" > /dev/null; then
  echo "DEBUG: the rejected import of <${upload_uri}> is in the namespace ontology"
  exit 1
fi
