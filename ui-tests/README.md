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

The SEF check is local-only by construction: `target/ROOT/…` exists exactly when
`docker-compose.override.yml` is bind-mounting the working tree over the image. CI builds
the SEF into the image, finds no local file, and the check stands down on its own.

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
