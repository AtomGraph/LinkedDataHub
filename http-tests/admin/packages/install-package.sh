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
  "$ADMIN_BASE_URL"packages/install \
| grep -q "$STATUS_SEE_OTHER"

# verify package stylesheet was installed to filesystem
# path should be: /static/com/linkeddatahub/packages/skos/layout.xsl
docker compose -f "$HTTP_TEST_ROOT/../docker-compose.yml" \
  -f "$HTTP_TEST_ROOT/docker-compose.http-tests.yml" \
  --env-file "$HTTP_TEST_ROOT/.env" \
  exec -T linkeddatahub \
  test -f /usr/local/tomcat/webapps/ROOT/static/com/linkeddatahub/packages/skos/layout.xsl

# verify master stylesheet was regenerated and includes package import
docker compose -f "$HTTP_TEST_ROOT/../docker-compose.yml" \
  -f "$HTTP_TEST_ROOT/docker-compose.http-tests.yml" \
  --env-file "$HTTP_TEST_ROOT/.env" \
  exec -T linkeddatahub \
  grep -q "com/linkeddatahub/packages/skos/layout.xsl" \
  /usr/local/tomcat/webapps/ROOT/static/localhost/layout.xsl
