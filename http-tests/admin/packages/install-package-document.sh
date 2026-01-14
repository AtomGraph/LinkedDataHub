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

# verify package document was created (hash of package URI)
package_hash=$(echo -n "$package_uri" | shasum -a 1 | cut -d' ' -f1)
curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  "${ADMIN_BASE_URL}packages/${package_hash}/" \
| grep -qE "^($STATUS_OK|$STATUS_NOT_MODIFIED)$"

# uninstall package
uninstall-package.sh \
  -b "$END_USER_BASE_URL" \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --package "$package_uri" \
| grep -q "$STATUS_SEE_OTHER"

# verify package document was deleted
#curl -k -w "%{http_code}\n" -o /dev/null -s \
#  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
#  "${ADMIN_BASE_URL}packages/${package_hash}/" \
#| grep -q "$STATUS_FORBIDDEN"
