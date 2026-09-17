#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# Each dataspace serves its own sitemap and robots.txt. Both dataspaces here are wired to the same two Fuseki
# endpoints, so a sitemap carrying another origin's documents is the regression this guards: the location of a
# sitemap determines the URLs it may contain (https://www.sitemaps.org/protocol.html).
# The sitemaps are generated at container startup from the public read rules, so this reads what that produced
# rather than granting access itself - root-owner.trig.template makes the root document of each dataspace
# publicly readable through a class rule, the shape that can match documents across dataspaces sharing a store.
#
# Every assertion reads its subject from a here-string rather than piping an echo into grep -q: grep matches and
# closes the pipe with the rest of the sitemap unwritten, and under `set -o pipefail` the SIGPIPE'd echo fails the
# pipeline on a response that was correct.

test_base_url="https://test.localhost:4443/"

# the root dataspace serves XML

code=$(curl -k -w "%{http_code}" -o /dev/null -s "${END_USER_BASE_URL}sitemap.xml")
echo "DEBUG: Expected: $STATUS_OK"
echo "DEBUG: Got: $code"
grep -qE "^(${STATUS_OK})$" <<< "$code"

content_type=$(curl -k -s -o /dev/null -w "%{content_type}" "${END_USER_BASE_URL}sitemap.xml")
echo "DEBUG: Expected content type: application/xml"
echo "DEBUG: Got: $content_type"
grep -q "application/xml" <<< "$content_type"

# and lists its own public root document, and nothing of the other dataspace

sitemap=$(curl -k -s "${END_USER_BASE_URL}sitemap.xml")
echo "DEBUG: Root sitemap: $sitemap"

grep -qF "<loc>${END_USER_BASE_URL}</loc>" <<< "$sitemap"

if grep -qF "$test_base_url" <<< "$sitemap"; then
  echo "Root sitemap lists documents of <${test_base_url}>"
  exit 1
fi

# the other dataspace lists its own, and every URL it lists is under its own origin

test_sitemap=$(curl -k -s "${test_base_url}sitemap.xml")
echo "DEBUG: Test sitemap: $test_sitemap"

grep -qF "<loc>${test_base_url}</loc>" <<< "$test_sitemap"

while read -r loc; do
  echo "DEBUG: Checking loc: $loc"

  case "$loc" in
    "${test_base_url}"*) ;;
    *) echo "Test sitemap lists <${loc}>, which is not under <${test_base_url}>" ; exit 1 ;;
  esac
done < <(sed -n 's|.*<loc>\(.*\)</loc>.*|\1|p' <<< "$test_sitemap")

# robots.txt names the sitemap of its own origin, so a crawler reaching it finds one it is allowed to trust

robots=$(curl -k -s "${END_USER_BASE_URL}robots.txt")
echo "DEBUG: Root robots.txt: $robots"

grep -qF "Sitemap: ${END_USER_BASE_URL}sitemap.xml" <<< "$robots"

test_robots=$(curl -k -s "${test_base_url}robots.txt")
echo "DEBUG: Test robots.txt: $test_robots"

grep -qF "Sitemap: ${test_base_url}sitemap.xml" <<< "$test_robots"

if grep -qF "Sitemap: ${END_USER_BASE_URL}sitemap.xml" <<< "$test_robots"; then
  echo "Test robots.txt points at the sitemap of <${END_USER_BASE_URL}>"
  exit 1
fi

# an admin dataspace describes agents, keys and authorizations, so it has no sitemap and says so

code=$(curl -k -w "%{http_code}" -o /dev/null -s "${ADMIN_BASE_URL}sitemap.xml")
echo "DEBUG: Expected: $STATUS_NOT_FOUND"
echo "DEBUG: Got: $code"
grep -qE "^(${STATUS_NOT_FOUND})$" <<< "$code"

admin_robots=$(curl -k -s "${ADMIN_BASE_URL}robots.txt")
echo "DEBUG: Admin robots.txt: $admin_robots"

grep -qF "Disallow: /" <<< "$admin_robots"

# neither is a dataspace that is not configured

code=$(curl -k -w "%{http_code}" -o /dev/null -s "https://non-existing.localhost:4443/sitemap.xml")
echo "DEBUG: Expected: $STATUS_NOT_FOUND"
echo "DEBUG: Got: $code"
grep -qE "^(${STATUS_NOT_FOUND})$" <<< "$code"
