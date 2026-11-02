/-
`ldh-http`: the graph store's answer of `LdhHttp.Answer` over a live instance's datasets, with no authorization in
front of it: what the graph store does with a request it is asked to answer.

    ldh-http --dataset END_USER.nq [--dataset ADMIN.nq]... --request REQUEST.tsv
      [--payload PAYLOAD.nt | --delete DELETE.nt --insert INSERT.nt] [--fixed URI]...
    ldh-http --select HISTORY.tsv [--datetime SECONDS]
    ldh-http --select-cases

The datasets are N-Quads dumps of the stores. A request is one line, `AGENT<TAB>METHOD<TAB>DOCUMENT<TAB>PRECONDITION`,
with `AGENT` a WebID or `-` (it owns a document it creates), `METHOD` one of `GET`, `HEAD`, `POST`, `PUT`, `PATCH`
and `DELETE`, and `PRECONDITION` one of `none`, `current` (`If-Match` with the current entity tag), `stale`
(`If-Match` with another) and `absent` (`If-None-Match: *`). The body of a `POST` or `PUT` is the `--payload`
N-Triples; a `PATCH` is `DELETE { --delete } INSERT { --insert } WHERE {}`. `--fixed` names the owner's and the
secretary's WebID documents. The status comes back on the first line, then the document's graph after the request,
as N-Triples.

`--select` is the TimeGate's choice (`selectMemento`) for a history, one `SHA<TAB>SECONDS` line per commit, most
recent first, and an `Accept-Datetime` in seconds since the epoch, or none: the selected SHA, or `none` for an empty
history. `--select-cases` prints a fixed set of generated histories and datetimes with the choice for each, one
`SECONDS,...<TAB>DATETIME<TAB>INDEX` line per case (`-` for no datetime, or no Memento): the `memento-cases.tsv` of
`GraphVersioningServiceTest`'s resources, which the `Formal` workflow regenerates and the test replays against the
Java.
-/
import LdhHttp

open LdhHttp

structure Args where
  datasets : List String := []
  request : Option RequestFiles := none
  select : Option String := none
  datetime : Option Int := none
  selectCases : Bool := false

partial def parseArgs : List String → Args → Except String Args
  | [], a => .ok a
  | "--dataset" :: v :: rest, a => parseArgs rest { a with datasets := a.datasets ++ [v] }
  | "--select" :: v :: rest, a => parseArgs rest { a with select := some v }
  | "--datetime" :: v :: rest, a => match v.toInt? with
    | some d => parseArgs rest { a with datetime := some d }
    | none => .error s!"cannot read datetime: {v}"
  | "--select-cases" :: rest, a => parseArgs rest { a with selectCases := true }
  | "--request" :: v :: rest, a => parseArgs rest { a with request := some { (a.request.getD { request := v }) with request := v } }
  | args@(arg :: _), a =>
    match parseRequestArg args (a.request.getD { request := "" }) with
    | some (rest, f) => parseArgs rest { a with request := some f }
    | none => .error s!"unknown argument: {arg}"

def usage : String :=
  "usage: ldh-http --dataset DATASET.nq... --request REQUEST.tsv " ++
    "[--payload PAYLOAD.nt | --delete DELETE.nt --insert INSERT.nt] [--fixed URI]...\n" ++
    "       ldh-http --select HISTORY.tsv [--datetime SECONDS]\n" ++
    "       ldh-http --select-cases"

/-! ## The TimeGate -/

/-- A linear congruential generator: the cases are the same on every run and every machine. -/
def lcg (x : Nat) : Nat := (1664525 * x + 1013904223) % 4294967296

/-- `n` cases from `seed`: histories of up to six commits, most recent first, a few seconds apart and some at the
same second, so that the datetimes fall between, on and beside them, and two commits are often as close. -/
def selectCases (n seed : Nat) : List (List Int × Option Int) := Id.run do
  let mut x := seed
  let mut out := #[]
  for _ in [0:n] do
    x := lcg x
    let len := (x / 65536) % 7
    x := lcg x
    let mut t : Int := ((x / 65536) % 100 : Nat)
    let mut times := #[]
    for _ in [0:len] do
      times := times.push t
      x := lcg x
      t := t - (((x / 65536) % 6 : Nat) : Int)
    x := lcg x
    let dt : Option Int := if (x / 65536) % 6 = 0 then none else
      let lo := (times.toList.getLastD 0) - 10
      let hi := (times.toList.headD 0) + 10
      some (lo + (((x / 256) % (hi - lo + 1).toNat : Nat) : Int))
    out := out.push (times.toList, dt)
  return out.toList

def runSelectCases : IO UInt32 := do
  for (times, dt) in selectCases 500 20261027 do
    let history := times.enum.map fun (i, t) => ({ sha := i, time := t } : Commit)
    let chosen := match selectMemento history dt with
      | some c => toString c.sha
      | none => "-"
    let dts := match dt with
      | some d => toString d
      | none => "-"
    IO.println s!"{",".intercalate (times.map toString)}\t{dts}\t{chosen}"
  return 0

def runSelect (path : String) (dt : Option Int) : IO UInt32 := do
  let lines := (← IO.FS.lines path).toList.filter (!·.trim.isEmpty)
  let mut shas := #[]
  let mut history := #[]
  for line in lines do
    match line.splitOn "\t" with
    | [sha, t] => match t.trim.toInt? with
      | some time =>
        history := history.push ({ sha := shas.size, time := time } : Commit)
        shas := shas.push sha
      | none => IO.eprintln s!"cannot read time: {line}"; return 2
    | _ => IO.eprintln s!"cannot read commit: {line}"; return 2
  match selectMemento history.toList dt with
  | some c => IO.println (shas.getD c.sha "")
  | none => IO.println "none"
  return 0

def main (argv : List String) : IO UInt32 := do
  let args ← match parseArgs argv {} with
    | .ok a => pure a
    | .error e => IO.eprintln e; IO.eprintln usage; return 2
  if args.selectCases then return ← runSelectCases
  if let some path := args.select then return ← runSelect path args.datetime
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
