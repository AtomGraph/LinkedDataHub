#!/bin/bash

[ -z "$JAVA_HOME" ] && echo "Need to set JAVA_HOME" && exit 1;

if [ "$#" -ne 6 ]; then
  echo "Usage:   $0" '$alias $cert_file $keystore_password $key_password $webid_uri $validity' >&2
  echo "Example: $0 martynas martynas.localhost.p12 Password Password https://localhost:4443/admin/acl/agents/ce84eb31-cc1e-41f4-9e29-dacd417b9818/#this 3650" >&2
  exit 1
fi

"$JAVA_HOME"/bin/keytool -genkeypair -alias "$1" -keyalg RSA -storetype PKCS12 -keystore "$2" -storepass "$3" -keypass "$4" -ext SAN=uri:"$5" -validity "$6"