#!/usr/bin/env bash

if [ "$#" -ne 4 ]; then
  echo "Usage:   $0" '$owner_pem_file $owner_cert_password $secretary_pem_file $secretary_cert_password' >&2
  echo "Example: $0 $PWD/ssl/owner/cert.pem OwnerPassword $PWD/ssl/secretary/cert.pem SecretaryPassword" >&2
  echo "Note: special characters such as $ need to be escaped in passwords!" >&2
  exit 1
fi

export OWNER_CERT_FILE="$(realpath "$1")"
export OWNER_CERT_PWD="$2"
export SECRETARY_CERT_FILE="$(realpath "$3")"
export SECRETARY_CERT_PWD="$4"

export STATUS_OK=200
export STATUS_DELETE_SUCCESS='200|204'
export STATUS_PATCH_SUCCESS='200|201|204'
export STATUS_POST_SUCCESS='200|201|204'
export STATUS_PUT_SUCCESS='200|201|204'
export STATUS_CREATED=201
export STATUS_NO_CONTENT=204
export STATUS_UPDATED='201|204'
export STATUS_SEE_OTHER=303
export STATUS_NOT_MODIFIED=304
export STATUS_PERMANENT_REDIRECT=308
export STATUS_BAD_REQUEST=400
export STATUS_UNAUTHORIZED=401
export STATUS_FORBIDDEN=403
export STATUS_NOT_FOUND=404
export STATUS_METHOD_NOT_ALLOWED=405
export STATUS_NOT_ACCEPTABLE=406
export STATUS_PRECONDITION_FAILED=412
export STATUS_REQUEST_ENTITY_TOO_LARGE=413
export STATUS_UNSUPPORTED_MEDIA=415
export STATUS_UNPROCESSABLE_ENTITY=422
export STATUS_INTERNAL_SERVER_ERROR=500
export STATUS_NOT_IMPLEMENTED=501
export STATUS_BAD_GATEWAY=502

# Millisecond epoch. Uses GNU date when available, otherwise falls back to Python.
_ms_probe=$(date +%s%3N 2>/dev/null)
if [[ "$_ms_probe" == *N ]] || [ -z "$_ms_probe" ]; then
    function now_ms() { python3 -c 'import time; print(int(time.time()*1000))'; }
else
    function now_ms() { date +%s%3N; }
fi
unset _ms_probe

# Escape a string for embedding inside a JSON string literal.
function json_escape()
{
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//	/\\t}"
    # Strip carriage returns, then encode newlines.
    s="${s//$'\r'/}"
    s="${s//$'\n'/\\n}"
    # Strip remaining control characters (anything below 0x20) - they would break JSON.
    s="$(printf '%s' "$s" | LC_ALL=C tr -d '\000-\037')"
    printf '%s' "$s"
}

function run_tests()
{
    local suite_name="$1"
    shift

    local error_count=0
    local suite_start_ms suite_end_ms
    suite_start_ms=$(now_ms)

    local results_file=""
    if [ -n "$TEST_RESULTS_DIR" ]; then
        mkdir -p "$TEST_RESULTS_DIR"
        results_file="$TEST_RESULTS_DIR/${suite_name}.ctrf.json"
        : > "$results_file.tests"
    fi

    local tests_total=0 tests_passed=0 tests_failed=0

    for script_pathname in "$@"
    do
        echo -n "$script_pathname";
        local script_filename script_directory
        script_filename=$(basename "$script_pathname")
        script_directory=$(dirname "$script_pathname")

        local log_file
        log_file=$(mktemp)
        local t_start_ms t_end_ms duration_ms exit_code
        t_start_ms=$(now_ms)
        ( cd "$script_directory" || exit;
            bash -e "$script_filename";
        ) > "$log_file" 2>&1
        exit_code=$?
        t_end_ms=$(now_ms)
        duration_ms=$(( t_end_ms - t_start_ms ))

        local status
        if [[ $exit_code == "0" ]]
        then
            echo "   ok"
            status="passed"
            (( tests_passed += 1 ))
        else
            echo "   failed";
            status="failed"
            (( tests_failed += 1 ))
            (( error_count += 1 ))
            # Echo the captured output so CI logs still show the failure.
            cat "$log_file"
        fi
        (( tests_total += 1 ))

        if [ -n "$results_file" ]; then
            local message=""
            if [ "$status" = "failed" ]; then
                # Keep the last ~4 KiB of captured output for the report.
                message=$(tail -c 4096 "$log_file")
            fi
            local rel_name="${script_pathname#./}"
            {
                printf '    {'
                printf '"name":"%s",' "$(json_escape "$rel_name")"
                printf '"status":"%s",' "$status"
                printf '"duration":%s,' "$duration_ms"
                printf '"suite":"%s"' "$(json_escape "$suite_name")"
                if [ -n "$message" ]; then
                    printf ',"message":"%s"' "$(json_escape "$message")"
                fi
                printf '}\n'
            } >> "$results_file.tests"
        fi

        rm -f "$log_file"
    done

    suite_end_ms=$(now_ms)

    if [ -n "$results_file" ]; then
        {
            printf '{\n'
            printf '  "results": {\n'
            printf '    "tool": {"name": "http-tests-run.sh"},\n'
            printf '    "summary": {\n'
            printf '      "tests": %s,\n' "$tests_total"
            printf '      "passed": %s,\n' "$tests_passed"
            printf '      "failed": %s,\n' "$tests_failed"
            printf '      "pending": 0,\n'
            printf '      "skipped": 0,\n'
            printf '      "other": 0,\n'
            printf '      "suites": 1,\n'
            printf '      "start": %s,\n' "$suite_start_ms"
            printf '      "stop": %s\n' "$suite_end_ms"
            printf '    },\n'
            printf '    "tests": [\n'
            # Join the per-test JSON object lines with commas.
            awk 'NR>1 {printf ",\n"} {printf "%s", $0}' "$results_file.tests"
            printf '\n    ]\n'
            printf '  }\n'
            printf '}\n'
        } > "$results_file"
        rm -f "$results_file.tests"
    fi

    return $error_count
}

function download_dataset()
{
    curl -s -f \
      -H "Accept: application/trig" \
      "$1"
}

function initialize_dataset()
{
    echo "@base <$1> ." \
    | cat - "$2" \
    | curl -f -s \
      -X PUT \
      --data-binary @- \
      -H "Content-Type: application/trig" \
      "$3" > /dev/null
}

function purge_cache()
{
    local service_name="$1"

    if [ -n "$(docker compose -f "$HTTP_TEST_ROOT/../docker-compose.yml" -f "$HTTP_TEST_ROOT/docker-compose.http-tests.yml" --env-file "$HTTP_TEST_ROOT/.env" ps -q | grep "$(docker compose -f "$HTTP_TEST_ROOT/../docker-compose.yml" -f "$HTTP_TEST_ROOT/docker-compose.http-tests.yml" --env-file "$HTTP_TEST_ROOT/.env" ps -q $service_name )" )" ]; then
        docker compose -f "$HTTP_TEST_ROOT/../docker-compose.yml" -f "$HTTP_TEST_ROOT/docker-compose.http-tests.yml" --env-file "$HTTP_TEST_ROOT/.env" exec -T "$service_name" varnishadm "ban req.url ~ /" > /dev/null # purge all entries
    fi
}

export OWNER_URI="$(webid-uri.sh "$OWNER_CERT_FILE")"
if [ -z "$OWNER_URI" ]; then
    echo "Failed to extract the owner's WebID URI from the cert file: $OWNER_CERT_FILE"
    exit 1
fi

printf "### Owner agent URI: %s\n" "$OWNER_URI"

export SECRETARY_URI="$(webid-uri.sh "$SECRETARY_CERT_FILE")"

if [ -z "$SECRETARY_URI" ]; then
    echo "Failed to extract the secretary's WebID URI from the cert file: $SECRETARY_CERT_FILE"
    exit 1
fi

printf "### Secretary agent URI: %s\n" "$SECRETARY_URI"

export -f initialize_dataset
export -f purge_cache

export HTTP_TEST_ROOT="$PWD"
export TEST_RESULTS_DIR="${TEST_RESULTS_DIR:-$HTTP_TEST_ROOT/out}"
mkdir -p "$TEST_RESULTS_DIR"
export END_USER_ENDPOINT_URL="http://localhost:3031/ds/"
export ADMIN_ENDPOINT_URL="http://localhost:3030/ds/"
export END_USER_BASE_URL="https://localhost:4443/"
export ADMIN_BASE_URL="https://admin.localhost:4443/"
export END_USER_VARNISH_SERVICE="varnish-end-user"
export ADMIN_VARNISH_SERVICE="varnish-admin"
export FRONTEND_VARNISH_SERVICE="varnish-frontend"

error_count=0

### Signup test ###

export AGENT_CERT_FILE=$(mktemp)
export AGENT_CERT_PWD="changeit"

start_time=$(date +%s)

run_tests "signup" "signup.sh"
(( error_count += $? ))

export AGENT_URI="$(webid-uri.sh "$AGENT_CERT_FILE")"
printf "### Signed up agent URI: %s\n" "$AGENT_URI"

# store the end-user and admin datasets
export TMP_END_USER_DATASET=$(mktemp)
export TMP_ADMIN_DATASET=$(mktemp)
download_dataset "$END_USER_ENDPOINT_URL" > "$TMP_END_USER_DATASET"
download_dataset "$ADMIN_ENDPOINT_URL" > "$TMP_ADMIN_DATASET"

### Other tests ###

run_tests "add" $(find ./add/ -type f -name '*.sh')
(( error_count += $? ))
run_tests "admin" $(find ./admin/ -type f -name '*.sh')
(( error_count += $? ))
run_tests "dataspaces" $(find ./dataspaces/ -type f -name '*.sh')
(( error_count += $? ))
run_tests "access" $(find ./access/ -type f -name '*.sh')
(( error_count += $? ))
run_tests "imports" $(find ./imports/ -type f -name '*.sh')
(( error_count += $? ))
run_tests "document-hierarchy" $(find ./document-hierarchy/ -type f -name '*.sh')
(( error_count += $? ))
run_tests "misc" $(find ./misc/ -type f -name '*.sh')
(( error_count += $? ))
run_tests "proxy" $(find ./proxy/ -type f -name '*.sh')
(( error_count += $? ))
run_tests "sparql-protocol" $(find ./sparql-protocol/ -type f -name '*.sh')
(( error_count += $? ))

end_time=$(date +%s)
runtime=$((end_time-start_time))

echo "### Failed tests: ${error_count} Test duration: ${runtime} s"

### Exit

# restore original datasets
initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"

rm "$AGENT_CERT_FILE"
rm "$TMP_END_USER_DATASET"
rm "$TMP_ADMIN_DATASET"

exit $error_count
