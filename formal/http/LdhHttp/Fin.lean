/-
A store as data: what the executable answer runs on, and the abstract store it denotes.
-/
import LdhHttp.Write

namespace LdhHttp

/-! ## Finite data -/

/-- A store as data: a document's graph as the list of its triples. A document listed more than once has the
union of its lists. -/
abbrev FinStore := List (Node × List Triple)

/-- The graph store's notion of existence, computed. -/
def hasDoc (fs : FinStore) (d : Node) : Bool := fs.any (·.1 == d)

/-- The triples of a document's own graph. -/
def graphOf (fs : FinStore) (d : Node) : List Triple :=
  fs.foldr (fun p acc => if p.1 = d then p.2 ++ acc else acc) []

/-- The abstract store the data denotes. -/
def FinStore.toStore (fs : FinStore) : Store :=
  fun d => if hasDoc fs d then some (fun t => t ∈ graphOf fs d) else none

theorem hasDoc_iff {fs : FinStore} {d : Node} : hasDoc fs d = true ↔ ∃ ts, (d, ts) ∈ fs := by
  simp only [hasDoc, List.any_eq_true, beq_iff_eq]
  constructor
  · rintro ⟨⟨d', ts⟩, h, rfl⟩
    exact ⟨ts, h⟩
  · rintro ⟨ts, h⟩
    exact ⟨(d, ts), h, rfl⟩

theorem graphOf_cons {p : Node × List Triple} {fs : FinStore} {d : Node} :
    graphOf (p :: fs) d = if p.1 = d then p.2 ++ graphOf fs d else graphOf fs d := rfl

theorem mem_graphOf {fs : FinStore} {d : Node} {t : Triple} :
    t ∈ graphOf fs d ↔ ∃ ts, (d, ts) ∈ fs ∧ t ∈ ts := by
  induction fs with
  | nil => simp [graphOf]
  | cons p fs ih =>
    obtain ⟨p1, p2⟩ := p
    rw [graphOf_cons]
    by_cases h : p1 = d
    · subst h
      simp only [if_true, List.mem_append, ih, List.mem_cons]
      constructor
      · rintro (ht | ⟨ts, hts, ht⟩)
        · exact ⟨p2, Or.inl rfl, ht⟩
        · exact ⟨ts, Or.inr hts, ht⟩
      · rintro ⟨ts, hts | hts, ht⟩
        · cases hts; exact Or.inl ht
        · exact Or.inr ⟨ts, hts, ht⟩
    · simp only [h, if_false, ih, List.mem_cons]
      constructor
      · rintro ⟨ts, hts, ht⟩
        exact ⟨ts, Or.inr hts, ht⟩
      · rintro ⟨ts, hts | hts, ht⟩
        · cases hts; exact absurd rfl h
        · exact ⟨ts, hts, ht⟩

theorem hasDoc_of_mem_graphOf {fs : FinStore} {d : Node} {t : Triple} (h : t ∈ graphOf fs d) :
    hasDoc fs d = true := by
  obtain ⟨ts, hm, _⟩ := mem_graphOf.1 h
  exact hasDoc_iff.2 ⟨ts, hm⟩

theorem toStore_of_hasDoc {fs : FinStore} {d : Node} (h : hasDoc fs d = true) :
    fs.toStore d = some (fun t => t ∈ graphOf fs d) := by
  simp [FinStore.toStore, h]

theorem toStore_of_not_hasDoc {fs : FinStore} {d : Node} (h : ¬ hasDoc fs d = true) :
    fs.toStore d = none := by
  simp [FinStore.toStore, h]

theorem present_iff {fs : FinStore} {d : Node} : present fs.toStore d ↔ hasDoc fs d = true := by
  constructor
  · rintro ⟨g, hg⟩
    unfold FinStore.toStore at hg
    split at hg
    · assumption
    · cases hg
  · intro h
    exact ⟨_, toStore_of_hasDoc h⟩

/-- A triple of a document's own graph. -/
theorem own_iff {fs : FinStore} {d : Node} {t : Triple} :
    (∃ g, fs.toStore d = some g ∧ g t) ↔ t ∈ graphOf fs d := by
  constructor
  · rintro ⟨g, hg, ht⟩
    by_cases h : hasDoc fs d = true
    · rw [toStore_of_hasDoc h] at hg
      cases hg
      exact ht
    · rw [toStore_of_not_hasDoc h] at hg
      cases hg
  · intro ht
    exact ⟨_, toStore_of_hasDoc (hasDoc_of_mem_graphOf ht), ht⟩

theorem ownTypes_iff {fs : FinStore} {x t : Node} :
    ownTypes fs.toStore x t ↔ ⟨x, .rdfType, t⟩ ∈ graphOf fs x := own_iff

theorem owner_iff {fs : FinStore} {x a : Node} :
    owner fs.toStore x a ↔ ⟨x, .aclOwner, a⟩ ∈ graphOf fs x := own_iff

/-- The objects of a document's own `rdf:type` triples. -/
def typesOf (fs : FinStore) (x : Node) : List Node :=
  (graphOf fs x).filterMap fun t => if t.s = x ∧ t.p = .rdfType then some t.o else none

/-- The objects of a document's own `acl:owner` triples. -/
def ownersOf (fs : FinStore) (x : Node) : List Node :=
  (graphOf fs x).filterMap fun t => if t.s = x ∧ t.p = .aclOwner then some t.o else none

theorem mem_filterMap_prop {fs : FinStore} {x p o : Node} :
    o ∈ ((graphOf fs x).filterMap fun t => if t.s = x ∧ t.p = p then some t.o else none) ↔
      ⟨x, p, o⟩ ∈ graphOf fs x := by
  simp only [List.mem_filterMap]
  constructor
  · rintro ⟨⟨s, p', o'⟩, ht, h⟩
    simp only at h
    split at h
    · rename_i hsp
      cases h
      obtain ⟨rfl, rfl⟩ := hsp
      exact ht
    · cases h
  · intro h
    exact ⟨_, h, by simp⟩

theorem mem_typesOf {fs : FinStore} {x t : Node} : t ∈ typesOf fs x ↔ ownTypes fs.toStore x t :=
  mem_filterMap_prop.trans ownTypes_iff.symm

theorem mem_ownersOf {fs : FinStore} {x a : Node} : a ∈ ownersOf fs x ↔ owner fs.toStore x a :=
  mem_filterMap_prop.trans owner_iff.symm

/-! ## Writing a finite store -/

/-- The store with document `x`'s graph replaced by `ts`. -/
def FinStore.set (fs : FinStore) (x : Node) (ts : List Triple) : FinStore :=
  (x, ts) :: fs.filter fun p => p.1 != x

/-- The store without document `x`. -/
def FinStore.erase (fs : FinStore) (x : Node) : FinStore := fs.filter fun p => p.1 != x

theorem hasDoc_erase {fs : FinStore} {x y : Node} (h : y ≠ x) : hasDoc (fs.erase x) y = hasDoc fs y := by
  simp only [FinStore.erase, hasDoc, List.any_filter]
  congr 1; funext p
  by_cases hp : p.1 = y
  · subst hp; simp [h]
  · simp [hp]

theorem graphOf_erase {fs : FinStore} {x y : Node} (h : y ≠ x) : graphOf (fs.erase x) y = graphOf fs y := by
  induction fs with
  | nil => rfl
  | cons p fs ih =>
    simp only [FinStore.erase, List.filter_cons] at ih ⊢
    by_cases hp : p.1 = x
    · have hpy : p.1 ≠ y := fun e => h (e ▸ hp)
      simp [hp, ih, graphOf_cons, Ne.symm h]
    · simp only [hp, bne_iff_ne, ne_eq, not_false_eq_true, decide_true, ite_true, graphOf_cons, ih]

theorem hasDoc_cons_other {fs : FinStore} {p : Node × List Triple} {y : Node} (h : p.1 ≠ y) :
    hasDoc (p :: fs) y = hasDoc fs y := by
  simp [hasDoc, h]

theorem graphOf_cons_other {fs : FinStore} {p : Node × List Triple} {y : Node} (h : p.1 ≠ y) :
    graphOf (p :: fs) y = graphOf fs y := by
  rw [graphOf_cons, if_neg h]

theorem set_eq {fs : FinStore} {x : Node} {ts : List Triple} : fs.set x ts = (x, ts) :: fs.erase x := rfl

theorem hasDoc_erase_self {fs : FinStore} {x : Node} : hasDoc (fs.erase x) x = false := by
  simp [FinStore.erase, hasDoc, List.any_filter]

theorem toStore_erase {fs : FinStore} {x : Node} : (fs.erase x).toStore = fs.toStore.set x none := by
  funext y
  by_cases h : y = x
  · subst h; simp [FinStore.toStore, Store.set, hasDoc_erase_self]
  · simp [FinStore.toStore, Store.set, h, hasDoc_erase h, graphOf_erase h]

theorem toStore_set {fs : FinStore} {x : Node} {ts : List Triple} :
    (fs.set x ts).toStore = fs.toStore.set x (some fun t => t ∈ ts) := by
  funext y
  by_cases h : y = x
  · subst h
    have he : graphOf (fs.erase y) y = [] := by
      rcases hx : graphOf (fs.erase y) y with _ | ⟨t, _⟩
      · rfl
      · have : hasDoc (fs.erase y) y = true := hasDoc_of_mem_graphOf (hx ▸ List.mem_cons_self t _)
        rw [hasDoc_erase_self] at this; cases this
    have hh : hasDoc (fs.set y ts) y = true := by simp [FinStore.set, hasDoc]
    have hg : graphOf (fs.set y ts) y = ts := by rw [set_eq, graphOf_cons, if_pos rfl, he, List.append_nil]
    rw [toStore_of_hasDoc hh, hg]; simp [Store.set]
  · have hh : hasDoc (fs.set x ts) y = hasDoc fs y := by
      rw [set_eq, hasDoc_cons_other (Ne.symm h), hasDoc_erase h]
    have hg : graphOf (fs.set x ts) y = graphOf fs y := by
      rw [set_eq, graphOf_cons_other (Ne.symm h), graphOf_erase h]
    simp [FinStore.toStore, Store.set, h, hh, hg]

end LdhHttp
