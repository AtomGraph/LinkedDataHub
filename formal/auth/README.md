# LinkedDataHub authentication model in Lean

A Lean 4 model of how LinkedDataHub establishes the agent a request is made by: the WebID filter with its cache and
`On-Behalf-Of` delegation, the ID token filters, and the OAuth callback's first login. It proves what each
guarantees and where each does not. The agent is the authorization decision's input, so this model builds on the
ACL model in [`../acl/`](../acl/), which it requires by path, and puts authentication in front of that model's answer.

The model is a specification. It is not extracted from the Java: each definition is transcribed from the code listed
in the mapping below, and when that code changes, the definition changes in the same commit.

## Building

```bash
cd formal/auth
lake build
```

Lean `v4.15.0` (pinned in `lean-toolchain`), core library only, with no Mathlib.

`lake build` builds the graph store and ACL models first. The `Formal` workflow builds every model on every push,
fails on a `sorry`, and on a pull request runs `tracks-code.sh`, which fails when a source listed under "Mapping to the
code" changes without a change in this directory. `web.xml` counts only through the three queries the mapping names.
Run it locally against the branch point:

```bash
formal/auth/tracks-code.sh origin/develop
```

## Files

| File | Contents |
|------|----------|
| `LdhAuth/Model.lean` | The certificate, the web and the WebID cache, the WebID filter, ID tokens and their filters, and the filter chain |
| `LdhAuth/Theorems.lean` | What the WebID filter and the ID token filters guarantee, and two counterexamples |
| `LdhAuth/Login.lean` | The OAuth callback's first login, and what it links an account to |
| `LdhAuth/Gate.lean` | The server's answer with authentication in front of `LdhAcl.serveB`, and delegation as non-interference |
| `Main.lean` | `ldh-auth`: the WebID filter over a request and WebID documents, for `tests/http/formal/` to replay against the server |

## The model

- **The chain (`authenticate`):** a request matched to an `lds:Dataset` is never authenticated. Otherwise the WebID
  filter runs, then each ID token filter in turn. The first filter that sets an agent ends the chain, and so does
  the first failure. Every failure is answered by an exception mapper (`AuthError`: `400`, a `303` to log in again,
  `500`) or caught, which leaves the request anonymous.
- **The certificate:**
  - `Client-Cert` counts only on a request whose `Proxy-Secret` matches, which nginx sets.
  - Its WebID is the first subjectAltName URI, and only with an RSA key.
  - `URLValidator` must let the WebID through.
  - The WebID's document comes from the cache or is dereferenced. With it comes its `cert:key` document, if the key
    is a URI.
  - The WebID is accepted if the first row of `webIDQuery` over that document is the WebID with the certificate's
    modulus and exponent.
  - The document is cached once the key matches.
- **`On-Behalf-Of`:** the principal's document comes from the cache or is dereferenced. The principal replaces the
  agent if it is the agent, or if its own document says `<agent> acl:delegates <principal>`. That is one hop, with no
  chain. The principal's document is then cached.
- **The web (`Web`):** a dereference returns a document, a status other than 2xx (`400`), a redirect `URLValidator`
  refused (`400`), or nothing (anonymous). A WebID's document is the URI without its fragment.
- **ID tokens:**
  - **Trusted checks:** the two checks `JWTVerifier` makes are each provider's functions, and the model trusts what
    they check. `signed` covers the algorithm, the signature, the issuer and the audience. `verified` adds the dates.
  - **Expiry:** a signed token with `exp` is used as it is or, once expired, refreshed. A refresh needs a refresh
    token stored for the subject; without one, the filter answers `303`.
  - **The token in use must be verified.**
  - **The cache:** the account's model comes from the token cache, keyed by the admin dataspace, the issuer and the
    subject, or else from `userAccountQuery` over that dataspace's admin dataset.
  - **The agent** is the `sioc:account_of` of the resource with the subject as `sioc:id`.
- **The first login (`login`):**
  - A subject with no account gets an account of its own.
  - That account is linked to the agent whose `foaf:mbox` is the token's email, if there is one and the provider
    verified the address (`email_verified`), and to a new agent if not. An unverified address counts as none.
- **The server's answer (`Gate.lean`):** a request that fails authentication is answered with the failure's status
  and changes nothing. Otherwise it gets `LdhAcl.serveB` for the agent.

## Mapping to the code

| Lean | Code |
|------|------|
| `authenticate` | `AuthenticationFilter.filter`, the filters' priorities in `Application` |
| `Request.fromProxy`, the `cert` of `authenticate` | `ProxiedWebIDFilter.filter`, `isProxySecret`, `getWebIDCertificate` |
| `Cert` | `WebIDFilter.getWebIDURI`, `checkValidity` |
| `webid` | `WebIDFilter.authenticate(ContainerRequestContext)` |
| `keyRows`, `keyMatch` | `webIDQuery` (`web.xml`), `WebIDFilter.authenticate(Model, URI, RSAPublicKey)` |
| `loadWebID`, `loadFromURI`, `fetchDoc`, `Cache` | `WebIDFilter.loadWebID`, `loadWebIDFromURI`, `webIDModelCache` |
| `Delegates` | the `On-Behalf-Of` branch of `WebIDFilter.authenticate` |
| `Provider.signed`, `Provider.verified` | `JWTVerifier.verifySignature`, `verify` |
| `current` | `IDTokenFilterBase.authenticate`'s expiry branch, `refreshIDToken` |
| `token`, `accountRows`, `describe`, `accountModel`, `accountAgent`, `TokenCache` | `IDTokenFilterBase.authenticate`, `userAccountQuery` (`web.xml`), `oidcModelCache` |
| `tokens` | `IDTokenFilterBase.filter`: the login and authorize URLs it skips |
| `login`, `agentByMbox` | `LoginBase.get`, `userAccountExists`, `findAgentByEmail`, `agentQuery` (`web.xml`); the claims `getUserInfo` gives it (`google/Login`, `orcid/Login`) |
| `AuthError.code` | `InvalidWebIDPublicKeyExceptionMapper`, `WebIDDelegationExceptionMapper`, `WebIDLoadingExceptionMapper`, `InternalURLExceptionMapper`, `TokenExpiredExceptionMapper` |

The filters live in `server/filter/request/` and `server/filter/request/auth/`, the mappers in `server/mapper/auth/`,
`JWTVerifier` in `server/util/` and `LoginBase` and the providers' `Login` in `resource/oauth2/`, all under
`src/main/java/com/atomgraph/linkeddatahub/`.

## Results

Proven with no `sorry`, using only the axioms `propext` and `Quot.sound`:

| Theorem | Statement |
|---------|-----------|
| `forged_cert_inert` | Without the proxy's secret, a request is authenticated the same whatever certificate and `On-Behalf-Of` it carries |
| `obo_needs_cert` | Without a certificate, `On-Behalf-Of` changes nothing |
| `webid_sound` | A certificate authenticates as its WebID only when the WebID's document gives it the certificate's key; with `On-Behalf-Of`, as exactly the principal, whose own document delegates to the WebID |
| `first_row_refuses` | Only the first key row is read: a document that gives the WebID its key can still be refused, never the other way round |
| `obo_acts_as_principal`, `authenticate_obo` | A request on behalf of a principal is authenticated as the principal, unless its certificate gave no identity at all and the ID token filters took over |
| `obo_complete` | A certificate that authenticates can act for every principal whose document delegates to it, which signing up arranges for the secretary and every agent |
| `revocation_waits_for_cache` | A cached principal's document is the one read, whatever the document now says |
| `auth_never_403` | Authentication answers `400`, `303` or `500`, never `403`: that status stays the decision's (`LdhAcl.decide_forbidden_iff`) |
| `token_sound` | A token identity needs a signed token and, after any refresh, a verified one: the agent comes from the cached model for its issuer and subject, or from `userAccountQuery` |
| `accountAgent_sound` | On a cache miss, the agent is the `sioc:account_of` of a bound account, as any admin graph states it |
| `token_cache_per_dataspace` | A token is authenticated by its own dataspace's accounts: one used on another dataspace first leaves it anonymous where no account was made for it |
| `unverified_email_ignored` | A first login whose provider has not verified the address it claims writes what a login with no address writes |
| `verified_email_links` | A first login whose provider verified the address links the account to the agent with that `foaf:mbox` |
| `serve_unauthenticated` | A request that fails authentication changes nothing |
| `delegation_noninterference` | Two requests authenticated as the same agent get the same answer to every request, however the agent was established |
| `delegation_needs_write` | A delegation is put in force by an authorized write of the principal's document |

Two of these were counterexamples, proven of the code as it was, until the fix that turned each into the theorem it
names:

- `token_cache_crosses_dataspaces`, now `token_cache_per_dataspace`: the cache was keyed by the issuer and subject
  alone, so the account model one dataspace's admin dataset gave a token authenticated it on every other dataspace
  until the entry expired, and `acl:AuthenticatedAgent` grants there applied to an account they never made. The key
  is now the admin dataspace's base URI, the issuer and the subject, a tuple: `cacheKey_inj`, which said when the
  concatenated key was unambiguous, has nothing left to state.
- `email_link_takeover`, now `unverified_email_ignored`: a first login linked the new account to the agent whose
  `foaf:mbox` the provider's email claim named, whether or not the provider had verified it, and Google's claims did
  not even carry `email_verified`, a boolean that `getUserInfo` dropped. An unverified address is now no address: it
  links nothing, and it becomes no new agent's `foaf:mbox`, which a later verified login would link to.

Neither is replayed by the HTTP tests: both take ID tokens a provider signed, and the suite has no provider.

## Delegation (roadmap step 5)

`delegation_noninterference` and `authenticate_obo` together say that on behalf of a caller, the secretary can do
exactly what the caller can do alone, whatever an LLM put in the plan. The request is authenticated as the caller.
From that point on, the decision and the graph store see the caller and nothing of the secretary.

What they do not say is which caller the request names. Two things decide that:

- **The secretary can act as anyone.** Every agent's document says `<secretary> acl:delegates <agent>`
  (`obo_complete`). So the secretary can name any agent, and what keeps a plan within its caller's rights is that
  `/webalgebra` sets `On-Behalf-Of` from the caller's certificate.
- **Anyone who can write a document can grant delegation on it.** Whoever may write an agent's document can make any
  WebID its delegate (`delegation_needs_write`). That is the agent's owner and the admin role.

Scoped `acl:delegates` would narrow the first. Neither is a property of this layer to fix.

## Replaying the model against the server

`ldh-auth` runs the WebID filter on a request and the WebID documents the server would dereference, with a WebID
cache in and out:

```bash
lake build
.lake/build/bin/ldh-auth --doc https://admin.localhost:4443/acl/agents/1/ agent.nt --doc ... \
  --cache cache.nq --cache-out cache-next.nq --request request.tsv
```

A request is `WEBID<TAB>MODULUS<TAB>EXPONENT<TAB>ON-BEHALF-OF`:

- `WEBID` is the certificate's WebID, or `-` for no certificate.
- `MODULUS` is in lower-case hex without leading zeros, and `EXPONENT` in decimal, as `WebIDFilter` binds them.
- `ON-BEHALF-OF` is a URI, `-` for none, or `!` for a value that is not a URI.

The answer is `agent URI`, `anonymous` or the status.

`tests/http/formal/auth-conformance.sh` drives it:

- **Agents:** it signs up two fresh agents.
- **Requests:** it pairs a certificate (none, the owner's, the secretary's, either fresh agent's) with an
  `On-Behalf-Of` value (none, each agent, a document that does not exist, a value that is not a URI).
- **Delegations:** between requests the owner grants and revokes delegations in the fresh agents' documents.
- **The check:** before each request, it fetches every WebID and key document as the server does and asks the model.
  The server's answer has to match: the agent in its `Link: <agent>; rel="…acl#agent"`, anonymous, or the status.
- **The cache:** the model's cache is carried from one request to the next. A revocation the server's cache still
  holds is predicted as the server honours it. Only the fresh agents' documents change, and the server cannot have
  cached them before the test signed them up.
- **Replay:** `AUTH_CONFORMANCE_SEED` replays a scenario.

The ID token path is not replayed. It needs a provider's signed tokens.

## Not modelled

- **What the token checks check:** the JWT's algorithm, signature, issuer, audience and dates. They are auth0's and
  the provider's, behind `Provider.signed` and `Provider.verified`.
- **The nonce:** it is generated by the authorize redirect and never checked, by the callback or by the filters. In
  the model it is a field of `Token` that no definition reads.
- **Expiry of the caches:** a day for WebID documents (`webIDCacheExpiration`), and the token's lifetime for
  accounts. The model takes each cache as it is when the request arrives.
- **Order:**
  - SPARQL row order and Jena's choice among several values of a property. The model takes document order.
    `first_row_refuses` holds in any order that puts another subject's row first.
  - The order of the Google and ORCID filters, which run at the same priority in an order Jersey does not specify.
    The model takes a list.
- **Literal matching:** `webIDQuery` matches the key's literals by value in Jena's in-memory graph. The model matches
  them as terms, and the replay sends the key as `WebIDFilter` writes it.
- **Writes other than the account:** the agent document, the authorization and the `acl:delegates` the first login
  writes. `login` models only the triples the token path reads.
- **The read-allowed dataspace shortcut and the Linked Data proxy:** both are past authentication, and the ACL
  model's.
