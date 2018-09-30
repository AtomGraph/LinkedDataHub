#!/bin/bash

[ -z "$SCRIPT_ROOT" ] && echo "Need to set SCRIPT_ROOT" && exit 1;

if [ "$#" -ne 3 ]; then
  echo "Usage:   $0 $base $cert_pem_file $cert_password" >&2
  echo "Example: $0" 'https://linkeddatahub.com/atomgraph/app/ ../../../../../certs/martynas.localhost.pem Password' >&2
  echo "Note: special characters such as $ need to be escaped in passwords!" >&2
  exit 1
fi

base=$1
cert_pem_file=$(realpath -s $2)
cert_password=$3

pwd=$(realpath -s $PWD)

pushd . && cd $SCRIPT_ROOT/admin/model

./create-construct.sh \
-b "${base}admin/" \
-f "$cert_pem_file" \
-p "$cert_password" \
--uri "${base}ns/domain#ConstructConcept" \
--label "Construct concept" \
--slug construct-concept \
--query-file "$pwd/queries/construct-concept.rq"

./create-construct.sh \
-b "${base}admin/" \
-f "$cert_pem_file" \
-p "$cert_password" \
--uri "${base}ns/domain#ConstructConceptScheme" \
--label "Construct concept scheme" \
--slug construct-concept-scheme \
--query-file "$pwd/queries/construct-concept-scheme.rq"

popd