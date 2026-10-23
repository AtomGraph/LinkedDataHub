/-
The ACL model the redesign targets: plain WAC over LinkedDataHub's document hierarchy.

This is a design, not a transcription. `LdhAcl.Model` describes the decision as deployed; this namespace
describes the one the redesign is to implement, so that its properties can be proven before any code is
written. It reuses the store (`Node`, `Graph`, `Store`), the modes, and the two own-graph lookups
(`ownTypes`, `owner`) of the deployed model.

What changes from the deployed decision:
* `acl:Control` means nothing: no request requires it, and no granted mode covers anything through it.
* `acl:default` is added, with union semantics: a default grant on `C` covers every descendant of `C`.
* the owner of a document is an agent class, `lacl:OwnerAgent`, granted by an ordinary authorization, in
  place of the authorization `createOwnerAuthorization` synthesizes;
* one decision serves both dataspaces: there is no `ownerAclQuery`;
* every triple the decision reads comes from a graph whose writers are trusted with it: types, ancestry and
  the owner from the document's own graph, authorizations and memberships from the admin document they are
  the primary topic of.
-/
import LdhAcl.Model

namespace LdhAcl.Wac

/-! ## The two dataspaces -/

/-- Deployment constants. The end-user and the admin dataspace are two URI trees: `parent` (the URI parent
`put()` resolves) never leaves a tree, and a tree's root is its only document with no parent. -/
structure Site where
  euRoot : Node
  adRoot : Node
  parent : Node → Node
  /-- The node belongs to the admin dataspace. -/
  admin : Node → Prop
  euRoot_not_admin : ¬ admin euRoot
  adRoot_admin : admin adRoot
  parent_admin : ∀ d, d ≠ euRoot → d ≠ adRoot → (admin (parent d) ↔ admin d)

def Site.isRoot (site : Site) (d : Node) : Prop := d = site.euRoot ∨ d = site.adRoot

/-- The classes of the document hierarchy, which both dataspaces type their documents with. -/
def hierClass (c : Node) : Prop := c = .defRoot ∨ c = .dhContainer ∨ c = .dhItem

/-! ## Containment and ancestry -/

def isContainment (t : Triple) : Prop := t.p = .siocHasParent ∨ t.p = .siocHasContainer

/-- `g` states that `d` is contained in `p`. -/
def contains (g : Graph) (d p : Node) : Prop :=
  g ⟨d, .siocHasParent, p⟩ ∨ g ⟨d, .siocHasContainer, p⟩

/-- A containment triple in *any* graph: what a path over `urn:x-arq:UnionGraph` sees. -/
def parentU (st : Store) (d p : Node) : Prop := ∃ y g, st y = some g ∧ contains g d p

/-- A containment triple in the document's own graph. -/
def parentO (st : Store) (d p : Node) : Prop := ∃ g, st d = some g ∧ contains g d p

/-- The transitive closure of `R`, built from the near end so that induction walks up the hierarchy. -/
inductive Anc (R : Node → Node → Prop) : Node → Node → Prop where
  | step {a b} : R a b → Anc R a b
  | trans {a b c} : R a b → Anc R b c → Anc R a c

/-- The ancestors the lookup finds: `$this (sioc:has_parent|sioc:has_container)+ ?ancestor` over the union
graph. -/
def ancestor (st : Store) : Node → Node → Prop := Anc (parentU st)

/-- The URI-parent chain from `d` up to its tree's root. -/
def Site.chain (site : Site) : Node → Node → Prop :=
  Anc (fun d p => ¬ site.isRoot d ∧ p = site.parent d)

/-! ## The admin dataset -/

/-- The agent classes the decision computes membership of. -/
inductive AgentClass where
  /-- `foaf:Agent`: everyone. -/
  | anyone
  /-- `acl:AuthenticatedAgent`: every agent with a WebID. -/
  | authenticated
  /-- `lacl:OwnerAgent`: the `acl:owner` of the document being accessed. -/
  | owner
  deriving DecidableEq, Repr

/-- An `acl:Authorization`. -/
structure Auth where
  agents : List Node              -- acl:agent
  groups : List Node              -- acl:agentGroup
  classes : List AgentClass       -- acl:agentClass
  modes : List Mode               -- acl:mode
  accessTo : List Node            -- acl:accessTo
  default : List Node             -- acl:default
  accessToClass : List Node       -- acl:accessToClass

/-- How the admin dataset is read. Authorizations and memberships are read per admin document, from that
document's own graph and only as its primary topic (`GRAPH ?g { ?g foaf:primaryTopic ?auth … }`): `auths d g`
is what graph `g` of document `d` contributes. `sub` is `rdfs:subClassOf*` over the admin ontology. -/
structure Reader where
  auths : Node → Graph → Auth → Prop
  member : Node → Graph → Node → Node → Prop
  sub : Node → Node → Prop
  sub_refl : ∀ c, sub c c

/-- The authorizations in force: those some admin document describes. -/
def authIn (site : Site) (rd : Reader) (st : Store) (au : Auth) : Prop :=
  ∃ d g, site.admin d ∧ st d = some g ∧ rd.auths d g au

/-- `?group foaf:member ?agent`, as some admin document states it. -/
def memberIn (site : Site) (rd : Reader) (st : Store) (grp a : Node) : Prop :=
  ∃ d g, site.admin d ∧ st d = some g ∧ rd.member d g grp a

/-! ## The document lookup -/

/-- The tag of a row the lookup returns: the `acl:` property an authorization must carry with the row's
node as object to match, or `acl:owner` for the row naming the document's owner. -/
inductive Rel where
  | accessTo | default | accessToClass | owner
  deriving DecidableEq, Repr

/-- `documentContextQuery`, run on the dataspace's store: `(?Rel ?Target)` rows for `x`, each bound in both
columns. The document itself, its ancestors (union graph), its own-graph types and its own-graph owner. -/
def context (st : Store) (x : Node) : Rel → Node → Prop
  | .accessTo, t => t = x
  | .default, c => ancestor st x c
  | .accessToClass, t => ownTypes st x t
  | .owner, a => owner st x a

/-! ## The decision -/

/-- The agent part of the ACL query. `owners` is the `acl:owner` rows of the lookup; Java turns them into the
`$OwnerAgentClass` switch, as it does `$AuthenticatedAgentClass`. -/
def Auth.principal (au : Auth) (member : Node → Node → Prop) (owners : Node → Prop) : Option Node → Prop
  | none => .anyone ∈ au.classes
  | some a => a ∈ au.agents ∨ (∃ grp ∈ au.groups, member grp a) ∨ .anyone ∈ au.classes ∨
      .authenticated ∈ au.classes ∨ (.owner ∈ au.classes ∧ owners a)

/-- `?auth ?Rel ?Target`: the authorization carries the row's property with the row's node, or, for a class,
a superclass of it. -/
def Auth.matchRow (au : Auth) (sub : Node → Node → Prop) : Rel → Node → Prop
  | .accessTo, t => t ∈ au.accessTo
  | .default, c => c ∈ au.default
  | .accessToClass, t => ∃ c ∈ au.accessToClass, sub t c
  | .owner, _ => False

/-- The target part of the ACL query: some row of the lookup matches. -/
def Auth.covers (au : Auth) (sub : Node → Node → Prop) (look : Rel → Node → Prop) : Prop :=
  ∃ r t, look r t ∧ au.matchRow sub r t

/-- The ACL query and `getAuthorizationByMode`, over an authorization set `A`, a membership relation `M` and
a lookup. -/
def grantWith (A : Auth → Prop) (M : Node → Node → Prop) (sub : Node → Node → Prop)
    (look : Rel → Node → Prop) (agent : Option Node) (m : Mode) : Prop :=
  ∃ au, A au ∧ au.principal M (look .owner) agent ∧ au.covers sub look ∧ ∃ g ∈ au.modes, g.covers m

def grant (site : Site) (rd : Reader) (st : Store) (agent : Option Node) (m : Mode) (x : Node) : Prop :=
  grantWith (authIn site rd st) (memberIn site rd st) rd.sub (context st x) agent m

/-- `AuthorizationFilter.authorize`. A `PUT` to a document the graph store does not have is a create,
decided on the parent, which must be typed `def:Root` or `dh:Container`. -/
def allow (site : Site) (rd : Reader) (st : Store) (agent : Option Node) (isPut : Prop) (m : Mode)
    (x : Node) : Prop :=
  ((present st x ∨ ¬ isPut) ∧ grant site rd st agent m x) ∨
  (¬ present st x ∧ isPut ∧
    (ownTypes st (site.parent x) .defRoot ∨ ownTypes st (site.parent x) .dhContainer) ∧
    grant site rd st agent m (site.parent x))

/-- The mode each method requires, as in the deployed filter. -/
def allowRequest (site : Site) (rd : Reader) (st : Store) (agent : Option Node) : Method → Node → Prop
  | .get, x => allow site rd st agent False .read x
  | .head, x => allow site rd st agent False .read x ∨ allow site rd st agent False .append x
  | .post, x => allow site rd st agent False .append x
  | .put, x => allow site rd st agent True .write x
  | .putCreate, x => allow site rd st agent True .append x
  | .patch, x => allow site rd st agent False .write x
  | .delete, x => allow site rd st agent False .write x

end LdhAcl.Wac
