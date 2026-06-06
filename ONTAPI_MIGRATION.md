# Jena Ontology API Migration Plan

Migrating off the deprecated `org.apache.jena.ontology` API onto the new `org.apache.jena.ontapi`.

## Scope

Three repos, in dependency order: **Core** → **Web-Client** → **LinkedDataHub**.

The 90+ deprecation warnings collapse into three patterns:

1. **Vocabulary classes** (~18 files in LDH, 2 in Core, several in Web-Client). Use `OntModel`-typed constants (`OntClass`, `ObjectProperty`, `DatatypeProperty`). Cannot be replaced with plain `Model` because consumers depend on the typed constants. Mechanical migration, wide cascade.
2. **Writer / Validator signatures** in Web-Client and LDH. Accept `OntModelSpec` / `OntModel` but don't exercise ontology features. Direct type rename.
3. **Ontology machinery** (the actual work): `OntDocumentManager` global wiring, per-request import resolution + inference materialization, direct `OntDocumentManager.getOntology()` calls.

## Type / method rename table

| Old (`org.apache.jena.ontology`) | New (`org.apache.jena.ontapi.model`) |
|---|---|
| `OntModel` | `OntModel` |
| `OntClass` | `OntClass` |
| `ObjectProperty` | `OntObjectProperty` |
| `DatatypeProperty` | `OntDataProperty` |
| `AnnotationProperty` | `OntAnnotationProperty` |
| `OntModelSpec.OWL_MEM` | `OntSpecification.OWL2_DL_MEM` (verify exact semantic match) |
| `OntModelSpec.OWL_MEM_RDFS_INF` | `OntSpecification.OWL2_DL_MEM_BUILTIN_RDFS_INF` |
| `OntModelSpec.RDFS_MEM` | `OntSpecification.RDFS_MEM` |
| `ModelFactory.createOntologyModel(spec, base)` | `OntModelFactory.createModel(base.getGraph(), spec)` |
| `model.createClass(uri)` | `model.createOntClass(uri)` |
| `model.createDatatypeProperty(uri)` | `model.createDataProperty(uri)` — **method renamed** |
| `model.createObjectProperty(uri)` | `model.createObjectProperty(uri)` |
| `model.createAnnotationProperty(uri)` | `model.createAnnotationProperty(uri)` |
| `model.getOntClass(uri)` | `model.getOntClass(uri)` |
| `OntDocumentManager.getInstance()` | `DocumentGraphRepository` (per-Application instance) |
| `OntDocumentManager.getOntology(uri, spec)` | repository lookup + `OntModelFactory.createModel(...)` |
| `model.listImportedOntologyURIs(true)` | `model.imports()` recursively (verify closure semantics) |

## Phase 0 — Spike (must come first)

Single throwaway branch. Validate the two unknowns before touching any production call sites:

1. Does `OntModel#imports()` give the same recursive-closure semantics as the old `listImportedOntologyURIs(true)`?
2. Does `DocumentGraphRepository` support the **materialize-inferences-then-cache-as-non-inferencing-model** pattern from `OntologyFilter.java:155–161`? This is the load-bearing trick — `OWL_MEM_RDFS_INF` → materialize → cache as `OWL_MEM`.

Spike target: rewrite `OntologyFilter.java` against ontapi in isolation. Compile-check only; production migration follows.

**Exit criteria:** either both patterns translate cleanly, or we know we need a compatibility shim.

## Phase 1 — Core

Smallest blast radius. Two vocabulary classes:

- `com.atomgraph.core.vocabulary.A`
- `com.atomgraph.core.vocabulary.SD`

Apply rename table. Publish snapshot. Verify LDH compiles against the snapshot (it won't fully — but the Core-originated typed constants should resolve under their new types).

## Phase 2 — Web-Client (gatekeeper)

Public API surface changes here, so this must land before LDH can finish.

**Public API:**
- `Application.getOntModelSpec()` → return `OntSpecification` (rename method to `getOntSpecification()` or keep name with new return type)
- `XSLTWriterBase`, `ModelXSLTWriter`, `ResultSetXSLTWriter` constructor signatures take `OntSpecification`

**Direct ontapi calls:**
- `ConstructForClass.java:92` — replace `getOntDocumentManager().getOntology(ontology, OntModelSpec.OWL_MEM)` with repository lookup

**Vocabulary classes:** apply rename table to all Web-Client vocabularies.

This is where the typed-constant cascade lands — every `import org.apache.jena.ontology.ObjectProperty` becomes `import org.apache.jena.ontapi.model.OntObjectProperty`, etc. Mechanical but wide.

## Phase 3 — LDH vocabularies (mechanical)

Apply rename table to all LDH vocabulary classes. Watch the `createDatatypeProperty` → `createDataProperty` method rename — this is not a pure import change.

Files: `LDH`, `LDHC`, `LDHT`, `LAPP`, `LACL`, `Admin`, `Default`, `ACL`, `Cert`, `DH`, `FOAF`, `Google`, `NFO`, `ORCID`, `PROV`, `SIOC`, `VoID`, plus `com.atomgraph.server.vocabulary.{HTTP,LDT}`.

Update every consumer that imports a typed constant (`OntClass`, `ObjectProperty`, `DatatypeProperty`, `AnnotationProperty`) — find/replace the imports.

## Phase 4 — LDH machinery (the actual work)

Driven by Phase 0 spike findings.

- **`Application.java:806`** — replace `OntDocumentManager.getInstance().setFileManager((FileManager) dataManager)` with a `DocumentGraphRepository` field configured via `addMapping()` for the URIs that `DataManagerImpl` resolves today.
- **`Application.java` lines 275, 284, 1781, 1792, 1796, 2018** — `OntModelSpec` field/parameter replacements.
- **`OntologyFilter.java:144–187`** — rewrite the per-request flow per spike outcome: inference materialization, import URI enumeration, caching.
- **`OntologyModelGetter.java`** — switch to `OntModelFactory.createModel()` + repository lookup.
- **`ClearOntology.java`** — same.
- **`Validator.java`** — type rename (weak coupling; signature only).
- **`XSLTWriterBase.java`, `ModelXSLTWriter.java`, `ResultSetXSLTWriter.java`** — type rename to match new Web-Client signatures.

## Phase 5 — Validation

Run the HTTP test suite via `./run.sh` from `http-tests/`. Pay particular attention to:

- Authorization tests — exercise the `acl:` ontology imports closure; sensitive to any change in import-resolution semantics
- Anything that loads multiple ontologies (admin app boot, end-user app boot)
- Cache-hit behavior on repeated requests for the same ontology

## Estimate

- **Phase 0 spike:** 2–3 days
- **Phases 1–3** (mechanical rename across 3 repos): 3–4 days
- **Phase 4** (machinery): 3 days if spike says ontapi maps cleanly; up to 2 weeks if a compatibility shim is needed
- **Phase 5** (HTTP test fixes / regression fixing): 2–3 days

**Total: ~2–3 weeks** if Phase 0 comes back clean; **4–6 weeks** if not.

## Risks

- `DocumentGraphRepository` is per-instance, not a process-wide singleton like `OntDocumentManager`. Multi-app/multi-dataspace wiring may need new threading discipline.
- Import-resolution semantics differ subtly between APIs. The HTTP authorization tests are the regression net but won't necessarily catch *performance* regressions (e.g., re-fetching cached imports).
- `OntSpecification.OWL2_DL_MEM` may have different default reasoner/personality settings than `OntModelSpec.OWL_MEM`. Verify before assuming it's a drop-in.
- Cross-repo coordination: Core and Web-Client need snapshots published before LDH can finish. Plan the merge order.

## Open questions for Phase 0 spike

1. Exact `OntSpecification` constant matching `OWL_MEM` semantics (no inference, full OWL vocabulary).
2. How to recreate the materialize-into-non-inferencing-model pattern in ontapi.
3. Does ontapi's import resolution respect a custom `FileManager`-equivalent for the `urn:` and `file:` URIs used by `DataManagerImpl`?
4. Is there a `cache="yes"`-equivalent gotcha (cf. SaxonJS) where ontapi memoises something we don't want memoised across requests?
