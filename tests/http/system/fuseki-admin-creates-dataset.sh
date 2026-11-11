#!/usr/bin/env bash
set -euo pipefail

# Fuseki's admin API makes a dataset at runtime, so a dataset per dataspace can be created without editing config.ttl
# and restarting the server: to the administrator only (FUSEKI_ADMIN_PASSWORD, which `make secrets` writes to .env),
# serving queries and updates as soon as it is made, and gone when it is removed. The suite reaches Fuseki on the
# port docker-compose.http-tests.yml publishes

password="${FUSEKI_ADMIN_PASSWORD:-$(sed -n 's/^FUSEKI_ADMIN_PASSWORD=//p' ../.env)}"
[ -n "$password" ] || { echo "DEBUG: FUSEKI_ADMIN_PASSWORD is neither in the environment nor in tests/http/.env"; exit 1; }

fuseki="http://localhost:3030"
name="created-$(uuidgen | tr '[:upper:]' '[:lower:]')"

# nobody else creates a dataset
status=$(curl -s -o /dev/null -w '%{http_code}' -d "dbName=${name}" -d "dbType=tdb2" "${fuseki}/\$/datasets")
[ "$status" = "$STATUS_UNAUTHORIZED" ] || { echo "DEBUG: creating a dataset without credentials answered $status"; exit 1; }
status=$(curl -s -o /dev/null -w '%{http_code}' -u "admin:not-the-password" -d "dbName=${name}" -d "dbType=tdb2" "${fuseki}/\$/datasets")
[ "$status" = "$STATUS_UNAUTHORIZED" ] || { echo "DEBUG: creating a dataset with the wrong password answered $status"; exit 1; }

# the administrator does
status=$(curl -s -o /dev/null -w '%{http_code}' -u "admin:${password}" -d "dbName=${name}" -d "dbType=tdb2" "${fuseki}/\$/datasets")
[ "$status" = "$STATUS_OK" ] || { echo "DEBUG: creating a dataset answered $status"; exit 1; }

# and the dataset serves updates and queries at once
status=$(curl -s -o /dev/null -w '%{http_code}' --data-urlencode "update=INSERT DATA { <urn:test:s> <urn:test:p> <urn:test:o> }" "${fuseki}/${name}/update")
[[ "$status" =~ ^($STATUS_UPDATED|$STATUS_OK)$ ]] || { echo "DEBUG: an update on the created dataset answered $status"; exit 1; }
answer=$(curl -s -H "Accept: text/csv" --data-urlencode "query=ASK { <urn:test:s> <urn:test:p> <urn:test:o> }" "${fuseki}/${name}/sparql" | tail -1 | tr -d '\r')
[ "$answer" = "true" ] || { echo "DEBUG: the created dataset does not hold what was inserted: $answer"; exit 1; }

# removed by the administrator, it is gone
status=$(curl -s -o /dev/null -w '%{http_code}' -u "admin:${password}" -X DELETE "${fuseki}/\$/datasets/${name}")
[ "$status" = "$STATUS_OK" ] || { echo "DEBUG: removing the dataset answered $status"; exit 1; }
status=$(curl -s -o /dev/null -w '%{http_code}' --data-urlencode "query=ASK {}" "${fuseki}/${name}/sparql")
[ "$status" = "$STATUS_NOT_FOUND" ] || { echo "DEBUG: the removed dataset still answered $status"; exit 1; }
