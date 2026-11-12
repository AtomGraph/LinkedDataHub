/-
`ldh-client`: the model's answers, for the workflow to check the stylesheets against.

    ldh-client href-cases   the href cases: PAGE<TAB>URI<TAB>PATH, one per line
    ldh-client sites        the request sites not built by ldh:href: FILE<TAB>EXPRESSION, one per line

PATH is `ldh:href(URI)` on PAGE up to its first `?`: the path the target is requested at, which is what decides its
origin. `href-cases.xsl` computes it with the stylesheets' own functions, and `sites.py` reads the sites off them.

What this file adds to the proven model is unproven and small: a concrete query map, whose contents never reach
PATH, and the lists of cases.
-/
import LdhClient

open LdhClient

/-- A query map as a list of entries; its string has no percent-encoding, since PATH ends where it starts. -/
def query : Query where
  P := List (Str × Str)
  empty := []
  withUri u q := ("uri".toList, u) :: q
  overlay a b := a ++ b
  parse s := (((String.mk s).splitOn "&").filter (fun t => t.any (!·.isWhitespace))).map fun t =>
    (t.toList.takeWhile (· != '='), after '=' t.toList)
  string q := if q.isEmpty then [] else '?' :: List.intercalate ['&'] (q.map fun (k, v) => k ++ '=' :: v)
  string_shape q := by
    by_cases h : q.isEmpty
    · left; simp [h]
    · right
      exact ⟨List.intercalate ['&'] (q.map fun (k, v) => k ++ '=' :: v), by simp [h]⟩

def pages : List String := [
  "https://localhost:4443/",
  "https://localhost:4443/x/?mode=y#f",
  "https://localhost:4443/?uri=https%3A%2F%2Fevil.example%2F",
  "https://admin.localhost:4443/acl/",
  "http://localhost:8080/a"
]

def uris : List String := [
  "",
  "https://localhost:4443/",
  "https://localhost:4443",
  "https://localhost:4443/a?b=c#d",
  "https://localhost:4443/a#b?c",
  "https://localhost:4443/a#b",
  "https://localhost:4443/../x",
  "https://localhost:44430/x",
  "https://localhost:4443.evil.example/",
  "https://localhost:4443@evil.example/",
  "HTTPS://localhost:4443/x",
  "http://localhost:4443/x",
  "https://admin.localhost:4443/",
  "http://localhost:8080/b",
  "//evil.example/x",
  "/x",
  "?q=1",
  "#f",
  "javascript:alert(1)",
  "data:text/html,<b>x</b>",
  "urn:x:y",
  "https://evil.example/a?uri=https://localhost:4443/"
]

def main : List String → IO UInt32
  | ["href-cases"] => do
    for p in pages do
      for u in uris do
        let r := (href query p.toList (some u.toList) query.empty none).getD []
        IO.println s!"{p}\t{u}\t{String.mk (before '?' (r ++ ['?']))}"
    return 0
  | ["sites"] => do
    for s in sites do
      IO.println s!"{s.file}\t{s.expr}"
    return 0
  | _ => do
    IO.eprintln "usage: ldh-client href-cases | sites"
    return 2
