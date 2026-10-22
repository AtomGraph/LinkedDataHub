/-
What the admin decision guarantees.
-/
import LdhAcl.Hierarchy

namespace LdhAcl

/-- End-user grants are always for a target: `aclQuery` matches only authorizations that target the
document or one of its classes. -/
theorem aclGrant_targeted {adm : Admin} {agent m x ty} (h : aclGrant adm agent m x ty) :
    ∃ au ∈ adm.auths, au.targets adm x ty := by
  obtain ⟨au, hau, _, ht, _⟩ := h; exact ⟨au, hau, ht⟩

/-- **The admin role.** Outside the documents the admin application makes public, an authorization opens an
admin document only if it carries `acl:Control` over `def:Root`. Control over a single document, or over a
narrower class, opens nothing. -/
theorem adminMatch_role {ctx : Ctx} {adm : Admin} {au : Auth} {agent x ty}
    (h : adminMatch ctx adm agent x ty au) (hx : ¬ ctx.adminPublic x) :
    Mode.control ∈ au.modes ∧ Node.defRoot ∈ au.accessToClass := by
  rcases h with ⟨hc, hr, _⟩ | ⟨_, _, hp⟩
  · exact ⟨hc, hr⟩
  · exact absurd hp hx

/-- Anonymous access to admin documents is limited to `Ctx.adminPublic`. -/
theorem adminMatch_anonymous_public {ctx : Ctx} {adm : Admin} {au : Auth} {x ty}
    (h : adminMatch ctx adm none x ty au) : ctx.adminPublic x := by
  rcases h with ⟨_, _, _, ha, _⟩ | ⟨_, _, hp⟩
  · cases ha
  · exact hp

/-- A signed-in agent gets no more of the admin dataspace through agent classes than an anonymous one: without
the admin role, it is limited to `Ctx.adminPublic` too. -/
theorem adminMatch_authenticated_public {ctx : Ctx} {adm : Admin} {au : Auth} {a x ty}
    (h : adminMatch ctx adm (some a) x ty au)
    (hrole : ¬ (Mode.control ∈ au.modes ∧ Node.defRoot ∈ au.accessToClass)) : ctx.adminPublic x := by
  rcases h with ⟨hc, hr, _⟩ | ⟨_, _, hp⟩
  · exact absurd ⟨hc, hr⟩ hrole
  · exact hp

/-- The owners keep every admin document: a group's `acl:Control` over `def:Root` matches whatever the target. -/
theorem adminMatch_owners {ctx : Ctx} {adm : Admin} {au : Auth} {a g : Node}
    (hc : Mode.control ∈ au.modes) (hr : Node.defRoot ∈ au.accessToClass) (hg : g ∈ au.groups)
    (hm : adm.member g a) (x : Node) (ty : Node → Prop) :
    adminMatch ctx adm (some a) x ty au :=
  Or.inl ⟨hc, hr, a, rfl, Or.inr ⟨g, hg, hm⟩⟩

end LdhAcl
