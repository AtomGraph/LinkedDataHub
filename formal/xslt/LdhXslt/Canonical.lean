/-
The editor's canonical form, `cm:canonical` (rdfa-editor/canonical-xhtml.xsl), rules S1-S3: the ones that take
content out. The editor stores what they leave, so before rendering took the active parts out itself
(`LdhXslt.Sanitize`), they were all that stood between a literal and the page, and only for literals saved through
the editor. They do not stop everything that runs, and the counterexamples below are what `canonical-cases.xsl`
replays against the stylesheet, which is copied into this repository unchanged and is fixed upstream if at all:

* `canonical_keeps_svg_script`: S1 matches script in the XHTML namespace only.
* `canonical_keeps_split_scheme`: S3 reads the scheme after `normalize-space`, which turns a tab into a space; the
  browser removes it, so `java&#9;script:` is `javascript:`.
* `canonical_keeps_xlink_href`: S3 matches `@href` in no namespace, and an SVG link's target is `xlink:href`.
-/
import LdhXslt.Sanitize

namespace LdhXslt

/-- S1: `script | style | iframe | object | embed | applet | form | input | select | textarea | link | meta | base`,
under `xpath-default-namespace="http://www.w3.org/1999/xhtml"`. -/
def s1Names : List String :=
  ["script", "style", "iframe", "object", "embed", "applet", "form", "input", "select", "textarea", "link", "meta", "base"]

def isXmlSpace (c : Char) : Bool := c == ' ' || isTabNl c

/-- `normalize-space`: runs of spaces, tabs and line breaks to one space, none at either end. -/
def normalizeSpace (s : Str) : Str :=
  let words := (s.splitBy (fun a b => isXmlSpace a == isXmlSpace b)).filter (fun w => !w.all isXmlSpace)
  List.intercalate [' '] words

def lowerPrefix (p s : Str) : Bool := (s.take p.length).map Char.toLower == p

/-- S3: `@href[matches(normalize-space(.), '^(javascript|vbscript|data):', 'i')]`, `@src[matches(normalize-space(.),
'^(javascript|vbscript):', 'i')]`, and `@src` with `^data:` but not `^data:image/`. -/
def s3 (a : Attr) : Bool :=
  let v := normalizeSpace a.value
  a.ns == "" &&
    ((a.name == "href" && (lowerPrefix "javascript:".toList v || lowerPrefix "vbscript:".toList v || lowerPrefix "data:".toList v)) ||
     (a.name == "src" && (lowerPrefix "javascript:".toList v || lowerPrefix "vbscript:".toList v ||
       (lowerPrefix "data:".toList v && !lowerPrefix "data:image/".toList v))))

mutual
/-- S1 drops the element, S2 (`@*[matches(local-name(), '^on', 'i')]`) and S3 the attribute. -/
def canonical : Node → List Node
  | .text s => [.text s]
  | .elem ns name attrs kids =>
    if ns == xhtmlNs && s1Names.contains name then []
    else [.elem ns name (attrs.filter (fun a => !(startsOn a.name || s3 a))) (canonicalList kids)]
def canonicalList : List Node → List Node
  | [] => []
  | k :: ks => canonical k ++ canonicalList ks
end

def svgScript : Node :=
  .elem svgNs "svg" [] [.elem svgNs "script" [] [.text "alert(document.domain)".toList]]

def splitScheme : Node :=
  .elem xhtmlNs "p" [] [.elem xhtmlNs "a" [⟨"", "href", "java\tscript:alert(document.domain)".toList⟩] [.text "link".toList]]

def xlinkHref : Node :=
  .elem svgNs "svg" [] [.elem svgNs "a" [⟨xlinkNs, "href", "javascript:alert(document.domain)".toList⟩] [.elem svgNs "text" [] [.text "link".toList]]]

theorem canonical_keeps_svg_script : runsList (canonical svgScript) = true := by decide

theorem canonical_keeps_split_scheme : runsList (canonical splitScheme) = true := by decide

theorem canonical_keeps_xlink_href : runsList (canonical xlinkHref) = true := by decide

/-- Rendering takes out all three. -/
theorem sanitize_takes_them_out : runsList (sanitize svgScript) = false ∧ runsList (sanitize splitScheme) = false ∧
    runsList (sanitize xlinkHref) = false := by decide

end LdhXslt
