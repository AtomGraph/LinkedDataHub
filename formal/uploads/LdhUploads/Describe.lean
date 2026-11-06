/-
What an upload is described by, and what decides who reads it.

`Item` reads the file's description with `DESCRIBE $this` (web.xml `fileQuery`), which Jena answers from every graph
of the dataset, so the description is the union of what each document states of the file's URI. The file's
document has no graph of its own: its URI is under `uploads/`, where no document is.

* `any_writer_describes_any_upload`: a write the graph store goes ahead with, to any document, can state anything of
  an upload but its containment, and the upload's description then holds it. The served media type is one of the
  `dct:format` values the description holds and the file's tag was one of its `foaf:sha1` values, so either was a
  pick among what any writer had stated (`LdhUploads.Serve`).
* `upload_context`: the authorization decision knows an upload by its own URI and the class `nfo:FileDataObject`,
  which any graph's statement gives it, and by nothing else - no document that describes it, so no document's
  authorizations decide who reads it.
-/
import LdhHttp.Answer

namespace LdhUploads

open LdhHttp

/-- `DESCRIBE <u>` over every graph. -/
def describe (fs : FinStore) (u : Node) : List Triple := (fs.flatMap (·.2)).filter (·.s == u)

theorem mem_describe_set {fs : FinStore} {x u : Node} {g : List Triple} {t : Triple} (ht : t ∈ g) (hs : t.s = u) :
    t ∈ describe (fs.set x g) u := by
  simp only [describe, FinStore.set, List.flatMap_cons, List.mem_filter, List.mem_append, beq_iff_eq]
  exact ⟨Or.inl ht, hs⟩

theorem keep_foreign {x : Node} {t : Triple} (h : t.s ≠ x) : keepB x t = true := by
  have : (t.s == x) = false := by simpa using h
  simp [keepB, ownershipB, containmentB, this]

theorem mem_putGraph {hs : HSite} {x : Node} {payload keep : List Triple} {t : Triple} (ht : t ∈ payload)
    (h : t.s ≠ x) : t ∈ putGraph hs x payload keep := by
  simp only [putGraph, List.mem_append, List.mem_filter]
  exact Or.inl ⟨ht, keep_foreign h⟩

theorem putB_writes {hs : HSite} {fs fs' : FinStore} {agent : Option Node} {x : Node} {payload : List Triple}
    {pc : Precond} {s : Success} (h : putB hs fs agent x payload pc = .ok (s, fs')) :
    ∃ keep, fs' = fs.set x (putGraph hs x payload keep) := by
  unfold putB at h
  split at h; · cases h
  split at h; · cases h
  split at h; · cases h
  split at h; · cases h
  split at h; · cases h
  split at h; · cases h
  split at h
  · split at h
    · cases h
    · injection h with h; injection h with _ h; exact ⟨_, h.symm⟩
  · split at h; · cases h
    split at h; · cases h
    injection h with h; injection h with _ h; exact ⟨_, h.symm⟩

/-- A PUT the graph store goes ahead with, to any document, states in the upload's description what its payload says
of the upload. -/
theorem any_writer_describes_any_upload {hs : HSite} {fs fs' : FinStore} {agent : Option Node} {x : Node}
    {payload : List Triple} {pc : Precond} {s : Success} {t : Triple}
    (hput : putB hs fs agent x payload pc = .ok (s, fs')) (ht : t ∈ payload) (hx : t.s ≠ x) :
    t ∈ describe fs' t.s := by
  obtain ⟨keep, rfl⟩ := putB_writes hput
  exact mem_describe_set (mem_putGraph ht hx) rfl

/-- What an authorization can name a document by. -/
inductive Rel where
  | accessTo | default | accessToClass | owner
  deriving DecidableEq, Repr

/-- The rows of the document context query (web.xml `documentContextQuery`) for an upload: the branch for the
document itself, and the one for a file typed `nfo:FileDataObject` in some graph and having no graph of its own. Its
containment and own types are empty, since it has no graph, and no graph can state another document's containment. -/
def uploadContext (fs : FinStore) (u : Node) : List (Rel × Node) :=
  (Rel.accessTo, u) ::
    (if (describe fs u).any (fun t => t.p == .rdfType && t.o == .nfoFileDataObject) && !hasDoc fs u
     then [(Rel.accessToClass, Node.nfoFileDataObject)] else [])

theorem upload_context (fs : FinStore) (u : Node) :
    ∀ row ∈ uploadContext fs u, (row.1 = .accessTo ∧ row.2 = u) ∨ (row.1 = .accessToClass ∧ row.2 = .nfoFileDataObject) := by
  intro row h
  simp only [uploadContext, List.mem_cons] at h
  rcases h with h | h
  · left; subst h; exact ⟨rfl, rfl⟩
  · split at h
    · simp at h; right; subst h; exact ⟨rfl, rfl⟩
    · simp at h

end LdhUploads
