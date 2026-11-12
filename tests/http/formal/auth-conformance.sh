#!/usr/bin/env bash
set -euo pipefail

# The Lean model of authentication (formal/auth) replayed against the server. Before every request the WebID
# documents the server may dereference are fetched as it fetches them, anonymously, and handed to ldh-auth with the
# WebID cache the model has kept since the start: the model predicts the agent the request is authenticated as, or
# the status a failure is answered with, and the server has to agree. The agent is read from the response's
# `Link: <agent>; rel="http://www.w3.org/ns/auth/acl#agent"`.
#
# The requests pair a certificate (none, the owner's, the secretary's, two fresh agents') with an On-Behalf-Of
# header (none, each of those agents, a document that does not exist, a value that is not a URI). Between them the
# owner adds and removes delegations in the fresh agents' documents, so that a delegation is granted, used and
# revoked: a revocation the server's WebID cache still holds is honoured until the entry expires, and the model says
# so. Only the fresh agents' documents change; the server cannot have cached them before this test signed them up.
#
# AUTH_CONFORMANCE_SEED replays a scenario; AUTH_CONFORMANCE_STEPS sets how many random steps there are.

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

model="${LDH_AUTH_MODEL:-$HTTP_TEST_ROOT/../../formal/auth/.lake/build/bin/ldh-auth}"
if [ ! -x "$model" ]; then
    echo "DEBUG: ldh-auth not found at $model: run 'lake build' in formal/auth, or point LDH_AUTH_MODEL at it" >&2
    exit 1
fi

seed="${AUTH_CONFORMANCE_SEED:-$RANDOM}"
steps="${AUTH_CONFORMANCE_STEPS:-40}"
echo "DEBUG: seed $seed, $steps random steps (replay with AUTH_CONFORMANCE_SEED=$seed)"
RANDOM=$seed

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# two fresh agents, whose documents the scenario changes
for n in 2 3; do
    (
        export AGENT_CERT_FILE="$work/agent$n.pem" AGENT_CERT_KEYSTORE="$work/agent$n.p12" AGENT_CERT_PWD="changeit"
        bash -e "$HTTP_TEST_ROOT/signup.sh"
    )
done
AGENT2_URI=$(webid-uri.sh "$work/agent2.pem")
AGENT3_URI=$(webid-uri.sh "$work/agent3.pem")
echo "DEBUG: fresh agents $AGENT2_URI $AGENT3_URI"

uri_of()
{
    case "$1" in
        owner) echo "$OWNER_URI" ;;
        secretary) echo "$SECRETARY_URI" ;;
        agent2) echo "$AGENT2_URI" ;;
        agent3) echo "$AGENT3_URI" ;;
        missing) echo "${ADMIN_BASE_URL}acl/agents/conformance-$seed-missing/#this" ;;
    esac
}

cert_of()
{
    case "$1" in
        owner) echo "$OWNER_CERT_FILE:$OWNER_CERT_PWD" ;;
        secretary) echo "$SECRETARY_CERT_FILE:$SECRETARY_CERT_PWD" ;;
        agent2) echo "$work/agent2.pem:changeit" ;;
        agent3) echo "$work/agent3.pem:changeit" ;;
    esac
}

pem_of()
{
    case "$1" in
        owner) echo "$OWNER_CERT_FILE" ;;
        secretary) echo "$SECRETARY_CERT_FILE" ;;
        agent2) echo "$work/agent2.pem" ;;
        agent3) echo "$work/agent3.pem" ;;
    esac
}

# the key as WebIDFilter binds it: the modulus in lower-case hex without leading zeros, the exponent in decimal
modulus_of() { openssl x509 -noout -modulus -in "$(pem_of "$1")" | sed 's/^Modulus=//' | tr '[:upper:]' '[:lower:]' | sed 's/^0*//'; }
exponent_of() { openssl x509 -noout -text -in "$(pem_of "$1")" | sed -n 's/.*Exponent: \([0-9]*\).*/\1/p' | head -1; }

doc_of() { echo "${1%%#*}"; }

holders=(none owner secretary agent2 agent3)
principals=(none none owner secretary agent2 agent3 missing malformed)
mutable=(agent2 agent3)
delegates=(owner secretary agent2 agent3)

pick() { echo $((RANDOM % $1)); }

# every document the server may dereference for the request, as it dereferences them: each agent's WebID document,
# and the key document each names
fetch_docs()
{
    local args=() name uri doc file key keydoc i=0
    for name in owner secretary agent2 agent3; do
        uri=$(uri_of "$name")
        doc=$(doc_of "$uri")
        file="$work/doc-$name.nt"
        curl -k -s -f -H "Accept: application/n-triples" "$doc" > "$file"
        args+=(--doc "$doc" "$file")
        while read -r key; do
            keydoc=$(doc_of "$key")
            i=$((i + 1))
            curl -k -s -f -H "Accept: application/n-triples" "$keydoc" > "$work/key-$i.nt"
            args+=(--doc "$keydoc" "$work/key-$i.nt")
        done < <(grep -F "<$uri> <http://www.w3.org/ns/auth/cert#key> <" "$file" | sed 's/.*cert#key> <\([^>]*\)>.*/\1/')
    done
    printf '%s\n' "${args[@]}" > "$work/doc-args"
}

: > "$work/cache.nq"
failures=0

for step in $(seq 1 "$steps"); do
    if [ "$(pick 5)" = 0 ]; then
        # the owner grants or revokes a delegation in a fresh agent's document
        target="${mutable[$(pick ${#mutable[@]})]}"
        delegate="${delegates[$(pick ${#delegates[@]})]}"
        target_uri=$(uri_of "$target")
        delegate_uri=$(uri_of "$delegate")
        if [ "$(pick 2)" = 0 ]; then op=INSERT; else op=DELETE; fi
        echo "DEBUG: step $step: owner ${op}s <$delegate_uri> acl:delegates <$target_uri>"
        printf '%s { <%s> <http://www.w3.org/ns/auth/acl#delegates> <%s> } WHERE {}\n' "$op" "$delegate_uri" "$target_uri" \
            | ldh patch -c "$OWNER_CERT_KEYSTORE" -p "$OWNER_CERT_PWD" "$(doc_of "$target_uri")"
        continue
    fi

    holder="${holders[$(pick ${#holders[@]})]}"
    principal="${principals[$(pick ${#principals[@]})]}"

    fetch_docs
    doc_args=()
    while IFS= read -r arg; do doc_args+=("$arg"); done < "$work/doc-args"
    if [ "$holder" = none ]; then
        line="-	-	-"
    else
        line="$(uri_of "$holder")	$(modulus_of "$holder")	$(exponent_of "$holder")"
    fi
    case "$principal" in
        none) obo="-"; header=() ;;
        malformed) obo="!"; header=(-H "On-Behalf-Of: not a uri") ;;
        *) obo=$(uri_of "$principal"); header=(-H "On-Behalf-Of: $obo") ;;
    esac
    printf '%s\t%s\n' "$line" "$obo" > "$work/request.tsv"

    expected=$("$model" "${doc_args[@]}" --cache "$work/cache.nq" --cache-out "$work/cache-next.nq" \
        --request "$work/request.tsv")

    cert=()
    [ "$holder" != none ] && cert=(-E "$(cert_of "$holder")")
    headers=$(curl -k -s -o /dev/null -D - ${cert[@]+"${cert[@]}"} ${header[@]+"${header[@]}"} -H "Accept: application/n-triples" \
        "$(doc_of "$AGENT2_URI")")
    status=$(head -1 <<< "$headers" | awk '{print $2}')
    agent=$(grep -i '^link:' <<< "$headers" | tr ',' '\n' | grep -F 'rel="http://www.w3.org/ns/auth/acl#agent"' \
        | sed 's/.*<\([^>]*\)>.*/\1/' | head -1 || true)
    if [ "$status" = 400 ] || [ "$status" = 500 ] || [ "$status" = 303 ]; then
        actual="$status"
    elif [ -n "$agent" ]; then
        actual="agent $agent"
    else
        actual="anonymous"
    fi

    echo "DEBUG: step $step: certificate $holder, On-Behalf-Of $principal: Expected: $expected  Got: $actual (status $status)"
    if [ "$expected" != "$actual" ]; then
        failures=$((failures + 1))
        mkdir -p "$work/mismatch-$step"
        cp "$work"/doc-*.nt "$work"/key-*.nt "$work/request.tsv" "$work/cache.nq" "$work/mismatch-$step/" 2>/dev/null || true
        echo "DEBUG: Mismatch! The documents, request and cache are under $work/mismatch-$step"
        trap - EXIT
        break
    fi
    mv "$work/cache-next.nq" "$work/cache.nq"
done

[ "$failures" = 0 ]
