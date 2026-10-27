# Formal models of LinkedDataHub

Machine-checked specifications of the parts of the platform whose failure is a security incident. Each
model lives in its own directory with its own toolchain, README and mapping to the code it describes.

| Directory | Tool | Covers |
|-----------|------|--------|
| [`acl/`](acl/) | Lean 4 | The authorization decision, the graph store writes that change what it reads, and the 6.0 migration of seeded authorizations |

The `Formal` workflow (`.github/workflows/formal.yml`) builds every model on each push, fails on an
unproven theorem, and on a pull request fails when a transcribed source changes without the model
(`acl/tracks-code.sh`). The HTTP test suite replays the ACL model's decision against the server
(`tests/http/formal/`).

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
credibility; the fourth is the one that answers the agent-era question and changes the product.

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

4. **Delegation as non-interference.** Model `On-Behalf-Of` and `acl:delegates`, and prove that for
   any plan an LLM emits, the requests the secretary can execute on behalf of a caller are exactly those
   the caller could execute alone, independently of prompt content. That reduces prompt injection to
   misuse within existing rights, and motivates scoping `acl:delegates`, which today delegates
   everything. Scoped delegation is the one design change this roadmap expects to force.

5. **Concurrency in its own model.** The lock protocol (a `PUT` holds its parent's lock and re-checks
   the parent exists, a `DELETE` checks for children) is a TLA+ problem: a small model and TLC, in a
   sibling directory. Lean is the wrong tool for it.

6. **Chokepoints checked by structure.** The input-handling class is closed by `SecureXML` and
   `URLValidator` being the only paths to a parser or an outbound connection. Architecture tests that
   forbid raw XML parser factories, URL opening and SPARQL string concatenation outside those classes
   turn that from a convention into a build failure.

7. **The claims are published.** A threat model page in the wiki, a `SECURITY.md` stating what is
   proven and under which hypotheses, and the model handed to the next penetration retest as its oracle.

## Not in scope

Authentication (WebID, OAuth, delegation until step 4), content negotiation, caching, imports, uploads,
XSLT and the client. Each is a candidate for its own model once the ones above hold.
