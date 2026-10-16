#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# the public dataspace context is readable anonymously on both origins, and lists every dataspace with its type and,
# for an end-user dataspace, the admin pairing - but none of the services, endpoints or credentials beside them

for base in "$END_USER_BASE_URL" "$ADMIN_BASE_URL"; do
  context=$(curl -k -f -s -H "Accept: application/n-triples" "${base}context")

  echo "$context" | grep -q '<https://w3id.org/atomgraph/linkeddatahub/dataspaces#EndUserDataspace>' || { echo "DEBUG: no EndUserDataspace in ${base}context"; exit 1; }
  echo "$context" | grep -q '<https://w3id.org/atomgraph/linkeddatahub/dataspaces#AdminDataspace>' || { echo "DEBUG: no AdminDataspace in ${base}context"; exit 1; }
  echo "$context" | grep -q "<https://w3id.org/atomgraph/linkeddatahub/dataspaces#admin> <${ADMIN_BASE_URL}>" || { echo "DEBUG: no lds:admin <${ADMIN_BASE_URL}> in ${base}context"; exit 1; }

  if echo "$context" | grep -q -E 'atomgraph/core#|sparql-service-description#Service|fuseki:3030|dataspaces#service>|dataspaces#versioningRepository>'; then
    echo "DEBUG: ${base}context leaks internal wiring:"
    echo "$context" | grep -E 'atomgraph/core#|sparql-service-description#Service|fuseki:3030|dataspaces#service>|dataspaces#versioningRepository>'
    exit 1
  fi
done
