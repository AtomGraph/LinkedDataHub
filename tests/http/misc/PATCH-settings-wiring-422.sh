#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# Test: PATCH /settings - the wiring is the deployment's. A dataspace's settings say what it is, not which store
# backs it or where it is served: changing lds:service or lds:origin answers 422 and the settings stay as they
# were, while a change of the title goes through

settings_url="${END_USER_BASE_URL}settings"
tag_before=$(etag "$settings_url" "$OWNER_CERT_FILE" "$OWNER_CERT_PWD")

patch_settings()
{
    curl -k -w "%{http_code}\n" -o /dev/null -s \
      -X PATCH \
      -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
      -H "Content-Type: application/sparql-update" \
      -H "Accept: application/n-triples" \
      -H "If-Match: $(etag "$settings_url" "$OWNER_CERT_FILE" "$OWNER_CERT_PWD")" \
      -d "$1" \
      "$settings_url"
}

# another dataspace's service
patch_settings "PREFIX lds: <https://w3id.org/atomgraph/linkeddatahub/dataspaces#>
DELETE { ?app lds:service ?service }
INSERT { ?app lds:service <urn:linkeddatahub:services/admin> }
WHERE { ?app lds:service ?service }" \
| grep -q "$STATUS_UNPROCESSABLE_ENTITY"

# another origin
patch_settings "PREFIX lds: <https://w3id.org/atomgraph/linkeddatahub/dataspaces#>
DELETE { ?app lds:origin ?origin }
INSERT { ?app lds:origin <https://elsewhere.localhost:4443> }
WHERE { ?app lds:origin ?origin }" \
| grep -q "$STATUS_UNPROCESSABLE_ENTITY"

# nothing changed
[ "$(etag "$settings_url" "$OWNER_CERT_FILE" "$OWNER_CERT_PWD")" = "$tag_before" ]

# what the dataspace says about itself is its own
patch_settings "PREFIX dct: <http://purl.org/dc/terms/>
DELETE { ?app dct:title ?title }
INSERT { ?app dct:title \"Renamed\" }
WHERE { ?app a <https://w3id.org/atomgraph/linkeddatahub/dataspaces#EndUserDataspace> . OPTIONAL { ?app dct:title ?title } }" \
| grep -qE "^(${STATUS_PATCH_SUCCESS})$"

curl -k -s -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" -H "Accept: application/n-triples" "$settings_url" \
| grep -q '"Renamed"'

# the title back, for the scripts after this one: the settings live in the context, which initialize_dataset does not reset
patch_settings "PREFIX dct: <http://purl.org/dc/terms/>
DELETE { ?app dct:title ?title }
INSERT { ?app dct:title \"LinkedDataHub\" }
WHERE { ?app dct:title ?title }" \
| grep -qE "^(${STATUS_PATCH_SUCCESS})$"
