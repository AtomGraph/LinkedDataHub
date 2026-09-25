# ui-tests

Playwright suite driving the LinkedDataHub browser UI. Where [`http-tests`](../http-tests)
asserts what the API returns, this asserts what the browser ends up showing: the
design-system markup contract, and the interactions that contract implies.

It exists because the checking was already happening and kept being thrown away — eight
recent commits report Playwright runs ("20/20 against `/admin-units/36/`", "27 checks
green as owner") from scripts that lived in a scratch directory and were deleted with it.

## Run it

```bash
make ui-tests-install     # once: the runner and its browser
make ui-tests             # builds the CLI, then drives the stack
npm run report            # open the HTML report of the last run
```

The stack has to be up and serving the build you mean to measure:

```bash
make up                                                          # the whole stack
make sef                                                         # compile client.xsl -> SEF
docker compose restart varnish-frontend varnish-end-user varnish-admin
```

## The preflight

`global-setup.mjs` refuses to run the suite against a stack that would give a misleading
answer. Each check fails with the command that fixes it:

| Check | Why it is there |
| --- | --- |
| The base URL answers | `nginx` fronts every port the suite uses, and is easy to leave stopped |
| `ldh` is on `$PATH` | Fixtures are built with it, the way `http-tests/run.sh` builds its own |
| The **served** SEF matches `target/ROOT` | `/static/` is Varnish-cached per encoding, so a recompiled stylesheet keeps serving stale to browser and `curl` alike. A green run against a stale SEF is worse than a red one |
| A **composed** package SEF is published | A package's rules reach the browser only once its stylesheet has been composed with the platform's and compiled, which happens asynchronously. Until then every page is served the stock stylesheet and a concept page renders no tree at all — the specs would fail as though the feature were missing |

The SEF check is local-only by construction: `target/ROOT/…` exists exactly when
`docker-compose.override.yml` is bind-mounting the working tree over the image. CI builds
the SEF into the image, finds no local file, and the check stands down on its own.

The composed-SEF wait is the opposite: it costs milliseconds on a lived-in dev stack that
composed one long ago, and is the whole difference between green and red on a CI instance
importing the package for the first time. Its key covers the platform build as well as the
import set, so `make sef` invalidates it too — and because the key is digested when the
application starts, recompiling alone is not enough: **restart `linkeddatahub`, not just
the Varnish layers**, or the browser keeps running the stylesheet the app started with. It
polls the taxonomy container rather than the root, because a dataspace's root document is
served the stock stylesheet even where its children get the composed one.

## Fixtures

Seeded into `ui-fixtures/` before the run and removed after, built with `ldh` so the suite
exercises the real API and behaves the same against a virgin CI instance and a lived-in
dev one. It does **not** snapshot and restore the whole dataset the way `http-tests` does —
right for a suite that owns the instance, wrong for one sharing your dev stack.

Every fixture URI is a pure function of its index (`itemUri(7)`), because `globalSetup`
runs in the main process and specs run in workers: a URI a spec needs has to be derivable,
not remembered.

| Variable | Effect |
| --- | --- |
| `UI_TESTS_SKIP_SEED=1` | Reuse whatever is already there — for iterating on one spec |
| `UI_TESTS_KEEP_FIXTURES=1` | Leave the container behind to inspect it in a browser |
| `UI_TESTS_ITEMS=n` | Fewer children (default 25 — enough for a second pager page) |
| `UI_TESTS_TAXONOMY_PACKAGE=uri` | A different taxonomy package to import (default: the bundled taxonomy editor) |

### The taxonomy

`ui-taxonomy/` is seeded separately (`lib/taxonomy.mjs`) because the concept tree belongs
to the SKOS **package**, not to the platform: the column, the hierarchy queries and the
reveal are all the package stylesheet's. So the fixture imports the package when the
dataspace does not already have it, and teardown removes it again — it is the one seeding
step that changes how every document in the dataspace renders, and leaving it behind on an
instance that did not ask for it is not the suite's to do.

Its shape is deliberate rather than illustrative. SKOS lets either end of a hierarchy link
carry it, so each level is asserted from a different side: `coffee` names its own
`skos:broader`, `tea` is reached only because `hot-drinks` names it as `skos:narrower`, and
the two top concepts arrive one from each direction. Depth is deliberate too — `espresso`
sits three hops below the scheme, which is what makes the reveal a walk rather than a
lookup. Polyhierarchy is *not* seeded: `addBroader()` adds a second parent for the one spec
that needs it and returns the undo, because a fixture that stays polyhierarchical changes
what every other spec sees. `seedConcept()` follows the same rule for a concept
the declared shape does not carry — an extra child, or one labelled in a single language —
and `addTriple()`/`removeTriple()` are the same bargain for one triple.

Seeding a concept writes `foaf:primaryTopic` itself, since `ldh create` writes none and the
tree reads the scheme off the topic's `skos:inScheme` — without it the page has no topic and
the tree renders nothing. Each concept also needs `skos:inScheme` in the *same* write: the
package constrains it (`:MissingInScheme`), so a concept seeded without one is refused 422.

## The spec tree

`specs/` mirrors the anatomy of the rendered page, which is already named three emitters deep:
`layout.xsl` owns everything outside the pane, `document.xsl` owns the pane, the action bar and
the content body, `resource.xsl` emits the block card and `client/block/*.xsl` the kinds.

```
specs/
  axes/                     a claim that crosses components, not a component
  controls/                 kit controls with no host of their own (the dropdown)
  document/                 document.xsl - the pane inwards
    action-bar/             create, breadcrumb, mode, overflow, timestamp
    content-aside/          the ldh:ContentColumn slot
    blocks/                 the card shell, kind-agnostic
      view/                 one folder per block kind
  forms/                    the write layer rendered in place
  overlays/                 surfaces mounted outside the document flow
    modal/
  shell/                    layout.xsl - outside the pane
    drawer/
    header/
```

`controls/` is the one region that is not a place on the page. A dropdown menu appears in the
header, in the action bar and in a block head, and behaves identically in all three because they
share one handler — so it is asserted once, and each host's own spec says only what its menu
holds. The rule for which layer such a control belongs to is what it does: a control that writes a
value into a form is a form control and lives under `forms/` (the combobox); a chrome control
lives here.

Two rules decide where a spec goes, and they are what make the tree answer a question a flat
directory cannot: *which components has nobody tested?*

- **A spec lives under the component it asserts *about*, never the one it navigates *through*.**
  `overlays/annotation-dialog` creates an XHTML block to reach `#rdfa-editor-overlay` and then
  asserts ten times on the overlay, so it is an overlay spec — and the XHTML block stays an
  honestly untested component rather than a covered-looking one.
- **A component's specs live in its folder; a leaf component with one spec may be that file.**
  `forms/combobox.spec.mjs` becomes `forms/combobox/*.spec.mjs` the day it has two, and the
  component it belongs to does not change.

`axes/` is the exception the tree needs to stay truthful. `responsive` measures the statement
grid, the chart controls, the address bar and the tab strip at three viewports;
`anonymous-affordances` asserts six write controls across three components. Filing either under
one component would claim coverage of five it happens to touch. The repo already calls these
axes in its own prose, so the folder is the README's vocabulary rather than a catch-all.

Two things that are *not* in the path, because neither is a fact about the component:
which app serves the fixture (`overlays/modal/ontology-import` runs against the admin origin,
`constructor-editor` against both), and who owns the markup (`document/content-aside/concept-tree`
is the SKOS package's, rendered in the platform's slot).

Helpers stay flat in `lib/`, named for the component whose vocabulary they carry. `specs/` is
containment; `lib/` is vocabulary. A helper is reached across regions — a block spec opens the
shell's drawer — so it must not live inside one region's subtree.

## Coverage

A folder cannot represent an absence — git does not track an empty directory — so the components
that have no specs are declared in `coverage/components.mjs`, and `npm run coverage` joins the
three things that together say what is tested: what is declared, which folders hold specs, and
what actually renders on five probe pages (the dataspace root, a container, an item, a concept in
ReadMode, and a result set asked for as a document).

```bash
npm run coverage          # writes out/coverage.md, also attached to the HTML report
```

Each component ends up in one of four states:

| | |
| --- | --- |
| `covered` | a spec in its own folder |
| `covered-below` | only a descendant has one — the region is entered, the component itself is not |
| `GAP` | it renders, and nothing asserts it |
| `unprobed` | it renders on no probe page, so its coverage is unknowable until a fixture shows it |
| `grouping` | a node that only nests others — its children are its coverage, and it owes no spec |

That last state is the one worth reading twice. A `ldh:ResultSetChart` is data until something
puts it in the document's `rdf:_N` list, so the fixture's chart once existed in the graph and
rendered nowhere, and a spec waited 30s for `.chart-controls` that could never appear. `unprobed`
is that condition, named: not "untested" but "not yet visible to the suite at all".

The inventory lives in `coverage/`, not in `lib/`, and a spec that imports from it fails the run.
A `selector` there answers *did this component render* and nothing else; the moment a spec wants
one, it has found a locator too specific to be shared, and it belongs inline at the assertion.
A platform component's class must be **emitted by some stylesheet**, and that is asserted — it
keeps a class styled in `app.css` and rendered by nothing (`.ldh-nblock`, `.ldh-query-block`,
`.ldh-auth`, `.ldh-rdf-type`) out of the inventory, where it would print a permanent gap for a
component that does not exist. A package's components are exempt, because a package's stylesheet
is downloaded by the running platform into a directory it owns and this process may not be able
to read it.

No record names the module it comes from. One field used to, and it earned its removal twice
over: it was wrong in four records (the drawer's tree was declared against `client/tree.xsl`,
which owns the lazy loading, while `client/navigation.xsl` emits the markup), and asserting those
paths broke CI twice — a package copy is mode `0750` and unreadable to the test process on Linux,
while Docker Desktop remaps it to the host user on a Mac, so the same file is readable here and
not there. The check that does the real work searches every stylesheet and never consulted the
field anyway.

A declared component with no spec never fails the run. It is the report's subject.

## Projects

The same specs run twice, as `owner` (holding the WebID client certificate) and as
`anonymous`. That is the authorization axis: "no edit pencil for anonymous" is a test
rather than a separate script. A spec that only makes sense for one of them says so
itself.

The owner context carries the certificate for **both** origins, end-user and admin. The
end-user page issues XHR against the admin origin while it loads, so a context holding
only the first authenticates half the page.

A spec that cannot run without a certificate — it writes, or it is about who you are — carries
the `@owner` tag, on its `describe` where it has one and per test where it does not, and the
`anonymous` project declines to collect it (`grepInvert: /@owner/`). That is deliberately not the
same as skipping: a skip should mean something, and it stopped meaning anything when 141 of 153
tests skipped every run. Two dozen of those were skipping on a reason that was simply **false** —
the fixtures ARE granted to an anonymous reader (`fixtures.readable` is `itemUri(1)`, and the
container and dataspace root are granted beside it), so the breadcrumb, the mode switcher, the
property list, every block kind, the drawer and the footer had been assumed agent-dependent
without anyone measuring it. They are not: they pass anonymously, and now they run that way. The
`test.skip` hooks stay in the tagged specs as a safety net, so a test added without the tag skips
rather than fails.

A third project, `coverage`, is not a test project: it runs `coverage/` rather than `specs/` and
produces the report above. It runs as the owner, because a reader who may not read a document
cannot tell an absent component from a forbidden one.

## Conventions

- **Assert with `expect(locator)`, not after a sleep.** The server sends a pre-rendered
  shell and Saxon-JS rebuilds it in place, so "loaded" and "settled" are different
  moments. Auto-retrying assertions handle that; `settled()` in `lib/settle.mjs` is for
  the cases where the assertion is about *how many* things there are and there is no
  single element to wait for.
- **Import `test` from `lib/console.mjs`, not from `@playwright/test`.** It fails any test
  whose page logged a console error, threw, raised an `alert()`, or made a request that
  came back 4xx/5xx. Saxon-JS failures are otherwise silent. Known-preexisting noise is
  excluded by pattern, with its reason, rather than by loosening the assertion.
- **Never inline the certificate passphrase.** `ownerPassword()` reads
  `secrets/owner_cert_password.txt`.
- **The drawer opens at `clientX` exactly 0.** Its handler tests `$x = 0` rather than a
  threshold, so `mouse.move(2, y)` leaves it shut — with its whole subtree still in the
  DOM, which is how ad-hoc scripts came to assert against a hidden tree without noticing.
  Move to `x: 0` and assert `toBeVisible()` before driving it.
- **Avoid a relative `:has(> …)` inside a `>`-prefixed chained locator.** Playwright
  resolves `locator('> ul > li:has(> div.tree-row)')` to nothing where `'> ul > li'` finds
  25. At the start of a selector `li:has(> …)` is fine; chained after a `>` it is not.
- **Record state that is transient, do not sample it.** The busy cursor is an inline style
  set for the duration of each fetch and reset after it, so polling it races the gaps
  between levels. A `MutationObserver` installed with `addInitScript` collects every
  transition, and the assertion becomes what the claim actually is.
