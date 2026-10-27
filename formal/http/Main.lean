/-
`ldh-http`: the graph store's answer of `LdhHttp.Answer` over a live instance's datasets, with no authorization in
front of it: what the graph store does with a request it is asked to answer.

    ldh-http --dataset END_USER.nq [--dataset ADMIN.nq]... --request REQUEST.tsv
      [--payload PAYLOAD.nt | --delete DELETE.nt --insert INSERT.nt] [--fixed URI]...

The datasets are N-Quads dumps of the stores. A request is one line, `AGENT<TAB>METHOD<TAB>DOCUMENT<TAB>PRECONDITION`,
with `AGENT` a WebID or `-` (it owns a document it creates), `METHOD` one of `GET`, `HEAD`, `POST`, `PUT`, `PATCH`
and `DELETE`, and `PRECONDITION` one of `none`, `current` (`If-Match` with the current entity tag), `stale`
(`If-Match` with another) and `absent` (`If-None-Match: *`). The body of a `POST` or `PUT` is the `--payload`
N-Triples; a `PATCH` is `DELETE { --delete } INSERT { --insert } WHERE {}`. `--fixed` names the owner's and the
secretary's WebID documents. The status comes back on the first line, then the document's graph after the request,
as N-Triples.
-/
import LdhHttp

open LdhHttp

structure Args where
  datasets : List String := []
  request : Option RequestFiles := none

partial def parseArgs : List String → Args → Except String Args
  | [], a => .ok a
  | "--dataset" :: v :: rest, a => parseArgs rest { a with datasets := a.datasets ++ [v] }
  | "--request" :: v :: rest, a => parseArgs rest { a with request := some { (a.request.getD { request := v }) with request := v } }
  | args@(arg :: _), a =>
    match parseRequestArg args (a.request.getD { request := "" }) with
    | some (rest, f) => parseArgs rest { a with request := some f }
    | none => .error s!"unknown argument: {arg}"

def usage : String :=
  "usage: ldh-http --dataset DATASET.nq... --request REQUEST.tsv " ++
    "[--payload PAYLOAD.nt | --delete DELETE.nt --insert INSERT.nt] [--fixed URI]..."

def main (argv : List String) : IO UInt32 := do
  let args ← match parseArgs argv {} with
    | .ok a => pure a
    | .error e => IO.eprintln e; IO.eprintln usage; return 2
  let some files := args.request
    | IO.eprintln usage; return 2
  let mut i : Interner := {}
  let mut triples : Array (Node × Triple) := #[]
  for path in args.datasets do
    let (ts, i') := internQuads i (← readQuads path)
    i := i'
    triples := triples ++ ts
  let r ← match ← loadRequest i files with
    | .ok r => pure r
    | .error e => IO.eprintln e; return 2
  let (status, fs') := respondB r.hs (toFinStore triples) r.agent r.pc r.req
  printAnswer r.interner status fs' r.req.target
  return 0
