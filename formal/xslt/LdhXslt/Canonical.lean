/-
The editor's canonical form, `cm:canonical` (rdfa-editor/canonical-xhtml.xsl), rules S1-S3: the ones that take
content out. The editor stores what they leave.

They had three gaps, each proven of the stylesheet as it was and replayed against it, and closed upstream
(AtomGraph/RDFa-Editor, `fix/sanitize-any-namespace`), from where the stylesheet is copied unchanged:

* S1 matched script in the XHTML namespace only, so an `svg:script` survived.
* S3 read the scheme after `normalize-space`, which turns a tab into a space; the browser removes it, so
  `java&#9;script:` survived as `javascript:`.
* S3 matched `@href` in no namespace only, so an SVG link's `xlink:href` survived.

S1 now matches by local name in any namespace, S2 takes `srcdoc` too, and S3 reads the scheme as the browser does
(`cm:url-scheme`, `xsltScheme`) on the URL attributes in any namespace: its attribute rule is `dropAttr`, the
renderer's own. So:

* `canonical_inert`: nothing S1-S3 leave runs, whatever was pasted or typed.
* `canonical_takes_them_out`: the three former counterexamples are taken out.
-/
import LdhXslt.Sanitize

namespace LdhXslt

/-- S1: by local name in any namespace. -/
def s1Names : List String :=
  ["script", "style", "iframe", "frame", "frameset", "object", "embed", "applet", "form", "input", "select",
   "textarea", "link", "meta", "base", "set", "animate", "animateMotion", "animateTransform"]

mutual
/-- S1 drops the element; S2 (`@*[matches(local-name(), '^on', 'i')] | @*[local-name() = 'srcdoc']`) and S3 the
attribute, which together are `dropAttr`. -/
def canonical : Node → List Node
  | .text s => [.text s]
  | .elem ns name attrs kids =>
    if s1Names.contains name then [] else [.elem ns name (attrs.filter (!dropAttr ·)) (canonicalList kids)]
def canonicalList : List Node → List Node
  | [] => []
  | k :: ks => canonical k ++ canonicalList ks
end

mutual
theorem canonical_inert' : ∀ (n : Node), Legal n → runsList (canonical n) = false
  | .text s, _ => by simp [canonical, runsList, runs]
  | .elem ns name attrs kids, ⟨ha, hk⟩ => by
    unfold canonical
    by_cases hn : s1Names.contains name = true
    · rw [if_pos hn]; rfl
    · have hn' : s1Names.contains name = false := by simpa using hn
      have hs : runsElem ns name = false := by
        cases hr : name == "script" with
        | false => simp [runsElem, hr]
        | true =>
          have : name = "script" := by simpa using hr
          subst this
          simp [s1Names] at hn'
      simp only [hn', Bool.false_eq_true, if_false, runsList, runs, hs, filter_inert attrs ha,
        canonicalList_inert kids hk, Bool.or_false]
theorem canonicalList_inert : ∀ (ks : List Node), LegalList ks → runsList (canonicalList ks) = false
  | [], _ => by simp [canonicalList, runsList]
  | k :: ks, ⟨hk, hks⟩ => by
    simp only [canonicalList, runsList_append, canonical_inert' k hk, canonicalList_inert ks hks, Bool.or_false]
end

/-- Nothing S1-S3 leave runs. -/
theorem canonical_inert (n : Node) (h : Legal n) : runsList (canonical n) = false := canonical_inert' n h

def svgScript : Node :=
  .elem svgNs "svg" [] [.elem svgNs "script" [] [.text "alert(document.domain)".toList]]

def splitScheme : Node :=
  .elem xhtmlNs "p" [] [.elem xhtmlNs "a" [⟨"", "href", "java\tscript:alert(document.domain)".toList⟩] [.text "link".toList]]

def xlinkHref : Node :=
  .elem svgNs "svg" [] [.elem svgNs "a" [⟨xlinkNs, "href", "javascript:alert(document.domain)".toList⟩] [.elem svgNs "text" [] [.text "link".toList]]]

/-- The canonical form takes out the three it used to keep. -/
theorem canonical_takes_them_out : runsList (canonical svgScript) = false ∧ runsList (canonical splitScheme) = false ∧
    runsList (canonical xlinkHref) = false := by decide

/-- Rendering takes out all three. -/
theorem sanitize_takes_them_out : runsList (sanitize svgScript) = false ∧ runsList (sanitize splitScheme) = false ∧
    runsList (sanitize xlinkHref) = false := by decide

end LdhXslt
