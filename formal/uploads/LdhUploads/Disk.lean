/-
The upload folder, and what the graph store's writes do to it.

A file is staged per request: written under a temporary name and digested, its resource renamed to the
content-addressed URI (`stageFiles`, DocumentHierarchyGraphStoreImpl). The staged files are committed only on the path
where the write goes ahead, as the step `post()` and `put()` run just before writing the graph, after every check
(`beforeWrite`); a write that is refused, or fails, discards them. Committing moves a file to the name of its
digest, unless that name is taken, in which case the bytes there stay (`commitFiles`). Nothing deletes a committed
file: deleting a document leaves the files it described.

The disk is a map from a digest to bytes. `respondU` is the graph store's answer (`LdhHttp.answerB`) with the files of
the request committed when it goes ahead.

* `refused_stores_nothing`: a refused write leaves the disk as it was.
* `disk_never_shrinks`: no request removes or replaces a stored file.
* `content_addressed`: every stored file is stored under its own digest, which no request changes.
* `first_writer_wins`: a file whose digest is taken is not stored; under a collision of the digest, the bytes of the
  first are what the second's URI serves. With SHA-1 taken collision-free on the bytes ever uploaded
  (`served_bytes_uploaded`), the bytes a URI serves are the bytes it was named for.

Beside the bytes the platform records, per digest, the media type a file was first uploaded with and the documents
it was uploaded into (`UploadRecords`, written by `commitFiles` for the request's target document):

* `type_first_writer`: a recorded media type is never changed.
* `recorded_by_uploaders`: a document is recorded for a digest only by a write to that document, which the graph
  store went ahead with, of a request that uploaded bytes with that digest.
-/
import LdhHttp.Answer

namespace LdhUploads

open LdhHttp

variable {Bytes : Type} (sha : Bytes → String)

abbrev Disk (Bytes : Type) := String → Option Bytes

/-- `commitFiles` for one staged file. -/
def commitOne (d : Disk Bytes) (b : Bytes) : Disk Bytes :=
  if (d (sha b)).isSome then d else fun k => if k = sha b then some b else d k

def commit (d : Disk Bytes) (staged : List Bytes) : Disk Bytes := staged.foldl (commitOne sha) d

/-- The status, the store and the disk after a request whose multipart body staged `staged`. -/
def respondU (hs : HSite) (fs : FinStore) (d : Disk Bytes) (agent : Option Node) (pc : Precond) (req : HReq)
    (staged : List Bytes) : Nat × FinStore × Disk Bytes :=
  match answerB hs fs agent pc req with
  | .ok (s, fs') => (s.code, fs', commit sha d staged)
  | .error r => (r.code, fs, d)

theorem refused_stores_nothing {hs fs d agent pc req staged r} (h : answerB hs fs agent pc req = .error r) :
    respondU sha hs fs d agent pc req staged = (r.code, fs, d) := by
  simp [respondU, h]

theorem commitOne_keeps {d : Disk Bytes} {b : Bytes} {k : String} {v : Bytes} (h : d k = some v) :
    commitOne sha d b k = some v := by
  unfold commitOne
  split
  · exact h
  · rename_i hn
    have : k ≠ sha b := by
      intro e; subst e; simp [h] at hn
    simp [this, h]

theorem commit_keeps (staged : List Bytes) : ∀ {d : Disk Bytes} {k : String} {v : Bytes}, d k = some v →
    commit sha d staged k = some v := by
  induction staged with
  | nil => intro d k v h; exact h
  | cons b bs ih => intro d k v h; exact ih (commitOne_keeps sha h)

theorem disk_never_shrinks {hs fs d agent pc req staged} {k : String} {v : Bytes} (h : d k = some v) :
    (respondU sha hs fs d agent pc req staged).2.2 k = some v := by
  unfold respondU
  split
  · exact commit_keeps sha staged h
  · exact h

/-- Every stored file is stored under its own digest. -/
def Addressed (d : Disk Bytes) : Prop := ∀ k b, d k = some b → sha b = k

theorem commitOne_addressed {d : Disk Bytes} (h : Addressed sha d) (b : Bytes) : Addressed sha (commitOne sha d b) := by
  intro k v hv
  unfold commitOne at hv
  split at hv
  · exact h k v hv
  · by_cases hk : k = sha b
    · subst hk; simp at hv; subst hv; rfl
    · simp [hk] at hv; exact h k v hv

theorem commit_addressed (staged : List Bytes) : ∀ {d : Disk Bytes}, Addressed sha d → Addressed sha (commit sha d staged) := by
  induction staged with
  | nil => intro d h; exact h
  | cons b bs ih => intro d h; exact ih (commitOne_addressed sha h b)

theorem content_addressed {hs fs d agent pc req staged} (h : Addressed sha d) :
    Addressed sha (respondU sha hs fs d agent pc req staged).2.2 := by
  unfold respondU
  split
  · exact commit_addressed sha staged h
  · exact h

/-- A staged file whose digest is taken leaves the stored bytes there. -/
theorem first_writer_wins {d : Disk Bytes} {b v : Bytes} (h : d (sha b) = some v) : commitOne sha d b = d := by
  simp [commitOne, h]

/-- With the digest collision-free on the bytes ever uploaded, a URI serves the bytes it is named for. -/
theorem served_bytes_uploaded {d : Disk Bytes} (h : Addressed sha d) (inj : ∀ a b, sha a = sha b → a = b)
    {b v : Bytes} (hv : d (sha b) = some v) : v = b :=
  inj v b (h (sha b) v hv)

/-! ### The records beside the bytes -/

structure Records where
  types : String → Option String
  documents : String → List Node

/-- `UploadRecords.record` for one committed file, uploaded with media type `t` into document `x`. -/
def recordOne (x : Node) (rs : Records) (staged : Bytes × String) : Records :=
  let k := sha staged.1
  { types := fun k' => if k' = k then (rs.types k).orElse fun _ => some staged.2 else rs.types k'
    documents := fun k' => if k' = k ∧ x ∉ rs.documents k then rs.documents k ++ [x] else rs.documents k' }

def record (x : Node) (rs : Records) (staged : List (Bytes × String)) : Records := staged.foldl (recordOne sha x) rs

/-- The records after a request that staged `staged`, files with the media types they were uploaded with. -/
def respondR (hs : HSite) (fs : FinStore) (rs : Records) (agent : Option Node) (pc : Precond) (req : HReq)
    (staged : List (Bytes × String)) : Records :=
  match answerB hs fs agent pc req with
  | .ok _ => record sha req.target rs staged
  | .error _ => rs

theorem recordOne_type {x : Node} {rs : Records} {st : Bytes × String} {k t : String} (h : rs.types k = some t) :
    (recordOne sha x rs st).types k = some t := by
  simp only [recordOne]
  split
  · rename_i e; subst e; rw [h]; rfl
  · exact h

theorem record_type (x : Node) (staged : List (Bytes × String)) :
    ∀ {rs : Records} {k t : String}, rs.types k = some t → (record sha x rs staged).types k = some t := by
  induction staged with
  | nil => intro rs k t h; exact h
  | cons st sts ih => intro rs k t h; exact ih (recordOne_type sha h)

theorem type_first_writer {hs fs rs agent pc req staged} {k t : String} (h : rs.types k = some t) :
    (respondR sha hs fs rs agent pc req staged).types k = some t := by
  unfold respondR
  split
  · exact record_type sha _ staged h
  · exact h

theorem recordOne_documents {x d : Node} {rs : Records} {st : Bytes × String} {k : String}
    (h : d ∈ (recordOne sha x rs st).documents k) : d ∈ rs.documents k ∨ (d = x ∧ sha st.1 = k) := by
  simp only [recordOne] at h
  split at h
  · rename_i hc
    rcases List.mem_append.mp h with h | h
    · exact Or.inl (hc.1 ▸ h)
    · simp at h; exact Or.inr ⟨h, hc.1.symm⟩
  · exact Or.inl h

theorem record_documents (x : Node) (staged : List (Bytes × String)) :
    ∀ {rs : Records} {d : Node} {k : String}, d ∈ (record sha x rs staged).documents k →
      d ∈ rs.documents k ∨ (d = x ∧ ∃ st ∈ staged, sha st.1 = k) := by
  induction staged with
  | nil => intro rs d k h; exact Or.inl h
  | cons st sts ih =>
    intro rs d k h
    rcases ih h with h | ⟨hx, st', hm, hk⟩
    · rcases recordOne_documents sha h with h | ⟨hx, hk⟩
      · exact Or.inl h
      · exact Or.inr ⟨hx, st, List.mem_cons_self st sts, hk⟩
    · exact Or.inr ⟨hx, st', List.mem_cons_of_mem st hm, hk⟩

/-- A document is recorded for a digest only by an accepted write to it that uploaded bytes with that digest. -/
theorem recorded_by_uploaders {hs fs rs agent pc req staged} {d : Node} {k : String}
    (h : d ∈ (respondR sha hs fs rs agent pc req staged).documents k) :
    d ∈ rs.documents k ∨
      ((∃ s fs', answerB hs fs agent pc req = .ok (s, fs')) ∧ d = req.target ∧ ∃ st ∈ staged, sha st.1 = k) := by
  unfold respondR at h
  split at h
  · rename_i s heq
    rcases record_documents sha _ staged h with h | ⟨hx, hst⟩
    · exact Or.inl h
    · exact Or.inr ⟨⟨s.1, s.2, heq⟩, hx, hst⟩
  · exact Or.inl h

end LdhUploads
