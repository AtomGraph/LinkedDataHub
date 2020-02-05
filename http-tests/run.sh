#!/bin/bash

if [ "$#" -ne 2 ]; then
  echo "Usage:   $0 cert_pem_file cert_password" >&2
  echo "Example: $0 $PWD/../certs/owner.p12.pem Password" >&2
  echo "Note: special characters such as $ need to be escaped in passwords!" >&2
  exit 1
fi

export OWNER_CERT_FILE="$1"
export OWNER_CERT_PWD="$2"
export SCRIPT_ROOT="$PWD/../scripts"

export STATUS_OK=200
export STATUS_DELETE_SUCCESS='200|204'
export STATUS_PATCH_SUCCESS='200|201|204'
export POST_SUCCESS='20201|204'
export STATUS_POST_SUCCESS='200|201|204'
export PUT_SUCCESS='201|204'
export STATUS_PUT_SUCCESS='200|201|204'
export STATUS_CREATED=201
export STATUS_NO_CONTENT=204
export STATUS_UPDATED='201|204'
export DELETE_SUCCESS=204
export STATUS_BAD_REQUEST=400
export STATUS_UNAUTHORIZED=401
export STATUS_FORBIDDEN=403
export STATUS_NOT_FOUND=404
export STATUS_NOT_ACCEPTABLE=406
export STATUS_UNSUPPORTED_MEDIA=415
export STATUS_INTERNAL_SERVER_ERROR=500
export STATUS_NOT_IMPLEMENTED=501

function run_tests()
{
    local error_count=0
    for script_pathname in "$@"
    do
        echo -n "$script_pathname";
        script_filename=$(basename "$script_pathname")
        script_directory=$(dirname "$script_pathname")
        ( cd "$script_directory" || exit;
            bash -e "$script_filename";
        )
        if [[ $? == "0" ]]
        then
            echo "   ok"
        else
            echo "   failed";
            (( error_count += 1))
        fi
    done
    return $error_count
}

function download_dataset()
{
    curl -s -f \
      -H "Accept: application/trig" \
      "${1}"
}

function initialize_dataset()
{
    echo "@base <${1}> ." \
    | cat - "${2}" \
    | curl -f -s \
      -X PUT \
      --data-binary @- \
      -H "Content-Type: application/trig" \
      "${3}" > /dev/null
}

export -f initialize_dataset

export END_USER_ENDPOINT_URL="http://localhost:3031/ds/"
export ADMIN_ENDPOINT_URL="http://localhost:3030/ds/"
export END_USER_BASE_URL="https://localhost:4443/"
export ADMIN_BASE_URL="https://localhost:4443/admin/"

error_count=0

### Authorization tests ###

export AGENT_CERT_FILE=$(mktemp)
export AGENT_CERT_PWD="changeit"

run_tests "signup.sh"
(( error_count += $? ))

export AGENT_WEBID_URI="$(../scripts/webid-uri.sh "$AGENT_CERT_FILE" "$AGENT_CERT_PWD")"

# store the end-user and admin datasets
export TMP_END_USER_DATASET=$(mktemp)
export TMP_ADMIN_DATASET=$(mktemp)
download_dataset "$END_USER_ENDPOINT_URL" > "$TMP_END_USER_DATASET"
download_dataset "$ADMIN_ENDPOINT_URL" > "$TMP_ADMIN_DATASET"

run_tests $(find ./admin/ -name '*.sh')
run_tests $(find ./imports/ -name '*.sh')
(( error_count += $? ))

### Exit

# restore original datasets
initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"

rm "$AGENT_CERT_FILE"
rm "$TMP_END_USER_DATASET"
rm "$TMP_ADMIN_DATASET"

exit $error_count