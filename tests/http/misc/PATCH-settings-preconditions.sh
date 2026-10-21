#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A settings PATCH is a read-modify-write of the whole settings model, the way a document PATCH is, and is held
# to the same terms (#453): without If-Match it is refused with 428, with a tag that is not the current one with
# 412 naming the current tag, and If-Match: * - which holds for any state - counts as no tag at all. An accepted
# PATCH answers with the tag of what it wrote, which is what the next write quotes.

settings="${END_USER_BASE_URL}settings"

# patch <If-Match header or empty> <title>: prints the status code and the response's ETag, space-separated
function patch()
{
    local headers=(-H "Accept: application/n-triples" -H "Content-Type: application/sparql-update")
    if [ -n "$1" ]; then headers+=(-H "$1"); fi

    curl -k -s -o /dev/null -D - -w '%{http_code}' \
      -X PATCH \
      -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
      "${headers[@]}" \
      -d "PREFIX dct: <http://purl.org/dc/terms/>
DELETE { ?app dct:title ?title }
INSERT { ?app dct:title \"$2\" }
WHERE { ?app dct:title ?title }" \
      "$settings" \
    | tr -d '\r' \
    | awk 'tolower($1) == "etag:" { etag = $2 } { last = $0 } END { printf "%s %s", last, etag }'
}

function title()
{
    curl -k -s -f \
      -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
      -H "Accept: application/n-triples" \
      "$settings" \
    | grep '<http://purl.org/dc/terms/title>' | sed 's/.*> "\(.*\)" \.$/\1/'
}

original_title=$(title)
initial_etag=$(etag "$settings" "$OWNER_CERT_FILE" "$OWNER_CERT_PWD")
echo "DEBUG: original title: $original_title, initial ETag: $initial_etag"
[ -n "$initial_etag" ] || exit 1

read -r status _ <<< "$(patch "" "No precondition")"
echo "DEBUG: PATCH without If-Match. Expected: $STATUS_PRECONDITION_REQUIRED Got: $status"
[ "$status" = "$STATUS_PRECONDITION_REQUIRED" ] || exit 1

read -r status _ <<< "$(patch "If-Match: *" "Wildcard")"
echo "DEBUG: PATCH with If-Match: *. Expected: $STATUS_PRECONDITION_REQUIRED Got: $status"
[ "$status" = "$STATUS_PRECONDITION_REQUIRED" ] || exit 1

read -r status current_etag <<< "$(patch 'If-Match: "bogus"' "Bogus tag")"
echo "DEBUG: PATCH with a made-up tag. Expected: $STATUS_PRECONDITION_FAILED Got: $status"
[ "$status" = "$STATUS_PRECONDITION_FAILED" ] || exit 1
echo "DEBUG: the 412 names the current tag. Expected: $initial_etag Got: $current_etag"
[ "$current_etag" = "$initial_etag" ] || exit 1

echo "DEBUG: refused PATCHes left the title alone. Expected: $original_title Got: $(title)"
[ "$(title)" = "$original_title" ] || exit 1

read -r status written_etag <<< "$(patch "If-Match: $initial_etag" "Preconditions Title")"
echo "DEBUG: PATCH with the current tag. Expected: $STATUS_NO_CONTENT Got: $status"
[ "$status" = "$STATUS_NO_CONTENT" ] || exit 1

after_etag=$(etag "$settings" "$OWNER_CERT_FILE" "$OWNER_CERT_PWD")
echo "DEBUG: the 204 carries the tag of the new state. Expected: $after_etag Got: $written_etag"
[ -n "$written_etag" ] && [ "$written_etag" = "$after_etag" ] || exit 1

read -r status _ <<< "$(patch "If-Match: $initial_etag" "Lost update")"
echo "DEBUG: PATCH quoting the state before the write. Expected: $STATUS_PRECONDITION_FAILED Got: $status"
[ "$status" = "$STATUS_PRECONDITION_FAILED" ] || exit 1

echo "DEBUG: the stale PATCH was not applied. Expected: Preconditions Title Got: $(title)"
[ "$(title)" = "Preconditions Title" ] || exit 1

# restore the title, quoting the tag the accepted PATCH answered with
read -r status _ <<< "$(patch "If-Match: $written_etag" "$original_title")"
echo "DEBUG: restore. Expected: $STATUS_NO_CONTENT Got: $status"
[ "$status" = "$STATUS_NO_CONTENT" ] || exit 1
