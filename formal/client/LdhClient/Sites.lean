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
  ⟨"client/chat.xsl", "ldh:chat-href('webalgebra')", .base "webalgebra".toList⟩,
  ⟨"client/chat.xsl", "ldh:chat-href('webalgebra/' || $id || '/result')", .base "webalgebra/{id}/result".toList⟩,
  ⟨"client/chat.xsl", "ldh:chat-href('webalgebra/answers')", .base "webalgebra/answers".toList⟩,
  ⟨"client/chat.xsl", "ldh:chat-href('webalgebra/plans')", .base "webalgebra/plans".toList⟩,
  ⟨"client/combobox.xsl", "$uri", .again⟩,
  ⟨"client/constructor.xsl", "$update?href", .again⟩,
  ⟨"client/memento.xsl", "$memento-uri", .given⟩,
  ⟨"client/memento.xsl", "$timemap-uri", .given⟩,
  ⟨"client/modal.xsl", "$endpoint", .base "sparql".toList⟩,
  ⟨"client/modal.xsl", "$settings-uri", .shell "settings".toList⟩,
  ⟨"client/modal.xsl", "resolve-uri('clear', lds:base())", .base "clear".toList⟩
]

/-- A site whose target the page's origin does not bound: `lds:base()` without `ldh:href`, or a given URI. -/
def Site.unbounded (s : Site) : Bool :=
  match s.target with
  | .base _ | .given => true
  | _ => false

/-- Eight sites leave the page's origin whenever their base or their URI does: the assistant's four, the ontology
import's query, the namespace `clear`, and the version history's two. -/
theorem unbounded_sites : (sites.filter Site.unbounded).length = 8 := by decide

/-- **A shell site stays on the page's origin.** -/
theorem shell_confined (page path : Str) (active : Option Pane) :
    ∀ r, (Target.shell path).uri page active = some r → SameOrigin page r := by
  intro r h; cases h; left; exact ⟨path, by simp⟩

/-- **A base site stays on the page's origin while the active pane is local.** -/
theorem base_confined {page path : Str} {active : Option Pane} (h : ∀ p, active = some p → p.Local page) :
    ∀ r, (Target.base path).uri page active = some r → SameOrigin page r := by
  intro r hr; cases hr; left; exact (base_local h).trans (List.prefix_append _ _)

private def page : Str := "https://localhost:4443/?uri=https%3A%2F%2Fevil.example%2F".toList
private def doc : Str := "https://evil.example/".toList

/-- **The assistant follows a proxied document's `lds:dataspace` off the page's origin.** On the page that shows
`https://evil.example/` through the proxy, a response for it naming any `lds:dataspace` makes the assistant post the
question, the document, the endpoint and the last turns to `https://evil.example/webalgebra/plans`. -/
theorem proxied_link_moves_base :
    (Target.base "webalgebra/plans".toList).uri page (some (newPane doc true)) =
      some "https://evil.example/webalgebra/plans".toList ∧
    ¬ SameOrigin page "https://evil.example/webalgebra/plans".toList := by
  refine ⟨by decide, ?_⟩
  intro h
  rcases h with h | h | h | h
  · have : (origin page ++ ['/']).isPrefixOf "https://evil.example/webalgebra/plans".toList = false := by decide
    rw [List.isPrefixOf_iff_prefix.symm] at h
    rw [this] at h
    cases h
  all_goals (revert h; decide)

end LdhClient
