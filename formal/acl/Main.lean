/-
`ldh-acl`: the decision of `LdhAcl.Decide` over a live instance's datasets.

    ldh-acl --end-user END_USER.nq --admin ADMIN.nq --admin-base https://admin.example.org/ --probes PROBES.tsv

The datasets are N-Quads dumps of the two stores. Each probe line is `AGENT<TAB>METHOD<TAB>DOCUMENT`, where
`AGENT` is a WebID or `-` for no agent and `METHOD` is `GET`, `HEAD`, `POST`, `PUT`, `PUT*` (a `PUT` with
`If-None-Match: *`), `PATCH` or `DELETE`. For every probe, one line comes back: `allow` or `deny`, then the probe.

What this file adds to the proven decision is unproven and small: the N-Quads reader, the interning of IRIs as
nodes, the reading of authorizations, memberships and subclass axioms out of the admin dataset (transcribed from
`aclQuery` in `web.xml`), and the URI parent a `PUT` of a new document is decided on.
-/
import LdhAcl
import Std.Data.HashMap

open LdhAcl Std

instance : Hashable Node where
  hash
    | .rdfType => 1 | .aclOwner => 2 | .dctCreator => 3 | .siocHasParent => 4 | .siocHasContainer => 5
    | .nfoFileDataObject => 6 | .dhContainer => 7 | .dhItem => 8 | .defRoot => 9
    | .iri n => hash (n + 16)

/-! ## Terms and quads -/

inductive Term where
  | iri (s : String)
  | blank (s : String)
  | literal
  deriving Repr, BEq

structure Quad where
  s : Term
  p : Term
  o : Term
  g : Term

/-- The name a node is interned under: an IRI, or a blank node label, which cannot collide with an IRI. -/
def Term.key : Term → Option String
  | .iri s => some s
  | .blank s => some s
  | .literal => none

/-! ## N-Quads -/

/-- One term from the front of `s`; the rest after it. Literals keep nothing but their kind. -/
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
    some (.literal, after)
  | _ => none

def parseQuad (line : String) : Option Quad := do
  let (s, r) ← parseTerm line.toSubstring
  let (p, r) ← parseTerm r
  let (o, r) ← parseTerm r
  let (g, _) ← parseTerm r
  pure ⟨s, p, o, g⟩

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
def rdfsSubClassOf := "http://www.w3.org/2000/01/rdf-schema#subClassOf"
def aclOwner := "http://www.w3.org/ns/auth/acl#owner"
def aclAgent := "http://www.w3.org/ns/auth/acl#agent"
def aclAgentGroup := "http://www.w3.org/ns/auth/acl#agentGroup"
def aclAgentClass := "http://www.w3.org/ns/auth/acl#agentClass"
def aclMode := "http://www.w3.org/ns/auth/acl#mode"
def aclAccessTo := "http://www.w3.org/ns/auth/acl#accessTo"
def aclDefault := "http://www.w3.org/ns/auth/acl#default"
def aclAccessToClass := "http://www.w3.org/ns/auth/acl#accessToClass"
def aclRead := "http://www.w3.org/ns/auth/acl#Read"
def aclAppend := "http://www.w3.org/ns/auth/acl#Append"
def aclWrite := "http://www.w3.org/ns/auth/acl#Write"
def aclControl := "http://www.w3.org/ns/auth/acl#Control"
def aclAuthenticatedAgent := "http://www.w3.org/ns/auth/acl#AuthenticatedAgent"
def foafAgent := "http://xmlns.com/foaf/0.1/Agent"
def foafPrimaryTopic := "http://xmlns.com/foaf/0.1/primaryTopic"
def foafMember := "http://xmlns.com/foaf/0.1/member"
def laclOwnerAgent := "https://w3id.org/atomgraph/linkeddatahub/admin/acl#OwnerAgent"
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

/-- A quad whose three positions are nodes, as a triple under its graph name; a literal object drops the quad,
since the decision reads none. -/
def Quad.keys (q : Quad) : Option (String × String × String × String) := do
  let s ← q.s.key
  let p ← q.p.key
  let o ← q.o.key
  let g ← q.g.key
  pure (s, p, o, g)

def internQuads (i : Interner) (quads : Array Quad) : Array (Node × Triple) × Interner := Id.run do
  let mut i := i
  let mut out := #[]
  for q in quads do
    if let some (s, p, o, g) := q.keys then
      let (ns, i1) := i.intern s
      let (np, i2) := i1.intern p
      let (no, i3) := i2.intern o
      let (ng, i4) := i3.intern g
      i := i4
      out := out.push (ng, ⟨ns, np, no⟩)
  pure (out, i)

/-- Groups interned quads by graph. -/
def toFinStore (quads : Array (Node × Triple)) : FinStore := Id.run do
  let mut m : HashMap Node (List Triple) := {}
  for (g, t) in quads do
    m := m.insert g (t :: m.getD g [])
  pure (m.toList)

/-! ## Reading the admin dataset: `aclQuery` -/

/-- The quads of one graph, by subject. -/
def bySubject (quads : Array Quad) (g : String) : HashMap String (List (String × Term)) := Id.run do
  let mut m : HashMap String (List (String × Term)) := {}
  for q in quads do
    if q.g.key == some g then
      if let some s := q.s.key then
        if let some p := q.p.key then
          m := m.insert s ((p, q.o) :: m.getD s [])
  pure m

def objects (props : List (String × Term)) (p : String) : List String :=
  props.filterMap fun (p', o) => if p' == p then o.key else none

def agentClassOf (s : String) : Option AgentClass :=
  if s == V.foafAgent then some .anyone
  else if s == V.aclAuthenticatedAgent then some .authenticated
  else if s == V.laclOwnerAgent then some .owner
  else none

def modeOf (s : String) : Option Mode :=
  if s == V.aclRead then some .read
  else if s == V.aclAppend then some .append
  else if s == V.aclWrite then some .write
  else if s == V.aclControl then some .control
  else none

/-- What `aclQuery` reads of the admin dataset, restricted to the graphs under the admin base as its `FILTER`s
are: for each graph `g`, the authorizations and the groups that are `g foaf:primaryTopic ?topic`, described in `g`
itself; and `rdfs:subClassOf` from every graph, as the path over `urn:x-arq:UnionGraph` is. -/
def readAdmin (i : Interner) (quads : Array Quad) (adminBase : String) : FinAdmin × Interner := Id.run do
  let mut i := i
  let mut auths : List (Node × Auth) := []
  let mut members : List (Node × Node × Node) := []
  let mut sub : List (Node × Node) := []
  let graphs := (quads.filterMap (·.g.key)).toList.eraseDups
  for g in graphs do
    if !g.startsWith adminBase then continue
    let subjects := bySubject quads g
    let (ng, i1) := i.intern g
    i := i1
    for topic in objects (subjects.getD g []) V.foafPrimaryTopic do
      let props := subjects.getD topic []
      -- an authorization: anything the ACL query can match, so a topic with any of its properties
      let modes := (objects props V.aclMode).filterMap modeOf
      let classes := (objects props V.aclAgentClass).filterMap agentClassOf
      let (agents, i2) := i.internAll (objects props V.aclAgent)
      let (groups, i3) := i2.internAll (objects props V.aclAgentGroup)
      let (accessTo, i4) := i3.internAll (objects props V.aclAccessTo)
      let (default, i5) := i4.internAll (objects props V.aclDefault)
      let (accessToClass, i6) := i5.internAll (objects props V.aclAccessToClass)
      i := i6
      if !(modes.isEmpty && agents.isEmpty && groups.isEmpty && classes.isEmpty && accessTo.isEmpty &&
          default.isEmpty && accessToClass.isEmpty) then
        auths := (ng, ⟨agents, groups, classes, modes, accessTo, default, accessToClass⟩) :: auths
      -- a group: its members
      let (ngrp, i7) := i.intern topic
      let (ms, i8) := i7.internAll (objects props V.foafMember)
      i := i8
      for m in ms do
        members := (ng, ngrp, m) :: members
  for q in quads do
    if q.p.key == some V.rdfsSubClassOf then
      if let some s := q.s.key then
        if let some o := q.o.key then
          let (ns, i1) := i.intern s
          let (no, i2) := i1.intern o
          i := i2
          sub := (ns, no) :: sub
  pure (⟨auths, members, sub⟩, i)

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

/-! ## Probes -/

structure Probe where
  agent : Option String
  method : Method
  target : String
  line : String

def parseMethod : String → Option Method
  | "GET" => some .get
  | "HEAD" => some .head
  | "POST" => some .post
  | "PUT" => some .put
  | "PUT*" => some .putCreate
  | "PATCH" => some .patch
  | "DELETE" => some .delete
  | _ => none

def parseProbe (line : String) : Option Probe :=
  match line.splitOn "\t" with
  | [agent, method, target] => do
    let m ← parseMethod method
    pure ⟨if agent == "-" then none else some agent, m, target, line⟩
  | _ => none

/-! ## Main -/

structure Args where
  endUser : Option String := none
  admin : Option String := none
  adminBase : Option String := none
  probes : Option String := none

def parseArgs : List String → Args → Except String Args
  | [], a => .ok a
  | "--end-user" :: v :: rest, a => parseArgs rest { a with endUser := some v }
  | "--admin" :: v :: rest, a => parseArgs rest { a with admin := some v }
  | "--admin-base" :: v :: rest, a => parseArgs rest { a with adminBase := some v }
  | "--probes" :: v :: rest, a => parseArgs rest { a with probes := some v }
  | arg :: _, _ => .error s!"unknown argument: {arg}"

def usage : String :=
  "usage: ldh-acl --end-user END_USER.nq --admin ADMIN.nq --admin-base ADMIN_BASE_URI --probes PROBES.tsv"

def main (argv : List String) : IO UInt32 := do
  let args ← match parseArgs argv {} with
    | .ok a => pure a
    | .error e => IO.eprintln e; IO.eprintln usage; return 2
  let (some endUserPath, some adminPath, some adminBase, some probesPath) :=
      (args.endUser, args.admin, args.adminBase, args.probes)
    | IO.eprintln usage; return 2
  let endUserQuads ← readQuads endUserPath
  let adminQuads ← readQuads adminPath
  let probeLines ← IO.FS.lines probesPath
  let mut probes : Array Probe := #[]
  for line in probeLines do
    if line.trim.isEmpty then continue
    match parseProbe line with
    | some p => probes := probes.push p
    | none => IO.eprintln s!"cannot read probe: {line}"; return 2
  -- intern: both stores, the admin dataset's authorizations, then every probe's nodes and the target's parent
  let i : Interner := {}
  let (euTriples, i) := internQuads i endUserQuads
  let (adTriples, i) := internQuads i adminQuads
  let (fa, i) := readAdmin i adminQuads adminBase
  let mut i := i
  let mut parents : HashMap Node Node := {}
  let mut decoded : Array (Option Node × Method × Node × String) := #[]
  for p in probes do
    let (target, i1) := i.intern p.target
    let (parent, i2) := i1.intern (parentIri p.target)
    let (agent, i3) := match p.agent with
      | some a => let (n, i3) := i2.intern a; (some n, i3)
      | none => (none, i2)
    i := i3
    parents := parents.insert target parent
    decoded := decoded.push (agent, p.method, target, p.line)
  let fs : FinStore := toFinStore (euTriples ++ adTriples)
  -- the admin dataspace is the graphs under the admin base: aclQuery's FILTER, and the dataspace a URI belongs to
  let adminNodes : HashMap Node Unit := Id.run do
    let mut m : HashMap Node Unit := {}
    for (k, n) in i.nodes.toList do
      if k.startsWith adminBase then m := m.insert n ()
    pure m
  let fsite : FinSite := { parent := fun d => parents.getD d d, admin := fun d => adminNodes.contains d }
  for (agent, method, target, line) in decoded do
    let verdict := if allowRequestB fsite fs fa agent method target then "allow" else "deny"
    IO.println s!"{verdict}\t{line}"
  return 0
