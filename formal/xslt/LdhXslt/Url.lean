/-
The scheme of a URL attribute's value, as the browser reads it and as the stylesheet does.

The browser (the WHATWG URL parser) trims leading and trailing C0 controls and spaces, removes every tab and line
break, and reads a scheme as a letter followed by letters, digits, `+`, `-` and `.` up to the first `:`; anything
else is a relative reference, resolved against the page and so carrying the page's scheme. The stylesheet's
`ldh:url-scheme` (imports/default.xsl) cannot trim C0 controls, since XPath strings come from XML, which cannot hold
them; it removes tabs and line breaks and trims leading spaces. On a string XML can hold the two agree
(`scheme_agrees`), which is what lets the sanitizer's rule stand for the browser's.
-/
namespace LdhXslt

abbrev Str := List Char

/-- A tab or a line break: removed anywhere in a URL. -/
def isTabNl (c : Char) : Bool := c == '\t' || c == '\n' || c == '\r'

/-- A C0 control or a space: trimmed from both ends of a URL. -/
def isC0Space (c : Char) : Bool := c.toNat ≤ 32

/-- A character XML 1.0 can hold below the space is a tab or a line break. -/
def xmlChar (c : Char) : Bool := 32 ≤ c.toNat || isTabNl c

def schemeChar (c : Char) : Bool := c.isAlphanum || c == '+' || c == '-' || c == '.'

/-- What comes before the first `:`, if there is one. -/
def beforeColon : Str → Option Str
  | [] => none
  | c :: cs => if c = ':' then some [] else (beforeColon cs).map (c :: ·)

def validScheme : Str → Bool
  | [] => false
  | c :: cs => c.isAlpha && cs.all schemeChar

/-- The scheme of a string the trimming is done for, lower-cased; `none` for a relative reference. -/
def schemeOf (s : Str) : Option Str :=
  match beforeColon s with
  | some p => if validScheme p then some (p.map Char.toLower) else none
  | none => none

def dropTrailing (f : Char → Bool) (s : Str) : Str := (s.reverse.dropWhile f).reverse

/-- The browser's reading. -/
def browserScheme (s : Str) : Option Str :=
  schemeOf ((dropTrailing isC0Space (s.dropWhile isC0Space)).filter (!isTabNl ·))

/-- `ldh:url-scheme`: `replace(replace($value, '[&#9;&#10;&#13;]', ''), '^ +', '')`, then the part before `:` when it
matches `^[A-Za-z][A-Za-z0-9+.\-]*$`, lower-cased. -/
def xsltScheme (s : Str) : Option Str :=
  schemeOf ((s.filter (!isTabNl ·)).dropWhile (· == ' '))

theorem beforeColon_noColon (w : Str) (h : ∀ c ∈ w, c ≠ ':') : beforeColon w = none := by
  induction w with
  | nil => rfl
  | cons c cs ih =>
    have hc : c ≠ ':' := h c (List.mem_cons_self c cs)
    simp [beforeColon, hc, ih (fun d hd => h d (List.mem_cons_of_mem c hd))]

theorem beforeColon_append (x w : Str) (h : ∀ c ∈ w, c ≠ ':') : beforeColon (x ++ w) = beforeColon x := by
  induction x with
  | nil => exact beforeColon_noColon w h
  | cons c cs ih => simp [beforeColon, ih]

theorem dropTrailing_split (f : Char → Bool) (s : Str) :
    ∃ w, s = dropTrailing f s ++ w ∧ ∀ c ∈ w, f c = true := by
  have hr : s.reverse = s.reverse.takeWhile f ++ s.reverse.dropWhile f := (List.takeWhile_append_dropWhile f s.reverse).symm
  refine ⟨(s.reverse.takeWhile f).reverse, ?_, ?_⟩
  · have := congrArg List.reverse hr
    simp only [List.reverse_reverse, List.reverse_append] at this
    exact this
  · intro c hc
    have hc' : c ∈ s.reverse.takeWhile f := List.mem_reverse.mp hc
    have key : ∀ (l : Str), c ∈ l.takeWhile f → f c = true := by
      intro l
      induction l with
      | nil => simp
      | cons d ds ih =>
        by_cases hd : f d = true
        · simp only [List.takeWhile_cons, hd, if_true, List.mem_cons]
          intro h
          cases h with
          | inl h => subst h; exact hd
          | inr h => exact ih h
        · simp [List.takeWhile_cons, hd]
    exact key _ hc'

theorem space_of_c0 (c : Char) (hx : xmlChar c = true) (h : isC0Space c = true) (ht : isTabNl c = false) : c = ' ' := by
  simp only [xmlChar, isC0Space, ht, Bool.or_false, decide_eq_true_eq] at hx h
  have h32 : c.toNat = 32 := Nat.le_antisymm h hx
  rw [← Char.ofNat_toNat c, h32]

/-- Trimming leading C0 controls and spaces, then removing tabs and line breaks, is removing tabs and line breaks, then
trimming leading spaces, on a string XML can hold. -/
theorem trim_filter (s : Str) (h : ∀ c ∈ s, xmlChar c = true) :
    (s.dropWhile isC0Space).filter (!isTabNl ·) = (s.filter (!isTabNl ·)).dropWhile (· == ' ') := by
  induction s with
  | nil => rfl
  | cons c cs ih =>
    have hcs := ih (fun d hd => h d (List.mem_cons_of_mem c hd))
    have hc := h c (List.mem_cons_self c cs)
    by_cases h0 : isC0Space c = true
    · by_cases ht : isTabNl c = true
      · simp [List.dropWhile_cons, h0, List.filter_cons, ht, hcs]
      · have ht' : isTabNl c = false := by simpa using ht
        have hsp := space_of_c0 c hc h0 ht'
        subst hsp
        simp [List.dropWhile_cons, h0, List.filter_cons, ht', hcs]
    · have h0' : isC0Space c = false := by simpa using h0
      have ht : isTabNl c = false := by
        cases htc : isTabNl c with
        | false => rfl
        | true =>
          exfalso
          simp only [isTabNl, Bool.or_eq_true, beq_iff_eq] at htc
          rcases htc with (rfl | rfl) | rfl <;> simp [isC0Space] at h0'
      have hns : (c == ' ') = false := by
        cases hcs' : (c == ' ') with
        | false => rfl
        | true =>
          exfalso
          have : c = ' ' := by simpa using hcs'
          subst this
          simp [isC0Space] at h0'
      simp [List.dropWhile_cons, h0', List.filter_cons, ht, hns]

theorem c0_not_colon (c : Char) (h : isC0Space c = true) : c ≠ ':' := by
  intro hc
  subst hc
  simp [isC0Space] at h

/-- The stylesheet reads the scheme the browser does, on every attribute value XML can hold. -/
theorem scheme_agrees (s : Str) (h : ∀ c ∈ s, xmlChar c = true) : browserScheme s = xsltScheme s := by
  unfold browserScheme xsltScheme
  rw [← trim_filter s h]
  obtain ⟨w, hw, hf⟩ := dropTrailing_split isC0Space (s.dropWhile isC0Space)
  generalize hu : s.dropWhile isC0Space = u at hw
  have hcol : ∀ c ∈ w.filter (!isTabNl ·), c ≠ ':' := fun c hc => c0_not_colon c (hf c (List.mem_filter.mp hc).1)
  have : u.filter (!isTabNl ·) = (dropTrailing isC0Space u).filter (!isTabNl ·) ++ w.filter (!isTabNl ·) := by
    conv => lhs; rw [hw]
    exact List.filter_append _ _
  unfold schemeOf
  rw [this, beforeColon_append _ _ hcol]

end LdhXslt
