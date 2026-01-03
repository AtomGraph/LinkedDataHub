#!/usr/bin/env bash
set -euo pipefail

echo "### STEP 1: Initializing datasets"
initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# test package URI (SKOS package)
package_uri="https://packages.linkeddatahub.com/skos/#this"

# install package via POST to packages/install endpoint
echo "### STEP 2: Installing package"
install_status=$(curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "package-uri=$package_uri" \
  "${ADMIN_BASE_URL}packages/install")
echo "Install status: $install_status (expected: $STATUS_SEE_OTHER)"
echo "$install_status" | grep -q "$STATUS_SEE_OTHER"

# Verify stylesheet file exists in Tomcat's webapps directory
docker compose exec -T linkeddatahub ls -l webapps/ROOT/static/com/linkeddatahub/packages/skos

# Make internal request from nginx to Tomcat to warm up static file cache
docker compose exec -T nginx curl -s -o /dev/null http://linkeddatahub:7070/static/com/linkeddatahub/packages/skos/layout.xsl

# verify package stylesheet was installed (should return 200)
echo "### STEP 3: Verifying package stylesheet exists"
stylesheet_status=$(curl -k -w "%{http_code}\n" -o /dev/null -s \
  "${END_USER_BASE_URL}static/com/linkeddatahub/packages/skos/layout.xsl")
echo "Stylesheet status: $stylesheet_status (expected: 200)"
if [ "$stylesheet_status" != "200" ]; then
  echo "ERROR: Expected 200, got $stylesheet_status"
  exit 1
fi

# verify master stylesheet was regenerated and includes package import
echo "### STEP 4: Verifying master stylesheet includes package"
master_xsl=$(curl -k -s "${END_USER_BASE_URL}static/xsl/layout.xsl")
if echo "$master_xsl" | grep -q "com/linkeddatahub/packages/skos/layout.xsl"; then
  echo "OK: Master stylesheet contains SKOS import"
else
  echo "ERROR: Master stylesheet does not contain SKOS import"
  echo "Master stylesheet content:"
  echo "$master_xsl"
  exit 1
fi
echo "All checks passed"
