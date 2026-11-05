/-
Where the client sends the window itself: the branch of `ldh:rdf-document-response` that opens an external document
whose RDF could not be retrieved (`client.xsl`).
-/
import LdhClient.Sites

namespace LdhClient

/-- The document a page loaded with `?uri=` shows: `ac:document-uri(ac:uri())`, the parameter's value without its
fragment, and the page's own path otherwise. -/
def pageDoc (page : Str) (uriParam : Option Str) : Str :=
  match uriParam with
  | some u => docUri u
  | none => absPath page

/-- The branch: a status from 400 on, but 401, 403 and 429, for a document that does not start with the page's
origin (`starts-with($doc-uri, lds:origin(ldh:request-uri()))`). The window opens the document with the fragment
of the page, or goes there when the popup is blocked: `window.open($href, '_blank')`, else `location.assign`. -/
def fallback (page doc : Str) (status : Nat) (frag : Option Str) : Option Str :=
  if 400 ≤ status ∧ status ∉ [401, 403, 429] ∧ (origin page).isPrefixOf doc = false then some (doc ++ tail frag)
  else none

/-- **The window goes where `?uri=` says.** A page loaded with `?uri=` whose document is not on the page's origin,
answered with any status the branch takes, opens the document as the parameter gives it, with no check of its
scheme. -/
theorem fallback_is_uri_param {page u : Str} {status : Nat} {frag : Option Str} (hs : 400 ≤ status)
    (hn : status ∉ [401, 403, 429]) (ho : (origin page).isPrefixOf (docUri u) = false) :
    fallback page (pageDoc page (some u)) status frag = some (docUri u ++ tail frag) := by
  simp [fallback, pageDoc, hs, hn, ho]

private def page : Str := "https://localhost:4443/?uri=javascript:alert(document.domain)".toList
private def script : Str := "javascript:alert(document.domain)".toList

/-- **`?uri=javascript:` is run.** A link to `https://localhost:4443/?uri=javascript:alert(document.domain)` whose
document the proxy answers with an error (a `javascript:` URI has no host, which `URLValidator` refuses) sends the
window to `javascript:alert(document.domain)`. Loaded from a link, the popup is blocked and `location.assign` runs
the script in the page's origin. -/
theorem uri_param_navigates_any_scheme (status : Nat) (hs : 400 ≤ status) (hn : status ∉ [401, 403, 429]) :
    fallback page (pageDoc page (some script)) status none = some script := by
  have ho : (origin page).isPrefixOf (docUri script) = false := by decide
  have := fallback_is_uri_param (frag := none) hs hn ho
  rw [this]
  have : docUri script = script := by decide
  rw [this]; simp [tail]

/-- The document a version restore writes (`client/memento.xsl`): `ac:absolute-path(ldh:request-uri())`, the
page's path, whichever pane the version history was opened from. -/
def restoreTarget (page : Str) : Str := absPath page

private def proxied : Str := "https://localhost:4443/?uri=https%3A%2F%2Fevil.example%2Fdoc".toList

/-- **A version restore writes the page's path, not the pane's document.** On the page that shows
`https://evil.example/doc` through the proxy, the restore puts the version it read, from a TimeMap the document's
response linked to, into `https://localhost:4443/`: the dataspace's root. -/
theorem restore_targets_page_path : restoreTarget proxied = "https://localhost:4443/".toList := by decide

end LdhClient
