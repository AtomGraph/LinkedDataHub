/-
The seeded authorizations, and what migrating the ones of a release before 6.0 changes.

Before 6.0 the seeds granted the whole of a dataspace through the hierarchy classes
(`acl:accessToClass def:Root, dh:Container, dh:Item`). The admin and end-user documents share those
classes, so such a grant was scoped by nothing but the query that read it. The migration
(`migrations/6.0-acl.ru.template`) rewrites each into `acl:accessTo` and `acl:default` on its dataspace's root.
-/
import LdhAcl.Theorems

namespace LdhAcl

/-- URI paths are finite: every non-root document's parent chain ends at a root. -/
def Site.Finite (site : Site) : Prop :=
  ∀ d, ¬ site.isRoot d → site.chain d site.euRoot ∨ site.chain d site.adRoot

/-- Every document the store has is typed with a hierarchy class. -/
def Typed (st : Store) : Prop := ∀ x, present st x → ∃ t, ownTypes st x t ∧ hierClass t

/-- An authorization with its targets replaced. -/
def Auth.withTargets (au : Auth) (accessTo default accessToClass : List Node) : Auth :=
  { au with accessTo, default, accessToClass }

theorem below_euRoot {site : Site} (hf : site.Finite) {d : Node} (hd : ¬ site.admin d)
    (hr : d ≠ site.euRoot) : site.chain d site.euRoot := by
  have hna : d ≠ site.adRoot := fun e => hd (e ▸ site.adRoot_admin)
  rcases hf d (fun h => h.elim hr hna) with hc | hc
  · exact hc
  · exact absurd ((chain_admin hc).1 site.adRoot_admin) hd

theorem below_adRoot {site : Site} (hf : site.Finite) {d : Node} (hd : site.admin d)
    (hr : d ≠ site.adRoot) : site.chain d site.adRoot := by
  have hne : d ≠ site.euRoot := fun e => site.euRoot_not_admin (e ▸ hd)
  rcases hf d (fun h => h.elim hne hr) with hc | hc
  · exact absurd ((chain_admin hc).2 hd) site.euRoot_not_admin
  · exact hc

/-- A grant on a root and its descendants covers every document the store has in that root's tree. -/
theorem root_grant_covers {site : Site} {st : Store} (h : Inv site st) {au : Auth} {sub}
    {root x : Node} (hc : site.chain x root ∨ x = root) (hx : present st x) :
    (au.withTargets [root] [root] []).covers sub (context st x) := by
  rw [covers_context]
  rcases hc with hc | rfl
  · exact Or.inr (Or.inl ⟨root, List.Mem.head _, (ancestor_iff_chain h hx).2 hc⟩)
  · exact Or.inl (List.Mem.head _)

/-! ## The admin role -/

/-- **The admin role in plain WAC.** `accessTo` and `acl:default` on the admin root cover every admin
document, which `ownerAclQuery` gave `acl:Control` over `def:Root` before 6.0 without looking at the
target. -/
theorem admin_role_covers {site : Site} {st : Store} (h : Inv site st) (hf : site.Finite) {au : Auth}
    {sub} {x : Node} (hx : site.admin x) (hp : present st x) :
    (au.withTargets [site.adRoot] [site.adRoot] []).covers sub (context st x) := by
  by_cases hr : x = site.adRoot
  · exact root_grant_covers h (Or.inr hr) hp
  · exact root_grant_covers h (Or.inl (below_adRoot hf hx hr)) hp

/-! ## Class grants become default grants -/

/-- The hierarchy classes, as the seeds list them. -/
def hierClasses : List Node := [.defRoot, .dhContainer, .dhItem]

theorem hierClass_mem {t : Node} (h : hierClass t) : t ∈ hierClasses := by
  rcases h with rfl | rfl | rfl <;> simp [hierClasses]

theorem class_grant_covers {st : Store} (ht : Typed st) {au : Auth} {sub : Node → Node → Prop}
    (hrefl : ∀ c, sub c c) {x : Node} (hp : present st x) :
    (au.withTargets [] [] hierClasses).covers sub (context st x) := by
  obtain ⟨t, hty, hh⟩ := ht x hp
  rw [covers_context]
  exact Or.inr (Or.inr ⟨t, hierClass_mem hh, t, hty, hrefl t⟩)

/-- **On the end-user dataspace the migration changes nothing.** A class grant on the hierarchy classes and
a default grant on the end-user root cover the same documents. -/
theorem migrate_endUser {site : Site} {rd : Reader} {st : Store} (h : Inv site st) (hf : site.Finite)
    (ht : Typed st) {au : Auth} {x : Node} (hx : ¬ site.admin x) (hp : present st x) :
    (au.withTargets [] [] hierClasses).covers rd.sub (context st x) ↔
      (au.withTargets [site.euRoot] [site.euRoot] []).covers rd.sub (context st x) := by
  refine ⟨fun _ => ?_, fun _ => class_grant_covers ht rd.sub_refl hp⟩
  by_cases hr : x = site.euRoot
  · exact root_grant_covers h (Or.inr hr) hp
  · exact root_grant_covers h (Or.inl (below_euRoot hf hx hr)) hp

/-- **On the admin dataspace the migration takes access away.** The class grant covers every admin
document; the default grant on the end-user root covers none. -/
theorem migrate_admin {site : Site} {rd : Reader} {st : Store} (h : Inv site st) (ht : Typed st)
    (hat : AdminTyped site st) {au : Auth} {x : Node} (hx : site.admin x) (hp : present st x) :
    (au.withTargets [] [] hierClasses).covers rd.sub (context st x) ∧
      ¬ (au.withTargets [site.euRoot] [site.euRoot] []).covers rd.sub (context st x) := by
  refine ⟨class_grant_covers ht rd.sub_refl hp, endUserOnly_confined h hat ?_ hx⟩
  refine ⟨?_, ?_, ?_⟩
  · intro t ht'; simp [Auth.withTargets] at ht'; subst ht'; exact site.euRoot_not_admin
  · intro c hc; simp [Auth.withTargets] at hc; subst hc; exact site.euRoot_not_admin
  · intro c hc; simp [Auth.withTargets] at hc

/-! ## Owner access -/

/-- The seeded owner-access authorization: `lacl:OwnerAgent` may read and write what it owns in the
end-user dataspace. -/
def ownerAccess (site : Site) : Auth :=
  ⟨[], [], [.owner], [.read, .append, .write], [site.euRoot], [site.euRoot], []⟩

theorem ownerAccess_endUserOnly (site : Site) (sub : Node → Node → Prop) :
    EndUserOnly site sub (ownerAccess site) := by
  refine ⟨?_, ?_, ?_⟩
  · intro t ht; simp [ownerAccess] at ht; subst ht; exact site.euRoot_not_admin
  · intro c hc; simp [ownerAccess] at hc; subst hc; exact site.euRoot_not_admin
  · intro c hc; simp [ownerAccess] at hc

/-- **Owner access is the owner grant of releases before 6.0 on the end-user dataspace.** The owner-access
authorization matches an agent on an end-user document exactly when the agent owns it, which is when
`createOwnerAuthorization` fired. -/
theorem ownerAccess_endUser {site : Site} {sub : Node → Node → Prop} {st : Store} (h : Inv site st)
    (hf : site.Finite) {M : Node → Node → Prop} {x a : Node} (hx : ¬ site.admin x) (hp : present st x) :
    ((ownerAccess site).principal M (owner st x) (some a) ∧
      (ownerAccess site).covers sub (context st x)) ↔ owner st x a := by
  have hc : (ownerAccess site).covers sub (context st x) := by
    have e : ownerAccess site = (ownerAccess site).withTargets [site.euRoot] [site.euRoot] [] := rfl
    rw [e]
    by_cases hr : x = site.euRoot
    · exact root_grant_covers h (Or.inr hr) hp
    · exact root_grant_covers h (Or.inl (below_euRoot hf hx hr)) hp
  simp only [Auth.principal, ownerAccess]
  constructor
  · rintro ⟨hpr, _⟩
    simp at hpr
    exact hpr
  · intro ho
    exact ⟨by simp; exact ho, hc⟩

/-- **Owner access opens nothing in the admin dataspace.** The owner grant of releases before 6.0 applied
there too, so an admin kept acl:Write on every authorization it created after leaving the owners group. -/
theorem ownerAccess_admin {site : Site} {rd : Reader} {st : Store} (h : Inv site st)
    (hat : AdminTyped site st) {x : Node} (hx : site.admin x) :
    ¬ (ownerAccess site).covers rd.sub (context st x) :=
  endUserOnly_confined h hat (ownerAccess_endUserOnly site rd.sub) hx

end LdhAcl
