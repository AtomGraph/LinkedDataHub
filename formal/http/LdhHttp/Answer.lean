/-
The graph store's answer to a request, as a program over finite data: the status, and the store after it.

Everything `DocumentHierarchyGraphStoreImpl` does with a request, in the order it checks it: the methods a document
allows, the URI checks, the write and type rules, the preconditions, existence, the parent and the children. Who is
asking is no part of it, beyond the agent a new document is owned by: the authorization decision comes before all of
it, and lives in the ACL model. A refused request changes nothing (`respond_refused`), no check here answers `403`
(`answer_not_forbidden`), and a request that goes through is a `Write` (`answer_write`), so the graph store keeps
every invariant a `Write` does (`answer_inv`).

The payload is ground: no blank nodes, which the server skolemizes, and no `dct:created` or `dct:modified`, which it
replaces. Constraint validation (SPIN and SHACL, `422`), parsing (`400`, `415`) and content negotiation are not
modelled: the replay sends only valid, parseable payloads that satisfy the ontology's constraints.
-/
import LdhHttp.Fin

namespace LdhHttp

/-! ## Requests and responses -/

/-- The precondition a request carries. -/
inductive Precond where
  /-- Neither `If-Match` nor `If-None-Match`. -/
  | none
  /-- `If-Match` with the document's current entity tag. -/
  | current
  /-- `If-Match` with any other entity tag. -/
  | stale
  /-- `If-None-Match: *`: create, only if there is nothing. -/
  | absent
  deriving DecidableEq, Repr

/-- A graph store request. A `PATCH` is `DELETE { delete } INSERT { insert } WHERE {}` over ground triples. -/
inductive HReq where
  | get (x : Node)
  | head (x : Node)
  | post (x : Node) (payload : List Triple)
  | put (x : Node) (payload : List Triple)
  | patch (x : Node) (delete insert : List Triple)
  | delete (x : Node)

def HReq.target : HReq → Node
  | .get x | .head x | .post x _ | .put x _ | .patch x _ _ | .delete x => x

/-- The method the decision is asked about: `getAccessMode` requires acl:Append of a `PUT` with `If-None-Match: *`. -/
def HReq.method (pc : Precond) : HReq → Method
  | .get _ => .get
  | .head _ => .head
  | .post .. => .post
  | .put .. => if pc = .absent then .putCreate else .put
  | .patch .. => .patch
  | .delete _ => .delete

/-- The statuses of a request that goes through. -/
inductive Success where
  | ok | created | noContent
  deriving DecidableEq, Repr

/-- The statuses of a request that does not. -/
inductive Refusal where
  | permanentRedirect | badRequest | forbidden | notFound | methodNotAllowed | conflict
  | preconditionFailed | unprocessable | preconditionRequired
  deriving DecidableEq, Repr

def Success.code : Success → Nat
  | .ok => 200 | .created => 201 | .noContent => 204

def Refusal.code : Refusal → Nat
  | .permanentRedirect => 308 | .badRequest => 400 | .forbidden => 403 | .notFound => 404
  | .methodNotAllowed => 405 | .conflict => 409 | .preconditionFailed => 412 | .unprocessable => 422
  | .preconditionRequired => 428

/-- The deployment constants the graph store reads. -/
structure HSite where
  /-- The URI parent `put()` resolves. -/
  parent : Node → Node
  isRoot : Node → Bool
  /-- The URI ends with a slash; `put()` redirects one that does not. -/
  slashed : Node → Bool
  /-- The URI's path has a double slash, which `put()` refuses. -/
  doubleSlash : Node → Bool
  /-- The owner's or the secretary's WebID document, which can be neither replaced nor deleted. -/
  fixed : Node → Bool

def HSite.agrees (hs : HSite) (tr : Tree) : Prop :=
  (∀ d, tr.parent d = hs.parent d) ∧ ∀ d, hs.isRoot d = true ↔ tr.isRoot d

/-! ## The rules, computed -/

def ownershipB (x : Node) (t : Triple) : Bool := t.s == x && (t.p == .aclOwner || t.p == .dctCreator)

def containmentB (x : Node) (t : Triple) : Bool := t.s == x && (t.p == .siocHasParent || t.p == .siocHasContainer)

def isContainmentB (t : Triple) : Bool := t.p == .siocHasParent || t.p == .siocHasContainer

def hierClassB (c : Node) : Bool := c == .defRoot || c == .dhContainer || c == .dhItem

/-- What a write keeps of a payload: `removeOwnership` and `removeContainment` strip the rest. -/
def keepB (x : Node) (t : Triple) : Bool := !ownershipB x t && !containmentB x t

/-- `checkForeignContainment` refuses the payload. -/
def foreignContainmentB (x : Node) (ts : List Triple) : Bool := ts.any fun t => isContainmentB t && t.s != x

/-- `checkDocumentTypes` refuses the payload. -/
def foreignTypeB (x : Node) (ts : List Triple) : Bool :=
  ts.any fun t => t.s == x && t.p == .rdfType && !hierClassB t.o

/-- `isHierarchyTyped`. -/
def typedB (x : Node) (ts : List Triple) : Bool := ts.any fun t => t.s == x && t.p == .rdfType && hierClassB t.o

/-- `childQuery`: a document whose own graph points its containment at `x`. -/
def hasChildB (fs : FinStore) (x : Node) : Bool :=
  fs.any fun p => p.1 != x && p.2.any fun t => t.s == p.1 && isContainmentB t && t.o == x

theorem ownershipB_iff {x : Node} {t : Triple} : ownershipB x t = true ↔ ownership x t := by
  simp [ownershipB, ownership]

theorem containmentB_iff {x : Node} {t : Triple} : containmentB x t = true ↔ containment x t := by
  simp [containmentB, containment]

theorem isContainmentB_iff {t : Triple} : isContainmentB t = true ↔ isContainment t := by
  simp [isContainmentB, isContainment]

theorem hierClassB_iff {c : Node} : hierClassB c = true ↔ hierClass c := by
  simp [hierClassB, hierClass, or_assoc]

theorem keepB_iff {x : Node} {t : Triple} : keepB x t = true ↔ ¬ ownership x t ∧ ¬ containment x t := by
  simp [keepB, ← ownershipB_iff, ← containmentB_iff]

theorem ff {b : Bool} (h : ¬ b = true) : b = false := by cases b <;> simp_all

theorem any_false {α : Type} {l : List α} {p : α → Bool} (h : l.any p = false) {t : α} (ht : t ∈ l) :
    p t = false := by
  cases hp : p t
  · rfl
  · have := List.any_eq_true.2 ⟨t, ht, hp⟩; rw [h] at this; cases this

theorem noForeign_of {x : Node} {ts : List Triple} (h : foreignContainmentB x ts = false) :
    NoForeign x fun t => t ∈ ts := by
  intro t ht hc
  have := any_false h ht
  simp only [Bool.and_eq_false_iff, bne_eq_false_iff_eq] at this
  rcases this with h1 | h1
  · rw [isContainmentB_iff.2 hc] at h1; cases h1
  · exact h1

theorem hierTypes_of {x : Node} {ts : List Triple} (h : foreignTypeB x ts = false) : HierTypes x fun t => t ∈ ts := by
  intro c hc
  have := any_false h hc
  simp only [beq_self_eq_true, Bool.true_and, Bool.not_eq_false', Bool.and_eq_false_iff] at this
  exact hierClassB_iff.1 (by simpa using this)

theorem typedBy_of {x : Node} {ts : List Triple} (h : typedB x ts = true) : TypedBy x fun t => t ∈ ts := by
  obtain ⟨⟨s, p, o⟩, ht, h⟩ := List.any_eq_true.1 h
  simp only [Bool.and_eq_true, beq_iff_eq] at h
  obtain ⟨⟨rfl, rfl⟩, hh⟩ := h
  exact ⟨o, ht, hierClassB_iff.1 hh⟩

theorem hasChild_of {fs : FinStore} {x : Node} (h : hasChildB fs x = false) : ¬ hasChild fs.toStore x := by
  rintro ⟨k, g, hk, hg, hc⟩
  have hh : hasDoc fs k = true := present_iff.1 ⟨g, hg⟩
  rw [toStore_of_hasDoc hh] at hg; cases hg
  have hc' : ∃ q, ⟨k, q, x⟩ ∈ graphOf fs k ∧ isContainment ⟨k, q, x⟩ := by
    rcases hc with hc | hc
    · exact ⟨_, hc, Or.inl rfl⟩
    · exact ⟨_, hc, Or.inr rfl⟩
  obtain ⟨q, hm, hq⟩ := hc'
  obtain ⟨ts, hp, ht⟩ := mem_graphOf.1 hm
  have h1 := any_false h hp
  rw [show (k != x) = true from bne_iff_ne.2 hk, Bool.true_and] at h1
  have h2 := any_false h1 ht
  simp [isContainmentB_iff.2 hq] at h2

/-! ## The graph store -/

/-- `evaluatePreconditions` on a document the store has: a write quotes its current entity tag, or is refused. -/
def precondFails : Precond → Option Refusal
  | .none => some .preconditionRequired
  | .current => none
  | .stale | .absent => some .preconditionFailed

/-- `GET` and `HEAD`. -/
def readB (fs : FinStore) (x : Node) : Except Refusal (Success × FinStore) :=
  if hasDoc fs x then .ok (.ok, fs) else .error .notFound

/-- `post()`. Appending nothing is a no-op that needs no precondition. -/
def postB (fs : FinStore) (x : Node) (payload : List Triple) (pc : Precond) : Except Refusal (Success × FinStore) :=
  if payload.isEmpty then .ok (.noContent, fs)
  else if foreignContainmentB x payload then .error .unprocessable
  else if foreignTypeB x payload then .error .unprocessable
  else if !hasDoc fs x then .error .notFound
  else match precondFails pc with
    | some r => .error r
    | none => .ok (.noContent, fs.set x (graphOf fs x ++ payload.filter (keepB x)))

/-- The containment `put()` asserts: `sioc:has_parent` of a container, `sioc:has_container` of anything else. -/
def containedB (hs : HSite) (x : Node) (payload : List Triple) : List Triple :=
  if hs.isRoot x then []
  else if decide (⟨x, .rdfType, .dhContainer⟩ ∈ payload) then [⟨x, .siocHasParent, hs.parent x⟩]
  else [⟨x, .siocHasContainer, hs.parent x⟩]

/-- The `dh:Item` `put()` types a document with that is neither the root nor a container. -/
def itemB (hs : HSite) (x : Node) (payload : List Triple) : List Triple :=
  if hs.isRoot x || decide (⟨x, .rdfType, .dhContainer⟩ ∈ payload) then [] else [⟨x, .rdfType, .dhItem⟩]

/-- The graph `put()` writes, with `keep` the ownership: the stored one, or the agent's for a new document. -/
def putGraph (hs : HSite) (x : Node) (payload keep : List Triple) : List Triple :=
  payload.filter (keepB x) ++ (containedB hs x payload ++ (keep ++ itemB hs x payload))

def ownedBy (x : Node) : Option Node → List Triple
  | some a => [⟨x, .aclOwner, a⟩, ⟨x, .dctCreator, a⟩]
  | none => []

/-- `put()`. -/
def putB (hs : HSite) (fs : FinStore) (agent : Option Node) (x : Node) (payload : List Triple) (pc : Precond) :
    Except Refusal (Success × FinStore) :=
  if hs.fixed x then .error .methodNotAllowed
  else if !hs.slashed x then .error .permanentRedirect
  else if hs.doubleSlash x then .error .badRequest
  else if foreignContainmentB x payload then .error .unprocessable
  else if foreignTypeB x payload then .error .unprocessable
  else if hs.isRoot x && !typedB x payload then .error .unprocessable
  else if hasDoc fs x then
    match precondFails pc with
    | some r => .error r
    | none => .ok (.noContent, fs.set x (putGraph hs x payload ((graphOf fs x).filter (ownershipB x))))
  -- If-Match is false when there is no current representation
  else if pc = .current ∨ pc = .stale then .error .preconditionFailed
  else if !hs.isRoot x && !hasDoc fs (hs.parent x) then .error .conflict
  else .ok (.created, fs.set x (putGraph hs x payload (ownedBy x agent)))

/-- `delete()` once its preconditions hold, as a `PATCH` that empties the graph reaches it. -/
def deleteChecked (fs : FinStore) (x : Node) : Except Refusal (Success × FinStore) :=
  if hasChildB fs x then .error .conflict
  else if !hasDoc fs x then .error .notFound
  else .ok (.noContent, fs.erase x)

/-- `delete()`. The preconditions are evaluated only on a document the store has. -/
def deleteB (hs : HSite) (fs : FinStore) (x : Node) (pc : Precond) : Except Refusal (Success × FinStore) :=
  if hs.isRoot x || hs.fixed x then .error .methodNotAllowed
  else if hasDoc fs x then
    match precondFails pc with
    | some r => .error r
    | none => deleteChecked fs x
  else deleteChecked fs x

/-- `rdf:type cannot be removed`: a resource the update leaves described but untyped. -/
def untypesB (g after : List Triple) : Bool :=
  g.any fun t => t.p == .rdfType && !(after.any fun u => u.s == t.s && u.p == .rdfType) && after.any fun u => u.s == t.s

/-- `patch()`. -/
def patchB (hs : HSite) (fs : FinStore) (x : Node) (del ins : List Triple) (pc : Precond) :
    Except Refusal (Success × FinStore) :=
  if !hasDoc fs x then .error .notFound
  else match precondFails pc with
    | some r => .error r
    | none =>
      let g := graphOf fs x
      let after := g.filter (fun t => !decide (t ∈ del)) ++ ins
      if after.isEmpty then
        if hs.isRoot x || hs.fixed x then .error .unprocessable else deleteChecked fs x
      else if (g ++ ins).any (fun t => (ownershipB x t || containmentB x t) && decide (t ∈ g) != decide (t ∈ after))
        then .error .unprocessable
      else if after.any (fun t => isContainmentB t && t.s != x && !decide (t ∈ g)) then .error .unprocessable
      else if after.any (fun t => t.s == x && t.p == .rdfType && !hierClassB t.o && !decide (t ∈ g))
        then .error .unprocessable
      else if !typedB x after then .error .unprocessable
      else if untypesB g after then .error .unprocessable
      else .ok (.noContent, fs.set x after)

/-- What the graph store does with a request: everything after the authorization decision. -/
def answerB (hs : HSite) (fs : FinStore) (agent : Option Node) (pc : Precond) :
    HReq → Except Refusal (Success × FinStore)
  | .get x => readB fs x
  | .head x => readB fs x
  | .post x payload => postB fs x payload pc
  | .put x payload => putB hs fs agent x payload pc
  | .patch x del ins => patchB hs fs x del ins pc
  | .delete x => deleteB hs fs x pc

/-- The status and the store after the request. -/
def respondB (hs : HSite) (fs : FinStore) (agent : Option Node) (pc : Precond) (req : HReq) : Nat × FinStore :=
  match answerB hs fs agent pc req with
  | .ok (s, fs') => (s.code, fs')
  | .error r => (r.code, fs)

/-! ## What the answer guarantees -/

/-- **A refused request changes nothing.** -/
theorem respond_refused {hs fs agent pc req r} (h : answerB hs fs agent pc req = .error r) :
    respondB hs fs agent pc req = (r.code, fs) := by
  simp [respondB, h]

theorem deleteChecked_not_forbidden {fs x} : deleteChecked fs x ≠ .error .forbidden := by
  unfold deleteChecked
  split
  · simp
  · split <;> simp

theorem precondFails_ne {pc : Precond} : precondFails pc ≠ some .forbidden := by
  cases pc <;> simp [precondFails]

/-- **No check of the graph store answers `403`:** that status is the authorization decision's. -/
theorem answer_not_forbidden {hs fs agent pc req} : answerB hs fs agent pc req ≠ .error .forbidden := by
  intro hd
  cases req with
  | get | head => simp only [answerB, readB] at hd; split at hd <;> cases hd
  | post =>
    simp only [answerB, postB] at hd
    repeat' (first | exact precondFails_ne ‹_› | split at hd | cases hd)
  | put =>
    simp only [answerB, putB] at hd
    repeat' (first | exact precondFails_ne ‹_› | split at hd | cases hd)
  | patch =>
    simp only [answerB, patchB] at hd
    repeat' (first | exact deleteChecked_not_forbidden hd | exact precondFails_ne ‹_› | split at hd | cases hd)
  | delete =>
    simp only [answerB, deleteB] at hd
    repeat' (first | exact deleteChecked_not_forbidden hd | exact precondFails_ne ‹_› | split at hd | cases hd)

/-! ## What goes through is a `Write` -/

theorem toStore_hasDoc {fs : FinStore} {x : Node} (h : hasDoc fs x = true) :
    fs.toStore x = some fun t => t ∈ graphOf fs x := toStore_of_hasDoc h

theorem toStore_not_hasDoc {fs : FinStore} {x : Node} (h : hasDoc fs x = false) : fs.toStore x = none :=
  toStore_of_not_hasDoc (by simp [h])

theorem mem_containedB {tr : Tree} {hs : HSite} (h : hs.agrees tr) {x : Node} {payload : List Triple}
    {t : Triple} : t ∈ containedB hs x payload ↔ containedIn tr x (fun t => t ∈ payload) t := by
  unfold containedB containedIn
  rw [← h.2 x, h.1 x]
  by_cases hr : hs.isRoot x = true
  · simp [hr]
  · by_cases hc : (⟨x, .rdfType, .dhContainer⟩ : Triple) ∈ payload
    · simp [hr, hc]
    · simp [hr, hc]

theorem mem_itemB {tr : Tree} {hs : HSite} (h : hs.agrees tr) {x : Node} {payload : List Triple}
    {t : Triple} : t ∈ itemB hs x payload ↔ itemTyped tr x (fun t => t ∈ payload) t := by
  unfold itemB itemTyped
  rw [← h.2 x]
  by_cases hr : hs.isRoot x = true
  · simp [hr]
  · by_cases hc : (⟨x, .rdfType, .dhContainer⟩ : Triple) ∈ payload
    · simp [hr, hc]
    · simp [hr, hc]

theorem putGraph_existing {tr : Tree} {hs : HSite} (h : hs.agrees tr) {fs : FinStore} {x : Node}
    {payload : List Triple} :
    (fun t => t ∈ putGraph hs x payload ((graphOf fs x).filter (ownershipB x))) =
      fun t => ((t ∈ payload) ∧ ¬ ownership x t ∧ ¬ containment x t) ∨ containedIn tr x (fun t => t ∈ payload) t ∨
        ((t ∈ graphOf fs x) ∧ ownership x t) ∨ itemTyped tr x (fun t => t ∈ payload) t := by
  funext t
  simp only [putGraph, List.mem_append, List.mem_filter, keepB_iff, ownershipB_iff, mem_containedB h, mem_itemB h]

theorem mem_ownedBy {x : Node} {agent : Option Node} {t : Triple} :
    t ∈ ownedBy x agent ↔ ∃ a, agent = some a ∧ t.s = x ∧ (t.p = .aclOwner ∨ t.p = .dctCreator) ∧ t.o = a := by
  cases agent with
  | none => simp [ownedBy]
  | some a =>
    obtain ⟨s, p, o⟩ := t
    simp only [ownedBy, List.mem_cons, List.mem_singleton, Triple.mk.injEq, List.not_mem_nil, or_false,
      Option.some.injEq, exists_eq_left']
    constructor
    · rintro (⟨rfl, rfl, rfl⟩ | ⟨rfl, rfl, rfl⟩)
      · exact ⟨rfl, Or.inl rfl, rfl⟩
      · exact ⟨rfl, Or.inr rfl, rfl⟩
    · rintro ⟨rfl, hp | hp, rfl⟩ <;> subst hp
      · exact Or.inl ⟨rfl, rfl, rfl⟩
      · exact Or.inr ⟨rfl, rfl, rfl⟩

theorem putGraph_new {tr : Tree} {hs : HSite} (h : hs.agrees tr) {x : Node} {payload : List Triple}
    {agent : Option Node} :
    (fun t => t ∈ putGraph hs x payload (ownedBy x agent)) =
      fun t => ((t ∈ payload) ∧ ¬ ownership x t ∧ ¬ containment x t) ∨ containedIn tr x (fun t => t ∈ payload) t ∨
        (∃ a, agent = some a ∧ t.s = x ∧ (t.p = .aclOwner ∨ t.p = .dctCreator) ∧ t.o = a) ∨
        itemTyped tr x (fun t => t ∈ payload) t := by
  funext t
  simp only [putGraph, List.mem_append, List.mem_filter, keepB_iff, mem_ownedBy, mem_containedB h, mem_itemB h]

theorem deleteChecked_write {tr : Tree} {hs : HSite} (h : hs.agrees tr) {fs : FinStore} {agent : Option Node}
    {x : Node} {s : Success} {fs' : FinStore} (hr : hs.isRoot x = false) (hd : deleteChecked fs x = .ok (s, fs')) :
    Write tr agent fs.toStore (.delete x) fs'.toStore := by
  unfold deleteChecked at hd
  split at hd
  · cases hd
  · rename_i hc
    split at hd
    · cases hd
    · cases hd
      rw [toStore_erase]
      refine Write.delete (fun hroot => ?_) (hasChild_of (by simpa using hc))
      rw [← h.2 x, hr] at hroot; cases hroot

/-- The write a request is carried out as: on its document, by its method, or by `DELETE` for a `PATCH` that
empties the graph, which `patch()` hands to `delete()`. -/
def HReq.writes (req : HReq) (pc : Precond) (r : Req) : Prop :=
  r.target = req.target ∧ (r.method = req.method pc ∨ (req.method pc = .patch ∧ r.method = .delete))

/-- **A request that goes through is a write of the model, or changes nothing.** For a store whose containment
sits in its subjects' own graphs, as `Inv` has it, every answer with a success status is a `Write` of the request
from the store before it to the store after it, or leaves the store as it was. -/
theorem answer_write {tr : Tree} {hs : HSite} (h : hs.agrees tr) {fs : FinStore} {agent : Option Node}
    {pc : Precond} {req : HReq} {s : Success} {fs' : FinStore}
    (hown : OwnGraphContainment fs.toStore) (hd : answerB hs fs agent pc req = .ok (s, fs')) :
    fs' = fs ∨ ∃ r, req.writes pc r ∧ Write tr agent fs.toStore r fs'.toStore := by
  cases req with
  | get x | head x =>
    simp only [answerB, readB] at hd; split at hd
    · cases hd; exact Or.inl rfl
    · cases hd
  | post x payload =>
    simp only [answerB, postB] at hd
    split at hd
    · cases hd; exact Or.inl rfl
    split at hd; · cases hd
    rename_i hfc
    split at hd; · cases hd
    rename_i hft
    split at hd; · cases hd
    rename_i hx
    have hx : hasDoc fs x = true := by simpa using hx
    split at hd; · cases hd
    cases hd
    refine Or.inr ⟨.post x fun t => t ∈ payload, ⟨rfl, Or.inl rfl⟩, ?_⟩
    have hG : (fun t => t ∈ graphOf fs x ++ payload.filter (keepB x)) =
        fun t => t ∈ graphOf fs x ∨ (t ∈ payload ∧ ¬ ownership x t ∧ ¬ containment x t) := by
      funext t; simp only [List.mem_append, List.mem_filter, keepB_iff]
    rw [toStore_set, hG]
    exact Write.post (toStore_hasDoc hx) (noForeign_of (by simpa using hfc)) (hierTypes_of (by simpa using hft))
  | put x payload =>
    simp only [answerB, putB] at hd
    split at hd; · cases hd
    split at hd; · cases hd
    split at hd; · cases hd
    split at hd; · cases hd
    rename_i hfc
    split at hd; · cases hd
    rename_i hft
    split at hd; · cases hd
    rename_i hroot
    have hnf := noForeign_of (x := x) (ts := payload) (by simpa using hfc)
    have hty := hierTypes_of (x := x) (ts := payload) (by simpa using hft)
    have hrt : tr.isRoot x → TypedBy x fun t => t ∈ payload := by
      intro hr
      have hr' := (h.2 x).2 hr
      simp only [hr', Bool.true_and, Bool.not_eq_true'] at hroot
      exact typedBy_of (by simpa using hroot)
    split at hd
    · rename_i hx
      split at hd; · cases hd
      rename_i hpc
      cases hd
      have hcf : pc ≠ .absent := by rintro rfl; simp [precondFails] at hpc
      refine Or.inr ⟨.put x (fun t => t ∈ payload) false, ⟨rfl, Or.inl (by simp [HReq.method, hcf, Req.method])⟩, ?_⟩
      rw [toStore_set, putGraph_existing h]
      exact Write.putExisting (toStore_hasDoc hx) rfl hnf hty hrt
    · rename_i hx
      split at hd; · cases hd
      split at hd; · cases hd
      rename_i hpar
      cases hd
      refine Or.inr ⟨.put x (fun t => t ∈ payload) (decide (pc = .absent)), ⟨rfl, Or.inl ?_⟩, ?_⟩
      · by_cases hcf : pc = .absent <;> simp [HReq.method, hcf, Req.method]
      rw [toStore_set, putGraph_new h]
      refine Write.putNew (toStore_not_hasDoc (by simpa using hx)) hnf hty hrt fun hr => ?_
      have hr' : hs.isRoot x = false := by
        cases hb : hs.isRoot x
        · rfl
        · exact absurd ((h.2 x).1 hb) hr
      rw [h.1 x]
      exact present_iff.2 (by simpa [hr'] using hpar)
  | patch x del ins =>
    simp only [answerB, patchB] at hd
    split at hd; · cases hd
    rename_i hx
    have hx : hasDoc fs x = true := by simpa using hx
    split at hd; · cases hd
    split at hd
    · split at hd; · cases hd
      rename_i hr
      have hr : hs.isRoot x = false := by simp at hr; exact hr.1
      exact Or.inr ⟨_, ⟨rfl, Or.inr ⟨rfl, rfl⟩⟩, deleteChecked_write h hr hd⟩
    split at hd; · cases hd
    rename_i hoc
    split at hd; · cases hd
    rename_i hfc
    split at hd; · cases hd
    rename_i hft
    split at hd; · cases hd
    rename_i hty
    split at hd; · cases hd
    cases hd
    refine Or.inr ⟨Req.patch x fun t => t ∈ (graphOf fs x).filter (fun t => !decide (t ∈ del)) ++ ins,
      ⟨rfl, Or.inl rfl⟩, ?_⟩
    rw [toStore_set]
    refine Write.patch (toStore_hasDoc hx) ?_ ?_ ?_ (typedBy_of (by simpa using hty))
    · -- the containment the update adds is about x, and what it keeps was, by `hown`
      intro t ht hc
      by_cases hg : t ∈ graphOf fs x
      · exact hown x _ t (toStore_hasDoc hx) hg hc
      · have := any_false (ff hfc) ht
        simp [isContainmentB_iff.2 hc, hg] at this
        exact this
    · intro t ho
      have hm : t ∈ graphOf fs x ++ ins ∨ ¬ (t ∈ graphOf fs x ++ ins) := Classical.em _
      rcases hm with hm | hm
      · have := any_false (ff hoc) hm
        have hoc' : (ownershipB x t || containmentB x t) = true := by
          rcases ho with ho | ho
          · simp [ownershipB_iff.2 ho]
          · simp [containmentB_iff.2 ho]
        simp only [hoc', Bool.true_and, bne_eq_false_iff_eq, decide_eq_decide] at this
        exact this.symm
      · simp only [List.mem_append, not_or] at hm
        simp [List.mem_append, List.mem_filter, hm.1, hm.2]
    · intro c hc
      by_cases hg : (⟨x, .rdfType, c⟩ : Triple) ∈ graphOf fs x
      · exact Or.inl hg
      · have := any_false (ff hft) hc
        simp only [beq_self_eq_true, Bool.true_and, hg, decide_false, Bool.not_false, Bool.and_true,
          Bool.not_eq_false'] at this
        exact Or.inr (hierClassB_iff.1 this)
  | delete x =>
    simp only [answerB, deleteB] at hd
    split at hd; · cases hd
    rename_i hr
    have hr' : hs.isRoot x = false := by simp at hr; exact hr.1
    split at hd
    · split at hd; · cases hd
      exact Or.inr ⟨_, ⟨rfl, Or.inl rfl⟩, deleteChecked_write h hr' hd⟩
    · exact Or.inr ⟨_, ⟨rfl, Or.inl rfl⟩, deleteChecked_write h hr' hd⟩

/-- **The graph store keeps the invariants.** Every answer leaves the containment invariants, and the typing of
documents, as it found them. -/
theorem answer_inv {tr : Tree} {hs : HSite} (h : hs.agrees tr) {fs : FinStore} {agent : Option Node}
    {pc : Precond} {req : HReq} {s : Success} {fs' : FinStore}
    (hinv : Inv tr fs.toStore) (hd : answerB hs fs agent pc req = .ok (s, fs')) :
    Inv tr fs'.toStore ∧ (Typed fs.toStore → Typed fs'.toStore) := by
  rcases answer_write h hinv.own hd with rfl | ⟨_, _, hw⟩
  · exact ⟨hinv, id⟩
  · exact ⟨hw.inv hinv, hw.typed⟩

end LdhHttp
