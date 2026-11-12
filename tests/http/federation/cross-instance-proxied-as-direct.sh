#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
initialize_dataset "$REMOTE_END_USER_BASE_URL" "$TMP_REMOTE_END_USER_DATASET" "$REMOTE_END_USER_ENDPOINT_URL"
initialize_dataset "$REMOTE_ADMIN_BASE_URL" "$TMP_REMOTE_ADMIN_DATASET" "$REMOTE_ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# What A's Linked Data proxy does with a request to another instance B, as a difference: every request sent through
# the proxy has to get the answer B gives the request the proxy should turn it into, sent to B directly. A read goes
# out anonymous, whoever sends it, so browsing does not announce the caller to B; a write goes out as the caller, A's
# secretary vouching for them with On-Behalf-Of. The cases cross A's owner (whom B grants read and write), A's
# signed-up agent (whom B grants nothing) and an anonymous caller with every method, a document anyone may read, one
# only A's owner may, one that does not exist, and the preconditions the proxy forwards.

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# on B, a container whose documents A's owner may read and write, and the documents the reads are about

container=$(ldh create container \
  -c "$REMOTE_OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Cross-instance cases" \
  --slug "cross-instance-$(date +%s)" \
  --parent "$REMOTE_END_USER_BASE_URL")

ldh admin create authorization \
  -c "$REMOTE_OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --label "A's owner may edit the cross-instance cases" \
  --agent "$OWNER_URI" \
  --default "$container" \
  --read \
  --write \
  "$REMOTE_ADMIN_BASE_URL" > /dev/null

new_doc()
{
    ldh create item \
      -c "$REMOTE_OWNER_CERT_KEYSTORE" \
      -p "$OWNER_CERT_PWD" \
      --title "$1" \
      --container "$container"
}

public=$(new_doc "Readable by anyone")
private=$(new_doc "Readable by A's owner")
missing="${container}missing/"

ldh admin create authorization \
  -c "$REMOTE_OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --label "Anyone may read the public cross-instance case" \
  --agent-class 'http://xmlns.com/foaf/0.1/Agent' \
  --to "$public" \
  --read \
  "$REMOTE_ADMIN_BASE_URL" > /dev/null

cert_pair()
{
    case "$1" in
        anon) echo "" ;;
        owner) echo "$OWNER_CERT_FILE:$OWNER_CERT_PWD" ;;
        agent) echo "$AGENT_CERT_FILE:$AGENT_CERT_PWD" ;;
    esac
}

# Sends the request as the caller, to the document directly or through A's proxy, with the header if one is given;
# prints the status
send()
{
    local who="$1" method="$2" doc="$3" via="$4" header="${5:-}" pair args url=("$3")
    pair=$(cert_pair "$who")
    [ "$via" = proxy ] && url=(--url-query "uri=$doc" "$END_USER_BASE_URL")
    args=(-k -s -o /dev/null -w '%{http_code}' ${pair:+-E "$pair"} -H "Accept: application/n-triples")
    [ -n "$header" ] && args+=(-H "$header")
    case "$method" in
        GET) ;;
        HEAD) args+=(-I) ;;
        PUT) args+=(-X PUT -H "Content-Type: application/n-triples" --data-binary \
            "<${doc}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#Item> .
<${doc}> <http://purl.org/dc/terms/title> \"Replaced\" .") ;;
        POST) args+=(-X POST -H "Content-Type: application/n-triples" --data-binary \
            "<${doc}#appended> <http://example.org/p> \"Appended\" .") ;;
        PATCH) args+=(-X PATCH -H "Content-Type: application/sparql-update" --data-binary \
            "INSERT DATA { <${doc}> <http://purl.org/dc/terms/description> \"Patched\" }") ;;
        DELETE) args+=(-X DELETE) ;;
    esac
    curl "${args[@]}" "${url[@]}"
}

failures=0
cases=0

compare()
{
    local label="$1" expected="$2" got="$3"
    cases=$((cases + 1))
    echo "DEBUG: $label - Expected: $expected  Got: $got"
    if [ "$got" != "$expected" ]; then
        echo "DEBUG: Mismatch!"
        failures=$((failures + 1))
    fi
}

# Controls: B gives A's owner what the reads below are compared against, so that a proxied read B refuses is refused
# for being anonymous

code=$(send owner GET "$private" direct)
echo "DEBUG: control: A's owner reads the private document directly - Expected: $STATUS_OK  Got: $code"
[ "$code" = "$STATUS_OK" ] || exit 1
code=$(send anon GET "$private" direct)
echo "DEBUG: control: an anonymous caller reads the private document directly - Expected: not $STATUS_OK  Got: $code"
[ "$code" != "$STATUS_OK" ] || exit 1

# Reads: through the proxy, as anyone, they get what an anonymous read gets. The documents are not changed, so the
# direct and the proxied request are about the same one

public_tag=$(curl -k -s -I -H "Accept: application/n-triples" "$public" | grep -i '^etag:' | tr -d '\r' | sed 's/^[Ee][Tt][Aa][Gg]: *//')
[ -n "$public_tag" ] || { echo "DEBUG: no entity tag for <$public>"; exit 1; }

for who in owner agent anon; do
    for method in GET HEAD; do
        for doc in "$public" "$private" "$missing"; do
            compare "$who $method <$doc> through the proxy, against anonymous directly" \
                "$(send anon "$method" "$doc" direct)" "$(send "$who" "$method" "$doc" proxy)"
        done
        compare "$who $method <$public> If-None-Match through the proxy, against anonymous directly" \
            "$(send anon "$method" "$public" direct "If-None-Match: $public_tag")" \
            "$(send "$who" "$method" "$public" proxy "If-None-Match: $public_tag")"
    done
done

# Writes: through the proxy, they get what the same caller's write gets. Each write changes its document, so the direct
# and the proxied request each have one of their own, made alike, with the precondition taken from it

for method in PUT POST PATCH DELETE; do
    for case in owner:current owner:stale agent:current anon:current; do
        who="${case%%:*}" precondition="${case##*:}"
        direct_doc=$(new_doc "Written directly")
        proxied_doc=$(new_doc "Written through the proxy")
        if [ "$precondition" = current ]; then
            direct_header="If-Match: $(etag "$direct_doc" "$OWNER_CERT_FILE" "$OWNER_CERT_PWD")"
            proxied_header="If-Match: $(etag "$proxied_doc" "$OWNER_CERT_FILE" "$OWNER_CERT_PWD")"
        else
            direct_header='If-Match: "stale"'
            proxied_header='If-Match: "stale"'
        fi

        expected=$(send "$who" "$method" "$direct_doc" direct "$direct_header")
        # the control: A's owner's write is one B lets through, so the comparison is not between two refusals
        if [ "$case" = owner:current ] && [[ "$expected" != 2* ]]; then
            echo "DEBUG: control: A's owner $method directly - Expected: 2xx  Got: $expected"
            exit 1
        fi
        compare "$who $method ($precondition) through the proxy, against $who directly" \
            "$expected" "$(send "$who" "$method" "$proxied_doc" proxy "$proxied_header")"
    done
done

echo "DEBUG: $cases cases, $failures where the proxied request was answered otherwise"
[ "$failures" -eq 0 ]
