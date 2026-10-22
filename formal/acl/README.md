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
| `Step.post` | `DocumentHierarchyGraphStoreImpl.post` (`:411`) |
| `Step.putExisting`, `Step.putNew` | `put` (`:505`), containment at `:553` |
| `Step.patch` | `patch` (`:644`), `isOwnershipChanged` (`:938`) |
| `Step.delete` | `delete` (`:885`) |
| `ownership` | `removeOwnership` (`:919`), `isOwnershipChanged` (`:938`) |

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
- **Concurrency:** steps are sequential. `writeLocked` takes a lock per graph URI, and the filter runs
  outside it, so the theorems describe serialised requests only.
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
| `hier_preserved` | Every non-root document's parent exists, after any write | `ownTypes` and `DeletePolicy.refuseNonEmpty` |
| `covers_control`, `write_covers_append` | Mode coverage | deployed code |

The deployed definitions are `types` and `DeletePolicy.current`. `Current.lean` states what about them
keeps the theorems above from covering the deployed code:

| Theorem | Statement |
|---------|-----------|
| `types_reads_other_graphs`, `types_not_local` | The `nfo:FileDataObject` branch of `documentTypeQuery` reads every graph, so a write to one graph changes another node's types |
| `types_without_graph` | That branch can type a node that has no graph, so the filter's "exists" (typed) and the store's (graph present) differ |
| `put_typed_skips_parent` | A `PUT` to a typed node is decided on the node and never consults the parent |
| `hier_not_preserved_current` | `delete()` can remove a container that has children |
| `adminMatch_control_untargeted` | In `ownerAclQuery`, an authorization carrying `acl:Control` matches every admin document regardless of its targets |
| `adminMatch_anonymous_public`, `adminMatch_authenticated_unlimited` | Anonymous access to admin documents is limited to the public set; `acl:AuthenticatedAgent` access is not |

`aclGrant_targeted` gives the contrast: on end-user dataspaces, every grant is for a target.
