#!/bin/bash

[ -z "$SCRIPT_ROOT" ] && echo "Need to set SCRIPT_ROOT" && exit 1;

if [ "$#" -ne 2 ]; then
  echo "Usage:   $0 cert_pem_file cert_password" >&2
  echo "Example: $0" '../certs/martynas.linkeddatahub.pem Password' >&2
  echo "Note: special characters such as $ need to be escaped in passwords!" >&2
  exit 1
fi

cert_pem_file=$(realpath -s $1)
cert_password=$2

pushd . && cd $SCRIPT_ROOT/apps/dydra

./install-context.sh \
-b https://linkeddatahub.com/ \
-f "$cert_pem_file" \
-b "$cert_password" \
--title Demo \
--description "LinkedDataHub demo applications developed by AtomGraph" \
--slug demo \
--app-base https://linkeddatahub.com/demo/ \
--public \
--admin-repository http://***********.dydra.com/demo/ldh-context-admin-prod \
--admin-service-user ********** \
--admin-service-password '**********' \
--end-user-repository http://**********.dydra.com/demo/ldh-context-prod \
--end-user-service-user ********** \
--end-user-service-password '**********'

popd