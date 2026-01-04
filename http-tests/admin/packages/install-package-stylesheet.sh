#!/usr/bin/env bash
set -euo pipefail

# Helper to get millisecond timestamp
get_ms() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    python3 -c 'import time; print(int(time.time() * 1000))'
  else
    date +%s%3N
  fi
}

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
t1=$(get_ms)
install_status=$(curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "package-uri=$package_uri" \
  "${ADMIN_BASE_URL}packages/install")
t2=$(get_ms)
echo "Install status: $install_status (expected: $STATUS_SEE_OTHER) [took $((t2-t1))ms]"
echo "$install_status" | grep -q "$STATUS_SEE_OTHER"

# Wait for package installation to complete (poll for stylesheet availability)
echo "### Waiting for package installation to complete"
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

# Verify stylesheet file exists in Tomcat's webapps directory
# docker compose exec -T linkeddatahub ls -l webapps/ROOT/static/com/linkeddatahub/packages/skos

# Make internal request from nginx to Tomcat to warm up static file cache
t3=$(get_ms)
docker compose exec -T nginx curl -s -o /dev/null http://linkeddatahub:7070/static/com/linkeddatahub/packages/skos/layout.xsl
t4=$(get_ms)
echo "Internal request took $((t4-t3))ms"

# verify package stylesheet was installed (should return 200)
echo "### STEP 3: Verifying package stylesheet exists (delay since install: $((t4-t2))ms)"
t5=$(get_ms)
stylesheet_status=$(curl -k -w "%{http_code}\n" -o /dev/null -s \
  "${END_USER_BASE_URL}static/com/linkeddatahub/packages/skos/layout.xsl")
t6=$(get_ms)
echo "Stylesheet status: $stylesheet_status (expected: 200) [took $((t6-t5))ms]"
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
