# LinkedDataHub ACL model in Lean

A Lean 4 model of LinkedDataHub's authorization decision and of the graph store writes that change what
the decision reads, with proofs of the properties the access-control model is meant to have.

The model is a specification. It is not extracted from the Java, and nothing here checks the Java
against it: each definition is transcribed from the code listed in the mapping below. When that code
changes, the definition changes in the same commit.

## Building

```bash
cd formal/acl
lake build
```

Lean `v4.15.0` (pinned in `lean-toolchain`), core library only, with no Mathlib.

## Files

| File | Contents |
|------|----------|
| `LdhAcl/Model.lean` | State (store, admin dataset), the four ACL queries, the decision |
| `LdhAcl/Step.lean` | Graph store writes as a step relation |
| `LdhAcl/Theorems.lean` | Mode facts, ownership confinement, authority locality, creation |
| `LdhAcl/Hierarchy.lean` | The hierarchy invariant |
| `LdhAcl/Admin.lean` | The admin decision |

## Mapping to the code

| Lean | Code |
|------|------|
| `Mode.covers` | `AccessModes.covering` (`server/security/AccessModes.java:77`), over `acl.rdf:21` |
| `types` | `documentTypeQuery` (`WEB-INF/web.xml:15`) |
| `owner` | `documentOwnerQuery` (`web.xml:37`), `AuthorizationFilter.isOwner` (`:285`) |
| `ownerGrant` | `AuthorizationFilter.createOwnerAuthorization` (`:379`) |
| `Auth.principal` | `AuthorizationParams.get` (`server/util/AuthorizationParams.java:58`) |
| `aclGrant` | `aclQuery` (`web.xml:49`), `getAuthorizationByMode` (`AuthorizationFilter.java:270`) |
| `adminMatch`, `adminGrant` | `ownerAclQuery` (`web.xml`) |
| `allow` | `AuthorizationFilter.authorize`, including the `PUT` fallback to the parent when `containsModel` is false |
| `allowRequest` | `AuthorizationFilter.filter` (`:105`), `getAccessMode` (`:254`) |
| `Step.post` | `DocumentHierarchyGraphStoreImpl.post` |
| `Step.putExisting`, `Step.putNew` | `put` |
| `Step.patch` | `patch`, `isOwnershipChanged`, `isContainmentChanged` |
| `Step.delete` | `delete` |
| `hasChild` | `childQuery` (`web.xml`), `hasChild` |
| `ownership` | `removeOwnership`, `isOwnershipChanged` |
| `containment` | `removeContainment`, `isContainmentChanged` |

`AuthorizationFilter` lives in `server/filter/request/` and `DocumentHierarchyGraphStoreImpl` in
`server/model/impl/`, both under `src/main/java/com/atomgraph/linkeddatahub/`.

## What is modelled

- **State:**
  - The end-user store is one named graph per document; the default graph is empty.
  - The admin dataset holds authorizations, group memberships and the `rdfs:subClassOf*` closure, after
    the queries' admin-base `FILTER`.
- **Decision:**
  - The decision is modelled as a predicate.
  - A `PUT` to a document the type query finds untyped is authorized against its URI parent.
  - The parent must be `def:Root` or `dh:Container`.
  - Owners get acl:Read, acl:Append and acl:Write.
  - `HEAD` falls back to acl:Append.
- **Writes:** each write is modelled only in the triples the decision reads: the document's ownership
  (`acl:owner`, `dct:creator`) and containment (`sioc:has_parent`, `sioc:has_container`). Everything else
  in the written graph is left to the payload.

## What is not modelled

- **Authentication:** WebID, OAuth and `On-Behalf-Of` delegation. The agent is an input.
- **Concurrency:** steps are sequential. The filter runs outside any lock. Under the locks, a `PUT` holds
  its parent's lock as well as its own and re-checks that the parent exists, and a `DELETE` checks for
  children. That serialisation is what the sequential steps assume; the model does not prove it.
- **Writes to the admin dataset:** the admin dataset is a fixed input to end-user steps.
- **Other server work:** validation, skolemization, dates, imports, uploads, content negotiation and
  caching. None of them reads or writes ownership, containment or authorizations.
- **Owner query:** the filter compares the agent with the first `acl:owner` solution; the model takes any
  solution. They agree while `put()` assigns a single owner.

## Results

Proven for the deployed code, using only the axioms `propext` and `Quot.sound`:

| Theorem | Statement |
|---------|-----------|
| `Step.frame` | Every write touches only the request's graph |
| `owner_confined` | After a write, a document's owner either owned it before, or created it in that write |
| `types_present`, `types_absent` | A document's types are its own graph's; a node without a graph is typed `nfo:FileDataObject` at most |
| `allow_local`, `step_preserves_other_decisions` | A write to `x` changes no decision about any other existing document |
| `create_needs_parent` | A `PUT` that creates `x` needs an existing `def:Root`/`dh:Container` parent and a grant on it |
| `contained_preserved` | Every non-root document's own graph points its containment at its URI parent, after any write |
| `hier_preserved` | Every non-root document's parent exists, after any write |
| `covers_control`, `write_covers_append` | Mode coverage |

The admin decision, also for the deployed code:

| Theorem | Statement |
|---------|-----------|
| `adminMatch_role` | Outside the documents the admin application makes public, only `acl:Control` over `def:Root` opens an admin document |
| `adminMatch_anonymous_public`, `adminMatch_authenticated_public` | Through agent classes, anonymous and signed-in agents alike reach only the public admin documents |
| `adminMatch_owners` | A group holding `acl:Control` over `def:Root` keeps every admin document |

`aclGrant_targeted` gives the contrast: on end-user dataspaces, every grant is for a target.
