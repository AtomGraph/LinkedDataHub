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
curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "package-uri=$package_uri" \
  "${ADMIN_BASE_URL}packages/install" \
| grep -q "$STATUS_SEE_OTHER"

# Wait for package installation to complete (poll for stylesheet availability)
max_wait=30  # maximum seconds to wait
wait_interval=0.5  # check every 0.5 seconds
elapsed=0
stylesheet_status=""

while [ $(echo "$elapsed < $max_wait" | bc) -eq 1 ]; do
  stylesheet_status=$(curl -k -w "%{http_code}\n" -o /dev/null -s \
    "${END_USER_BASE_URL}static/com/linkeddatahub/packages/skos/layout.xsl")
  if [ "$stylesheet_status" = "200" ]; then
    echo "Package stylesheet available after ${elapsed}s (status: $stylesheet_status)"
    break
  fi
  sleep $wait_interval
  elapsed=$(echo "$elapsed + $wait_interval" | bc)
done

if [ "$stylesheet_status" != "200" ]; then
  echo "ERROR: Package stylesheet not available after ${elapsed}s (status: $stylesheet_status)"
  exit 1
fi

# verify package stylesheet exists before uninstall (should return 200)
curl -k -f -s -o /dev/null \
  "${END_USER_BASE_URL}static/com/linkeddatahub/packages/skos/layout.xsl"

# uninstall package via POST to packages/uninstall endpoint
curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "package-uri=$package_uri" \
  "${ADMIN_BASE_URL}packages/uninstall" \
| grep -q "$STATUS_SEE_OTHER"

# Wait for package uninstallation to complete (poll for stylesheet removal)
max_wait=30  # maximum seconds to wait
wait_interval=0.5  # check every 0.5 seconds
elapsed=0
stylesheet_status=""

while [ $(echo "$elapsed < $max_wait" | bc) -eq 1 ]; do
  stylesheet_status=$(curl -k -w "%{http_code}\n" -o /dev/null -s \
    "${END_USER_BASE_URL}static/com/linkeddatahub/packages/skos/layout.xsl")
  if [ "$stylesheet_status" = "404" ]; then
    echo "Package stylesheet removed after ${elapsed}s (status: $stylesheet_status)"
    break
  fi
  sleep $wait_interval
  elapsed=$(echo "$elapsed + $wait_interval" | bc)
done

if [ "$stylesheet_status" != "404" ]; then
  echo "ERROR: Package stylesheet not removed after ${elapsed}s (status: $stylesheet_status)"
  exit 1
fi

# verify package stylesheet was deleted (should return 404)
curl -k -w "%{http_code}\n" -o /dev/null -s \
  "${END_USER_BASE_URL}static/com/linkeddatahub/packages/skos/layout.xsl" \
| grep -q "$STATUS_NOT_FOUND"

# verify master stylesheet was regenerated without package import
master_xsl=$(curl -k -s "${END_USER_BASE_URL}static/xsl/layout.xsl")
if echo "$master_xsl" | grep -q "com/linkeddatahub/packages/skos/layout.xsl"; then
  exit 1
fi
