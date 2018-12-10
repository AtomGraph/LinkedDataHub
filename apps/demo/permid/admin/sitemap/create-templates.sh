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

# Instrument container

./create-template.sh \
-b "${base}admin/" \
-f "$cert_pem_file" \
-p "$cert_password" \
--uri "${base}ns/templates#InstrumentContainer" \
--label "Instrument container" \
--slug instrument-container \
--extends "${base}ns/templates#Container" \
--match "/instruments/" \
--query "${base}ns/templates#ConstructInstruments" \
--param "${base}ns/templates#HasPermId" \
--param "${base}ns/templates#HasAssetClass" \
--param "${base}ns/templates#HasInstrumentStatus" \
--param "${base}ns/templates#HasName" \
--is-defined-by "${base}ns/templates#" \

# Instrument item

./create-template.sh \
-b "${base}admin/" \
-f "$cert_pem_file" \
-p "$cert_password" \
--uri "${base}ns/templates#InstrumentItem" \
--label "Instrument item" \
--slug instrument-item \
--extends "${base}ns/templates#Item" \
--match "/1-{permid}" \
--query "https://www.w3.org/ns/ldt/core/templates#Describe" \
--is-defined-by "${base}ns/templates#" \

popd