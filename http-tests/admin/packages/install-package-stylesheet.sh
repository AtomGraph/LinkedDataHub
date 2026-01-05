#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# test package URI (SKOS package)
package_uri="https://packages.linkeddatahub.com/skos/#this"

# install package via POST to packages/install endpoint
curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "package-uri=$package_uri" \
  "${ADMIN_BASE_URL}packages/install" \
| grep -q "$STATUS_SEE_OTHER"

# Purge cache after install to clear any cached 404 responses
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# Wait for package installation to complete (poll for stylesheet availability)
elapsed=0
iteration=0
while [ $(echo "$elapsed < 30" | bc) -eq 1 ]; do
  # Get status and headers via proxy in one request
  proxy_response=$(curl -k -s -I "${END_USER_BASE_URL}static/com/linkeddatahub/packages/skos/layout.xsl")
  stylesheet_status=$(echo "$proxy_response" | head -1 | grep -oE '[0-9]{3}')

  iteration=$((iteration + 1))

  # Only break on success after at least 2 iterations (to see Age > 0)
  if [ "$stylesheet_status" = "200" ] && [ $iteration -ge 2 ]; then
    break
  fi

  echo "--- Waiting for stylesheet (${elapsed}s) ---"
  echo "Via proxy: HTTP $stylesheet_status"
  echo "$proxy_response" | grep -E "(Age|X-Cache|X-Varnish)" || echo "(no cache headers)"

  # Check file on disk
  docker compose exec -T linkeddatahub ls -l webapps/ROOT/static/com/linkeddatahub/packages/skos || echo "Directory does not exist"

  # Test direct access to Tomcat (bypasses Varnish/Nginx cache)
  internal_status=$(docker compose exec -T nginx curl -s -w "%{http_code}\n" -o /dev/null http://linkeddatahub:8080/static/com/linkeddatahub/packages/skos/layout.xsl)
  echo "Direct Tomcat: HTTP $internal_status"

  sleep 0.5
  elapsed=$(echo "$elapsed + 0.5" | bc)
done

if [ "$stylesheet_status" != "200" ]; then
  echo "--- Final check after timeout ---"
  docker compose exec -T linkeddatahub ls -l webapps/ROOT/static/com/linkeddatahub/packages/skos || echo "Directory does not exist"
  exit 1
fi

# verify package stylesheet was installed (should return 200)
curl -k -f -s -o /dev/null \
  "${END_USER_BASE_URL}static/com/linkeddatahub/packages/skos/layout.xsl"

# verify master stylesheet was regenerated and includes package import
curl -k -s "${END_USER_BASE_URL}static/xsl/layout.xsl" \
  | grep -q "com/linkeddatahub/packages/skos/layout.xsl"
