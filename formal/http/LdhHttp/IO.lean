/-
Reading a live instance's data and a request into the model's terms, and printing an answer. Unproven and small:
the N-Triples and N-Quads reader, the interning of terms as nodes (literals included, so that a payload of
literals is not empty), the URI parent `put()` resolves, and the URI checks of `put()` (a root is its own URI
parent; a trailing slash; a double slash in the path).
-/
import LdhHttp.Answer
import Std.Data.HashMap

namespace LdhHttp

open Std

instance : Hashable Node where
  hash
    | .rdfType => 1 | .aclOwner => 2 | .dctCreator => 3 | .siocHasParent => 4 | .siocHasContainer => 5
    | .nfoFileDataObject => 6 | .dhContainer => 7 | .dhItem => 8 | .defRoot => 9
    | .iri n => hash (n + 16)

/-! ## Terms and quads -/

inductive Term where
  | iri (s : String)
  | blank (s : String)
  /-- A literal, as written: the quoted form with its language tag or datatype. -/
  | literal (s : String)
  deriving Repr, BEq

structure Quad where
  s : Term
  p : Term
  o : Term
  g : Term

/-- The name a node is interned under: an IRI, or a blank node label, which cannot collide with an IRI. The admin
dataset is read through these alone, as `aclQuery` matches no literal. -/
def Term.key : Term → Option String
  | .iri s => some s
  | .blank s => some s
  | .literal _ => none

/-- The name a store's term is interned under: a literal as written, which cannot collide with an IRI or a blank
node label either. The graph store's answer reads literals: a payload of literals alone is not empty. -/
def Term.storeKey : Term → String
  | .iri s => s
  | .blank s => s
  | .literal s => s

/-! ## N-Quads -/

/-- One term from the front of `s`; the rest after it. -/
partial def parseTerm (s : Substring) : Option (Term × Substring) :=
  let s := s.trimLeft
  if s.isEmpty then none
  else match s.front with
  | '<' =>
    let body := (s.drop 1).takeWhile (· ≠ '>')
    let rest := (s.drop 1).dropWhile (· ≠ '>')
    if rest.isEmpty then none else some (.iri body.toString, rest.drop 1)
  | '_' =>
    let body := s.takeWhile fun c => !c.isWhitespace
    some (.blank body.toString, s.drop body.bsize)
  | '"' =>
    -- the closing quote is the first one not escaped
    let rec close (t : Substring) (escaped : Bool) : Substring :=
      if t.isEmpty then t
      else
        let c := t.front
        if escaped then close (t.drop 1) false
        else if c == '\\' then close (t.drop 1) true
        else if c == '"' then t.drop 1
        else close (t.drop 1) false
    let after := close (s.drop 1) false
    -- a language tag or a datatype follows without a space
    let after := after.dropWhile fun c => !c.isWhitespace
    some (.literal (Substring.mk s.str s.startPos after.startPos).toString, after)
  | _ => none

def parseQuad (line : String) : Option Quad := do
  let (s, r) ← parseTerm line.toSubstring
  let (p, r) ← parseTerm r
  let (o, r) ← parseTerm r
  let (g, _) ← parseTerm r
  pure ⟨s, p, o, g⟩

def parseTriple (line : String) : Option (Term × Term × Term) := do
  let (s, r) ← parseTerm line.toSubstring
  let (p, r) ← parseTerm r
  let (o, _) ← parseTerm r
  pure (s, p, o)

def readTriples (path : System.FilePath) : IO (Array (Term × Term × Term)) := do
  let lines ← IO.FS.lines path
  let mut triples := #[]
  for line in lines do
    let t := line.trim
    if t.isEmpty || t.startsWith "#" then continue
    match parseTriple t with
    | some q => triples := triples.push q
    | none => throw (IO.userError s!"cannot read N-Triples line: {line}")
  pure triples

def readQuads (path : System.FilePath) : IO (Array Quad) := do
  let lines ← IO.FS.lines path
  let mut quads := #[]
  for line in lines do
    let t := line.trim
    if t.isEmpty || t.startsWith "#" then continue
    match parseQuad t with
    | some q => quads := quads.push q
    | none => throw (IO.userError s!"cannot read N-Quads line: {line}")
  pure quads

/-! ## Vocabulary -/

namespace V
def rdfType := "http://www.w3.org/1999/02/22-rdf-syntax-ns#type"
def aclOwner := "http://www.w3.org/ns/auth/acl#owner"
def dctCreator := "http://purl.org/dc/terms/creator"
def siocHasParent := "http://rdfs.org/sioc/ns#has_parent"
def siocHasContainer := "http://rdfs.org/sioc/ns#has_container"
def nfoFileDataObject := "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#FileDataObject"
def dhContainer := "https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#Container"
def dhItem := "https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#Item"
def defRoot := "https://w3id.org/atomgraph/linkeddatahub/default#Root"
end V


/-- The terms the decision reads are constructors of `Node`; every other one is interned. -/
def vocabulary : List (String × Node) :=
  [(V.rdfType, .rdfType), (V.aclOwner, .aclOwner), (V.dctCreator, .dctCreator), (V.siocHasParent, .siocHasParent),
   (V.siocHasContainer, .siocHasContainer), (V.nfoFileDataObject, .nfoFileDataObject),
   (V.dhContainer, .dhContainer), (V.dhItem, .dhItem), (V.defRoot, .defRoot)]

structure Interner where
  nodes : HashMap String Node := vocabulary.foldl (fun m (k, n) => m.insert k n) {}
  next : Nat := 0

def Interner.intern (i : Interner) (key : String) : Node × Interner :=
  match i.nodes[key]? with
  | some n => (n, i)
  | none => (.iri i.next, { nodes := i.nodes.insert key (.iri i.next), next := i.next + 1 })

/-- Interns a batch of keys, in order. -/
def Interner.internAll (i : Interner) (keys : List String) : List Node × Interner :=
  keys.foldr (fun k (ns, i) => let (n, i) := i.intern k; (n :: ns, i)) ([], i)

/-! ## Reading the stores -/

def internTriple (i : Interner) (s p o : Term) : Triple × Interner :=
  let (ns, i) := i.intern s.storeKey
  let (np, i) := i.intern p.storeKey
  let (no, i) := i.intern o.storeKey
  (⟨ns, np, no⟩, i)

/-- Every quad, literals included, as a triple under its graph name. -/
def internQuads (i : Interner) (quads : Array Quad) : Array (Node × Triple) × Interner := Id.run do
  let mut i := i
  let mut out := #[]
  for q in quads do
    let (t, i1) := internTriple i q.s q.p q.o
    let (ng, i2) := i1.intern q.g.storeKey
    i := i2
    out := out.push (ng, t)
  pure (out, i)

def internTriples (i : Interner) (ts : Array (Term × Term × Term)) : List Triple × Interner := Id.run do
  let mut i := i
  let mut out := #[]
  for (s, p, o) in ts do
    let (t, i1) := internTriple i s p o
    i := i1
    out := out.push t
  pure (out.toList, i)

/-- A node as an N-Triples term, from the name it was interned under. -/
def render (names : HashMap Node String) (n : Node) : String :=
  let k := names.getD n ""
  if k.startsWith "\"" || k.startsWith "_:" then k else s!"<{k}>"

/-- Groups interned quads by graph. -/
def toFinStore (quads : Array (Node × Triple)) : FinStore := Id.run do
  let mut m : HashMap Node (List Triple) := {}
  for (g, t) in quads do
    m := m.insert g (t :: m.getD g [])
  pure (m.toList)

/-! ## The site -/

/-- The URI parent `put()` resolves: `..` against the document URI, by RFC 3986. The base's last segment goes
first, so a URI with a trailing slash (every document the graph store has) climbs one level, and one without
climbs two: `/a/b/` and `/a/b/c` both give `/a/`. The root of a tree is its own parent. -/
def parentIri (s : String) : String :=
  -- no path at all: nothing to climb
  if !(((s.splitOn "://").getD 1 "").contains '/') then s else
  -- the directory of the URI: up to and including its last slash
  let dir := match s.revPosOf '/' with
    | some pos => s.extract 0 (s.next pos)
    | none => s
  let core := dir.dropRight 1
  match core.revPosOf '/' with
  | none => s
  | some pos =>
    let before := core.extract 0 pos
    -- the slash found belongs to the scheme's `//`: the URI has no path above it
    if before.endsWith "/" || before.endsWith ":" then dir else core.extract 0 (core.next pos)

/-- The URI's path has a double slash. -/
def doubleSlash (s : String) : Bool :=
  decide ((((s.splitOn "://").getD 1 "").splitOn "//").length > 1)

def parsePrecond : String → Option Precond
  | "none" => some .none
  | "current" => some .current
  | "stale" => some .stale
  | "absent" => some .absent
  | _ => none

/-! ## Requests -/

/-- Where a request and its body are read from. -/
structure RequestFiles where
  request : String
  payload : Option String := none
  delete : Option String := none
  insert : Option String := none
  /-- The owner's and the secretary's WebID documents. -/
  fixed : List String := []

/-- A request read and interned: the site constants about its document, the agent, the precondition and the
request. -/
structure LoadedRequest where
  hs : HSite
  agent : Option Node
  pc : Precond
  req : HReq
  interner : Interner

/-- Reads `AGENT<TAB>METHOD<TAB>DOCUMENT<TAB>PRECONDITION` and the body files, interning their terms. -/
def loadRequest (i : Interner) (files : RequestFiles) : IO (Except String LoadedRequest) := do
  let line := ((← IO.FS.lines files.request).toList.filter (!·.trim.isEmpty)).headD ""
  let (agentKey, method, target, pc) ← match line.splitOn "\t" with
    | [a, m, t, p] => match parsePrecond p with
      | some pc => pure (if a == "-" then none else some a, m, t, pc)
      | none => return .error s!"cannot read precondition: {p}"
    | _ => return .error s!"cannot read request: {line}"
  let readOpt (path : Option String) : IO (Array (Term × Term × Term)) :=
    match path with
    | some p => readTriples p
    | none => pure #[]
  let payloadTerms ← readOpt files.payload
  let deleteTerms ← readOpt files.delete
  let insertTerms ← readOpt files.insert
  let (x, i) := i.intern target
  let (parent, i) := i.intern (parentIri target)
  let (agent, i) := match agentKey with
    | some a => let (n, i) := i.intern a; (some n, i)
    | none => (none, i)
  let (payload, i) := internTriples i payloadTerms
  let (del, i) := internTriples i deleteTerms
  let (ins, i) := internTriples i insertTerms
  let (fixedNodes, i) := i.internAll files.fixed
  let req ← match method with
    | "GET" => pure (HReq.get x)
    | "HEAD" => pure (HReq.head x)
    | "POST" => pure (HReq.post x payload)
    | "PUT" => pure (HReq.put x payload)
    | "PATCH" => pure (HReq.patch x del ins)
    | "DELETE" => pure (HReq.delete x)
    | m => return .error s!"cannot read method: {m}"
  -- the constants are computed for the request's document: a root is its own URI parent
  let hs : HSite := {
    parent := fun d => if d == x then parent else d
    isRoot := fun d => d == x && parentIri target == target
    slashed := fun d => d != x || target.endsWith "/"
    doubleSlash := fun d => d == x && doubleSlash target
    fixed := fun d => fixedNodes.contains d }
  return .ok ⟨hs, agent, pc, req, i⟩

/-- The status, then the document's graph, as N-Triples. -/
def printAnswer (i : Interner) (status : Nat) (fs : FinStore) (x : Node) : IO Unit := do
  IO.println s!"{status}"
  let names : HashMap Node String := i.nodes.fold (fun m k n => m.insert n k) {}
  for t in graphOf fs x do
    IO.println s!"{render names t.s} {render names t.p} {render names t.o} ."

/-- The arguments that name a request and its body. -/
def parseRequestArg : List String → RequestFiles → Option (List String × RequestFiles)
  | "--payload" :: v :: rest, f => some (rest, { f with payload := some v })
  | "--delete" :: v :: rest, f => some (rest, { f with delete := some v })
  | "--insert" :: v :: rest, f => some (rest, { f with insert := some v })
  | "--fixed" :: v :: rest, f => some (rest, { f with fixed := v :: f.fixed })
  | _, _ => none

end LdhHttp
