#!/usr/bin/env bash
set -euo pipefail

# The Lean models of the graph store and the authorization decision (formal/http, formal/acl), replayed against the
# server. A random scenario of documents, groups and authorizations is built through the API, and before every
# request the two datasets are dumped and handed to ldh-acl, which runs the server's answer to the request
# (LdhAcl.Gate): the decision proven equal to the model's allowRequest, then the graph store's answer
# (LdhHttp.Answer), proven to write only what an authorized Write writes. The server has to
# agree with it twice: on the status, and on the document's graph after the request, but for the dates the server
# stamps. The requests carry random preconditions and payloads, some of which the write and type rules refuse. The
# scenario's writes are themselves requests the model decides, so what the agents may do shapes what gets built.
#
# ACL_CONFORMANCE_SEED replays a scenario; ACL_CONFORMANCE_STEPS sets how many random steps follow the setup.

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

decider="${LDH_ACL_DECIDER:-$HTTP_TEST_ROOT/../../formal/acl/.lake/build/bin/ldh-acl}"
if [ ! -x "$decider" ]; then
    echo "DEBUG: ldh-acl not found at $decider: run 'lake build' in formal/acl, or point LDH_ACL_DECIDER at it" >&2
    exit 1
fi
hash riot 2>/dev/null || { echo "DEBUG: riot (Apache Jena) is not on PATH" >&2; exit 1; }

seed="${ACL_CONFORMANCE_SEED:-$RANDOM}"
steps="${ACL_CONFORMANCE_STEPS:-40}"
echo "DEBUG: seed $seed, $steps random steps (replay with ACL_CONFORMANCE_SEED=$seed)"
RANDOM=$seed

work=$(mktemp -d)
AGENT2_CERT_FILE=$(mktemp)
AGENT2_CERT_KEYSTORE=$(mktemp)
AGENT2_CERT_PWD="changeit"
trap 'rm -rf "$work" "$AGENT2_CERT_FILE" "$AGENT2_CERT_KEYSTORE"' EXIT

# a second agent, so a grant can name someone other than the requester and a group can tell them apart
(
    export AGENT_CERT_FILE="$AGENT2_CERT_FILE" AGENT_CERT_KEYSTORE="$AGENT2_CERT_KEYSTORE" AGENT_CERT_PWD="$AGENT2_CERT_PWD"
    bash -e "$HTTP_TEST_ROOT/signup.sh"
)
AGENT2_URI=$(webid-uri.sh "$AGENT2_CERT_FILE")
echo "DEBUG: second agent $AGENT2_URI"

agent_uri()
{
    case "$1" in
        anon) echo "" ;;
        owner) echo "$OWNER_URI" ;;
        agent) echo "$AGENT_URI" ;;
        agent2) echo "$AGENT2_URI" ;;
    esac
}

cert_pair()
{
    case "$1" in
        anon) echo "" ;;
        owner) echo "$OWNER_CERT_FILE:$OWNER_CERT_PWD" ;;
        agent) echo "$AGENT_CERT_FILE:$AGENT_CERT_PWD" ;;
        agent2) echo "$AGENT2_CERT_FILE:$AGENT2_CERT_PWD" ;;
    esac
}

# the documents the scenario is about: a tree in each dataspace, created by the first steps where the model lets
# the owner, with the roots as further grant targets. Documents end in a slash; the one path that does not is never
# created (the server answers it with a redirect) and exercises how `..` resolves against it: two levels up
tag="conformance-$seed"
containers=(
    "${END_USER_BASE_URL}${tag}/"
    "${END_USER_BASE_URL}${tag}/a/"
    "${END_USER_BASE_URL}${tag}/a/b/"
    "${ADMIN_BASE_URL}${tag}/"
)
items=(
    "${END_USER_BASE_URL}${tag}/a/b/c/"
    "${END_USER_BASE_URL}${tag}/a/d/"
    "${END_USER_BASE_URL}${tag}/e/"
    "${ADMIN_BASE_URL}${tag}/f/"
)
docs=("${containers[@]}" "${items[@]}" "${END_USER_BASE_URL}${tag}/a/x")
targets=("${docs[@]}" "$END_USER_BASE_URL" "$ADMIN_BASE_URL")
agents=(anon agent agent2 owner)
methods=(GET HEAD POST PUT PATCH DELETE)
preconditions=(current current current none stale absent)
groups=()
group_docs=()

pick() { echo $((RANDOM % $1)); }

dump()
{
    curl -s -f -H "Accept: application/trig" "$END_USER_ENDPOINT_URL" > "$work/end-user.trig"
    curl -s -f -H "Accept: application/trig" "$ADMIN_ENDPOINT_URL" > "$work/admin.trig"
    riot --syntax=trig --output=nquads "$work/end-user.trig" > "$work/end-user.nq"
    riot --syntax=trig --output=nquads "$work/admin.trig" > "$work/admin.nq"
}

# the model's answer to the request in $work/request.tsv, over the last dump: the status, then the document's graph
predict()
{
    "$decider" --end-user "$work/end-user.nq" --admin "$work/admin.nq" --admin-base "$ADMIN_BASE_URL" \
        --request "$work/request.tsv" --payload "$work/payload.nt" --delete "$work/delete.nt" --insert "$work/insert.nt"
}

# the quads of the document's graph in the last dump: its name is the term before the closing dot
quads_of() { awk -v g="<$1>" '$(NF-1) == g' "$work/end-user.nq" "$work/admin.nq"; }

# whether the last dump has a graph named by the document
exists_doc() { [ -n "$(quads_of "$1")" ]; }

# the document's graph in the last dump, as N-Triples, without the dates the server stamps on every write
graph_of() { quads_of "$1" | sed 's/ <[^>]*> \.$/ ./' | without_dates "$1"; }

without_dates()
{
    grep -vF -e "<$1> <http://purl.org/dc/terms/created> " -e "<$1> <http://purl.org/dc/terms/modified> " | sort || true
}

T="<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>"
DH="https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#"

document_body()
{
    local type="${DH}Item" c
    for c in "${containers[@]}"; do
        [ "$c" = "$1" ] && type="${DH}Container"
    done
    printf '<%s> %s <%s> .\n<%s> <http://purl.org/dc/terms/title> "Conformance %s" .\n' "$1" "$T" "$type" "$1" "$RANDOM"
}

# a payload for the method, mostly one the rules let through, sometimes one they refuse or strip; `plain` asks for
# the one they let through
payloads()
{
    local method="$1" target="$2" variant other="${docs[$(pick ${#docs[@]})]}"
    : > "$work/payload.nt"; : > "$work/delete.nt"; : > "$work/insert.nt"
    if [ "${3:-}" = plain ]; then variant=plain; else variant=$(pick 8); fi
    case "$method:$variant" in
        POST:0) ;; # appending nothing
        POST:1) printf '<%s> %s <http://xmlns.com/foaf/0.1/Person> .\n' "$target" "$T" > "$work/payload.nt" ;;
        POST:2) printf '<%s> <http://rdfs.org/sioc/ns#has_parent> <%s> .\n' "$other" "$target" > "$work/payload.nt" ;;
        POST:3) printf '<%s> <http://www.w3.org/ns/auth/acl#owner> <%s> .\n' "$target" "$AGENT2_URI" > "$work/payload.nt" ;;
        POST:*) printf '<%s#p%s> <http://example.org/p> "v" .\n' "$target" "$RANDOM" > "$work/payload.nt" ;;
        PUT:0) { document_body "$target"; printf '<%s> %s <http://xmlns.com/foaf/0.1/Person> .\n' "$target" "$T"; } > "$work/payload.nt" ;;
        PUT:1) { document_body "$target"; printf '<%s> <http://rdfs.org/sioc/ns#has_container> <%s> .\n' "$other" "$target"; } > "$work/payload.nt" ;;
        PUT:2) { document_body "$target"; printf '<%s> <http://www.w3.org/ns/auth/acl#owner> <%s> .\n' "$target" "$AGENT2_URI"; } > "$work/payload.nt" ;;
        PUT:*) document_body "$target" > "$work/payload.nt" ;;
        PATCH:0) printf '<%s> %s <http://xmlns.com/foaf/0.1/Person> .\n' "$target" "$T" > "$work/insert.nt" ;;
        PATCH:1) printf '<%s> <http://rdfs.org/sioc/ns#has_parent> <%s> .\n' "$target" "$END_USER_BASE_URL" > "$work/insert.nt" ;;
        PATCH:2) printf '<%s> %s <%sItem> .\n' "$target" "$T" "$DH" > "$work/delete.nt"
                 printf '<%s> %s <%sContainer> .\n' "$target" "$T" "$DH" > "$work/insert.nt" ;;
        PATCH:*) printf '<%s> <http://example.org/patched> "%s" .\n' "$target" "$RANDOM" > "$work/insert.nt" ;;
        *) ;;
    esac
}

# the request, as the agent, with the precondition and the payloads in $work; prints the status
request()
{
    local agent="$1" method="$2" target="$3" precondition="$4" pair header=(-H "X-Conformance-Step: $step")
    pair=$(cert_pair "$agent")
    case "$precondition" in
        current)
            # the owner's validator for the variant the request negotiates; a document with none has no current tag
            if exists_doc "$target"; then
                header=(-H "If-Match: $(etag "$target" "$OWNER_CERT_FILE" "$OWNER_CERT_PWD" "application/n-triples" 2>/dev/null || echo '"none"')")
            else
                header=(-H 'If-Match: "none"')
            fi ;;
        stale) header=(-H 'If-Match: "stale"') ;;
        absent) header=(-H 'If-None-Match: *') ;;
    esac
    case "$method" in
        GET)
            curl -k -s -o /dev/null -w '%{http_code}' ${pair:+-E "$pair"} -H "Accept: application/n-triples" "$target" ;;
        HEAD)
            curl -k -s -o /dev/null -w '%{http_code}' -I ${pair:+-E "$pair"} -H "Accept: application/n-triples" "$target" ;;
        POST|PUT)
            curl -k -s -o /dev/null -w '%{http_code}' ${pair:+-E "$pair"} -X "$method" "${header[@]}" \
                -H "Content-Type: application/n-triples" -H "Accept: application/n-triples" --data-binary @"$work/payload.nt" "$target" ;;
        PATCH)
            curl -k -s -o /dev/null -w '%{http_code}' ${pair:+-E "$pair"} -X PATCH "${header[@]}" \
                -H "Content-Type: application/sparql-update" -H "Accept: application/n-triples" \
                --data-binary "DELETE { $(cat "$work/delete.nt") } INSERT { $(cat "$work/insert.nt") } WHERE {}" "$target" ;;
        DELETE)
            curl -k -s -o /dev/null -w '%{http_code}' ${pair:+-E "$pair"} -X DELETE "${header[@]}" \
                -H "Accept: application/n-triples" "$target" ;;
    esac
}

purge_all()
{
    purge_cache "$END_USER_VARNISH_SERVICE"
    purge_cache "$ADMIN_VARNISH_SERVICE"
    purge_cache "$FRONTEND_VARNISH_SERVICE"
}

mismatches=0
step=0

# one request: predicted, sent, compared
probe()
{
    local agent="$1" method="$2" target="$3" precondition="$4" expected status outcome=ok
    step=$((step + 1))
    dump
    payloads "$method" "$target" "${5:-}"
    printf '%s\t%s\t%s\t%s\n' "$(agent_uri "$agent" | sed 's/^$/-/')" "$method" "$target" "$precondition" > "$work/request.tsv"
    predict > "$work/predicted"
    expected=$(head -n 1 "$work/predicted")
    tail -n +2 "$work/predicted" | without_dates "$target" > "$work/predicted.nt"
    status=$(request "$agent" "$method" "$target" "$precondition")
    cp "$work/end-user.nq" "$work/before.end-user.nq"
    cp "$work/admin.nq" "$work/before.admin.nq"
    dump
    graph_of "$target" > "$work/actual.nt"
    [ "$status" = "$expected" ] || outcome=MISMATCH
    if ! diff -q "$work/predicted.nt" "$work/actual.nt" > /dev/null; then
        outcome=MISMATCH
        echo "DEBUG: the graph of <$target>, predicted (<) and stored (>):"
        diff "$work/predicted.nt" "$work/actual.nt" | sed 's/^/DEBUG:   /' || true
    fi
    echo "DEBUG: step $step: $agent $method $target ($precondition): model says $expected, server returned $status: $outcome"
    if [ "$outcome" = MISMATCH ]; then
        mismatches=$((mismatches + 1))
        local keep="$TEST_RESULTS_DIR/acl-conformance-$seed-step-$step"
        cp "$work/before.end-user.nq" "$keep.end-user.nq"
        cp "$work/before.admin.nq" "$keep.admin.nq"
        cp "$work/request.tsv" "$keep.request.tsv"
        cp "$work/payload.nt" "$keep.payload.nt"
        cp "$work/delete.nt" "$keep.delete.nt"
        cp "$work/insert.nt" "$keep.insert.nt"
        echo "DEBUG: datasets, request and payloads kept as $keep.*"
    fi
    # a request that went through may have changed the stores, and with them what the caches hold
    case "$status" in 2*) purge_all ;; esac
}

# the owner's administration between requests: what the ACL query will read next
new_group()
{
    local n=$((${#groups[@]} + 1)) members
    case "$(pick 3)" in
        0) members="--member $AGENT_URI" ;;
        1) members="--member $AGENT2_URI" ;;
        2) members="--member $AGENT_URI --member $AGENT2_URI" ;;
    esac
    local uri="${ADMIN_BASE_URL}acl/groups/$tag-g$n/#this" doc
    # shellcheck disable=SC2086
    doc=$(ldh admin create group -c "$OWNER_CERT_KEYSTORE" -p "$OWNER_CERT_PWD" \
        --name "Conformance group $n" --slug "$tag-g$n" --uri "$uri" $members "$ADMIN_BASE_URL")
    groups+=("$uri")
    group_docs+=("$doc")
    echo "DEBUG: group $uri with $members"
    purge_all
}

add_member()
{
    local k; k=$(pick ${#groups[@]})
    local who; who=$(agent_uri "${agents[$((1 + $(pick 2)))]}")
    if ldh admin add agent -c "$OWNER_CERT_KEYSTORE" -p "$OWNER_CERT_PWD" --agent "$who" "${group_docs[$k]}"; then
        echo "DEBUG: added $who to ${groups[$k]}"
    else
        echo "DEBUG: adding $who to ${groups[$k]} failed (a repeat is a no-op the server may refuse)"
    fi
    purge_all
}

new_authorization()
{
    local n=$((auth_count += 1)) principal target modes=""
    case "$(pick 6)" in
        0) principal="--agent $AGENT_URI" ;;
        1) principal="--agent $AGENT2_URI" ;;
        2) if [ ${#groups[@]} -gt 0 ]; then principal="--agent-group ${groups[$(pick ${#groups[@]})]}"; else principal="--agent $AGENT_URI"; fi ;;
        3) principal="--agent-class http://xmlns.com/foaf/0.1/Agent" ;;
        4) principal="--agent-class http://www.w3.org/ns/auth/acl#AuthenticatedAgent" ;;
        5) principal="--agent-class https://w3id.org/atomgraph/linkeddatahub/admin/acl#OwnerAgent" ;;
    esac
    local t="${targets[$(pick ${#targets[@]})]}"
    case "$t" in
        */) if [ "$(pick 2)" = 0 ]; then target="--to $t"; else target="--default $t"; fi ;;
        *) target="--to $t" ;;
    esac
    if [ "$(pick 3)" = 0 ]; then target="$target --to ${targets[$(pick ${#targets[@]})]}"; fi
    local bits=$((1 + $(pick 7)))
    [ $((bits & 1)) -ne 0 ] && modes="$modes --read"
    [ $((bits & 2)) -ne 0 ] && modes="$modes --append"
    [ $((bits & 4)) -ne 0 ] && modes="$modes --write"
    # shellcheck disable=SC2086
    if ldh admin create authorization -c "$OWNER_CERT_KEYSTORE" -p "$OWNER_CERT_PWD" \
        --label "Conformance authorization $n" $principal $target $modes "$ADMIN_BASE_URL" > /dev/null; then
        echo "DEBUG: authorization $n: $principal $target$modes"
    else
        echo "DEBUG: authorization $n refused: $principal $target$modes"
    fi
    purge_all
}
auth_count=0

# setup: the owner creates the tree, containers first; the model decides each of these too
for d in "${containers[@]}" "${items[@]}"; do
    probe owner PUT "$d" absent plain
done
new_group
new_authorization
new_authorization

# the random walk
for ((i = 1; i <= steps; i++)); do
    case "$(pick 12)" in
        0) new_authorization ;;
        1) if [ "$(pick 2)" = 0 ]; then new_group; else add_member; fi ;;
        *)
            method="${methods[$(pick ${#methods[@]})]}"
            precondition=none
            case "$method" in GET|HEAD) ;; *) precondition="${preconditions[$(pick ${#preconditions[@]})]}" ;; esac
            probe "${agents[$(pick ${#agents[@]})]}" "$method" "${docs[$(pick ${#docs[@]})]}" "$precondition" ;;
    esac
done

echo "DEBUG: $step requests, $mismatches mismatches (seed $seed)"
[ "$mismatches" -eq 0 ]
