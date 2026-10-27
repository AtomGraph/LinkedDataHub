# LinkedDataHub graph store model in Lean

A Lean 4 model of LinkedDataHub's graph store: the documents it keeps, the writes it makes of a request, and its
answer to every request, with proofs of the invariants those writes keep. Who is asking is no part of it: the
authorization decision comes before all of it, and is the ACL model's ([`../acl/`](../acl/)), which builds on this
one.

The model is a specification. It is not extracted from the Java: each definition is transcribed from the code
listed in the mapping below, and when that code changes, the definition changes in the same commit.

## Building

```bash
cd formal/http
lake build
```

Lean `v4.15.0` (pinned in `lean-toolchain`), core library only, with no Mathlib.

The `Formal` workflow builds the model on every push, fails on a `sorry`, and on a pull request runs
`tracks-code.sh`, which fails when a source listed under "Mapping to the code" changes without a change in this
directory. `web.xml` counts only through `childQuery`. Run it locally against the branch point:

```bash
formal/http/tracks-code.sh origin/develop
```

## Files

| File | Contents |
|------|----------|
| `LdhHttp/Base.lean` | The store (one named graph per document), the document hierarchy, own-graph lookups and requests |
| `LdhHttp/Write.lean` | The graph store's writes as a relation, and the invariants they keep |
| `LdhHttp/Fin.lean` | A store as data, and the abstract store it denotes |
| `LdhHttp/Answer.lean` | The graph store's answer as a program: every status and the store after it, and the proof that what goes through is a `Write` |
| `LdhHttp/IO.lean` | Reading dumps and a request into the model's terms, and printing an answer |
| `Main.lean` | `ldh-http`: the answer over a live instance's datasets |

## The model

- **Documents:** one named graph per document, named by the document's URI. The default graph is empty and not
  modelled. A document exists when its graph does.
- **The hierarchy (`Tree`):** the URI parent `put()` resolves, and the roots, the documents with none.
- **The write rule:** a graph written for `x` may state `sioc:has_parent` or `sioc:has_container` of `x` only.
  `PUT` asserts the containment itself: `sioc:has_parent` of a container, `sioc:has_container` of anything else.
- **The type rule:** a graph written for `x` may type `x` with the hierarchy classes (`def:Root`, `dh:Container`,
  `dh:Item`) only, and leaves it typed with one: `PUT` adds `dh:Item` to a non-root document that is not a container,
  a `PUT` of the root must carry the type itself, and a `PATCH` may keep the types it finds, add hierarchy classes and
  not drop the last of them.
- **Ownership:** `acl:owner` and `dct:creator` of a document are the server's: a new document gets the agent's, an
  existing one keeps its own, and a `PATCH` cannot change them.
- **Creation:** a document is created only below a parent the store has (`409`, checked under the parent's lock).
- **The answer (`Answer.lean`):** each method's checks in the order the graph store makes them: the methods a
  document allows (`405`), the URI (`308`, `400`), the write and type rules (`422`), the preconditions (`428` without
  one on an existing document, `412` on a stale one or on `If-None-Match: *`), existence (`404`), the parent and the
  children (`409`), and the rest of `PATCH`'s guards (`422`).

## Mapping to the code

| Lean | Code |
|------|------|
| `Write.post`, `Write.putExisting`, `Write.putNew`, `Write.patch`, `Write.delete` | `DocumentHierarchyGraphStoreImpl.post`, `put`, `patch`, `delete` |
| `NoForeign` | `getForeignContainment`, `checkForeignContainment` |
| `hierClass`, `HierTypes`, `TypedBy` | `HIERARCHY_CLASSES`, `getForeignTypes`, `isHierarchyTyped`, `checkDocumentTypes`, and their checks in `put` (the root) and `patch` |
| `containedIn`, `itemTyped` | the `sioc:has_parent` or `sioc:has_container`, and the `dh:Item`, that `put` asserts |
| `ownership`, `containment` | `removeOwnership`, `isOwnershipChanged`, `removeContainment`, `isContainmentChanged` |
| `hasChild` | `childQuery` (`web.xml`), `hasChild` |
| `Write.putNew`'s parent | `put`'s `409` for a parent that does not exist |
| `readB` | `get()`, and the store client's `404` for a graph it does not have |
| `postB`, `putB`, `patchB`, `deleteB`, `deleteChecked` | `DocumentHierarchyGraphStoreImpl.post`, `put`, `patch`, `delete`, in their order of checks; `delete`'s `404` is Core's `GraphStoreBase.delete` |
| `precondFails` | `evaluatePreconditions`: `428` without `If-Match` or `If-None-Match: *`, and Core's evaluation of either |
| `HSite.fixed`, `HSite.isRoot` | `allowedMethods`: no `PUT` or `DELETE` of the owner's or the secretary's WebID document, no `DELETE` of the root |
| `untypesB` | `patch`'s `rdf:type cannot be removed` |
| `parentIri`, `doubleSlash`, `slashed` (`IO.lean`) | `IRIx.resolve("..")`; `put`'s redirect to a trailing slash and refusal of a double slash |

`DocumentHierarchyGraphStoreImpl` lives in `src/main/java/com/atomgraph/linkeddatahub/server/model/impl/`. Core's
`GraphStoreBase` is a dependency, outside what `tracks-code.sh` can watch.

## Results

Proven with no `sorry`, using only the axioms `propext`, `Quot.sound` and, through case splits on presence,
`Classical.choice`:

| Theorem | Statement |
|---------|-----------|
| `Write.inv` | The containment rule, exact containment, the hierarchy and the roots hold after every write |
| `Write.typed` | After every write, every document is still typed with a hierarchy class |
| `Write.ownTypes` | A write types a document with nothing but the classes it had and hierarchy classes |
| `Write.owner_confined` | Whoever owns a document after a write owned it before, or created it with that write |
| `respond_refused` | A refused request leaves the store as it was |
| `answer_not_forbidden` | No check of the graph store answers `403`: that status is the authorization decision's |
| `answer_write` | A request that goes through is a `Write` of it from the store before to the store after, or changes nothing |
| `answer_inv` | So the graph store keeps `Inv` and `Typed`, as every `Write` does |

The invariants are hypotheses the ACL model's theorems take; it proves them of its authorized writes through these.

## Replaying the answer

`ldh-http` runs the answer on N-Quads dumps of the stores:

```bash
lake build
.lake/build/bin/ldh-http --dataset end-user.nq --dataset admin.nq --request request.tsv --payload payload.nt
```

A request is `AGENT<TAB>METHOD<TAB>DOCUMENT<TAB>PRECONDITION`, with the precondition `none`, `current` or `stale`
(`If-Match` with the current entity tag or another) or `absent` (`If-None-Match: *`); the body of a `POST` or `PUT`
is `--payload`, and a `PATCH` is `DELETE { --delete } INSERT { --insert } WHERE {}`. The answer is the status, then
the document's graph after the request. It is what the graph store does with a request it is asked to answer; the
server's own answer puts the authorization decision first, which is `ldh-acl --request` in the ACL model, and what
`tests/http/formal/acl-conformance.sh` replays.

## Not modelled

- **Concurrency:** writes are sequential. Under the locks, a `PUT` holds its parent's lock as well as its own and
  re-checks that the parent exists, and a `DELETE` checks for children; the model does not prove that
  serialisation.
- **Other server work:** constraint validation, parsing, skolemization, dates, imports, uploads, content
  negotiation, conditional `GET` and caching. A write refused for its body, such as one with a malformed IRI or a
  missing title answered with `422`, changes nothing, and the model has no write for it. The answer takes the
  payload as ground triples free of `dct:created` and `dct:modified`, and the replay sends only such payloads, valid
  against the ontology's constraints, with a single-operation `PATCH`.
- **Entity tags:** a precondition is `current` or `stale` as the request states it, not computed from the graph.
