/-
Entity tags, and what a write guarded by one guarantees.

`EntityTags.entityTag` digests the document's URI and its graph as sorted N-Triples with SHA-256, keeps 128 bits,
and folds in the negotiated variant. The model takes one variant, as the replay negotiates N-Triples throughout, and
the tag as a function of the document and its graph with two properties: it is the graph's, so the order and
repetition of triples do not count (`ETags.set`, the sorting), and different graphs have different tags
(`ETags.sound`). The second is the one assumption: that the digest is collision-free on the graphs that occur.

`answerB` takes the precondition as `current` or `stale`; `Cond.resolve` computes which, as `evaluatePreconditions`
does, from the tag the request quotes and the graph the store has. Every write reads the graph, changes it in memory
and writes the whole of it back, so a write the precondition does not guard can overwrite another's work; one it
does guard cannot (`no_lost_update`).
-/
import LdhHttp.Answer

namespace LdhHttp

/-- An entity tag function. -/
structure ETags (Tag : Type) where
  tag : Node → List Triple → Tag
  /-- The tag is of the graph, a set of triples: `toSortedNTriples` sorts the lines. -/
  set : ∀ x ts ts', (∀ t, t ∈ ts ↔ t ∈ ts') → tag x ts = tag x ts'
  /-- Collision-freeness: one tag of a document, one graph. -/
  sound : ∀ x ts ts', tag x ts = tag x ts' → ∀ t, t ∈ ts ↔ t ∈ ts'

/-- The conditional headers of a write. -/
inductive Cond (Tag : Type) where
  /-- Neither `If-Match` nor `If-None-Match`. -/
  | none
  /-- `If-Match` with an entity tag. -/
  | ifMatch (t : Tag)
  /-- `If-None-Match: *`. -/
  | ifNoneMatchAny

/-- `evaluatePreconditions`: `If-Match` holds when it quotes the tag of the graph the store has. -/
def Cond.resolve {Tag : Type} [DecidableEq Tag] (E : ETags Tag) (fs : FinStore) (x : Node) : Cond Tag → Precond
  | .none => .none
  | .ifNoneMatchAny => .absent
  | .ifMatch t => if hasDoc fs x = true ∧ E.tag x (graphOf fs x) = t then .current else .stale

/-- A request whose `If-Match` quotes a tag the document does not have changes nothing. -/
theorem stale_changes_nothing {hs : HSite} {fs : FinStore} {agent : Option Node} {req : HReq} {s : Success}
    {fs' : FinStore} (hd : answerB hs fs agent .stale req = .ok (s, fs')) : fs' = fs := by
  cases req with
  | get x | head x =>
    simp only [answerB, readB] at hd; split at hd
    · cases hd; rfl
    · cases hd
  | post x payload =>
    simp only [answerB, postB, precondFails] at hd
    repeat' (first | (cases hd; rfl) | split at hd | cases hd)
  | put x payload =>
    simp only [answerB, putB, precondFails] at hd
    repeat' (first | split at hd | cases hd)
    all_goals simp_all
  | patch x del ins =>
    simp only [answerB, patchB, precondFails] at hd
    repeat' (first | split at hd | cases hd)
  | delete x =>
    simp only [answerB, deleteB, precondFails] at hd
    split at hd; · cases hd
    split at hd
    · cases hd
    · rename_i hx
      simp only [deleteChecked] at hd
      split at hd; · cases hd
      split at hd
      · cases hd
      · simp_all

/-- **No lost update.** A write guarded by `If-Match` with the tag of the graph a client read changes the store
only if the document still holds that graph: whatever another write did in between, this one is not made over it. -/
theorem no_lost_update {Tag : Type} [DecidableEq Tag] (E : ETags Tag) {hs : HSite} {fs : FinStore}
    {agent : Option Node} {req : HReq} {s : Success} {fs' : FinStore} {g₀ : List Triple}
    (hd : answerB hs fs agent ((Cond.ifMatch (E.tag req.target g₀)).resolve E fs req.target) req = .ok (s, fs'))
    (hw : fs' ≠ fs) :
    hasDoc fs req.target = true ∧ ∀ t, t ∈ graphOf fs req.target ↔ t ∈ g₀ := by
  simp only [Cond.resolve] at hd
  split at hd
  · rename_i hc
    exact ⟨hc.1, E.sound _ _ _ hc.2⟩
  · exact absurd (stale_changes_nothing hd) hw

/-- **A write over another's is refused.** Two clients read the same graph; once one of them has changed it, the
other's write, quoting the tag it read, changes nothing. -/
theorem concurrent_write_changes_nothing {Tag : Type} [DecidableEq Tag] (E : ETags Tag) {hs : HSite}
    {fs : FinStore} {agent : Option Node} {req : HReq} {s : Success} {fs' : FinStore} {g₀ : List Triple}
    (hchanged : ¬ (hasDoc fs req.target = true ∧ ∀ t, t ∈ graphOf fs req.target ↔ t ∈ g₀))
    (hd : answerB hs fs agent ((Cond.ifMatch (E.tag req.target g₀)).resolve E fs req.target) req = .ok (s, fs')) :
    fs' = fs :=
  Classical.byContradiction fun hw => hchanged (no_lost_update E hd hw)

end LdhHttp
