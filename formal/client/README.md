# LinkedDataHub browser client model in Lean

A Lean 4 model of where the browser client sends its requests and the window: `ldh:href`, which builds nearly every
request target, the base `lds:base()` gives the rest, and the branch that opens an external document the proxy could
not fetch. It proves which targets stay on the page's origin and where they do not.

The model is a specification. It is not extracted from the stylesheets: each definition is transcribed from the
code listed in the mapping below, and when that code changes, the definition changes in the same commit.

## Building

```bash
cd formal/client
lake build
```

Lean `v4.15.0` (pinned in `lean-toolchain`), core library only, with no Mathlib. The model stands alone.

The `Formal` workflow builds it on every push, fails on a `sorry`, and checks it against the stylesheets in two ways
(see "Replaying"). On a pull request it also runs `tracks-code.sh`, which fails when a declaration listed under
"Mapping to the code" changes without a change in this directory:

```bash
formal/client/tracks-code.sh origin/develop
```

## Files

| File | Contents |
|------|----------|
| `LdhClient/Uri.lean` | URIs as XPath's string functions handle them: `lds:origin`, `ac:absolute-path`, `ac:document-uri`, `ac:build-uri` |
| `LdhClient/Href.lean` | `ldh:is-local` and `ldh:href`, and why `ldh:href` stays on the page's origin |
| `LdhClient/Pane.lean` | The pane's base and `lds:base()` |
| `LdhClient/Sites.lean` | The request sites not built by `ldh:href`, and why each stays on the page's origin |
| `LdhClient/Navigate.lean` | Where the window goes for an external document the proxy could not fetch, and where a version restore writes |
| `Main.lean` | `ldh-client`: the href cases and the site list, for the workflow |
| `href-cases.tsv` | The href cases, as the model answers them |
| `href-cases.xsl` | The href cases, as the stylesheets answer them |
| `sites.py` | The request sites, as the stylesheets have them |

## The model

- **URIs are strings.** Nothing in the client parses a URI. `lds:origin` is a regex replacement, `ldh:is-local` a
  `starts-with`, `ac:absolute-path` a `substring-before`, and the model transcribes each over a list of characters.
  A URI `lds:origin`'s regex does not match comes back whole, as `replace` returns it.
- **`ldh:href`:**
  - A URI that does not start with the page's origin and a slash is put in `?uri=` on the page's path.
  - A local URI keeps its path, and its own query parameters are overlaid with the caller's.
  - The empty URI is falsy and takes the local branch. No URI at all is a dynamic error.
  - What the query maps hold is abstract (`Query`): only the shape of the query string reaches the target's origin.
- **The page** is `window.location`: an `http(s)` URL with a non-empty authority, a path, and no newline.
- **The pane's base:** a pane is created for a document when no pane shows it or its origin. If the document's
  response has a `Link` with rel `lds:dataspace`, the pane's base is the document's own origin, whatever the link
  names. `lds:base()` reads the active pane's base, and falls back to the page's origin.
- **The request sites:** every `'href'` entry of a request map in `client.xsl` and `client/`. A site built by
  `ldh:href` is covered by `href_same_origin`. The other nine are listed in `Sites.lean`, each with how it builds
  its target:
  - `again`: a target an `ldh:href` built earlier, passed on.
  - `shell`: a path on the page's origin.
  - `localOrHref`: the TimeMap a response linked to, as it is when `ldh:is-local`, else through `ldh:href`, which
    would rebuild a local `?timemap` as `?timemap=`.

  `Target` keeps two more kinds, which no site is today: `base`, a path on `lds:base()` with no `ldh:href`, and
  `given`, a URI the page or a response carried, used as it is. A site of either kind leaves the page's origin with
  its base or its URI, and `unbounded_sites` fails when one appears.
- **The version history:** a restore writes the document the active pane shows, and reads its modes, its TimeMap
  and the version, through `ldh:href`.
- **The window:** an external `http(s)` document answered with a status from 400 on, other than 401, 403 and 429,
  is opened as the document's URI says. On a page loaded with `?uri=`, that URI is the parameter.

## Mapping to the code

| Lean | Code |
|------|------|
| `origin` | `lds:origin` (`imports/default.xsl`) |
| `absPath`, `docUri`, `buildUri` | `ac:absolute-path`, `ac:document-uri`, `ac:build-uri` (Web-Client's `functions.xsl`) |
| `isLocal`, `href` | `ldh:is-local`, `ldh:href` (`imports/default.xsl`) |
| `Page` | `ldh:request-uri` (`client/functions.xsl`) |
| `tabBase`, `newPane` | `$application`, `$tab-base` and `$reuse-pane` in `ldh:rdf-document-response` (`client.xsl`) |
| `base` | `lds:base` (`client/functions.xsl`) |
| `Target.shell` for the assistant | `ldh:chat-href` (`client/chat.xsl`) |
| `sites` | the request maps in `client.xsl` and `client/`, as `sites.py` reads them |
| `pageDoc` | `ac:uri` (`client/functions.xsl`), the `doc-uri` of the first `ldh:DocumentNavigate` (`client.xsl`) |
| `fallback` | the `?status ge 400` branch of `ldh:rdf-document-response` (`client.xsl`) |
| `restoreTarget` | `ldh:history-document` (`client/memento.xsl`) |

The stylesheets are under `src/main/webapp/static/com/atomgraph/linkeddatahub/xsl/`. `tracks-code.sh` tracks
`ldh:href`, `ldh:is-local`, `lds:origin`, `lds:base`, `ldh:request-uri`, `ac:uri`, `ldh:chat-href`,
`ldh:history-document`, the three variables, and the branch, each as `xmllint` serializes it. Web-Client's functions live in another repository; the
href cases replay them.

## Results

Proven with no `sorry`, using only the axioms `propext` and `Quot.sound`:

| Theorem | Statement |
|---------|-----------|
| `href_same_origin` | Whatever URI `ldh:href` is given, the target starts with the page's origin and a slash, or is relative to the page. A URI on another origin, `javascript:` included, ends up in `?uri=` |
| `base_local`, `base_confined` | While the active pane's base is on the page's origin, so is `lds:base()`, and so is every site built on it |
| `newPane_local` | A pane created for a document on the page's origin has its base there |
| `shell_confined` | A site on the page's origin stays there |
| `sites_confined`, `localOrHref_same_origin`, `unbounded_sites` | Every request site not built by `ldh:href` stays on the page's origin, whatever pane is active, so every request the client makes does |
| `proxied_link_keeps_chat` | On a proxied page whose document names an `lds:dataspace`, `lds:base()` moves to the document's origin, and the assistant's requests stay on the page's |
| `restore_targets_pane_document` | A version restore on a proxied page writes the document the pane shows, through the proxy, and not the page's path |
| `fallback_web` | The window is sent only to a URL starting with `http://` or `https://`, whatever the document and the status |
| `fallback_is_uri_param` | The window goes to the `http(s)` document `?uri=` names |
| `uri_param_script_refused` | `https://localhost:4443/?uri=javascript:alert(document.domain)` leaves the window where it is, whatever the server answers |

Each of the three below was a counterexample, proven of the code as it was and reproduced on a local instance,
until the fix that turned it into the theorem it names:

- `uri_param_navigates_any_scheme`, now `uri_param_script_refused`: the proxy answered `?uri=javascript:…` 502, the
  client called `window.open('javascript:alert(document.domain)', '_blank')`, and when the browser blocked that popup,
  as it does without a user gesture, `alert` ran on the dataspace's origin. The branch now opens only `http(s)`, and
  `ApplicationFilter` refuses a `?uri=` that is not `http(s)` with 400.
- `proxied_link_moves_base`, now `proxied_link_keeps_chat`: the proxy forwards the origin's `Link` headers as they
  are (`ProxyRequestFilter.overlayHeaders`), so a proxied document names the `lds:dataspace` that moves `lds:base()`,
  and the assistant posted the question, the document, the endpoint and the last turns to that origin's
  `/webalgebra`. Proxying another LinkedDataHub instance moved the pane's `data-base` to its origin. The ontology
  import's query and the namespace `clear` were built on `lds:base()` with no `ldh:href` too. `lds:base()` still
  moves, which is what lets a proxied dataspace be browsed: the sites built on it go through `ldh:href`, and the
  assistant resolves against the page's origin.
- `restore_targets_page_path`, now `restore_targets_pane_document`: the history read the access modes of the page's
  path and wrote the restored version there. On a proxied page that is the dataspace's root, which the owner may
  write, so the History link a remote's `Link: rel="timemap"` turned on offered Restore, and Restore put the remote's
  version over the root. Reproduced with routes standing in for the remote: `PUT https://localhost:4443/`. The
  TimeMap and the version were requested from the remote's origin directly.

`tests/ui/specs/axes/uri-scheme.spec.mjs` replays the first and `tests/ui/specs/axes/proxied-dataspace.spec.mjs` the
third, expecting each refused; `tests/http/proxy/GET-proxied-non-http-400.sh` checks the server's half of the first.
The second takes the assistant, which the stacks the suites run on go without, and `sites_confined` holds it: a new site
that bypasses `ldh:href` fails the `sites.py` diff until it is classified, and `unbounded_sites` once it is classified
`base` or `given`.

## Replaying

Two checks hold the model to the stylesheets, and the workflow runs both:

- **The href cases.** `ldh-client href-cases` prints `PAGE<TAB>URI<TAB>PATH` for five pages and 22 URIs, where PATH
  is the target up to its first `?`: the part that decides the origin. `href-cases.tsv` is that output, committed.
  `href-cases.xsl` takes `ldh:href` and the functions it calls out of `imports/default.xsl` and Web-Client's
  `functions.xsl` as they are, compiles them with a `ldh:request-uri` that answers each case's page, and prints the
  same lines. Both have to equal the file:

  ```bash
  .lake/build/bin/ldh-client href-cases | diff href-cases.tsv -
  cd ../.. && java -cp Saxon-HE.jar:xmlresolver.jar net.sf.saxon.Transform -xsl:formal/client/href-cases.xsl -it \
    cases=formal/client/href-cases.tsv web-client=../Web-Client | diff formal/client/href-cases.tsv -
  ```

- **The request sites.** `sites.py` reads every request map's `'href'` entry, follows a variable to its
  declaration, and prints the sites not built by `ldh:href`. `ldh-client sites` prints `Sites.lean`'s list. A site
  added or changed fails the diff until it is classified:

  ```bash
  python3 sites.py ../../src/main/webapp/static/com/atomgraph/linkeddatahub/xsl | diff <(.lake/build/bin/ldh-client sites) -
  ```

## Not modelled

- **The browser's URL parser.** `SameOrigin` says a target starts with the page's origin and a slash, or is
  relative to the page. That the browser then requests the page's origin is the parser's: for an `http(s)` URL the
  slash ends the authority. Likewise, that `window.open` and `location.assign` run a `javascript:` URL is the
  browser's.
- **The server's answer.** `fallback` takes any status, so `fallback_web` holds whatever the server answers: the
  `400` `ApplicationFilter` gives a `?uri=` that is not `http(s)` is defence in depth, not a premise.
- **`resolve-uri`.** The base sites append their relative path to a base that ends in a slash, which is what
  `resolve-uri` does for those paths.
- **`document()` and `ixsl:schedule-action`'s `document` attribute.** Only request maps are sites. The client's
  `document()` calls are not classified.
- **Query strings.** `ldh:url-decode`, `encode-for-uri` and the order of map entries never reach PATH.
