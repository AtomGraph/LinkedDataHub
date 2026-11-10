/-
What authentication guarantees, and where it does not.
-/
import LdhAuth.Model

namespace LdhAuth

open LdhHttp

/-! ## The certificate header -/

/-- **A forged `Client-Cert` is inert.** Without the proxy's secret, the request is authenticated the same whatever
certificate and `On-Behalf-Of` it carries: by its ID token, or not at all. -/
theorem forged_cert_inert {env : Env} {s : State} {r : Request} (h : r.fromProxy = false) (c : Option Cert)
    (o : Obo) : authenticate env s { r with clientCert := c, onBehalfOf := o } = authenticate env s r := by
  simp only [authenticate, h, webid, Bool.false_eq_true, if_false]

/-- **`On-Behalf-Of` needs a certificate.** Without one, the header changes nothing. -/
theorem obo_needs_cert {env : Env} {s : State} {r : Request} (h : r.clientCert = none) (o : Obo) :
    authenticate env s { r with onBehalfOf := o } = authenticate env s r := by
  simp only [authenticate, h, webid, ite_self]

/-! ## The WebID and its key -/

theorem keyMatch_hasKey {V : Vocab} {d : Doc} {w : Node} {key : Key} (h : keyMatch V d w key = true) :
    HasKey V d w key := by
  unfold keyMatch at h
  have hm : w ∈ keyRows V d key := by
    rcases hr : keyRows V d key with _ | ⟨x, xs⟩
    · rw [hr] at h; cases h
    · rw [hr] at h
      simp only [List.head?_cons, beq_iff_eq, Option.some.injEq] at h
      subst h
      exact List.mem_cons_self _ _
  simp only [keyRows, List.mem_filterMap] at hm
  obtain ⟨⟨s, p, o⟩, ht, he⟩ := hm
  simp only at he
  split at he
  · rename_i hc
    cases he
    obtain ⟨rfl, hmod, hexp⟩ := hc
    exact ⟨o, ht, hmod, hexp⟩
  · cases he

/-- **The first row only, and it is sound.** `keyMatch` accepts a WebID only when the document gives it the
certificate's key; but it can refuse a WebID the document gives the key to, when another subject's row comes first. -/
theorem first_row_refuses : ∃ (V : Vocab) (d : Doc) (w : Node) (key : Key),
    HasKey V d w key ∧ keyMatch V d w key = false := by
  let V : Vocab := ⟨.iri 0, .iri 1, .iri 2, .iri 3, .iri 4, .iri 5, .iri 6, .iri 7⟩
  let key : Key := ⟨.iri 13, .iri 14⟩
  let d : Doc := [⟨.iri 11, .iri 0, .iri 12⟩, ⟨.iri 10, .iri 0, .iri 12⟩, ⟨.iri 12, .iri 1, .iri 13⟩,
    ⟨.iri 12, .iri 2, .iri 14⟩]
  exact ⟨V, d, .iri 10, key, ⟨.iri 12, by decide, by decide, by decide⟩, by decide⟩

/-- **What a certificate authenticates as.** The WebID of a valid certificate, which `URLValidator` lets through,
whose document (cached or loaded) gives it the certificate's key; and with `On-Behalf-Of`, exactly the principal
named, which `URLValidator` lets through and whose own document (cached or loaded) says the WebID `acl:delegates`
it. One hop: the principal's document is read for the WebID's delegation and nothing else. -/
theorem webid_sound {V : Vocab} {web : Web} {c : Cache} {cert : Option Cert} {obo : Obo} {a : Node}
    (h : (webid V web c cert obo).1 = .ok a) :
    ∃ crt w d, cert = some crt ∧ crt.valid = true ∧ crt.webID = some w ∧ web.internal w = false ∧
      loadWebID V web c w = .ok d ∧ HasKey V d w crt.key ∧
      ((obo = .none ∧ a = w) ∨
        (obo = .uri a ∧ web.internal a = false ∧
          ∃ dp, loadWebID V web (c.put w d) a = .ok dp ∧ Delegates V dp w a)) := by
  unfold webid at h
  rcases cert with _ | crt
  · cases h
  simp only at h
  cases hv : crt.valid
  · simp [hv] at h
  simp only [hv, Bool.not_true, Bool.false_eq_true, if_false] at h
  rcases hw : crt.webID with _ | w
  · simp [hw] at h
  simp only [hw] at h
  cases hi : web.internal w
  case true => simp [hi] at h
  simp only [hi, Bool.false_eq_true, if_false] at h
  rcases hd : loadWebID V web c w with d | _ | e
  · simp only [hd] at h
    cases hk : keyMatch V d w crt.key
    · simp [hk] at h
    simp only [hk, Bool.not_true, Bool.false_eq_true, if_false] at h
    refine ⟨crt, w, d, rfl, hv, hw, hi, hd, keyMatch_hasKey hk, ?_⟩
    rcases obo with _ | _ | p
    · simp only [Out.ok.injEq] at h
      exact Or.inl ⟨rfl, h.symm⟩
    · cases h
    · simp only at h
      cases hp : web.internal p
      case true => simp [hp] at h
      simp only [hp, Bool.false_eq_true, if_false] at h
      rcases hdp : loadWebID V web (c.put w d) p with dp | _ | e
      · simp only [hdp] at h
        by_cases hdel : Delegates V dp w p
        · simp only [hdel, if_true, Out.ok.injEq] at h
          subst h
          exact Or.inr ⟨rfl, hp, dp, hdp, hdel⟩
        · simp [hdel] at h
      · simp [hdp] at h
      · simp [hdp] at h
  · simp [hd] at h
  · simp [hd] at h

/-- **On behalf of a principal, the agent is the principal.** Nothing of the certificate's own agent is left. -/
theorem obo_acts_as_principal {V : Vocab} {web : Web} {c : Cache} {cert : Option Cert} {p a : Node}
    (h : (webid V web c cert (.uri p)).1 = .ok a) : a = p := by
  obtain ⟨_, _, _, _, _, _, _, _, _, ho⟩ := webid_sound h
  rcases ho with ⟨ho, _⟩ | ⟨ho, _⟩
  · cases ho
  · cases ho; rfl

/-- **Any principal that delegates is reachable.** A certificate that authenticates acts for every principal whose
document says its WebID `acl:delegates` it. Signing up and the first OAuth login write
`<secretary> acl:delegates <agent>` into every agent's document, so the secretary can act as any of them; what keeps
the assistant within the caller's rights is that it names the caller, which is no part of this layer. -/
theorem obo_complete {V : Vocab} {web : Web} {c : Cache} {crt : Cert} {w p : Node} {d dp : Doc}
    (hv : crt.valid = true) (hw : crt.webID = some w) (hi : web.internal w = false)
    (hd : loadWebID V web c w = .ok d) (hk : keyMatch V d w crt.key = true) (hp : web.internal p = false)
    (hdp : loadWebID V web (c.put w d) p = .ok dp) (hdel : Delegates V dp w p) :
    webid V web c (some crt) (.uri p) = (.ok p, (c.put w d).put p dp) := by
  simp [webid, hv, hw, hi, hd, hk, hp, hdp, hdel]

/-- **Revoking a delegation waits for the cache.** A principal's document in the cache is the one read, whatever its
document now says, until the entry expires (`webIDCacheExpiration`, a day by default). -/
theorem revocation_waits_for_cache {V : Vocab} {web : Web} {c : Cache} {p : Node} {dp : Doc} (h : c p = some dp) :
    loadWebID V web c p = .ok dp := by
  simp [loadWebID, h]

/-! ## Statuses -/

/-- **Authentication never answers `403`.** Its failures are `400`, a `303` to log in again and `500`; `403` stays
the authorization decision's alone (`LdhAcl.decide_forbidden_iff`). -/
theorem auth_never_403 (e : AuthError) : e.code ≠ 403 := by
  cases e <;> decide

/-! ## ID tokens -/

/-- **A token identity needs a verified token.** The agent comes from a token the provider signed, and from the
token in use, its refresh if it had expired, fully verified, dates included: the account model the cache holds for
its issuer and subject, or else the one `userAccountQuery` returns over the dataspace's admin dataset or the root's. -/
theorem token_sound {V : Vocab} {name : Node → String} {admin : String} {fs root : FinStore} {pv : Provider}
    {tc : TokenCache} {t : Token} {a : Node} {tc' : TokenCache} (h : token V name admin fs root pv tc t = .ok (a, tc')) :
    pv.signed t = true ∧ t.hasExp = true ∧ ∃ t', current pv t = .ok t' ∧ pv.verified t' = true ∧
      ∃ m, (tc (admin, name t'.iss, name t'.sub) = some m ∨
              (tc (admin, name t'.iss, name t'.sub) = none ∧ m = accountModelOf V fs root t'.iss t'.sub)) ∧
        accountAgent V m t'.sub = .ok a := by
  unfold token at h
  by_cases hs : (!pv.signed t || !t.hasExp) = true
  · simp [hs] at h
  simp only [hs, if_false] at h
  simp only [Bool.or_eq_true, Bool.not_eq_true', not_or, Bool.not_eq_false] at hs
  refine ⟨hs.1, hs.2, ?_⟩
  rcases hc : current pv t with t' | _ | e
  · simp only [hc] at h
    cases hv : pv.verified t'
    · simp [hv] at h
    simp only [hv, Bool.not_true, Bool.false_eq_true, if_false] at h
    refine ⟨t', rfl, hv, ?_⟩
    rcases hk : tc (admin, name t'.iss, name t'.sub) with _ | m
    · simp only [hk] at h
      refine ⟨_, Or.inr ⟨rfl, rfl⟩, ?_⟩
      split at h
      · cases h
      · cases h
      · rename_i ag hag
        simp only [Out.ok.injEq, Prod.mk.injEq] at h
        rw [← h.1]; exact hag
    · simp only [hk] at h
      refine ⟨m, Or.inl rfl, ?_⟩
      split at h
      · cases h
      · cases h
      · rename_i ag hag
        simp only [Out.ok.injEq, Prod.mk.injEq] at h
        rw [← h.1]; exact hag
  · simp [hc] at h
  · simp [hc] at h

/-- **On a cache miss, the agent is an account's `sioc:account_of`, from any admin graph.** `userAccountQuery` finds
an account stated in one graph with the subject, the issuer and an agent; `DESCRIBE` then takes the triples about
the account, and about every agent so found, from every graph, and the agent is a `sioc:account_of` among them. A
graph that says something about an account is admin data, written by the admin role. -/
theorem accountAgent_sound {V : Vocab} {fs : FinStore} {iss sub a : Node}
    (h : accountAgent V (accountModel V fs iss sub) sub = .ok a) :
    ∃ x, (x ∈ (accountRows V fs iss sub).map Prod.fst ∨ x ∈ (accountRows V fs iss sub).map (·.2)) ∧
      ∃ p ∈ fs, ⟨x, V.siocAccountOf, a⟩ ∈ p.2 := by
  unfold accountAgent at h
  split at h
  · cases h
  rename_i x _
  split at h
  · rename_i ag hag
    cases h
    have hm : ⟨x, V.siocAccountOf, a⟩ ∈ accountModel V fs iss sub := by
      apply mem_objects.1
      rcases ho : objects (accountModel V fs iss sub) x V.siocAccountOf with _ | ⟨y, ys⟩
      · rw [ho] at hag; cases hag
      · rw [ho] at hag
        simp only [List.head?_cons, Option.some.injEq] at hag
        subst hag
        exact List.mem_cons_self _ _
    simp only [accountModel, describe, List.mem_flatMap, List.mem_filter, decide_eq_true_eq,
      List.mem_append] at hm
    obtain ⟨p, hp, ht, hx⟩ := hm
    exact ⟨x, hx, p, hp, ht⟩
  · cases h

/-- **An account the dataspace made stands.** When the dataspace's admin dataset has an account for the subject, a
cache miss reads it and not the root's: an agent made before accounts moved to root keeps its grants. -/
theorem legacy_account_first {V : Vocab} {fs root : FinStore} {iss sub : Node}
    (h : hasAccount V (accountModel V fs iss sub) sub = true) :
    accountModelOf V fs root iss sub = accountModel V fs iss sub := by
  simp [accountModelOf, h]

/-- **The agent is the dataspace's or the root's.** On a cache miss, the agent is a `sioc:account_of` stated in the
dataspace's admin dataset or in the root's, and in no other dataspace's: an owner of another dataspace cannot point a
subject's account at an agent of theirs. -/
theorem account_from_own_or_root {V : Vocab} {fs root : FinStore} {iss sub a : Node}
    (h : accountAgent V (accountModelOf V fs root iss sub) sub = .ok a) :
    (∃ p ∈ fs, ∃ x, ⟨x, V.siocAccountOf, a⟩ ∈ p.2) ∨ (∃ p ∈ root, ∃ x, ⟨x, V.siocAccountOf, a⟩ ∈ p.2) := by
  by_cases hl : hasAccount V (accountModel V fs iss sub) sub = true
  · rw [legacy_account_first hl] at h
    obtain ⟨x, _, p, hp, ht⟩ := accountAgent_sound h
    exact Or.inl ⟨p, hp, x, ht⟩
  · simp only [accountModelOf, hl, Bool.false_eq_true, if_false] at h
    obtain ⟨x, _, p, hp, ht⟩ := accountAgent_sound h
    exact Or.inr ⟨p, hp, x, ht⟩

/-! ## A cache entry per dataspace -/

section CrossDataspace

/-- A token every check passes, of subject `iri 21` at issuer `iri 20`. -/
private def tok : Token := ⟨0, .iri 20, .iri 21, true, false, none⟩

private def pv : Provider := ⟨fun _ => true, fun _ => true, fun _ => false, fun _ => none, .iri 30, .iri 31⟩

private def vocab : Vocab := ⟨.iri 0, .iri 1, .iri 2, .iri 3, .iri 4, .iri 5, .iri 6, .iri 7⟩

private def web : Web := ⟨id, fun _ => .unreachable, fun _ => false, fun _ => true⟩

/-- Dataspace A's admin dataset: an account for the subject, of agent `iri 40`. -/
private def adminA : FinStore :=
  [(.iri 50, [⟨.iri 41, .iri 4, .iri 21⟩, ⟨.iri 41, .iri 5, .iri 20⟩, ⟨.iri 41, .iri 6, .iri 40⟩])]

/-- Dataspace B's admin dataset: an account it made for the subject before accounts moved to root, of agent `iri 42`. -/
private def legacyB : FinStore :=
  [(.iri 51, [⟨.iri 43, .iri 4, .iri 21⟩, ⟨.iri 43, .iri 5, .iri 20⟩, ⟨.iri 43, .iri 6, .iri 42⟩])]

private def envOf (admin : String) (agents root : FinStore) : Env :=
  ⟨vocab, web, [pv], fun n => match n with | .iri k => toString k | _ => "", admin, agents, root⟩

private def req : Request := ⟨true, none, .none, some tok, false, .iri 60⟩

private def fresh : State := ⟨fun _ => none, fun _ => none⟩

/-- **A token is authenticated by its own dataspace's accounts.** Dataspace B's admin dataset has no account for the
token, and the request is anonymous there, also once the same token has been used on dataspace A, whose account
model the cache now holds. Until the cache was keyed by the admin dataspace too, B authenticated it as A's agent
until the entry expired (`token_cache_crosses_dataspaces`), and `acl:AuthenticatedAgent` grants on B applied to an
account B never made. -/
theorem token_cache_per_dataspace :
    (authenticate (envOf "a" adminA []) fresh req).1 = .ok (some (.iri 40)) ∧
    (authenticate (envOf "b" [] []) fresh req).1 = .ok none ∧
    (authenticate (envOf "b" [] []) (authenticate (envOf "a" adminA []) fresh req).2 req).1 = .ok none := by
  refine ⟨rfl, rfl, rfl⟩

/-- **A root account is recognised on every dataspace.** With the subject's account in the root admin dataset, a
dataspace whose own admin dataset has none authenticates the token as the root's agent; one that made an account for
the subject before accounts moved to root authenticates it as that account's agent. -/
theorem root_account_everywhere :
    (authenticate (envOf "b" [] adminA) fresh req).1 = .ok (some (.iri 40)) ∧
    (authenticate (envOf "b" legacyB adminA) fresh req).1 = .ok (some (.iri 42)) := by
  refine ⟨rfl, rfl⟩

end CrossDataspace

end LdhAuth
