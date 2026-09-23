## [6.0.0]
Bootstrap 2 is gone, and with it the class vocabulary and the `bs2:` template modes application stylesheets were written against. An override of a `bs2:` mode still compiles and never fires, and the Bootstrap classes are backed by no stylesheet, so the page renders unstyled with no diagnostic — hence the major version.

### Migration
- Legacy Bootstrap buttons (`btn`, `btn-primary`, `btn-large`, …) become the `ac-btn` intent/appearance/size vocabulary — `ac-btn in-primary ap-solid sz-md`
- `$ac:langs` and `$ac:lang` stylesheet parameters become the `ac:langs()` and `ac:langs()[1]` functions; an `xsl:with-param` left behind is silently ignored
- `pull-left` and `pull-right` have no replacement — the design system lays out with flex and grid
- Overrides depending on `bootstrap.js`, jQuery, WYMEditor or the sprite icons need rewriting: IXSL templates drive dropdowns and modals, the `msi` font draws icons, the RDFa editor edits `rdf:XMLLiteral`
- Stylesheets extending the removed vocabulary can be diffed against `ldh.css`, the one app layer LDH loads over the vendored design kits
- The platform stylesheet is `xsl/layout.xsl`; an `xsl:import` of `xsl/bootstrap/2.3.2/layout.xsl` fails to compile
- Every `bs2:` mode takes its design-system component name: `bs2:Row` becomes `ldh:BlockRow`, `bs2:Header` `ac:BlockHeader`, `bs2:PropertyList` `ac:PropertyEditor`, `bs2:Form` `ac:ResourceForm`, `bs2:NavBar` `ac:Header`, `bs2:Lookup` `ldh:Combobox`, `ac:ModeList` `ac:ModeSwitcher`, `ldh:LeftSidebar` `ldh:DataspaceDrawer`
- `ldt:base()` becomes `lapp:base()` and the `$ldt:base` parameter goes; the Java `LDT` vocabulary, the `ldt#ontology` `Link` relation and the `ldt:` terms in `config/*.trig` are untouched
- One `fuseki` service replaces `fuseki-admin` and `fuseki-end-user`, holding an end-user and an admin TDB2 dataset per dataspace, declared in `config/fuseki/config.ttl` and persisted under `fuseki/<dataset>/`
- Datasets are named after the dataspace origin with the deployment host dropped and the role appended: `end-user`, `admin`, `northwind-traders.demo.end-user`, …
- An existing deployment moves its two TDB2 directories under the new dataset names, points every `ldt:service` in `config/system.trig` at `http://fuseki:3030/<dataset>/` and merges the two stores' heap and `mem_limit`; `varnish-admin` and `varnish-end-user` stay
- Client-side package composition needs the new `sef-compiler` service: a deployment with its own compose file adds it, the platform's `depends_on` on it and the `./sef` bind mount at `/var/www/linkeddatahub/sef`
- `SEF_ROOT` and `SEF_COMPILER` are optional; without them packages compose server-side only, as in 5.10.0
- `CLIENT_STYLESHEET` names the client stylesheet the SEF is composed from (default: the platform's `client.xsl`); a deployment bootstrapping its own sets it to that stylesheet's webapp path, which must import the platform's `client.xsl` directly, and its layout prefers `ldh:client-stylesheet()` over its own SEF
- A package stylesheet is composed right after `hooks.xsl`: it can specialise an open mode (`ldh:RowHook`, the tree node, the leaves in `imports/values.xsl`) and no longer replaces a sealed mode, a typed rule or a global
- The ACL query fails closed on a typeless resource (see Security), so a non-owner request for a URL that does not exist is answered 403 rather than 404
- The `oauth2-login` and `oauth2-authorize` grants move from the admin store to the end-user app's `namespace-ontology.trig.template` as `acl:accessTo` on the login and callback URLs; an existing deployment re-seeds or migrates them
- `ldh:container` leaves the ontology, the `ldh:ViewConstructor` form and the view query: a view's Create button determines the container from the view's own solutions

### Added
- Design system port: the app shell, content blocks, action bar, breadcrumbs, mode lists, type badges, property lists, pager, modals and forms all render the design system's class vocabulary
- Vendored design system stylesheets and typefaces, with latin-ext subsets so Latin Extended-A no longer falls back mid-word
- A long-form typography layer binds headings, `code`/`samp`/`kbd`, `pre`, `dl`, `blockquote`, `hr` and tables to the design system on the element itself, so `rdf:XMLLiteral` content is dressed everywhere
- `ldh.css` is the one app layer loaded after the vendored design kits, replacing the Web-Client Bootstrap stylesheet link
- `ac:langs()` returns the reader's accepted languages as deduped primary subtags with an `en` floor — from the writer-supplied parameter on the server, from `navigator.languages` in the browser
- `ac:lang-rank()` ranks a value's language against that list, so property values sort by the reader's preference
- `Content-Language` on HTML responses, negotiated against the languages the UI translation bundle ships
- `Vary: Accept-Language` and language-sensitive entity tags on language-negotiated representations, so a shared cache cannot serve one reader's rendering to another
- Every rendered literal declares its own language: lang-tagged values carry their tag, untagged values carry `lang=""`, typed non-string values inherit
- Predicate labels, object links and table cells declare the language their label was chosen in
- `http-tests/language/`: six scripts covering `Content-Language`, `Vary`, per-language entity tags, `<html lang>` agreement and per-literal marking
- `ResponseHeadersFilterTest` covers the response filter's hypermedia (snapshot read-only modes, proxy suppression, RFC 7089 relations, `Link` folding) and the language labelling
- `BundleLanguagesTest` covers deriving the supported languages from the translation bundle and the RFC 4647 matching behind it
- Spanish translations completed
- View table columns are sortable, keyed off each column's XSD datatype through `ldh:sort-key()`
- Facet toolbar, three-zone pager, chart controls grid, design-system list and grid modes
- Block drag-and-drop is payload-typed with an app MIME marker, with a single moving drop marker
- Copy-URI button reaches every block type through a context-free `ldh:CopyUriButton` mode
- Empty blocks and empty chart result sets say so through the design system's block-state component
- `ldh:date-time()`, `ldh:datatype-family()`, `ldh:css-token()` and `ldh:view-cache()` replace logic written out at every call site
- Package ontologies are declared as `owl:imports` instead of grafted, with an imports characterization test
- `ldh packages list`, `ldh packages add` and `ldh packages remove`: the catalog read through the Linked Data proxy with imported packages marked, the `ldh:import` declaration written through `PATCH /settings`
- `ldh get` reaches a versioned document's Memento roles through `--timemap`, `--version <sha>` and `--timegate` (with `--datetime` in RFC 1123 or ISO 8601, printing the negotiated version's URI)
- `ldh put` and `ldh post` take an optional `FILE` argument and recognize the RDF syntax from its extension; `-t/--content-type` stays required on stdin
- Every dataspace serves its own `/sitemap.xml`, generated at startup from the public read rules of its own admin service
- `/robots.txt` per dataspace: one with a sitemap names it and allows crawling, one without (an admin dataspace, or nothing public) disallows everything
- A `RewriteValve` and `WEB-INF/rewrite.config` answer both paths from the file generated for the requested host, since a servlet mapping cannot dispatch on `Host`
- `http-tests/dataspaces/sitemap.sh` pins both paths answering per origin; the cross-dataspace assertion cannot run on that stack yet and the script says so
- `ldh push` replays a directory into the document tree it maps to — the apps' `update-folder.sh` as a CLI command: RDF files are `PUT` to the document their path spells, `root.ttl` is the target document, other files are uploaded, subdirectories recurse
- `ldh push` honours a gitignore-style `.ldhignore`, prints its plan with `--dry-run`, writes one URL per line to stdout and stops at the first failed request; `http-tests/push/` covers the mapping, skips, upload and convergence
- `ldh create item` and `ldh create container` take `--primary-topic`, resolved against the created document (`'#this'` for a fragment, an absolute URI for a resource described elsewhere)
- The page renders in the colour scheme the reader's browser asks for: `color-scheme: light dark`, differing tokens written once as `light-dark()`, a `<meta name="color-scheme">` against the white flash, `data-theme` only as a forcing override
- Chart tokens are registered with `@property` so `getComputedStyle` resolves them per scheme; CodeMirror, YASQE and the RDFa editor chrome take the tokens; the map stays light
- A responsive axis: the shell queries `@media` at 768 and 1024, content components query `@container` at 520; the action bar wraps into two tiers below 640 and the page stops overflowing at phone width
- Block corner affordances join the flow where the device cannot hover
- A document's markup asserts the graph the same URL serves: value cells carry `@content` where display and lexical form differ, `ldh:DocumentMetadata` carries the document's own statements as `link`/`meta`, an XHTML block says it is `rdf:value`, and `@about` on the root pins the default subject
- `http-tests/rdfa/` pins the RDFa round trip
- Package stylesheets reach the client: a wrapper importing `client.xsl` and the imported packages is compiled by `sef-compiler` and published under `/static/xsl/sef/<key>`, announced to the page as a `Link` header; server-side composition is never withheld
- `ldh:ContentColumn`, a declared slot in `ldh:ContentBody` that the platform wraps in `.ldh-content-aside` when a package fills it
- A tree component (`xsl/tree.xsl` in the shared trunk, `client/tree.xsl` for the handlers) the document tree is one consumer of
- The taxonomy editor package fills the content column with a concept tree rooted at the scheme and opened down to the concept being read, a polyhierarchical concept under each of its parents
- The SKOS ontology gains views for `skos:hasTopConcept` and `skos:inScheme`, an orphan-concepts view, a missing-`inScheme` constraint and `rdf:langString` constructors for the label properties
- A document created from a view's Create button carries `foaf:primaryTopic` and a `dct:title` taken from the topic's label, so it renders with a body and pairs with its topic in list, table and grid rows
- Dropping an RDF file anywhere on a document imports it: a fixed overlay raised on the first file `dragenter` takes the drop, and a successful import lands in `ReadMode`
- An HTTP error document tells the reader what the status means: the block header becomes an inline alert with the sentence `ac:http-error-key()` picks; the error builders move to Web-Client
- Every failed client request reports where it was made: `ldh:promise-failure` takes the host element and a headline, `ldh:RenderFailure` picks the shape by host, and `alert()` remains only for a host that has left the page
- Keyboard operability: menus take the `role=menu` model with roving focus and Escape restoring the trigger, the RDFa annotation object switch answers the arrow keys, and the pager's previous and next become buttons
- Static `.css`, `.js` and `.txt` files are served with `charset=UTF-8` and `.map` with its JSON type; `http-tests/static/` keeps it so and gathers the CORS and gzip tests
- `ui-tests/`: a Playwright suite driving the running stack as owner and anonymous, with a console/page-error/alert/4xx collector, a hydration gate on Saxon-JS's listener binding, `ldh`-seeded fixtures and a stale-SEF preflight; its own CI workflow (`make ui-tests`)
- `http-tests/system/`: 19 auth-boundary scripts over `/settings`, `/sparql`, `/ns`, `/access` and `/clear` for the owner, an agent, a reader and an unauthenticated client
- `http-tests/sparql-protocol/query/GET-sparql-xhtml.sh` asks the endpoint for a rendered result set, the first test to reach the XSLT writer on that path
- An import test declares a stylesheet-only package described on the instance and requires the settings `PATCH` and the first render to answer within 30 s

### Changed
- `POST /clear` takes an optional `uri`: without one it empties the cache and reloads nothing, with one it also purges that URI's proxy caches and reassembles its closure before responding. `ldh admin clear ontology --ontology` is optional to match
- **BREAKING**: the bundled package `https://packages.linkeddatahub.com/skos/#this` becomes `https://packages.linkeddatahub.com/editor/taxonomy/#this` and its stylesheet `skos.xsl`; an `ldh:import` naming the old URI resolves to nothing and must be re-declared
- **BREAKING**: `ldh` commands regroup by verb, dropping the `bin/` mirror: `create`, `add` and `remove` groups (`ldh create item`, `ldh add view`, `ldh remove block`), `import` for the composite workflows, `admin` for the admin scope; `cli/README.md` maps every old name
- `<html lang>` is taken from the `Content-Language` the response carries, so header and document agree by construction
- The language a page reports is the first accepted language the UI bundle has, so asking for German no longer puts `lang="de"` on an English page
- Published language tags are the shortest the bundle justifies (`en`, not `en-US`)
- Supported UI languages are derived from `translations.rdf` rather than declared in `web.xml`
- Property lists and table cells order their values by the reader's language instead of hiding the ones that do not match
- Language negotiation moved out of `Application` into `LanguageNegotiator`
- Object metadata merges on the RDF term rather than the lexical form, so a tagged literal is no longer collapsed into an untagged twin
- Document responses pass the accepted languages into entity tag computation, so tags stop colliding across languages
- Legacy Bootstrap buttons move to the `ac-btn` intent/appearance/size vocabulary
- Block link columns route through the `ldh-drawer`; backlinks and copy-URI split into two placements chosen by what a click does
- Charts draw with resolved design tokens; the HTML Table chart is skinned in CSS and fills the block width
- Client-side HTTP moves to promise chains, retiring the legacy `ixsl:schedule-action` `http-request` form
- The busy cursor becomes a promise concern rather than 53 copies of the same `ixsl:set-style`
- Dropdown dismissal moves into IXSL, and the `DOMContentLoaded` block retires into an `ldh:CloseDropdown` mode
- Subject-control change handlers move from JavaScript into `ixsl:onchange` templates
- `ac:uuid()` generates through the platform, and the seven call sites that went around it stop doing so
- One navigation leaves one history entry
- CSR failures render through the design system's block states instead of `div.alert.alert-block`
- The RDFa editor's XMLLiteral canonicalization runs as a single `cm:canonical` pass in `ldh:FormPreSubmit`
- RDFa editor template names and modes move into their module namespaces
- Document-level map and graph modes fill the space between action bar and footer
- The map marker info window is the card itself, fitted into the map viewport and panning the least it can to reveal itself
- Editing forms already open on the page reconcile with the constructor after a constructor save
- The edit pencil on a resource description appears only under `acl:Write`
- `http-tests` assertions read captured responses from a here-string instead of piping `curl` into `grep -q`
- A view's parallax row becomes a closed-by-default `<details>` disclosure, and the toolbar states what the query shows (filters, sort, count, mode)
- A view's Create button moves out of the view toolbar into the block header beside Copy
- The query block runs its stored query on render, results first, with the editor folded behind a toggle in the block head and Run as the one primary action
- The SPARQL editor fills the code field on both axes, with a fifteen-line floor so an empty query field opens at a height a query gets written in
- The add-data items (RDF import, CSV import, …) move into the Actions menu, offered on the Root document and on containers where `acl:Append` applies
- XHTML prose blocks render without a header: the drag grip is a hover-surfaced strip on the card's edge, and links, Copy and Edit a corner cluster
- An `ldh:Object` block is a chrome-less carrier with a slot bar over the embedded card, so a block has one header
- Instance timestamps leave the block chrome and render as ordinary statements
- A collection of resources renders as `ul`/`li` and a read-mode property list as `dl`/`dt`/`dd`, the markup the RDFa is carried on
- The design system's DataTable gets table layout back (`colgroup` instead of grid tracks, no restated `role` attributes), so the SPARQL results table stops being a second table component
- Paging or re-sorting a view no longer collapses the block: the pager lives in its own host and the rows stay standing, dimmed, while the query runs
- Class state on the client is one vocabulary — `contains-token()` to read, `ldh:set-token()` to write — and the client XSL uses `ixsl:` instructions where it called DOM methods
- The floating Edit pill retires; every block carries the edit pencil in its own control cluster, and click-anywhere-to-edit lands on that button
- The object-position lookups, `sh.xsl` and `RDFPostMediaTypeInterceptor` move down to Web-Client, and the SSR and CSR import chains align so a generic resolves identically in both
- The combobox cluster takes design-system names (`ldh:Combobox`, `ldh:ComboboxChip`, `ldh:ComboboxItem`, …), taking the last `graphity.org` namespace out of the codebase
- The last hard-coded English leaves the client: the RDFa editor's chrome, the media-type option groups, the 3D graph's panels and the block drag and delete strings read from `translations.rdf`
- The vendored RDFa editor is a byte-identical copy of `RDFa-Editor/src` again; LDH's integration is four parameters and one function
- The RDFa annotation dialog pins the statement's subject and predicate and tabs the rest: an object tab with a Text or Link switch and a subject tab for the `@about` and `@typeof` overrides
- Constraint violations decorate the affected fields with the inline message instead of stacking generic alerts
- An XHTML block clicked out of unedited restores its snapshot without a save, so no version is minted for a no-op
- A press outside a whole-resource edit form dismisses an untouched form and leaves an edited one to Save or Cancel; a press between blocks moves the caret instead of exiting
- A grid card no longer offers an edit pin: a card is one projection of a result row, and the whole resource is one hop away
- A 3D graph node's link navigates in the page, through the Linked Data proxy for an external URI, instead of opening a browser tab
- A video embed fills a 16:9 well sized by CSS instead of a fixed 560×315 box
- The document tree's children query is a bounded `CONSTRUCT` of what a node renders, paged by `ldh:tree-page-size` (default 1000) and always including the child leading to the document being opened
- The shell carries its landmark roles (`banner`, `main`, `contentinfo`), the tab strip and breadcrumbs are labelled navigations, and the address bar is a `role=search` with a `type=url` input that works without CSR
- Constructor instantiation is one shared pipeline behind a dual `ldh:parse-query` (SPARQL.js in the browser, a `ParseQuery` Jena extension on the server), so the sign-up form appears on a direct page load
- `ldh:is-local()`, `ldh:service-endpoint()`, `lapp:application-description()` and one shared `Link` header parser replace the copies at every call site; six SPARQL queries duplicated between `layout.xsl` and `client.xsl` are single-sourced
- `sh:name` and `sh:description` labelling moves into LDH, where it outranks `dc:title` and `foaf:name`
- Jersey components are pinned to the version Core declares
- The seed authorizations drop the retired `/add` and `/generate` endpoints
- Web-Client dependency bumped to 6.0.0, twirl to 2.0.1

### Removed
- Bootstrap 2: the framework stylesheets, `bootstrap.js`, jQuery, WYMEditor, the sprite icon layer and the `pull-left`/`pull-right` tokens
- The Bootstrap 2 class vocabulary that no stylesheet backed
- `$ac:langs` and `$ac:lang` parameters, replaced by `ac:langs()` and `ac:langs()[1]` at 36 call sites
- `ldt:lang`, which nothing declared, read or wrote
- `DEBUG:` output from `http-tests`, with the diagnostic-only `gh api` and `curl` calls and the helper that fed them
- `$ldt:base`, `$ldt:ontology`, `$ac:httpHeaders`, `$ac:method`, `$Referer`, `$ac:googleMapsKey`, `$doc-types`, `$main-doc` and `$acl:Agent` — parameters read by nothing or never populated; the `ldt:` prefix leaves the LDH stylesheets
- `ldh-bridge.css`, merged into `ldh.css`, and the dead Bootstrap residue it carried
- `ldh:container` (see Migration) and the stored `ldh:SelectChildren` query, which the generated tree query replaces
- `ac:ConstructMode` from both ontologies, its Create label becoming a catalog entry, and the `graphity.org` typeahead namespace

### Fixed
- Clearing an ontology discards every cached graph and assembled closure, not just the keys derived from the URI it was given: a closure caches each URI it imports, so a vocabulary or package ontology kept answering from a document that had been edited or deleted until the container restarted
- The sitemap covers every dataspace rather than the root one, and an origin is served its own: one file per host, generated against that dataspace's own services
- The sitemap queries carry the service credentials, so a store that requires authentication no longer answers them 401
- Sitemap generation no longer joins the admin service through SPARQL `SERVICE`, which an isolated store refuses; the public read rules are passed as `VALUES`, and a failed generation is logged instead of stopping the platform
- The sitemap lists a document once, with its latest date, and only when a public rule of its own dataspace covers it
- `curl ... | grep -q` was a race under `pipefail`: `grep -q` closed the pipe on its first match and `curl` died with 141
- View sort's numeric keys yield an empty sequence rather than `NaN` for non-numeric values
- `DataTransfer.types` marshals to an XDM array under SaxonJS, so payload guards compare via `array:flatten`
- The content-body drag-and-drop guards spell the child step `./div`, since after `and` a bare `div` parses as the division operator
- Reading an `ixsl:call` result of two numbers as an XDM array hung the renderer with no diagnostic; it arrives as a sequence of doubles
- Nested cards no longer draw doubled borders, and `dl` column placement is corrected
- The DataTable converters recognise the derived numeric and dateTime types
- An alert an author writes inside an XHTML content block keeps its prose spacing
- The violation renderer fails on an absent form again, rather than falling back to the rejected rendering
- Concurrent writes to a versioned application silently lost commits: the commit chain was keyed by file path while GitHub locks on the branch head; commits to one branch now share a single chain
- A conflicting write is retried with a re-read blob SHA (`MAX_CONFLICT_RETRIES`) instead of being abandoned
- A rate-limited commit retried with an empty request body, since `JsonObjectBuilder` yields its object only once
- `release.sh` published to Maven Central before its `git checkout master`; the switches are proven possible first, and the trap prints recovery steps instead of deleting the tag
- `release.sh`'s clean check could not see `skip-worktree`/`assume-unchanged` files; they are warned about at startup and checked before publishing
- `release.sh` derived the release and snapshot commits positionally (`git log -2`); they are derived from an anchor taken before `release:prepare`
- A drop-down flips to whichever side of its trigger has room, on both axes, and caps its height to the room on that side
- The language tag renders as a pill wherever a value is laid out, not only inside a property list
- A view block derived from the ontology keeps its URI across reloads: the fragment is hashed from the host resource and the view instead of drawn from `ac:uuid()`
- A fragment scroll waits for the injected blocks to hydrate
- An injected view block's subject keeps the hash that makes it a fragment
- A `pre` in an `ldh:XHTML` block takes the recessed code surface the inline chip and error listing share
- The property-list grid keys on the wrapped `dt`/`dd` shape, leaving prose `dl`s to their own layout
- An error page renders without the action bar, which had nothing left to act on
- The context dataset's read/write race, a `ConcurrentModificationException` or a torn model on a `PATCH /settings` concurrent with any request: writes are copy-on-write behind a volatile swap and the file is written atomically
- The expiring auth caches' check-then-get races, an intermittent login 500
- `EMailListener` no longer runs SMTP on the common pool
- `GraphVersioningService` no longer leaks one commit-chain entry per branch
- `XsltExecutableFilter` no longer compiles each stylesheet once per thread on a cold start
- A `PATCH /settings` adding an `ldh:import` returned 204 but the package ontology never joined the `/ns` closure; the rebuild re-reads the app from the current dataspace model
- Importing a package described on this instance answered 504 from a self-resolving loop; a local package's named graph is read from the store, and only foreign URIs are dereferenced
- A `DOCTYPE` in an application's `ac:stylesheet` silently disabled package composition; the server parses through the same entity-tolerant reader the client uses
- The `/access` endpoint under-reported class-based grants once the ACL query failed closed; it injects the resource's types the way `AuthorizationFilter` does
- Document creation by `PUT` authorizes against the parent container's types rather than the wildcard that used to let it through
- Asking the SPARQL endpoint for a document (`Accept: text/html`) answered 500 since the document tabs; the tab panel and body match a result set too, and the client's re-fetch keeps the query parameters
- The drawer tree fetched an unbounded `DESCRIBE` of every child of a container on every render, so large containers answered 502 — 343 KB now where 20.5 MB was
- A facet on a large container never returned: the label lookup's eight-alternative property path under `GRAPH ?labelGraph` scanned the store (24.9 s); binding the predicate with `VALUES` takes 0.055 s
- The x on a parallax step chip did nothing and raised an error
- A chart axis bound to a URI-valued variable printed escaped anchor markup; only the Table chart keeps the anchor
- Filtering a facet on a language-tagged value matched nothing, since the tag was dropped at every step of the chain
- Clearing a facet filter left "No results." over the rows in hand, and the empty state's Clear filters button never rendered
- A chart or view created from a query block replaced the query block; it lands beside it now, and the Create buttons require the Properties layout
- A chart pane's default series excluded nothing, so any plotted type raised "All series on a given axis must be of the same data type"; the default is the number columns minus the category
- An ontology-defined view (`ldh:view`, `ldh:inverseView`) rendered as a nested well that missed every block-body layout rule; it comes out of the same emitter as an authored view
- Reordering a block on a document with an embedded block `PATCH`ed the embedded document; the target is the dragged block's document, not the one under the pointer
- A paged view's grid mode escaped its block and painted over the footer
- The class-instances, Geo and Latest dialogs left a 60px band under the pager
- A dialog's form actions scrolled away with the fields; the bar sticks to the scrollport's bottom
- The first save of prose nobody had edited rewrote the `rdf:XMLLiteral`, adding an `xmlns` to its first child; the wrapper is built as a node
- An XHTML literal longer than the JS stack allows (about 6–7K characters) took the client transform down with "too much recursion"; `ldh:bounded-key()` folds long keys into prefix, length and hash
- The pencil on a committed object value emptied the row when clicked by accident; the chip is stashed and Escape or an empty focusout restores it
- `acl:mode()` threw inside a match pattern, which Saxon-JS discards, so click-to-edit and the Write-gated drag rules were dead until the first document response
- A document describing two resources beside a content aside put the second resource in the gutter; the aside spans every row
- An image in document content scales to its column instead of its pixel size, while editing too
- A `PATCH` 422 echoed the entire would-be document graph rather than the violating resources, crashing the client on YASQE init; the response carries the violation roots' bounded descriptions
- The shipped Sign up document's seed content rendered an unstyled lead paragraph and a notice with no background
- The view mode menu inside an embedded view was clipped to one item by the nested block's `overflow: hidden`
- Opening any document on an instance nobody had made public raised a modal alert with raw Saxon text: the tree descent walked the loading placeholder as a child
- Navigation that cannot work degrades quietly: a drawer section whose query is refused is removed, breadcrumbs stop at the ancestor that could not be read, and Geo, Latest and search defer their query to the click
- A block's affordances gate on the pane's access modes rather than the window's, which answered for whichever dataspace tab was active

### Security
- A SPARQL `SERVICE` clause in a query to `/sparql` could read the admin store from inside the stack; the triplestores' outbound requests go through an `egress` Squid proxy that refuses loopback, private and link-local destinations
- Deployments with their own compose files need the `egress` service and the stores' `JAVA_TOOL_OPTIONS`, including the empty `http.nonProxyHosts`
- A `SERVICE` clause in a PATCH update or an import mapping runs in the platform's JVM; it is routed through the egress proxy too (`EGRESS_PROXY`, default `egress:3128`), and with no proxy and `ALLOW_INTERNAL_URLS` unset, in-JVM `SERVICE` is disabled
- CSV/RDF imports validate the `ldh:file` source and `spin:query` URIs via `URLValidator` before fetching, closing an SSRF surface on the import path
- An unbound `$Type` in the ACL query was a wildcard, so a typeless resource (`/settings`, `/sparql`, a missing URL) matched every `acl:accessToClass` authorization; both ACL queries carry a default `VALUES ?Type { rdfs:Resource }`
- Net access after the fix: `/settings` owner-only, `/sparql` authenticated-only, `/ns` and `/access` public, OAuth login public

### Known limitations
- The in-place editor edits tab-group content but cannot create tab groups; that markup is authored via the HTTP API (e.g. `ldh put`) for now
- When a result set fits one page the view's total counts the related resources the `DESCRIBE` pulled in, so one row can read "Total results 2"
- While a composed SEF key is unpublished every render submits a build, so a persistently unreachable `sef-compiler` costs one attempt per request
- List row separators are gone until the kit rule targets the `li` rather than the row inside it

## [5.10.0] - 2026-08-30
### Added
- `ldh` command line interface (`cli/`): a standalone picocli/Jena port of the `bin/` HTTP API scripts — one command per script with the same option names, `bin/` subdirectories as nested subcommand groups, PKCS12 WebID keystore authentication, env-var defaults and a shaded executable jar
- Every release attaches an `ldh-<version>.tar.gz` archive of the CLI launcher and jar, stamped with the platform version, so using `ldh` needs a Java runtime rather than a source checkout and a Maven build
- `make cli` builds the CLI and prints the `PATH` export to run, and `make tests` depends on it — the suite builds its fixtures with `ldh` and used to abort telling you to go build it by hand
- `make cli-version` sets `cli/pom.xml` to the platform version, which `release.sh` now runs around both release bumps so the CLI shares the platform's version line instead of its own `1.0.0-SNAPSHOT`
- Restore a document to an earlier version from the history modal: the memento is read back and written to the live document, so the restore rolls forward as a new commit and the versions rolled past stay in the TimeMap; gated on `acl:Write`, hidden on the version being viewed, and confirmed first
- Version diffs in the history modal: From/To selection navigates to `?version=<to>&diff=<from>` and the diff renders on the document page — `diff-added`/`diff-removed`/`diff-changed` block borders, marked property values, a changed XHTML block stacking its old content above the new, and a color legend
- `diff` is display state read from the URL at render time and never sent to the server, so back/forward re-render it and a plain reload degrades to the `?version=` snapshot
- Memento TimeGate (`?timegate`): `Accept-Datetime` negotiation answers `302` with the closest Memento in `Location` — smallest absolute distance, ties towards the more recent, most recent when no datetime is asked for — carrying `Vary: accept-datetime`
- TimeMaps serialized as `application/link-format` (`TimeMapWriter`), the representation RFC 7089 requires, derived from the PROV description and scoped to the `?timemap` response so ordinary documents answer `406` for it
- `http-tests/versioning/` covers the RFC 7089 contract: datetime negotiation (`GET-timegate.sh`), the PROV description of the TimeMap, its link-format serialization and `406` scoping, `rel=original` on Mementos but not the Original Resource, and a zero-padded RFC 1123 `Memento-Datetime`
- CLI unit tests for `HttpException.check`, the stdout contract the shell pipelines depend on, and stdin handling in `put`/`patch`, driven against a `com.sun.net.httpserver` stub — 41 tests to 63
- `http-tests/federation/` self-federation suite: one dataspace's client browses, queries and writes against another origin's dataspace through the Linked Data proxy — endpoint discovery from forwarded `Link` headers, the constructor SELECT against the remote `ns`, a graph-scoped SPARQL Update `PATCH` under the origin's `If-Match` precondition, and the unauthenticated negative

### Changed
- http-tests build their fixtures with `ldh` instead of the `bin/` HTTP API scripts — 260 invocations of 19 commands per CI run, making the suite the CLI's end-to-end coverage; only the arrange phase moves, every assertion stays a `curl` call
- **DEPRECATED**: the `bin/` HTTP API scripts, superseded by `ldh`; the certificate and WebID tooling (`webid-keygen.sh`, `webid-keygen-pem.sh`, `webid-uri.sh`, `webid-modulus.sh`, `server-cert-gen.sh`) talks to no API and is not deprecated
- Test authentication splits by consumer: `ldh` reads the PKCS12 keystore, `curl` keeps the PEM derived beside it, and `run.sh` derives the keystore paths from the certificate paths it is given (its four-argument interface is unchanged)
- `signup.sh` keeps the keystore it downloads instead of deleting it after the PEM conversion
- CI builds `cli/`, runs its unit tests, puts the launcher on `PATH`, and extends the certificate permission fix to the keystores
- The CLI JVM starts with `-XX:TieredStopAtLevel=1 -XX:+UseSerialGC`, tuned for startup rather than throughput (0.231s to 0.201s per invocation locally); `LDH_JAVA_OPTS` replaces those defaults rather than appending
- `ldh import-ontology` mirrors the rewritten script's scratch-document flow (proxy fetch → PUT into a UUID-slugged scratch document → `construct-constructors` scoped to that graph → append the constructors and an `owl:imports` header to the target → delete the scratch document on every exit path), replacing the `POST` to the deleted `/transform` endpoint
- **BREAKING**: TimeMaps are described with PROV-O instead of `http://mementoweb.org/ns#`, which has no published vocabulary — a `prov:Collection` of `prov:Entity` mementos, each `prov:specializationOf` the Original Resource, `prov:generatedAtTime` its commit datetime and `prov:wasRevisionOf` its predecessor; a TimeMap with no mementos `404`s
- Memento hypermedia uses the IANA-registered relation types with `type="application/link-format"`, branching per response type: the Original Resource advertises `timemap`/`timegate` and never `original`, a Memento links back to its Original Resource, the TimeMap identifies itself with `self`
- The `type` parameter of `Link` response headers is emitted as a quoted-string per RFC 8288 — a media type containing a solidus is not a token
- `Memento-Datetime` uses the same zero-padded RFC 1123 formatter as the TimeMap body; `DateTimeFormatter.RFC_1123_DATE_TIME` leaves the day of month unpadded where the RFC 7089 grammar wants `2DIGIT`
- TimeMap commit history is paged, bounded at `MAX_COMMIT_PAGES` with truncation logged, instead of stopping at the first 100 commits; mementos are ordered by parsed instant rather than datetime string
- TimeGate redirects are `no-store`: `Vary: accept-datetime` gives Varnish an unbounded key space, and the write-time ban matches the document URL, never the `?timegate` URL
- Install metadata is applied by one SPARQL update per app with the existence check in the `WHERE` clause, replacing `enrich_document_metadata`'s blind append
- The owner and secretary authorizations get stable slugs (`acl/authorizations/owner-webid/`, `acl/authorizations/secretary-webid/`) instead of a fresh UUID per dataset load, and the test owner fixture points at the same slug
- CI gives each run its own versioning branch, branched from `main` and deleted afterwards
- Editing forms already open on the page reconcile with the constructor after a constructor save: missing properties get `bs2:FormControl` groups appended, value-less groups the constructor no longer asserts are removed, controls holding entered values and `rdf:type` controls are untouched, and a failed fetch leaves the form as it was
- Snapshot params (`?version`/`?timemap`) deliberately do not survive a modal document save
- Constructor instances are instantiated client-side: one SPARQL SELECT fetches the type set's `spin:constructor` queries (subclass closure, deduplicated) and their CONSTRUCT templates are expanded onto a single instance typed with all the resource's classes — same-range duplicate properties collapse, and a constructor must have an empty `WHERE` clause to be client-instantiable
- Server-rendered edit forms show data properties only; the client re-render supplies the constructor controls (`ldh:construct-forClass` is an empty stub under SAXON, the `ac:construct` stub pattern)
- "Add data" accepts foreign target documents: the proxied append carries the delegated agent identity, so the target instance's access control arbitrates and its refusal surfaces as the form error
- "Import ontology" keeps the local-target requirement because its constructor derivation is scoped to the local `/sparql` endpoint
- Packages are declarative: an application imports a package with a single `<app> ldh:import <package-uri>` triple in its dataspace settings — in `config/dataspaces.trig` (permanent, applied on restart) or live via `PATCH /settings` (effective on the next request, no restart)
- A package's components are discovered from its Linked Data description (bundled ones resolve from the classpath) and its stylesheet is composed into the application stylesheet in memory at compile time, per dataspace — nothing is copied into the webapp and `/static/` is never modified
- The available-package catalog is data at the registry URI `https://packages.linkeddatahub.com/` (bundled one-entry copy listing the SKOS package, served through the Linked Data proxy's mapped-URI resolution until the registry is live)
- The application settings modal lists the available packages with a per-row Installed checkbox serialized as an RDF/POST `ldh:import` input, and the form's single Save submits settings and package imports as one PATCH through `/settings`
- The package's ontology joins the application's ontology imports closure automatically, derived from `ldh:import` at ontology-load time: each package ontology is assembled as its own `owl:imports` closure and added as a union member, with no `owl:imports` triple materialized anywhere
- A `/settings` PATCH evicts the assembled closure, so package installs and uninstalls take effect on the next request; a package ontology that fails to load is skipped
- "Import ontology" persists only the derived annotation ontology — generated class constructors plus `owl:imports` of the canonical vocabulary URI, the artifact shape a package ontology ships; the fetched vocabulary is scaffolding in a scratch document deleted on every exit path
- The vocabulary resolves live through the graph repository, so constructors derived for bundled vocabularies now reach the ontology closure — the shipped file previously shadowed the local copy holding them
- The annotation document is wired into the namespace ontology itself (`add-ontology-import.sh --import <document>`)
- XSLT compilation resolves `xsl:import` URLs under an application origin's `/static/` path to local webapp files (`LocalStylesheetResolver`) instead of HTTPS round-trips through nginx, and modules imported via different routes deduplicate under one URL
- `ac:stylesheet` values in `config/dataspaces.trig` are absolute URLs on the application's own origin (previously relative, absolutized against the root base URI)

### Removed
- **BREAKING**: `/ns?forClass=` constructed-instance responses — the client-side instantiation is the only consumer path; the `Namespace` endpoint serves SPARQL queries and the raw ontology graph only
- **BREAKING**: `packages/install` and `packages/uninstall` endpoints, the admin `packages/` container and their ACL entries, the package Actions UI (`imports/lapp.xsl`), and `bin/admin/packages/` CLI scripts — the `ldh:import` declaration itself is the installation. Packages installed with earlier releases were webapp-file mutations and do not carry over: re-declare them with `ldh:import`
- `XSLTMasterUpdater`, `Package.getStylesheetPath()` and the bundled `packages/skos/layout.xsl` copy — dead now that the webapp-file installation path is gone
- `MEM` vocabulary class — no consumers left once the Memento namespace gave way to PROV-O and the IANA relation types
- Vestigial `forClass` URL params: the `add-constructor` button `@href`s (the onclick reads `@data-for-class`), the chart form's `@action` (`btn-save-chart` `PATCH`es the current document), `ldh:build-query`'s `forClass` arity, and `CacheInvalidationFilter`'s unreachable ban branch
- `ldh:NoOp`, replaced by the constructor-sync fan-out on `ldh:ClearNamespace`
- `ProvenanceFilter` — a 2021 skeleton whose registration was commented out since it was written; the PROV-O provenance sidecar (P2.3) will not start from its graph-per-request shape

### Fixed
- `ldh --version` reported a hardcoded `1.0.0-SNAPSHOT` regardless of the build; it now reads `Implementation-Version` back from the jar manifest
- `--help` was unrecognized on every `ldh` subcommand — `mixinStandardHelpOptions` only reaches the root command, so the option now lives in `BaseCommand` and in a new `CommandGroup` base that the five subcommand groups extend in place of their duplicated `@Spec`/`call()` pairs
- GraphMode rendering of `ldh:Object` blocks crashed with a cardinality error: the `bs2:Row` branch applied `bs2:Graph` without the required `canvas-id` param; the 3D force graph now initializes after the row is rendered
- Constructor edits never surfaced in instance forms: the callback cleared the ontology derived from the class' `rdfs:isDefinedBy` and left the annotation graph cached, so it now clears the document its `PATCH` just updated (`ac:document-uri($constructor-uri)`)
- Modal document save re-rendered in the default layout mode instead of the active one; the post-save navigation now carries the URL's `?mode=`, guarded to same-document reloads
- Restore buttons were missing when History was opened from a `?version=` view: `acl:mode()` reflects the snapshot response, which `ResponseHeadersFilter` caps at `acl:Read`, so the modal now `HEAD`s the live document and reads its `acl:mode` links
- Documents accumulated a `dct:created` value per container recreate — 201 on one development instance — because the dataset load appends rather than replaces; documents that already carry one keep the timestamp they have
- Every dataset load left another copy of the owner's and secretary's authorizations behind, 60 on one development instance; the stable slugs make re-running the load a no-op
- Concurrent CI runs silently lost versioning commits to the GitHub Contents API's optimistic lock on the branch head, timing out unrelated tests waiting for them
- `create-file.sh` carried two lines on stdout once `ldh add-file` printed the content-addressed upload URI, mangling the URL `GET-file-304.sh` captures from it
- `cache: 'maven'` failed the CLI job outright — `setup-java` runs before the checkout in that workflow, so there was no `pom.xml` to hash
- Constructor-supplied inputs went nondeterministically missing (the intermittently vanishing app-settings Description field) and multi-range predicates raised cardinality errors — both fixed by the client-side instantiation
- Modal violation re-renders harvested `property-uris` from everything except the edited resource, degrading property labels to their local-name fallback; the violation/response machinery no longer pollutes the `property-uris`/`object-uris` harvests
- The `required` function on the modal violation context is stamped per flow by the response handlers, matching each flow's initial-render chain — the shared Container/Item test disagreed with the app-settings chain
- The Linked Data proxy stamped re-serialization validators instead of forwarding the origin's `ETag`/`Last-Modified`, dropped conditional request headers (`If-Match`, `If-None-Match`, `If-Modified-Since`, `If-Unmodified-Since`), and parsed the origin's `4xx`/`5xx` error bodies as RDF (turning a proxied `412`/`403` into a `502`) — preconditioned and access-controlled writes against proxied documents are now evaluated at the origin and their real status reaches the client


## [5.9.1] - 2026-08-19
### Added
- Inline creation in views: views carrying the new `ldh:container` metadata render a Create button that creates a linked instance in that container (#351)
- `ldh:showWhenEmpty` hides a view while its query returns no results

### Changed
- Bundled SKOS package view queries tolerate untagged `skos:prefLabel` literals

### Fixed
- Type/class typeaheads dropped `owl:Class`-typed classes under inference-free ontology serving
- SKOS package URLs moved to LinkedDataHub-Apps `master` after the `develop` branch was deleted (package installs 404ed)

## [5.9.0] - 2026-08-18
### Added
- GitHub-backed graph versioning: writes mirror each document into a repository as a sorted N-Triples commit authored with the agent's WebID (per-dataspace `lapp:versioningRepository` → `doap:GitRepository` in `system.trig`; token as `a:authToken` in `secrets/credentials.trig`) (#350)
- `GET ?version=<commit-sha>` serves a historical version with `Memento-Datetime`, a SHA `ETag`, and immutable `Cache-Control`
- `GET ?timemap` serves the version history as an RFC 7089 TimeMap in RDF (Memento vocabulary), advertised via a `Link rel=memento:timemap` header
- History modal opened from the document's action-bar timestamp: version table with agent attribution, current version marked
- Historical-version notice banner with a link back to the current version
- Gated `http-tests/versioning/` suite (runs when `VERSIONING_TEST_REPO` and `GITHUB_TOKEN` are set)

### Changed
- Historical version and TimeMap views are read-only: only `acl:Read` advertised in `Link` headers, write methods rejected with `405`
- `version`/`timemap` query params ride the client-side RDF re-fetch and survive URL rebuilds, so snapshot pages render fully (content blocks included)
- New hostname-verified HTTP client factory for public-web API hosts (the existing clients disable hostname verification against a truststore that includes public CAs)

### Fixed
- Entrypoint parses the credentials secret from a `.trig`-suffixed copy — the extensionless secret mount made `riot` fail silently and killed startup whenever the `credentials` secret was enabled

## [5.8.0] - 2026-08-17
### Added
- HTTP tests pinning graph-scoped queries via SPARQL Protocol dataset parameters on `/sparql` (`default-graph-uri=<doc-uri>` scopes a query to one document's graph; overrides `FROM`; `GRAPH` patterns match nothing) — the read-side counterpart of graph-scoped `PATCH`, no server changes needed

### Changed
- Application ontologies resolved as a native ontapi `owl:imports` union graph (cached per ontology URI), no RDFS inference — replaces the manually flattened, RDFS-materialized model
- "Import ontology" orchestrated client-side: proxy fetch → GSP append of the raw ontology to the target document → `construct-constructors` CONSTRUCT scoped to that document's graph via the SPARQL Protocol dataset specification (`default-graph-uri` on `/sparql`) → GSP append of the result; `import-ontology.sh` rewritten curl-only (drops the `turtle` CLI dependency)
- `Namespace` no-query GET serves the raw ontology graph from the shared repository instead of rebuilding one per request
- View controls (order-by dropdown, facet headers, parallax, `rdf:type` facet values) resolve term labels via `/ns` instead of per-term Linked Data proxy fetches (#340)
- Dependency bumps: Jersey 3.1.12, csv2rdf 2.2.1, java-jwt 4.6.0, jsoup 1.23.1, central-publishing-maven-plugin 0.11.0, frontend-maven-plugin 2.0.2
- GitHub Actions bumps: checkout v7, setup-java v5, docker build/push actions v4
- HTTP tests count SPARQL results with `xmllint` instead of `grep -c` (#348); flaky DBpedia proxy test replaced with a local cross-origin query
- **BREAKING**: "Add data" and "Generate containers" orchestrated client-side over the Graph Store Protocol (POST-append via `?uri=` proxy; per-class container PUT fan-out embedding the view as `ldh:Object` → `rdf:value` → `ldh:View`), replacing the `/add` and `/generate` endpoints

### Fixed
- Raw ontology graphs no longer leak inferred `rdf:type rdfs:Resource` that broke View block rendering via multi-token `@typeof`
- Missing labels on class-valued objects (e.g. `rdf:type`): `/ns` ontology labels merged into object-metadata, SSR and CSR (#345)

### Removed
- Linked Data proxy no longer serves ontology terms (now dumb transport: bundled-vocab file cache + SSRF-checked external fetch); ontology terms served by `/ns`
- **BREAKING**: `/add` and `/generate` server-side endpoints (`Add`/`Generate` JAX-RS resources), superseded by the client-orchestrated writes; removes their server-side fetch/SSRF surface (LNK-002)
- **BREAKING**: `/transform` endpoint (`Transform` JAX-RS resource), superseded by the client-orchestrated "Import ontology" flow — the last bespoke server-side fetch/SSRF surface (LNK-002) is gone

## [5.7.1] - 2026-08-06
### Changed
- RDFa editor: annotation overlay rebuilt on demand (`rdfa-editor/overlay.xsl`)

### Fixed
- RDFa editor: exit-canvas save fired a duplicate PATCH that 412'd on a stale `If-Match`; `onfocusout` is now the sole save trigger
- RDFa editor: block drag-handle visibility (bootstrap.css collision) and dropping blocks inside a LinkedDataHub document
- RDFa editor: annotation overlay dismissed on teardown; caret lands at the clicked word

## [5.7.0] - 2026-08-02
### Changed
- WYMEditor replaced with the RDFa editor for `rdf:XMLLiteral` editing (#336)
- RDFa annotation dialog controls grouped into Subject and Object fieldsets
- Entity-inlining and SEF compilation moved to the pre-integration-test Maven phase
- Dependency and Maven plugin upgrades: slf4j-reload4j 2.0.18, Mockito 5.23.0, Surefire 3.5.6, maven-compiler-plugin 3.15.0, frontend-maven-plugin 2.0.0, maven-gpg-plugin 3.2.8

### Fixed
- Static asset URIs resolve against the shell-origin `$lapp:origin`, fixing CORS-blocked fetches on proxied dataspaces

## [5.6.1] - 2026-07-26
### Security
- SSRF: `URLValidator` blocks wildcard/any-local (`0.0.0.0`, `::`) addresses and checks every resolved address; loopback stays reachable, `ALLOW_INTERNAL_URLS` remains the escape hatch (LNK-003/LNK-009)
- XXE: `SecureXML` hardened parser factories disable DTDs/external entities in `XSLTMasterUpdater` and `ldh:send-request` responses (LNK-005 residual)
- Upgraded `java-jwt` 3.19.4 → 4.5.2 on the OAuth2/OIDC verification path
- Documented the pinned-truststore invariant behind disabled hostname verification on internal HTTP clients

### Added
- Unit tests for `AuthorizationFilter`'s HTTP-method → ACL access-mode contract, mode lookup, and owner grant
- Loopback/wildcard `URLValidator` tests; JWKS-based `JWTVerifier` tests
- `AGENTS.md`: agent-facing guide to driving a running instance's HTTP API
- Dependabot config (`.github/dependabot.yml`) for Maven, the Docker base image, and GitHub Actions

### Changed
- Cache TTLs configurable via `WEBID_CACHE_EXPIRATION` / `JWKS_CACHE_EXPIRATION` (default 86400s), bounding how long a revoked WebID stays authenticated
- CSR label rendering consolidated on Web-Client per-vocab templates; retired `$ldt:lang` for `$ac:langs` from `navigator.languages`; added client-side `ac:uuid()` (#323)
- Web-Client dependency bumped to 5.0.3

### Fixed
- View queries with a `FROM`/`FROM NAMED` clause returned `400`; `ldh:wrap-describe` now hoists the clause to the outer `DESCRIBE`
- Duplicate bilingual widget headings when the browser language matched neither value (#323)
- Language badge leaking into view headings (e.g. `enCurrent members`)
- `acl:mode()` went stale on fetch-less tab-pane switches; flags now re-synced from the activated pane
- Modal live-search debounce logged an unsupported-scheme fetch from `document="ixsl:page()"`
- Left-sidebar flyout clipped on short viewports; now scrolls

## [5.6.0] - 2026-07-08
### Added
- `OntologyRepository` (renamed from `OntologyModelGetter`): a bounded, evicting ontology cache that serves bundled vocabularies without querying SPARQL; per-app creation is thread-safe and each ontology is materialized once under a lock (`owl:imports` closure flattened manually, then RDFS-inferred and materialized). Seeded ad-hoc in `Namespace`
- Blank nodes skolemized after `PATCH` (+ HTTP test)
- Unit tests for the graph store, RDF import streaming, and proxied WebID auth
- Regression tests for Varnish cache poisoning (On-Behalf-Of delegation, and the Client-Cert + RDF path)
- HTTP test for `?forClass` namespace requests against `rdfs:Class`

### Changed
- Migrated 19 vocabularies off the deprecated-for-removal `org.apache.jena.ontology` API to `org.apache.jena.ontapi` (Jena 6 ont-api), using the `OWL2_FULL_MEM` profile; document/LDT/ACL classes normalized to `owl:Class`; SPIN constraints run against twirl's SPIN personality so LDH no longer registers SPIN globally (#316)
- Dependency upgrades: Guava 33.6.0, twirl 2.0.0, Web-Client 5.0.1, jsoup 1.22.2, JUnit 6.1.0, Mockito 5.18.0; adapt to the `StylesheetResolver(Client)` constructor
- Proxy namespace `DESCRIBE` query built with `ParameterizedSparqlString`
- Forward upstream validators for `HEAD` proxy responses
- `active` token deferred on new tab panes to `ldh:ActivateTab`
- Progress cursor shown while 3D graph requests are in flight
- Fuseki memory limits, heap, and restart policy set in `docker-compose.yml`

### Fixed
- Varnish cache poisoning: bypass the `varnish-frontend` cache for any Client-Cert request outside `/static/` and for On-Behalf-Of requests

### Removed
- Dead `CACHE_MODEL_LOADS` (`cacheModelLoads`) and `preemptiveAuth` config flags; `ENV CACHE_MODEL_LOADS` dropped from the `Dockerfile`
- Unnecessary frontend cache purge; unused imports

## [5.5.4] - 2026-06-29
### Fixed
- HTTP client connection-pool exhaustion: the pooled clients had no socket/read timeout (Apache default `SO_TIMEOUT` = 0 = infinite), so a stalled backend read held its leased connection forever and the route eventually pinned at max, wedging the listener. Added socket timeout, connect timeout, connection time-to-live and validate-after-inactivity to the pooled clients, configurable via the `CLIENT_SOCKET_TIMEOUT`, `CLIENT_CONNECT_TIMEOUT`, `CLIENT_CONNECTION_TIME_TO_LIVE` and `CLIENT_VALIDATE_AFTER_INACTIVITY` env vars (`CATALINA_OPTS` system properties), with image defaults in the `Dockerfile`
- `SignUp`: PublicKey/Agent/Authorization client `Response`s are now closed on all code paths (connection leak on the signup path)

## [5.5.3] - 2026-06-09
### Changed
- Dependency hygiene: exclude duplicate `jakarta.json` from `jena-arq`, align `slf4j-reload4j` to 2.0.17, drop unused `tomcat-coyote`

### Fixed
- `JSONGRDDLFilter` response-side gate scoped per subclass (instance-level property key) with defensive `isApplicable` re-check; prevents cross-fire when multiple subclasses share the client filter chain

## [5.5.2] - 2026-06-09
### Changed
- Left sidebar moved to CSR: `ldh:LeftSidebar` emits its own `left-sidebar` wrapper and is injected via `ixsl:append-content`; SSR `bs2:DocumentTree` placeholder dropped

## [5.5.1] - 2026-06-08
### Changed
- Consolidated href parsing into `ldh:parse-href#1` (inverse of `ldh:href#3`), shared by all navigation handlers

### Fixed
- Cross-origin URL query strings stripped on navigation (e.g. `youtube.com/watch?v=...`)
- ContentMode block drag-drop reordering broken after the tab/`document-body` DOM flatten

## [5.5.0] - 2026-06-07
### Added
- HTML+JSON-LD reader: extracts every `<script type="application/ld+json">` from HTML responses and parses each payload through Jena's `Lang.JSONLD11`, so embedded schema.org markup parses as RDF. Bundled schema.org JSON-LD `@context` served locally by `SchemaOrgDocumentLoader` (no network fetch). Replaces the old `JsonLDReader` and drops the `jsonld-java` + `httpclient-cache` dependencies (#312)
- GraphMode 3D canvas Fullscreen toggle (CSS maximize, Esc exits)
- Esc closes topmost modal
- HTTP test for orphan bnode object skolemization
- HTTP test for HTML+JSON-LD ingestion through the document hierarchy

### Changed
- Jena upgraded to 6.1.0 (#309)
- Modal- and row-form metadata fetches converted to async load/set pairs; row-form chain extended with property-metadata, constraints, object-metadata; `sd:endpoint()` carried in context (#310)
- `bs2:Form` `$required` lifted to a predicate at `rdf:RDF` level
- CSR-only helpers moved out of `layout.xsl`; `bs2:FormControl` boolean overrides relocated
- Admin XSLT overrides (`bs2:Row`, `bs2:Create`, `bs2:FormControl`, `bs2:NavBarNavList`) and ACL/cert vocab templates moved from the SSR-only `admin/` chain into shared `document.xsl`/`resource.xsl`/`layout.xsl` and new `imports/{acl,cert}.xsl`; gated by `admin.`-subdomain on `lapp:origin()`
- `lapp:Application` form restrictions scoped to the app-settings flow
- `rdf:type` editable on `ldh:View` instance forms
- GraphMode canvas persisted across view re-renders via a `{container-id}-graph-host`; WebGL context and force-simulation state survive search/filter re-runs; dangling `@rdf:nodeID` and anonymous nested `rdf:Description` rendered as bnodes; click handlers skip bnodes
- View mode preserved across re-runs of the same search container
- Container result count short-circuits COUNT when the result set fits one page
- Removed bash trace debug from entrypoint
- Modal-form per-flow `render-fn` stamping unified via `ldh:constructor-form-response` / `ldh:edit-form-response` (parallel to `ldh:settings-form-response`); new `ldh:render-constructor-form#2` routes Container/Item creation violation re-render through `mode="bs2:Form"`, leaving `mode="ldh:DocumentForm"` for the edit flow

### Fixed
- Drop just-added block on empty-graph submit
- `btn-remove-resource` removes outermost duplicate `.block` wrapper
- Relative `document('translations.rdf')` calls in `imports/{nfo,sioc,sp}.xsl`, `admin/layout.xsl`, `document.xsl` 404'd against the SEF root under SaxonJS 3; switched to absolute `resolve-uri(..., lapp:origin())`
- Admin dropdowns, form-control defaults, and navbar reverted to end-user variants after CSR navigation (overrides only lived in the SSR `admin/` chain)
- Admin `bs2:Row` `foaf:Person`/`foaf:Group` lookup failed under SaxonJS XHR because `ac:document-uri` leaves slash-vocab term URIs intact; override now fetches the namespace doc
- `Skolemizer` covers blank nodes in object position; orphan bnode references (e.g. `<container> rdf:_1 [ ]`) rewritten to skolem URIs
- Container/Item modal violation re-render preserves co-shipped peer Descriptions (default `ldh:ChildrenView` content block was lost)
- EDIT and violation re-render were missing the SPIN-constructor merge that CREATE performs; `bs2:FormControl`'s SHACL branch silently dropped SPIN-defined property templates for classes with both (e.g. `skos:Concept`); merge extracted into shared `ldh:build-merged-constructor` and wired into both flows via the `constructor` tunnel

## [5.4.0] - 2026-06-04
### Added
- Multi-tab document navigation (`Document tabs`) with per-pane modal scoping and cached tab switching (#294, #302)
- 3D Linked Data browser graph mode (#288); right-click loads backlinks on URI nodes (#305)
- Client-side property and object metadata loading, generalised loader, ontology-view render chain (#297, #298)
- `ldh:view` block injection moved client-side under Saxon-JS (#295)
- gzip compression in nginx for RDF and JSON content types, scoped to static locations (#290)
- SPIN constraint enforcing `ldh:ContentMode` block-type restriction (only `ldh:Object` and `ldh:XHTML` allowed)
- Static resource URLs built from dataspace origin (#303)
- Linked Data proxy for URIs in the namespace ontology (#285)
- Constructor predicate typeahead rendered when `/ns` has no metadata
- Fallback to synthesized predicate description when proxy unavailable
- HTTP test for `?accept` param on non-existent dataspaces

### Changed
- Server-side `acl:mode()` derived from `Link` response headers (#299)
- Constructor and shape `document()` calls refactored to `ixsl:promise` for async loading (#306, #307)
- Proxied RDF responses rendered in tab panes; navbar templates tidied for unknown dataspaces
- `?accept` override applied before app matching so 404 on unknown dataspace respects requested format
- `bs2:Actions`, `bs2:AddData`, and `http:Response`/`bs2:Header` overrides moved from `layout.xsl` to `document.xsl` for CSR compatibility
- Document-type checks factored out of `bs2:Form`/`bs2:FormControl` widgets
- `normalize-rdfxml` mode-isolated to stop intercepting default-mode dispatches
- Client-side `rdf:RDF` rendering surfaces document and primary topic first
- Auto-generated container block wrapped in `ldh:Object`
- Mode query param preserved when navigating from links on proxied pages; tab href kept in sync with address-bar mode
- Path-aware view ordering for modal search (#301)
- Server tolerates SPARQL failures when loading object metadata
- Object-metadata fetch skipped when `block-object-value-response` renders inline

### Fixed
- Reject PATCH that strips `rdf:type`; validate full post-PATCH model (#308)
- Connection pool exhaustion from proxy requests (#292)
- `acl:mode()` regex — XPath F&O doesn't support lookahead or `\b` (#300)
- CORS response headers (#286)
- `ProxyRequestFilter` swallowing PATCH to ontology-namespace URIs
- Constructor-form staleness via xkey purge + async XSLT refactor (#306)
- Client-side vocab-doc lookups now gated on `ixsl:doc-fetched()`
- Forward response headers from proxy when upstream has no `Content-Type`
- Local tab pane hidden on SSR for proxy requests by restoring `$ac:uri`
- Proxy and LDH error responses rendered with visible tab pane
- Tab activation deferred until `rdf-document-response` populates the cache
- Reused-pane tab metadata synced; address-bar local check fixed
- `ac:property-label` cache lookup aligned with `documentPool` key shape
- `XMLLiteral` in `PUT-content-blocks.sh`
- Cursor style

## [5.3.5] - 2026-04-06
### Changed
- `ProxyRequestFilter` now proxies all HTTP methods generically instead of whitelisting GET/POST/PUT/PATCH/DELETE
- Allow proxying to registered `lapp:Application` endpoints regardless of `ENABLE_LINKED_DATA_PROXY`

## [5.3.4] - 2026-04-05
### Fixed
- Do not append facet well into left-nav when there are no BGP triples
- Hide progress bars when errors need to be shown in blocks
- Exempt proxy requests from local ACL checks in `AuthorizationFilter` (#280)

## [5.3.3] - 2026-04-01
### Added
- New HTTP test for non-existing namespaces
- New HTTP test for not found files

### Changed
- Removed unused namespaces
- More XSLT fixes related to optional applications
- Making application optional in XSLT writer
- Preserve URL fragment identifier in history `pushState`
- `varnish_end_user_cache` volume (#279)

### Fixed
- Progress bar CSS fix
- Throw 404 when file description is not found
- Fix NPE in `CacheInvalidationFilter` when request scope is unavailable
- Fixed WebID URI logging in entrypoint

## [5.3.2] - 2026-03-30
### Fixed
- Fix `ClientUriRewriteFilter` host (#277)

## [5.3.1] - 2026-03-29
### Added
- Namespace endpoint handles queries with relative URIs, resolved against the endpoint URL (#276 related)
- GRDDL filters loaded using `ServiceLoader` for better extensibility
- HTTP tests for namespace endpoint relative URI queries
- HTTP test for package stylesheet deduplication

### Changed
- `XSLTMasterUpdater` refactored: `regenerateMasterStylesheet()` replaced with `addPackageImport()`/`removePackageImport()` methods that preserve existing stylesheet content (#275)
- Resolving relative URLs in XHTML literals against the document's base URI (#276)
- Removed unused XSLT params
- `make tests` command added to Makefile

### Fixed
- Fixed `XSLTMasterUpdater` to avoid duplicate `xsl:import` statements when installing packages (#275)

## [5.3.0] - 2026-03-05
### Added
- Class-based navigation (#270)
- `VARNISH_*_BACKEND_PORT` env params for configurable Varnish backend ports
- Bearer auth token support in entrypoint; service credentials moved to `secrets/credentials.trig`
- `gsp_append_quads` function in the entrypoint
- New ACL HTTP tests for system endpoints
- Ignored paths in `OntologyFilter` (#269)

### Changed
- Renamed `DirectGraphStoreImpl` to `DocumentHierarchyGraphStoreImpl`
- Dataspace nav list now visible for unauthenticated agents
- Client-side SPARQL query execution uses `POST` instead of `GET`
- Full context dataset now passed to XSLT
- Introduced `ServiceContext` to decouple HTTP infrastructure from `Service`
- Split dataspace metadata from service metadata in configuration
- Moved types to `system.trig`; `lapp:endUserApplication`/`lapp:adminApplication` now inferred on the fly
- Refactored CSV/RDF import scripts

### Fixed
- UTF-8 charset handling for text-based media types in uploaded files
- Fixed links to the admin app
- URI resolution fix in `AuthorizationFilter`
- Left sidebar CSS fixes

### Removed
- Removed system endpoint resources from default RDF datasets

## [5.2.1] - 2026-01-20
### Changed
- Package view rendering refactored to use type-driven discovery with `ldh:view`/`ldh:inverseView` properties matching resource types against `rdfs:domain`/`rdfs:range` constraints

## [5.2.0] - 2026-01-14
### Added
- Application settings form with modal UI for editing dataspace configuration
- Settings endpoint (`/settings`) with `GET` and `PATCH` support for dataspace settings
- HTTP tests for the settings endpoint
- LinkedDataHub packages system with install/uninstall functionality

### Changed
- Core library refactored Graph Store Protocol implementation - split into `GraphStoreBase` (common functionality), `DirectGraphStoreImpl` (direct graph identification), and `GraphStoreImpl` (indirect graph identification with query parameters)
- Incorporated AtomGraph Server code directly into LinkedDataHub codebase
- System configuration dataset now uses named graphs instead of default graph
- Web-Client dependency version bump
- CLI scripts improved for better parameter handling

## [5.1.0] - 2025-12-12
### Added
- ORCID OpenID Connect login support with JWT token verification
- `CORSFilter` response filter for cross-origin resource sharing on static assets
- Cache invalidation (`BAN` requests) for agent and user account lookup queries
- New `Application::normalizeOrigin` method for origin normalization
- `ldh:parent-origin` XPath function for parent origin retrieval
- HTTP tests for CORS functionality, internal IP blocking, and form proxying
- `ForbiddenExceptionMapper` for handling forbidden exceptions
- `Content-Security-Policy` header for uploaded files to prevent XSS attacks
- Sticky left and right navigation panels
- Support for recursive content blocks
- Docker volume for Varnish cache file persistence

### Changed
- **BREAKING**: Admin application moved from `/admin/` path to `admin.` subdomain
- **BREAKING**: Replaced `ldt:base` with `ldh:origin` in configuration (now uses absolute URIs with full domain names)
- Refactored OAuth2 authentication with extracted base classes `AuthorizeBase`, `LoginBase`, and `JWTVerifier`
- Provider-specific implementations for Google and ORCID OAuth flows in separate packages
- Authorization queries now isolated by dataspace using `FILTER(strstarts(str(?g), str($base)))`
- Optimized Varnish caching for authenticated requests with proper cache bypass for user-specific content
- Root domain extraction logic replaced with configured `BASE_URI` from `Application.getBaseURI()`
- Eliminated unnecessary wrapper methods (`getRootContextURI()`) in favor of direct `getSystem().getBaseURI()` calls
- Client-side XSLT now uses `ldt:base()` function instead of `$ldt:base` parameter
- OAuth and access request endpoints moved to end-user dataspace (no longer extend `GraphStoreImpl` or `SPARQLEndpointImpl`)
- ID tokens now returned via URL fragment instead of query parameters
- CLI scripts refactored: `--fragment` parameter renamed to `--uri`
- Nginx configuration now exempts internal requests from rate limiting
- Parameterized nginx and Varnish configurations for better flexibility
- Improved `ClientUriRewriteFilter` to use configured host instead of hardcoded localhost
- Agent metadata and authorizations now managed per-app in entrypoint.sh
- Separated templates for owner and secretary authorizations
- Fuseki data directory changed in Docker configuration
- `$ORIGIN` environment variable now excludes default ports (80/443)
- WYMEditor cross-origin compatibility fixes
- Replaced `ldh:new` with `ixsl:new` in client-side code

### Fixed
- Fixed security vulnerability [LNK-002 (cache poisoning)](https://github.com/AtomGraph/LinkedDataHub/issues/253)
- Fixed security vulnerability [LNK-004 (path traversal)](https://github.com/AtomGraph/LinkedDataHub/issues/252)
- Fixed security vulnerability [LNK-009 (SSRF - internal IP address proxying)](https://github.com/AtomGraph/LinkedDataHub/issues/250)
- Fixed security vulnerability [LNK-011 (XSS via uploaded files)](https://github.com/AtomGraph/LinkedDataHub/issues/254)
- Fixed Billion Laughs [XML entity expansion exploit](https://github.com/AtomGraph/LinkedDataHub/issues/249) by excluding Xerces dependency
- Fixed OpenLayers map dragging functionality
- Fixed graph layout rendering issues
- Fixed SPARQL update and `application/x-www-form-urlencoded` proxying
- Fixed access request URL building and modal form display
- Fixed `ldh:Shape` mode in XSLT
- Fixed HTML reloading after OAuth login
- Improved SHACL support in UI with better form controls
- Fixed performance regression in `ClientUriRewriteFilter` for production deployments
- Fixed agent and user account duplicate creation via proper cache invalidation
- Fixed same-site URI resolution for XSLT document loading across subdomains
- Fixed entrypoint to load datasets for all configured apps
- Fixed authorization filter to handle non-existent dataspaces (throws `NotFoundException`)

### Removed
- Removed `RequestAccess` resource from admin package (moved to end-user)
- Removed `admin/oauth2` package (OAuth moved to end-user dataspace)
- Removed XOM dependency
- Removed rate limiting tests from HTTP test suite
- Removed debug output from entrypoint and test scripts
- Removed unused namespace declarations

## [5.0.23] - 2025-09-11
### Added
- Drag handles for content blocks - blocks can now only be dragged by their dedicated drag handles
- Client-side XPath `ac:mode` function for layout mode detection
- New `ldh:request-uri` XPath function for URI handling
- New `acl:mode` XPath function for client-side ACL mode detection   
- New HTTP tests for ACL `Link` headers to verify authorization modes in response

### Changed
- Service input on the container generation form is now optional
- IXSL promise cleanup and refactoring for better client-side performance
- Document context handling improvements

### Fixed
- `AuthorizationFilter` to always load authorizations from the admin dataset
- Modal form validation
- Layout mode is now retained after RDF file upload

## [5.0.22] - 2025-08-29
### Added
- SPARQL query support for `ProxyResourceBase` via `POST` requests
- YouTube object block support with GRDDL transformation
- New HTTP tests for proxy SPARQL query functionality
- `JSONGRDDLFilter` feature for processing JSON-LD from HTML script elements
- New CLI command for `PATCH` requests
- Self-referencing object detection to prevent infinite loops

### Changed
- Web-Client dependency version bump
- Increased nginx rate limits for better performance
- Uniform `ldh:href` function calls across codebase
- Improved `Link` header parsing and usage fixes
- Adjusted document controls size for better UI
- Enhanced view titles for better user experience
- Improved tests for document property cardinalities
- Removed DBPedia's prefix mapping

### Fixed
- Fixed template match issues
- Improved `dct:modified` handling in Graph `POST` operations
- Fixed error handling for "Document loaded successfully but resource was not found" cases
- HTTP test fixes for better reliability

## [5.0.19] - 2025-07-01
### Fixed
- Form callback invocation

## [5.0.18] - 2025-06-30
### Added
- Proxy parameter tunneling in CLI scripts (`add-object-block.sh`, `add-xhtml-block.sh`)

### Changed
- Web-Client dependency version bump
- Chart form actions now only display when agent has write access
- CLI scripts now rewrite effective URLs back to original hostname when using proxy
- Default configuration now uses `varnish-frontend`
- `MAX_CONTENT_LENGTH` environment variable moved to `.env` file

### Fixed
- Fixed object blocks rendering for non-RDF resources (e.g. images)
- Fixed `rdf:value` cardinality constraint
- Fixed proxied return URL in `post.sh`

## [5.0.17] - 2025-06-23
### Changed
  - Replaced `xsl:value-of` usage in XSLT stylesheets
  - Removed debug output for cleaner production logs

### Fixed
  - Fixed map and chart mode rendering for general Linked Data objects in content mode
  - Refactored date/datetime comparison logic for improved accuracy
  - Fixed `@id` value handling in client-side processing
  - Fixed multiple factory promises per top-level `<div>` element
  - Fixed client-side `ldh:base` function
  - Fixed default datasets to use `ldh:ChildrenView`
  - Fixed `owl:NamedIndividual` case in `.add-constructor` onclick handler

### Removed
  - Removed the unused ldh:createGraph property

## [5.0.16] - 2025-06-15
## Added
- Javadoc comments

## [5.0.15] - 2025-06-15
### Changed
- Inlined nginx and Varnish config templates into `docker-compose.yml`
- SaxonJS 3 bump to 3.0.0-beta-2

### Fixed
- Remove user-supplied `dct:created` values to prevent timestamp conflicts
- XSLT SEF generation in Maven build

## [5.0.14] - 2025-05-25
### Added
- Inline chart save feature for better user experience

### Changed
- Improved template match patterns for better performance

### Fixed
- Fixed action URL in navbar form
- Comment fixes in codebase

## [5.0.13] - 2025-05-12
### Added
- Saxon-JS upgraded from 2.x to 3.x with "suspended promise tree" architecture
- Auto-generation of WebID certificates (owner and secretary) in entrypoint
- Request access modal forms with ACL integration
- Multi-platform Docker images (ARM64 + AMD64) with GitHub Actions
- Modal document editing forms with in-place editing
- Rate limiting and retry logic for HTTP 429 responses with `Retry-After` headers
- Conditional HTTP requests support (`ETag`, `If-None-Match`, preconditions)
- Access control endpoints for authorization management
- Progress indicators for long-running operations
- Drag-and-drop improvements for block reorganization
- SPARQL endpoint read-only access for authenticated agents
- Enhanced form controls with better `datetime-local` rendering
- New HTTP test suite for conditional requests and access endpoints
- Chart creation workflow improvements
- View system overhaul - `ldh:View` now embedded via `ldh:Object`
- Secrets management for Google OAuth credentials
- Enhanced SSL/TLS management with automated keystore generation
- MacOS compatibility improvements

### Changed
- CLI tools reorganization - scripts moved to `bin/` directory with PATH management
- Client-side named templates converted to XPath functions for better composability
- Promise-based rendering for charts, views, and objects
- `ldh:View` is now a "normal" resource instead of content block
- Authorization query optimization for better performance
- Document type injection with dynamic `VALUES` for type-based queries
- Varnish configuration improvements with separate VCL templates
- User-specific content handling with proper cache bypass
- RDF/POST parser improvements for empty values and relative URIs
- SPARQL.js 2.x compatibility with regex fixes for datatype URIs
- Container orchestration with memory limits and better configuration
- Base image updates: `atomgraph/letsencrypt-tomcat:10.1.34`, `atomgraph/fuseki:4.7.0`
- XHTML namespace handling with default `xmlns="http://www.w3.org/1999/xhtml"`
- Block system improvements with better nesting and unique identifiers
- Authorization filter improvements with `SERVICE`-less queries
- Static file optimizations with increased burst limits

### Fixed
- Multiple null pointer exceptions in Java code
- XPath syntax errors in XSLT stylesheets
- Variable naming conflicts and scoping issues
- Certificate permission issues across platforms
- Progress bar visibility and selector issues
- Block rendering and nesting logic
- Form submission and response handling
- Chart rendering and display logic
- View navigation and object loading
- HTTP status code handling (`201 Created`, `308 Permanent Redirect`)
- Double slash URI prevention in requests
- Container CSS and modal sizing issues
- RDFS-specific vocabulary support

### Removed
- `IMPORT_KEEPALIVE` parameter
- Unused `Reserialize` Saxon function (replaced with pure XSLT)
- Debug output from XSLT stylesheets
- Unnecessary `ixsl:http-request` arguments
- Secret environment variables from Dockerfile
- `bs2:RowContent` mode in XSLT

## [4.0.10] - 2024-11-07
### Changed
- Fixed namespace prefix declaration in client-side XSLT

## [4.0.9] - 2024-02-07
### Changed
- Fixed dragging within a map
- Fixed Docker build issue caused by an old Node.js version
- Fixed Login with Google caused by Varnish configuration stripping HTTP cookies

## [4.0.8] - 2023-07-11
### Changed
- Dependency on `com.atomgraph.server` (new module) instead of `com.atomgraph.processor`
- JAX-RS application now registers the `NotAcceptableExceptionMapper` so that the `406 Not Acceptable` responses are mapped correctly
- Ontologies are now cached by default
- Bumped Jena version in Dockerfile from 4.3.2 to 4.7.0 in order to avoid the Log4Shell CVE warning

## [4.0.6] - 2023-07-01
### Added
- (X)HTML writer for SPARQL XML Results

## [4.0.5] - 2023-06-23
### Added
- New Varnish proxy cache between nginx and LinkedDataHub (`varnish-frontend` service) in order to improve performance
- New `lapp:frontendProxy` and `lapp:backendProxy` properties in the LAPP ontology
- `HEALTHCHECK` configuration in Dockerfile (relies on public access to the namespace document)

### Changed
- Fixed content drag and drop logic to only work in content mode and not affect dragging in map and graph modes
- Content drag and drop is only enabled when the authenticated agent has an `acl:Write` authorization for the document
- Improved extensibility of client-side XSLT templates for faceted search and parallax navigation
- When `ENABLE_LINKED_DATA_PROXY=false`, `?uri=` proxy requests will return `405 Method Not Allowed` unless the URI is already cached or mapped to file
- Replaced the `atomgraph/varnish:6.0.11` Docker image with the official `varnish:7.3.0` image
- Replaced the `atomgraph/nginx:1.23.3` Docker image with the official `nginx:1.23.3` image

## [4.0.4] - 2023-06-07
### Changed
- Moved `Cache-Control` header settings from webapp's `web.xml` to nginx's config template

## [4.0.3] - 2023-05-24
### Added
- Option to re-arrange content blocks by drag & drop in content mode (enabled only when the agent has write access)

### Changed
- Instead of writing JSON-LD directly, `schema:BreadCrumbList` mode returns RDF/XML which is then transformed to JSON-LD using `ac:JSON-LD`

## [4.0.2] - 2023-05-08
### Added
- [XML sitemap](https://www.sitemaps.org/protocol.html) generation when env param `GENERATE_SITEMAP=true` is specified (enabled by default)
- JSON-LD output in the `<script>` tag containing [`schema:BreadCrumbList`](https://schema.org/BreadcrumbList) structured data

### Changed
- Content blocks use `@about` attributes as identifiers instead of `@data-content-uri`

## [4.0.1] - 2023-04-23
### Added
- Backlink navigation on XHTML content

### Changed
- Navigation bar is now fully rendered server-side, i.e. the whole visible HTML body is replaced via AJAX
- Generalized client-side navigation templates using XPath maps
- Fixed default `@id` value in `bs2:RowContent` mode

## [4.0.0] - 2023-01-04
### Changed
- Upgraded dependencies to use Jersey 3.x and the Servlet 5 API. That required replacing `javax.*` dependencies with `jakarta.*`
- Upgraded `atomgraph/nginx`, `atomgraph/letsencrypt-tomcat` and `atomgraph/varnish` base images
- `docker-compose.yml` now uses image versions instead of hashes
- Refactored `RDFXML2JSON-LD.xsl` converter uses the XSLT 3.0 JSON instructions instead of string concatenation
- New `<acl/authorizations/public-namespace/#this>` authorization, separate from `<acl/authorizations/public/#this>`
- Fixed editing mode for resources that do not have any `rdf:type` properties
- Replaced all SPARQLBuilder usages for query building with XSLT 3.0 transformations (SPARQLBuilder still used for query serialization)

## [3.3.2] - 2022-12-12
### Added
- A separate HTTP client used only by the Linked Data client, to avoid sharing the connection pool with the main system client
- Linked Data client now sends a `User-Agent` request header impersonating the Firefox browser

### Changed
- `@id` attributes are rewritten and `@href` attributes are resolved against base URI when XHTML content is being transcluded

## [3.3.1] - 2022-11-19
### Changed
- Fixed HTTP connection leak in the `ldh:send-request` function
- Fixed blank node labels and typeaheads in instance creation forms
- Fixed response caching in the container generation logic to make sure fresh content with the new containers is loaded after redirect

## [3.3.0] - 2022-11-16
### Added
- If content resource cannot be loaded from Linked Data, fallback to a `DESCRIBE` query over the local endpoint

### Changed
- Disabled SPARQL updates on the namespace ontology endpoint `/ns`
- Better aligned document's timestamp and breadcrumbs in the navbar
- Constraint violation responses return `422 Unprocessable Entity` instead of `400 Bad Request` (same change in Processor)
- `PUT`/`DELETE` restrictions on root/owner/secretary documents return `405 Method Not Allowed` instead of `400 Bad Request`
- Improved error handling in the modal "Add data" form
- Resources in containers with remote endpoints get `DESCRIBE` query links instead of plain resource URI which would be attempted to load as Linked Data
- Improved `rdf:type` controls in editing mode to enable adding/removing types on instances (except document instances where types are required)

## [3.2.25] - 2022-11-07
### Changed
- Public `acl:Append` access to the namespace ontology which is required because the `ldh:send-request` function sends unauthenticated SPARQL Protocol `POST` requests

## [3.2.24] - 2022-11-07
### Added
- `ldh:send-request` XSLT extension function which allows stylesheets to execute HTTP `POST` requests (e.g. if the query string is too long for `GET`).

### Changed
- Fixed datetime literal conversion from RDF/XML and SPARQL Results XML to Google Chart's `DataTable`
- Fixed encoding of URIs with special characters in HTTP client requests
- Optimized resource-level XSLT modes by consolidating HTTP requests for type/property/constructor/constraint/shape metadata using SPARQL `VALUES`

### Removed
- Fallback to a `DESCRIBE` request in `ProxyResourceBase`
- `$ldh:localGraph`/`$ldh:original` XSLT parameters. XSLT stylesheet now loads the same data over HTTP without the need for special parameters.

## [3.2.23] - 2022-10-31
### Added
- New "Generate containers" feature that loads a schema from a SPARQL service and then generates a container for each class

### Changed
- Fixed regression of multiple RDF types in the typeahead component
- Fixed container result count widget to support remote SPARQL endpoints
- Fixed regression of created/modified timestaps not rendered on documents

## [3.2.22] - 2022-10-26
### Added
- Result count widget for container content

## [3.2.21] - 2022-10-24
### Changed
- Fixed map initialization regression

## [3.2.20] - 2022-10-24
### Added
- An onboarding message show the first time LinkedDataHub starts
- ACL agent URI is passed to the client-side stylesheet as an `$acl:agent` param

### Changed
- Fixed minor signup and request-access UI issues
- Disabling "Save as" and "Delete" action buttons when the agent does not have a write permission

## [3.2.19] - 2022-10-22
### Added
- Support for recursive content blocks

### Changed
- Loading class and property descriptions from the namespace ontology before falling back to Linked Data
- Fixed shapes support for resources with multiple RDF types

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
