#!/usr/bin/env bash
set -euo pipefail

# acl-conformance.sh with every request sent through the Linked Data proxy, as ?uri= on the other dataspace's base,
# and the model's prediction left as it is. The proxy delegates the caller to this instance's dataspaces (its
# certificate plus On-Behalf-Of), forwards the method, the body and the preconditions, and relays the origin's status,
# so a proxied request has to be decided for the agent who sent it and answered as if it had been sent directly: what
# an agent can do through the proxy is exactly what it can do without it.

ACL_CONFORMANCE_PROXIED=true bash -e "$HTTP_TEST_ROOT/formal/acl-conformance.sh"
