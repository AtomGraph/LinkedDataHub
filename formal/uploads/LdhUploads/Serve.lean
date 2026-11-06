/-
Serving an upload: `Item.getResponseBuilder` (resource/upload/Item.java) and `ByteRange.parse` (server/util).

The request's `Range` is taken here after its syntax: a header with another unit, several ranges or a range-spec
that does not parse is ignored (`none`), and a single range-spec is `Spec`. `select` is what `ByteRange.parse` does
with it against the file's length.

`serve` is the response: 404 for a URI nothing describes, 406 when `Accept` does not take the media type, 304 when
`If-None-Match` names the tag, 404 for a description without a file, and otherwise the file - whole, a range of it,
or 416 - where `Range` applies, which is a GET whose `If-Range` holds. The media type is a pick among the
description's `dct:format` values (Jena's `getPropertyResourceValue` returns one of several), and the entity tag is
`tag` of the description and the URI's digest.

* `served_sandboxed`: every 200 and 206 carries `Content-Security-Policy: default-src 'none'; sandbox`.
* `range_sound`: a 206's `Content-Range` lies within the file; `unsatisfiable_iff`: 416 exactly when the RFC 9110
  conditions say so.
* `etag_content_addressed`: the tag is the URI's digest, whatever the description says. Before, the tag was a pick
  among the description's `foaf:sha1` values, which any writer can add to (`etag_was_any_writers`).
* `format_is_any_writers`: the served media type is a pick among what any writer stated, which is why the body is
  sandboxed.
-/
namespace LdhUploads

inductive Spec where
  /-- `first-last`, `last` empty for `first-` -/
  | int (first : Nat) (last : Option Nat)
  /-- `-n` -/
  | suffix (n : Nat)
  deriving DecidableEq, Repr

inductive Selected where
  | whole
  | range (first last : Nat)
  | unsatisfiable
  deriving DecidableEq, Repr

/-- `ByteRange.parse` after the header's syntax. -/
def select (len : Nat) : Option Spec → Selected
  | none => .whole
  | some (.suffix n) => if n = 0 then .unsatisfiable else if len = 0 then .whole else .range (len - n) (len - 1)
  | some (.int f none) => if len ≤ f then .unsatisfiable else .range f (len - 1)
  | some (.int f (some l)) => if l < f then .unsatisfiable else if len ≤ f then .unsatisfiable else .range f (min l (len - 1))

theorem range_sound {len : Nat} {s : Option Spec} {f l : Nat} (h : select len s = .range f l) : f ≤ l ∧ l < len := by
  match s with
  | none => simp [select] at h
  | some (.suffix n) =>
    simp only [select] at h
    split at h; · cases h
    split at h; · cases h
    injection h with h1 h2; omega
  | some (.int f' none) =>
    simp only [select] at h
    split at h; · cases h
    injection h with h1 h2; omega
  | some (.int f' (some l')) =>
    simp only [select] at h
    split at h; · cases h
    split at h; · cases h
    injection h with h1 h2; omega

/-- RFC 9110 §14.1.1: a suffix range is satisfiable when its length is not zero, a range from a first position when
that position is within the file; a last position before the first makes the range-spec invalid, which is refused too. -/
theorem unsatisfiable_iff (len : Nat) (s : Spec) :
    select len (some s) = .unsatisfiable ↔
      s = .suffix 0 ∨ (∃ f l, s = .int f l ∧ ((∃ l', l = some l' ∧ l' < f) ∨ len ≤ f)) := by
  cases s with
  | suffix n =>
    simp only [select]
    by_cases hn : n = 0
    · subst hn; simp
    · by_cases hl : len = 0 <;> simp [hn, hl]
  | int f l =>
    cases l with
    | none =>
      by_cases hf : len ≤ f
      · simp [select, hf]; exact ⟨f, none, ⟨rfl, rfl⟩, Or.inr hf⟩
      · simp [select, hf]; omega
    | some l' =>
      by_cases h1 : l' < f
      · simp [select, h1]; exact ⟨f, some l', ⟨rfl, rfl⟩, Or.inl ⟨l', rfl, h1⟩⟩
      · by_cases h2 : len ≤ f
        · simp [select, h1, h2]; exact ⟨f, some l', ⟨rfl, rfl⟩, Or.inr h2⟩
        · simp [select, h1, h2]; omega

structure Desc where
  /-- something describes the URI -/
  described : Bool
  formats : List String
  sha1s : List String

structure Req where
  get : Bool
  /-- `Accept` takes the media type -/
  accepts : String → Bool
  ifNoneMatch : Option String
  ifRange : Bool
  range : Option Spec

structure Resp where
  status : Nat
  csp : Bool
  tag : Option String
  contentRange : Option (Nat × Nat × Nat)

/-- `Item.getResponseBuilder`, after `init()`'s 404 for an undescribed URI. `pick` is Jena's choice among the values
of a property; `tag` is how the entity tag is read; `file` is the file's length, if it is on disk. -/
def serve (pick : List String → Option String) (tag : Desc → String → Option String) (d : Desc) (sha : String)
    (file : Option Nat) (r : Req) : Resp :=
  if !d.described then ⟨404, false, none, none⟩ else
  match pick d.formats with
  | none => ⟨500, false, none, none⟩
  | some fmt =>
    if !r.accepts fmt then ⟨406, false, none, none⟩ else
    match tag d sha with
    | none => ⟨500, false, none, none⟩
    | some t =>
      if r.ifNoneMatch = some t then ⟨304, false, some t, none⟩ else
      match file with
      | none => ⟨404, false, none, none⟩
      | some len =>
        if r.get && r.ifRange then
          match select len r.range with
          | .range f l => ⟨206, true, some t, some (f, l, len)⟩
          | .unsatisfiable => ⟨416, false, some t, none⟩
          | .whole => ⟨200, true, some t, none⟩
        else ⟨200, true, some t, none⟩

/-- The tag before: `getRequiredProperty(FOAF.sha1)`, a pick among the description's values. -/
def describedTag (pick : List String → Option String) (d : Desc) (_ : String) : Option String := pick d.sha1s

/-- The tag now: the digest the URI is named by. -/
def addressTag (_ : Desc) (sha : String) : Option String := some sha

theorem served_sandboxed {pick tag d sha file r} (h : (serve pick tag d sha file r).status = 200 ∨
    (serve pick tag d sha file r).status = 206) : (serve pick tag d sha file r).csp = true := by
  unfold serve at *
  split <;> (try simp_all)
  split <;> (try simp_all)
  split <;> (try simp_all)
  split <;> (try simp_all)
  split <;> (try simp_all)
  split <;> (try simp_all)
  split <;> (try simp_all)
  split <;> simp_all

theorem served_range_sound {pick tag d sha file r} {f l len : Nat}
    (h : (serve pick tag d sha file r).contentRange = some (f, l, len)) : f ≤ l ∧ l < len ∧ file = some len := by
  unfold serve at h
  split at h; · cases h
  split at h; · cases h
  split at h; · cases h
  split at h; · cases h
  split at h; · cases h
  split at h; · cases h
  rename_i len' _
  split at h
  · split at h
    · rename_i hs
      simp only [Option.some.injEq, Prod.mk.injEq] at h
      obtain ⟨rfl, rfl, rfl⟩ := h
      exact ⟨(range_sound hs).1, (range_sound hs).2, rfl⟩
    · cases h
    · cases h
  · cases h

theorem etag_content_addressed {pick d sha file r} {t : String}
    (h : (serve pick addressTag d sha file r).tag = some t) : t = sha := by
  unfold serve at h
  split at h; · cases h
  split at h; · cases h
  split at h; · cases h
  simp only [addressTag, Option.some.injEq] at *
  split at h
  · injection h with h; exact h.symm
  · split at h; · cases h
    split at h
    · split at h <;> (injection h with h; exact h.symm)
    · injection h with h; exact h.symm

/-- Before: a second `foaf:sha1`, which any writer can state (`any_writer_describes_any_upload`), made the tag one
the file is not named by, and a request conditional on it was answered 304. -/
theorem etag_was_any_writers :
    let d : Desc := ⟨true, ["image/png"], ["0000", "abcd"]⟩
    let r : Req := ⟨true, fun _ => true, some "0000", true, none⟩
    serve List.head? (describedTag List.head?) d "abcd" (some 4) r = ⟨304, false, some "0000", none⟩ := rfl

/-- The media type is whichever of the stated formats is picked: one any writer stated is served. -/
theorem format_is_any_writers (pick : List String → Option String) (hpick : ∀ l, l ≠ [] → ∃ v, pick l = some v ∧ v ∈ l)
    (d : Desc) (sha : String) (len : Nat) (r : Req) (hd : d.described = true) (hf : d.formats ≠ [])
    (ha : ∀ m, r.accepts m = true) (hn : r.ifNoneMatch ≠ some sha) (hr : r.get = false) :
    ∃ fmt ∈ d.formats, pick d.formats = some fmt ∧ (serve pick addressTag d sha (some len) r).status = 200 := by
  obtain ⟨v, hv, hm⟩ := hpick d.formats hf
  refine ⟨v, hm, hv, ?_⟩
  simp [serve, hd, hv, ha, addressTag, hn, hr]

end LdhUploads
