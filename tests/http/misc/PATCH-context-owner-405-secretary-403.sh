#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# the owners control the context as they control the rest of the admin dataspace: a write on it passes the
# authorization and reaches the resource, which the platform's own serves read-only (405); an extension that
# keeps the dataspace descriptions elsewhere adds the PATCH. The secretary, a writer, has no say over the context

update="DROP GRAPH <urn:linkeddatahub:apps/nothing>"

status=$(curl -k -s -o /dev/null -w '%{http_code}' -E "$OWNER_CERT_FILE:$OWNER_CERT_PWD" -X PATCH -H "Content-Type: application/sparql-update" --data-binary "$update" "${ADMIN_BASE_URL}context")
[ "$status" = "405" ] || { echo "DEBUG: the owner's PATCH of the context answered $status, not 405"; exit 1; }

status=$(curl -k -s -o /dev/null -w '%{http_code}' -E "$SECRETARY_CERT_FILE:$SECRETARY_CERT_PWD" -X PATCH -H "Content-Type: application/sparql-update" --data-binary "$update" "${ADMIN_BASE_URL}context")
[ "$status" = "403" ] || { echo "DEBUG: the secretary's PATCH of the context answered $status, not 403"; exit 1; }

status=$(curl -k -s -o /dev/null -w '%{http_code}' -X PATCH -H "Content-Type: application/sparql-update" --data-binary "$update" "${ADMIN_BASE_URL}context")
[ "$status" = "403" ] || { echo "DEBUG: an anonymous PATCH of the context answered $status, not 403"; exit 1; }
