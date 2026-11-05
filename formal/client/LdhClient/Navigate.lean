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

/-- The branch: a status from 400 on, but 401, 403 and 429, for an `http(s)` document that does not start with the
page's origin (`matches($doc-uri, '^https?://') and not(starts-with($doc-uri, lds:origin(ldh:request-uri())))`).
The window opens the document with the fragment of the page, or goes there when the popup is blocked:
`window.open($href, '_blank')`, else `location.assign`. -/
def fallback (page doc : Str) (status : Nat) (frag : Option Str) : Option Str :=
  if 400 ≤ status ∧ status ∉ [401, 403, 429] ∧ isWeb doc ∧ (origin page).isPrefixOf doc = false then
    some (doc ++ tail frag)
  else none

/-- **The window goes only to an `http(s)` URL.** Whatever document and status, the branch either leaves the window
alone or sends it to a URL starting with `http://` or `https://`: never a `javascript:`, `data:` or other URL the
browser would run in the page's origin. -/
theorem fallback_web {page doc : Str} {status : Nat} {frag : Option Str} {h : Str}
    (hf : fallback page doc status frag = some h) : isWeb h = true := by
  simp only [fallback] at hf
  split at hf
  · rename_i hc
    cases hf
    have keep : ∀ p : Str, p.isPrefixOf doc = true → p.isPrefixOf (doc ++ tail frag) = true := by
      intro p hp
      exact List.isPrefixOf_iff_prefix.2 ((List.isPrefixOf_iff_prefix.1 hp).trans (List.prefix_append _ _))
    have hw := hc.2.2.1
    simp only [isWeb, Bool.or_eq_true] at hw ⊢
    exact hw.elim (fun h => Or.inl (keep _ h)) (fun h => Or.inr (keep _ h))
  · cases hf

/-- **The window goes where an `http(s)` `?uri=` says.** A page loaded with `?uri=` naming an `http(s)` document not
on the page's origin, answered with any status the branch takes, opens the document as the parameter gives it. -/
theorem fallback_is_uri_param {page u : Str} {status : Nat} {frag : Option Str} (hs : 400 ≤ status)
    (hn : status ∉ [401, 403, 429]) (hw : isWeb (docUri u) = true)
    (ho : (origin page).isPrefixOf (docUri u) = false) :
    fallback page (pageDoc page (some u)) status frag = some (docUri u ++ tail frag) := by
  simp [fallback, pageDoc, hs, hn, hw, ho]

private def page : Str := "https://localhost:4443/?uri=javascript:alert(document.domain)".toList
private def script : Str := "javascript:alert(document.domain)".toList

/-- **`?uri=javascript:` is not run.** A link to `https://localhost:4443/?uri=javascript:alert(document.domain)`,
whatever the server answers, leaves the window where it is: the error is rendered in the pane. -/
theorem uri_param_script_refused (status : Nat) (frag : Option Str) :
    fallback page (pageDoc page (some script)) status frag = none := by
  have hw : isWeb (docUri script) = false := by decide
  simp [fallback, pageDoc, hw]

/-- The document a version restore writes (`client/memento.xsl`): `ac:absolute-path(ldh:request-uri())`, the
page's path, whichever pane the version history was opened from. -/
def restoreTarget (page : Str) : Str := absPath page

private def proxied : Str := "https://localhost:4443/?uri=https%3A%2F%2Fevil.example%2Fdoc".toList

/-- **A version restore writes the page's path, not the pane's document.** On the page that shows
`https://evil.example/doc` through the proxy, the restore puts the version it read, from a TimeMap the document's
response linked to, into `https://localhost:4443/`: the dataspace's root. -/
theorem restore_targets_page_path : restoreTarget proxied = "https://localhost:4443/".toList := by decide

end LdhClient
