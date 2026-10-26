/-
Memento (RFC 7089): a document's versions, as `GraphVersioningService` keeps and serves them.

A versioned dataspace commits every document's graph to a Git repository, one file per document. Its history is the
list of commits that touched the file, most recent first, as GitHub lists them (`GitHubClient.listCommits`). The
TimeGate selects one of them for a datetime, the TimeMap lists them all, and a write schedules the commit that
records it. Four things are modelled:

* **the TimeGate's choice** (`selectMemento`): RFC 7089 leaves it to the server and asks only that it be consistent.
  This one takes the commit closest in time, the more recent of two as close, and the most recent with no datetime;
* **the TimeMap** (`toTimeMap`): its members are the history, and each is `prov:wasRevisionOf` the one before it;
* **the commit queue** (`commitAsync`, `reconcile`): every write that succeeds queues a reconcile, the reconciles of a
  branch run one at a time, and each records the graph the store has when it runs. Versions are snapshots taken when a
  reconcile runs, not one per write: two writes close together can leave one version. Once the queue is drained, the
  newest version is the document's graph (`drained_is_current`);
* **the file a document is versioned in** (`path`): the root document's is `root`, which a document named `root` at
  the top of the tree shares (`versionFile_root_collides`).
-/
import LdhHttp.Base

namespace LdhHttp

/-! ## The TimeGate -/

/-- A commit of a document's file: its SHA and its author datetime, in seconds. -/
structure Commit where
  sha : Nat
  time : Int
  deriving DecidableEq, Repr

/-- `Duration.between(commit.datetime(), datetime).abs()`. -/
def Commit.dist (d : Int) (c : Commit) : Nat := (c.time - d).natAbs

/-- `stream().min(comparator)`: the first of the closest, as `BinaryOperator.minBy` keeps the earlier of two equal. -/
def closer (d : Int) (best c : Commit) : Commit := if c.dist d < best.dist d then c else best

/-- `selectMemento`, over a history most recent first. -/
def selectMemento : List Commit → Option Int → Option Commit
  | [], _ => none
  | c :: _, none => some c
  | c :: cs, some d => some (cs.foldl (closer d) c)

theorem foldl_closer (d : Int) : ∀ (cs : List Commit) (b r : Commit), cs.foldl (closer d) b = r →
    (r = b ∨ r ∈ cs) ∧ r.dist d ≤ b.dist d ∧ (∀ c ∈ cs, r.dist d ≤ c.dist d) ∧
      ∃ pre post, b :: cs = pre ++ r :: post ∧ ∀ c ∈ pre, r.dist d < c.dist d
  | [], b, r, hr => by
    simp only [List.foldl_nil] at hr; subst hr
    exact ⟨Or.inl rfl, Nat.le_refl _, by simp, [], [], rfl, by simp⟩
  | c :: cs, b, r, hr => by
    simp only [List.foldl_cons] at hr
    obtain ⟨hm, hb, hall, pre, post, hsplit, hpre⟩ := foldl_closer d cs (closer d b c) r hr
    by_cases hc : c.dist d < b.dist d
    · simp only [closer, hc, if_true] at hm hb hall hsplit hpre
      refine ⟨?_, by omega, ?_, b :: pre, post, by rw [List.cons_append, ← hsplit], ?_⟩
      · rcases hm with h | h
        · rw [h]; exact Or.inr (List.mem_cons_self _ _)
        · exact Or.inr (List.mem_cons_of_mem _ h)
      · intro c' hc'
        rcases List.mem_cons.1 hc' with rfl | h
        · exact hb
        · exact hall c' h
      · intro c' hc'
        rcases List.mem_cons.1 hc' with rfl | h
        · omega
        · exact hpre c' h
    · simp only [closer, hc, if_false] at hm hb hall hsplit hpre
      refine ⟨?_, hb, ?_, ?_⟩
      · rcases hm with h | h
        · exact Or.inl h
        · exact Or.inr (List.mem_cons_of_mem _ h)
      · intro c' hc'
        rcases List.mem_cons.1 hc' with rfl | h
        · omega
        · exact hall c' h
      · cases pre with
        | nil =>
          simp only [List.nil_append, List.cons.injEq] at hsplit
          obtain ⟨hrb, rfl⟩ := hsplit
          exact ⟨[], c :: cs, by rw [← hrb]; rfl, by simp⟩
        | cons p pre =>
          simp only [List.cons_append, List.cons.injEq] at hsplit
          obtain ⟨hpb, hcs⟩ := hsplit
          have hrb := hpre p (List.mem_cons_self _ _)
          rw [← hpb] at hrb
          refine ⟨b :: c :: pre, post, by rw [hcs]; rfl, ?_⟩
          intro c' hc'
          rcases List.mem_cons.1 hc' with rfl | h
          · exact hrb
          rcases List.mem_cons.1 h with rfl | h
          · omega
          · exact hpre c' (List.mem_cons_of_mem _ h)

/-- A history has a Memento for every datetime, and only a history: an empty one is `404`. -/
theorem select_none_iff {cs : List Commit} {dt : Option Int} : selectMemento cs dt = none ↔ cs = [] := by
  cases cs with
  | nil => simp [selectMemento]
  | cons c cs => cases dt <;> simp [selectMemento]

/-- **The Memento is one of the document's.** -/
theorem select_mem {cs : List Commit} {dt : Option Int} {m : Commit} (h : selectMemento cs dt = some m) :
    m ∈ cs := by
  cases cs with
  | nil => simp [selectMemento] at h
  | cons c cs =>
    cases dt with
    | none => simp [selectMemento] at h; exact h ▸ List.mem_cons_self _ _
    | some d =>
      simp only [selectMemento, Option.some.injEq] at h
      rcases (foldl_closer d cs c m h).1 with h | h
      · rw [h]; exact List.mem_cons_self _ _
      · exact List.mem_cons_of_mem _ h

/-- **With no datetime, the most recent.** -/
theorem select_latest {c : Commit} {cs : List Commit} : selectMemento (c :: cs) none = some c := rfl

/-- **The closest, and of the closest the most recent.** No commit of the history is closer to the datetime, and
every commit more recent than the Memento is further from it. -/
theorem select_closest {cs : List Commit} {d : Int} {m : Commit} (h : selectMemento cs (some d) = some m) :
    (∀ c ∈ cs, m.dist d ≤ c.dist d) ∧ ∃ pre post, cs = pre ++ m :: post ∧ ∀ c ∈ pre, m.dist d < c.dist d := by
  cases cs with
  | nil => simp [selectMemento] at h
  | cons c cs =>
    simp only [selectMemento, Option.some.injEq] at h
    obtain ⟨_, hb, hall, rest⟩ := foldl_closer d cs c m h
    refine ⟨fun c' hc' => ?_, rest⟩
    rcases List.mem_cons.1 hc' with rfl | h
    · exact hb
    · exact hall c' h

/-! ## The TimeMap -/

/-- `toTimeMap`'s `prov:hadMember`: a Memento for every commit of the history. -/
def members (cs : List Commit) : List Nat := cs.map (·.sha)

/-- `toTimeMap`'s `prov:wasRevisionOf`: each Memento is a revision of the next one down the history. -/
def revisions : List Commit → List (Commit × Commit)
  | c :: c' :: cs => (c, c') :: revisions (c' :: cs)
  | _ => []

theorem mem_members {cs : List Commit} {sha : Nat} : sha ∈ members cs ↔ ∃ c ∈ cs, c.sha = sha := by
  simp [members]

/-- **Each Memento is a revision of the one before it in the history, and of nothing else.** -/
theorem mem_revisions : ∀ {cs : List Commit} {a b : Commit},
    (a, b) ∈ revisions cs ↔ ∃ pre post, cs = pre ++ a :: b :: post
  | [], a, b => by simp [revisions]
  | [c], a, b => by
    simp only [revisions, List.not_mem_nil, false_iff, not_exists]
    intro pre post h
    cases pre with
    | nil => simp at h
    | cons p pre => cases pre <;> simp at h
  | c :: c' :: cs, a, b => by
    simp only [revisions, List.mem_cons, Prod.mk.injEq]
    rw [mem_revisions]
    constructor
    · rintro (⟨rfl, rfl⟩ | ⟨pre, post, h⟩)
      · exact ⟨[], cs, rfl⟩
      · exact ⟨c :: pre, post, by rw [h]; rfl⟩
    · rintro ⟨pre, post, h⟩
      cases pre with
      | nil =>
        simp only [List.nil_append, List.cons.injEq] at h
        exact Or.inl ⟨h.1.symm, h.2.1.symm⟩
      | cons p pre =>
        simp only [List.cons_append, List.cons.injEq] at h
        exact Or.inr ⟨pre, post, h.2⟩

/-! ## The commit queue -/

/-- One document's versioning: the graph the store has, the reconciles queued for it, and the graph its newest
version holds, `none` for no graph. -/
structure Versioning (G : Type) where
  store : Option G
  queued : Nat
  newest : Option G
  /-- A write has been made since versioning began: the file of a document that predates it is not yet its own. -/
  written : Bool

inductive VEvent (G : Type) where
  /-- A write that succeeds, leaving the graph `g` (`none` after a `DELETE`); `VersioningFilter` queues a reconcile. -/
  | write (g : Option G)
  /-- The next reconcile of the branch's chain runs: it commits the graph the store has, or deletes the file. -/
  | reconcile

def Versioning.step {G : Type} (v : Versioning G) : VEvent G → Option (Versioning G)
  | .write g => some { v with store := g, queued := v.queued + 1, written := true }
  | .reconcile => if v.queued = 0 then none else some { v with queued := v.queued - 1, newest := v.store }

/-- Once nothing is queued, the newest version of a document written since versioning began is its graph. -/
def Versioning.Drained {G : Type} (v : Versioning G) : Prop := v.written = true → v.queued = 0 → v.newest = v.store

/-- Every event leaves the versioning drained-current: a write queues a reconcile, and a reconcile records the
store's graph. -/
theorem Versioning.step_drained {G : Type} {v v' : Versioning G} {e : VEvent G}
    (hs : v.step e = some v') : v'.Drained := by
  cases e with
  | write g =>
    simp only [Versioning.step, Option.some.injEq] at hs; subst hs
    intro _ hq; simp at hq
  | reconcile =>
    simp only [Versioning.step] at hs
    split at hs
    · cases hs
    · simp only [Option.some.injEq] at hs; subst hs
      intro _ _; rfl

/-- The events a document's versioning goes through. -/
inductive Versioning.Reach {G : Type} : Versioning G → Versioning G → Prop where
  | refl (v) : Reach v v
  | step {v v' v''} (e : VEvent G) : v.step e = some v' → Reach v' v'' → Reach v v''

/-- **A drained queue is current.** From the state versioning begins in, whatever writes and reconciles follow,
whenever no reconcile is queued the newest version is the document's graph. -/
theorem drained_is_current {G : Type} {store newest : Option G} {v : Versioning G}
    (h : Versioning.Reach ⟨store, 0, newest, false⟩ v) : v.Drained := by
  have : ∀ {a b : Versioning G}, Versioning.Reach a b → a.Drained → b.Drained := by
    intro a b hr
    induction hr with
    | refl => exact id
    | step e hs _ ih => exact fun _ => ih (Versioning.step_drained hs)
  exact this h (by intro hw; simp at hw)

/-! ## The version file -/

/-- `GraphVersioningService.path`, on the document's path below the base as segments, without the trailing slash:
the root document, which has none, is versioned as `root`. -/
def versionFile (segments : List String) : List String := if segments = [] then ["root"] else segments

/-- **The root document shares its file with a document named `root`.** `https://example.org/` and
`https://example.org/root/` are versioned in the same `root.nt`, so their histories, TimeMaps and TimeGates are one. -/
theorem versionFile_root_collides : versionFile [] = versionFile ["root"] := rfl

/-- That is the only collision: two other documents never share a file. -/
theorem versionFile_inj {a b : List String} (ha : a ≠ ["root"]) (hb : b ≠ ["root"])
    (h : versionFile a = versionFile b) : a = b := by
  unfold versionFile at h
  by_cases ha' : a = [] <;> by_cases hb' : b = [] <;> simp only [ha', hb', if_true, if_false] at h
  · rw [ha', hb']
  · exact absurd h.symm hb
  · exact absurd h ha
  · exact h

end LdhHttp
