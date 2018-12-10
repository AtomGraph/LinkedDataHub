#!/bin/bash

[ -z "$SCRIPT_ROOT" ] && echo "Need to set SCRIPT_ROOT" && exit 1;

if [ "$#" -ne 3 ]; then
  echo "Usage:   $0 $base $cert_pem_file $cert_password" >&2
  echo "Example: $0" 'https://linkeddatahub.com/atomgraph/app/admin/ ../../../../../../certs/martynas.localhost.pem Password' >&2
  echo "Note: special characters such as $ need to be escaped in passwords!" >&2
  exit 1
fi

base=$1
cert_pem_file=$(realpath -s $2)
cert_password=$3

pushd . && cd $SCRIPT_ROOT/admin/sitemap

./create-parameter.sh \
-b "${base}admin/" \
-f "$cert_pem_file" \
-p "$cert_password" \
--uri "${base}ns/templates#HasPermId" \
--label "Has PermID" \
--slug has-permid \
--predicate "http://permid.org/ontology/common/hasPermId" \
--value-type "http://www.w3.org/2001/XMLSchema#string" \
--optional \
--is-defined-by "${base}ns/templates#"

./create-parameter.sh \
-b "${base}admin/" \
-f "$cert_pem_file" \
-p "$cert_password" \
--uri "${base}ns/templates#HasAssetClass" \
--label "Has asset class" \
--slug has-asset-class \
--predicate "http://permid.org/ontology/financial/hasAssetClass" \
--value-type "http://www.w3.org/2000/01/rdf-schema#Resource" \
--optional \
--is-defined-by "${base}ns/templates#"

./create-parameter.sh \
-b "${base}admin/" \
-f "$cert_pem_file" \
-p "$cert_password" \
--uri "${base}ns/templates#HasInstrumentStatus" \
--label "Has instrument status" \
--slug has-instrument-status \
--predicate "http://permid.org/ontology/financial/hasInstrumentStatus" \
--value-type "http://www.w3.org/2000/01/rdf-schema#Resource" \
--optional \
--is-defined-by "${base}ns/templates#"

./create-parameter.sh \
-b "${base}admin/" \
-f "$cert_pem_file" \
-p "$cert_password" \
--uri "${base}ns/templates#HasName" \
--label "Has name" \
--slug has-name \
--predicate "http://permid.org/ontology/common/hasName" \
--value-type "http://www.w3.org/2001/XMLSchema#string" \
--optional \
--is-defined-by "${base}ns/templates#"

popd