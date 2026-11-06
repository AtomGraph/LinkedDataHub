/-
`ldh-uploads`: the model's answers, for `tests/http/formal/uploads-conformance.sh` to replay against the server.

    ldh-uploads cases LENGTH SHA1    RANGE<TAB>IF-NONE-MATCH<TAB>IF-RANGE<TAB>ACCEPT<TAB>STATUS<TAB>CONTENT-RANGE
    ldh-uploads range-cases          RANGE<TAB>LENGTH<TAB>SELECTED

`cases`: one line per request to a file of LENGTH bytes named by SHA1 and stored as application/octet-stream. A `-`
is a header the request does not send, or the response does not carry. Every request is a GET. The front Varnish
drops an inverted range and `-0` before they reach the platform, so `cases` leaves them out; `range-cases` has them.

`range-cases`: `select` on each range over files of several lengths, SELECTED being `whole`, `FIRST-LAST` or `416`,
for `ByteRangeModelTest` to check `ByteRange.parse` against (src/test/resources/.../server/util/range-cases.tsv).

What this file adds to the proven model is unproven and small: the header syntax of each case, the 416's
`Content-Range` (`bytes */LENGTH`), and the lists of cases.
-/
import LdhUploads

open LdhUploads

def specs (len : Nat) : List (Option Spec) := [
  none,
  some (.int 0 (some 0)),
  some (.int 0 none),
  some (.int 0 (some (len - 1))),
  some (.int 10 (some 19)),
  some (.int (len - 1) none),
  some (.int len none),
  some (.int 20 (some 10)),
  some (.int 5 (some (len + 100))),
  some (.suffix 0),
  some (.suffix 1),
  some (.suffix len),
  some (.suffix (len + 10))
]

def rangeHeader : Option Spec → String
  | none => "-"
  | some (.int f (some l)) => s!"bytes={f}-{l}"
  | some (.int f none) => s!"bytes={f}-"
  | some (.suffix n) => s!"bytes=-{n}"

/-- What the front Varnish forwards to the platform. -/
def forwarded : Option Spec → Bool
  | some (.int f (some l)) => f ≤ l
  | some (.suffix 0) => false
  | _ => true

def selectedString : Selected → String
  | .whole => "whole"
  | .range f l => s!"{f}-{l}"
  | .unsatisfiable => "416"

def main : List String → IO UInt32
  | ["range-cases"] => do
    for len in [0, 1, 1000] do
      for s in (specs 1000).filter (·.isSome) do
        IO.println s!"{rangeHeader s}\t{len}\t{selectedString (select len s)}"
    return 0
  | ["cases", lenS, sha] => do
    let some len := lenS.toNat? | do IO.eprintln "LENGTH is not a number"; return 2
    let format := "application/octet-stream"
    let d : Desc := ⟨true, [format], []⟩
    for s in (specs len).filter forwarded do
      for inm in [none, some sha, some "0000"] do
        for ifRange in [true, false] do
          for accept in ["*/*", "text/turtle"] do
            let r : Req := ⟨true, fun m => accept == "*/*" || accept == m, inm, ifRange, s⟩
            let resp := serve List.head? addressTag d sha (some len) r
            let contentRange := match resp.contentRange with
              | some (f, l, n) => s!"bytes {f}-{l}/{n}"
              | none => if resp.status == 416 then s!"bytes */{len}" else "-"
            let inmS := match inm with | some t => s!"\"{t}\"" | none => "-"
            let ifRangeS := if ifRange then s!"\"{sha}\"" else "\"0000\""
            IO.println s!"{rangeHeader s}\t{inmS}\t{ifRangeS}\t{accept}\t{resp.status}\t{contentRange}"
    return 0
  | _ => do
    IO.eprintln "usage: ldh-uploads cases LENGTH SHA1 | range-cases"
    return 2
