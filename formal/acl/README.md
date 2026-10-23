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
| `LdhAcl/Current.lean` | Where the deployed definitions differ from the ones the proofs need |
| `LdhAcl/Wac/Model.lean` | The redesign: the decision as plain WAC, with `acl:default` and `lacl:OwnerAgent` |
| `LdhAcl/Wac/Step.lean` | The writes under the containment write rule, and the invariants they keep |
| `LdhAcl/Wac/Theorems.lean` | What the redesigned decision guarantees |
| `LdhAcl/Wac/Migration.lean` | The seeded authorizations, and what migrating the deployed ones changes |

## Mapping to the code

| Lean | Code |
|------|------|
| `Mode.covers` | `AccessModes.covering` (`server/security/AccessModes.java:77`), over `acl.rdf:21` |
| `types` | `documentTypeQuery` (`WEB-INF/web.xml:15`) |
| `owner` | `documentOwnerQuery` (`web.xml:37`), `AuthorizationFilter.isOwner` (`:285`) |
| `ownerGrant` | `AuthorizationFilter.createOwnerAuthorization` (`:379`) |
| `Auth.principal` | `AuthorizationParams.get` (`server/util/AuthorizationParams.java:58`) |
| `aclGrant` | `aclQuery` (`web.xml:49`), `getAuthorizationByMode` (`AuthorizationFilter.java:270`) |
| `adminMatch`, `adminGrant` | `ownerAclQuery` (`web.xml:96`) |
| `allow` | `AuthorizationFilter.authorize` (`:160`), including the `PUT` fallback to the parent (`:202`) |
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

Proven, using only the axioms `propext` and `Quot.sound`:

| Theorem | Statement | Holds for |
|---------|-----------|-----------|
| `Step.frame` | Every write touches only the request's graph | deployed code |
| `owner_confined` | After a write, a document's owner either owned it before, or created it in that write | deployed code, any type view |
| `allow_local`, `step_preserves_other_decisions` | A write to `x` changes no decision about any other typed document | `ownTypes` |
| `create_needs_parent` | A `PUT` that creates `x` needs an existing `def:Root`/`dh:Container` parent and a grant on it | `ownTypes` |
| `contained_preserved` | Every non-root document's own graph points its containment at its URI parent, after any write | deployed code |
| `hier_preserved` | Every non-root document's parent exists, after any write | `ownTypes` |
| `covers_control`, `write_covers_append` | Mode coverage | deployed code |

The deployed type view is `types`. `Current.lean` states what about it keeps the theorems above from
covering the deployed code, along with the admin query's properties:

| Theorem | Statement |
|---------|-----------|
| `types_reads_other_graphs`, `types_not_local` | The `nfo:FileDataObject` branch of `documentTypeQuery` reads every graph, so a write to one graph changes another node's types |
| `types_without_graph` | That branch can type a node that has no graph, so the filter's "exists" (typed) and the store's (graph present) differ |
| `put_typed_skips_parent` | A `PUT` to a typed node is decided on the node and never consults the parent |
| `adminMatch_control_untargeted` | In `ownerAclQuery`, an authorization carrying `acl:Control` matches every admin document regardless of its targets |
| `adminMatch_anonymous_public`, `adminMatch_authenticated_unlimited` | Anonymous access to admin documents is limited to the public set; `acl:AuthenticatedAgent` access is not |

`aclGrant_targeted` gives the contrast: on end-user dataspaces, every grant is for a target.

## The redesign (`LdhAcl.Wac`)

`LdhAcl.Wac` is a specification of the decision the ACL redesign is to implement, written before the code
so that its properties are settled first. It shares the store, the modes and the own-graph lookups
(`ownTypes`, `owner`) with the model of the deployed code, and nothing else.

### The model

- **Modes:** acl:Read, acl:Append and acl:Write, with Append covered by Write. `acl:Control` may appear
  in data and means nothing.
- **Targets:**
  - `acl:accessTo` names documents and endpoints.
  - `acl:default C` covers every descendant of `C`, with union semantics, so no grant overrides another.
  - `acl:accessToClass` covers documents of a class or a subclass of it.
- **Agents:** `acl:agent`, `acl:agentGroup`, and the agent classes `foaf:Agent`, `acl:AuthenticatedAgent`
  and `lacl:OwnerAgent`, the `acl:owner` of the document being accessed.
- **One decision for both dataspaces:** there is no `ownerAclQuery` and no synthesized owner
  authorization. Owner access is the seeded authorization `ownerAccess`.
- **The lookup (`context`):** one query on the dataspace's store returns `(?Rel ?Target)` rows: the
  document itself, its ancestors, its own-graph types and its own-graph owner. Every row binds both columns.
- **Where each triple is read from:**
  - types, ancestry and the owner come from the document's own graph;
  - authorizations and memberships come from the admin document they are the primary topic of.
- **The write rule:** a graph written for `x` may state `sioc:has_parent` or `sioc:has_container` of `x`
  only. Under it, a containment path over `urn:x-arq:UnionGraph` finds exactly the own-graph ancestry.

### Results

Proven with no `sorry`, using only the axioms `propext`, `Quot.sound` and, through case splits on presence,
`Classical.choice`:

| Theorem | Statement |
|---------|-----------|
| `control_inert` | `acl:Control` covers no mode a request requires |
| `grantWith_mono` | More authorizations or memberships never take access away |
| `covers_context` | Matching the lookup's rows is WAC: named, below a default container, or of a granted class |
| `untagged_fails_open` | An untagged `VALUES (?Type ?Ancestor)` table would match a default grant on a document not below its container |
| `Step.inv` | The containment rule, exact containment, the hierarchy and the roots hold after every write |
| `parentU_iff`, `ancestor_iff` | Under the rule, union-graph ancestry is own-graph ancestry: the URI-parent chain of a present document |
| `ancestor_stable` | A write never changes the ancestors of a document present before and after it |
| `context_local` | The lookup for `x` reads only `x`'s own graph |
| `endUser_step_preserves_acl`, `endUser_step_preserves_other_grants` | A write to an end-user document changes no authorization, no membership and no decision about any other document |
| `admin_write_grants_anything` | acl:Write on an admin document can put any authorization in force: the admin role is whoever may write the admin dataspace |
| `endUserOnly_confined`, `admin_allow_needs_admin_scope` | An authorization scoped to the end-user dataspace covers no admin document; every allowed request on an admin node comes from one that is not |
| `owner_confined` | `lacl:OwnerAgent` membership is fixed for the life of a document |
| `admin_role_covers` | `accessTo` and `acl:default` on the admin root cover every admin document |
| `migrate_endUser` | On the end-user dataspace, a class grant on the hierarchy classes and a default grant on the root cover the same documents |
| `migrate_admin` | On the admin dataspace, the class grant covers every document and the default grant on the end-user root none |
| `ownerAccess_endUser` | Owner access matches an end-user document exactly when the agent owns it, as the deployed owner grant does |
| `ownerAccess_admin` | Owner access opens nothing in the admin dataspace, where the deployed owner grant applies too |

### What the proofs need of the data

These are hypotheses of the theorems, which the implementation has to enforce:

- **`AdminTyped`:** admin documents carry hierarchy classes only. Together with `EndUserOnly`, it
  requires the store to refuse `acl:accessToClass` of any class a hierarchy class is a subclass of, which
  includes the hierarchy classes themselves and any superclass the ontology declares for them.
- **`Typed`:** every document is typed with a hierarchy class. It is needed only for `migrate_endUser`.
- **`Site.Finite`:** every parent chain ends at a root, as URI paths do.
- **`Reader.Expressive`:** an authorization can be described in an admin document's graph. It is needed
  only to show that write access to the admin dataspace is the admin role.

### Not modelled

- **`rdfs:subClassOf*`:** fixed. Class axioms are admin data, and a write to them is an admin write.
- **The read-allowed dataspace shortcut:** not modelled.
- **Authentication and concurrency:** as for the deployed model.
