#!/bin/bash

[ -z "$SCRIPT_ROOT" ] && echo "Need to set SCRIPT_ROOT" && exit 1;

if [ "$#" -ne 2 ]; then
  echo "Usage:   $0 $auth_token $repository" >&2
  echo "Example: $0" 'XXXXXX http://dydra.com/account/repository' >&2
  exit 1
fi

auth_token=$1
repository=$2

curl -v -X DELETE "${repository}/service?auth_token=${auth_token}"