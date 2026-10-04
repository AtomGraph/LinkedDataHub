#!/usr/bin/env bash
# Publishes this fixture package registry onto a LinkedDataHub dataspace, the way
# LinkedDataHub-Apps/packages/install.sh publishes https://packages.linkeddatahub.com/: pushes the document
# tree, whose folders are the package URIs, and declares each package's stylesheet, which the push uploads
# as text/xsl, by the URI of that upload.
#
# The package tests import from here rather than from the public registry, so that they depend on neither
# its reachability nor its current content. editor/taxonomy is a copy of the taxonomy editor package from
# LinkedDataHub-Apps; what the tests assert about it (its constructors, views and stylesheet rules) is
# pinned by this copy and changes only when it is updated here.
#
# Usage: publish.sh BASE_URI KEYSTORE PASSWORD
set -euo pipefail

base="$1"
cert="$2"
password="$3"
dir="$(cd "$(dirname "$0")" && pwd)"

ldh push -c "$cert" -p "$password" --dir "$dir" "$base" > /dev/null

# a package is the folder its stylesheet is in, e.g. editor/taxonomy/skos.xsl -> ${base}editor/taxonomy/#this
(cd "$dir" && find . -name '*.xsl' | sed 's|^\./||' | sort) | while read -r stylesheet; do
    package_doc="${base}$(dirname "$stylesheet")/"
    upload="${base}uploads/$(shasum -a 1 "$dir/$stylesheet" | cut -d' ' -f1)"
    echo "INSERT { <${package_doc}#this> <https://w3id.org/atomgraph/client#stylesheet> <${upload}> } WHERE { }" |
        ldh patch -c "$cert" -p "$password" "$package_doc"
done
