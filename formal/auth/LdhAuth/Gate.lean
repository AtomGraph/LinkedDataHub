/-
The server's answer with authentication in front: the request filters establish the agent, then the authorization
decision and the graph store answer for it (`LdhAcl.serveB`).

Roadmap step 5 asks that what the secretary can do on behalf of a caller be exactly what the caller can do alone,
whatever plan an LLM emitted. Authentication gives that as an identity: a request on behalf of a principal is
authenticated as the principal and nothing else (`authenticate_obo`), and two requests authenticated as the same
agent get the same answer (`delegation_noninterference`). What it does not give is the choice of principal: every
agent's document delegates to the secretary (`obo_complete`), and a delegation is put in force by whoever may write
the principal's document (`delegation_needs_write`).
-/
import LdhAuth.Login

namespace LdhAuth

open LdhHttp LdhAcl

/-- The server's answer: the status, and the store after the request. -/
def serve (env : Env) (s : State) (r : Request) (fsite : FinSite) (fs : FinStore) (fa : FinAdmin) (pc : Precond)
    (req : HReq) : Nat × FinStore :=
  match (authenticate env s r).1 with
  | .error e => (e.code, fs)
  | .ok a => serveB fsite fs fa a pc req

/-- A request that fails authentication changes nothing. -/
theorem serve_unauthenticated {env s r fsite fs fa pc req e} (h : (authenticate env s r).1 = .error e) :
    serve env s r fsite fs fa pc req = (e.code, fs) := by
  simp [serve, h]

/-- **Delegation is non-interference.** Two requests authenticated as the same agent get the same answer to every
request on every store: how the agent was established (its own certificate, a delegate's with `On-Behalf-Of`, an
ID token) leaves no trace in the decision or the graph store. -/
theorem delegation_noninterference {env₁ env₂ : Env} {s₁ s₂ : State} {r₁ r₂ : Request} {a : Option Node}
    (h₁ : (authenticate env₁ s₁ r₁).1 = .ok a) (h₂ : (authenticate env₂ s₂ r₂).1 = .ok a)
    (fsite : FinSite) (fs : FinStore) (fa : FinAdmin) (pc : Precond) (req : HReq) :
    serve env₁ s₁ r₁ fsite fs fa pc req = serve env₂ s₂ r₂ fsite fs fa pc req := by
  simp [serve, h₁, h₂]

/-- **On behalf of a principal, the server answers as the principal.** A request whose certificate authenticates
and which names a principal is authenticated as that principal. A certificate that leaves the request anonymous
(expired, with no WebID, or a document that cannot be reached) hands it to the ID token filters instead. -/
theorem authenticate_obo {env : Env} {s : State} {r : Request} {p a : Node} (hp : r.fromProxy = true)
    (ho : r.onBehalfOf = .uri p) (hw : (webid env.V env.web s.webids r.clientCert (.uri p)).1 ≠ .anon)
    (h : (authenticate env s r).1 = .ok (some a)) : a = p := by
  unfold authenticate at h
  split at h
  · cases h
  simp only [hp, if_true, ho] at h
  split at h
  · rename_i a' c hwc
    simp only [Except.ok.injEq, Option.some.injEq] at h
    rw [← h]
    exact obo_acts_as_principal (by rw [hwc])
  · cases h
  · rename_i c hwc
    exact absurd (by rw [hwc]) hw

/-- **A delegation is put in force by a write of the principal's document.** For a local agent, the document
`loadWebID` reads is the agent's graph in the admin dataset, as the graph store serves it. A triple that graph did
not have and has after an authorized write was written by a request on that document, which the decision allowed:
whoever may write an agent's document may make any WebID its delegate. -/
theorem delegation_needs_write {site : Site} {rd : Reader} {agent : Option Node} {st st' : Store} {req : Req}
    {doc : Node} {t : Triple} (hs : Step site rd agent st req st') (hbefore : ∀ g, st doc = some g → ¬ g t)
    (hafter : ∃ g, st' doc = some g ∧ g t) :
    req.target = doc ∧ allowRequest site rd st agent req.method doc := by
  by_cases htg : req.target = doc
  · exact ⟨htg, htg ▸ hs.authorized⟩
  · obtain ⟨g, hg, ht⟩ := hafter
    rw [hs.frame (Ne.symm htg)] at hg
    exact absurd ht (hbefore g hg)

end LdhAuth
