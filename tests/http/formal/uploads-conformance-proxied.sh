#!/usr/bin/env bash
set -euo pipefail

# uploads-conformance.sh with every request sent through the Linked Data proxy, as ?uri= on the admin base, and the
# model's prediction left as it is. The proxy delegates the caller to this instance's dataspaces and forwards Accept,
# If-None-Match and the origin's ETag, and the front cache serves a Range from the whole file it relays, so the upload
# is answered as it is directly; and since the bytes are then served from the proxy's origin, they have to carry the
# sandbox policy there too.

UPLOADS_CONFORMANCE_PROXIED=true bash -e "$HTTP_TEST_ROOT/formal/uploads-conformance.sh"
