/-
The request sites of the client's stylesheets whose target is not built by `ldh:href` where they stand: every other
site's target is `ldh:href`'s, and `href_same_origin` covers it. `sites.py` reads the same list off the stylesheets,
and the workflow diffs it against `ldh-client sites`, so a site added or changed fails until it is classified here.
-/
import LdhClient.Pane

namespace LdhClient

/-- How a site builds its target. -/
inductive Target where
  /-- `ldh:href(…)` at the site: never in the list below -/
  | href
  /-- a target an `ldh:href` built earlier, passed on to the site: the request being retried, a parameter -/
  | again
  /-- `resolve-uri(path, lds:origin(ldh:request-uri()) || '/')` -/
  | shell (path : Str)
  /-- `resolve-uri(path, lds:base())`, not through `ldh:href` -/
  | base (path : Str)
  /-- a URI the page or a response carried, used as it is -/
  | given
  /-- a URI a response carried: as it is when `ldh:is-local`, else `ldh:href`'s, which `localOrHref` is -/
  | localOrHref
  deriving DecidableEq

/-- What a target is on the page `page` with the active pane `active`, for a relative `path` with no scheme, no
leading `/` and no query: `resolve-uri` appends it to a base ending in `/`. `href` and `again` are `ldh:href`'s,
and `given` is anything. -/
def Target.uri (page : Str) (active : Option Pane) : Target → Option Str
  | .shell p => some (origin page ++ '/' :: p)
  | .base p => some (LdhClient.base page active ++ p)
  | _ => none

structure Site where
  file : String
  expr : String
  target : Target

def sites : List Site := [
  ⟨"client/block/object.xsl", "$context('request')?href", .again⟩,
  ⟨"client/chat.xsl", "ldh:webalgebra-href('webalgebra/answers')", .shell "webalgebra/answers".toList⟩,
  ⟨"client/chat.xsl", "ldh:webalgebra-href('webalgebra/plans')", .shell "webalgebra/plans".toList⟩,
  ⟨"client/combobox.xsl", "$uri", .again⟩,
  ⟨"client/constructor.xsl", "$update?href", .again⟩,
  ⟨"client/memento.xsl", "if (ldh:is-local($timemap-uri)) then $timemap-uri else ldh:href($timemap-uri)", .localOrHref⟩,
  ⟨"client/modal.xsl", "$settings-uri", .shell "settings".toList⟩,
  ⟨"client/webalgebra.xsl", "ldh:webalgebra-href('webalgebra')", .shell "webalgebra".toList⟩,
  ⟨"client/webalgebra.xsl", "ldh:webalgebra-href('webalgebra/' || $id || '/result')", .shell "webalgebra/{id}/result".toList⟩
]

/-- A site whose target the page's origin does not bound: `lds:base()` without `ldh:href`, or a given URI. -/
def Site.unbounded (s : Site) : Bool :=
  match s.target with
  | .base _ | .given => true
  | _ => false

/-- No site is unbounded: every one is on the page's origin or is `ldh:href`'s. -/
theorem unbounded_sites : (sites.filter Site.unbounded).length = 0 := by decide

/-- **A shell site stays on the page's origin.** -/
theorem shell_confined (page path : Str) (active : Option Pane) :
    ∀ r, (Target.shell path).uri page active = some r → SameOrigin page r := by
  intro r h; cases h; left; exact ⟨path, by simp⟩

/-- **A base site stays on the page's origin while the active pane is local.** -/
theorem base_confined {page path : Str} {active : Option Pane} (h : ∀ p, active = some p → p.Local page) :
    ∀ r, (Target.base path).uri page active = some r → SameOrigin page r := by
  intro r hr; cases hr; left; exact (base_local h).trans (List.prefix_append _ _)

/-- `if (ldh:is-local($u)) then $u else ldh:href($u)`. -/
def localOrHref (Q : Query) (page u : Str) : Option Str :=
  if isLocal page u then some u else href Q page (some u) Q.empty none

/-- **A local URI as it is, or `ldh:href`'s, stays on the page's origin.** -/
theorem localOrHref_same_origin (Q : Query) {page : Str} (hp : Page page) (u : Str) {r : Str}
    (h : localOrHref Q page u = some r) : SameOrigin page r := by
  unfold localOrHref at h
  split at h
  · rename_i hl
    cases h
    exact Or.inl (List.isPrefixOf_iff_prefix.1 hl)
  · exact href_same_origin Q hp _ _ _ h

/-- **Every request site stays on the page's origin**, whatever pane is active: a shell site by `shell_confined`,
an `again` site is a target `ldh:href` built, which `href_same_origin` covers, and the TimeMap's is
`localOrHref_same_origin`'s. -/
theorem sites_confined (page : Str) (active : Option Pane) :
    ∀ s ∈ sites, ∀ r, s.target.uri page active = some r → SameOrigin page r := by
  intro s hs r hr
  simp only [sites, List.mem_cons, List.mem_nil_iff, or_false] at hs
  rcases hs with rfl | rfl | rfl | rfl | rfl | rfl | rfl | rfl | rfl <;>
    first | exact shell_confined page _ active r hr | cases hr

private def page : Str := "https://localhost:4443/?uri=https%3A%2F%2Fevil.example%2F".toList
private def doc : Str := "https://evil.example/".toList

/-- **The assistant stays on the page's origin on a proxied pane.** On the page that shows `https://evil.example/`
through the proxy, a response naming an `lds:dataspace` still moves `lds:base()` there (`newPane_base`), and the
assistant's requests stay on `https://localhost:4443/`. Until `ldh:webalgebra-href` (then `ldh:chat-href`, now shared
with the actions in `client/webalgebra.xsl`) resolved against the page's origin they
followed `lds:base()`: the question, the document, the endpoint and the last turns went to
`https://evil.example/webalgebra/plans` (`proxied_link_moves_base`). -/
theorem proxied_link_keeps_chat :
    (Target.shell "webalgebra/plans".toList).uri page (some (newPane doc true)) =
      some "https://localhost:4443/webalgebra/plans".toList ∧
    LdhClient.base page (some (newPane doc true)) = "https://evil.example/".toList := by
  decide

end LdhClient
