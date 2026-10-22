/-
The admin query as deployed. It has no corrected definition yet, so its properties are stated as they are.
-/
import LdhAcl.Hierarchy

namespace LdhAcl

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
