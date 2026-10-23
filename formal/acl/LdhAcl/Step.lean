/-
The writes of `DocumentHierarchyGraphStoreImpl`, as far as the authorization decision can see them.

Each write touches one graph, the request URI's (`checkDirectIdentification`, and `PATCH` refuses `GRAPH`,
`WITH` and `USING`). What a step does to that graph is modelled only in the triples the decision reads:
the document's ownership and containment. Everything else in the graph is whatever the payload says.
Validation, skolemization, dates and imports are left out; none of them reads or writes ownership,
containment or authorizations.
-/
import LdhAcl.Model

namespace LdhAcl

/-- `acl:owner` or `dct:creator` of the document resource: what `removeOwnership` strips from a payload
and `isOwnershipChanged` guards in a `PATCH`. -/
def ownership (x : Node) (t : Triple) : Prop :=
  t.s = x ∧ (t.p = .aclOwner ∨ t.p = .dctCreator)

/-- `sioc:has_parent` or `sioc:has_container` of the document resource: `put()` strips them from the
payload and asserts one of them itself. -/
def containment (x : Node) (t : Triple) : Prop :=
  t.s = x ∧ (t.p = .siocHasParent ∨ t.p = .siocHasContainer)

/-- The containment `put()` asserts for a non-root document: `sioc:has_parent` for a container,
`sioc:has_container` for an item, always pointing at the URI parent. -/
def containedIn (ctx : Ctx) (x : Node) (t : Triple) : Prop :=
  x ≠ ctx.root ∧ t.s = x ∧ (t.p = .siocHasParent ∨ t.p = .siocHasContainer) ∧ t.o = ctx.parent x

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

/-- One authorized request on the end-user store, by `agent`, from `st` to `st'`.

The first premise of every case is the filter's decision. The rest is the graph store:
* `post` merges the payload minus its ownership and containment triples into the existing graph;
* `put` keeps the payload minus ownership and containment, asserts containment in the URI parent, and
  takes ownership from the stored graph, or, for a new document, from the agent;
* `patch` may change anything but the document's ownership and containment;
* `delete` drops the graph of a document with no children (`409` otherwise); the root cannot be deleted (it
  is not in `getAllowedMethods()`). -/
inductive Step (T : TypeView) (ctx : Ctx) (acl : AclGrant) (readAllowed : Bool)
    (agent : Option Node) : Store → Req → Store → Prop where
  | post {st x payload g} :
      allowRequest T ctx acl readAllowed st agent .post x →
      st x = some g →
      Step T ctx acl readAllowed agent st (.post x payload)
        (st.set x (some fun t => g t ∨ (payload t ∧ ¬ ownership x t ∧ ¬ containment x t)))
  | putExisting {st x payload createOnly g} :
      allowRequest T ctx acl readAllowed st agent (Req.put x payload createOnly).method x →
      st x = some g →
      createOnly = false →  -- `If-None-Match: *` on an existing document is `412`
      Step T ctx acl readAllowed agent st (.put x payload createOnly)
        (st.set x (some fun t =>
          (payload t ∧ ¬ ownership x t ∧ ¬ containment x t) ∨ containedIn ctx x t ∨
          (g t ∧ ownership x t)))
  | putNew {st x payload createOnly} :
      allowRequest T ctx acl readAllowed st agent (Req.put x payload createOnly).method x →
      st x = none →
      Step T ctx acl readAllowed agent st (.put x payload createOnly)
        (st.set x (some fun t =>
          (payload t ∧ ¬ ownership x t ∧ ¬ containment x t) ∨ containedIn ctx x t ∨
          (∃ a, agent = some a ∧ t.s = x ∧ (t.p = .aclOwner ∨ t.p = .dctCreator) ∧ t.o = a)))
  | patch {st x after g} :
      allowRequest T ctx acl readAllowed st agent .patch x →
      st x = some g →
      (∀ t, ownership x t ∨ containment x t → (after t ↔ g t)) →
      Step T ctx acl readAllowed agent st (.patch x after) (st.set x (some after))
  | delete {st x} :
      allowRequest T ctx acl readAllowed st agent .delete x →
      x ≠ ctx.root →
      ¬ hasChild st x →
      Step T ctx acl readAllowed agent st (.delete x) (st.set x none)

/-- Every step writes one graph: the request's. -/
theorem Step.frame {T ctx acl ra agent st req st'} (h : Step T ctx acl ra agent st req st')
    {y : Node} (hy : y ≠ req.target) : st' y = st y := by
  cases h <;> simp [Store.set, Req.target] at hy ⊢ <;> simp [hy]

/-- Every step is authorized. -/
theorem Step.authorized {T ctx acl ra agent st req st'} (h : Step T ctx acl ra agent st req st') :
    allowRequest T ctx acl ra st agent req.method req.target := by
  cases h <;> assumption

end LdhAcl
