/-
URIs as the client's stylesheets handle them: strings, cut and compared by XPath's string functions. Nothing here
parses a URI; each definition is the XPath expression it names, over a list of characters.
-/
namespace LdhClient

/-- A string as XPath's string functions see it. -/
abbrev Str := List Char

def http : Str := ['h', 't', 't', 'p', ':', '/', '/']
def https : Str := ['h', 't', 't', 'p', 's', ':', '/', '/']

/-- One scheme's alternative of `lds:origin`'s regex: the scheme, then `[^/]+`, then `.*$`, where `.` is any
character but a newline. -/
def originWith (sch u : Str) : Option Str :=
  if sch.isPrefixOf u then
    let rest := u.drop sch.length
    let auth := rest.takeWhile (· != '/')
    if auth.isEmpty || (rest.dropWhile (· != '/')).contains '\n' then none else some (sch ++ auth)
  else none

/-- `lds:origin`: `replace($uri, '^(https?://[^/]+).*$', '$1')`. A URI the regex does not match comes back
whole, as `replace` returns it. -/
def origin (u : Str) : Str :=
  match originWith https u with
  | some o => o
  | none => (originWith http u).getD u

/-- `substring-before($u, $c)` for a `$u` that contains `$c`. -/
def before (c : Char) (u : Str) : Str := u.takeWhile (· != c)

/-- `substring-after($u, $c)`: empty when `$u` does not contain `$c`. -/
def after (c : Char) (u : Str) : Str := (u.dropWhile (· != c)).drop 1

/-- Web-Client's `ac:absolute-path`: before the first `?`, else before the first `#`. -/
def absPath (u : Str) : Str :=
  if u.contains '?' then before '?' u else if u.contains '#' then before '#' u else u

/-- Web-Client's `ac:document-uri`: before the first `#`. -/
def docUri (u : Str) : Str := if u.contains '#' then before '#' u else u

/-- The query parameter maps `ldh:href` builds, kept abstract: what they hold does not reach the target's origin.
`string` is the query string `ac:build-uri` appends, empty for an empty map and starting with `?` otherwise. -/
structure Query where
  P : Type
  empty : P
  /-- `map{ 'uri': $uri }` merged with the caller's map, in that order -/
  withUri : Str → P → P
  /-- `map:merge(($parsed, $query-params), map{ 'duplicates': 'use-last' })` -/
  overlay : P → P → P
  /-- `ldh:parse-query-params` -/
  parse : Str → P
  string : P → Str
  string_shape : ∀ p, string p = [] ∨ ∃ s, string p = '?' :: s

/-- Web-Client's `ac:build-uri`: the path, then the query string. An empty path is falsy, and the query string
alone comes back, which is the same list. -/
def buildUri (Q : Query) (path : Str) (q : Q.P) : Str := path ++ Q.string q

end LdhClient
