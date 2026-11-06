# LinkedDataHub XSLT model in Lean

A Lean 4 model of what the stylesheets put into a page from data someone else controls: an XML literal rendered from
a document, an answer the assistant was given, the agent's URI in the bootstrap script, and what a server-side
`document()` reaches. It proves what of it a browser can run, and what the server can be made to read.

The model is a specification. It is not extracted from the stylesheets: each definition is transcribed from the
code listed in the mapping below, and when that code changes, the definition changes in the same commit.

## Building

```bash
cd formal/xslt
lake build
```

Lean `v4.15.0` (pinned in `lean-toolchain`), core library only, with no Mathlib. The model stands alone.

The `Formal` workflow builds it on every push, fails on a `sorry`, and replays it against the stylesheets (see
"Replaying"). On a pull request it also runs `tracks-code.sh`, which fails when a declaration listed under "Mapping
to the code" changes without a change in this directory:

```bash
formal/xslt/tracks-code.sh origin/develop
```

## Files

| File | Contents |
|------|----------|
| `LdhXslt/Url.lean` | The scheme of a URL as the browser reads it and as `ldh:url-scheme` does, and why the two agree |
| `LdhXslt/Sanitize.lean` | XML trees, what a browser runs in one, the rendering rules, and why nothing they render runs |
| `LdhXslt/Canonical.lean` | The editor's canonical form, rules S1-S3, and why nothing they leave runs |
| `LdhXslt/Chat.lean` | The assistant's answer allowlist, and why nothing it keeps runs |
| `LdhXslt/Bootstrap.lean` | The JavaScript string literal the agent's URI is written into, and why a URI cannot leave it |
| `LdhXslt/Resolver.lean` | What a server-side `document()` reaches |
| `Main.lean` | `ldh-xslt`: the sanitize cases and the canonical form's former counterexamples, for the workflow |
| `sanitize-cases.tsv` | The sanitize cases, as the model renders them |
| `canonical-cases.tsv` | The canonical form's former counterexamples, as the model has it take them out |
| `sanitize-cases.xsl` | Both, as the stylesheets render them |

## The model

**Trees.** An XML literal is a tree of elements and text nodes; each element and attribute has a namespace and a local
name (`Node`, `Attr`). Values are strings XML can hold (`Legal`): below the space, only a tab and the line breaks.

**What the browser runs** (`runs`), stated once as the model's hypothesis about browsers: a `script` element in the
XHTML or SVG namespace or in none (an element in no namespace is an HTML element once the page is served as
`text/html`, which it is); an event handler, an attribute in no namespace whose name starts with `on`; a frame's
`srcdoc`, which runs with the page's origin; and a URL attribute (`href`, `src`, `action`, `formaction`, `poster`,
`background`, in any namespace, so `xlink:href` too) whose scheme, as the browser reads it, is `javascript` or
`vbscript`.

**The browser's reading of a scheme** (`browserScheme`) follows the WHATWG URL parser: trim C0 controls and spaces from
both ends, remove every tab and line break, then read a letter followed by letters, digits, `+`, `-` and `.` up to
the first `:`. `ldh:url-scheme` (`xsltScheme`) removes tabs and line breaks and trims leading spaces, which is all an
XML string leaves to do.

**The rendering rules** (`sanitize`) are the templates `ldh:XHTMLContent` and `ldh:SafeXHTML` share in
`imports/default.xsl`. They take out an element by local name in any namespace when it runs script, styles the page,
loads a plugin, retargets or refreshes the page, or animates an attribute (`activeNames`). They take out an
attribute when its name starts with `on` in any case, when it is `srcdoc`, and when it is a URL attribute whose
scheme is `javascript` or `vbscript`, or `data` other than an image's `src`. Everything else is copied. Frames and
forms stay, since the content the deployments render embeds video and holds a contact form.

`ldh:XHTMLContent` renders a block's literal for reading, on the server and in the browser alike; it adds a pilcrow
link to a heading with an `id` (`href="#…"`, a fragment) and wraps a `pre` in a copy control, and resolves a relative
URL in proxy mode, none of which the model includes, since none adds a scheme. `ldh:SafeXHTML` fills the editor's
live region (`imports/values.xsl`), where before the stored literal was copied in as it was, so a handler ran when
the editor opened.

**The canonical form** (`canonical`) is the editor's `cm:canonical` pass, rules S1-S3: the ones that take content out.
`rdfa-editor/` is a copy kept byte-identical with its upstream, AtomGraph/RDFa-Editor, where its three gaps were
closed. Its S1 now takes elements out by local name in any namespace, and its S2 and S3 take attributes out by the
renderer's rule (`dropAttr`), so the model proves the same of it as of rendering.

**The chat allowlist** (`chat`) is `ldh:ChatAnswer` in `client/chat.xsl`.

**The bootstrap script** (`afterString`) reads a JavaScript double-quoted string from just after its opening quote:
it ends at an unescaped `"`, fails at a line terminator, and skips the character after a backslash. `uriChar` is a
character a `java.net.URI` can hold.

**The resolver** (`resolve`) is `SameSiteSourceResolver.resolve` over Web-Client's `RDFSourceResolver.resolve`: a
cached or mapped graph is read from the repository, an `http(s)` URI is fetched when it is same-site and empty
otherwise, and what the parent answers `null` for is empty.

## Mapping to the code

Paths are relative to `src/main/webapp/static/com/atomgraph/linkeddatahub/xsl/`, Java to
`src/main/java/com/atomgraph/linkeddatahub/`.

| Model | Code |
|-------|------|
| `sanitize`, `activeNames`, `dropAttr`, `dataImage` | `imports/default.xsl`: the templates in mode `ldh:SafeXHTML`, which mode `ldh:XHTMLContent` shares |
| `xsltScheme` | `imports/default.xsl`: `ldh:url-scheme` |
| the editor's region | `imports/values.xsl`: `*[@rdf:parseType = 'Literal']/xhtml:*` in mode `ac:FormControl` |
| `canonical`, `s1Names` | `rdfa-editor/canonical-xhtml.xsl`: S1, S2 and S3 in mode `cm:canonical`, and `cm:url-scheme` |
| `chat`, `chatKept`, `chatDropped`, `httpHref` | `client/chat.xsl`: the templates in mode `ldh:ChatAnswer` |
| `afterString`, `uriChar` | `layout.xsl`: the `contextUri` and `agentUri` values written with `disable-output-escaping` |
| `resolve`, `parentResolve`, `resolvingUncached` | `writer/impl/SameSiteSourceResolver.java`, and Web-Client's `RDFSourceResolver.resolve` |

`tracks-code.sh` holds the model to each of these, declaration by declaration; Web-Client's resolver is outside this
repository, and the model takes the part of it the override relies on: that `null` is its answer for a scheme other
than `http` and `https`.

## Results

Proven with no `sorry`, using only the axioms `propext` and `Quot.sound`:

| Theorem | Statement |
|---------|-----------|
| `scheme_agrees` | On every value XML can hold, `ldh:url-scheme` reads the scheme the browser does |
| `sanitize_inert` | Nothing an XML literal renders to runs, whatever was stored |
| `sanitize_faithful` | A literal holding none of what the rules name renders as it was stored |
| `text_inert` | A text node renders as itself, which the serializer escapes |
| `canonical_inert` | Nothing the editor's canonical form leaves runs, whatever was pasted or typed |
| `canonical_takes_them_out`, `sanitize_takes_them_out` | The canonical form and rendering both take out a script in the SVG namespace, `java&#9;script:`, and an SVG link's `xlink:href` |
| `chat_inert` | Nothing an assistant's answer renders to runs, whatever the model wrote |
| `bootstrap_closed` | A value of URI characters ends the bootstrap's string literal at its closing quote, and holds neither `<` nor `>` |
| `parent_hands_back` | Web-Client's resolver hands a URI that is not cached, mapped or `http(s)` back to Saxon |
| `resolve_confined` | The platform's resolver hands nothing back to Saxon, and fetches only a same-site `http(s)` URI |

Three findings were reproduced against the code as it was, and are fixed with the model:

- Behind `sanitize_inert`: `ldh:XHTMLContent` was an identity copy, so a literal rendered
  as it was stored, and the editor's canonical form was all that kept the active parts out, for literals saved
  through the editor only. A writer of a document who PUT or PATCHed a literal, or imported one, put a script on a
  page the owner reads; and a proxied document's literal ran on the proxying dataspace's origin with nothing
  written at all. The canonical form, besides, kept the three counterexamples below. Rendering now takes the active
  parts out itself, and the editor's region renders through the same rules: it had copied the literal in, so a
  handler ran when the editor opened. Reproduced by replaying the sanitize cases against the stylesheet as it was:
  `script`, `svg:script`, `onerror`, `javascript:` and `srcdoc` all came out as they went in.
- Behind `resolve_confined`, with `parent_hands_back` still true of Web-Client's resolver: a stored resource naming a `file:` or `jar:http:` URI made the
  server read that file, or fetch directly past the egress proxy, when the page looked up its label (Web-Client's
  `ac:object-label` calls `doc-available()` on the resource's document). Reproduced by
  `SameSiteSourceResolverTest` against the resolver as it was: the stylesheet read the server's file, and
  `jar:http:` made two requests that did not go through the proxy.

`tests/http/document-hierarchy/GET-html-xhtml-inert.sh` writes a literal with each active part straight to a
document and checks the server-rendered page has none of them and keeps the rest;
`writer/impl/SameSiteSourceResolverTest` checks the resolver.

- Behind `canonical_inert`: the canonical form's S1 matched script in the XHTML namespace only, and S3 read the scheme
  after `normalize-space` and matched `@href` in no namespace only, so it kept a script in the SVG namespace,
  `java&#9;script:` and an SVG link's `xlink:href` (`canonical_keeps_svg_script`, `canonical_keeps_split_scheme`,
  `canonical_keeps_xlink_href`, proven of the stylesheet as it was, and replayed against it). Closed upstream
  (AtomGraph/RDFa-Editor `fix/sanitize-any-namespace`, with a fixture of the three) and copied in unchanged.

## Replaying

The rendering rules are replayed against the stylesheet: `ldh-xslt sanitize-cases` prints thirty literals, each
with what the model renders it to, and `sanitize-cases.xsl` renders the same literals with the templates taken from
`imports/default.xsl` as they are. The workflow diffs both against `sanitize-cases.tsv`:

```bash
formal/xslt/.lake/build/bin/ldh-xslt sanitize-cases | diff formal/xslt/sanitize-cases.tsv -
java -cp Saxon-HE.jar:xmlresolver.jar net.sf.saxon.Transform -xsl:formal/xslt/sanitize-cases.xsl -it \
  cases=formal/xslt/sanitize-cases.tsv which=sanitize | diff formal/xslt/sanitize-cases.tsv -
```

The cases cover each rule and the spellings that get past a weaker one: a script in no namespace, `ONCLICK`,
`java&#9;script:`, a leading line break, `xlink:href`, `data:` in a link and in an image, a frame's `srcdoc`, a form's
`action` and a button's `formaction`; and what has to stay: `javascript:` in a query string or a path, a fragment,
an embedded video, a form posting to the instance, inline style, and markup quoted in a `pre`.

The canonical form's former counterexamples are replayed the same way, with `which=canonical`, which runs the whole
canonical form (`cm:canonical-xhtml`, both passes, with the content model) on each literal as the editor's region
content. Its other rules leave what S1-S3 leave of them, so the model's partial transcription and the stylesheet
print the same. That the other rules add nothing that runs - they rename, unwrap and wrap elements, and strip
attributes - is assumed, not proven.

## Not modelled

- What else a browser runs. `runs` names script elements, handlers, `srcdoc` and script URLs; a vector outside it
  (a browser-specific attribute, a future element) is outside the theorem. The rules take out more than `runs` names,
  `style` and plugins among them, so the margin is wider than the theorem.
- Markup that runs nothing but misleads: a form posting elsewhere, an embedded frame, styling that covers the page.
  Frames and forms are kept on purpose, and a frame on another origin cannot reach the page.
- How a page parses as HTML. The serializer is taken to escape text and attribute values, which Saxon's does; the
  page's JSON-LD is written by `xml-to-json`, which escapes `</` as `<\/`, so stored text cannot end that script.
- Values a deployment configures rather than a caller: the location mapping and the client stylesheet's location,
  also written into the bootstrap script with escaping disabled.
- Web-Client's `unparsed-text()` resolver, which goes through the platform's client.
