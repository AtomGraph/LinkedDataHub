/-
The decision as a program. `allowRequest` is a proposition over an abstract store and reader; this file gives the
same decision over finite data, as a `Bool`, and proves the two agree. The executable in `Main.lean` runs it on a
live instance's datasets so the model can be replayed against the server.
-/
import LdhAcl.Theorems

namespace LdhAcl

open LdhHttp

/-! ## Containment, as edges -/

/-- Every containment triple of every graph, as `(document, container)`: what a path over the union graph walks. -/
def edges (fs : FinStore) : List (Node × Node) :=
  fs.flatMap fun p =>
    (p.2.filter fun t => t.p == .siocHasParent || t.p == .siocHasContainer).map fun t => (t.s, t.o)

theorem mem_edges {fs : FinStore} {d p : Node} : (d, p) ∈ edges fs ↔ parentU fs.toStore d p := by
  simp only [edges, List.mem_flatMap, List.mem_map, List.mem_filter, Bool.or_eq_true, beq_iff_eq, parentU,
    contains]
  constructor
  · rintro ⟨⟨y, ts⟩, hy, ⟨s, p', o⟩, ⟨ht, hp⟩, he⟩
    simp only [Prod.mk.injEq] at he
    obtain ⟨rfl, rfl⟩ := he
    refine ⟨y, _, toStore_of_hasDoc (hasDoc_iff.2 ⟨ts, hy⟩), ?_⟩
    have hm : (⟨s, p', o⟩ : Triple) ∈ graphOf fs y := mem_graphOf.2 ⟨ts, hy, ht⟩
    rcases hp with rfl | rfl
    · exact Or.inl hm
    · exact Or.inr hm
  · rintro ⟨y, g, hg, h⟩
    have hh : hasDoc fs y = true := present_iff.1 ⟨g, hg⟩
    rw [toStore_of_hasDoc hh] at hg
    cases hg
    rcases h with h | h <;> obtain ⟨ts, hy, ht⟩ := mem_graphOf.1 h
    · exact ⟨(y, ts), hy, _, ⟨ht, Or.inl rfl⟩, rfl⟩
    · exact ⟨(y, ts), hy, _, ⟨ht, Or.inr rfl⟩, rfl⟩

/-! ## Transitive closure -/

/-- Membership in an edge list, as a relation. -/
def mem2 (l : List (Node × Node)) : Node → Node → Prop := fun a b => (a, b) ∈ l

/-- `b` is reachable from `a` over the edges still available, each edge used at most once. With fuel at least
the number of edges, this is the transitive closure: a shortest path never reuses an edge. -/
def reachB : Nat → List (Node × Node) → Node → Node → Bool
  | 0, _, _, _ => false
  | n + 1, avail, a, b => avail.any fun e => e.1 == a && (e.2 == b || reachB n (avail.erase e) e.2 b)

theorem Anc.mono {R R' : Node → Node → Prop} (h : ∀ a b, R a b → R' a b) {a b : Node} :
    Anc R a b → Anc R' a b := by
  intro h'
  induction h' with
  | step hab => exact .step (h _ _ hab)
  | trans hab _ ih => exact .trans (h _ _ hab) ih

theorem reachB_sound : ∀ {n : Nat} {avail : List (Node × Node)} {a b : Node},
    reachB n avail a b = true → Anc (mem2 avail) a b := by
  intro n
  induction n with
  | zero => intro _ _ _ h; simp [reachB] at h
  | succ n ih =>
    intro avail a b h
    simp only [reachB, List.any_eq_true, Bool.and_eq_true, Bool.or_eq_true, beq_iff_eq] at h
    obtain ⟨⟨a', c⟩, he, rfl, h⟩ := h
    rcases h with rfl | h
    · exact .step he
    · exact .trans he ((ih h).mono fun _ _ hm => List.mem_of_mem_erase hm)

/-- Taking the last use of `e` in a derivation: either the derivation does without `e`, or `e` is the last edge,
or what follows its last use does without it. -/
theorem Anc.lastUse {avail : List (Node × Node)} {c b : Node} (h : Anc (mem2 avail) c b) (e : Node × Node) :
    Anc (mem2 (avail.erase e)) c b ∨ e.2 = b ∨ Anc (mem2 (avail.erase e)) e.2 b := by
  induction h with
  | @step x y hxy =>
    by_cases hce : (x, y) = e
    · subst hce
      exact Or.inr (Or.inl rfl)
    · exact Or.inl (.step ((List.mem_erase_of_ne hce).2 hxy))
  | @trans x y z hxy _ ih =>
    rcases ih with h | h | h
    · by_cases hce : (x, y) = e
      · subst hce
        exact Or.inr (Or.inr h)
      · exact Or.inl (.trans ((List.mem_erase_of_ne hce).2 hxy) h)
    · exact Or.inr (Or.inl h)
    · exact Or.inr (Or.inr h)

theorem reachB_complete : ∀ {n : Nat} {avail : List (Node × Node)} {a b : Node},
    avail.length ≤ n → Anc (mem2 avail) a b → reachB n avail a b = true := by
  intro n
  induction n with
  | zero =>
    intro avail a b hlen h
    cases avail with
    | nil =>
      cases h with
      | step h => cases h
      | trans h _ => cases h
    | cons _ _ => simp at hlen
  | succ n ih =>
    intro avail a b hlen h
    simp only [reachB, List.any_eq_true, Bool.and_eq_true, Bool.or_eq_true, beq_iff_eq]
    cases h with
    | step hab => exact ⟨(a, b), hab, rfl, Or.inl rfl⟩
    | @trans _ c _ hac hcb =>
      refine ⟨(a, c), hac, rfl, ?_⟩
      have hlen' : (avail.erase (a, c)).length ≤ n := by
        rw [List.length_erase_of_mem hac]
        omega
      rcases hcb.lastUse (a, c) with h | h | h
      · exact Or.inr (ih hlen' h)
      · exact Or.inl h
      · exact Or.inr (ih hlen' h)

theorem Anc_iff_reachB {avail : List (Node × Node)} {a b : Node} :
    Anc (mem2 avail) a b ↔ reachB avail.length avail a b = true :=
  ⟨reachB_complete (Nat.le_refl _), reachB_sound⟩

/-- `ancestor`, computed: the closure of the containment edges. -/
def ancB (fs : FinStore) (x c : Node) : Bool :=
  reachB (edges fs).length (edges fs) x c

theorem ancestor_iff_ancB {fs : FinStore} {x c : Node} : ancestor fs.toStore x c ↔ ancB fs x c = true := by
  have hR : ∀ a b, parentU fs.toStore a b ↔ mem2 (edges fs) a b := fun a b => mem_edges.symm
  constructor
  · intro h
    exact Anc_iff_reachB.1 (h.mono fun a b => (hR a b).1)
  · intro h
    exact (Anc_iff_reachB.2 h).mono fun a b => (hR a b).2

/-- `rdfs:subClassOf*` over a list of `rdfs:subClassOf` axioms. -/
def finSub (sc : List (Node × Node)) (t c : Node) : Prop := t = c ∨ Anc (mem2 sc) t c

def subB (sc : List (Node × Node)) (t c : Node) : Bool := t == c || reachB sc.length sc t c

theorem finSub_iff {sc : List (Node × Node)} {t c : Node} : finSub sc t c ↔ subB sc t c = true := by
  simp only [finSub, subB, Bool.or_eq_true, beq_iff_eq, Anc_iff_reachB]

/-! ## The admin dataset, as data -/

/-- What the ACL query reads of the admin dataset: the authorizations each admin document describes as its
primary topic, the memberships each states of the group that is its primary topic, and the subclass axioms. -/
structure FinAdmin where
  auths : List (Node × Auth)
  members : List (Node × Node × Node)
  subClassOf : List (Node × Node)

def FinAdmin.reader (fa : FinAdmin) : Reader where
  auths := fun d _ au => (d, au) ∈ fa.auths
  member := fun d _ grp a => (d, grp, a) ∈ fa.members
  sub := finSub fa.subClassOf
  sub_refl := fun _ => Or.inl rfl

/-- The deployment constants, computed. -/
structure FinSite extends HSite where
  admin : Node → Bool

def FinSite.agrees (fsite : FinSite) (site : Site) : Prop :=
  (∀ d, site.parent d = fsite.parent d) ∧ (∀ d, site.admin d ↔ fsite.admin d = true)

/-! ## The decision -/

def coversModeB (granted required : Mode) : Bool :=
  granted == required || (granted == .write && required == .append)

theorem coversMode_iff {g r : Mode} : Mode.covers g r ↔ coversModeB g r = true := by
  simp [Mode.covers, coversModeB]

def memberB (fsite : FinSite) (fs : FinStore) (fa : FinAdmin) (grp a : Node) : Bool :=
  fa.members.any fun m => fsite.admin m.1 && hasDoc fs m.1 && m.2.1 == grp && m.2.2 == a

theorem memberIn_iff {fsite : FinSite} {site : Site} (h : fsite.agrees site) {fs : FinStore} {fa : FinAdmin}
    {grp a : Node} : memberIn site fa.reader fs.toStore grp a ↔ memberB fsite fs fa grp a = true := by
  simp only [memberIn, FinAdmin.reader, memberB, List.any_eq_true, Bool.and_eq_true, beq_iff_eq]
  constructor
  · rintro ⟨d, g, hd, hg, hm⟩
    exact ⟨(d, grp, a), hm, ⟨⟨(h.2 d).1 hd, present_iff.1 ⟨g, hg⟩⟩, rfl⟩, rfl⟩
  · rintro ⟨⟨d, grp', a'⟩, hm, ⟨⟨hd, hp⟩, h1⟩, h2⟩
    simp only at h1 h2
    subst h1 h2
    obtain ⟨g, hg⟩ := present_iff.2 hp
    exact ⟨d, g, (h.2 d).2 hd, hg, hm⟩

def principalB (fsite : FinSite) (fs : FinStore) (fa : FinAdmin) (owners : List Node) (au : Auth) :
    Option Node → Bool
  | none => decide (AgentClass.anyone ∈ au.classes)
  | some a => decide (a ∈ au.agents) || au.groups.any (fun grp => memberB fsite fs fa grp a) ||
      decide (AgentClass.anyone ∈ au.classes) || decide (AgentClass.authenticated ∈ au.classes) ||
      (decide (AgentClass.owner ∈ au.classes) && decide (a ∈ owners))

theorem principal_iff {fsite : FinSite} {site : Site} (h : fsite.agrees site) {fs : FinStore} {fa : FinAdmin}
    {au : Auth} {x : Node} {agent : Option Node} :
    au.principal (memberIn site fa.reader fs.toStore) (owner fs.toStore x) agent ↔
      principalB fsite fs fa (ownersOf fs x) au agent = true := by
  cases agent with
  | none => simp [Auth.principal, principalB]
  | some a =>
    simp only [Auth.principal, principalB, Bool.or_eq_true, Bool.and_eq_true, decide_eq_true_iff,
      List.any_eq_true, memberIn_iff h, mem_ownersOf]
    constructor
    · rintro (h | ⟨grp, hg, hm⟩ | h | h | h)
      · exact Or.inl (Or.inl (Or.inl (Or.inl h)))
      · exact Or.inl (Or.inl (Or.inl (Or.inr ⟨grp, hg, hm⟩)))
      · exact Or.inl (Or.inl (Or.inr h))
      · exact Or.inl (Or.inr h)
      · exact Or.inr h
    · rintro ((((h | ⟨grp, hg, hm⟩) | h) | h) | h)
      · exact Or.inl h
      · exact Or.inr (Or.inl ⟨grp, hg, hm⟩)
      · exact Or.inr (Or.inr (Or.inl h))
      · exact Or.inr (Or.inr (Or.inr (Or.inl h)))
      · exact Or.inr (Or.inr (Or.inr (Or.inr h)))

def coversB (fs : FinStore) (fa : FinAdmin) (au : Auth) (x : Node) : Bool :=
  decide (x ∈ au.accessTo) || au.default.any (fun c => ancB fs x c) ||
    au.accessToClass.any fun c => (typesOf fs x).any fun t => subB fa.subClassOf t c

theorem covers_iff {fs : FinStore} {fa : FinAdmin} {au : Auth} {x : Node} :
    au.covers fa.reader.sub (context fs.toStore x) ↔ coversB fs fa au x = true := by
  rw [covers_context]
  simp only [coversB, FinAdmin.reader, Bool.or_eq_true, decide_eq_true_iff, List.any_eq_true,
    ancestor_iff_ancB, finSub_iff]
  constructor
  · rintro (h | ⟨c, hc, ha⟩ | ⟨c, hc, t, ht, hs⟩)
    · exact Or.inl (Or.inl h)
    · exact Or.inl (Or.inr ⟨c, hc, ha⟩)
    · exact Or.inr ⟨c, hc, t, mem_typesOf.2 ht, hs⟩
  · rintro ((h | ⟨c, hc, ha⟩) | ⟨c, hc, t, ht, hs⟩)
    · exact Or.inl h
    · exact Or.inr (Or.inl ⟨c, hc, ha⟩)
    · exact Or.inr (Or.inr ⟨c, hc, t, mem_typesOf.1 ht, hs⟩)

def grantB (fsite : FinSite) (fs : FinStore) (fa : FinAdmin) (agent : Option Node) (m : Mode) (x : Node) :
    Bool :=
  fa.auths.any fun p => fsite.admin p.1 && hasDoc fs p.1 && principalB fsite fs fa (ownersOf fs x) p.2 agent &&
    coversB fs fa p.2 x && p.2.modes.any (fun g => coversModeB g m)

theorem grant_iff {fsite : FinSite} {site : Site} (h : fsite.agrees site) {fs : FinStore} {fa : FinAdmin}
    {agent : Option Node} {m : Mode} {x : Node} :
    grant site fa.reader fs.toStore agent m x ↔ grantB fsite fs fa agent m x = true := by
  simp only [grant, grantWith, authIn, grantB, List.any_eq_true, Bool.and_eq_true]
  constructor
  · rintro ⟨au, ⟨d, g, hd, hg, hau⟩, hp, hc, g', hg', hm⟩
    exact ⟨(d, au), hau, ⟨⟨⟨(h.2 d).1 hd, present_iff.1 ⟨g, hg⟩⟩, (principal_iff h).1 hp⟩, covers_iff.1 hc⟩,
      g', hg', coversMode_iff.1 hm⟩
  · rintro ⟨⟨d, au⟩, hau, ⟨⟨⟨hd, hpres⟩, hp⟩, hc⟩, g', hg', hm⟩
    obtain ⟨g, hg⟩ := present_iff.2 hpres
    exact ⟨au, ⟨d, g, (h.2 d).2 hd, hg, hau⟩, (principal_iff h).2 hp, covers_iff.2 hc, g', hg',
      coversMode_iff.2 hm⟩

/-- A document the graph store does not have is created under its parent, which must be the root or a container. -/
def containerB (fs : FinStore) (p : Node) : Bool :=
  decide (⟨p, .rdfType, .defRoot⟩ ∈ graphOf fs p) || decide (⟨p, .rdfType, .dhContainer⟩ ∈ graphOf fs p)

def allowB (fsite : FinSite) (fs : FinStore) (fa : FinAdmin) (agent : Option Node) (isPut : Bool) (m : Mode)
    (x : Node) : Bool :=
  ((hasDoc fs x || !isPut) && grantB fsite fs fa agent m x) ||
  (!hasDoc fs x && isPut && containerB fs (fsite.parent x) && grantB fsite fs fa agent m (fsite.parent x))

theorem allow_iff {fsite : FinSite} {site : Site} (h : fsite.agrees site) {fs : FinStore} {fa : FinAdmin}
    {agent : Option Node} {isPut : Prop} [Decidable isPut] {m : Mode} {x : Node} :
    allow site fa.reader fs.toStore agent isPut m x ↔ allowB fsite fs fa agent (decide isPut) m x = true := by
  simp only [allow, allowB, containerB, Bool.or_eq_true, Bool.and_eq_true, Bool.not_eq_true', decide_eq_true_iff,
    decide_eq_false_iff_not, present_iff, grant_iff h, ownTypes_iff, h.1 x, Bool.eq_false_iff, and_assoc, ne_eq,
    decide_eq_true_eq]

def allowRequestB (fsite : FinSite) (fs : FinStore) (fa : FinAdmin) (agent : Option Node) :
    Method → Node → Bool
  | .get, x => allowB fsite fs fa agent false .read x
  | .head, x => allowB fsite fs fa agent false .read x || allowB fsite fs fa agent false .append x
  | .post, x => allowB fsite fs fa agent false .append x
  | .put, x => allowB fsite fs fa agent true .write x
  | .putCreate, x => allowB fsite fs fa agent true .append x
  | .patch, x => allowB fsite fs fa agent false .write x
  | .delete, x => allowB fsite fs fa agent false .write x

/-- **The program decides as the model does.** For every site the constants agree with, every finite store and
admin dataset, every agent, method and document. -/
theorem allowRequest_iff {fsite : FinSite} {site : Site} (h : fsite.agrees site) {fs : FinStore} {fa : FinAdmin}
    {agent : Option Node} (meth : Method) (x : Node) :
    allowRequest site fa.reader fs.toStore agent meth x ↔ allowRequestB fsite fs fa agent meth x = true := by
  have hf : ∀ m x, allow site fa.reader fs.toStore agent False m x ↔ allowB fsite fs fa agent false m x = true :=
    fun m x => by simpa using allow_iff h (isPut := False)
  have ht : ∀ m x, allow site fa.reader fs.toStore agent True m x ↔ allowB fsite fs fa agent true m x = true :=
    fun m x => by simpa using allow_iff h (isPut := True)
  cases meth <;> simp only [allowRequest, allowRequestB, Bool.or_eq_true, hf, ht]

end LdhAcl
