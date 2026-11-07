/-
What an XML literal renders to, and what of it a browser runs.

A literal is a tree of elements and text, each element and attribute with a namespace and a local name. Rendering it
(`ldh:XHTMLContent`, and `ldh:SafeXHTML` for the editor's live region, in imports/default.xsl) copies it, minus what
the shared rules take out; `sanitize` is those rules. `runs` is what the browser executes in a tree inserted into the
page: a script element, an event handler, a frame's inline document, and a URL that navigates to script. That
definition is the model's hypothesis about browsers, stated once, here.

* `sanitize_inert`: nothing a literal renders to runs, whatever was stored.
* `sanitize_faithful`: a literal with none of what the rules name renders as it was stored.
* `text_inert`: a text node renders as itself; the serializer escapes it, so it is never markup.
-/
import LdhXslt.Url

namespace LdhXslt

def xhtmlNs : String := "http://www.w3.org/1999/xhtml"
def svgNs : String := "http://www.w3.org/2000/svg"
def xlinkNs : String := "http://www.w3.org/1999/xlink"

structure Attr where
  ns : String
  name : String
  value : Str
deriving Repr, DecidableEq

inductive Node where
  | text (s : Str)
  | elem (ns name : String) (attrs : List Attr) (kids : List Node)
deriving Repr

/-! ### The browser -/

/-- A script element runs as XHTML or SVG; one in no namespace is an HTML script once the page is served as HTML. -/
def runsElem (ns name : String) : Bool := name == "script" && (ns == xhtmlNs || ns == svgNs || ns == "")

/-- `matches(local-name(), '^on', 'i')`, which is also the shape of every event handler attribute. -/
def startsOn (name : String) : Bool :=
  match name.toList with
  | o :: n :: _ => o.toLower == 'o' && n.toLower == 'n'
  | _ => false

/-- The attributes whose value the browser navigates to or loads. -/
def urlAttrs : List String := ["href", "src", "action", "formaction", "poster", "background"]

def scriptScheme (s : Option Str) : Bool := s == some "javascript".toList || s == some "vbscript".toList

def runsAttr (a : Attr) : Bool :=
  (a.ns == "" && startsOn a.name) || a.name == "srcdoc" || (urlAttrs.contains a.name && scriptScheme (browserScheme a.value))

mutual
def runs : Node → Bool
  | .text _ => false
  | .elem ns name attrs kids => runsElem ns name || attrs.any runsAttr || runsList kids
def runsList : List Node → Bool
  | [] => false
  | k :: ks => runs k || runsList ks
end

/-! ### The rules -/

/-- The elements taken out, by local name in any namespace. -/
def activeNames : List String :=
  ["script", "style", "object", "embed", "applet", "base", "link", "meta", "frame", "frameset",
   "set", "animate", "animateMotion", "animateTransform", "handler", "listener"]

/-- `matches(replace(., '[&#9;&#10;&#13;]', ''), '^ *data:image/', 'i')` -/
def dataImage (v : Str) : Bool :=
  ((v.filter (!isTabNl ·)).dropWhile (· == ' ')).take 11 |>.map Char.toLower |> (· == "data:image/".toList)

def dropAttr (a : Attr) : Bool :=
  startsOn a.name || a.name == "srcdoc" ||
  (urlAttrs.contains a.name &&
    (scriptScheme (xsltScheme a.value) || (xsltScheme a.value == some "data".toList && !(a.name == "src" && dataImage a.value))))

mutual
def sanitize : Node → List Node
  | .text s => [.text s]
  | .elem ns name attrs kids =>
    if activeNames.contains name then [] else [.elem ns name (attrs.filter (!dropAttr ·)) (sanitizeList kids)]
def sanitizeList : List Node → List Node
  | [] => []
  | k :: ks => sanitize k ++ sanitizeList ks
end

/-! ### Values XML can hold -/

def legalAttr (a : Attr) : Prop := ∀ c ∈ a.value, xmlChar c = true

mutual
def Legal : Node → Prop
  | .text _ => True
  | .elem _ _ attrs kids => (∀ a ∈ attrs, legalAttr a) ∧ LegalList kids
def LegalList : List Node → Prop
  | [] => True
  | k :: ks => Legal k ∧ LegalList ks
end

/-! ### Results -/

theorem kept_inert (a : Attr) (h : legalAttr a) (hk : dropAttr a = false) : runsAttr a = false := by
  have hs := scheme_agrees a.value h
  simp only [dropAttr, Bool.or_eq_false_iff, Bool.and_eq_false_iff] at hk
  simp only [runsAttr, hs, Bool.or_eq_false_iff, Bool.and_eq_false_iff]
  obtain ⟨⟨hon, hsrc⟩, hurl⟩ := hk
  refine ⟨⟨?_, hsrc⟩, ?_⟩
  · exact Or.inr hon
  · rcases hurl with h1 | h1
    · exact Or.inl h1
    · exact Or.inr h1.1

theorem filter_inert (attrs : List Attr) (h : ∀ a ∈ attrs, legalAttr a) :
    (attrs.filter (!dropAttr ·)).any runsAttr = false := by
  rw [List.any_eq_false]
  intro a ha
  have ⟨hm, hk⟩ := List.mem_filter.mp ha
  simpa using kept_inert a (h a hm) (by simpa using hk)

theorem runsList_append (xs ys : List Node) : runsList (xs ++ ys) = (runsList xs || runsList ys) := by
  induction xs with
  | nil => simp [runsList]
  | cons x xs ih => simp [runsList, ih, Bool.or_assoc]

mutual
theorem sanitize_inert' : ∀ (n : Node), Legal n → runsList (sanitize n) = false
  | .text s, _ => by simp [sanitize, runsList, runs]
  | .elem ns name attrs kids, ⟨ha, hk⟩ => by
    unfold sanitize
    by_cases hn : activeNames.contains name = true
    · rw [if_pos hn]; rfl
    · have hn' : activeNames.contains name = false := by simpa using hn
      have hs : runsElem ns name = false := by
        cases hr : name == "script" with
        | false => simp [runsElem, hr]
        | true =>
          have : name = "script" := by simpa using hr
          subst this
          simp [activeNames] at hn'
      simp only [hn', Bool.false_eq_true, if_false, runsList, runs, hs, filter_inert attrs ha,
        sanitizeList_inert kids hk, Bool.or_false]
theorem sanitizeList_inert : ∀ (ks : List Node), LegalList ks → runsList (sanitizeList ks) = false
  | [], _ => by simp [sanitizeList, runsList]
  | k :: ks, ⟨hk, hks⟩ => by
    simp only [sanitizeList, runsList_append, sanitize_inert' k hk, sanitizeList_inert ks hks, Bool.or_false]
end

/-- Nothing a literal renders to runs, whatever was stored. -/
theorem sanitize_inert (n : Node) (h : Legal n) : ∀ m ∈ sanitize n, runs m = false := by
  have key : ∀ (l : List Node), runsList l = false → ∀ m ∈ l, runs m = false := by
    intro l
    induction l with
    | nil => simp
    | cons x xs ih =>
      intro hl m hm
      simp only [runsList, Bool.or_eq_false_iff] at hl
      cases List.mem_cons.mp hm with
      | inl he => subst he; exact hl.1
      | inr ht => exact ih hl.2 m ht
  exact key _ (sanitize_inert' n h)

-- what the rules name: none of it in a tree, and the tree renders as it was stored
mutual
def Clean : Node → Prop
  | .text _ => True
  | .elem _ name attrs kids => activeNames.contains name = false ∧ (∀ a ∈ attrs, dropAttr a = false) ∧ CleanList kids
def CleanList : List Node → Prop
  | [] => True
  | k :: ks => Clean k ∧ CleanList ks
end

mutual
theorem sanitize_faithful : ∀ (n : Node), Clean n → sanitize n = [n]
  | .text _, _ => rfl
  | .elem ns name attrs kids, ⟨hn, ha, hk⟩ => by
    have hf : attrs.filter (!dropAttr ·) = attrs := List.filter_eq_self.mpr (fun a h => by simp [ha a h])
    unfold sanitize
    rw [if_neg (by rw [hn]; decide), hf, sanitizeList_faithful kids hk]
theorem sanitizeList_faithful : ∀ (ks : List Node), CleanList ks → sanitizeList ks = ks
  | [], _ => rfl
  | k :: ks, ⟨hk, hks⟩ => by simp [sanitizeList, sanitize_faithful k hk, sanitizeList_faithful ks hks]
end

/-- A text node renders as itself. -/
theorem text_inert (s : Str) : sanitize (.text s) = [.text s] := rfl

end LdhXslt
