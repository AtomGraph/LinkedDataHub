#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A malformed ?accept= value is refused with 400 before ApplicationFilter sets the dataspace. The response filters
# that look the dataspace up afterwards used to turn that refusal into a 500 ("already seeded in this scope").
# Crawlers send the unencoded +, which decodes to a space: application/rdf xml

for accept in "application%2Frdf+xml" "application/ld+json"; do
  for rest in "" "&uri=${END_USER_BASE_URL}"; do
    url="${END_USER_BASE_URL}?accept=${accept}${rest}"

    status=$(curl -k -s -o /dev/null -w "%{http_code}" \
      -H "Accept: text/html" \
      "$url")

    echo "DEBUG: anonymous GET $url Expected: $STATUS_BAD_REQUEST  Got: $status"
    if [ "$status" != "$STATUS_BAD_REQUEST" ]; then
      exit 1
    fi

    status=$(curl -k -s -o /dev/null -w "%{http_code}" \
      -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
      -H "Accept: text/html" \
      "$url")

    echo "DEBUG: owner GET $url Expected: $STATUS_BAD_REQUEST  Got: $status"
    if [ "$status" != "$STATUS_BAD_REQUEST" ]; then
      exit 1
    fi
  done
done

# the admin dataspace answers the same

status=$(curl -k -s -o /dev/null -w "%{http_code}" \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  "${ADMIN_BASE_URL}?accept=application%2Fld+json")

echo "DEBUG: owner GET admin ?accept=application%2Fld+json Expected: $STATUS_BAD_REQUEST  Got: $status"
if [ "$status" != "$STATUS_BAD_REQUEST" ]; then
  exit 1
fi

# a well-formed value still negotiates

status=$(curl -k -s -o /dev/null -w "%{http_code}" \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  "${END_USER_BASE_URL}?accept=application%2Fn-triples")

echo "DEBUG: owner GET ?accept=application%2Fn-triples Expected: $STATUS_OK  Got: $status"
if [ "$status" != "$STATUS_OK" ]; then
  exit 1
fi
