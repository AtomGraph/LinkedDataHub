## [3.2.18] - 2022-10-19
### Added
- SHACL node shape and property shape creation in the admin app
- Basic support for instance construction from SHACL node shapes

### Changed
- Improved validation of "Add data" and inline content editing forms
- SaxonJS upgraded to v2.5. Client-side XSLT code updated to take advantage of the latest bugfixes.

## [3.2.17] - 2022-09-28
### Added
- Basic support for [HTTP range requests](https://developer.mozilla.org/en-US/docs/Web/HTTP/Range_requests) when serving uploded files (`uploads/{sha1sum}`)

### Changed
- Fixed infinite XSLT loop in the WebID signup flow
- Container UI code only hydrates server-side HTML elements, does not create them if they don't exist
- Parameterized CSS classes in `bs2:RowContent` mode
- `ProxyResourceBase` guards against queries to the backend SPARQL service by requiring that agent is authorized

## [3.2.15] - 2022-09-26
### Changed
- Fixed order by dropdown population for container content
- Fixed and optimized container sorting

### Removed
- Usage of group-sort-triples.xsl because Jena RDF/XML writer takes care of grouping triples and they're sorted during container rendering anyway

## [3.2.14] - 2022-09-21
### Added
- WKT geometry support in map layout mode

## [3.2.13] - 2022-09-16
### Changed
- Fixed query builder behind faceted search to generate a correct query that loads facet values

## [3.2.12] - 2022-09-13
### Added
- Moved RDFXML2DataTable.xsl and SPARQLXMLResults2DataTable.xsl converters from Web-Client

### Changed
- Refactored RDFXML2DataTable.xsl and SPARQLXMLResults2DataTable.xsl using XSLT 3.0 JSON/XML instructions and fixed support for repeating columns

## [3.2.11] - 2022-09-10
### Changed
- Fixed the `[Actions]` button in edit mode to update the constructor list when new types are added to the edited instance
- The ontology import query now adds explicit `rdfs:isDefinedBy` triples that connect classes to the ontology

## [3.2.10] - 2022-09-09
### Changed
- Web-Client upgrade fixes the RDF/XML to DataTable converter

## [3.2.9] - 2022-09-08
### Added
- Map view is fit to the extent of loaded features

### Changed
- Fixed blank node resources rendered as empty elements in `bs2:Row` mode

## [3.2.8] - 2022-09-07
### Changed
- Fixed calculation of center coordinates correctly for all map usages

## [3.2.7] - 2022-09-06
### Changed
- Google Maps and SPARQLMap dependencies replaced with OpenLayers 7.0. All functionality ported except bounding box-based feature loader.

## [3.2.6] - 2022-08-12
### Changed
- Fixed instance creation with multiple `rdf:type`s

## [3.2.5] - 2022-08-11
### Added
- "Actions" button in edit mode allows adding and editing constructors of ontology classes without switching to the admin app
- `xsd:dateTime` literals are rendered as `datetime-local` inputs in edit mode

### Changed
- Fixed `refresh_token` cache to store a token per client ID
- Improved edit mode support for instances that have multiple `rdf:type` properties

### Removed
- Usages of `OntModelReadOnly` which broke RDF/XML writing in Jena: https://github.com/apache/jena/issues/1450

## [3.2.3] - 2022-06-30
### Added
- The persistent storage of `refresh_token`s allows long-lived sessions when authenticated with Google login

### Changed
- Fixed the back button (the history states were being mismanaged)

## [3.2.0] - 2022-06-22
### Added
- Inline creation and editing of container and XHTML content in content layout mode
- ACL access modes sent as `Link` response headers and accessible in the client-side XSLT stylesheets using the `acl:mode` function
- Results of queries that use `forClass` type after a new instance was created are banned from Varnish cache
- `endpoint` URL param can be used to override the SPARQL endpoint that the fallback `DESCRIBE` query gets executed against
- XML literals in SPARQL updates get canonicalized before reaching the SPARQL endpoint

### Changed
- Content model uses `rdf:Seq` and `rdf:_1`, `rdf:_2` ... properties instead of `rdf:List` and `rdf:first`/`rdf:rest`
- SPARQL updates submitted to the Graph Store via the `PATCH` method now have to use the default graph context, the `GRAPH` keyword is disallowed
- Fixed caching of delegated WebID agents, eliminating an unnecessary request with each authentication
- Multiple `Link` headers combined into a single one with concatenated values

## [3.1.9] - 2022-05-23
### Added
- `--fragment` parameter to CLI scripts that can be used to specify the fragment ID of the resource paired with the document (defaults to UUID)
- `ENABLE_LINKED_DATA_PROXY` env parameter that allows disabling the Linked Data proxy/browser (enabled by default)

### Changed
- Fixed double `On-Behalf-Of` header value when both WebID and OIDC agent contexts were delegated
- Fixed Linked Data proxy fallback to a local `DESCRIBE` query when the external URL does not dereference
- Fixed IP address check in the setup script
- Jena upgraded to 4.5.0
- Fuseki Docker image upgraded to 4.5.0
- Saxon-JS upgraded to 2.4
- `key()` lookups enabled in client-side XSLT as HTML page mutations do not break indexes anymore (fixed in [5036](https://saxonica.plan.io/issues/5036))


## [3.1.6] - 2022-05-10
### Added
- Spanish UI localization
- Reconciliation of OIDC accounts with existing agents by email address
- Document tree widget
- New `/clear` endpoint which is used to clear ontologies from memory
- Second nginx port which has WebID client certificate authentication always enabled
- `--proxy` parameter to CLI scripts

### Changed
- Variables in SPARQL query and update strings whose values are injected now start with `$` instead of `?`, for example `$this`
- CSV and RDF imports write data directly to the backend Graph Store
- Only namespace, signup, OAuth2 login, WebID profiles and public keys can be public in admin apps, nothing else (hardcoded in the admin authorization query)
- When graph URI not explicitly specified, the Graph Store always returns `201 Created` (even if the graph existed)
- Fuseki image upgraded to 4.3.2


## [3.0.11] - 2022-03-16
### Added
- Interactivity to the graph SVG layout
- Notifications to the requesting agent when its access request is granted (requires email server)
- JSON-LD export option for documents
- `append-content` CLI script that appends content resources to document
- `create-file` CLI script automatically recognizes the MIME type of the file being uploaded
- Linked Data browser functionality in graph layout mode
- Javadoc comments

### Changed
- The setup script requirements relaxed to make it easier to run on MacOS
- Fixed CSV imports
- Linked Data browser now supports relative URIs
- Upgraded Java from 11 to 17
- A built-in HTTP API constraint does not allow `PUT` on documents without the document description in request body
- A built-in HTTP API constraint does not allow to `DELETE` the root document
- A built-in HTTP API constraint does not allow to `DELETE` or `PUT` the the app owner's and secretary's WebID documents
- Shell script interpreter line

### Removed
- Dydra-specific code


## [3.0.3] - 2022-02-16
### Added
- Ability to copy (fork) RDF data into the local dataspace
- Block-based content layout (`ldh:ContentList` mode) and editor
- Login with Google (OpenID Connect)
- Ability to load JSON-LD data from `<script>` elements in HTML
- Namespace endpoint, which is an in-memory SPARQL endpoint over the app's ontology

### Changed
- The HTTP CRUD API is now Graph Store Protocol, not Linked Data Templates
- HTML documents are hydrated HTML fragments over AJAX
- XSLT stylesheets now load constraints and constructors using SPARQL over the namespace endpoint
- The URIs of ontology terms are not relative to the app's base URI anymore
- Additional assertions added to external ontology terms instead of subclassing them
- Every UI state generates a distinct URL which is loaded consistently on both server- and client-side
- Upgraded Jena to 4.3.2
- Upgraded Saxon-JS to 2.3
- Upgraded Fuseki, Varnish and nginx Docker images

### Removed
- Linked Data Templates support (still supported by Processor)


## [2.2.9] - 2021-04-22
### Added
- HTTP smoke tests for SPARQL endpoint and Graph Store
- HTTP test for RDF import without mapping query
- `add-data.sh` CLI script which POSTs RDF data to URL
- `ExceptionMapper` constructors with injection in order to align with Processor
- An option to override request URI using the `?uri=` URL param, implemented in `ApplicationFilter`
- `Dispatcher` as the new "entrypoint" JAX-RS resource which routes between `ResourceBase` (if app is not empty) and `ProxyResourceBase` (if app is empty)
- Missing XML namespace definitions to client-side XSLT stylesheets
- `$output-json-ld` parameter in `xhtml:Script` template which outputs the RDF document as JSON-LD in the `<script>` element

### Changed
- `select-labelled` query in the end-user dataset to include a default graph pattern
- `spin:query` property is now optional for `apl:RDFImport`
- Entrypoint script logic to load agent metadata only when `$LOAD_DATASETS` is true
- Injecting `Optional<Application>`, `Optional<Service>`, `Optional<Ontology>` instead of `Application`, `Service`, `Ontology`
- Using `javax.inject.Provider<>` for injection into providers that are not in the request scope
- If no application matches request URI, `NotFoundException` is not thrown anymore -- `Optional.empty()` is used as application instead
- Auth filters skipped if the matched application is not an instance of `lapp:EndUserApplication` or `lapp:AdminApplication`
- Simplified `ResourceBase::describe` by removing the `?uri=` indirection logic

### Removed
- Proxy injections from injection factory binders


## [2.1.55] - 2021-03-26
### Added
- varnish-admin service that proxy-caches the fuseki-admin triplestore
- `purge_backend_cache` function to the HTTP test runner script run.sh
- `purge_backend_cache` calls to clear proxy caches before each HTTP script
- `BackendInvalidationFilter` response filter with backend proxy cache invalidation heuristics
- Basic environment variable documentation to README

### Changed
- Upgraded Processor and Web-Client to the latest versions
- Upgraded Saxon-JS to 2.1
- End-user and admin Services passed to import `Executor` instead of `DatasetAccessor`
- Defined HTTP method -> ACL mode mapping as the `AuthorizationFilter.ACCESS_MODES` map

### Removed
- Unused Docker mounts from linkeddatahub service
- `ban()` calls from `ResourceBase` -- now handled by the `BackendInvalidationFilter`

## [2.1.49] - 2021-03-19
### Added
- `apl:baseUri` as a static XSLT stylesheet param

### Changed
- `bs2:PropertyControl` XSLT mode can handle multiple RDF types on a resource
- Replaced error alerts with inline HTML warning blocks
- Refactored `bs2:SignUp` template to make it more extensible

### Removed
- `ORDER BY` in `apl:ResultCounts` mode in client.xsl


## [2.1.28] - 2021-03-06
### Added
- `$request_base` parameter support in scripts allows to use a base URI for HTTP requests which is different from the RDF dataset base URI. Useful when multiple LDH instances on different domains or port numbers are backed by the same dataset. E.g. one with WebID-TLS auth enabled and the other without.
- Dydra-specific `QuadStoreClient` and `GraphStoreClient` with support for [asynchonous GSP requests](https://api.dydra.com/graphstore/asynchronous.html)

### Changed
- Ontology classes that used to be in the `ns:` namespace (`${base}ns#`) moved to `nsds:` (`${base}ns/domain/system#`)
- Ontology classes that used to be in the `def:` namespace (`${base}def#`) moved to `nsdd:` (`${base}ns/domain/default#`)
- `python` usages replaced with `python2` in CLI scripts
- Mounting only `ssl/owner/public.pem` instead of the whole `ssl/owner` folder which includes the private key

### Removed
- Expensive join with the provenance graph from the `laclt:ConstructAgentItem` query. As a result, `dct:created` value is not included in agent's description.
- Unnecessary methods from the `Import` Java interface. Passing arguments directly to `ImportListener` instead