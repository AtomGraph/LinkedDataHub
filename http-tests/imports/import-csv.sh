#!/bin/bash

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"

pwd=$(realpath -s "$PWD")

pushd . > /dev/null && cd "$SCRIPT_ROOT"

# create container

./create-container.sh \
-f "$OWNER_CERT_FILE" \
-p "$OWNER_CERT_PWD" \
-b "$END_USER_BASE_URL" \
--title "Test" \
--slug "test" \
--parent "$END_USER_BASE_URL" \
"$END_USER_BASE_URL"

# import CSV

cd imports

import_url=$(./import-csv.sh \
-f "$OWNER_CERT_FILE" \
-p "$OWNER_CERT_PWD" \
-b "$END_USER_BASE_URL" \
--title "Test" \
--query-file "$pwd/test.rq" \
--file "$pwd/test.csv" \
--action "${END_USER_BASE_URL}test/")

popd > /dev/null

# wait until the imported item appears (since import is executed asynchronously)

counter=20
i=1

while [ "$i" -le "$counter" ] && ! curl -k -s -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" "${END_USER_BASE_URL}test/test-item/" -H "Accept: application/n-triples"  >/dev/null 2>&1
do
    sleep 1 ;
    i=$(( i+1 ))

    echo "$i"
done

# check item properties

curl -k -f -v -N \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "${END_USER_BASE_URL}test/test-item/" \
| grep "<${END_USER_BASE_URL}test/test-item/> <http://www.w3.org/1999/02/22-rdf-syntax-ns#value> \"42\"^^<http://www.w3.org/2001/XMLSchema#integer>"