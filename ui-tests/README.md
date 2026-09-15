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

## Projects

The same specs run twice, as `owner` (holding the WebID client certificate) and as
`anonymous`. That is the authorization axis: "no edit pencil for anonymous" is a test
rather than a separate script. A spec that only makes sense for one of them says so
itself.

The owner context carries the certificate for **both** origins, end-user and admin. The
end-user page issues XHR against the admin origin while it loads, so a context holding
only the first authenticates half the page.

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
