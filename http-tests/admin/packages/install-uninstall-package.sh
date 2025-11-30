#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# test package URI (SKOS package)
package_uri="https://packages.linkeddatahub.com/skos/#this"

# ensure package is not installed initially
docker compose -f "$HTTP_TEST_ROOT/../docker-compose.yml" \
  -f "$HTTP_TEST_ROOT/docker-compose.http-tests.yml" \
  --env-file "$HTTP_TEST_ROOT/.env" \
  exec -T linkeddatahub \
  test ! -f /usr/local/tomcat/webapps/ROOT/static/com/linkeddatahub/packages/skos/layout.xsl || true

# install package
curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "package-uri=$package_uri" \
  "$ADMIN_BASE_URL"packages/install \
| grep -q "$STATUS_SEE_OTHER"

# verify package was installed
docker compose -f "$HTTP_TEST_ROOT/../docker-compose.yml" \
  -f "$HTTP_TEST_ROOT/docker-compose.http-tests.yml" \
  --env-file "$HTTP_TEST_ROOT/.env" \
  exec -T linkeddatahub \
  test -f /usr/local/tomcat/webapps/ROOT/static/com/linkeddatahub/packages/skos/layout.xsl

# verify master stylesheet includes package
docker compose -f "$HTTP_TEST_ROOT/../docker-compose.yml" \
  -f "$HTTP_TEST_ROOT/docker-compose.http-tests.yml" \
  --env-file "$HTTP_TEST_ROOT/.env" \
  exec -T linkeddatahub \
  grep -q "com/linkeddatahub/packages/skos/layout.xsl" \
  /usr/local/tomcat/webapps/ROOT/static/localhost/layout.xsl

# uninstall package
curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "package-uri=$package_uri" \
  "$ADMIN_BASE_URL"packages/uninstall \
| grep -q "$STATUS_SEE_OTHER"

# verify package was uninstalled
docker compose -f "$HTTP_TEST_ROOT/../docker-compose.yml" \
  -f "$HTTP_TEST_ROOT/docker-compose.http-tests.yml" \
  --env-file "$HTTP_TEST_ROOT/.env" \
  exec -T linkeddatahub \
  test ! -f /usr/local/tomcat/webapps/ROOT/static/com/linkeddatahub/packages/skos/layout.xsl

# verify master stylesheet no longer includes package
docker compose -f "$HTTP_TEST_ROOT/../docker-compose.yml" \
  -f "$HTTP_TEST_ROOT/docker-compose.http-tests.yml" \
  --env-file "$HTTP_TEST_ROOT/.env" \
  exec -T linkeddatahub \
  bash -c '! grep -q "com/linkeddatahub/packages/skos/layout.xsl" /usr/local/tomcat/webapps/ROOT/static/localhost/layout.xsl'
