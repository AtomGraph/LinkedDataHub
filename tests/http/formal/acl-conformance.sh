#!/usr/bin/env bash
set -euo pipefail

# The Lean model of the authorization decision (formal/acl), replayed against the server. A random scenario of
# documents, groups and authorizations is built through the API, and before every request the two datasets are
# dumped and handed to ldh-acl, the executable decision proven equal to the model's allowRequest. The server has
# to agree with its verdict: 401 or 403 where it says deny, anything else where it says allow. The scenario's
# writes are themselves requests the model decides, so what the agents may do shapes what gets built.
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
methods=(GET HEAD POST PUT 'PUT*' PATCH DELETE)
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

# the model's verdict on a request, over the last dump
predict()
{
    printf '%s\t%s\t%s\n' "${1:--}" "$2" "$3" > "$work/probe.tsv"
    "$decider" --end-user "$work/end-user.nq" --admin "$work/admin.nq" --admin-base "$ADMIN_BASE_URL" --probes "$work/probe.tsv" \
    | cut -f1
}

# whether the last dump has a graph named by the document
exists_doc() { grep -qF -- "> <$1> ." "$work/end-user.nq" "$work/admin.nq"; }

document_body()
{
    local type="https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#Item" c
    for c in "${containers[@]}"; do
        [ "$c" = "$1" ] && type="https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#Container"
    done
    printf '<%s> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <%s> .\n<%s> <http://purl.org/dc/terms/title> "Conformance %s" .\n' "$1" "$type" "$1" "$RANDOM"
}

# the request, as the agent; prints the status. A write to an existing document quotes the owner's validator, so
# that only the decision stands between the request and its effect
request()
{
    local agent="$1" method="$2" target="$3" pair ifmatch=""
    pair=$(cert_pair "$agent")
    if exists_doc "$target" && [ "$method" != GET ] && [ "$method" != HEAD ] && [ "$method" != POST ] && [ "$method" != 'PUT*' ]; then
        ifmatch=$(etag "$target" "$OWNER_CERT_FILE" "$OWNER_CERT_PWD" "application/n-triples" 2>/dev/null || true)
    fi
    case "$method" in
        GET)
            curl -k -s -o /dev/null -w '%{http_code}' ${pair:+-E "$pair"} -H "Accept: application/n-triples" "$target" ;;
        HEAD)
            curl -k -s -o /dev/null -w '%{http_code}' -I ${pair:+-E "$pair"} -H "Accept: application/n-triples" "$target" ;;
        POST)
            printf '<%s#p%s> <http://example.org/p> "v" .\n' "$target" "$RANDOM" \
            | curl -k -s -o /dev/null -w '%{http_code}' ${pair:+-E "$pair"} -X POST \
                -H "Content-Type: application/n-triples" -H "Accept: application/n-triples" --data-binary @- "$target" ;;
        PUT)
            document_body "$target" \
            | curl -k -s -o /dev/null -w '%{http_code}' ${pair:+-E "$pair"} -X PUT ${ifmatch:+-H "If-Match: $ifmatch"} \
                -H "Content-Type: application/n-triples" -H "Accept: application/n-triples" --data-binary @- "$target" ;;
        'PUT*')
            document_body "$target" \
            | curl -k -s -o /dev/null -w '%{http_code}' ${pair:+-E "$pair"} -X PUT -H "If-None-Match: *" \
                -H "Content-Type: application/n-triples" -H "Accept: application/n-triples" --data-binary @- "$target" ;;
        PATCH)
            curl -k -s -o /dev/null -w '%{http_code}' ${pair:+-E "$pair"} -X PATCH ${ifmatch:+-H "If-Match: $ifmatch"} \
                -H "Content-Type: application/sparql-update" -H "Accept: application/n-triples" \
                --data-binary "INSERT DATA { <$target> <http://example.org/patched> \"$RANDOM\" }" "$target" ;;
        DELETE)
            curl -k -s -o /dev/null -w '%{http_code}' ${pair:+-E "$pair"} -X DELETE ${ifmatch:+-H "If-Match: $ifmatch"} \
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
    local agent="$1" method="$2" target="$3" verdict status outcome
    step=$((step + 1))
    dump
    verdict=$(predict "$(agent_uri "$agent")" "$method" "$target")
    status=$(request "$agent" "$method" "$target")
    case "$verdict:$status" in
        deny:401|deny:403) outcome=ok ;;
        deny:*) outcome=MISMATCH ;;
        allow:401|allow:403) outcome=MISMATCH ;;
        allow:*) outcome=ok ;;
    esac
    echo "DEBUG: step $step: $agent $method $target: model says $verdict, server returned $status: $outcome"
    if [ "$outcome" = MISMATCH ]; then
        mismatches=$((mismatches + 1))
        local keep="$TEST_RESULTS_DIR/acl-conformance-$seed-step-$step"
        cp "$work/end-user.nq" "$keep.end-user.nq"
        cp "$work/admin.nq" "$keep.admin.nq"
        cp "$work/probe.tsv" "$keep.probe.tsv"
        echo "DEBUG: datasets and probe kept as $keep.*"
    fi
    # anything but a refused request may have changed the stores, and with them what the caches hold
    if [ "$method" != GET ] && [ "$method" != HEAD ] && [ "$status" != 401 ] && [ "$status" != 403 ]; then
        purge_all
    fi
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
    probe owner 'PUT*' "$d"
done
new_group
new_authorization
new_authorization

# the random walk
for ((i = 1; i <= steps; i++)); do
    case "$(pick 12)" in
        0) new_authorization ;;
        1) if [ "$(pick 2)" = 0 ]; then new_group; else add_member; fi ;;
        *) probe "${agents[$(pick ${#agents[@]})]}" "${methods[$(pick ${#methods[@]})]}" "${docs[$(pick ${#docs[@]})]}" ;;
    esac
done

echo "DEBUG: $step requests, $mismatches mismatches (seed $seed)"
[ "$mismatches" -eq 0 ]
