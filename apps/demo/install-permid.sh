#!/bin/bash

[ -z "$SCRIPT_ROOT" ] && echo "Need to set SCRIPT_ROOT" && exit 1;

if [ "$#" -ne 5 ]; then
  echo "Usage:   $0 cert_pem_file cert_password" >&2
  echo "Example: $0" '../../certs/martynas.stage.localhost.pem Password' >&2
  echo "Note: special characters such as $ need to be escaped in passwords!" >&2
  exit 1
fi

cert_pem_file=$(realpath -s $1)
cert_password=$2
base=$3
admin_repository=$4
end_user_repository=$5

pushd . && cd $SCRIPT_ROOT/apps/dydra

./install-dataspace.sh \
-b "${base}" \
-f "${cert_pem_file}" \
-p "${cert_password}" \
--title "PermID" \
--description "Thomson Reuters PermIDs are open, permanent and universal identifiers where underlying attributes capture the context of the identity they each represent." \
--slug permid \
--app-base "${base}permid/" \
--public \
--stylesheet "${base}uploads/ca0ab57ff8efc66324c12345fa587862d1334ef1" \
--admin-repository "${admin_repository}" \
--admin-service-user ********** \
--admin-service-password '**********' \
--end-user-repository "${end_user_repository}" \
--end-user-service-user ********** \
--end-user-service-password '**********'

cd ..

./add-base.sh \
-f "${cert_pem_file}" \
-p "${cert_password}" \
--app-base https://permid.org/ \
"${base}apps/end-user/permid" # TO-DO: retrieve app URI value from install-dataspace

cd ../admin/acl

./create-authorization.sh \
-b "${base}admin/" \
-f "${cert_pem_file}" \
-p "${cert_password}" \
--label "Public PermID XSLT stylesheet" \
--agent-class http://xmlns.com/foaf/0.1/Agent \
--to "${base}uploads/ca0ab57ff8efc66324c12345fa587862d1334ef1" \
--read

./create-authorization.sh \
-b "${base}admin/" \
-f "${cert_pem_file}" \
-p "${cert_password}" \
--label "Public PermID CSS stylesheet" \
--agent-class http://xmlns.com/foaf/0.1/Agent \
--to "${base}uploads/802e46b09118457d6114eb10cec2cad7c661afc" \
--read

popd

$SCRIPT_ROOT/imports/create-file.sh \
-b "${base}" \
-f "${cert_pem_file}" \
-p "${cert_password}" \
--title "PermID XSLT stylesheet" \
--file "permid.xsl" \
--file-content-type "text/xsl"

$SCRIPT_ROOT/imports/create-file.sh \
-b "${base}" \
-f "${cert_pem_file}" \
-p "${cert_password}" \
--title "PermID CSS stylesheet" \
--file "permid.css" \
--file-content-type "text/css"