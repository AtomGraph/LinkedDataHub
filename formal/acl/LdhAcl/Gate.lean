/-
The graph store's answer behind the authorization decision: the decision first, then `LdhHttp.answerB`.

Three theorems hold of the two together and of neither alone: a request is answered `403` exactly when the decision
denies it (`decide_forbidden_iff`), so a denied agent learns nothing a later check would say; a request that goes
through is a `Step`, an authorized `Write` (`decide_step`); and so the server keeps the invariants, including the
typing of admin documents the decision's class grants depend on (`decide_inv`).
-/
import LdhAcl.Decide

namespace LdhAcl

open LdhHttp

/-- The server's answer: the decision first, and nothing else for a request it denies. -/
def decideB (fsite : FinSite) (fs : FinStore) (fa : FinAdmin) (agent : Option Node) (pc : Precond) (req : HReq) :
    Except Refusal (Success × FinStore) :=
  if allowRequestB fsite fs fa agent (req.method pc) req.target then answerB fsite.toHSite fs agent pc req
  else .error .forbidden

/-- The status and the store after the request. -/
def serveB (fsite : FinSite) (fs : FinStore) (fa : FinAdmin) (agent : Option Node) (pc : Precond) (req : HReq) :
    Nat × FinStore :=
  match decideB fsite fs fa agent pc req with
  | .ok (s, fs') => (s.code, fs')
  | .error r => (r.code, fs)

/-- **A refused request changes nothing.** -/
theorem serve_refused {fsite fs fa agent pc req r} (h : decideB fsite fs fa agent pc req = .error r) :
    serveB fsite fs fa agent pc req = (r.code, fs) := by
  simp [serveB, h]

/-- **`403` is the decision's, and only the decision's.** A request is answered `403` exactly when the model
denies it, and a denied request learns nothing else: not whether the document exists, nor anything a later check
would have said about it. -/
theorem decide_forbidden_iff {site : Site} {fsite : FinSite} (h : fsite.agrees site) {fs fa agent pc req} :
    decideB fsite fs fa agent pc req = .error .forbidden ↔
      ¬ allowRequest site fa.reader fs.toStore agent (req.method pc) req.target := by
  rw [allowRequest_iff h]
  constructor
  · intro hd ha
    simp only [decideB, ha, if_true] at hd
    exact answer_not_forbidden hd
  · intro hn
    simp [decideB, hn]

/-- **A request that goes through is an authorized write, or changes nothing.** -/
theorem decide_step {site : Site} {fsite : FinSite} (h : fsite.agrees site) (ht : fsite.toHSite.agrees site.toTree)
    {fs : FinStore} {fa : FinAdmin} {agent : Option Node} {pc : Precond} {req : HReq} {s : Success} {fs' : FinStore}
    (hown : OwnGraphContainment fs.toStore) (hd : decideB fsite fs fa agent pc req = .ok (s, fs')) :
    fs' = fs ∨ ∃ r, Step site fa.reader agent fs.toStore r fs'.toStore := by
  unfold decideB at hd
  split at hd
  · rename_i ha
    have ha := (allowRequest_iff h _ _).2 ha
    rcases answer_write ht hown hd with rfl | ⟨r, ⟨htg, hm⟩, hw⟩
    · exact Or.inl rfl
    · refine Or.inr ⟨r, ⟨?_, hw⟩⟩
      rw [htg]
      rcases hm with hm | ⟨hp, hm⟩
      · rw [hm]; exact ha
      · rw [hm]; rw [hp] at ha; exact ha
  · cases hd

/-- **The server keeps the invariants.** Every answer leaves the containment invariants, and the typing of
documents and of admin documents, as it found them. -/
theorem decide_inv {site : Site} {fsite : FinSite} (h : fsite.agrees site) (ht : fsite.toHSite.agrees site.toTree)
    {fs : FinStore} {fa : FinAdmin} {agent : Option Node} {pc : Precond} {req : HReq} {s : Success} {fs' : FinStore}
    (hinv : Inv site.toTree fs.toStore) (hd : decideB fsite fs fa agent pc req = .ok (s, fs')) :
    Inv site.toTree fs'.toStore ∧ (AdminTyped site fs.toStore → AdminTyped site fs'.toStore) ∧
      (Typed fs.toStore → Typed fs'.toStore) := by
  rcases decide_step h ht hinv.own hd with rfl | ⟨_, hs⟩
  · exact ⟨hinv, id, id⟩
  · exact ⟨hs.inv hinv, hs.adminTyped, hs.typed⟩

end LdhAcl
