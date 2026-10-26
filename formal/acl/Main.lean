/-
`ldh-acl`: the decision of `LdhAcl.Decide`, and the server's answer of `LdhAcl.Gate` (the decision, then the
graph store's answer of `LdhHttp.Answer`), over a live instance's datasets.

    ldh-acl --end-user END_USER.nq --admin ADMIN.nq --admin-base https://admin.example.org/ --probes PROBES.tsv
    ldh-acl --end-user END_USER.nq --admin ADMIN.nq --admin-base https://admin.example.org/ --request REQUEST.tsv
      [--payload PAYLOAD.nt | --delete DELETE.nt --insert INSERT.nt] [--fixed URI]...

The datasets are N-Quads dumps of the two stores. Each probe line is `AGENT<TAB>METHOD<TAB>DOCUMENT`, where
`AGENT` is a WebID or `-` for no agent and `METHOD` is `GET`, `HEAD`, `POST`, `PUT`, `PUT*` (a `PUT` with
`If-None-Match: *`), `PATCH` or `DELETE`. For every probe, one line comes back: `allow` or `deny`, then the probe.

A request is one line, `AGENT<TAB>METHOD<TAB>DOCUMENT<TAB>PRECONDITION`, with `METHOD` one of `GET`, `HEAD`, `POST`,
`PUT`, `PATCH` and `DELETE`, and `PRECONDITION` one of `none`, `current` (`If-Match` with the current entity tag),
`stale` (`If-Match` with another) and `absent` (`If-None-Match: *`). The body of a `POST` or `PUT` is the
`--payload` N-Triples; a `PATCH` is `DELETE { --delete } INSERT { --insert } WHERE {}`. `--fixed` names the
owner's and the secretary's WebID documents. The status comes back on the first line, then the document's graph
after the request, as N-Triples.

What this file adds to the proven model is unproven and small: the reading of authorizations, memberships and
subclass axioms out of the admin dataset (transcribed from `aclQuery` in `web.xml`). Reading the dumps and the
request is `LdhHttp.IO`'s.
-/
import LdhAcl
import LdhHttp.IO
import Std.Data.HashMap

open LdhHttp LdhAcl Std


/-! ## Vocabulary -/

namespace V
def rdfsSubClassOf := "http://www.w3.org/2000/01/rdf-schema#subClassOf"
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
end V

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
  request : Option RequestFiles := none

partial def parseArgs : List String → Args → Except String Args
  | [], a => .ok a
  | "--end-user" :: v :: rest, a => parseArgs rest { a with endUser := some v }
  | "--admin" :: v :: rest, a => parseArgs rest { a with admin := some v }
  | "--admin-base" :: v :: rest, a => parseArgs rest { a with adminBase := some v }
  | "--probes" :: v :: rest, a => parseArgs rest { a with probes := some v }
  | "--request" :: v :: rest, a => parseArgs rest { a with request := some { (a.request.getD { request := v }) with request := v } }
  | args@(arg :: _), a =>
    match parseRequestArg args (a.request.getD { request := "" }) with
    | some (rest, f) => parseArgs rest { a with request := some f }
    | none => .error s!"unknown argument: {arg}"

def usage : String :=
  "usage: ldh-acl --end-user END_USER.nq --admin ADMIN.nq --admin-base ADMIN_BASE_URI " ++
    "(--probes PROBES.tsv | --request REQUEST.tsv [--payload PAYLOAD.nt | --delete DELETE.nt --insert INSERT.nt] " ++
    "[--fixed URI]...)"

/-- The admin dataspace is the graphs under the admin base: aclQuery's FILTER, and the dataspace a URI belongs to. -/
def adminNodes (i : Interner) (adminBase : String) : HashMap Node Unit := Id.run do
  let mut m : HashMap Node Unit := {}
  for (k, n) in i.nodes.toList do
    if k.startsWith adminBase then m := m.insert n ()
  pure m

/-- One request, decided and answered: its status, then the document's graph after it. -/
def runRequest (files : RequestFiles) (endUserQuads adminQuads : Array Quad) (adminBase : String) : IO UInt32 := do
  let i : Interner := {}
  let (euTriples, i) := internQuads i endUserQuads
  let (adTriples, i) := internQuads i adminQuads
  let (fa, i) := readAdmin i adminQuads adminBase
  let r ← match ← loadRequest i files with
    | .ok r => pure r
    | .error e => IO.eprintln e; return 2
  let admins := adminNodes r.interner adminBase
  let fsite : FinSite := { r.hs with admin := fun d => admins.contains d }
  let fs : FinStore := toFinStore (euTriples ++ adTriples)
  let (status, fs') := serveB fsite fs fa r.agent r.pc r.req
  printAnswer r.interner status fs' r.req.target
  return 0

def main (argv : List String) : IO UInt32 := do
  let args ← match parseArgs argv {} with
    | .ok a => pure a
    | .error e => IO.eprintln e; IO.eprintln usage; return 2
  let (some endUserPath, some adminPath, some adminBase) := (args.endUser, args.admin, args.adminBase)
    | IO.eprintln usage; return 2
  let endUserQuads ← readQuads endUserPath
  let adminQuads ← readQuads adminPath
  if let some files := args.request then
    return ← runRequest files endUserQuads adminQuads adminBase
  let some probesPath := args.probes
    | IO.eprintln usage; return 2
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
  let admins := adminNodes i adminBase
  -- the decision reads the URI parent and the dataspace alone
  let fsite : FinSite := {
    parent := fun d => parents.getD d d, isRoot := fun _ => false, slashed := fun _ => true,
    doubleSlash := fun _ => false, fixed := fun _ => false, admin := fun d => admins.contains d }
  for (agent, method, target, line) in decoded do
    let verdict := if allowRequestB fsite fs fa agent method target then "allow" else "deny"
    IO.println s!"{verdict}\t{line}"
  return 0
