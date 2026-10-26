/-
The graph store's data and requests: the quad store of a dataspace, one named graph per document, the document
hierarchy over it, and the requests that change it.
-/
namespace LdhHttp

/-- RDF nodes. The vocabulary terms the graph store and the authorization decision read are constructors of their
own; every other term, literals included, is `iri n`. -/
inductive Node where
  | rdfType | aclOwner | dctCreator | siocHasParent | siocHasContainer
  | nfoFileDataObject | dhContainer | dhItem | defRoot
  | iri (n : Nat)
  deriving DecidableEq, Repr

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

/-! ## The document hierarchy -/

/-- Deployment constants: the URI parent `put()` resolves, and the documents with none, the roots. -/
structure Tree where
  parent : Node → Node
  isRoot : Node → Prop

/-- The classes of the document hierarchy, which both dataspaces type their documents with. -/
def hierClass (c : Node) : Prop := c = .defRoot ∨ c = .dhContainer ∨ c = .dhItem

def isContainment (t : Triple) : Prop := t.p = .siocHasParent ∨ t.p = .siocHasContainer

/-- `g` states that `d` is contained in `p`. -/
def contains (g : Graph) (d p : Node) : Prop :=
  g ⟨d, .siocHasParent, p⟩ ∨ g ⟨d, .siocHasContainer, p⟩

/-! ## Reading a document's own graph -/

/-- The `acl:accessToClass` rows of `documentContextQuery`: the types a document's own graph asserts for it. -/
def ownTypes (st : Store) (x t : Node) : Prop :=
  ∃ g, st x = some g ∧ g ⟨x, .rdfType, t⟩

/-- The `acl:owner` rows of `documentContextQuery`: `GRAPH $this { $this acl:owner ?Target }`. -/
def owner (st : Store) (x a : Node) : Prop :=
  ∃ g, st x = some g ∧ g ⟨x, .aclOwner, a⟩

/-! ## Requests -/

inductive Method where
  | get | head | post | put | putCreate | patch | delete
  deriving DecidableEq, Repr

/-- `acl:owner` or `dct:creator` of the document resource: what `removeOwnership` strips from a payload
and `isOwnershipChanged` guards in a `PATCH`. -/
def ownership (x : Node) (t : Triple) : Prop :=
  t.s = x ∧ (t.p = .aclOwner ∨ t.p = .dctCreator)

/-- `sioc:has_parent` or `sioc:has_container` of the document resource: `put()` strips them from the
payload and asserts one of them itself. -/
def containment (x : Node) (t : Triple) : Prop :=
  t.s = x ∧ (t.p = .siocHasParent ∨ t.p = .siocHasContainer)

inductive Req where
  /-- `POST`: append a payload to an existing document. -/
  | post (x : Node) (payload : Graph)
  /-- `PUT`, plain or with `If-None-Match: *`: create or replace a document. -/
  | put (x : Node) (payload : Graph) (createOnly : Bool)
  /-- `PATCH`: the graph after the SPARQL update, which must not be empty (that case is a delete). -/
  | patch (x : Node) (after : Graph)
  /-- `DELETE`, and a `PATCH` that empties the graph, which `patch()` hands to `delete()`. -/
  | delete (x : Node)

def Req.target : Req → Node
  | .post x _ | .put x _ _ | .patch x _ | .delete x => x

def Req.method : Req → Method
  | .post .. => .post
  | .put _ _ false => .put
  | .put _ _ true => .putCreate
  | .patch .. => .patch
  | .delete .. => .delete

/-- `childQuery` (`web.xml`): a document whose own graph points its containment at `x`. Containment
asserted in any other graph does not count. -/
def hasChild (st : Store) (x : Node) : Prop :=
  ∃ k g, k ≠ x ∧ st k = some g ∧ (g ⟨k, .siocHasParent, x⟩ ∨ g ⟨k, .siocHasContainer, x⟩)

end LdhHttp
