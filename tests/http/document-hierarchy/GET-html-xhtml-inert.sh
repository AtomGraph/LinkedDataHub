#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# add agent to the readers group

ldh admin add agent \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/readers/"

# An XML literal written straight to the graph store never passes through the editor's canonical form, so the
# rendering is what keeps its markup from running on this origin (formal/xslt, sanitize_inert). Each active part
# goes - a script in either namespace, a handler, a javascript: URL however it is spelled - and the rest stays.

item=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --container "$END_USER_BASE_URL" \
  --title "Active markup" \
  --slug "active-markup")

ldh add xhtml-block \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --value '<div xmlns="http://www.w3.org/1999/xhtml"><p>kept-paragraph</p><script>alert("xhtml-script")</script><svg xmlns="http://www.w3.org/2000/svg"><script>alert("svg-script")</script><a xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="javascript:alert(&quot;xlink-href&quot;)"><text>kept-svg-link</text></a></svg><img src="kept.png" onerror="alert(&quot;handler&quot;)"/><a href="java&#9;script:alert(&quot;split-scheme&quot;)">kept-link</a><iframe srcdoc="&lt;script&gt;alert(&quot;srcdoc&quot;)&lt;/script&gt;"></iframe></div>' \
  "$item"

html=$(curl -k -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: text/html" \
  "$item")

for kept in kept-paragraph kept-svg-link kept.png kept-link
do
    echo "$html" | grep -q "$kept" || { echo "DEBUG: '$kept' was not rendered:"; echo "$html"; exit 1; }
done

# the literal's lexical form rides along on @content, escaped, where it is a string; what is rendered as markup is the
# element tree, which is what has to be inert

markup=$(echo "$html" | sed -E 's/content="[^"]*"//g')
for active in xhtml-script svg-script xlink-href handler split-scheme srcdoc
do
    if echo "$markup" | grep -q "$active"; then
        echo "DEBUG: '$active' was rendered as markup:"
        echo "$markup" | grep -o ".\{120\}$active.\{40\}" || true
        exit 1
    fi
done
