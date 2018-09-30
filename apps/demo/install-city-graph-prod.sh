#!/bin/bash

[ -z "$SCRIPT_ROOT" ] && echo "Need to set SCRIPT_ROOT" && exit 1;

if [ "$#" -ne 2 ]; then
  echo "Usage:   $0 cert_pem_file cert_password" >&2
  echo "Example: $0" '../../certs/martynas.linkeddatahub.pem Password' >&2
  echo "Note: special characters such as $ need to be escaped in passwords!" >&2
  exit 1
fi

cert_pem_file=$(realpath -s $1)
cert_password=$2

pushd . && cd $SCRIPT_ROOT/apps/dydra

./install-dataspace.sh \
-b https://linkeddatahub.com/demo/ \
-f "$cert_pem_file" \
-p "$cert_password" \
--title "City Graph" \
--description "Geospatial and other open data about cities, imported by transforming CSV files to RDF" \
--slug city-graph \
--app-base https://linkeddatahub.com/demo/city-graph/ \
--public \
--admin-repository http://**********.dydra.com/city-graph/admin-prod \
--admin-service-user ********** \
--admin-service-password "**********" \
--end-user-repository http://**********.dydra.com/city-graph/prod \
--end-user-service-user ********** \
--end-user-service-password "**********"

popd