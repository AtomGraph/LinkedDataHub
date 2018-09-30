#!/bin/bash

pushd . && cd ./admin

printf "\n### Creating authorization to make the app public\n\n"

./make-public.sh "$@"

popd

printf "\n### Creating documents\n\n"

./create-documents.sh "$@"

printf "\n### Uploading images\n\n"

./upload-images.sh "$@"

printf "\n### Uploading videos\n\n"

./upload-videos.sh "$@"