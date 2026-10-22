/-
Where the deployed definitions differ from the ones the theorems are proven under.

`Theorems.lean` and `Hierarchy.lean` prove locality, creation and the hierarchy for `ownTypes`. The code
runs `types`; this file states the properties of it that the proofs rely on not holding. The admin query has
no corrected definition yet; its properties are stated as they are.
-/
import LdhAcl.Hierarchy

namespace LdhAcl

/-! ## `documentTypeQuery` -/

/-- `types` reads graphs other than the document's own: a graph `x` that types `y` as
`nfo:FileDataObject` contributes every type it asserts for `y`. This is what `allow_local` needs not to
hold. -/
theorem types_reads_other_graphs {st : Store} {x y t : Node} {g : Graph}
    (hf : g ⟨y, .rdfType, .nfoFileDataObject⟩) (ht : g ⟨y, .rdfType, t⟩) :
    types (st.set x (some g)) y t :=
  Or.inr ⟨x, g, by simp [Store.set], hf, ht⟩

/-- A write to one graph changes the types of another node. -/
theorem types_not_local : ∃ (st : Store) (x y : Node) (g : Graph) (t : Node),
    y ≠ x ∧ (st.set x (some g)) y = st y ∧ types (st.set x (some g)) y t ∧ ¬ types st y t := by
  let y := Node.iri 1
  let g : Graph := fun tr => tr = ⟨y, .rdfType, .nfoFileDataObject⟩ ∨ tr = ⟨y, .rdfType, .iri 2⟩
  refine ⟨fun _ => none, .iri 0, y, g, .iri 2, by decide, by simp [Store.set, y], ?_, ?_⟩
  · exact types_reads_other_graphs (Or.inl rfl) (Or.inr rfl)
  · rintro (⟨_, h, _⟩ | ⟨_, _, h, _⟩) <;> simp at h

/-- `types` can find types for a node with no graph, so the filter's notion of existence (typed) and the
graph store's (graph present) differ. -/
theorem types_without_graph : ∃ (st : Store) (y t : Node), types st y t ∧ ¬ present st y := by
  let y := Node.iri 1
  let g : Graph := fun tr => tr = ⟨y, .rdfType, .nfoFileDataObject⟩
  refine ⟨Store.set (fun _ => none) (.iri 0) (some g), y, .nfoFileDataObject, ?_, ?_⟩
  · exact types_reads_other_graphs rfl rfl
  · rintro ⟨_, h⟩; simp [Store.set, y] at h

/-- A `PUT` to a typed node is decided on the node itself: the parent is not consulted. Together with
`types_without_graph`, a `PUT` can create a document without the parent conditions of
`create_needs_parent`. -/
theorem put_typed_skips_parent {T ctx acl st agent m x} (typed : ∃ t, T st x t)
    (hg : acl agent m x (T st x)) : allow T ctx acl st agent True m x :=
  Or.inl ⟨Or.inl typed, Or.inr hg⟩

/-! ## `ownerAclQuery` -/

/-- End-user grants are always for a target: `aclQuery` matches only authorizations that target the
document or one of its classes. -/
theorem aclGrant_targeted {adm : Admin} {agent m x ty} (h : aclGrant adm agent m x ty) :
    ∃ au ∈ adm.auths, au.targets adm x ty := by
  obtain ⟨au, hau, _, ht, _⟩ := h; exact ⟨au, hau, ht⟩

/-- The admin query's Control branch matches whatever the document: an authorization carrying
`acl:Control` for the agent matches every admin document, whatever its `acl:accessTo` or
`acl:accessToClass`. -/
theorem adminMatch_control_untargeted {ctx : Ctx} {adm : Admin} {au : Auth} {a : Node}
    (hc : Mode.control ∈ au.modes) (ha : a ∈ au.agents) (x : Node) (ty : Node → Prop) :
    adminMatch ctx adm (some a) x ty au :=
  Or.inl ⟨hc, a, rfl, Or.inl ha⟩

/-- Anonymous access to admin documents is limited to `Ctx.adminPublic`. -/
theorem adminMatch_anonymous_public {ctx : Ctx} {adm : Admin} {au : Auth} {x ty}
    (h : adminMatch ctx adm none x ty au) : ctx.adminPublic x := by
  rcases h with ⟨_, _, ha, _⟩ | ⟨_, hn, _⟩ | ⟨_, _, _, hp⟩
  · cases ha
  · exact absurd rfl hn
  · exact hp

/-- Authenticated access to admin documents carries no such limit: an `acl:AuthenticatedAgent`
authorization matches every admin document it targets, `Ctx.adminPublic` or not. -/
theorem adminMatch_authenticated_unlimited {ctx : Ctx} {adm : Admin} {au : Auth} {a x ty}
    (hau : au.authenticated = true) (ht : au.targets adm x ty) :
    adminMatch ctx adm (some a) x ty au :=
  Or.inr (Or.inl ⟨hau, by simp, ht⟩)

end LdhAcl
