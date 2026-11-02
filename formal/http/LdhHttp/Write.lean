/-
The writes of `DocumentHierarchyGraphStoreImpl`, and the invariants they keep.

Each write touches one graph, the request URI's. A write is what the graph store does with a request it answers
with a success status; whether the request was authorized is no part of it. A graph written for document `x` may state containment of `x` only: a
payload with `sioc:has_parent` or `sioc:has_container` of any other subject is refused (`422`,
`checkForeignContainment`), and containment of `x` itself is stripped or guarded. That rule is what makes the union
graph a faithful view of containment. A write may also type `x` with hierarchy classes only, and must leave it typed
with one (`422`, `checkDocumentTypes`). A document is created only below a parent the store has (`409`).
-/
import LdhHttp.Base

namespace LdhHttp

/-- The write rule: every containment triple of `g` is about `x`. -/
def NoForeign (x : Node) (g : Graph) : Prop := ∀ t, g t → isContainment t → t.s = x

/-- The containment `put()` asserts for a non-root document, pointing at the URI parent: `sioc:has_parent` when
the payload types it `dh:Container`, `sioc:has_container` otherwise. -/
def containedIn (tr : Tree) (x : Node) (payload : Graph) (t : Triple) : Prop :=
  ¬ tr.isRoot x ∧
    ((payload ⟨x, .rdfType, .dhContainer⟩ ∧ t = ⟨x, .siocHasParent, tr.parent x⟩) ∨
      (¬ payload ⟨x, .rdfType, .dhContainer⟩ ∧ t = ⟨x, .siocHasContainer, tr.parent x⟩))

theorem containedIn.props {tr : Tree} {x : Node} {payload : Graph} {t : Triple}
    (h : containedIn tr x payload t) : ¬ tr.isRoot x ∧ t.s = x ∧ isContainment t ∧ t.o = tr.parent x := by
  obtain ⟨hr, ⟨_, rfl⟩ | ⟨_, rfl⟩⟩ := h
  · exact ⟨hr, rfl, Or.inl rfl, rfl⟩
  · exact ⟨hr, rfl, Or.inr rfl, rfl⟩

/-- A non-root document's `put()` graph states its containment in its URI parent. -/
theorem containedIn_contains {tr : Tree} {x : Node} {payload : Graph} {G : Graph} (hr : ¬ tr.isRoot x)
    (hG : ∀ t, containedIn tr x payload t → G t) : contains G x (tr.parent x) := by
  by_cases hc : payload ⟨x, .rdfType, .dhContainer⟩
  · exact Or.inl (hG _ ⟨hr, Or.inl ⟨hc, rfl⟩⟩)
  · exact Or.inr (hG _ ⟨hr, Or.inr ⟨hc, rfl⟩⟩)

/-- The type rule: a graph written for `x` types `x` with hierarchy classes only. -/
def HierTypes (x : Node) (g : Graph) : Prop := ∀ c, g ⟨x, .rdfType, c⟩ → hierClass c

/-- `g` types `x` with a hierarchy class. -/
def TypedBy (x : Node) (g : Graph) : Prop := ∃ c, g ⟨x, .rdfType, c⟩ ∧ hierClass c

/-- The class `put()` asserts for a non-root document the payload does not type `dh:Container`. -/
def itemTyped (tr : Tree) (x : Node) (payload : Graph) (t : Triple) : Prop :=
  ¬ tr.isRoot x ∧ ¬ payload ⟨x, .rdfType, .dhContainer⟩ ∧ t = ⟨x, .rdfType, .dhItem⟩

/-- One write by `agent`, from `st` to `st'`. A `PUT` of the root is stored as sent, so its payload has to type it;
any other `PUT` is typed `dh:Item` unless it is a container, and creates a document only below a parent the store
has. A `PATCH` may keep the types the document has and add hierarchy classes, and must not drop the last of them. -/
inductive Write (tr : Tree) (agent : Option Node) : Store → Req → Store → Prop where
  | post {st x payload g} :
      st x = some g →
      NoForeign x payload →
      HierTypes x payload →
      Write tr agent st (.post x payload)
        (st.set x (some fun t => g t ∨ (payload t ∧ ¬ ownership x t ∧ ¬ containment x t)))
  | putExisting {st x payload createOnly g} :
      st x = some g →
      createOnly = false →
      NoForeign x payload →
      HierTypes x payload →
      (tr.isRoot x → TypedBy x payload) →
      Write tr agent st (.put x payload createOnly)
        (st.set x (some fun t =>
          (payload t ∧ ¬ ownership x t ∧ ¬ containment x t) ∨ containedIn tr x payload t ∨
          (g t ∧ ownership x t) ∨ itemTyped tr x payload t))
  | putNew {st x payload createOnly} :
      st x = none →
      NoForeign x payload →
      HierTypes x payload →
      (tr.isRoot x → TypedBy x payload) →
      (¬ tr.isRoot x → present st (tr.parent x)) →
      Write tr agent st (.put x payload createOnly)
        (st.set x (some fun t =>
          (payload t ∧ ¬ ownership x t ∧ ¬ containment x t) ∨ containedIn tr x payload t ∨
          (∃ a, agent = some a ∧ t.s = x ∧ (t.p = .aclOwner ∨ t.p = .dctCreator) ∧ t.o = a) ∨
          itemTyped tr x payload t))
  | patch {st x after g} :
      st x = some g →
      NoForeign x after →
      (∀ t, ownership x t ∨ containment x t → (after t ↔ g t)) →
      (∀ c, after ⟨x, .rdfType, c⟩ → g ⟨x, .rdfType, c⟩ ∨ hierClass c) →
      TypedBy x after →
      Write tr agent st (.patch x after) (st.set x (some after))
  | delete {st x} :
      ¬ tr.isRoot x →
      ¬ hasChild st x →
      Write tr agent st (.delete x) (st.set x none)

theorem Write.frame {tr agent st req st'} (h : Write tr agent st req st')
    {y : Node} (hy : y ≠ req.target) : st' y = st y := by
  cases h <;> simp [Store.set, Req.target] at hy ⊢ <;> simp [hy]

/-! ## Invariants -/

/-- What the write rule maintains: every containment triple sits in its subject's own graph. -/
def OwnGraphContainment (st : Store) : Prop :=
  ∀ y g t, st y = some g → g t → isContainment t → t.s = y

/-- A document's own graph points its containment at its URI parent and nowhere else. -/
def Exact (tr : Tree) (st : Store) : Prop :=
  ∀ d g p, st d = some g → contains g d p → ¬ tr.isRoot d ∧ p = tr.parent d

/-- Every non-root document's own graph states its containment. -/
def Contained (tr : Tree) (st : Store) : Prop :=
  ∀ d g, st d = some g → ¬ tr.isRoot d → contains g d (tr.parent d)

/-- Every non-root document's URI parent is in the store. -/
def Hier (tr : Tree) (st : Store) : Prop :=
  ∀ d, present st d → ¬ tr.isRoot d → present st (tr.parent d)

def RootsPresent (tr : Tree) (st : Store) : Prop :=
  ∀ r, tr.isRoot r → present st r

structure Inv (tr : Tree) (st : Store) : Prop where
  own : OwnGraphContainment st
  exact : Exact tr st
  contained : Contained tr st
  hier : Hier tr st
  roots : RootsPresent tr st

theorem present_set_self {st : Store} {x : Node} {g : Graph} : present (st.set x (some g)) x :=
  ⟨g, by simp [Store.set]⟩

theorem present_set_other {st : Store} {x z : Node} {v} (h : z ≠ x) :
    present (st.set x v) z ↔ present st z := by
  simp [present, Store.set, h]

/-- Every write but a delete leaves a graph at its target. -/
theorem Write.present_target {tr agent st req st'} (h : Write tr agent st req st')
    (hd : ∀ x, req ≠ .delete x) : present st' req.target := by
  cases h with
  | delete => exact absurd rfl (hd _)
  | _ => exact present_set_self

/-- Every write but a delete keeps every present document present. -/
theorem Write.present_mono {tr agent st req st'} (h : Write tr agent st req st')
    (hd : ∀ x, req ≠ .delete x) {p : Node} (hp : present st p) : present st' p := by
  by_cases hpx : p = req.target
  · rw [hpx]; exact h.present_target hd
  · obtain ⟨g, hg⟩ := hp; exact ⟨g, by rw [h.frame hpx]; exact hg⟩

theorem ownership_not_containment {x : Node} {t : Triple} (ho : ownership x t) (hc : isContainment t) :
    False := by
  obtain ⟨_, hp⟩ := ho
  rcases hp with hp | hp <;> rcases hc with hc | hc <;> rw [hp] at hc <;> cases hc

theorem own_preserved {tr agent st req st'} (hs : Write tr agent st req st')
    (h : OwnGraphContainment st) : OwnGraphContainment st' := by
  intro y g' t hy ht hc
  by_cases hyx : y = req.target
  · cases hs with
    | @post x _ g hg hnf =>
      simp [Req.target] at hyx; subst hyx; simp [Store.set] at hy; subst hy
      rcases ht with ht | ⟨ht, _⟩
      · exact h _ _ _ hg ht hc
      · exact hnf _ ht hc
    | putExisting _ _ hnf =>
      simp [Req.target] at hyx; subst hyx; simp [Store.set] at hy; subst hy
      rcases ht with ⟨ht, _⟩ | hci | ⟨_, hs, _⟩ | ⟨_, _, rfl⟩
      · exact hnf _ ht hc
      · exact hci.props.2.1
      · exact hs
      · rcases hc with hc | hc <;> cases hc
    | putNew _ hnf =>
      simp [Req.target] at hyx; subst hyx; simp [Store.set] at hy; subst hy
      rcases ht with ⟨ht, _⟩ | hci | ⟨_, _, hs, _⟩ | ⟨_, _, rfl⟩
      · exact hnf _ ht hc
      · exact hci.props.2.1
      · exact hs
      · rcases hc with hc | hc <;> cases hc
    | patch _ hnf =>
      simp [Req.target] at hyx; subst hyx; simp [Store.set] at hy; subst hy
      exact hnf _ ht hc
    | delete =>
      simp [Req.target] at hyx; subst hyx; simp [Store.set] at hy
  · rw [hs.frame hyx] at hy
    exact h _ _ _ hy ht hc

theorem exact_preserved {tr agent st req st'} (hs : Write tr agent st req st')
    (h : Exact tr st) : Exact tr st' := by
  intro d g' p hd hc
  by_cases hdx : d = req.target
  · cases hs with
    | @post x _ g hg _ =>
      simp [Req.target] at hdx; subst hdx; simp [Store.set] at hd; subst hd
      rcases hc with (hc | ⟨_, _, hn⟩) | (hc | ⟨_, _, hn⟩)
      · exact h _ _ _ hg (Or.inl hc)
      · exact absurd ⟨rfl, Or.inl rfl⟩ hn
      · exact h _ _ _ hg (Or.inr hc)
      · exact absurd ⟨rfl, Or.inr rfl⟩ hn
    | putExisting =>
      simp [Req.target] at hdx; subst hdx; simp [Store.set] at hd; subst hd
      rcases hc with (⟨_, _, hn⟩ | hci | ⟨_, ho⟩ | ⟨_, _, he⟩) |
          (⟨_, _, hn⟩ | hci | ⟨_, ho⟩ | ⟨_, _, he⟩)
      · exact absurd ⟨rfl, Or.inl rfl⟩ hn
      · exact ⟨hci.props.1, hci.props.2.2.2⟩
      · exact (ownership_not_containment ho (Or.inl rfl)).elim
      · cases he
      · exact absurd ⟨rfl, Or.inr rfl⟩ hn
      · exact ⟨hci.props.1, hci.props.2.2.2⟩
      · exact (ownership_not_containment ho (Or.inr rfl)).elim
      · cases he
    | putNew =>
      simp [Req.target] at hdx; subst hdx; simp [Store.set] at hd; subst hd
      rcases hc with (⟨_, _, hn⟩ | hci | ⟨_, _, _, hp, _⟩ | ⟨_, _, he⟩) |
          (⟨_, _, hn⟩ | hci | ⟨_, _, _, hp, _⟩ | ⟨_, _, he⟩)
      · exact absurd ⟨rfl, Or.inl rfl⟩ hn
      · exact ⟨hci.props.1, hci.props.2.2.2⟩
      · rcases hp with hp | hp <;> cases hp
      · cases he
      · exact absurd ⟨rfl, Or.inr rfl⟩ hn
      · exact ⟨hci.props.1, hci.props.2.2.2⟩
      · rcases hp with hp | hp <;> cases hp
      · cases he
    | @patch x _ g hg _ hkeep =>
      simp [Req.target] at hdx; subst hdx; simp [Store.set] at hd; subst hd
      rcases hc with hc | hc
      · exact h _ _ _ hg (Or.inl ((hkeep _ (Or.inr ⟨rfl, Or.inl rfl⟩)).1 hc))
      · exact h _ _ _ hg (Or.inr ((hkeep _ (Or.inr ⟨rfl, Or.inr rfl⟩)).1 hc))
    | delete =>
      simp [Req.target] at hdx; subst hdx; simp [Store.set] at hd
  · rw [hs.frame hdx] at hd
    exact h _ _ _ hd hc

theorem contained_preserved {tr agent st req st'} (hs : Write tr agent st req st')
    (h : Contained tr st) : Contained tr st' := by
  intro d g' hd hroot
  by_cases hdx : d = req.target
  · cases hs with
    | @post x _ g hg _ =>
      simp [Req.target] at hdx; subst hdx; simp [Store.set] at hd; subst hd
      rcases h d g hg hroot with hc | hc
      · exact Or.inl (Or.inl hc)
      · exact Or.inr (Or.inl hc)
    | putExisting =>
      simp [Req.target] at hdx; subst hdx; simp [Store.set] at hd; subst hd
      exact containedIn_contains hroot fun _ h => Or.inr (Or.inl h)
    | putNew =>
      simp [Req.target] at hdx; subst hdx; simp [Store.set] at hd; subst hd
      exact containedIn_contains hroot fun _ h => Or.inr (Or.inl h)
    | @patch x _ g hg _ hkeep =>
      simp [Req.target] at hdx; subst hdx; simp [Store.set] at hd; subst hd
      rcases h d g hg hroot with hc | hc
      · exact Or.inl ((hkeep _ (Or.inr ⟨rfl, Or.inl rfl⟩)).2 hc)
      · exact Or.inr ((hkeep _ (Or.inr ⟨rfl, Or.inr rfl⟩)).2 hc)
    | delete =>
      simp [Req.target] at hdx; subst hdx; simp [Store.set] at hd
  · rw [hs.frame hdx] at hd
    exact h d g' hd hroot

theorem ownTypes_present {st : Store} {x t : Node} (h : ownTypes st x t) : present st x := by
  obtain ⟨g, hg, _⟩ := h; exact ⟨g, hg⟩

theorem hier_preserved {tr agent st req st'} (hs : Write tr agent st req st')
    (h : Hier tr st) (hc : Contained tr st) : Hier tr st' := by
  intro d hd hroot
  have hm := hs.present_mono
  cases hs with
  | @delete x _ noChild =>
    have hdx : d ≠ x := by
      rintro rfl; obtain ⟨g, hg⟩ := hd; simp [Store.set] at hg
    have hd0 := (present_set_other hdx).1 hd
    have hp := h d hd0 hroot
    by_cases hpx : tr.parent d = x
    · obtain ⟨g, hg⟩ := hd0
      have hcd := hc d g hg hroot
      rw [hpx] at hcd
      exact absurd ⟨d, g, hdx, hg, hcd⟩ noChild
    · exact (present_set_other hpx).2 hp
  | @putNew x _ _ _ _ _ _ hpar =>
    apply hm (by intro _ h; cases h)
    by_cases hdx : d = x
    · subst hdx; exact hpar hroot
    · exact h d ((present_set_other hdx).1 hd) hroot
  | @post x _ g hg =>
    apply hm (by intro _ h; cases h)
    by_cases hdx : d = x
    · subst hdx; exact h d ⟨_, hg⟩ hroot
    · exact h d ((present_set_other hdx).1 hd) hroot
  | @putExisting x _ _ g hg =>
    apply hm (by intro _ h; cases h)
    by_cases hdx : d = x
    · subst hdx; exact h d ⟨_, hg⟩ hroot
    · exact h d ((present_set_other hdx).1 hd) hroot
  | @patch x _ g hg =>
    apply hm (by intro _ h; cases h)
    by_cases hdx : d = x
    · subst hdx; exact h d ⟨_, hg⟩ hroot
    · exact h d ((present_set_other hdx).1 hd) hroot

theorem roots_preserved {tr agent st req st'} (hs : Write tr agent st req st')
    (h : RootsPresent tr st) : RootsPresent tr st' := by
  have hm := hs.present_mono
  cases hs with
  | @delete x hr _ =>
    intro r hrr
    have hrx : r ≠ x := fun e => hr (e ▸ hrr)
    exact (present_set_other hrx).2 (h r hrr)
  | _ => exact fun r hrr => hm (by intro _ h; cases h) (h r hrr)

/-- **The invariants hold after every write.** -/
theorem Write.inv {tr agent st req st'} (hs : Write tr agent st req st') (h : Inv tr st) :
    Inv tr st' :=
  ⟨own_preserved hs h.own, exact_preserved hs h.exact, contained_preserved hs h.contained,
    hier_preserved hs h.hier h.contained, roots_preserved hs h.roots⟩

/-! ## Typing -/

/-- Every document the store has is typed with a hierarchy class. -/
def Typed (st : Store) : Prop := ∀ x, present st x → ∃ t, ownTypes st x t ∧ hierClass t

/-- A write types a document with nothing but the classes it had and hierarchy classes. -/
theorem Write.ownTypes {tr agent st req st'} (hs : Write tr agent st req st') {x c : Node}
    (ht : LdhHttp.ownTypes st' x c) : LdhHttp.ownTypes st x c ∨ hierClass c := by
  obtain ⟨g', hg', hc⟩ := ht
  by_cases hx : x = req.target
  · cases hs with
    | @post y _ g hg _ hty =>
      simp [Req.target] at hx; subst hx; simp [Store.set] at hg'; subst hg'
      rcases hc with hc | ⟨hc, _⟩
      · exact Or.inl ⟨g, hg, hc⟩
      · exact Or.inr (hty c hc)
    | putExisting _ _ _ hty =>
      simp [Req.target] at hx; subst hx; simp [Store.set] at hg'; subst hg'
      rcases hc with ⟨hc, _⟩ | hci | ⟨_, _, hp⟩ | ⟨_, _, he⟩
      · exact Or.inr (hty c hc)
      · rcases hci.props.2.2.1 with hp | hp <;> cases hp
      · rcases hp with hp | hp <;> cases hp
      · cases he; exact Or.inr (Or.inr (Or.inr rfl))
    | putNew _ _ hty =>
      simp [Req.target] at hx; subst hx; simp [Store.set] at hg'; subst hg'
      rcases hc with ⟨hc, _⟩ | hci | ⟨_, _, _, hp, _⟩ | ⟨_, _, he⟩
      · exact Or.inr (hty c hc)
      · rcases hci.props.2.2.1 with hp | hp <;> cases hp
      · rcases hp with hp | hp <;> cases hp
      · cases he; exact Or.inr (Or.inr (Or.inr rfl))
    | @patch y _ g hg _ _ hty =>
      simp [Req.target] at hx; subst hx; simp [Store.set] at hg'; subst hg'
      rcases hty c hc with hc | hc
      · exact Or.inl ⟨g, hg, hc⟩
      · exact Or.inr hc
    | delete =>
      simp [Req.target] at hx; subst hx; simp [Store.set] at hg'
  · exact Or.inl ⟨g', by rw [← hs.frame hx]; exact hg', hc⟩

theorem set_self {st : Store} {x : Node} {v : Option Graph} : st.set x v x = v := by simp [Store.set]

/-- What a `PUT` stores types the document with a hierarchy class: the payload's, or the `dh:Item` `put()` adds. -/
theorem put_typed {tr : Tree} {st : Store} {x : Node} {payload G : Graph}
    (hroot : tr.isRoot x → TypedBy x payload)
    (hG : ∀ t, (payload t ∧ ¬ ownership x t ∧ ¬ containment x t) ∨ itemTyped tr x payload t → G t) :
    ∃ c, ownTypes (st.set x (some G)) x c ∧ hierClass c := by
  have hno : ∀ c, ¬ ownership x ⟨x, .rdfType, c⟩ ∧ ¬ containment x ⟨x, .rdfType, c⟩ := by
    intro c; constructor <;> rintro ⟨_, hp | hp⟩ <;> cases hp
  by_cases hr : tr.isRoot x
  · obtain ⟨c, hc, hh⟩ := hroot hr
    exact ⟨c, ⟨_, set_self, hG _ (Or.inl ⟨hc, hno c⟩)⟩, hh⟩
  · by_cases hk : payload ⟨x, .rdfType, .dhContainer⟩
    · exact ⟨_, ⟨_, set_self, hG _ (Or.inl ⟨hk, hno _⟩)⟩, Or.inr (Or.inl rfl)⟩
    · exact ⟨_, ⟨_, set_self, hG _ (Or.inr ⟨hr, hk, rfl⟩)⟩, Or.inr (Or.inr rfl)⟩

/-- **Every document stays typed with a hierarchy class.** -/
theorem Write.typed {tr agent st req st'} (hs : Write tr agent st req st') (h : Typed st) :
    Typed st' := by
  intro x hx
  by_cases hxt : x = req.target
  · cases hs with
    | @post y _ g hg =>
      simp [Req.target] at hxt; subst hxt
      obtain ⟨c, ⟨g0, hg0, hc⟩, hh⟩ := h x ⟨g, hg⟩
      rw [hg] at hg0; cases hg0
      exact ⟨c, ⟨_, set_self, Or.inl hc⟩, hh⟩
    | @putExisting y payload _ g _ _ _ _ hroot =>
      simp [Req.target] at hxt; subst hxt
      exact put_typed hroot fun t ht => ht.elim Or.inl fun ht => Or.inr (Or.inr (Or.inr ht))
    | @putNew y payload _ _ _ _ hroot =>
      simp [Req.target] at hxt; subst hxt
      exact put_typed hroot fun t ht => ht.elim Or.inl fun ht => Or.inr (Or.inr (Or.inr ht))
    | @patch y after _ _ _ _ _ htb =>
      simp [Req.target] at hxt; subst hxt
      obtain ⟨c, hc, hh⟩ := htb
      exact ⟨c, ⟨_, set_self, hc⟩, hh⟩
    | delete =>
      simp [Req.target] at hxt; subst hxt
      obtain ⟨g, hg⟩ := hx; simp [Store.set] at hg
  · obtain ⟨g, hg⟩ := hx
    rw [hs.frame hxt] at hg
    obtain ⟨c, ⟨g0, hg0, hc⟩, hh⟩ := h x ⟨g, hg⟩
    exact ⟨c, ⟨g0, by rw [hs.frame hxt]; exact hg0, hc⟩, hh⟩

/-! ## Ownership -/

/-- **Ownership confinement.** Whoever owns a document after a write owned it before, or created it with
that write. -/
theorem Write.owner_confined {tr agent st req st'} (hs : Write tr agent st req st')
    {y b : Node} (ho : owner st' y b) :
    owner st y b ∨ (y = req.target ∧ st y = none ∧ agent = some b) := by
  by_cases hy : y = req.target
  · subst hy
    cases hs with
    | post hg =>
      obtain ⟨g', hg', hb⟩ := ho
      simp [Store.set, Req.target] at hg'
      subst hg'
      rcases hb with hb | ⟨_, hno, _⟩
      · exact Or.inl ⟨_, hg, hb⟩
      · exact absurd ⟨rfl, Or.inl rfl⟩ hno
    | putExisting hg _ =>
      obtain ⟨g', hg', hb⟩ := ho
      simp [Store.set, Req.target] at hg'
      subst hg'
      rcases hb with ⟨_, hno, _⟩ | hci | ⟨hb, _⟩ | ⟨_, _, he⟩
      · exact absurd ⟨rfl, Or.inl rfl⟩ hno
      · rcases hci.props.2.2.1 with hp | hp <;> cases hp
      · exact Or.inl ⟨_, hg, hb⟩
      · cases he
    | putNew hn =>
      obtain ⟨g', hg', hb⟩ := ho
      simp [Store.set, Req.target] at hg'
      subst hg'
      rcases hb with ⟨_, hno, _⟩ | hci | ⟨a, ha, _, _, hab⟩ | ⟨_, _, he⟩
      · exact absurd ⟨rfl, Or.inl rfl⟩ hno
      · rcases hci.props.2.2.1 with hp | hp <;> cases hp
      · simp at hab; subst hab
        exact Or.inr ⟨rfl, hn, ha⟩
      · cases he
    | patch hg _ hkeep =>
      obtain ⟨g', hg', hb⟩ := ho
      simp [Store.set, Req.target] at hg'
      subst hg'
      exact Or.inl ⟨_, hg, (hkeep _ (Or.inl ⟨rfl, Or.inl rfl⟩)).1 hb⟩
    | delete =>
      obtain ⟨g', hg', _⟩ := ho
      simp [Store.set, Req.target] at hg'
  · obtain ⟨g, hg, hb⟩ := ho
    exact Or.inl ⟨g, by rw [← hs.frame hy]; exact hg, hb⟩

end LdhHttp
