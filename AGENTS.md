# LinkedDataHub — Agent Guide

This document describes how an autonomous agent (or any HTTP/LLM client) drives a **running LinkedDataHub (LDH) instance's HTTP API**. It is the API-usage counterpart to `CLAUDE.md` (which is for contributing to the codebase).

LinkedDataHub is a data-driven Knowledge Graph platform. Everything — documents, applications, access control, the UI — is RDF, managed over a small, uniform HTTP API and standard protocols. There is no bespoke REST surface to learn: you work with RDF documents and SPARQL.

## Data model

- The content is a **hierarchy of documents** (containers and items). A container holds child documents; items are leaves.
- **Every document URL is a named graph.** Reading a document returns the RDF in that graph; writing changes it. This is the [SPARQL 1.1 Graph Store Protocol](https://www.w3.org/TR/sparql11-http-rdf-update/).
- Identifiers are opaque URLs. Do not parse structure out of them; follow links (hypermedia) instead.

## Authentication

- **WebID-TLS** (client certificate) is the primary mechanism for programmatic agents. Every request carries the cert; the certificate's WebID is the agent identity. With `curl`: `-E cert.pem:password` (`-k` in dev with self-signed certs).
- **OAuth2 (Google)** and **OpenID Connect (ORCID)** are available for human logins.
- **Delegation**: an authorized secretary agent can act for a principal via the `On-Behalf-Of: <principal-WebID>` request header.
- Authorization is WebID-based ACLs (`acl:Read`/`Append`/`Write`/`Control`), enforced per document. A response's `Link` headers advertise the modes the current agent holds on that resource.

## Reading data

`GET` a document URL with content negotiation:

- `Accept: text/turtle` · `application/rdf+xml` · `application/ld+json` · `application/n-triples` (any RDF serialization Jena supports) → the document's RDF.
- `Accept: text/html` → the application shell (Saxon-JS then renders client-side). Request RDF, not HTML, when you want data.

## Writing data (the discipline)

Writes go through the **document URLs**, never through the SPARQL endpoint (which is read-only):

| Intent | Method | Body | Notes |
|--------|--------|------|-------|
| Create a child in a container | `POST` container URL | RDF (e.g. `Content-Type: text/turtle`) | Server mints the child URL and returns it in `Location` |
| Create or replace a document at a known URL | `PUT` document URL | RDF | Replaces the whole named graph |
| Update a document in place | `PATCH` document URL | `Content-Type: application/sparql-update` | A SPARQL Update (`INSERT`/`DELETE`) applied to that named graph |
| Delete a document | `DELETE` document URL | — | Removes the named graph |

Relative URIs in a request body resolve against the target URL. See `bin/post.sh`, `bin/put.sh`, `bin/patch.sh`, `bin/delete.sh` for exact, working invocations.

## Querying (read-only)

The dataspace exposes a **read-only SPARQL 1.1 Query** endpoint (advertised via the Service Description `sd:endpoint`; conventionally `/sparql`). `GET`/`POST` a `SELECT`/`CONSTRUCT`/`DESCRIBE`/`ASK`; results are content-negotiated. The endpoint does **not** accept SPARQL Update — mutate via `PATCH` on document URLs (above).

Write portable, standard SPARQL: use explicit `GRAPH` patterns, no engine-specific extensions.

## Content & document model

- Documents carry ordered **content blocks**. Only `ldh:Object` (an embedded RDF resource view) and `ldh:XHTML` (rich text) are permitted as block values; anything else must be wrapped in an `ldh:Object`.
- **Views** (`ldh:View`) are SPARQL-driven blocks (`SELECT`/`CONSTRUCT`/`DESCRIBE`) rendered as lists, tables, grids, charts, maps, or a graph.
- Forms and validation are ontology-driven (SPIN constructors + SHACL shapes), so instance data is shaped by the app's ontology rather than hardcoded schemas.

## Dataspaces

A single instance hosts multiple **dataspaces**, each a subdomain (origin). Each dataspace pairs an end-user app (`<subdomain>`) with an admin app at the **`admin.` prefix** (`admin.<subdomain>`) — never an `/admin` path. Admin apps manage ontologies, ACLs, and app settings.

## Tooling

- **CLI**: the `bin/` scripts wrap every operation above (`get.sh`, `post.sh`, `put.sh`, `patch.sh`, `delete.sh`, `create-container.sh`, `create-item.sh`, `add-view.sh`, `add-select.sh`, `add-construct.sh`, `add-result-set-chart.sh`, `add-file.sh`, `webid-keygen.sh`). They are the authoritative reference for request shapes.
- **Programmatic / MCP**: [Web-Algebra](https://github.com/AtomGraph/Web-Algebra) is the recommended path for agent-composed workflows — a JSON DSL and MCP server whose operations (create container/item, add view/chart, generate portal, …) compose multi-step LDH writes atomically under WebID auth.

## Standards

WebID-TLS · SPARQL 1.1 Query & Update · Graph Store Protocol · Linked Data Templates · SHACL · SPIN · RDF (Turtle/RDF-XML/JSON-LD/N-Triples). LDH composes existing W3C/IETF standards; it does not define new wire protocols.
