#!/usr/bin/env bash
# The Lean model is transcribed by hand from the code listed under "Mapping to the code" in README.md.
# This fails when a commit range changes one of those sources without touching the model, so the
# transcription cannot drift silently: either the definitions change in the same commit, or the README
# says why they do not.
#
# The stylesheets are large and change for other reasons, so they are tracked declaration by declaration:
# only the functions, variables and branches below count. The request sites are held to the model by
# sites.py instead, and ldh:href by the href cases.
#
# Usage: tracks-code.sh <base> [<head>]   (head defaults to HEAD; the range starts at their merge base)
set -euo pipefail

head=${2:-HEAD}
base=$(git merge-base "$1" "$head")
cd "$(git rev-parse --show-toplevel)"
model=formal/client
xsl=src/main/webapp/static/com/atomgraph/linkeddatahub/xsl

# FILE<TAB>XPATH: the declarations transcribed, each compared as xmllint serializes it
declarations=(
  "$xsl/imports/default.xsl	//*[local-name()='function'][@name='ldh:href' or @name='ldh:is-local' or @name='lds:origin']"
  "$xsl/client/functions.xsl	//*[local-name()='function'][@name='lds:base' or @name='ldh:request-uri' or @name='ac:uri']"
  "$xsl/client/chat.xsl	//*[local-name()='function'][@name='ldh:chat-href']"
  "$xsl/client.xsl	//*[local-name()='variable'][@name='application' or @name='tab-base' or @name='reuse-pane']"
  "$xsl/client.xsl	//*[local-name()='when'][starts-with(@test, '?status ge 400')]"
)

declaration_text() { # <revision> <file> <xpath>
  git show "$1:$2" 2>/dev/null | xmllint --xpath "$3" - 2>/dev/null || true
}

changed=()
for declaration in "${declarations[@]}"; do
  file=${declaration%%	*}
  xpath=${declaration#*	}
  if [ "$(declaration_text "$base" "$file" "$xpath")" != "$(declaration_text "$head" "$file" "$xpath")" ]; then
    changed+=("$file ($xpath)")
  fi
done

[ ${#changed[@]} -eq 0 ] && exit 0
[ -n "$(git diff --name-only "$base" "$head" -- "$model")" ] && exit 0

{
  echo "$model transcribes these declarations, and $(git rev-parse --short "$base")..$(git rev-parse --short "$head") changes them without touching the model:"
  printf '  %s\n' "${changed[@]}"
  echo "Change the matching definitions in $model in the same commit, or record in $model/README.md why they stand."
} >&2
exit 1
