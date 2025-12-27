#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# test package URI (SKOS package)
package_uri="https://packages.linkeddatahub.com/skos/#this"
package_ontology_uri="http://www.w3.org/2004/02/skos/core"
namespace_ontology_uri="${END_USER_BASE_URL}ns#"

# install package
curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "package-uri=$package_uri" \
  "$ADMIN_BASE_URL"packages/install \
| grep -q "$STATUS_SEE_OTHER"

# verify owl:imports triple was added
curl -k -s \
  -H "Accept: application/n-triples" \
  "${END_USER_BASE_URL}ns" \
| grep -q "<${namespace_ontology_uri}> <http://www.w3.org/2002/07/owl#imports> <${package_ontology_uri}>"

# verify package ontology document exists
package_ontology_hash=$(echo -n "$package_ontology_uri" | shasum -a 1 | cut -d' ' -f1)
curl -k -f -s -o /dev/null \
  "${ADMIN_BASE_URL}ontologies/${package_ontology_hash}/"

# uninstall package
curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "package-uri=$package_uri" \
  "$ADMIN_BASE_URL"packages/uninstall \
| grep -q "$STATUS_SEE_OTHER"

# verify owl:imports triple was removed
curl -k -s \
  -H "Accept: application/n-triples" \
  "${END_USER_BASE_URL}ns" \
| grep -v -q "<${namespace_ontology_uri}> <http://www.w3.org/2002/07/owl#imports> <${package_ontology_uri}>"

# verify package ontology document was deleted
curl -k -w "%{http_code}\n" -o /dev/null -s \
  "${ADMIN_BASE_URL}ontologies/${package_ontology_hash}/" \
| grep -q "$STATUS_NOT_FOUND"
