#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# test package URI (SKOS package)
package_uri="https://packages.linkeddatahub.com/skos/#this"

# install package
install-package.sh \
  -b "$END_USER_BASE_URL" \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --package "$package_uri" \
| grep -q "$STATUS_SEE_OTHER"

# the stylesheet is not available via URL right away. If we request it right away, Varnish will cache a 404 Not Found response for it
# TO-DO: make sure the stylesheet URL is available immediately after installation
sleep 2

# verify package stylesheet was installed (should return 200)
curl -k -f -s -o /dev/null \
  "${END_USER_BASE_URL}static/com/linkeddatahub/packages/skos/layout.xsl"

# verify master stylesheet was regenerated and includes package import
curl -k -s "${END_USER_BASE_URL}static/xsl/layout.xsl" \
  | grep -q "com/linkeddatahub/packages/skos/layout.xsl"
