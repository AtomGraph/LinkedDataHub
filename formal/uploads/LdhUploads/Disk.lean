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

end LdhUploads
