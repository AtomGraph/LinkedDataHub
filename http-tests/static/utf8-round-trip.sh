#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
clear_ontology

# The bytes behind the charset are the ones the file was written with.
#
# content-type-charset.sh asserts what the response CLAIMS; this asserts what it delivers. The two
# fail differently: a missing charset leaves correct bytes mislabelled, while a re-encoded file
# leaves the label right and the bytes doubled. A build step that reads a stylesheet in one encoding
# and writes it in another produces exactly that, and nothing else in the suite would notice.
#
# The assertion is that specific characters survive, rather than that mojibake is absent. Hunting
# for the signature is character-dependent and quietly incomplete: "·" degrades to "Â·" and "—" to
# "â€"", both of which a marker test catches, but "⤴" degrades to "â¤´", which carries neither
# marker. What each character becomes varies; that it must still be itself does not.

path="com/atomgraph/linkeddatahub/css/ldh.css"
body=$(curl -k -s "${END_USER_BASE_URL}static/${path}")

if ! printf "%s" "$body" | iconv -f UTF-8 -t UTF-8 > /dev/null 2>&1
then
    echo "DEBUG: first bytes: $(printf "%s" "$body" | head -c 120 | od -c | head -3)"
    echo "${path} is not valid UTF-8"
    exit 1
fi

# "⤴" is the one that matters beyond legibility: it is a content: value, so a mangled byte sequence
# renders as a broken glyph on every external link rather than merely reading badly in the source.
declare -a characters=("—" "⤴")

for character in "${characters[@]}"
do
    count=$(grep -c "$character" <<< "$body" || true)
    echo "DEBUG: lines carrying '${character}' in ${path}: ${count}"

    if [ "$count" -eq 0 ]
    then
        # read the character's own UTF-8 bytes back as latin-1: that is the shape it takes on
        echo "DEBUG: what a latin-1 round trip would have left instead: $(printf "%s" "$character" | iconv -f ISO-8859-1 -t UTF-8 2>/dev/null || echo '(unrepresentable)')"
        echo "'${character}' did not survive in ${path} - the file has been re-encoded, not merely mislabelled"
        exit 1
    fi
done
