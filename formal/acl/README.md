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

The `Formal` workflow builds the model on every push, fails on a `sorry`, and on a pull request runs
`tracks-code.sh`, which fails when a source listed under "Mapping to the code" changes without a change
in this directory. `web.xml` counts only through the three queries the mapping names; the rest of the
file is free to change. Run it locally against the branch point:

```bash
formal/acl/tracks-code.sh origin/develop
```

## Files

| File | Contents |
|------|----------|
| `LdhAcl/Base.lean` | The store (one named graph per document), modes, own-graph lookups and requests |
| `LdhAcl/Model.lean` | The two dataspaces, ancestry, the admin dataset, the document context and the decision |
| `LdhAcl/Step.lean` | Graph store writes as a step relation, and the invariants they keep |
| `LdhAcl/Theorems.lean` | What the decision guarantees |
| `LdhAcl/Migration.lean` | The seeded authorizations, and what migrating those of a release before 6.0 changes |
| `LdhAcl/Decide.lean` | The decision as a program over finite data, and the proof that it agrees with `allowRequest` |
| `Main.lean` | `ldh-acl`: that program over a live instance's datasets, for `tests/http/formal/` to replay against the server |

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
- **The type rule:** a graph written for `x` may type `x` with the hierarchy classes (`def:Root`, `dh:Container`,
  `dh:Item`) only, and leaves it typed with one: `PUT` adds `dh:Item` to a non-root document that is not a container,
  a `PUT` of the root must carry the type itself, and a `PATCH` may keep the types it finds, add hierarchy classes and
  not drop the last of them. Under it, a class grant reaches a document only through a hierarchy class.

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
| `hierClass`, `HierTypes`, `TypedBy` | `HIERARCHY_CLASSES`, `getForeignTypes`, `isHierarchyTyped`, `checkDocumentTypes`, and their checks in `put` (the root) and `patch` |
| `itemTyped` | the `dh:Item` that `put` adds to a document the payload does not type `dh:Container` |
| `ownership`, `containment` | `removeOwnership`, `isOwnershipChanged`, `removeContainment`, `isContainmentChanged` |
| `hasChild` | `childQuery` (`web.xml`), `hasChild` |
| `EndUserOnly` (class part) | the `adm:HierarchyClassAccess` constraint on `acl:Authorization` (`app/admin/adm.ttl`) |
| `ownerAccess` | `acl/authorizations/owner-access/` (`platform/namespace-ontology.trig.template`) |
| `Auth.withTargets` rewrites | `migrations/6.0-acl.ru.template` |
| `readAdmin` (`Main.lean`) | `aclQuery`'s `?g foaf:primaryTopic ?auth`, `?groupG foaf:primaryTopic ?Group . ?Group foaf:member $agent` and `rdfs:subClassOf*` branches, with its `strstarts($base)` filters |
| `parentIri` (`Main.lean`) | `IRIx.resolve("..")` in `AuthorizationFilter.authorize` |

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
| `Step.adminTyped` | After every write, admin documents are still typed with hierarchy classes only |
| `Step.typed` | After every write, every document is still typed with a hierarchy class |
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
| `Anc_iff_reachB` | Reachability over an edge list with each edge used once is the transitive closure, with fuel the number of edges |
| `allowRequest_iff` | `allowRequestB`, a `Bool` over a finite store and admin dataset, is `allowRequest` on the store and reader they denote |

## Replaying the decision against the server

`allowRequest` is a proposition; `Decide.lean` gives the same decision as a program over finite data (`FinStore`,
`FinAdmin`, `FinSite`) and proves them equal (`allowRequest_iff`), for every `Site` whose `parent` and `admin` the
program's agree with. `Main.lean` runs that program on N-Quads dumps of the two stores:

```bash
lake build
.lake/build/bin/ldh-acl --end-user end-user.nq --admin admin.nq --admin-base https://admin.localhost:4443/ --probes probes.tsv
```

Each probe line is `AGENT<TAB>METHOD<TAB>DOCUMENT` (`-` for no agent; `PUT*` is a `PUT` with `If-None-Match: *`), and
each answer `allow` or `deny`. The part outside the proof is small and transcribed from `aclQuery`: the N-Quads
reader, the interning of IRIs as nodes, the reading of authorizations (every `foaf:primaryTopic` of an admin graph
under the admin base, with its `acl:` properties from that graph), memberships (`foaf:member` of such a topic) and
`rdfs:subClassOf` from the admin dataset, and the URI parent a `PUT` of a new document is decided on.

`tests/http/formal/acl-conformance.sh` drives it: a seeded random scenario of documents, groups and authorizations
is built through the API, and before every request the stores are dumped and the server's status compared with
the verdict, 401 or 403 on `deny` and anything else on `allow`. The scenario's own writes are requests the model
decides, so the agents' rights shape what gets built. `ACL_CONFORMANCE_SEED` replays a scenario, and a mismatch
leaves its dumps and probe under the results directory.

## What the proofs need of the data

Two hypotheses of the theorems are about the stored data, which a write could falsify. The type rule enforces both,
the model proves that every write keeps them, and an HTTP test tries each write that would break them:

- **`AdminTyped`:** admin documents carry hierarchy classes only (`Step.adminTyped`). Together with
  `EndUserOnly`, it requires the store to refuse `acl:accessToClass` of any class a hierarchy class is a
  subclass of. `adm:HierarchyClassAccess` refuses the hierarchy classes and the superclasses the platform's
  vocabularies declare for them; a superclass a namespace ontology declares is admin data, written by the
  admin role (see `rdfs:subClassOf*` below). Tested by `tests/http/admin/acl/class-authorization-admin-typed.sh`.
- **`Typed`:** every document is typed with a hierarchy class (`Step.typed`). It is needed only for
  `migrate_endUser`. Tested by `tests/http/document-hierarchy/{PUT,POST,PATCH}-foreign-type-422.sh`.

Every seeded document satisfies both. The admin dataset also seeds graphs for two endpoints, `clear` and `sign up`,
typed `foaf:Document`, with no containment. They are not documents: `Dispatcher` routes them to their own resources,
so no graph store write reaches them, and `adm:HierarchyClassAccess` refuses a grant of `foaf:Document`. A store
written before the type rule may hold documents typed otherwise: a `PATCH` leaves the types it finds, and the first
`PUT` drops them.

The other two are facts about the platform rather than its data, and nothing a request sends can falsify them:

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
  A write refused for its body, such as one with a malformed IRI answered with `422`, changes nothing, and the
  model has no step for it.
