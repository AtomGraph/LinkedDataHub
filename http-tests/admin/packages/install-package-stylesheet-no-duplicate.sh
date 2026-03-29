#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# Clean up any leftover package stylesheet files from previous test runs
docker compose exec -T linkeddatahub rm -rf /usr/local/tomcat/webapps/ROOT/static/com/linkeddatahub/packages/skos 2>/dev/null || true
docker compose exec -T linkeddatahub sed -i '/linkeddatahub\/packages\/skos\/layout.xsl/d' /usr/local/tomcat/webapps/ROOT/static/xsl/layout.xsl 2>/dev/null || true

# Tomcat caches static files with default cacheTtl=5000ms (5 seconds)
# See: https://tomcat.apache.org/tomcat-10.1-doc/config/resources.html#Attributes
default_ttl=5

# test package URI (SKOS package)
package_uri="https://packages.linkeddatahub.com/skos/#this"

# first install
install-package.sh \
  -b "$END_USER_BASE_URL" \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --package "$package_uri"

# Wait for Tomcat's static resource cache to expire
sleep $default_ttl

# verify exactly one import after first install
import_count=$(curl -k -s "${END_USER_BASE_URL}static/xsl/layout.xsl" \
  | grep -c "com/linkeddatahub/packages/skos/layout.xsl" || true)
if [ "$import_count" -ne 1 ]; then
  exit 1
fi

# second install (same package)
install-package.sh \
  -b "$END_USER_BASE_URL" \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --package "$package_uri"

# Wait for Tomcat's static resource cache to expire
sleep $default_ttl

# verify still exactly one import after second install (deduplication guard)
import_count=$(curl -k -s "${END_USER_BASE_URL}static/xsl/layout.xsl" \
  | grep -c "com/linkeddatahub/packages/skos/layout.xsl" || true)
if [ "$import_count" -ne 1 ]; then
  exit 1
fi

# cleanup
uninstall-package.sh \
  -b "$END_USER_BASE_URL" \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --package "$package_uri"
