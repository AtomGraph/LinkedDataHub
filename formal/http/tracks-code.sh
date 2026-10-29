#!/usr/bin/env bash
# The Lean model of the graph store is transcribed by hand from the code listed under "Mapping to the code" in
# README.md.
# This fails when a commit range changes one of those sources without touching the model, so the
# transcription cannot drift silently: either the definitions change in the same commit, or the README
# says why they do not.
#
# Usage: tracks-code.sh <base> [<head>]   (head defaults to HEAD; the range starts at their merge base)
set -euo pipefail

head=${2:-HEAD}
base=$(git merge-base "$1" "$head")
cd "$(git rev-parse --show-toplevel)"
model=formal/http
web_xml=src/main/webapp/WEB-INF/web.xml
config=https://w3id.org/atomgraph/linkeddatahub/config#

# Sources transcribed whole: any change counts
sources=(
  src/main/java/com/atomgraph/linkeddatahub/server/model/impl/DocumentHierarchyGraphStoreImpl.java
  src/main/java/com/atomgraph/linkeddatahub/server/util/EntityTags.java
  src/main/java/com/atomgraph/linkeddatahub/server/util/GraphVersioningService.java
  src/main/java/com/atomgraph/linkeddatahub/server/filter/response/VersioningFilter.java
  src/main/java/com/atomgraph/linkeddatahub/client/GitHubClient.java
)
# web.xml is transcribed query by query: only these context params count
queries=(childQuery)

changed=()
while IFS= read -r file; do
  [ -n "$file" ] && changed+=("$file")
done < <(git diff --name-only "$base" "$head" -- "${sources[@]}")

query_text() { # <revision> <param name>
  git show "$1:$web_xml" | xmllint --xpath "string(//*[local-name()='context-param'][*[local-name()='param-name']='$config$2']/*[local-name()='param-value'])" -
}
for query in "${queries[@]}"; do
  if [ "$(query_text "$base" "$query")" != "$(query_text "$head" "$query")" ]; then
    changed+=("$web_xml ($query)")
  fi
done

[ ${#changed[@]} -eq 0 ] && exit 0
[ -n "$(git diff --name-only "$base" "$head" -- "$model")" ] && exit 0

{
  echo "$model transcribes these sources, and $(git rev-parse --short "$base")..$(git rev-parse --short "$head") changes them without touching the model:"
  printf '  %s\n' "${changed[@]}"
  echo "Change the matching definitions in $model in the same commit, or record in $model/README.md why they stand."
} >&2
exit 1
