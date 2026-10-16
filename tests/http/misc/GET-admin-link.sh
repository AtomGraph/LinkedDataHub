#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

admin_rel='https://w3id.org/atomgraph/linkeddatahub/dataspaces#admin'

links() {
  curl -k -f -s -o /dev/null -D - -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" -H "Accept: application/n-triples" "$@" | grep -i '^link:' | tr ',' '\n'
}

# an end-user response links its administration application

end_user_links=$(links "$END_USER_BASE_URL")
echo "$end_user_links" | grep "$admin_rel" | grep -q "<${ADMIN_BASE_URL}>" || { echo "DEBUG: end-user links: $end_user_links"; exit 1; }

# an admin response does not

if links "$ADMIN_BASE_URL" | grep -q "$admin_rel"; then
  echo "DEBUG: the admin root advertises lds:admin"
  exit 1
fi

# nor does a proxied response, which describes a remote application

if links -G --data-urlencode "uri=http://www.w3.org/2004/02/skos/core" "$END_USER_BASE_URL" | grep -q "$admin_rel"; then
  echo "DEBUG: a proxied response advertises lds:admin"
  exit 1
fi
