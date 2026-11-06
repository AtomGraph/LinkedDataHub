/-
How the agent is established: the request filters that run before the authorization decision, in their order.

* `ProxiedWebIDFilter` trusts the `Client-Cert` header only on a request whose `Proxy-Secret` matches, which only
  nginx sets.
* `WebIDFilter` takes the certificate's WebID, loads its document (from the cache, or over HTTP), and accepts the
  WebID if the document's first `webIDQuery` row is the WebID with the certificate's key. An `On-Behalf-Of` principal
  then replaces the agent, if the principal's own document says the agent `acl:delegates` it.
* `IDTokenFilterBase`, once per configured provider, reads the `LinkedDataHub.id_token` cookie: a token the provider
  verifies, refreshed if it has expired, names an account by its issuer and subject, and the account names the agent.
* A request matched to an `lds:Dataset` is never authenticated, and the first filter that sets an agent wins.

The agent is the authorization decision's input (`LdhAcl.allowRequest`). Every failure is either answered by an
exception mapper (`AuthError`, never `403`) or caught, which leaves the request anonymous.
-/
import LdhAcl

namespace LdhAuth

open LdhHttp

/-- The vocabulary terms authentication reads, as the nodes the deployment interns them as. -/
structure Vocab where
  certKey : Node
  certModulus : Node
  certExponent : Node
  aclDelegates : Node
  siocId : Node
  laclIssuer : Node
  siocAccountOf : Node
  foafMbox : Node

/-- An RDF document as a fetch or a query returns it: its triples, in the order they come. -/
abbrev Doc := List Triple

/-- The objects of `s p ?o` in a document, in its order. -/
def objects (d : Doc) (s p : Node) : List Node :=
  d.filterMap fun t => if t.s = s ∧ t.p = p then some t.o else none

theorem mem_objects {d : Doc} {s p o : Node} : o ∈ objects d s p ↔ ⟨s, p, o⟩ ∈ d := by
  simp only [objects, List.mem_filterMap]
  constructor
  · rintro ⟨⟨s', p', o'⟩, ht, h⟩
    simp only at h
    split at h
    · rename_i hsp
      cases h
      obtain ⟨rfl, rfl⟩ := hsp
      exact ht
    · cases h
  · intro h
    exact ⟨_, h, by simp⟩

/-! ## What the filters fail with -/

/-- The failures an exception mapper answers. Every other failure is caught, and leaves the request anonymous. -/
inductive AuthError where
  /-- `InvalidWebIDPublicKeyException`: the WebID document's first key row is not the WebID's with the
  certificate's key. -/
  | badKey
  /-- `WebIDLoadingException`: the WebID or key document answered other than 2xx. -/
  | loading
  /-- `WebIDDelegationException`: the principal is not the agent, and its document does not say the agent
  `acl:delegates` it. -/
  | delegation
  /-- `InternalURLException`: `URLValidator` refused a WebID, key or principal URI, or a redirect to one. -/
  | internalUrl
  /-- `TokenExpiredException`: an expired token, and no refresh token stored for its subject. -/
  | tokenExpired
  /-- `InternalServerErrorException`, or a token that does not decode: the token endpoint's answer to a refresh. -/
  | refreshFailed
  /-- `PropertyNotFoundException`: the resource with the token's subject as `sioc:id` has no `sioc:account_of`. -/
  | unlinked
  deriving DecidableEq, Repr

/-- The status each failure is answered with. -/
def AuthError.code : AuthError → Nat
  /- `TokenExpiredExceptionMapper` redirects to the authorize URL: an ID token filter runs only on a dataspace, and
  never on that URL, so the redirect is always made -/
  | .tokenExpired => 303
  | .refreshFailed | .unlinked => 500
  | .badKey | .loading | .delegation | .internalUrl => 400

/-- A filter step's outcome: a value, the anonymous fallback of a caught exception (`return null`), or a failure the
mappers answer. -/
inductive Out (α : Type) where
  | ok (a : α)
  | anon
  | err (e : AuthError)

/-! ## The web, as the WebID filter sees it -/

/-- A dereference through `RedirectingClient`, every hop validated. -/
inductive Fetch where
  | ok (d : Doc)
  /-- A final response other than 2xx. -/
  | refused
  /-- A redirect `URLValidator` refused. -/
  | blocked
  /-- A `ProcessingException`: no response at all. -/
  | unreachable

structure Web where
  /-- The document URI: a WebID or key URI without its fragment. -/
  docOf : Node → Node
  fetch : Node → Fetch
  /-- `URLValidator.validate` refuses the URI: it resolves to an internal address. -/
  internal : Node → Bool
  /-- The node is a URI resource. A `cert:key` that is not one is described in the WebID document itself. -/
  isUri : Node → Bool

/-- `webIDModelCache`: a WebID's document as last loaded, until it expires. Expiry is the environment's: the model
takes the cache as it is when the request arrives. -/
abbrev Cache := Node → Option Doc

def Cache.put (c : Cache) (w : Node) (d : Doc) : Cache := fun y => if y = w then some d else c y

def fetchDoc (web : Web) (u : Node) : Out Doc :=
  match web.fetch (web.docOf u) with
  | .ok d => .ok d
  | .refused => .err .loading
  | .blocked => .err .internalUrl
  | .unreachable => .anon

/-- `loadWebIDFromURI`: the WebID's document, and the document of its `cert:key` if that is a URI. Jena's
`getPropertyResourceValue` returns one of the `cert:key` values; the model takes the first in document order. -/
def loadFromURI (V : Vocab) (web : Web) (w : Node) : Out Doc :=
  match fetchDoc web w with
  | .ok d =>
    match (objects d w V.certKey).head? with
    | some k =>
      if web.isUri k then
        if web.internal k then .err .internalUrl
        else match fetchDoc web k with
          | .ok d' => .ok (d ++ d')
          | .anon => .anon
          | .err e => .err e
      else .ok d
    | none => .ok d
  | .anon => .anon
  | .err e => .err e

/-- `loadWebID`: the cached document, else a fresh load. -/
def loadWebID (V : Vocab) (web : Web) (c : Cache) (w : Node) : Out Doc :=
  match c w with
  | some d => .ok d
  | none => loadFromURI V web w

/-! ## The certificate and its key -/

/-- The certificate's RSA public key, as `webIDQuery` binds it: the modulus as an `xsd:hexBinary` literal of
lower-case hex digits, and the exponent as an `xsd:integer` literal. -/
structure Key where
  modulus : Node
  exponent : Node
  deriving DecidableEq, Repr

/-- What the filter reads of the certificate in the `Client-Cert` header. -/
structure Cert where
  /-- `checkValidity`: the request falls within the validity period. -/
  valid : Bool
  /-- `getWebIDURI`: the first subjectAltName of type URI; `none` without one, or when the key is not RSA, or when
  `new URI(..)` refuses it, each of which leaves the request anonymous. -/
  webID : Option Node
  key : Key

/-- The rows of `webIDQuery` (`SELECT * { ?webid cert:key [ cert:modulus ?mod ; cert:exponent ?exp ] }`, with
`?mod` and `?exp` bound to the key): every `?webid` with a key of the certificate's modulus and exponent. The model
takes them in document order, SPARQL in an order of its own. -/
def keyRows (V : Vocab) (d : Doc) (key : Key) : List Node :=
  d.filterMap fun t =>
    if t.p = V.certKey ∧ ⟨t.o, V.certModulus, key.modulus⟩ ∈ d ∧ ⟨t.o, V.certExponent, key.exponent⟩ ∈ d
    then some t.s else none

/-- The document states that `w` has the key. -/
def HasKey (V : Vocab) (d : Doc) (w : Node) (key : Key) : Prop :=
  ∃ k, ⟨w, V.certKey, k⟩ ∈ d ∧ ⟨k, V.certModulus, key.modulus⟩ ∈ d ∧ ⟨k, V.certExponent, key.exponent⟩ ∈ d

/-- `authenticate(Model, URI, RSAPublicKey)`: the first row only, and only if its `?webid` is the WebID. -/
def keyMatch (V : Vocab) (d : Doc) (w : Node) (key : Key) : Bool := (keyRows V d key).head? == some w

/-- The `On-Behalf-Of` header. -/
inductive Obo where
  | none
  /-- A value `new URI(..)` refuses: caught, so the request is anonymous. -/
  | malformed
  | uri (p : Node)

/-- The principal's document lets `w` act for `p`: `p` is `w`, or `p`'s document says `w acl:delegates p`. -/
def Delegates (V : Vocab) (dp : Doc) (w p : Node) : Prop := w = p ∨ ⟨w, V.aclDelegates, p⟩ ∈ dp

instance {V : Vocab} {dp : Doc} {w p : Node} : Decidable (Delegates V dp w p) := by
  unfold Delegates; infer_instance

/-- `WebIDFilter.authenticate`, in its order of checks: the agent, and the cache after the request. The WebID's
document is cached once its key matches, whatever the `On-Behalf-Of` check then says; the principal's, once it
delegates. -/
def webid (V : Vocab) (web : Web) (c : Cache) (cert : Option Cert) (obo : Obo) : Out Node × Cache :=
  match cert with
  | none => (.anon, c)
  | some crt =>
    if !crt.valid then (.anon, c)
    else match crt.webID with
    | none => (.anon, c)
    | some w =>
      if web.internal w then (.err .internalUrl, c)
      else match loadWebID V web c w with
      | .anon => (.anon, c)
      | .err e => (.err e, c)
      | .ok d =>
        if !keyMatch V d w crt.key then (.err .badKey, c)
        else
          let c := c.put w d
          match obo with
          | .none => (.ok w, c)
          | .malformed => (.anon, c)
          | .uri p =>
            if web.internal p then (.err .internalUrl, c)
            else match loadWebID V web c p with
            | .anon => (.anon, c)
            | .err e => (.err e, c)
            | .ok dp => if Delegates V dp w p then (.ok p, c.put p dp) else (.err .delegation, c)

/-! ## ID tokens -/

/-- An ID token, as the filters read it: its issuer and subject, whether it carries `exp` and whether that is past,
and its `nonce`. What else it is (header, signature, audience) is for a provider's checks. -/
structure Token where
  raw : Nat
  iss : Node
  sub : Node
  hasExp : Bool
  expired : Bool
  nonce : Option Node

/-- One `IDTokenFilter` (Google, ORCID). The two checks are `JWTVerifier`'s and are taken as given: what they check
(RS256, the signature against the provider's JWKS, the issuer, the audience, and for `verified` the dates too) is
auth0's and the provider's, which the model trusts. -/
structure Provider where
  /-- `verifySignature`: the algorithm, the signature, the issuer and the audience, not the dates. -/
  signed : Token → Bool
  /-- `verify`, at the time of the request: `signed`'s checks, and `exp`, `nbf` and `iat`. -/
  verified : Token → Bool
  /-- A refresh token is stored for the subject. `getRefreshToken` is keyed by `sub` alone. -/
  hasRefresh : Node → Bool
  /-- The token endpoint's answer to a refresh: a token, or `none` for an error or one that does not decode. -/
  refresh : Node → Option Token
  /-- The provider's login and authorize URLs, which its filter skips. -/
  loginURL : Node
  authorizeURL : Node

/-- The accounts `userAccountQuery` binds (`GRAPH ?g { ?account sioc:id $id ; lacl:issuer $issuer ;
sioc:account_of ?agent }`), with their agents. -/
def accountRows (V : Vocab) (fs : FinStore) (iss sub : Node) : List (Node × Node) :=
  fs.flatMap fun p => p.2.filterMap fun t =>
    if t.p = V.siocAccountOf ∧ ⟨t.s, V.siocId, sub⟩ ∈ p.2 ∧ ⟨t.s, V.laclIssuer, iss⟩ ∈ p.2 then some (t.s, t.o)
    else none

/-- `DESCRIBE ?account ?agent`: every triple, from every graph, whose subject is a bound account or agent. -/
def describe (fs : FinStore) (rs : List Node) : Doc :=
  fs.flatMap fun p => p.2.filter fun t => t.s ∈ rs

/-- What `userAccountQuery` returns for an issuer and subject. -/
def accountModel (V : Vocab) (fs : FinStore) (iss sub : Node) : Doc :=
  let rows := accountRows V fs iss sub
  describe fs (rows.map (·.1) ++ rows.map (·.2))

/-- `getResourceByPropertyValue(model, sioc:id, sub)`, then that resource's `sioc:account_of`. Both are one of
several in Jena; the model takes the first in the model's order. -/
def accountAgent (V : Vocab) (m : Doc) (sub : Node) : Out Node :=
  match (m.filterMap fun t => if t.p = V.siocId ∧ t.o = sub then some t.s else none).head? with
  | none => .anon
  | some a =>
    match (objects m a V.siocAccountOf).head? with
    | some ag => .ok ag
    | none => .err .unlinked

/-- `oidcModelCache`: an account's model by the admin dataspace it was read from, the issuer and the subject. -/
abbrev TokenCache := String × String × String → Option Doc

def TokenCache.put (c : TokenCache) (k : String × String × String) (m : Doc) : TokenCache :=
  fun y => if y = k then some m else c y

/-- The token in use: the cookie's, or its refresh if it has expired. -/
def current (pv : Provider) (t : Token) : Out Token :=
  if t.expired then
    if pv.hasRefresh t.sub then
      match pv.refresh t.sub with
      | some t' => .ok t'
      | none => .err .refreshFailed
    else .err .tokenExpired
  else .ok t

/-- `IDTokenFilterBase.authenticate`, in its order of checks. -/
def token (V : Vocab) (name : Node → String) (admin : String) (fs : FinStore) (pv : Provider) (tc : TokenCache) (t : Token) :
    Out (Node × TokenCache) :=
  if !pv.signed t || !t.hasExp then .anon
  else match current pv t with
  | .anon => .anon
  | .err e => .err e
  | .ok t =>
    if !pv.verified t then .anon
    else
      let k := (admin, name t.iss, name t.sub)
      let m := match tc k with
        | some m => m
        | none => accountModel V fs t.iss t.sub
      match accountAgent V m t.sub with
      | .anon => .anon
      | .err e => .err e
      | .ok ag => .ok (ag, tc.put k m)

/-! ## The filter chain -/

/-- What the filters read of a request. -/
structure Request where
  /-- `isProxySecret`: the `Proxy-Secret` header is the configured secret. -/
  fromProxy : Bool
  /-- The `Client-Cert` header, parsed; `none` without one or when it does not parse. -/
  clientCert : Option Cert
  onBehalfOf : Obo
  /-- The `LinkedDataHub.id_token` cookie, decoded; `none` without one or when it is not a JWT. -/
  idToken : Option Token
  /-- `ApplicationFilter` matched an `lds:Dataset`: a proxied dataset, which no filter authenticates. -/
  dataset : Bool
  /-- The request's absolute path. -/
  path : Node

/-- Deployment constants. -/
structure Env where
  V : Vocab
  web : Web
  /-- The registered ID token filters, in the order they run. Google and ORCID run at the same priority, in an order
  Jersey does not specify. -/
  providers : List Provider
  /-- The string a node's term is written as: the token cache's key is built from them. -/
  name : Node → String
  /-- The base URI of the request's admin dataspace, which the token cache is keyed by. -/
  admin : String
  /-- The admin dataset of the request's dataspace, which `getAgentService` queries. -/
  agents : FinStore

/-- The caches, shared by every request and every dataspace. -/
structure State where
  webids : Cache
  tokens : TokenCache

/-- The ID token filters, in their order, over the request's path and cookie: the first that sets an agent or fails ends the chain. -/
def tokens (env : Env) (tc : TokenCache) (path : Node) (idToken : Option Token) :
    List Provider → Out (Node × TokenCache)
  | [] => .anon
  | pv :: pvs =>
    if path = pv.loginURL ∨ path = pv.authorizeURL then tokens env tc path idToken pvs
    else match idToken with
    | none => .anon
    | some t =>
      match token env.V env.name env.admin env.agents pv tc t with
      | .anon => tokens env tc path idToken pvs
      | .err e => .err e
      | .ok a => .ok a

/-- The request filters before `AuthorizationFilter`: the agent the request is made by (`none` for anonymous), or
the failure the request is answered with; and the caches after it. -/
def authenticate (env : Env) (s : State) (r : Request) : Except AuthError (Option Node) × State :=
  if r.dataset then (.ok none, s)
  else
    let cert := if r.fromProxy then r.clientCert else none
    match webid env.V env.web s.webids cert r.onBehalfOf with
    | (.ok a, c) => (.ok (some a), { s with webids := c })
    | (.err e, c) => (.error e, { s with webids := c })
    | (.anon, c) =>
      let s := { s with webids := c }
      match tokens env s.tokens r.path r.idToken env.providers with
      | .ok (a, tc) => (.ok (some a), { s with tokens := tc })
      | .err e => (.error e, s)
      | .anon => (.ok none, s)

end LdhAuth
