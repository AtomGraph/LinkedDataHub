#!/bin/bash

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

function initialize_dataset()
{
    #echo "@base <${1}> ." \
    #| cat - "$2" \
    cat "$2" \
    | curl -f -s \
      -X PUT \
      --data-binary @- \
      -H "Content-Type: application/n-quads" \
      "${3}" > /dev/null
}

export -f initialize_dataset

export ADMIN_ENDPOINT_URL="http://localhost:3030/ds/"
export TMP_ADMIN_DATASET="/tmp/original_admin_dataset.nq"

curl "$ADMIN_ENDPOINT_URL" -s -f -H "Accept: application/n-quads" > "$TMP_ADMIN_DATASET"

error_count=0

### Authorization tests ###

export END_USER_BASE_URL="https://localhost:4443/"
export ADMIN_BASE_URL="https://localhost:4443/admin/"
export CERT_FILE="$PWD/../certs/owner.p12.pem"

#initialize_dataset "$BASE_URL" "dataset.trig" "$ADMIN_ENDPOINT_URL"
#initialize_dataset "$BASE_URL_WRITABLE" "dataset.trig" "$ADMIN_ENDPOINT_URL_WRITABLE"

run_tests $(find ./acl/ -name '*.sh*')
(( error_count += $? ))

### Exit

rm "$TMP_ADMIN_DATASET"

exit $error_count