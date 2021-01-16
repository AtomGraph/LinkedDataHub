#!/bin/bash

### This script is specific to LinkedDataHub Cloud version. See https://linkeddatahub.com/

hash curl 2>/dev/null || { echo >&2 "curl not on \$PATH. Aborting."; exit 1; }

if [ "$#" -ne 2 ]; then
  echo "Usage:   $0 $auth_token $repository" >&2
  echo "Example: $0" 'XXXXXX http://dydra.com/account/repository' >&2
  exit 1
fi

auth_token=$1
repository=$2

curl -s -X DELETE "${repository}/service?auth_token=${auth_token}"