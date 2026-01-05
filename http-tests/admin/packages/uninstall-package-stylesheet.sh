#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# test package URI (SKOS package)
package_uri="https://packages.linkeddatahub.com/skos/#this"

# first install the package
install-package.sh \
  -b "$END_USER_BASE_URL" \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --package "$package_uri" \
| grep -q "$STATUS_SEE_OTHER"

# verify package stylesheet exists before uninstall (should return 200)
curl -k -f -s -o /dev/null \
  "${END_USER_BASE_URL}static/com/linkeddatahub/packages/skos/layout.xsl"

# uninstall package
uninstall-package.sh \
  -b "$END_USER_BASE_URL" \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --package "$package_uri" \
| grep -q "$STATUS_SEE_OTHER"

# Wait for Tomcat's static resource cache to expire
# Tomcat caches static files with default cacheTtl=5000ms (5 seconds)
# See: https://tomcat.apache.org/tomcat-10.1-doc/config/resources.html#Attributes
default_ttl=5
sleep $default_ttl

# verify package stylesheet was deleted (should return 404)
curl -k -w "%{http_code}\n" -o /dev/null -s \
  "${END_USER_BASE_URL}static/com/linkeddatahub/packages/skos/layout.xsl" \
| grep -q "$STATUS_NOT_FOUND"

# verify master stylesheet was regenerated without package import
master_xsl=$(curl -k -s "${END_USER_BASE_URL}static/xsl/layout.xsl")
if echo "$master_xsl" | grep -q "com/linkeddatahub/packages/skos/layout.xsl"; then
  exit 1
fi
