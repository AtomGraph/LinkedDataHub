#!/usr/bin/env bash
set -euo pipefail

# The Lean model of Memento (formal/http, LdhHttp.Memento), replayed against the server. A document is written four
# times, and once its versions are committed, the history GitHub lists for its file is handed to ldh-http. The
# server's TimeMap has to list exactly that history, each Memento a prov:wasRevisionOf the one before it, and its
# TimeGate has to select what the model's selectMemento selects: with no datetime, at each commit, midway between
# two (where both are as close), and before and after the history.

# requires a dataspace configured with lds:versioningRepository (branch "main", path prefix "graphs")
# pointing at $VERSIONING_TEST_REPO ("owner/repo"), with the token in secrets/credentials.trig
if [ -z "${VERSIONING_TEST_REPO:-}" ] || [ -z "${GITHUB_TOKEN:-}" ] || ! command -v gh > /dev/null; then
    echo "SKIPPED: VERSIONING_TEST_REPO/GITHUB_TOKEN not set or gh CLI not available"
    exit 0
fi

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

decider="${LDH_HTTP_DECIDER:-$HTTP_TEST_ROOT/../../formal/http/.lake/build/bin/ldh-http}"
if [ ! -x "$decider" ]; then
    echo "DEBUG: ldh-http not found at $decider: run 'lake build' in formal/http, or point LDH_HTTP_DECIDER at it" >&2
    exit 1
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# add agent to the writers group

ldh admin add agent \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

slug=$(uuidgen | tr '[:upper:]' '[:lower:]')
doc_url="${END_USER_BASE_URL}${slug}/"
path="${VERSIONING_PATH_PREFIX:-graphs}/${slug}.nt"

put_document()
{
    echo "<${doc_url}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#Item> .
<${doc_url}> <http://purl.org/dc/terms/title> \"${1}\" ." | \
      ldh put \
        -c "$AGENT_CERT_KEYSTORE" \
        -p "$AGENT_CERT_PWD" \
        -t "application/n-triples" \
        "$doc_url" > /dev/null
}

# the file's history as GitHub lists it, most recent first: SHA and author datetime in seconds, as the server reads it
history()
{
    gh api "repos/${VERSIONING_TEST_REPO}/commits?path=${path}&sha=${VERSIONING_TEST_BRANCH:-main}&per_page=100" \
        --jq '.[] | "\(.sha)\t\(.commit.author.date | fromdateiso8601)"' 2> /dev/null || true
}

iso() { date -u -d "@$1" +%Y-%m-%dT%H:%M:%SZ 2> /dev/null || date -u -r "$1" +%Y-%m-%dT%H:%M:%SZ; }

# four versions, each committed before the next is written
for n in 1 2 3 4; do
    put_document "Version $n"
    for i in $(seq 1 30); do
        [ "$(history | wc -l | tr -d ' ')" -ge "$n" ] && break
        sleep 1
    done
    count=$(history | wc -l | tr -d ' ')
    echo "DEBUG: version $n: $count commits"
    [ "$count" -ge "$n" ] || exit 1
done

history > "$work/history.tsv"
echo "DEBUG: history (most recent first):"
sed 's/^/DEBUG:   /' "$work/history.tsv"

# the TimeMap lists the history, and each Memento is a revision of the next one down it

timemap=$(
ldh get \
  -c "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  --timemap \
  "$doc_url")

expected_members=$(cut -f1 "$work/history.tsv" | sed "s|^|${doc_url}?version=|" | sort)
actual_members=$(echo "$timemap" | grep -F "<${doc_url}?timemap> <http://www.w3.org/ns/prov#hadMember> " | sed -E 's/^.* <([^>]*)> \.$/\1/' | sort)
echo "DEBUG: TimeMap members. Expected:"; echo "$expected_members" | sed 's/^/DEBUG:   /'
echo "DEBUG: Got:"; echo "$actual_members" | sed 's/^/DEBUG:   /'
[ "$expected_members" = "$actual_members" ] || exit 1

expected_revisions=$(cut -f1 "$work/history.tsv" | awk -v d="$doc_url" 'NR > 1 { print d "?version=" prev " " d "?version=" $0 } { prev = $0 }' | sort)
actual_revisions=$(echo "$timemap" | grep -F "<http://www.w3.org/ns/prov#wasRevisionOf>" | sed -E 's/^<([^>]*)> <[^>]*> <([^>]*)> \.$/\1 \2/' | sort)
echo "DEBUG: TimeMap revisions. Expected:"; echo "$expected_revisions" | sed 's/^/DEBUG:   /'
echo "DEBUG: Got:"; echo "$actual_revisions" | sed 's/^/DEBUG:   /'
[ "$expected_revisions" = "$actual_revisions" ] || exit 1

# the TimeGate selects what the model selects

times=$(cut -f2 "$work/history.tsv")
first=$(echo "$times" | tail -n 1)
last=$(echo "$times" | head -n 1)
datetimes=$( { echo "$times"; echo "$times" | awk 'NR > 1 { print int((prev + $0) / 2) } { prev = $0 }'; echo $((first - 3600)); echo $((last + 3600)); } | sort -un)

expected=$("$decider" --select "$work/history.tsv")
actual=$(ldh get -c "$AGENT_CERT_KEYSTORE" -p "$AGENT_CERT_PWD" --timegate "$doc_url")
echo "DEBUG: TimeGate with no datetime. Expected: ${doc_url}?version=${expected} Got: $actual"
[ "$actual" = "${doc_url}?version=${expected}" ] || exit 1

for s in $datetimes; do
    expected=$("$decider" --select "$work/history.tsv" --datetime "$s")
    actual=$(ldh get -c "$AGENT_CERT_KEYSTORE" -p "$AGENT_CERT_PWD" --timegate --datetime "$(iso "$s")" "$doc_url")
    echo "DEBUG: TimeGate at $(iso "$s"). Expected: ${doc_url}?version=${expected} Got: $actual"
    [ "$actual" = "${doc_url}?version=${expected}" ] || exit 1
done
