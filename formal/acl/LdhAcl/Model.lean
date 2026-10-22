/-
The authorization decision of `AuthorizationFilter` and the state it reads.

Everything the decision consults is a function of two things: the end-user (or admin) store, one named
graph per document, and the admin dataset's authorizations, group memberships and class hierarchy. The
SPARQL queries in `web.xml` (`documentTypeQuery`, `documentOwnerQuery`, `aclQuery`, `ownerAclQuery`) are
transcribed as predicates over that state, one definition per query.
-/
namespace LdhAcl

/-- RDF nodes. The vocabulary terms the decision reads are constructors of their own; every other IRI is
`iri n`. Literals play no part in the decision and are not modelled. -/
inductive Node where
  | rdfType | aclOwner | dctCreator | siocHasParent | siocHasContainer
  | nfoFileDataObject | dhContainer | dhItem | defRoot
  | iri (n : Nat)
  deriving DecidableEq, Repr

/-- `acl:Read`, `acl:Append`, `acl:Write`, `acl:Control`. -/
inductive Mode where
  | read | append | write | control
  deriving DecidableEq, Repr

/-- `AccessModes.covering`: a granted mode covers the required one if it is that mode or one of its
superclasses in `acl.rdf`, where the only edge between modes is `acl:Append rdfs:subClassOf acl:Write`. -/
def Mode.covers (granted required : Mode) : Prop :=
  granted = required ∨ (granted = .write ∧ required = .append)

structure Triple where
  s : Node
  p : Node
  o : Node
  deriving DecidableEq, Repr

/-- A named graph, as the set of its triples. -/
abbrev Graph := Triple → Prop

/-- A quad store with one named graph per document; `none` is a graph that does not exist. The default
graph is always empty and is not modelled. -/
abbrev Store := Node → Option Graph

/-- The graph store's notion of existence: the document's graph is there. -/
def present (st : Store) (x : Node) : Prop := ∃ g, st x = some g

/-- The store with graph `x` replaced by `v`. -/
def Store.set (st : Store) (x : Node) (v : Option Graph) : Store :=
  fun y => if y = x then v else st y

/-! ## The admin dataset -/

/-- An `acl:Authorization`, as the ACL queries match it. -/
structure Auth where
  agents : List Node          -- acl:agent
  groups : List Node          -- acl:agentGroup
  anyone : Bool               -- acl:agentClass foaf:Agent
  authenticated : Bool        -- acl:agentClass acl:AuthenticatedAgent
  modes : List Mode           -- acl:mode
  accessTo : List Node        -- acl:accessTo
  accessToClass : List Node   -- acl:accessToClass

/-- What the ACL queries read from the admin dataset. Graphs outside the admin base are already dropped
(the queries' `FILTER(strstarts(str(?g), str($base)))`): `auths` and `member` hold only what survives it. -/
structure Admin where
  auths : List Auth
  /-- `?Group foaf:member ?agent` in a graph under the admin base. -/
  member : Node → Node → Prop
  /-- `$Type (rdfs:subClassOf)* ?Class` over the admin union graph. Reflexive, as `*` is. -/
  subClassOf : Node → Node → Prop

/-- Deployment constants: the root document, URI parent resolution (`IRIx.resolve("..")`, used by both the
filter and `put()`), and the admin documents the admin query lets `foaf:Agent` read (its last `FILTER`). -/
structure Ctx where
  root : Node
  parent : Node → Node
  adminPublic : Node → Prop

/-! ## Reading the store -/

/-- How the decision learns a document's types. -/
abbrev TypeView := Store → Node → Node → Prop

/-- `documentTypeQuery` as deployed: the types the document's own graph asserts for it, and, for a subject
some graph types `nfo:FileDataObject`, every type *that* graph asserts for it (`GRAPH ?g`, any graph). -/
def types : TypeView := fun st x t =>
  (∃ g, st x = some g ∧ g ⟨x, .rdfType, t⟩) ∨
  (∃ y g, st y = some g ∧ g ⟨x, .rdfType, .nfoFileDataObject⟩ ∧ g ⟨x, .rdfType, t⟩)

/-- The first branch of `documentTypeQuery` alone: only a document's own graph types it. -/
def ownTypes : TypeView := fun st x t =>
  ∃ g, st x = some g ∧ g ⟨x, .rdfType, t⟩

/-- `documentOwnerQuery`: `GRAPH $this { $this acl:owner ?owner }`. The filter compares the agent against
the first solution only; with the single owner `put()` assigns, that is the same as any solution. -/
def owner (st : Store) (x a : Node) : Prop :=
  ∃ g, st x = some g ∧ g ⟨x, .aclOwner, a⟩

/-! ## The decision -/

/-- `createOwnerAuthorization`: the owner of `x` gets acl:Read, acl:Append and acl:Write on it. -/
def ownerGrant (st : Store) (agent : Option Node) (m : Mode) (x : Node) : Prop :=
  ∃ a, agent = some a ∧ owner st x a ∧ m ≠ .control

/-- `AuthorizationParams`: the agent branch and the `acl:AuthenticatedAgent` branch are enabled only for an
authenticated agent; `foaf:Agent` matches everyone. -/
def Auth.principal (adm : Admin) (au : Auth) : Option Node → Prop
  | none => au.anyone = true
  | some a => a ∈ au.agents ∨ (∃ g ∈ au.groups, adm.member g a) ∨ au.anyone = true ∨ au.authenticated = true

/-- The target part of both ACL queries: `acl:accessTo $this`, or `acl:accessToClass` of one of the
injected types or a superclass of one. -/
def Auth.targets (adm : Admin) (au : Auth) (x : Node) (ty : Node → Prop) : Prop :=
  x ∈ au.accessTo ∨ ∃ c ∈ au.accessToClass, ∃ t, ty t ∧ adm.subClassOf t c

/-- What an ACL query contributes: some matched authorization carries a mode covering the required one
(`getAuthorizationByMode` over the `DESCRIBE`d authorizations). -/
abbrev AclGrant := Option Node → Mode → Node → (Node → Prop) → Prop

/-- `aclQuery`, run for end-user dataspaces. -/
def aclGrant (adm : Admin) : AclGrant := fun agent m x ty =>
  ∃ au ∈ adm.auths, au.principal adm agent ∧ au.targets adm x ty ∧ ∃ g ∈ au.modes, g.covers m

/-- `ownerAclQuery`, run for admin dataspaces. Its three branches:
  * any authorization carrying `acl:Control` for the agent or one of its groups, *with no target pattern*;
  * `acl:AuthenticatedAgent` authorizations targeting the document, with no further restriction;
  * `foaf:Agent` authorizations with `acl:Read` targeting the document, only for `Ctx.adminPublic` documents. -/
def adminMatch (ctx : Ctx) (adm : Admin) (agent : Option Node) (x : Node) (ty : Node → Prop) (au : Auth) : Prop :=
  (Mode.control ∈ au.modes ∧ ∃ a, agent = some a ∧ (a ∈ au.agents ∨ ∃ g ∈ au.groups, adm.member g a)) ∨
  (au.authenticated = true ∧ agent ≠ none ∧ au.targets adm x ty) ∨
  (au.anyone = true ∧ Mode.read ∈ au.modes ∧ au.targets adm x ty ∧ ctx.adminPublic x)

def adminGrant (ctx : Ctx) (adm : Admin) : AclGrant := fun agent m x ty =>
  ∃ au ∈ adm.auths, adminMatch ctx adm agent x ty au ∧ ∃ g ∈ au.modes, g.covers m

/-- `AuthorizationFilter.authorize` for a required mode. A document the type query finds untyped is taken
not to exist; a `PUT` to it is then authorized against the parent, which must be typed `def:Root` or
`dh:Container`. The owner check on `x` itself runs first, on either path. -/
def allow (T : TypeView) (ctx : Ctx) (acl : AclGrant) (st : Store) (agent : Option Node)
    (isPut : Prop) (m : Mode) (x : Node) : Prop :=
  (((∃ t, T st x t) ∨ ¬ isPut) ∧
    (ownerGrant st agent m x ∨ acl agent m x (T st x))) ∨
  ((¬ ∃ t, T st x t) ∧ isPut ∧
    (T st (ctx.parent x) .defRoot ∨ T st (ctx.parent x) .dhContainer) ∧
    (ownerGrant st agent m x ∨ ownerGrant st agent m (ctx.parent x) ∨
      acl agent m (ctx.parent x) (T st (ctx.parent x))))

inductive Method where
  | get | head | post | put | putCreate | patch | delete
  deriving DecidableEq, Repr

/-- `AuthorizationFilter.filter`: the mode a method requires (`getAccessMode`; a `PUT` with
`If-None-Match: *` needs only acl:Append), the read-allowed dataspace shortcut, and the `HEAD` fallback to
acl:Append for an agent that may write but not read. -/
def allowRequest (T : TypeView) (ctx : Ctx) (acl : AclGrant) (readAllowed : Bool) (st : Store)
    (agent : Option Node) : Method → Node → Prop
  | .get, x => readAllowed = true ∨ allow T ctx acl st agent False .read x
  | .head, x => readAllowed = true ∨ allow T ctx acl st agent False .read x ∨ allow T ctx acl st agent False .append x
  | .post, x => allow T ctx acl st agent False .append x
  | .put, x => allow T ctx acl st agent True .write x
  | .putCreate, x => allow T ctx acl st agent True .append x
  | .patch, x => allow T ctx acl st agent False .write x
  | .delete, x => allow T ctx acl st agent False .write x

end LdhAcl
