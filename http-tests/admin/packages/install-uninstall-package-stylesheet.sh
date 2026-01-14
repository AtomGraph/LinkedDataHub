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

# verify package stylesheet does NOT exist initially (should return 404)
curl -k -w "%{http_code}\n" -o /dev/null -s \
  "${END_USER_BASE_URL}static/com/linkeddatahub/packages/skos/layout.xsl" \
| grep -q "$STATUS_NOT_FOUND"

# verify master stylesheet does NOT include package initially
if curl -k -s "${END_USER_BASE_URL}static/xsl/layout.xsl" | grep -q "com/linkeddatahub/packages/skos/layout.xsl"; then
  exit 1
fi

# install package
install-package.sh \
  -b "$END_USER_BASE_URL" \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --package "$package_uri"

# Wait for Tomcat's static resource cache to expire
sleep $default_ttl

# verify package stylesheet was installed (should return 200)
install_status=$(curl -k -w "%{http_code}\n" -o /dev/null -s \
  "${END_USER_BASE_URL}static/com/linkeddatahub/packages/skos/layout.xsl")
if [ "$install_status" != "200" ]; then
  exit 1
fi

# verify master stylesheet includes package
if ! curl -k -s "${END_USER_BASE_URL}static/xsl/layout.xsl" | grep -q "com/linkeddatahub/packages/skos/layout.xsl"; then
  exit 1
fi

# uninstall package
uninstall-package.sh \
  -b "$END_USER_BASE_URL" \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --package "$package_uri"

# Wait for Tomcat's static resource cache to expire
sleep $default_ttl

# verify package stylesheet was deleted (should return 404)
curl -k -w "%{http_code}\n" -o /dev/null -s \
  "${END_USER_BASE_URL}static/com/linkeddatahub/packages/skos/layout.xsl" \
| grep -q "$STATUS_NOT_FOUND"

# verify master stylesheet no longer includes package
if curl -k -s "${END_USER_BASE_URL}static/xsl/layout.xsl" | grep -q "com/linkeddatahub/packages/skos/layout.xsl"; then
  exit 1
fi
