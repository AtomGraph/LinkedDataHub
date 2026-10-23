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
| `LdhAcl/Base.lean` | The store (one named graph per document), modes, own-graph lookups and requests |
| `LdhAcl/Model.lean` | The two dataspaces, ancestry, the admin dataset, the document context and the decision |
| `LdhAcl/Step.lean` | Graph store writes as a step relation, and the invariants they keep |
| `LdhAcl/Theorems.lean` | What the decision guarantees |
| `LdhAcl/Migration.lean` | The seeded authorizations, and what migrating those of a release before 6.0 changes |

## The model

- **Modes:** acl:Read, acl:Append and acl:Write, with Append covered by Write. `acl:Control` may appear in data
  and means nothing.
- **Targets:**
  - `acl:accessTo` names documents and endpoints.
  - `acl:default C` covers every descendant of `C`, with union semantics, so no grant overrides another.
  - `acl:accessToClass` covers documents of a class or a subclass of it.
- **Agents:** `acl:agent`, `acl:agentGroup`, and the agent classes `foaf:Agent`, `acl:AuthenticatedAgent` and
  `lacl:OwnerAgent`, the `acl:owner` of the document being accessed.
- **One decision for both dataspaces.** Owner access is the seeded authorization `ownerAccess`; the admin role is
  `accessTo` and `acl:default` on the admin root.
- **The lookup (`context`):** one query on the dataspace's store returns `(?Rel ?Target)` rows: the document
  itself, its ancestors, its own-graph types and its own-graph owner. Every row binds both columns.
- **Where each triple is read from:**
  - types, ancestry and the owner come from the document's own graph;
  - authorizations and memberships come from the admin document they are the primary topic of.
- **The write rule:** a graph written for `x` may state `sioc:has_parent` or `sioc:has_container` of `x` only.
  Under it, a containment path over `urn:x-arq:UnionGraph` finds exactly the own-graph ancestry.

## Mapping to the code

| Lean | Code |
|------|------|
| `Mode.covers` | `AccessModes.covering` (`server/security/AccessModes.java`), over `acl.rdf` |
| `context`, `ownTypes`, `owner`, `ancestor` | `documentContextQuery` (`WEB-INF/web.xml`), `DocumentContext` (`server/util/`) |
| `Auth.principal` | `aclQuery`'s agent branches, `AuthorizationParams.get` (`server/util/`) |
| `Auth.matchRow`, `Auth.covers` | `aclQuery`'s target branches over the injected `VALUES (?Rel ?Target)` |
| `Reader`, `authIn`, `memberIn` | `aclQuery`'s `?g foaf:primaryTopic ?auth` and `?groupG foaf:primaryTopic ?Group` |
| `grant`, `allow` | `AuthorizationFilter.authorize`, including the `PUT` fallback to the parent |
| `allowRequest` | `AuthorizationFilter.filter`, `getAccessMode` |
| `Step.post`, `Step.putExisting`, `Step.putNew`, `Step.patch`, `Step.delete` | `DocumentHierarchyGraphStoreImpl.post`, `put`, `patch`, `delete` |
| `NoForeign` | `getForeignContainment`, `checkForeignContainment` |
| `ownership`, `containment` | `removeOwnership`, `isOwnershipChanged`, `removeContainment`, `isContainmentChanged` |
| `hasChild` | `childQuery` (`web.xml`), `hasChild` |
| `EndUserOnly` (class part) | the `adm:HierarchyClassAccess` constraint on `acl:Authorization` (`app/admin/adm.ttl`) |
| `ownerAccess` | `acl/authorizations/owner-access/` (`platform/namespace-ontology.trig.template`) |
| `Auth.withTargets` rewrites | `migrations/6.0-acl.ru.template` |

`AuthorizationFilter` lives in `server/filter/request/` and `DocumentHierarchyGraphStoreImpl` in
`server/model/impl/`, both under `src/main/java/com/atomgraph/linkeddatahub/`.

## Results

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
| `ownerAccess_endUser` | Owner access matches an end-user document exactly when the agent owns it, as the owner grant before 6.0 did |
| `ownerAccess_admin` | Owner access opens nothing in the admin dataspace, where the owner grant before 6.0 applied too |

## What the proofs need of the data

These are hypotheses of the theorems, which the implementation has to enforce:

- **`AdminTyped`:** admin documents carry hierarchy classes only. Together with `EndUserOnly`, it
  requires the store to refuse `acl:accessToClass` of any class a hierarchy class is a subclass of, which
  includes the hierarchy classes themselves and any superclass the ontology declares for them.
- **`Typed`:** every document is typed with a hierarchy class. It is needed only for `migrate_endUser`.
- **`Site.Finite`:** every parent chain ends at a root, as URI paths do.
- **`Reader.Expressive`:** an authorization can be described in an admin document's graph. It is needed
  only to show that write access to the admin dataspace is the admin role.

## Not modelled

- **`rdfs:subClassOf*`:** fixed. Class axioms are admin data, and a write to them is an admin write.
- **The read-allowed dataspace shortcut:** a dataspace marked readable skips the decision for `GET` and `HEAD`.
- **Authentication:** WebID, OAuth and `On-Behalf-Of` delegation. The agent is an input.
- **Concurrency:** steps are sequential. Under the locks, a `PUT` holds its parent's lock as well as its own and
  re-checks that the parent exists, and a `DELETE` checks for children; the model does not prove that
  serialisation.
- **Other server work:** validation, skolemization, dates, imports, uploads, content negotiation and caching.
