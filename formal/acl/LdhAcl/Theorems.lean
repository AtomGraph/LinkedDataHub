/-
What the end-user decision guarantees.
-/
import LdhAcl.Step

namespace LdhAcl

/-! ## Modes -/

theorem write_covers_append : Mode.covers .write .append := Or.inr ⟨rfl, rfl⟩

/-- Only acl:Control covers acl:Control. -/
theorem covers_control {g : Mode} : g.covers .control ↔ g = .control := by
  cases g <;> simp [Mode.covers]

/-! ## Locality -/

theorem ownTypes_local {st st' : Store} {x : Node} (h : st' x = st x) : ownTypes st' x = ownTypes st x := by
  funext t; simp [ownTypes, h]

/-- A document's types are its own graph's: for a node with a graph, `types` is `ownTypes`. -/
theorem types_present {st : Store} {x : Node} (hp : present st x) : types st x = ownTypes st x := by
  obtain ⟨g, hg⟩ := hp
  funext t; apply propext
  simp only [types, ownTypes, hg]
  constructor
  · rintro (h | ⟨h, _⟩)
    · exact h
    · cases h
  · intro h; exact Or.inl h

/-- A node without a graph of its own can only be typed `nfo:FileDataObject`, whatever other graphs assert
about it. -/
theorem types_absent {st : Store} {x t : Node} (hn : ¬ present st x) (h : types st x t) : t = .nfoFileDataObject := by
  rcases h with ⟨g, hg, _⟩ | ⟨_, rfl, _⟩
  · exact absurd ⟨g, hg⟩ hn
  · rfl

theorem owner_local {st st' : Store} {x a : Node} (h : st' x = st x) : owner st' x a ↔ owner st x a := by
  simp [owner, h]

theorem ownerGrant_local {st st' : Store} {x : Node} {agent m} (h : st' x = st x) :
    ownerGrant st' agent m x ↔ ownerGrant st agent m x := by
  simp [ownerGrant, owner_local h]

/-- **Authority locality.** The decision about an existing document `y` (for any agent, mode and method)
depends only on graph `y` and the admin dataset: its types and its owner are read from its own graph, and an
existing `y` never takes the `PUT` fallback, so the parent's graph does not enter. -/
theorem allow_local {ctx acl} {st st' : Store} {y : Node} (h : st' y = st y) (hp : present st y)
    {agent isPut m} :
    allow types ctx acl st' agent isPut m y ↔ allow types ctx acl st agent isPut m y := by
  have hp' : present st' y := by obtain ⟨g, hg⟩ := hp; exact ⟨g, by rw [h]; exact hg⟩
  have ht : types st' y = types st y := by
    rw [types_present hp', types_present hp, ownTypes_local h]
  simp only [allow, ht, ownerGrant_local h]
  constructor
  · rintro (⟨_, hg⟩ | ⟨hn, _⟩)
    · exact Or.inl ⟨Or.inl hp, hg⟩
    · exact absurd hp' hn
  · rintro (⟨_, hg⟩ | ⟨hn, _⟩)
    · exact Or.inl ⟨Or.inl hp', hg⟩
    · exact absurd hp hn

/-- A step on `x` changes no decision about any other existing document. -/
theorem step_preserves_other_decisions {ctx acl ra agent st req st'}
    (hs : Step types ctx acl ra agent st req st') {y : Node} (hy : y ≠ req.target)
    (hp : present st y) {agent' isPut m} :
    allow types ctx acl st' agent' isPut m y ↔ allow types ctx acl st agent' isPut m y :=
  allow_local (hs.frame hy) hp

/-! ## Ownership -/

/-- **Ownership confinement.** After any step, whoever owns a document owned it before, or the document is
the one the step created and the owner is the agent that created it. This holds under any type view:
ownership is read from the document's own graph, and every write to that graph holds it fixed. -/
theorem owner_confined {T ctx acl ra agent st req st'} (hs : Step T ctx acl ra agent st req st')
    {y b : Node} (ho : owner st' y b) :
    owner st y b ∨ (y = req.target ∧ st y = none ∧ agent = some b) := by
  by_cases hy : y = req.target
  · subst hy
    cases hs with
    | post _ hg =>
      obtain ⟨g', hg', hb⟩ := ho
      simp [Store.set, Req.target] at hg'
      subst hg'
      rcases hb with hb | ⟨_, hno, _⟩
      · exact Or.inl ⟨_, hg, hb⟩
      · exact absurd ⟨rfl, Or.inl rfl⟩ hno
    | putExisting _ hg _ =>
      obtain ⟨g', hg', hb⟩ := ho
      simp [Store.set, Req.target] at hg'
      subst hg'
      rcases hb with ⟨_, hno, _⟩ | ⟨_, _, hp, _⟩ | ⟨hb, _⟩
      · exact absurd ⟨rfl, Or.inl rfl⟩ hno
      · cases hp <;> contradiction
      · exact Or.inl ⟨_, hg, hb⟩
    | putNew _ hn =>
      obtain ⟨g', hg', hb⟩ := ho
      simp [Store.set, Req.target] at hg'
      subst hg'
      rcases hb with ⟨_, hno, _⟩ | ⟨_, _, hp, _⟩ | ⟨a, ha, _, _, hab⟩
      · exact absurd ⟨rfl, Or.inl rfl⟩ hno
      · cases hp <;> contradiction
      · simp at hab; subst hab
        exact Or.inr ⟨rfl, hn, ha⟩
    | patch _ hg hkeep =>
      obtain ⟨g', hg', hb⟩ := ho
      simp [Store.set, Req.target] at hg'
      subst hg'
      exact Or.inl ⟨_, hg, (hkeep _ (Or.inl ⟨rfl, Or.inl rfl⟩)).1 hb⟩
    | delete =>
      obtain ⟨g', hg', _⟩ := ho
      simp [Store.set, Req.target] at hg'
  · exact Or.inl ((owner_local (hs.frame hy)).1 ho)

/-! ## Creation -/

theorem ownTypes_present {st : Store} {x t : Node} (h : ownTypes st x t) : present st x := by
  obtain ⟨g, hg, _⟩ := h; exact ⟨g, hg⟩

theorem ownerGrant_present {st : Store} {agent m x} (h : ownerGrant st agent m x) : present st x := by
  obtain ⟨_, _, ⟨g, hg, _⟩, _⟩ := h; exact ⟨g, hg⟩

/-- Only a document with a graph is typed a container or the root: the upload branch types nothing but
`nfo:FileDataObject`. -/
theorem types_container_present {st : Store} {x t : Node} (h : types st x t) (ht : t = .defRoot ∨ t = .dhContainer) :
    present st x := by
  rcases h with ⟨g, hg, _⟩ | ⟨_, rfl, _⟩
  · exact ⟨g, hg⟩
  · rcases ht with h | h <;> cases h

/-- **Creation needs the parent.** A `PUT` that creates `x` is authorized only if the parent exists, is typed
`def:Root` or `dh:Container`, and the agent owns it or holds a grant on it. -/
theorem create_needs_parent {ctx acl st agent m x}
    (hnew : st x = none) (ha : allow types ctx acl st agent True m x) :
    present st (ctx.parent x) ∧
    (types st (ctx.parent x) .defRoot ∨ types st (ctx.parent x) .dhContainer) ∧
    (ownerGrant st agent m (ctx.parent x) ∨ acl agent m (ctx.parent x) (types st (ctx.parent x))) := by
  have notPresent : ¬ present st x := by rintro ⟨g, hg⟩; simp [hnew] at hg
  rcases ha with ⟨hpx | hnp, _⟩ | ⟨_, _, hpt, hg⟩
  · exact absurd hpx notPresent
  · exact absurd trivial hnp
  · rcases hg with hg | hg
    · exact absurd (ownerGrant_present hg) notPresent
    · have hp : present st (ctx.parent x) := by
        rcases hpt with h | h
        · exact types_container_present h (Or.inl rfl)
        · exact types_container_present h (Or.inr rfl)
      exact ⟨hp, hpt, hg⟩

end LdhAcl
