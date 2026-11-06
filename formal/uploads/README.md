# LinkedDataHub uploads model in Lean

A Lean 4 model of uploaded files: what the graph store's writes do to the upload folder, what an upload is described
and authorized by, and how it is served. It proves that a refused write stores nothing, that a file is stored and
served by its digest with the media type it was first uploaded with, who may read it, and what a 200, 206 and 416
carry.

The model is a specification. It is not extracted from the code: each definition is transcribed from the code
listed in the mapping below, and when that code changes, the definition changes in the same commit.

## Building

```bash
cd formal/uploads
lake build
```

Lean `v4.15.0` (pinned in `lean-toolchain`), core library only, with no Mathlib. The model requires the graph store
model by path (`require LdhHttp from "../http"`): its writes commit an upload's files, and its graphs describe it.

The `Formal` workflow builds it on every push, fails on a `sorry`, and diffs the range cases (see "Replaying"). On a
pull request it also runs `tracks-code.sh`, which fails when a source listed under "Mapping to the code" changes
without a change in this directory:

```bash
formal/uploads/tracks-code.sh origin/develop
```

## Files

| File | Contents |
|------|----------|
| `LdhUploads/Disk.lean` | The upload folder, the commit of staged files, and what the graph store's answer does to it |
| `LdhUploads/Describe.lean` | An upload's description, what any write adds to it, and what the authorization decision knows of it |
| `LdhUploads/Serve.lean` | Byte ranges, and the response to a GET |
| `Main.lean` | `ldh-uploads`: the serving cases and the range cases |
| `tracks-code.sh` | The check that the model changes with its sources |

The range cases are kept at `src/test/resources/com/atomgraph/linkeddatahub/server/util/range-cases.tsv`, where the
Docker build's unit tests can read them.

## The model

**The disk** is a map from a digest to bytes (`Disk`), the digest a function of the bytes. A request whose multipart
body staged some files commits them only when the graph store's answer (`LdhHttp.answerB`) goes ahead
(`respondU`): `post()` and `put()` run the commit just before writing the graph, after every check, and a refused or
failed write discards what was staged. Committing a file stores it under its digest unless something is stored
there already (`commitOne`), and records beside it (`Records`, `recordOne`) the media type it was uploaded with,
unless one is recorded, and the document the request wrote, the one it was uploaded into. Nothing else touches the
disk or the records.

**The description** of an upload is `DESCRIBE` of its URI, which Jena answers from every graph (`describe`). An upload's
URI is under `uploads/`, where no document is, so it has no graph of its own. The authorization decision's document
context for it (`uploadContext`) is the rows the context query gives a URI without a graph: the URI itself, and the
class `nfo:FileDataObject` when some graph types it so. Reading it (`uploadReadable`) takes a grant on that context,
or the grant to read one of the documents of this dataspace recorded for it.

**Serving** (`serve`) is `Item.getResponseBuilder`: 404 for a URI nothing describes; 406 when `Accept` does not take
the media type, which is the recorded one, and one of the description's `dct:format` values for a file uploaded
before types were recorded; 304 when `If-None-Match` names the entity
tag; 404 for a file not on disk; and otherwise the file, whole or a range of it or 416, where `Range` applies, which
is a GET whose `If-Range` holds. **A range** (`select`) is `ByteRange.parse` on a single range-spec: the header's
other forms (another unit, several ranges, a spec that does not parse) select the whole file, and are taken before
the model.

## Mapping to the code

| Model | Code |
|-------|------|
| `commitOne`, `commit`, `respondU` | `DocumentHierarchyGraphStoreImpl`: `stageFiles`, `commitFiles`, `discardFiles`, and the `beforeWrite` step of `post()` and `put()` |
| `Records`, `recordOne`, `record`, `respondR` | `UploadRecords.record`, as `commitFiles` calls it with the request's document |
| `describe` | web.xml `fileQuery` (`DESCRIBE $this`), as `Item.describe()` runs it |
| `uploadContext` | web.xml `documentContextQuery`: the `acl:accessTo` branch and the `nfo:FileDataObject` one |
| `uploadReadable` | `AuthorizationFilter.authorize`, then `authorizeUpload` for a read that the upload's own context does not grant |
| `serve`, `addressTag`, `recordedFormat` | `Item.getResponseBuilder`, `Item.getEntityTag`, `Item.getMediaType` |
| `describedTag`, `describedFormat` | `Item.getEntityTag` and `Item.getMediaType` before this model: `getRequiredProperty(FOAF.sha1)`, `getPropertyResourceValue(DCTerms.format)` |
| `select`, `Spec` | `ByteRange.parse` |

## Results

Proven with no `sorry`, using only the axioms `propext`, `Quot.sound` and `Classical.choice`:

| Theorem | Statement |
|---------|-----------|
| `refused_stores_nothing` | A write the graph store refuses leaves the disk as it was |
| `disk_never_shrinks` | No request removes or replaces a stored file |
| `content_addressed` | Every stored file is stored under its own digest, and stays so |
| `first_writer_wins` | A file whose digest is taken is not stored: the bytes there stay |
| `served_bytes_uploaded` | With the digest collision-free on the bytes ever uploaded, a URI serves the bytes it is named for |
| `any_writer_describes_any_upload` | A PUT to any document states in an upload's description what its payload says of the upload |
| `type_first_writer` | A recorded media type is never changed |
| `recorded_by_uploaders` | A document is recorded for a digest only by an accepted write to it that uploaded bytes with that digest |
| `upload_context` | An upload's own document context names it by its URI and `nfo:FileDataObject`, and by no document that describes it |
| `upload_readable` | An upload is read with a grant on its own context, or the grant to read a recorded document of this dataspace |
| `served_sandboxed` | Every 200 and 206 carries `Content-Security-Policy: default-src 'none'; sandbox` |
| `range_sound`, `served_range_sound` | A selected range, and so a 206's `Content-Range`, lies within the file |
| `unsatisfiable_iff` | 416 exactly for a zero-length suffix, a first position past the file, or a last before the first |
| `etag_content_addressed` | The entity tag is the digest the URI is named by, whatever the description says |
| `etag_was_any_writers` | Before: a second `foaf:sha1` made the tag one the file is not named by, and a request conditional on it was answered 304 |
| `format_first_uploaders` | The served media type is the recorded one, whatever the description states |
| `format_was_any_writers` | Before: the served media type was a pick among the `dct:format` values any writer stated |

`served_bytes_uploaded` takes SHA-1 to be collision-free on what is uploaded, as an assumption: a collision would
plant the first writer's bytes under the second's URI (`first_writer_wins`), and SHA-1 collisions can be made.

Three findings were reproduced or proven of the code as it was, and are fixed with the model. All three come from
`any_writer_describes_any_upload`: an upload's description merges what every graph says of it, which any writer of
any document adds to, and Jena's `DESCRIBE` over two graphs returned both digests and both formats.

- `etag_was_any_writers`, now `etag_content_addressed`: the entity tag was read from the description, so a second
  `foaf:sha1` made it a pick between the two, and a request conditional on the stated one was answered 304. The tag is
  now the URI's digest. `tests/http/imports/GET-file-etag-content-address.sh` states a second digest from another
  document and checks the tag and a request conditional on it.
- `format_was_any_writers`, now `format_first_uploaders`: the media type was a pick among the `dct:format` values
  every writer stated. The sandbox policy kept that from running anything (`served_sandboxed`), but the type was
  still anyone's. It is now the one recorded beside the bytes on their first upload, in `uploads/.types/{sha1}`, which
  no URI addresses. `tests/http/imports/GET-file-format-first-upload.sh` states two other formats from another
  document and checks the type.
- `upload_context`, now with `upload_readable`: who could read an upload was decided by grants on
  `nfo:FileDataObject` alone, never by the documents it was uploaded into, so an agent granted one document could not
  read the files in it. Reading now also follows the documents recorded in `uploads/.documents/{sha1}`, which only an
  upload of the bytes into the document adds to (`recorded_by_uploaders`): describing a file in some graph grants
  nothing. `tests/http/imports/GET-file-read-through-document.sh` grants an agent one document and checks it reads
  the file uploaded there, and not one uploaded into another.

A file uploaded before the records existed has none: it is served with the description's type and read with the
class grant, as before.

## Replaying

`tests/http/formal/uploads-conformance.sh` uploads a file, and `ldh-uploads cases` predicts the status and
`Content-Range` of a GET for each combination of thirteen ranges, three `If-None-Match` values, a matching and a
stale `If-Range`, and two `Accept` values; the server, through the whole stack, has to answer the same, and every 200
and 206 carry the sandbox policy. The front Varnish drops an inverted range and `-0` before they reach the platform
(its VCL says why), so the cases leave those two out.

`ldh-uploads range-cases` prints `select` on every range over files of 0, 1 and 1000 bytes, and
`ByteRangeModelTest` checks `ByteRange.parse` against the copy under `src/test/resources`, all of them included. The
workflow diffs that copy against the model's output.

## Not modelled

- The bytes' media type as a browser would sniff it, and `Content-Disposition`.
- Staging itself: the multipart parsing, the request size limit, and the renaming of the file's resource to its
  digest's URI, which `stageFiles` does before the write is checked.
- A write that fails after its files are committed, which leaves files no graph describes; the disk only grows, so
  they stay until removed by hand.
- `HEAD`, which answers as the 200 a GET without `Range` would, and the front servers' caching.
- The authorization decision itself, which `formal/acl` models over documents; `uploadReadable` takes its answer for
  the upload's own context and for each recorded document as given.
