#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# Each dataspace answers /sitemap.xml and /robots.txt from SitemapServlet, which queries the documents a public read
# rule of that dataspace grants access to (the test stack sets ENABLE_SITEMAP=true). The two end-user dataspaces of
# this stack share their stores, so a public document of one must not appear in the other's sitemap.
#
# Every assertion reads its subject from a here-string rather than piping an echo into grep -q: grep matches and
# closes the pipe with the rest of the response unwritten, and under `set -o pipefail` the SIGPIPE'd echo fails the
# pipeline on a response that was correct.

test_base_url="https://test.localhost:4443/"

# nothing is publicly readable yet: every robots.txt disallows crawling, as plain text, and no dataspace has a sitemap

for base_url in "$END_USER_BASE_URL" "$test_base_url" "$ADMIN_BASE_URL"; do
  code=$(curl -k -w "%{http_code}" -o /dev/null -s "${base_url}robots.txt")
  echo "DEBUG: ${base_url}robots.txt expected: $STATUS_OK"
  echo "DEBUG: Got: $code"
  grep -qE "^(${STATUS_OK})$" <<< "$code"

  content_type=$(curl -k -s -o /dev/null -w "%{content_type}" "${base_url}robots.txt")
  echo "DEBUG: Expected content type: text/plain"
  echo "DEBUG: Got: $content_type"
  grep -q "text/plain" <<< "$content_type"

  robots=$(curl -k -s "${base_url}robots.txt")
  echo "DEBUG: ${base_url}robots.txt: $robots"
  grep -qF "User-agent: *" <<< "$robots"
  grep -qF "Disallow: /" <<< "$robots"

  if grep -qF "Sitemap:" <<< "$robots"; then
    echo "robots.txt of <${base_url}> names a sitemap, but no document here is publicly readable"
    exit 1
  fi

  code=$(curl -k -w "%{http_code}" -o /dev/null -s "${base_url}sitemap.xml")
  echo "DEBUG: ${base_url}sitemap.xml expected: $STATUS_NOT_FOUND"
  echo "DEBUG: Got: $code"
  grep -qE "^(${STATUS_NOT_FOUND})$" <<< "$code"
done

# a host that is no dataspace at all has neither, which is what makes the answers per-origin

for path in "robots.txt" "sitemap.xml"; do
  code=$(curl -k -w "%{http_code}" -o /dev/null -s "https://non-existing.localhost:4443/${path}")
  echo "DEBUG: non-existing.localhost/${path} expected: $STATUS_NOT_FOUND"
  echo "DEBUG: Got: $code"
  grep -qE "^(${STATUS_NOT_FOUND})$" <<< "$code"
done

# make the root document of the end-user dataspace public

ldh admin create authorization \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --label "Public access authorization" \
  --agent-class 'http://xmlns.com/foaf/0.1/Agent' \
  --to "$END_USER_BASE_URL" \
  --read \
  "$ADMIN_BASE_URL" > /dev/null

purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# the end-user dataspace is now crawlable and names its sitemap; the other two still disallow crawling

robots=$(curl -k -s "${END_USER_BASE_URL}robots.txt")
echo "DEBUG: ${END_USER_BASE_URL}robots.txt: $robots"
grep -qF "Allow: /" <<< "$robots"
grep -qxF "Sitemap: ${END_USER_BASE_URL}sitemap.xml" <<< "$robots"

for base_url in "$test_base_url" "$ADMIN_BASE_URL"; do
  robots=$(curl -k -s "${base_url}robots.txt")
  echo "DEBUG: ${base_url}robots.txt: $robots"
  grep -qF "Disallow: /" <<< "$robots"
done

# one public document fits in a single sitemap, served as /sitemap.xml itself, with a max-age for the frontend cache

headers=$(curl -k -s -D - -o /dev/null "${END_USER_BASE_URL}sitemap.xml")
echo "DEBUG: ${END_USER_BASE_URL}sitemap.xml headers: $headers"
grep -qE "^HTTP/[0-9.]+ ${STATUS_OK}" <<< "$headers"
grep -qi "^Content-Type: application/xml" <<< "$headers"
grep -qi "^Cache-Control: public, max-age=" <<< "$headers"

sitemap=$(curl -k -s "${END_USER_BASE_URL}sitemap.xml")
echo "DEBUG: ${END_USER_BASE_URL}sitemap.xml: $sitemap"
grep -qF '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' <<< "$sitemap"
grep -qF "<loc>${END_USER_BASE_URL}</loc>" <<< "$sitemap"

# the dataspace sharing its stores lists none of it

code=$(curl -k -w "%{http_code}" -o /dev/null -s "${test_base_url}sitemap.xml")
echo "DEBUG: ${test_base_url}sitemap.xml expected: $STATUS_NOT_FOUND"
echo "DEBUG: Got: $code"
grep -qE "^(${STATUS_NOT_FOUND})$" <<< "$code"

# a bucket is a prefix of the MD5 of the document URI: the document's own bucket lists it, another one is empty,
# and a value that is no prefix is no sitemap

bucket=$(printf '%s' "$END_USER_BASE_URL" | openssl md5 -r | cut -c1-2)
other_bucket=$( [ "$bucket" = "00" ] && echo "ff" || echo "00" )
echo "DEBUG: bucket of <${END_USER_BASE_URL}>: $bucket"

sitemap=$(curl -k -s "${END_USER_BASE_URL}sitemap.xml?bucket=${bucket}")
echo "DEBUG: ${END_USER_BASE_URL}sitemap.xml?bucket=${bucket}: $sitemap"
grep -qF "<loc>${END_USER_BASE_URL}</loc>" <<< "$sitemap"

for value in "$other_bucket" "zz" "abc"; do
  code=$(curl -k -w "%{http_code}" -o /dev/null -s "${END_USER_BASE_URL}sitemap.xml?bucket=${value}")
  echo "DEBUG: ${END_USER_BASE_URL}sitemap.xml?bucket=${value} expected: $STATUS_NOT_FOUND"
  echo "DEBUG: Got: $code"
  grep -qE "^(${STATUS_NOT_FOUND})$" <<< "$code"
done
