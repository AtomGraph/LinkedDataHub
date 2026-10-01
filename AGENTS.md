# LinkedDataHub — Agent Guide

This document describes how an autonomous agent (or any HTTP/LLM client) drives a **running LinkedDataHub (LDH) instance's HTTP API**. It is the API-usage counterpart to `CLAUDE.md` (which is for contributing to the codebase).

LinkedDataHub is a data-driven Knowledge Graph platform. Everything — documents, applications, access control, the UI — is RDF, managed over a small, uniform HTTP API and standard protocols. There is no bespoke REST surface to learn: you work with RDF documents and SPARQL.

## Data model

- The content is a **hierarchy of documents** (containers and items). A container holds child documents; items are leaves.
- **Every document URL is a named graph.** Reading a document returns the RDF in that graph; writing changes it. This is the [SPARQL 1.1 Graph Store Protocol](https://www.w3.org/TR/sparql11-http-rdf-update/).
- Identifiers are opaque URLs. Do not parse structure out of them; follow links (hypermedia) instead.
- The vocabularies LDH defines live under `https://w3id.org/atomgraph/linkeddatahub`:

| Prefix | Namespace | Holds |
|---|---|---|
| `ldh:` | `https://w3id.org/atomgraph/linkeddatahub#` | content blocks, views, charts, imports, packages |
| `dh:` | `https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#` | `dh:Container`, `dh:Item` |
| `lds:` | `https://w3id.org/atomgraph/linkeddatahub/dataspaces#` | dataspaces, services, ontologies |
| `lacl:` | `https://w3id.org/atomgraph/linkeddatahub/admin/acl#` | the admin ACL extensions to `acl:` |

`ac:` is `https://w3id.org/atomgraph/client#` (Web-Client's presentation vocabulary) and `acl:` is `http://www.w3.org/ns/auth/acl#`.

## Authentication

- **WebID-TLS** (client certificate) is the primary mechanism for programmatic agents. Every request carries the cert; the certificate's WebID is the agent identity. With `curl`: `-E cert.pem:password` (`-k` in dev with self-signed certs).
- **OAuth2 (Google)** and **OpenID Connect (ORCID)** are available for human logins.
- **Delegation**: an authorized secretary agent can act for a principal via the `On-Behalf-Of: <principal-WebID>` request header.
- Authorization is WebID-based ACLs (`acl:Read`/`Append`/`Write`/`Control`), enforced per document.
- Every response advertises its context in `Link` headers, whose relation types are the property URIs: `acl:agent` (the authenticated agent's WebID), one `acl:mode` per access mode the agent holds on this resource, `sd:endpoint` (the SPARQL endpoint), `lds:dataspace`, `lds:ontology` and `ac:stylesheet`. Read the wiring off these rather than assembling URLs by convention.

## Reading data

`GET` a document URL with content negotiation:

- `Accept: text/turtle` · `application/rdf+xml` · `application/ld+json` · `application/n-triples` (any RDF serialization Jena supports) → the document's RDF.
- `Accept: text/html` → the application shell (Saxon-JS then renders client-side). Request RDF, not HTML, when you want data.
- `Accept-Language` is honoured and answered with `Content-Language` and `Vary: Accept-Language`. Property values come ordered by the reader's language preference.

`HEAD` is answered for any access mode the agent holds, so an agent with `acl:Write` or `acl:Append` alone can read the validator its writes have to quote. `GET` needs `acl:Read`.

## Writing data (the discipline)

Writes go through the **document URLs**, never through the SPARQL endpoint (which is read-only):

| Intent | Method | Body | Answer |
|--------|--------|------|--------|
| Create a document at a URL you choose | `PUT` document URL | RDF (e.g. `Content-Type: text/turtle`) | `201` with `Location` = that URL. The parent container must already exist |
| Replace an existing document | `PUT` document URL | RDF | `200`; replaces the whole named graph |
| Append to a document | `POST` document URL | RDF | `204` with the updated `ETag`; merges into the named graph |
| Update a document in place | `PATCH` document URL | `Content-Type: application/sparql-update` | `204` with the updated `ETag`; a SPARQL Update (`INSERT`/`DELETE`) applied to that named graph |
| Delete a document | `DELETE` document URL | — | Removes the named graph |
| Upload a file | `POST`/`PUT` document URL | `multipart/form-data` | The file is content-addressed at `{base}uploads/{sha1}` |

There is no LDP-style `POST` to a container that mints a child URL: the client picks the URL (a slug, or a UUID), and `PUT` creates it. Relative URIs in a request body resolve against the target URL. Blank nodes are skolemized against it.

The `PATCH` update is executed in the context of the one named graph, so the `GRAPH` keyword is not allowed in it. An update that empties the graph is treated as a `DELETE`. An update that strips `rdf:type` off a resource that keeps other properties answers `422` — SPIN constraints are class-scoped, and removing the type would bypass them silently. So does a result that violates the ontology's SHACL shapes, carrying bounded descriptions of the violating resources.

### Conditional writes are mandatory

Since 6.0.0 every write is conditional:

- A write to a document that **already exists** must carry `If-Match: <ETag>`. Without it the server answers `428 Precondition Required`. An empty `If-Match` counts as absent.
- A write meant to **create** carries `If-None-Match: *` instead, and cannot also carry `If-Match`.
- A failed precondition answers `412` **with the document's current entity tag**, so the retry needs no second read.
- An entity tag identifies a **negotiated variant** (a SHA-256 digest of the graph URI and its statements, folded with the variant, languages included). The read that supplies the validator must therefore send the same `Accept` and `Accept-Language` as the write that quotes it. A tag read as `application/rdf+xml` and quoted by a write that negotiates to HTML can never agree — `412`.
- A write invalidates the tag it quoted, so the next one cannot reuse it. `POST` and `PATCH` answer `204` with the updated tag — record it. After a `PUT`, re-read the validator with `HEAD` under the same `Accept` and `Accept-Language`.

`ldh` does all of the above for you.

## Querying (read-only)

The dataspace exposes a **read-only SPARQL 1.1 Query** endpoint (advertised via the Service Description `sd:endpoint`; conventionally `/sparql`). `GET`/`POST` a `SELECT`/`CONSTRUCT`/`DESCRIBE`/`ASK`; results are content-negotiated. The endpoint does **not** accept SPARQL Update — mutate via `PATCH` on document URLs (above).

Write portable, standard SPARQL: use explicit `GRAPH` patterns, no engine-specific extensions.

**The default graph is empty.** Every document is a named graph whose name is the document's URL, so a triple pattern outside `GRAPH` matches nothing. Put the patterns inside `GRAPH ?g { ... }` to query across every document, or inside `GRAPH <document URL> { ... }` for one document; a subquery needs its own `GRAPH` as well. A query that returns no rows without a `GRAPH` clause is not evidence that the data is absent.

Outbound `SERVICE` and `LOAD` — from the triplestore and from the platform alike — are routed through the `egress` forward proxy, which refuses loopback, private and link-local destinations. A federated query reaches public endpoints and cannot reach the deployment's own services. With no proxy configured and `ALLOW_INTERNAL_URLS` unset, in-JVM `SERVICE` (in a `PATCH` update or an import mapping) is disabled outright.

## Content & document model

- Documents carry ordered **content blocks**, attached by RDF container membership properties — `rdf:_1`, `rdf:_2`, … on the document resource. Reordering a block rewrites those predicates.
- Only `ldh:Object` (an embedded RDF resource view, `rdf:value` naming the resource) and `ldh:XHTML` (rich text, `rdf:value` an `rdf:XMLLiteral`) are permitted as block values; anything else must be wrapped in an `ldh:Object`.
- **Views** (`ldh:View`) are SPARQL-driven blocks (`SELECT`/`CONSTRUCT`/`DESCRIBE`) rendered as lists, tables, grids, charts, maps, or a graph.
- Forms and validation are ontology-driven (SPIN constructors + SHACL shapes), so instance data is shaped by the app's ontology rather than hardcoded schemas.
- **Imports** are documents too: an `ldh:CSVImport` or `ldh:RDFImport` resource with `ldh:file` (the source), `spin:query` (the transformation) and, for CSV, `ldh:delimiter`. Creating one submits the ingest; the source URIs are validated before being fetched.
- **Packages** bundle an ontology with an optional stylesheet. An application imports one by declaring a single `<app> ldh:import <package>` triple in its settings — the declaration *is* the installation. It takes effect on the next request, with no restart.

## Versions (Memento)

A document in a versioned application serves the three [RFC 7089](https://datatracker.ietf.org/doc/html/rfc7089) roles as query parameters on its own URL, advertised in `Link` headers with `type="application/link-format"`:

| Role | Request | Answer |
|---|---|---|
| Version history (TimeMap) | `GET <doc>?timemap` | A `prov:Collection` of mementos, or `application/link-format`. `404` when the document has no versions |
| A historical version (Memento) | `GET <doc>?version=<sha>` | That version, with `Memento-Datetime` and a `rel=original` link back |
| TimeGate | `GET <doc>?timegate` with `Accept-Datetime` | `302` to the closest version, `Vary: accept-datetime`, `no-store` |

The TimeMap is described with PROV-O (`prov:Entity` mementos, `prov:specializationOf` the original, `prov:generatedAtTime`, `prov:wasRevisionOf`). `application/link-format` is served only for `?timemap`; asking for it anywhere else answers `406`.

## Endpoints beyond documents

| Path | Method | Access | Purpose |
|---|---|---|---|
| `/sparql` | `GET`/`POST` | `acl:AuthenticatedAgent` | Read-only SPARQL 1.1 Query over the dataspace |
| `/ns` | `GET`/`POST` | public | A SPARQL endpoint over the in-memory application ontology. A plain `GET` returns the standalone namespace graph (not the full `owl:imports` closure) |
| `/access?this=<doc URI>` | `GET` | public | The current agent's `acl:Authorization`s for that document |
| `/access/request` | `POST` | public | Request access to a document |
| `/settings` | `GET`, `PATCH` | owner | The running dataspace's settings; `PATCH` (`application/sparql-update`) is how an `ldh:import` is declared live |
| `/clear` | `POST` | owner | Empties the ontology cache; the optional `uri` form parameter also purges that URI's proxy caches and reassembles its closure |
| `/uploads/{sha1}` | `GET` | per ACL | A content-addressed upload |
| `/sign up` | `GET`, `POST` | public | WebID sign-up, which hands back a PKCS12 keystore |
| `/oauth2/login/{google,orcid}`, `/oauth2/authorize/{google,orcid}` | `GET` | public | Human login flows |
| `/sitemap.xml`, `/robots.txt` | `GET` | public | Per-dataspace, generated at startup from that dataspace's public read rules and served at servlet level |

`/ns` and `/sign up` are public in the ACL query itself. The rest of the access column is the authorizations a dataspace is seeded with, which a deployment is free to change — read the `acl:mode` `Link` headers of a response to learn what the agent actually holds.

## The Linked Data proxy, and federation

An external URI is read **through the dataspace**, never fetched cross-origin: `GET <base>?uri=<external URI>`.

- With an RDF `Accept`, the server dereferences the URI, parses the RDF and returns it, forwarding the external response's `Link` headers.
- With `Accept: text/html` the proxy is bypassed and the local application shell is returned; the browser then makes the RDF-typed request itself.
- `MAX_CONTENT_LENGTH` bounds what the proxy fetches. An oversize upstream response answers `502`.

Federation rides on the forwarded headers: the remote dataspace's `sd:endpoint` arrives as a `Link`, so a client can query the remote app's endpoint and write to its documents under its own preconditions.

## Dataspaces

A single instance hosts multiple **dataspaces**, each a subdomain (origin). Each dataspace pairs an end-user app (`<subdomain>`) with an admin app at the **`admin.` prefix** (`admin.<subdomain>`) — never an `/admin` path. Admin apps manage ontologies, ACLs, and app settings.

## Statuses that read as bugs

- **`403` where you expect `404`.** The ACL query fails closed on a typeless resource, so a non-owner request for a URL that does not exist is answered `403`.
- **`428`** on any write to an existing document that carries no `If-Match`; **`412`** when the tag quoted was read under a different negotiated variant. See *Conditional writes*.
- **`502`** (rather than `413`) when an upstream response exceeds `MAX_CONTENT_LENGTH`: what was too large is the upstream's response. Requests to the deployment's own SPARQL, Graph Store and Quad Store services are exempt from the bound.
- **`406`** for `application/link-format` on anything but `?timemap`.

## Tooling

- **CLI**: `ldh` (built from `cli/`) wraps every operation above and is the authoritative reference for request shapes. Commands group by verb:

  - `get`, `post`, `put`, `patch`, `delete` — the bare HTTP methods. `post`/`put` take an optional `FILE` argument and read the RDF syntax from its extension; `-t/--content-type` is required on stdin. `get` also addresses the Memento roles with `--timemap`, `--version <sha>` and `--timegate [--datetime]`.
  - `create item|container` — `PUT`s a new document (`--parent`/`--container`, `--title`, `--slug`, `--primary-topic`).
  - `add view|construct|select|result-set-chart|file|generic-service|rdf-import|csv-import|object-block|xhtml-block` — `POST`s an append onto an existing document.
  - `remove block` — names the single request it makes.
  - `import rdf|csv` — the workflows composing `add construct`, `add file` and `add {rdf,csv}-import`.
  - `packages list|add|remove` — the application's package imports, written through `PATCH /settings`. `list` reads the registry catalog through the Linked Data proxy and marks the imported ones.
  - `push` — replays a directory into the document tree it maps to: RDF files are `PUT` to the document their path spells, `root.ttl` is the target document, other files are uploaded, subdirectories recurse. Honours a gitignore-style `.ldhignore`, prints its plan with `--dry-run`, writes one URL per line and stops at the first failed request.
  - `admin {create,add,clear,import,make-public}` — the same verbs scoped to the admin application (ontologies, classes, constructors, constraints, restrictions, ACL groups and authorizations).

  Authentication is the agent's WebID credential given to `-c/--cert`, as either a PKCS12 keystore or a PEM file holding the certificate and its PKCS#8 private key, told apart by content (`-p/--cert-password`, or `LDH_CERT_FILE`/`LDH_CERT_PASSWORD`; `LDH_BASE` and `LDH_PROXY` for `-b` and `--proxy`). Commands that create or append print the document's URL as the only line on stdout, so they compose in pipelines; exit codes are `0` success, `1` HTTP or runtime failure, `2` usage error. Shell completion: `source <(ldh generate-completion)`.

  Certificate and WebID tooling (`webid-keygen.sh`, `server-cert-gen.sh`) remains in `bin/`; the `bin/` HTTP API scripts `ldh` replaces are deprecated.

- **Programmatic / MCP**: [Web-Algebra](https://github.com/AtomGraph/Web-Algebra) is the recommended path for agent-composed workflows — a JSON DSL and MCP server whose operations (create container/item, add view/chart, generate portal, …) compose multi-step LDH writes atomically under WebID auth.

## Standards

WebID-TLS · SPARQL 1.1 Query · SPARQL 1.1 Update (over `PATCH`) · Graph Store Protocol · HTTP conditional requests (RFC 9110) · Web Linking (RFC 8288) · Memento (RFC 7089) · PROV-O · SHACL · SPIN · OWL · RDF (Turtle/RDF-XML/JSON-LD/N-Triples). LDH composes existing W3C/IETF standards; it does not define new wire protocols.
