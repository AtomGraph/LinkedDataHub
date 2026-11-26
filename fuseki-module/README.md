# LinkedDataHub Fuseki module

A Fuseki module that makes a SPARQL `SERVICE` call on behalf of the agent who asked the query.

## Why

A query asked at one dataspace's endpoint can name another dataspace - of this deployment or of another LinkedDataHub
- with `SERVICE <https://people.example/sparql> { … }`. The platform knows who asked; the triplestore, which makes the
`SERVICE` call, does not, so the call arrived anonymous and the other dataspace's endpoint, which guards itself,
refused it. Each dataspace decides its own access; what was missing is the asking agent's identity on the second hop.

## How

1. **The platform marks the call** (`ServiceTargets`, `ServiceDelegation` in the platform). Before the query goes to
   the store, every `https` `SERVICE` IRI gets three parameters: `ldh-on-behalf-of` (the agent's WebID),
   `ldh-expires` (seconds since the epoch, five minutes on) and `ldh-signature` (base64url `SHA256withRSA` with the
   secretary's private key over `target \n agent \n expires`). Any marker a query author wrote is removed first.
2. **The store delegates the call** (this module). `DelegatingServiceExecutor` sits in Jena's `SERVICE` chain. For a
   marked IRI it checks the signature against the secretary's certificate (a forged, partial or expired marker fails
   the query, `SILENT` or not), removes the marker, and asks the target - by an anonymous TLS handshake, remembered
   per origin for ten minutes - whether it wants a client certificate:
   - if it does, the call is made as the secretary with `On-Behalf-Of` naming the agent, exactly as the platform's
     Linked Data proxy sends a write to another instance; the target's `WebIDFilter` accepts it when the agent's
     WebID says the secretary delegates for them, and its own access control decides;
   - if it does not (a public SPARQL service), the call is made anonymously, as before: the agent is not announced to
     an endpoint that does not ask who is calling.

   A target on this deployment's host or a subdomain is reached through nginx's client-certificate listener under its
   own name, trusting the deployment's server certificate, as the platform reaches its own origins; any other target is
   reached as named, through the JVM's proxy (the egress proxy).

The signature is what lets the store trust a marker: anything that can send the store a query could write the
parameters, but only the platform holds the secretary's key. The store holds the key too, to answer the target's
certificate request - as the `web-algebra` service already does to act for users.

## Configuration

| Variable | What |
| --- | --- |
| `LDH_DELEGATION_KEYSTORE` | the secretary's PKCS#12 keystore (`ssl/secretary/keystore.p12`) |
| `LDH_DELEGATION_KEYSTORE_PASSWORD_FILE` | its password (`/run/secrets/secretary_cert_password`) |
| `LDH_DELEGATION_TRUSTSTORE` | the deployment's server certificate, PEM (`ssl/server/server.crt`) |
| `LDH_DELEGATION_HOST` | the deployment's host; it and its subdomains are its own origins |
| `LDH_DELEGATION_PROXY_HOST`, `LDH_DELEGATION_PROXY_PORT` | nginx's client-certificate listener (`nginx`, `9443`) |

The keystore is read at the first marked call: the platform makes it and starts after the store. Without
`LDH_DELEGATION_KEYSTORE` the module drops every marker before the call, so a marked query never sends the agent's
WebID or the signature on. The platform marks only with `SERVICE_DELEGATION=true`; a deployment on a stock Fuseki
turns it off.

## Image

The `fuseki` stage of the platform's `Dockerfile`: `atomgraph/fuseki` with this jar in `/fuseki/extra/` and an
entrypoint that puts it on the classpath (the stock entrypoint starts the server with `-jar`, which reads no other jar)
and lets the `Host` header through for calls to the own origins (`-Djdk.httpclient.allowRestrictedHeaders=host`).
Released as `atomgraph/linkeddatahub-fuseki` with the platform.

## Cost

Each delegated `SERVICE` call is a TLS round trip and an access-control decision at the target, and ARQ makes one call
per solution of the pattern before the `SERVICE`; a query that joins several dataspaces should put the `SERVICE` with
the larger result first.
