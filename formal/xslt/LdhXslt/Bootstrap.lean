/-
The bootstrap script (layout.xsl, `ac:Scripts` in xhtml:Head), which writes the dataspace's origin and the agent's
URI into a JavaScript string literal with output escaping disabled:

    var contextUri = "<origin>";
    var agentUri = ["<agent>"];

Nothing escapes either value, so the literal holds because of what a URI can be. The agent is the one value a caller
chooses - the subject alternative name of a certificate, or `On-Behalf-Of` - and the platform parses both as a
`java.net.URI`, which admits US-ASCII letters, digits and the characters RFC 2396 reserves or leaves unreserved, `%`
for an escape, and non-ASCII characters that are neither controls nor spaces. `uriChar` admits every one of those;
that it admits nothing the literal cannot hold is the hypothesis, and what `java.net.URI` documents.

* `bootstrap_closed`: such a value ends the literal exactly at its closing quote, and holds neither `<`, which an HTML
  parser would read as the end of the script, nor `>`, which ends the CDATA section the script is wrapped in when the
  page is read as XML.
-/
import LdhXslt.Url

namespace LdhXslt

def uriAscii : List Char := "-_.!~*'();/?:@&=+$,%[]#".toList

/-- What ends a JavaScript string before its closing quote: a line terminator. -/
def lineTerminator (c : Char) : Bool := c == '\n' || c == '\r' || c.toNat == 0x2028 || c.toNat == 0x2029

/-- A character a `java.net.URI` may hold, stated with what `java.net.URI` leaves out of it named: the quote, the
backslash and the angle brackets, which are neither reserved nor unreserved, and the line terminators, which are
controls or spaces. -/
def uriChar (c : Char) : Bool :=
  (c.isAlphanum || uriAscii.contains c || 0x9F < c.toNat) &&
    !lineTerminator c && c != '"' && c != '\\' && c != '<' && c != '>'

/-- The rest of the script after a double-quoted string literal whose opening quote has been read; `none` when the
literal does not end. -/
def afterString : Str → Option Str
  | [] => none
  | c :: cs =>
    if c = '"' then some cs
    else if c = '\\' then (match cs with | [] => none | _ :: rest => afterString rest)
    else if lineTerminator c then none
    else afterString cs

/-- A value of URI characters ends the literal at its closing quote, and holds no `<` or `>`. -/
theorem bootstrap_closed (s rest : Str) (h : ∀ c ∈ s, uriChar c = true) :
    afterString (s ++ '"' :: rest) = some rest ∧ '<' ∉ s ∧ '>' ∉ s := by
  refine ⟨?_, ?_, ?_⟩
  · induction s with
    | nil => unfold afterString; simp
    | cons c cs ih =>
      have hc := h c (List.mem_cons_self c cs)
      simp only [uriChar, Bool.and_eq_true, Bool.not_eq_true', bne_iff_ne, ne_eq] at hc
      obtain ⟨⟨⟨⟨⟨_, hl⟩, hq⟩, hb⟩, _⟩, _⟩ := hc
      rw [List.cons_append]
      unfold afterString
      rw [if_neg hq, if_neg hb, hl]
      exact ih (fun d hd => h d (List.mem_cons_of_mem c hd))
  · intro hm; have := h '<' hm; revert this; decide
  · intro hm; have := h '>' hm; revert this; decide

end LdhXslt
