#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_backend_cache "$END_USER_VARNISH_SERVICE"
purge_backend_cache "$ADMIN_VARNISH_SERVICE"

pwd=$(realpath -s "$PWD")

file=$(./create-file.sh)

curl -k \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  --range 10-15 \
  "$file" \
  > range1.bin

# extract byte range

dd skip=10 count=5 if="$pwd/test.csv" of=range2.bin bs=1

# compare byte ranges

echo "========"
cat range1.bin
echo "========"
cat range2.bin
echo "========"

cmp range1.bin range2.bin