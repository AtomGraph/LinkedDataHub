#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# After `ldh admin make-public` anyone may query the end-user endpoint, over GET and over POST. The POST grant is an
# authorization of its own (acl:Append on <sparql>), in a document of its own: an authorization counts only in the
# document whose primary topic it is.

query="ASK {}"

anonymous_query()
{
    local method="$1"

    if [ "$method" = "GET" ]; then
        curl -k -w "%{http_code}" -o /dev/null -s -G \
          -H "Accept: application/sparql-results+json" \
          --data-urlencode "query=${query}" \
          "${END_USER_BASE_URL}sparql"
    else
        curl -k -w "%{http_code}" -o /dev/null -s \
          -H "Accept: application/sparql-results+json" \
          --data-urlencode "query=${query}" \
          "${END_USER_BASE_URL}sparql"
    fi
}

for method in GET POST; do
    status=$(anonymous_query "$method")
    echo "DEBUG: anonymous ${method} query before make-public. Expected: $STATUS_FORBIDDEN Got: $status"
    [ "$status" = "$STATUS_FORBIDDEN" ] || exit 1
done

ldh admin make-public \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  "$END_USER_BASE_URL"

for method in GET POST; do
    status=$(anonymous_query "$method")
    echo "DEBUG: anonymous ${method} query after make-public. Expected: $STATUS_OK Got: $status"
    [ "$status" = "$STATUS_OK" ] || exit 1
done
