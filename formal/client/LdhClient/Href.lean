/-
`ldh:href`, the function nearly every request the client makes takes its target from (`imports/default.xsl`), and
`ldh:is-local`, which decides whether it wraps a URI in `?uri=` on the page's own origin.
-/
import LdhClient.Uri

namespace LdhClient

/-- `ldh:is-local`: `starts-with($uri, lds:origin(ldh:request-uri()) || '/')`. -/
def isLocal (page u : Str) : Bool := (origin page ++ ['/']).isPrefixOf u

/-- `if ($fragment) then ('#' || $fragment) else ()`: an empty fragment is falsy. -/
def tail : Option Str → Str
  | some f => if f.isEmpty then [] else '#' :: f
  | none => []

/-- `ldh:href($uri, $query-params, $fragment)` on the page `page`. A URI that is not local is wrapped in `?uri=` on
the page's path; a local one keeps its path, its own query parameters overlaid by the caller's. The empty URI is
falsy, so it takes the local branch. No URI at all is a dynamic error: `ac:document-uri` takes a required item. -/
def href (Q : Query) (page : Str) (u : Option Str) (q : Q.P) (frag : Option Str) : Option Str :=
  match u with
  | none => none
  | some u =>
    if !u.isEmpty && !isLocal page u then some (buildUri Q (absPath page) (Q.withUri u q) ++ tail frag)
    else some (buildUri Q (absPath u) (Q.overlay (Q.parse (after '?' (docUri u))) q) ++ tail frag)

/-- A request target the browser sends to the page's origin: it starts with the origin and a slash, which ends the
authority of an `http(s)` URL, or it is a reference relative to the page that keeps its path (empty, a query, a
fragment). -/
def SameOrigin (page r : Str) : Prop :=
  (origin page ++ ['/']) <+: r ∨ r = [] ∨ r.head? = some '?' ∨ r.head? = some '#'

/-- The page the client runs on, as `window.location` gives it: `http(s)`, a non-empty authority, and a path. The
location's authority holds no `/`, `?` or `#`, and a location holds no newline. -/
structure Page (page : Str) : Prop where
  shape : ∃ sch auth rest, (sch = http ∨ sch = https) ∧ page = sch ++ auth ++ '/' :: rest ∧ auth ≠ [] ∧
    '/' ∉ auth ∧ '?' ∉ auth ∧ '#' ∉ auth ∧ '\n' ∉ rest

section lemmas

theorem takeWhile_of_prefix {p : Char → Bool} {l s : Str} (h : ∀ a ∈ l, p a = true) :
    l <+: (l ++ s).takeWhile p := by
  rw [List.takeWhile_append_of_pos h]; exact List.prefix_append _ _

/-- A prefix with no `?` and no `#` survives `ac:absolute-path`. -/
theorem prefix_absPath {o u : Str} (hp : o <+: u) (hq : '?' ∉ o) (hh : '#' ∉ o) : o <+: absPath u := by
  obtain ⟨s, rfl⟩ := hp
  have nq : ∀ a ∈ o, (a != '?') = true := fun a ha => by
    have : a ≠ '?' := fun e => hq (e ▸ ha)
    simpa using this
  have nh : ∀ a ∈ o, (a != '#') = true := fun a ha => by
    have : a ≠ '#' := fun e => hh (e ▸ ha)
    simpa using this
  unfold absPath before
  split
  · exact takeWhile_of_prefix nq
  · split
    · exact takeWhile_of_prefix nh
    · exact List.prefix_append _ _

theorem origin_page {sch auth rest : Str} (hs : sch = http ∨ sch = https) (ha : auth ≠ [])
    (hsl : '/' ∉ auth) (hn : '\n' ∉ rest) : origin (sch ++ auth ++ '/' :: rest) = sch ++ auth := by
  have tw : (auth ++ '/' :: rest).takeWhile (· != '/') = auth := by
    rw [List.takeWhile_append_of_pos (fun a h => by
      have : a ≠ '/' := fun e => hsl (e ▸ h)
      simpa using this)]
    simp
  have dw : (auth ++ '/' :: rest).dropWhile (· != '/') = '/' :: rest := by
    rw [List.dropWhile_append_of_pos (fun a h => by
      have : a ≠ '/' := fun e => hsl (e ▸ h)
      simpa using this)]
    simp
  have nl : ((auth ++ '/' :: rest).dropWhile (· != '/')).contains '\n' = false := by
    rw [dw]; simpa using hn
  have ne : (auth.isEmpty) = false := by cases auth <;> simp_all
  have pre : ∀ sch : Str, sch.isPrefixOf (sch ++ (auth ++ '/' :: rest)) = true := fun sch => by
    rw [List.isPrefixOf_iff_prefix]; exact List.prefix_append _ _
  have hw : ∀ sch : Str, originWith sch (sch ++ (auth ++ '/' :: rest)) = some (sch ++ auth) := fun sch => by
    simp only [originWith, pre, if_true, List.drop_left, tw, nl, ne, Bool.false_or, Bool.false_eq_true, if_false]
  rw [List.append_assoc]
  rcases hs with rfl | rfl
  · have h1 : originWith https (http ++ (auth ++ '/' :: rest)) = none := by
      simp [originWith, https, http, List.isPrefixOf]
    simp [origin, h1, hw]
  · simp [origin, hw]

end lemmas

/-- **`ldh:href` stays on the page's origin.** Whatever URI it is given, on a page `window.location` can be, the
target it returns starts with the page's origin and a slash or is relative to the page. A URI on another origin, a
`javascript:` URI included, ends up in the `?uri=` parameter of the page's own path. -/
theorem href_same_origin (Q : Query) {page : Str} (hp : Page page) (u : Option Str) (q : Q.P) (frag : Option Str)
    {r : Str} (h : href Q page u q frag = some r) : SameOrigin page r := by
  obtain ⟨sch, auth, rest, hs, rfl, ha, hsl, hq, hh, hn⟩ := hp.shape
  have ho := origin_page hs ha hsl hn
  have schq : '?' ∉ sch ∧ '#' ∉ sch := by rcases hs with rfl | rfl <;> simp [http, https]
  have oq : '?' ∉ origin (sch ++ auth ++ '/' :: rest) ++ ['/'] := by
    rw [ho]; simp [schq.1, hq]
  have oh : '#' ∉ origin (sch ++ auth ++ '/' :: rest) ++ ['/'] := by
    rw [ho]; simp [schq.2, hh]
  unfold href at h
  cases u with
  | none => cases h
  | some u =>
    simp only at h
    split at h
    · -- not local: the page's own path, then `?uri=`
      cases h
      left
      have : origin (sch ++ auth ++ '/' :: rest) ++ ['/'] <+: sch ++ auth ++ '/' :: rest := by
        rw [ho]; exact ⟨rest, by simp⟩
      exact ((prefix_absPath this oq oh).trans (List.prefix_append _ _)).trans (List.prefix_append _ _)
    · cases h
      rename_i hl
      by_cases he : u.isEmpty
      · -- the empty URI: a query string or a fragment, relative to the page
        have : u = [] := by cases u <;> simp_all
        subst this
        right
        simp only [buildUri, absPath, before, List.contains, List.elem_nil, Bool.false_eq_true, if_false,
          List.nil_append]
        rcases Q.string_shape (Q.overlay (Q.parse (after '?' (docUri []))) q) with hs' | ⟨s, hs'⟩
        · rw [hs']
          cases frag with
          | none => left; rfl
          | some f =>
            simp only [tail]
            split
            · left; rfl
            · right; right; rfl
        · rw [hs']; right; left; rfl
      · -- local: the URI's own path, which starts with the page's origin
        have hloc : isLocal (sch ++ auth ++ '/' :: rest) u = true := by
          simp only [he, Bool.not_false, Bool.true_and, Bool.not_eq_true', Bool.not_eq_false] at hl
          simpa using hl
        left
        have : origin (sch ++ auth ++ '/' :: rest) ++ ['/'] <+: u := (List.isPrefixOf_iff_prefix).1 hloc
        exact ((prefix_absPath this oq oh).trans (List.prefix_append _ _)).trans (List.prefix_append _ _)

end LdhClient
