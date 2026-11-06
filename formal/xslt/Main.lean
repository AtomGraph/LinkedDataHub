/-
`ldh-xslt`: the model's answers, for the workflow to check the stylesheets against.

    ldh-xslt sanitize-cases    the sanitize cases: LITERAL<TAB>RENDERED, one per line
    ldh-xslt canonical-cases   the canonical form's former counterexamples, in the same shape

LITERAL is an element serialized as XML, and RENDERED what the model renders it to, as a projection both sides can
print: an element is `(NS NAME @ANS ANAME="VALUE"... CHILD...)` with its attributes ordered by namespace and name, a
text node is its quoted string. `sanitize-cases.xsl` renders the same literals with the stylesheets' own templates.

What this file adds to the proven model is unproven and small: the serializer, the projection, and the cases.
-/
import LdhXslt

open LdhXslt

def escapeWith (attr : Bool) : Char → String
  | '&' => "&amp;"
  | '<' => "&lt;"
  | '>' => "&gt;"
  | '"' => if attr then "&quot;" else "\""
  | '\t' => if attr then "&#9;" else "\t"
  | '\n' => if attr then "&#10;" else "\n"
  | '\r' => "&#13;"
  | c => c.toString

def escapeXml (attr : Bool) (s : Str) : String := String.join (s.map (escapeWith attr))

/-- Every namespace is declared with a prefix, on the element that uses it, so no default namespace is ever in scope. -/
partial def toXml : Node → String
  | .text s => escapeXml false s
  | .elem ns name attrs kids =>
    let qname := if ns.isEmpty then name else "e:" ++ name
    let decl := if ns.isEmpty then "" else s!" xmlns:e=\"{ns}\""
    let attrsXml := String.join <| (attrs.enum.map fun (i, a) =>
      if a.ns.isEmpty then s!" {a.name}=\"{escapeXml true a.value}\""
      else s!" a{i}:{a.name}=\"{escapeXml true a.value}\" xmlns:a{i}=\"{a.ns}\"")
    s!"<{qname}{decl}{attrsXml}>{String.join (kids.map toXml)}</{qname}>"

def quote (s : Str) : String :=
  "\"" ++ String.join (s.map fun
    | '\\' => "\\\\"
    | '"' => "\\\""
    | '\t' => "\\t"
    | '\n' => "\\n"
    | '\r' => "\\r"
    | c => c.toString) ++ "\""

partial def project : Node → String
  | .text s => quote s
  | .elem ns name attrs kids =>
    "(" ++ ns ++ " " ++ name ++ String.join (attrs.map fun a => s!" @{a.ns} {a.name}={quote a.value}") ++
      String.join (kids.map fun k => " " ++ project k) ++ ")"

def x (name : String) (attrs : List Attr) (kids : List Node) : Node := .elem xhtmlNs name attrs kids
def s (name : String) (attrs : List Attr) (kids : List Node) : Node := .elem svgNs name attrs kids
def t (v : String) : Node := .text v.toList
def a (name v : String) : Attr := ⟨"", name, v.toList⟩

def sanitizeCases : List Node := [
  x "div" [] [x "p" [] [t "plain ", x "strong" [] [t "text"]]],
  x "div" [] [x "script" [] [t "alert(document.domain)"], x "p" [] [t "after"]],
  x "div" [] [.elem "" "script" [] [t "alert(document.domain)"]],
  x "div" [] [s "svg" [] [s "script" [] [t "alert(document.domain)"], s "circle" [a "r" "1"] []]],
  x "div" [] [x "img" [a "onerror" "alert(document.domain)", a "src" "x.png"] []],
  x "div" [] [x "p" [a "ONCLICK" "alert(document.domain)", a "class" "c"] [t "x"]],
  x "div" [] [x "a" [a "href" "javascript:alert(document.domain)"] [t "link"]],
  x "div" [] [x "a" [a "href" "java\tscript:alert(document.domain)"] [t "link"]],
  x "div" [] [x "a" [a "href" " \n JavaScript:alert(document.domain)"] [t "link"]],
  x "div" [] [x "a" [a "href" "vbscript:msgbox(1)"] [t "link"]],
  x "div" [] [x "a" [a "href" "data:text/html,<script>alert(1)</script>"] [t "link"]],
  x "div" [] [x "img" [a "src" "data:image/png;base64,AAAA"] []],
  x "div" [] [x "img" [a "src" "data:text/html,x"] []],
  x "div" [] [x "a" [a "href" "data:image/png;base64,AAAA"] [t "link"]],
  x "div" [] [x "a" [a "href" "https://example.org/a?b=javascript:"] [t "link"]],
  x "div" [] [x "a" [a "href" "/relative/javascript:x"] [t "link"]],
  x "div" [] [x "a" [a "href" "#section"] [t "link"]],
  x "div" [] [s "svg" [] [s "a" [⟨xlinkNs, "href", "javascript:alert(document.domain)".toList⟩] [s "text" [] [t "link"]]]],
  x "div" [] [s "svg" [] [s "set" [a "attributeName" "href", a "to" "javascript:alert(1)"] []]],
  x "div" [] [x "iframe" [a "src" "https://www.youtube.com/embed/x"] []],
  x "div" [] [x "iframe" [a "srcdoc" "<script>alert(1)</script>"] []],
  x "div" [] [x "iframe" [a "src" "javascript:alert(document.domain)"] []],
  x "div" [] [x "form" [a "action" "javascript:alert(1)"] [x "button" [a "formaction" "javascript:alert(1)"] [t "go"]]],
  x "div" [] [x "form" [a "action" "?forClass=x", a "method" "post"] [x "input" [a "name" "rdf", a "type" "hidden"] []]],
  x "div" [] [x "object" [a "data" "x.swf"] [], x "embed" [a "src" "x.swf"] [], x "base" [a "href" "https://evil.example/"] []],
  x "div" [] [x "meta" [a "content" "0;url=https://evil.example/", a "http-equiv" "refresh"] [], x "link" [a "href" "x.css", a "rel" "stylesheet"] []],
  x "div" [] [x "style" [] [t "body { display: none }"], x "p" [a "style" "color: red"] [t "kept"]],
  x "div" [] [x "video" [a "poster" "javascript:alert(1)"] []],
  x "div" [] [x "pre" [] [t "<script>alert(1)</script> & \"quoted\""]],
  x "div" [] [x "h2" [a "id" "s", a "onmouseover" "alert(1)"] [t "Heading"]]
]

/-- The canonical form's former counterexamples, each with something in it that runs. -/
def canonicalCases : List Node := [svgScript, splitScheme, xlinkHref]

def main : List String → IO UInt32
  | ["sanitize-cases"] => do
    for n in sanitizeCases do
      IO.println s!"{toXml n}\t{" ".intercalate ((sanitize n).map project)}"
    return 0
  | ["canonical-cases"] => do
    for n in canonicalCases do
      IO.println s!"{toXml n}\t{" ".intercalate ((canonical n).map project)}"
    return 0
  | _ => do
    IO.eprintln "usage: ldh-xslt sanitize-cases | canonical-cases"
    return 2
