# Formal models of LinkedDataHub

Machine-checked specifications of the parts of the platform whose failure is a security incident. Each
model lives in its own directory with its own toolchain, README and mapping to the code it describes.

| Directory | Tool | Covers |
|-----------|------|--------|
| [`http/`](http/) | Lean 4 | The graph store: its documents, its writes and the invariants they keep, and its answer to every request |
| [`acl/`](acl/) | Lean 4 | The authorization decision over the graph store's data, the server's answer with the decision in front of the graph store, and the 6.0 migration of seeded authorizations |
| [`auth/`](auth/) | Lean 4 | How the agent is established: the WebID filter, its cache and `On-Behalf-Of` delegation, the ID token filters and the first OAuth login, in front of the ACL model's answer |
| [`client/`](client/) | Lean 4 | Where the browser client sends its requests and the window: `ldh:href`, the pane's base, and every request site not built by `ldh:href` |
| [`uploads/`](uploads/) | Lean 4 | The upload folder under the graph store's writes, what an upload is described and authorized by, and how it is served: ranges, preconditions and the sandbox |

The graph store model stands alone; the ACL model requires it, by path, since the decision reads the graph store's
data and its theorems about writes are about the graph store's writes. The authentication model requires the ACL
model, since the agent it establishes is the decision's input. The client model stands alone. The uploads model
requires the graph store model, whose writes commit an upload's files and whose graphs describe it.

The `Formal` workflow (`.github/workflows/formal.yml`) builds every model on each push, fails on an
unproven theorem, and on a pull request fails when a transcribed source changes without the model
(`http/tracks-code.sh`, `acl/tracks-code.sh`, `auth/tracks-code.sh`, `client/tracks-code.sh`,
`uploads/tracks-code.sh`). The HTTP test suite
replays the models' answers against the server: the status and the document's graph after each request
(`tests/http/formal/`). The client model is replayed against the stylesheets themselves: `ldh:href` under Saxon-HE on
the model's cases, and the request sites as `client/sites.py` reads them. The uploads model's serving is replayed through the
stack (`tests/http/formal/uploads-conformance.sh`), and its range selection against `ByteRange.parse`
(`ByteRangeModelTest`).

## Why

Automated attackers make instance bugs cheap to find: the 2025 pen test's findings (SSRF, XXE, stored
XSS) are the kind of thing an agentic scanner now turns up at near-zero cost and chains together.
Patching instances does not keep pace with that. What does is proving a class of bug absent, or
shrinking the surface until the class cannot occur, and stating in public which classes are covered and
under which assumptions.

LinkedDataHub is also an agent target in its own right: the assistant drawer, Web-Algebra and the `ldh`
Claude Code plugin all act under delegated WebIDs. The threats that matter most there are confused
deputies and prompt injection escalating past the delegating agent's rights, and both are statements
about the authorization decision, which is the part already modelled.

## Roadmap

Each step is independent of the ones after it. The first three are the cheapest and buy most of the
credibility; the fifth is the one that answers the agent-era question and changes the product.

1. **The model is a build artifact.** Done in this directory's `Formal` workflow: `lake build`, a
   `sorry` check and the drift check. The README mapping stops being a promise kept by hand.

2. **The decision is executable, and the server is tested against it.** Done: `acl/LdhAcl/Decide.lean`
   gives `allowRequest` a `Bool` twin over finite data with a proof that the two agree, `acl/Main.lean`
   runs it on N-Quads dumps of a live instance's stores, and `tests/http/formal/acl-conformance.sh`
   builds a seeded random scenario through the API and checks the server's status against the verdict
   before every request. Verifying the Java directly is not worth the cost; this is how the proofs
   constrain the code.

3. **Every hypothesis of a theorem is an enforced constraint.** Done: of the premises in `acl/README.md`,
   "What the proofs need of the data", the two a request can falsify, `AdminTyped` and `Typed`, are kept by
   a type rule on every write (`checkDocumentTypes`), proven preserved by `Step.adminTyped` and `Step.typed`,
   and tried by negative HTTP tests. `Site.Finite` and `Reader.Expressive` are facts about URIs and the
   query, with nothing to falsify.

4. **The graph store's answer is modelled, and the server is replayed against it.** Done: the graph store
   is a model of its own, `http/`, which the ACL model now requires. `http/LdhHttp/Answer.lean` gives every
   status a graph store request can get and the store after it, as a program, and proves that a refused
   request changes nothing and that a request that goes through is a `Write`, so the graph store keeps
   every invariant a `Write` does. `acl/LdhAcl/Gate.lean` puts the decision in front of it and proves that
   `403` is the decision's alone (a denied agent learns nothing else, not even whether the document
   exists) and that what goes through is an authorized `Write`. The replay checks the server's status and
   the document's graph after each request against it. `ETag.lean` proves that a write guarded by
   `If-Match` loses no update, on the assumption that the tag's digest is collision-free. `Memento.lean`
   models the TimeGate (the closest commit, the more recent of two as close), the TimeMap and the commit
   queue, and the TimeGate is replayed against the Java on generated histories and against the server on a
   versioned dataspace.

5. **Delegation as non-interference.** Done: `auth/` models `On-Behalf-Of` and `acl:delegates`, and proves
   that a request on behalf of a caller is authenticated as the caller (`authenticate_obo`) and that two
   requests authenticated as the same agent get the same answer to every request
   (`delegation_noninterference`). So for any plan an LLM emits, the requests the secretary can execute on
   behalf of a caller are exactly those the caller could execute alone, independently of prompt content.
   That reduces prompt injection to misuse within existing rights. The model also proves that the
   secretary can act for every agent (`obo_complete`), which is what motivates scoping `acl:delegates`.
   Scoped delegation is the one design change this roadmap expects to force.

6. **Concurrency in its own model.** The lock protocol (a `PUT` holds its parent's lock and re-checks
   the parent exists, a `DELETE` checks for children) is a TLA+ problem: a small model and TLC, in a
   sibling directory. Lean is the wrong tool for it.

7. **Chokepoints checked by structure.** The input-handling class is closed by `SecureXML` and
   `URLValidator` being the only paths to a parser or an outbound connection. Architecture tests that
   forbid raw XML parser factories, URL opening and SPARQL string concatenation outside those classes
   turn that from a convention into a build failure. The client's request sites are checked this way already:
   `client/sites.py` fails the workflow on a request target not built by `ldh:href` that the model has not
   classified.

8. **The claims are published.** A threat model page in the wiki, a `SECURITY.md` stating what is
   proven and under which hypotheses, and the model handed to the next penetration retest as its oracle.

## Not in scope

Content negotiation, caching, imports and XSLT. Each is a candidate for its own model once the ones above hold.
