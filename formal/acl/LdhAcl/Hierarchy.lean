/-
The document hierarchy: every document but the root has its URI parent in the store.
-/
import LdhAcl.Theorems

namespace LdhAcl

/-- The hierarchy invariant. `put()` points every non-root document's containment at its URI parent, so
"the parent exists" is "the containment link resolves". -/
def Hier (ctx : Ctx) (st : Store) : Prop :=
  ∀ d, present st d → d ≠ ctx.root → present st (ctx.parent d)

theorem present_set_self {st : Store} {x : Node} {g : Graph} : present (st.set x (some g)) x :=
  ⟨g, by simp [Store.set]⟩

theorem present_set_other {st : Store} {x z : Node} {v} (h : z ≠ x) :
    present (st.set x v) z ↔ present st z := by
  simp [present, Store.set, h]

/-- The `PUT` that creates a document, read back from `allowRequest`: it is authorized as a `PUT`. -/
theorem put_allow {T ctx acl ra st agent x payload createOnly}
    (ha : allowRequest T ctx acl ra st agent (Req.put x payload createOnly).method x) :
    ∃ m, allow T ctx acl st agent True m x := by
  cases createOnly <;> exact ⟨_, ha⟩

/-- **The hierarchy is preserved** under the own-graph type view and a `DELETE` that refuses a document
with children. -/
theorem hier_preserved {ctx acl ra agent st req st'}
    (hs : Step ownTypes ctx acl ra .refuseNonEmpty agent st req st') (h : Hier ctx st) : Hier ctx st' := by
  intro d hd hroot
  cases hs with
  | @post x _ _ _ hg =>
    by_cases hdx : d = x
    · subst hdx
      have hp := h d ⟨_, hg⟩ hroot
      by_cases hpx : ctx.parent d = d
      · rw [hpx]; exact present_set_self
      · exact (present_set_other hpx).2 hp
    · have hp := h d ((present_set_other hdx).1 hd) hroot
      by_cases hpx : ctx.parent d = x
      · rw [hpx]; exact present_set_self
      · exact (present_set_other hpx).2 hp
  | @putExisting x _ _ _ _ hg _ =>
    by_cases hdx : d = x
    · subst hdx
      have hp := h d ⟨_, hg⟩ hroot
      by_cases hpx : ctx.parent d = d
      · rw [hpx]; exact present_set_self
      · exact (present_set_other hpx).2 hp
    · have hp := h d ((present_set_other hdx).1 hd) hroot
      by_cases hpx : ctx.parent d = x
      · rw [hpx]; exact present_set_self
      · exact (present_set_other hpx).2 hp
  | @putNew x _ _ ha hn =>
    by_cases hdx : d = x
    · subst hdx
      obtain ⟨m, ham⟩ := put_allow ha
      have hp := (create_needs_parent hn ham).1
      have hpx : ctx.parent d ≠ d := by
        intro e; rw [e] at hp; obtain ⟨g, hg⟩ := hp; simp [hn] at hg
      exact (present_set_other hpx).2 hp
    · have hp := h d ((present_set_other hdx).1 hd) hroot
      by_cases hpx : ctx.parent d = x
      · rw [hpx]; exact present_set_self
      · exact (present_set_other hpx).2 hp
  | @patch x _ _ _ hg _ =>
    by_cases hdx : d = x
    · subst hdx
      have hp := h d ⟨_, hg⟩ hroot
      by_cases hpx : ctx.parent d = d
      · rw [hpx]; exact present_set_self
      · exact (present_set_other hpx).2 hp
    · have hp := h d ((present_set_other hdx).1 hd) hroot
      by_cases hpx : ctx.parent d = x
      · rw [hpx]; exact present_set_self
      · exact (present_set_other hpx).2 hp
  | @delete x _ _ guard =>
    by_cases hdx : d = x
    · subst hdx; obtain ⟨g, hg⟩ := hd; simp [Store.set] at hg
    · have hd0 := (present_set_other hdx).1 hd
      have hp := h d hd0 hroot
      by_cases hpx : ctx.parent d = x
      · exact absurd ⟨d, hdx, hd0, hpx⟩ (guard rfl)
      · exact (present_set_other hpx).2 hp

end LdhAcl
