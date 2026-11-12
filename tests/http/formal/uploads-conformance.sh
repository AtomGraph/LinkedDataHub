#!/usr/bin/env bash
set -euo pipefail

# The Lean model of serving an upload (formal/uploads, LdhUploads.Serve) replayed against the server. A file is
# uploaded, and ldh-uploads predicts the status and Content-Range of a GET for every combination of a Range, an
# If-None-Match, an If-Range and an Accept it lists; the server has to answer the same, and every 200 and 206 has to
# carry the sandbox policy (served_sandboxed).
#
# UPLOADS_CONFORMANCE_PROXIED sends every request through the Linked Data proxy instead, as ?uri= on the admin base
# (one on the end-user base is not proxied but served as the file), with the same prediction
# (uploads-conformance-proxied.sh). The proxy forwards Accept and If-None-Match but neither Range nor If-Range; the
# front cache serves the range from the whole file the proxy relays, evaluating If-Range against the origin's ETag the
# proxy forwards, so the client gets the same answer. The sandbox policy is required all the same: the bytes are then
# served from the proxy's origin.

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

model="${LDH_UPLOADS_MODEL:-$HTTP_TEST_ROOT/../../formal/uploads/.lake/build/bin/ldh-uploads}"
if [ ! -x "$model" ]; then
    echo "DEBUG: ldh-uploads not found at $model: run 'lake build' in formal/uploads, or point LDH_UPLOADS_MODEL at it" >&2
    exit 1
fi

ldh admin add agent \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# under nginx's gzip_min_length, so the body is served as it is stored
length=1000
dd if=/dev/urandom of="$work/file" bs=1 count=$length 2>/dev/null
sha1sum=$(shasum -a 1 "$work/file" | awk '{print $1}')
file="${END_USER_BASE_URL}uploads/${sha1sum}"

doc=$(ldh create item \
  -c "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --title "Conformance file" \
  --container "$END_USER_BASE_URL")

ldh add file \
  -c "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --title "Conformance file" \
  --file "$work/file" \
  --content-type "application/octet-stream" \
  "$doc"

proxied="${UPLOADS_CONFORMANCE_PROXIED:-}"
url=("$file")
[ -n "$proxied" ] && url=(--url-query "uri=$file" "$ADMIN_BASE_URL")

failures=0
cases=0
while IFS=$'\t' read -r range inm if_range accept status content_range
do
    cases=$((cases + 1))
    args=(-k -s -o /dev/null -D "$work/headers" -w "%{http_code}" -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" -H "Accept: $accept" -H "If-Range: $if_range")
    [ "$range" != "-" ] && args+=(-H "Range: $range")
    [ "$inm" != "-" ] && args+=(-H "If-None-Match: $inm")

    got_status=$(curl "${args[@]}" "${url[@]}")
    got_range=$(tr -d '\r' < "$work/headers" | sed -n 's/^[Cc]ontent-[Rr]ange: *//p')
    got_csp=$(tr -d '\r' < "$work/headers" | sed -n 's/^[Cc]ontent-[Ss]ecurity-[Pp]olicy: *//p')
    [ -n "$got_range" ] || got_range="-"

    if [ "$got_status" != "$status" ] || [ "$got_range" != "$content_range" ]; then
        echo "DEBUG: Range: $range, If-None-Match: $inm, If-Range: $if_range, Accept: $accept"
        echo "DEBUG: Expected: $status $content_range Got: $got_status $got_range"
        failures=$((failures + 1))
    elif { [ "$status" = "200" ] || [ "$status" = "206" ]; } && [ "$got_csp" != "default-src 'none'; sandbox" ]; then
        echo "DEBUG: Range: $range, If-None-Match: $inm, If-Range: $if_range, Accept: $accept"
        echo "DEBUG: $status without the sandbox policy: '$got_csp'"
        failures=$((failures + 1))
    fi
done < <("$model" cases "$length" "$sha1sum")

echo "DEBUG: $cases cases, $failures disagreeing with the model${proxied:+, through the proxy}"
[ "$cases" -gt 0 ]
[ "$failures" -eq 0 ]
