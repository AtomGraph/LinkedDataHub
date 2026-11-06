#!/usr/bin/env bash
# The Lean model is transcribed by hand from the code listed under "Mapping to the code" in README.md.
# This fails when a commit range changes one of those sources without touching the model, so the
# transcription cannot drift silently: either the definitions change in the same commit, or the README
# says why they do not.
#
# The stylesheets are large and change for other reasons, so they are tracked declaration by declaration:
# only the templates, functions and instructions below count. The rendering rules are held to the model by
# the sanitize cases too, and the canonical form by its counterexamples.
#
# Usage: tracks-code.sh <base> [<head>]   (head defaults to HEAD; the range starts at their merge base)
set -euo pipefail

head=${2:-HEAD}
base=$(git merge-base "$1" "$head")
cd "$(git rev-parse --show-toplevel)"
model=formal/xslt
xsl=src/main/webapp/static/com/atomgraph/linkeddatahub/xsl

# FILE<TAB>XPATH: the declarations transcribed, each compared as xmllint serializes it
declarations=(
  "$xsl/imports/default.xsl	//*[local-name()='template'][contains(@mode, 'ldh:XHTMLContent') or contains(@mode, 'ldh:SafeXHTML')] | //*[local-name()='function'][@name='ldh:url-scheme']"
  "$xsl/imports/values.xsl	//*[local-name()='template'][@mode='ac:FormControl'][contains(@match, 'Literal')]"
  "$xsl/client/chat.xsl	//*[local-name()='template'][@mode='ldh:ChatAnswer']"
  "$xsl/layout.xsl	//*[local-name()='value-of'][@disable-output-escaping][contains(@select, 'acl:agent') or contains(@select, 'lds:origin()')]"
  "$xsl/rdfa-editor/canonical-xhtml.xsl	//*[local-name()='template'][@mode='cm:canonical'][@priority='3' or contains(@match, '^on') or contains(@match, 'javascript')] | //*[local-name()='function'][@name='cm:url-scheme']"
)

# files transcribed whole
files=(
  src/main/java/com/atomgraph/linkeddatahub/writer/impl/SameSiteSourceResolver.java
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

for file in "${files[@]}"; do
  [ -n "$(git diff --name-only "$base" "$head" -- "$file")" ] && changed+=("$file")
done

[ ${#changed[@]} -eq 0 ] && exit 0
[ -n "$(git diff --name-only "$base" "$head" -- "$model")" ] && exit 0

{
  echo "$model transcribes these declarations, and $(git rev-parse --short "$base")..$(git rev-parse --short "$head") changes them without touching the model:"
  printf '  %s\n' "${changed[@]}"
  echo "Change the matching definitions in $model in the same commit, or record in $model/README.md why they stand."
} >&2
exit 1
