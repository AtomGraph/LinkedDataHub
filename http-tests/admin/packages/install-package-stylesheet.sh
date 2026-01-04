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

# Wait for package installation to complete (poll for stylesheet availability)
echo "--- Initial logs after install request ---"
docker compose logs --tail=50 linkeddatahub
elapsed=0
while [ $(echo "$elapsed < 30" | bc) -eq 1 ]; do
  stylesheet_status=$(curl -k -w "%{http_code}\n" -o /dev/null -s \
    "${END_USER_BASE_URL}static/com/linkeddatahub/packages/skos/layout.xsl")
  if [ "$stylesheet_status" = "200" ]; then
    break
  fi
  echo "--- Waiting for stylesheet (${elapsed}s, status: $stylesheet_status) ---"
  docker compose logs --tail=50 linkeddatahub
  sleep 0.5
  elapsed=$(echo "$elapsed + 0.5" | bc)
done

if [ "$stylesheet_status" != "200" ]; then
  echo "--- Final logs after timeout ---"
  docker compose logs --tail=50 linkeddatahub
  exit 1
fi

# verify package stylesheet was installed (should return 200)
curl -k -f -s -o /dev/null \
  "${END_USER_BASE_URL}static/com/linkeddatahub/packages/skos/layout.xsl"

# verify master stylesheet was regenerated and includes package import
curl -k -s "${END_USER_BASE_URL}static/xsl/layout.xsl" \
  | grep -q "com/linkeddatahub/packages/skos/layout.xsl"
