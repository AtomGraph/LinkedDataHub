/-
`ldh-auth`: the WebID filter of `LdhAuth.Model` over WebID documents and a request, for `tests/http/formal/` to
replay against the server.

    ldh-auth --doc URI DOC.nt [--doc URI DOC.nt]... [--internal URI]... [--cache CACHE.nq] [--cache-out CACHE.nq]
      --request REQUEST.tsv

Each `--doc` is what dereferencing a document URI returns, as N-Triples; a document with none answers other than
2xx. `--internal` names a URI `URLValidator` refuses. `--cache` is the WebID cache before the request, one graph per
cached WebID, and `--cache-out` where the cache after it is written.

The request is one line, `WEBID<TAB>MODULUS<TAB>EXPONENT<TAB>ON-BEHALF-OF`: the WebID of the client certificate (`-`
for none), its RSA modulus in lower-case hex without leading zeros and its public exponent in decimal, as
`WebIDFilter` binds them, and the `On-Behalf-Of` header (`-` for none, `!` for a value that is not a URI). The certificate is valid, and comes through
nginx, so with the proxy secret. The answer is one line: `agent URI`, `anonymous`, or the status the failure is
answered with.

What this file adds to the proven model is unproven and small: stripping a fragment, and reading the files. Reading
N-Triples and N-Quads is `LdhHttp.IO`'s.
-/
import LdhAuth
import LdhHttp.IO
import Std.Data.HashMap

open LdhHttp LdhAuth Std

namespace V
def certKey := "http://www.w3.org/ns/auth/cert#key"
def certModulus := "http://www.w3.org/ns/auth/cert#modulus"
def certExponent := "http://www.w3.org/ns/auth/cert#exponent"
def aclDelegates := "http://www.w3.org/ns/auth/acl#delegates"
def siocId := "http://rdfs.org/sioc/ns#id"
def laclIssuer := "https://w3id.org/atomgraph/linkeddatahub/admin/acl#issuer"
def siocAccountOf := "http://rdfs.org/sioc/ns#account_of"
def foafMbox := "http://xmlns.com/foaf/0.1/mbox"
def xsdHexBinary := "http://www.w3.org/2001/XMLSchema#hexBinary"
def xsdInteger := "http://www.w3.org/2001/XMLSchema#integer"
end V

/-- The URI without its fragment: what `loadWebIDFromURI` dereferences. -/
def stripFragment (s : String) : String := (s.splitOn "#").headD s

structure Args where
  docs : List (String × System.FilePath) := []
  internal : List String := []
  cache : Option System.FilePath := none
  cacheOut : Option System.FilePath := none
  request : Option System.FilePath := none

def parseArgs : List String → Args → Except String Args
  | [], a => .ok a
  | "--doc" :: u :: f :: rest, a => parseArgs rest { a with docs := a.docs ++ [(u, System.FilePath.mk f)] }
  | "--internal" :: u :: rest, a => parseArgs rest { a with internal := u :: a.internal }
  | "--cache" :: f :: rest, a => parseArgs rest { a with cache := some (System.FilePath.mk f) }
  | "--cache-out" :: f :: rest, a => parseArgs rest { a with cacheOut := some (System.FilePath.mk f) }
  | "--request" :: f :: rest, a => parseArgs rest { a with request := some (System.FilePath.mk f) }
  | arg :: _, _ => .error s!"unknown argument: {arg}"

def usage : String :=
  "usage: ldh-auth --doc URI DOC.nt... [--internal URI]... [--cache CACHE.nq] [--cache-out CACHE.nq] --request REQUEST.tsv"

def internMany (i : Interner) (ss : List String) : Interner := ss.foldl (fun i s => (i.intern s).2) i

def main (argv : List String) : IO UInt32 := do
  let args ← match parseArgs argv {} with
    | .ok a => pure a
    | .error e => IO.eprintln e; IO.eprintln usage; return 2
  let some requestPath := args.request
    | IO.eprintln usage; return 2
  let line := ((← IO.FS.readFile requestPath).splitOn "\n").headD ""
  let (webIDName, modulus, exponent, oboName) ← match line.trim.splitOn "\t" with
    | [w, m, e, o] => pure (w, m, e, o)
    | _ => IO.eprintln s!"cannot read request: {line}"; return 2
  let i : Interner := {}
  let (vocab, i) := i.internAll [V.certKey, V.certModulus, V.certExponent, V.aclDelegates, V.siocId, V.laclIssuer,
    V.siocAccountOf, V.foafMbox]
  let vb : Vocab := match vocab with
    | [a, b, c, d, e, f, g, h] => ⟨a, b, c, d, e, f, g, h⟩
    | _ => ⟨.iri 0, .iri 0, .iri 0, .iri 0, .iri 0, .iri 0, .iri 0, .iri 0⟩
  -- the documents, then the cache, then the request's terms
  let mut i := i
  let mut docs : HashMap Node Doc := {}
  for (u, f) in args.docs do
    let (n, i1) := i.intern u
    let (ts, i2) := internTriples i1 (← readTriples f)
    i := i2
    docs := docs.insert n ts
  let mut cached : HashMap Node (Array Triple) := {}
  if let some f := args.cache then
    for q in ← readQuads f do
      let (t, i1) := internTriple i q.s q.p q.o
      let (g, i2) := i1.intern q.g.storeKey
      i := i2
      cached := cached.insert g ((cached.getD g #[]).push t)
  let modLit := s!"\"{modulus}\"^^<{V.xsdHexBinary}>"
  let expLit := s!"\"{exponent}\"^^<{V.xsdInteger}>"
  i := internMany i ([modLit, expLit] ++ args.internal ++ [webIDName, oboName].filter fun s => s != "-" && s != "!")
  -- every name's document, interned last so that every URI the model may dereference has one
  i := internMany i (i.nodes.toList.map fun (k, _) => stripFragment k)
  let names : HashMap Node String := i.nodes.fold (fun m k n => m.insert n k) {}
  let node (s : String) : Node := i.nodes.getD s (.iri 0)
  let internal := args.internal.map node
  let web : Web := {
    docOf := fun n => node (stripFragment (names.getD n ""))
    fetch := fun n => match docs[n]? with
      | some d => .ok d
      | none => .refused
    internal := fun n => internal.contains n
    isUri := fun n => let k := names.getD n ""; !(k.startsWith "\"" || k.startsWith "_:") }
  let cache : Cache := fun n => (cached[n]?).map (·.toList)
  let cert : Option Cert :=
    if webIDName == "-" then none else some ⟨true, some (node webIDName), ⟨node modLit, node expLit⟩⟩
  let obo : Obo := if oboName == "-" then .none else if oboName == "!" then .malformed else .uri (node oboName)
  let (out, cache') := webid vb web cache cert obo
  match out with
  | .ok a => IO.println s!"agent {names.getD a ""}"
  | .anon => IO.println "anonymous"
  | .err e => IO.println s!"{e.code}"
  if let some f := args.cacheOut then
    -- the cache after the request: every WebID it held before, and the ones the request loaded. A key document that
    -- is the WebID's own is loaded twice, as the server does; Jena's model merges the copies, and so does the file
    let keys := (cached.toList.map (·.1) ++ [cert.bind (·.webID), match obo with | .uri p => some p | _ => none].filterMap id).eraseDups
    let lines := keys.flatMap fun g => match cache' g with
      | some d => d.eraseDups.map fun t => s!"{render names t.s} {render names t.p} {render names t.o} {render names g} ."
      | none => []
    IO.FS.writeFile f (String.intercalate "\n" lines ++ "\n")
  return 0
