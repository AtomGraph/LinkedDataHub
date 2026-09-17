#!/usr/bin/env bash
set -euo pipefail

# Each dataspace answers /sitemap.xml and /robots.txt from a file named after the requested host, written at
# container startup and rewritten to by WEB-INF/rewrite.config. That is what this pins: a configured origin
# answers, an unconfigured one does not, and the platform's own resource layer is not involved.
#
# No fixture of this stack grants public read to an end-user document, so neither dataspace has a sitemap and every
# robots.txt disallows crawling. The cross-dataspace assertion these two dataspaces exist for - both are wired to
# the same stores, so neither sitemap may carry the other's documents - therefore cannot run here, and is not
# silently skipped below: it needs a publicly readable document at startup, which no mount of this stack can
# currently provide (http-tests/root-owner.trig.template is mounted at a path the entrypoint does not read).
#
# Every assertion reads its subject from a here-string rather than piping an echo into grep -q: grep matches and
# closes the pipe with the rest of the response unwritten, and under `set -o pipefail` the SIGPIPE'd echo fails the
# pipeline on a response that was correct.

test_base_url="https://test.localhost:4443/"

# robots.txt answers per origin, as plain text

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

  # nothing is publicly readable in this stack, so no origin names a sitemap
  grep -qF "Disallow: /" <<< "$robots"

  if grep -qF "Sitemap:" <<< "$robots"; then
    echo "robots.txt of <${base_url}> names a sitemap, but no document here is publicly readable"
    exit 1
  fi
done

# a dataspace with no public document has no sitemap either, rather than an empty urlset

for base_url in "$END_USER_BASE_URL" "$test_base_url" "$ADMIN_BASE_URL"; do
  code=$(curl -k -w "%{http_code}" -o /dev/null -s "${base_url}sitemap.xml")
  echo "DEBUG: ${base_url}sitemap.xml expected: $STATUS_NOT_FOUND"
  echo "DEBUG: Got: $code"
  grep -qE "^(${STATUS_NOT_FOUND})$" <<< "$code"
done

# and a host that is no dataspace at all has neither file, which is what makes the answers above per-origin

for path in "robots.txt" "sitemap.xml"; do
  code=$(curl -k -w "%{http_code}" -o /dev/null -s "https://non-existing.localhost:4443/${path}")
  echo "DEBUG: non-existing.localhost/${path} expected: $STATUS_NOT_FOUND"
  echo "DEBUG: Got: $code"
  grep -qE "^(${STATUS_NOT_FOUND})$" <<< "$code"
done
