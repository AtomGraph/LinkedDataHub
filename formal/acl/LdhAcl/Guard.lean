/-
The decision for a query: `allowRequest` decides one document for an agent, `Grants.guard` decides for an agent, inside a
SPARQL query, which graphs it reads. The two are the same decision read in opposite directions. Per document, the
document's context rows (`documentContextQuery`) are fixed and the ACL query asks for authorizations matching them;
per query, the ACL query runs with the document left open, giving the rows the agent's authorizations name
(`Authorizer.getGrantQuery`), and the context of each graph is asked whether it meets one.
-/
import LdhAcl.Model

namespace LdhAcl

open LdhHttp

/-- `Authorizer.getGrantQuery`: the `(?Rel ?Target)` rows the authorizations name for the agent with a mode covering
`m`, the ACL query's pattern with no document's rows injected. `$OwnerAgentClass` is `lacl:OwnerAgent` on the owner's
run and nothing otherwise, so the owner part of `Auth.principal` holds of everyone or of no one. -/
def grantRows (A : Auth → Prop) (M : Node → Node → Prop) (sub : Node → Node → Prop) (agent : Option Node)
    (isOwner : Prop) (m : Mode) (r : Rel) (t : Node) : Prop :=
  ∃ au, A au ∧ au.principal M (fun _ => isOwner) agent ∧ au.matchRow sub r t ∧ ∃ g ∈ au.modes, g.covers m

/-- `Grants.guard`, as `Grants.of` builds it: the graph's context meets a row of the non-owner run, or it names the
agent as its owner and meets a row only the owner's run adds. -/
def guardWith (A : Auth → Prop) (M : Node → Node → Prop) (sub : Node → Node → Prop) (look : Rel → Node → Prop)
    (agent : Option Node) (m : Mode) : Prop :=
  (∃ r t, look r t ∧ grantRows A M sub agent False m r t) ∨
  (∃ a, agent = some a ∧ look .owner a ∧
    ∃ r t, look r t ∧ grantRows A M sub agent True m r t ∧ ¬ grantRows A M sub agent False m r t)

/-- The agent part depends on the owners only at the agent. -/
theorem Auth.principal_at {au : Auth} {M : Node → Node → Prop} {O O' : Node → Prop} {a : Node}
    (h : O a → O' a) : au.principal M O (some a) → au.principal M O' (some a) := by
  rintro (h1 | h2 | h3 | h4 | ⟨hc, ho⟩)
  · exact Or.inl h1
  · exact Or.inr (Or.inl h2)
  · exact Or.inr (Or.inr (Or.inl h3))
  · exact Or.inr (Or.inr (Or.inr (Or.inl h4)))
  · exact Or.inr (Or.inr (Or.inr (Or.inr ⟨hc, h ho⟩)))

/-- Without its owner part, the agent part holds whoever the owners are. -/
theorem Auth.principal_notOwner {au : Auth} {M : Node → Node → Prop} {O O' : Node → Prop} {agent : Option Node}
    (h : au.principal M O agent) (hn : ¬ (∃ a, agent = some a ∧ AgentClass.owner ∈ au.classes ∧ O a)) :
    au.principal M O' agent := by
  cases agent with
  | none => exact h
  | some a =>
    rcases h with h1 | h2 | h3 | h4 | ⟨hc, ho⟩
    · exact Or.inl h1
    · exact Or.inr (Or.inl h2)
    · exact Or.inr (Or.inr (Or.inl h3))
    · exact Or.inr (Or.inr (Or.inr (Or.inl h4)))
    · exact absurd ⟨a, rfl, hc, ho⟩ hn

/-- **The query decides as the document does.** A graph passes the guard exactly when the per-document decision
grants the agent the mode on it: for every authorization set, membership relation, subclass relation and context. -/
theorem guardWith_iff {A : Auth → Prop} {M : Node → Node → Prop} {sub : Node → Node → Prop}
    {look : Rel → Node → Prop} {agent : Option Node} {m : Mode} :
    guardWith A M sub look agent m ↔ grantWith A M sub look agent m := by
  constructor
  · rintro (⟨r, t, hl, au, hA, hp, hm, hmode⟩ | ⟨a, rfl, ho, r, t, hl, ⟨au, hA, hp, hm, hmode⟩, _⟩)
    · exact ⟨au, hA, Auth.principal_notOwner hp (fun ⟨_, _, _, hf⟩ => hf), ⟨r, t, hl, hm⟩, hmode⟩
    · exact ⟨au, hA, Auth.principal_at (fun _ => ho) hp, ⟨r, t, hl, hm⟩, hmode⟩
  · rintro ⟨au, hA, hp, ⟨r, t, hl, hm⟩, hmode⟩
    by_cases hown : ∃ a, agent = some a ∧ AgentClass.owner ∈ au.classes ∧ look .owner a
    · obtain ⟨a, rfl, hc, ho⟩ := hown
      by_cases hrow : grantRows A M sub (some a) False m r t
      · exact Or.inl ⟨r, t, hl, hrow⟩
      · exact Or.inr ⟨a, rfl, ho, r, t, hl,
          ⟨au, hA, Or.inr (Or.inr (Or.inr (Or.inr ⟨hc, trivial⟩))), hm, hmode⟩, hrow⟩
    · exact Or.inl ⟨r, t, hl, au, hA, Auth.principal_notOwner hp hown, hm, hmode⟩

/-- The guard on graph `x` of the dataspace's store. -/
def guard (site : Site) (rd : Reader) (st : Store) (agent : Option Node) (m : Mode) (x : Node) : Prop :=
  guardWith (authIn site rd st) (memberIn site rd st) rd.sub (context st x) agent m

/-- `guardWith_iff` on the store: the graphs a query reads are the documents `grant` lets the agent read. -/
theorem guard_iff {site : Site} {rd : Reader} {st : Store} {agent : Option Node} {m : Mode} {x : Node} :
    guard site rd st agent m x ↔ grant site rd st agent m x :=
  guardWith_iff

end LdhAcl
