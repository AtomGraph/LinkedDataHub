/-
The writes of `DocumentHierarchyGraphStoreImpl`, and the invariants they keep.

Each write touches one graph, the request URI's, and is modelled only in the triples the decision reads: the
document's ownership and containment. A graph written for document `x` may state containment of `x` only: a payload
with `sioc:has_parent` or `sioc:has_container` of any other subject is refused (`422`, `checkForeignContainment`),
and containment of `x` itself is stripped or guarded. That rule is what makes the union graph a faithful view of
containment.
-/
import LdhAcl.Model

namespace LdhAcl

/-- The write rule: every containment triple of `g` is about `x`. -/
def NoForeign (x : Node) (g : Graph) : Prop := ∀ t, g t → isContainment t → t.s = x

/-- The containment `put()` asserts for a non-root document: both `sioc:has_parent` and
`sioc:has_container` are allowed by the model, always pointing at the URI parent. -/
def containedIn (site : Site) (x : Node) (t : Triple) : Prop :=
  ¬ site.isRoot x ∧ t.s = x ∧ isContainment t ∧ t.o = site.parent x

/-- One authorized write by `agent`, from `st` to `st'`, on either dataspace's store. -/
inductive Step (site : Site) (rd : Reader) (agent : Option Node) : Store → Req → Store → Prop where
  | post {st x payload g} :
      allowRequest site rd st agent .post x →
      st x = some g →
      NoForeign x payload →
      Step site rd agent st (.post x payload)
        (st.set x (some fun t => g t ∨ (payload t ∧ ¬ ownership x t ∧ ¬ containment x t)))
  | putExisting {st x payload createOnly g} :
      allowRequest site rd st agent (Req.put x payload createOnly).method x →
      st x = some g →
      createOnly = false →
      NoForeign x payload →
      Step site rd agent st (.put x payload createOnly)
        (st.set x (some fun t =>
          (payload t ∧ ¬ ownership x t ∧ ¬ containment x t) ∨ containedIn site x t ∨
          (g t ∧ ownership x t)))
  | putNew {st x payload createOnly} :
      allowRequest site rd st agent (Req.put x payload createOnly).method x →
      st x = none →
      NoForeign x payload →
      Step site rd agent st (.put x payload createOnly)
        (st.set x (some fun t =>
          (payload t ∧ ¬ ownership x t ∧ ¬ containment x t) ∨ containedIn site x t ∨
          (∃ a, agent = some a ∧ t.s = x ∧ (t.p = .aclOwner ∨ t.p = .dctCreator) ∧ t.o = a)))
  | patch {st x after g} :
      allowRequest site rd st agent .patch x →
      st x = some g →
      NoForeign x after →
      (∀ t, ownership x t ∨ containment x t → (after t ↔ g t)) →
      Step site rd agent st (.patch x after) (st.set x (some after))
  | delete {st x} :
      allowRequest site rd st agent .delete x →
      ¬ site.isRoot x →
      ¬ hasChild st x →
      Step site rd agent st (.delete x) (st.set x none)

theorem Step.frame {site rd agent st req st'} (h : Step site rd agent st req st')
    {y : Node} (hy : y ≠ req.target) : st' y = st y := by
  cases h <;> simp [Store.set, Req.target] at hy ⊢ <;> simp [hy]

theorem Step.authorized {site rd agent st req st'} (h : Step site rd agent st req st') :
    allowRequest site rd st agent req.method req.target := by
  cases h <;> assumption

/-! ## Invariants -/

/-- What the write rule maintains: every containment triple sits in its subject's own graph. -/
def OwnGraphContainment (st : Store) : Prop :=
  ∀ y g t, st y = some g → g t → isContainment t → t.s = y

/-- A document's own graph points its containment at its URI parent and nowhere else. -/
def Exact (site : Site) (st : Store) : Prop :=
  ∀ d g p, st d = some g → contains g d p → ¬ site.isRoot d ∧ p = site.parent d

/-- Every non-root document's own graph states its containment. -/
def Contained (site : Site) (st : Store) : Prop :=
  ∀ d g, st d = some g → ¬ site.isRoot d → contains g d (site.parent d)

/-- Every non-root document's URI parent is in the store. -/
def Hier (site : Site) (st : Store) : Prop :=
  ∀ d, present st d → ¬ site.isRoot d → present st (site.parent d)

def RootsPresent (site : Site) (st : Store) : Prop :=
  present st site.euRoot ∧ present st site.adRoot

structure Inv (site : Site) (st : Store) : Prop where
  own : OwnGraphContainment st
  exact : Exact site st
  contained : Contained site st
  hier : Hier site st
  roots : RootsPresent site st

theorem present_set_self {st : Store} {x : Node} {g : Graph} : present (st.set x (some g)) x :=
  ⟨g, by simp [Store.set]⟩

theorem present_set_other {st : Store} {x z : Node} {v} (h : z ≠ x) :
    present (st.set x v) z ↔ present st z := by
  simp [present, Store.set, h]

/-- Every write but a delete leaves a graph at its target. -/
theorem Step.present_target {site rd agent st req st'} (h : Step site rd agent st req st')
    (hd : ∀ x, req ≠ .delete x) : present st' req.target := by
  cases h with
  | delete => exact absurd rfl (hd _)
  | _ => exact present_set_self

/-- Every write but a delete keeps every present document present. -/
theorem Step.present_mono {site rd agent st req st'} (h : Step site rd agent st req st')
    (hd : ∀ x, req ≠ .delete x) {p : Node} (hp : present st p) : present st' p := by
  by_cases hpx : p = req.target
  · rw [hpx]; exact h.present_target hd
  · obtain ⟨g, hg⟩ := hp; exact ⟨g, by rw [h.frame hpx]; exact hg⟩

theorem ownership_not_containment {x : Node} {t : Triple} (ho : ownership x t) (hc : isContainment t) :
    False := by
  obtain ⟨_, hp⟩ := ho
  rcases hp with hp | hp <;> rcases hc with hc | hc <;> rw [hp] at hc <;> cases hc

theorem own_preserved {site rd agent st req st'} (hs : Step site rd agent st req st')
    (h : OwnGraphContainment st) : OwnGraphContainment st' := by
  intro y g' t hy ht hc
  by_cases hyx : y = req.target
  · cases hs with
    | @post x _ g _ hg hnf =>
      simp [Req.target] at hyx; subst hyx; simp [Store.set] at hy; subst hy
      rcases ht with ht | ⟨ht, _⟩
      · exact h _ _ _ hg ht hc
      · exact hnf _ ht hc
    | putExisting _ _ _ hnf =>
      simp [Req.target] at hyx; subst hyx; simp [Store.set] at hy; subst hy
      rcases ht with ⟨ht, _⟩ | ⟨_, hs, _⟩ | ⟨_, hs, _⟩
      · exact hnf _ ht hc
      · exact hs
      · exact hs
    | putNew _ _ hnf =>
      simp [Req.target] at hyx; subst hyx; simp [Store.set] at hy; subst hy
      rcases ht with ⟨ht, _⟩ | ⟨_, hs, _⟩ | ⟨_, _, hs, _⟩
      · exact hnf _ ht hc
      · exact hs
      · exact hs
    | patch _ _ hnf _ =>
      simp [Req.target] at hyx; subst hyx; simp [Store.set] at hy; subst hy
      exact hnf _ ht hc
    | delete =>
      simp [Req.target] at hyx; subst hyx; simp [Store.set] at hy
  · rw [hs.frame hyx] at hy
    exact h _ _ _ hy ht hc

theorem exact_preserved {site rd agent st req st'} (hs : Step site rd agent st req st')
    (h : Exact site st) : Exact site st' := by
  intro d g' p hd hc
  by_cases hdx : d = req.target
  · cases hs with
    | @post x _ g _ hg _ =>
      simp [Req.target] at hdx; subst hdx; simp [Store.set] at hd; subst hd
      rcases hc with (hc | ⟨_, _, hn⟩) | (hc | ⟨_, _, hn⟩)
      · exact h _ _ _ hg (Or.inl hc)
      · exact absurd ⟨rfl, Or.inl rfl⟩ hn
      · exact h _ _ _ hg (Or.inr hc)
      · exact absurd ⟨rfl, Or.inr rfl⟩ hn
    | putExisting =>
      simp [Req.target] at hdx; subst hdx; simp [Store.set] at hd; subst hd
      rcases hc with (⟨_, _, hn⟩ | ⟨hr, _, _, ho⟩ | ⟨_, ho⟩) | (⟨_, _, hn⟩ | ⟨hr, _, _, ho⟩ | ⟨_, ho⟩)
      · exact absurd ⟨rfl, Or.inl rfl⟩ hn
      · exact ⟨hr, ho⟩
      · exact (ownership_not_containment ho (Or.inl rfl)).elim
      · exact absurd ⟨rfl, Or.inr rfl⟩ hn
      · exact ⟨hr, ho⟩
      · exact (ownership_not_containment ho (Or.inr rfl)).elim
    | putNew =>
      simp [Req.target] at hdx; subst hdx; simp [Store.set] at hd; subst hd
      rcases hc with (⟨_, _, hn⟩ | ⟨hr, _, _, ho⟩ | ⟨_, _, _, hp, _⟩) |
          (⟨_, _, hn⟩ | ⟨hr, _, _, ho⟩ | ⟨_, _, _, hp, _⟩)
      · exact absurd ⟨rfl, Or.inl rfl⟩ hn
      · exact ⟨hr, ho⟩
      · rcases hp with hp | hp <;> cases hp
      · exact absurd ⟨rfl, Or.inr rfl⟩ hn
      · exact ⟨hr, ho⟩
      · rcases hp with hp | hp <;> cases hp
    | @patch x _ g _ hg _ hkeep =>
      simp [Req.target] at hdx; subst hdx; simp [Store.set] at hd; subst hd
      rcases hc with hc | hc
      · exact h _ _ _ hg (Or.inl ((hkeep _ (Or.inr ⟨rfl, Or.inl rfl⟩)).1 hc))
      · exact h _ _ _ hg (Or.inr ((hkeep _ (Or.inr ⟨rfl, Or.inr rfl⟩)).1 hc))
    | delete =>
      simp [Req.target] at hdx; subst hdx; simp [Store.set] at hd
  · rw [hs.frame hdx] at hd
    exact h _ _ _ hd hc

theorem contained_preserved {site rd agent st req st'} (hs : Step site rd agent st req st')
    (h : Contained site st) : Contained site st' := by
  intro d g' hd hroot
  by_cases hdx : d = req.target
  · cases hs with
    | @post x _ g _ hg _ =>
      simp [Req.target] at hdx; subst hdx; simp [Store.set] at hd; subst hd
      rcases h d g hg hroot with hc | hc
      · exact Or.inl (Or.inl hc)
      · exact Or.inr (Or.inl hc)
    | putExisting =>
      simp [Req.target] at hdx; subst hdx; simp [Store.set] at hd; subst hd
      exact Or.inl (Or.inr (Or.inl ⟨hroot, rfl, Or.inl rfl, rfl⟩))
    | putNew =>
      simp [Req.target] at hdx; subst hdx; simp [Store.set] at hd; subst hd
      exact Or.inl (Or.inr (Or.inl ⟨hroot, rfl, Or.inl rfl, rfl⟩))
    | @patch x _ g _ hg _ hkeep =>
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

/-- A create is authorized only below a present parent. -/
theorem create_parent_present {site rd st agent m x} (hnew : st x = none)
    (ha : allow site rd st agent True m x) : present st (site.parent x) := by
  rcases ha with ⟨hp | hn, _⟩ | ⟨_, _, ht, _⟩
  · obtain ⟨g, hg⟩ := hp; simp [hnew] at hg
  · exact absurd trivial hn
  · rcases ht with ht | ht <;> exact ownTypes_present ht

theorem put_allow {site rd st agent x payload createOnly}
    (ha : allowRequest site rd st agent (Req.put x payload createOnly).method x) :
    ∃ m, allow site rd st agent True m x := by
  cases createOnly <;> exact ⟨_, ha⟩

theorem hier_preserved {site rd agent st req st'} (hs : Step site rd agent st req st')
    (h : Hier site st) (hc : Contained site st) : Hier site st' := by
  intro d hd hroot
  cases hs with
  | @delete x _ _ noChild =>
    have hdx : d ≠ x := by
      rintro rfl; obtain ⟨g, hg⟩ := hd; simp [Store.set] at hg
    have hd0 := (present_set_other hdx).1 hd
    have hp := h d hd0 hroot
    by_cases hpx : site.parent d = x
    · obtain ⟨g, hg⟩ := hd0
      have hcd := hc d g hg hroot
      rw [hpx] at hcd
      exact absurd ⟨d, g, hdx, hg, hcd⟩ noChild
    · exact (present_set_other hpx).2 hp
  | @putNew x _ _ ha hn hnf =>
    have hs' : Step site rd agent st (.put x _ _) _ := Step.putNew ha hn hnf
    apply hs'.present_mono (by intro _ h; cases h)
    by_cases hdx : d = x
    · subst hdx
      obtain ⟨m, ham⟩ := put_allow ha
      exact create_parent_present hn ham
    · exact h d ((present_set_other hdx).1 hd) hroot
  | @post x _ g ha hg hnf =>
    have hs' := Step.post (site := site) (rd := rd) (agent := agent) ha hg hnf
    apply hs'.present_mono (by intro _ h; cases h)
    by_cases hdx : d = x
    · subst hdx; exact h d ⟨_, hg⟩ hroot
    · exact h d ((present_set_other hdx).1 hd) hroot
  | @putExisting x _ _ g ha hg hc' hnf =>
    have hs' := Step.putExisting (site := site) (rd := rd) (agent := agent) ha hg hc' hnf
    apply hs'.present_mono (by intro _ h; cases h)
    by_cases hdx : d = x
    · subst hdx; exact h d ⟨_, hg⟩ hroot
    · exact h d ((present_set_other hdx).1 hd) hroot
  | @patch x _ g ha hg hnf hkeep =>
    have hs' := Step.patch (site := site) (rd := rd) (agent := agent) ha hg hnf hkeep
    apply hs'.present_mono (by intro _ h; cases h)
    by_cases hdx : d = x
    · subst hdx; exact h d ⟨_, hg⟩ hroot
    · exact h d ((present_set_other hdx).1 hd) hroot

theorem roots_preserved {site rd agent st req st'} (hs : Step site rd agent st req st')
    (h : RootsPresent site st) : RootsPresent site st' := by
  cases hs with
  | @delete x _ hr _ =>
    have he : site.euRoot ≠ x := fun e => hr (Or.inl e.symm)
    have ha : site.adRoot ≠ x := fun e => hr (Or.inr e.symm)
    exact ⟨(present_set_other he).2 h.1, (present_set_other ha).2 h.2⟩
  | post ha hg hnf =>
    have hs' := Step.post (site := site) (rd := rd) (agent := agent) ha hg hnf
    exact ⟨hs'.present_mono (by intro _ h; cases h) h.1, hs'.present_mono (by intro _ h; cases h) h.2⟩
  | putExisting ha hg hc hnf =>
    have hs' := Step.putExisting (site := site) (rd := rd) (agent := agent) ha hg hc hnf
    exact ⟨hs'.present_mono (by intro _ h; cases h) h.1, hs'.present_mono (by intro _ h; cases h) h.2⟩
  | putNew ha hn hnf =>
    have hs' := Step.putNew (site := site) (rd := rd) (agent := agent) ha hn hnf
    exact ⟨hs'.present_mono (by intro _ h; cases h) h.1, hs'.present_mono (by intro _ h; cases h) h.2⟩
  | patch ha hg hnf hkeep =>
    have hs' := Step.patch (site := site) (rd := rd) (agent := agent) ha hg hnf hkeep
    exact ⟨hs'.present_mono (by intro _ h; cases h) h.1, hs'.present_mono (by intro _ h; cases h) h.2⟩

/-- **The invariants hold after every write.** -/
theorem Step.inv {site rd agent st req st'} (hs : Step site rd agent st req st') (h : Inv site st) :
    Inv site st' :=
  ⟨own_preserved hs h.own, exact_preserved hs h.exact, contained_preserved hs h.contained,
    hier_preserved hs h.hier h.contained, roots_preserved hs h.roots⟩

end LdhAcl
