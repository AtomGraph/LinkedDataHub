/-
The Linked Data proxy's outbound side: the credentials each request it sends for a caller carries, hop by hop.

`Gate.lean` proves what a server does with a delegated request it receives. This is the other end, the instance that
sends one: `ProxyRequestFilter` picks a client for each hop `RedirectingClient` makes, by whether the hop's origin is
one of this instance's dataspaces and by the method the hop uses, and `GraphStoreClient.delegate` adds the caller.
-/
namespace LdhAuth.Proxy

/-- The methods the proxy forwards. -/
inductive Method where
  | get | head | post | put | patch | delete
  deriving DecidableEq, Repr

/-- A read: the methods that go out to a foreign origin anonymous. -/
def Method.isRead : Method → Bool
  | .get | .head => true
  | _ => false

/-- The caller, as the request's `AgentContext` gives it: none, a WebID, or an ID token with the agent of its account. -/
inductive Caller (A T : Type) where
  | anon
  | webID (agent : A)
  | idToken (agent : A) (token : T)

def Caller.agent? {A T : Type} : Caller A T → Option A
  | .anon => none
  | .webID a => some a
  | .idToken a _ => some a

/-- What a request the proxy sends carries: the platform's certificate (`getExternalClient` rather than
`getExternalNoCertClient`), an `On-Behalf-Of` agent, and an ID token cookie. -/
structure Creds (A T : Type) where
  cert : Bool
  obo : Option A
  token : Option T

/-- No certificate, no `On-Behalf-Of`, no token. -/
def anonymous {A T : Type} : Creds A T := ⟨false, none, none⟩

/-- `GraphStoreClient.delegate` for one of this instance's dataspaces: an ID token caller with the token and
`On-Behalf-Of` (`IDTokenDelegationFilter`), a WebID caller with `On-Behalf-Of` (`WebIDDelegationFilter`). -/
def delegate {A T : Type} (c : Creds A T) : Caller A T → Creds A T
  | .anon => c
  | .webID a => { c with obo := some a }
  | .idToken a t => { c with obo := some a, token := some t }

/-- The target of one hop, by whether its origin is one of this instance's dataspaces (`System.matchApp`) and by the
method the hop uses: the `targets` function of `ProxyRequestFilter.filter`. A caller is delegated to this instance's
dataspaces, and to another origin for a write; the ID token goes to this instance's dataspaces only. -/
def target {A T : Type} (caller : Caller A T) (own : Bool) (m : Method) : Creds A T :=
  let delegated := caller.agent?.isSome && (own || !m.isRead)
  let c : Creds A T := ⟨delegated, none, none⟩
  if own then delegate c caller
  else if delegated then { c with obo := caller.agent? }
  else c

/-- The method the next hop uses when the client follows a response with the given status, `none` when the response
is the answer: `RedirectingClient.invoke`. A `303` is followed for any method and continues as `GET` (`HEAD` stays
`HEAD`); `301`, `302`, `307` and `308` are followed for reads only. -/
def follow (m : Method) (status : Nat) : Option Method :=
  if status = 303 then some (if m = .head then .head else .get)
  else if (status = 301 ∨ status = 302 ∨ status = 307 ∨ status = 308) ∧ m.isRead = true then some m
  else none

/-- The methods of the hops a request makes, given the status each hop answers: the first is the request's own. -/
def methods : Method → List Nat → List Method
  | m, [] => [m]
  | m, s :: ss => match follow m s with
    | some m' => m :: methods m' ss
    | none => [m]

/-- The request headers the proxy copies to every hop (`FORWARDED_REQUEST_HEADERS`), among those that say who sends a
request or from where. -/
inductive Header where
  | ifMatch | ifNoneMatch | ifModifiedSince | ifUnmodifiedSince
  | origin | cookie | authorization | onBehalfOf | clientCert
  deriving DecidableEq, Repr

def forwarded : List Header := [.ifMatch, .ifNoneMatch, .ifModifiedSince, .ifUnmodifiedSince]

/-! ## What each hop carries -/

/-- An anonymous caller is proxied anonymous, everywhere. -/
theorem anon_anonymous {A T : Type} (own : Bool) (m : Method) : target (Caller.anon : Caller A T) own m = anonymous := by
  cases own <;> rfl

/-- A read of another origin goes out anonymous, whoever the caller: browsing does not announce the caller. -/
theorem foreign_read_anonymous {A T : Type} (caller : Caller A T) {m : Method} (hm : m.isRead = true) :
    target caller false m = anonymous := by
  simp [target, hm, anonymous]

/-- A write to another origin is delegated: the platform's certificate, `On-Behalf-Of` naming the caller, no token. -/
theorem foreign_write_delegated {A T : Type} {caller : Caller A T} {a : A} (ha : caller.agent? = some a) {m : Method}
    (hm : m.isRead = false) : target caller false m = ⟨true, some a, none⟩ := by
  simp [target, ha, hm]

/-- The ID token goes to this instance's dataspaces only. -/
theorem token_stays_home {A T : Type} {caller : Caller A T} {own : Bool} {m : Method}
    (h : (target caller own m).token.isSome = true) : own = true := by
  cases own
  · cases caller <;> cases m <;> simp_all [target, Caller.agent?, Method.isRead]
  · rfl

/-- `On-Behalf-Of` names the caller and no one else. -/
theorem obo_is_caller {A T : Type} {caller : Caller A T} {own : Bool} {m : Method} {a : A}
    (h : (target caller own m).obo = some a) : caller.agent? = some a := by
  cases caller <;> cases own <;> simp_all [target, delegate, Caller.agent?] <;> split at h <;> simp_all

/-- `On-Behalf-Of` goes with the platform's certificate, which is what the receiving `WebIDFilter` verifies it against
(`LdhAuth.obo_needs_cert`). -/
theorem obo_has_cert {A T : Type} {caller : Caller A T} {own : Bool} {m : Method}
    (h : (target caller own m).obo.isSome = true) : (target caller own m).cert = true := by
  cases caller <;> cases own <;> simp_all [target, delegate, Caller.agent?] <;> split at h <;> simp_all

/-! ## Redirects -/

/-- A write is followed only through a `303`, and continues as `GET`. -/
theorem follow_write {m m' : Method} {s : Nat} (hm : m.isRead = false) (h : follow m s = some m') :
    s = 303 ∧ m' = .get := by
  unfold follow at h
  by_cases hs : s = 303
  · cases m <;> simp_all [Method.isRead]
  · simp_all

/-- A hop the client follows to is a read. -/
theorem follow_read {m m' : Method} {s : Nat} (h : follow m s = some m') : m'.isRead = true := by
  unfold follow at h
  by_cases hs : s = 303
  · simp only [hs, if_true, Option.some.injEq] at h
    subst h; split <;> rfl
  · simp [hs] at h; obtain ⟨_, hr⟩ := h.1; cases h.2; exact hr

/-- Every hop after the first is a read, whatever the request's method and the statuses. -/
theorem redirects_read (m : Method) (ss : List Nat) : ∀ m' ∈ (methods m ss).tail, m'.isRead = true := by
  induction ss generalizing m with
  | nil => simp [methods]
  | cons s ss ih =>
    simp only [methods]
    split
    · next m'' hf =>
      intro m' hm'
      simp only [List.tail_cons] at hm'
      cases ss with
      | nil => simp [methods] at hm'; subst hm'; exact follow_read hf
      | cons s' ss' =>
        have := ih m''
        simp only [methods] at hm' this ⊢
        split at hm'
        · next m3 hf3 =>
          simp only [methods, hf3] at this
          rcases List.mem_cons.mp hm' with rfl | hrest
          · exact follow_read hf
          · exact this m' hrest
        · simp at hm'; subst hm'; exact follow_read hf
    · simp

/-- So a redirect never carries the caller to another origin: each hop after the first, to an origin that is not one of
this instance's dataspaces, goes out anonymous. -/
theorem redirect_foreign_anonymous {A T : Type} (caller : Caller A T) (m : Method) (ss : List Nat) :
    ∀ m' ∈ (methods m ss).tail, target caller false m' = anonymous :=
  fun _ hm' => foreign_read_anonymous caller (redirects_read m ss _ hm')

/-- Why the hop's own method decides: by the request's method, a write the origin answers with `303` would be
delegated on the read it continues as, which is how the proxy behaved before. -/
theorem request_method_delegates_redirect {A T : Type} (a : A) :
    methods .post [303] = [.post, .get] ∧
    target (Caller.webID a : Caller A T) false .post = ⟨true, some a, none⟩ ∧
    target (Caller.webID a : Caller A T) false .get = anonymous := by
  simp [methods, follow, target, Caller.agent?, Method.isRead, anonymous]

/-! ## Headers -/

/-- The caller's `Origin` is not forwarded: a write the page's own origin sends through the proxy reaches the target
with none, which `OriginFilter` lets through, and a cross-origin one is refused before it is forwarded. -/
theorem origin_not_forwarded : Header.origin ∉ forwarded := by decide

/-- Nor are the caller's own credentials: what a hop carries is `target`'s and nothing else. -/
theorem credentials_not_forwarded :
    Header.cookie ∉ forwarded ∧ Header.authorization ∉ forwarded ∧ Header.onBehalfOf ∉ forwarded ∧
    Header.clientCert ∉ forwarded := by decide

end LdhAuth.Proxy
