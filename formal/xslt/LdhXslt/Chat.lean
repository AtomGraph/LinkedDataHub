/-
The assistant's answer, `ldh:ChatAnswer` (client/chat.xsl): an XHTML fragment a model wrote, kept to paragraphs, lists,
emphasis, code and http(s) links. An element it keeps is rebuilt in the XHTML namespace with no attribute but a
link's `href`; one it does not know is unwrapped to its content; script and its kin go whole.

* `chat_inert`: nothing an answer renders to runs, whatever the model wrote.
-/
import LdhXslt.Sanitize

namespace LdhXslt

def chatKept : List String := ["p", "ul", "ol", "li", "strong", "em", "code"]

def chatDropped : List String := ["script", "style", "iframe", "object", "embed", "template", "noscript"]

/-- `matches(@href, '^https?://')` -/
def httpHref (v : Str) : Bool := "http://".toList.isPrefixOf v || "https://".toList.isPrefixOf v

mutual
/-- `normalize-space()` is not empty: the element has text other than whitespace. -/
def hasText : Node → Bool
  | .text s => !s.all (fun c => c == ' ' || isTabNl c)
  | .elem _ _ _ kids => hasTextList kids
def hasTextList : List Node → Bool
  | [] => false
  | k :: ks => hasText k || hasTextList ks
end

def hrefOf (attrs : List Attr) : Option Str := (attrs.find? (fun a => a.ns == "" && a.name == "href")).map (·.value)

mutual
def chat : Node → List Node
  | .text s => [.text s]
  | n@(.elem ns name attrs kids) =>
    if ns == xhtmlNs && chatKept.contains name then
      if hasText n then [.elem xhtmlNs name [] (chatList kids)] else []
    else if ns == xhtmlNs && name == "a" && (hrefOf attrs).any httpHref then
      if hasText n then [.elem xhtmlNs "a" [⟨"", "href", (hrefOf attrs).getD []⟩] (chatList kids)] else []
    else if ns == xhtmlNs && chatDropped.contains name then []
    else chatList kids
def chatList : List Node → List Node
  | [] => []
  | k :: ks => chat k ++ chatList ks
end

theorem xsltScheme_http_prefix (p r : Str) (hp : ∀ c ∈ p, c ≠ ':' ∧ isTabNl c = false) (hp0 : p.head? ≠ some ' ') :
    xsltScheme (p ++ ':' :: r) = schemeOf (p ++ ':' :: r.filter (!isTabNl ·)) := by
  unfold xsltScheme
  have hf : (p ++ ':' :: r).filter (!isTabNl ·) = p ++ ':' :: r.filter (!isTabNl ·) := by
    rw [List.filter_append, List.filter_eq_self.mpr (fun c hc => by simp [(hp c hc).2])]
    simp [isTabNl]
  rw [hf]
  cases p with
  | nil => simp
  | cons c cs =>
    have : (c == ' ') = false := by
      cases h : (c == ' ') with
      | false => rfl
      | true => exact absurd (by simpa using h) (by simpa using hp0)
    simp [List.dropWhile_cons, this]

theorem httpHref_scheme (v : Str) (h : httpHref v = true) :
    xsltScheme v = some "http".toList ∨ xsltScheme v = some "https".toList := by
  unfold httpHref at h
  simp only [Bool.or_eq_true] at h
  rcases h with h | h
  · obtain ⟨r, hr⟩ := List.isPrefixOf_iff_prefix.mp h
    subst hr
    left
    rw [show "http://".toList ++ r = ['h', 't', 't', 'p'] ++ ':' :: ('/' :: '/' :: r) from rfl]
    rw [xsltScheme_http_prefix _ _ (by decide) (by decide)]
    rfl
  · obtain ⟨r, hr⟩ := List.isPrefixOf_iff_prefix.mp h
    subst hr
    right
    rw [show "https://".toList ++ r = ['h', 't', 't', 'p', 's'] ++ ':' :: ('/' :: '/' :: r) from rfl]
    rw [xsltScheme_http_prefix _ _ (by decide) (by decide)]
    rfl

theorem href_inert (v : Str) (hl : ∀ c ∈ v, xmlChar c = true) (h : httpHref v = true) :
    runsAttr ⟨"", "href", v⟩ = false := by
  have hs : browserScheme v = xsltScheme v := scheme_agrees v hl
  simp only [runsAttr, hs]
  rcases httpHref_scheme v h with e | e <;> rw [e] <;> decide

theorem hrefOf_legal (attrs : List Attr) (h : ∀ a ∈ attrs, legalAttr a) : ∀ c ∈ (hrefOf attrs).getD [], xmlChar c = true := by
  unfold hrefOf
  cases hf : attrs.find? (fun a => a.ns == "" && a.name == "href") with
  | none => simp
  | some a => simpa using h a (List.mem_of_find?_eq_some hf)

mutual
theorem chat_inert' : ∀ (n : Node), Legal n → runsList (chat n) = false
  | .text s, _ => by simp [chat, runsList, runs]
  | .elem ns name attrs kids, ⟨ha, hk⟩ => by
    have hkids := chatList_inert kids hk
    unfold chat
    split
    · split
      · simp [runsList, runs, runsElem, hkids, xhtmlNs, svgNs]
        intro h; subst h; simp_all [chatKept]
      · rfl
    · split
      · split
        · rename_i hh _
          simp only [Bool.and_eq_true] at hh
          have hv := href_inert _ (hrefOf_legal attrs ha) (by
            cases e : hrefOf attrs with
            | none => simp [e] at hh
            | some v => simpa [e] using hh.2)
          simp [runsList, runs, runsElem, hkids, hv]
        · rfl
      · split
        · rfl
        · exact hkids
theorem chatList_inert : ∀ (ks : List Node), LegalList ks → runsList (chatList ks) = false
  | [], _ => by simp [chatList, runsList]
  | k :: ks, ⟨hk, hks⟩ => by
    simp only [chatList, runsList_append, chat_inert' k hk, chatList_inert ks hks, Bool.or_false]
end

/-- Nothing an answer renders to runs, whatever the model wrote. -/
theorem chat_inert (n : Node) (h : Legal n) : runsList (chat n) = false := chat_inert' n h

end LdhXslt
