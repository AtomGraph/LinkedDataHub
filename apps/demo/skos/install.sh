#!/bin/bash

pushd . && cd ./admin

printf "\n### Creating authorization to make the app public\n\n"

./make-public.sh "$@"

cd model

printf "\n### Creating constructor queries\n\n"

./create-constructors.sh "$@"

printf "\n### Creating classes\n\n"

./create-classes.sh "$@"

printf "\n### Creating constraints\n\n"

./create-constraints.sh "$@"

printf "\n### Creating restrictions\n\n"

./create-restrictions.sh "$@"

popd

pushd . && cd ./admin

printf "\n### Clearing ontologies\n\n"

./clear-ontologies.sh "$@"

popd

printf "\n### Creating containers\n\n"

./create-containers.sh "$@"