/-
The pane a document is shown in, and the base it gives `lds:base()` (`client.xsl`, `client/functions.xsl`).

A pane is created for a document when no pane shows it or its origin. Its `data-base` is the document's own origin
when the response that brought it carries an `lds:dataspace` link, and it has none otherwise. `lds:base()` reads the
active pane's `data-base`, and falls back to the page's origin.
-/
import LdhClient.Href

namespace LdhClient

/-- A pane, as `ldh:TabPanel` stamps it: the document it shows and the `data-base` it was created with. A reused
pane keeps the base it was created with. -/
structure Pane where
  doc : Str
  base : Option Str

/-- `$tab-base` in `ldh:rdf-document-response`: `resolve-uri('/', lds:origin($doc-uri))` when the response's `Link`
names an `lds:dataspace`, whatever it names. -/
def tabBase (doc : Str) (dataspace : Bool) : Option Str :=
  if dataspace then some (origin doc ++ ['/']) else none

/-- The pane created for a document, from its response's `lds:dataspace` link. -/
def newPane (doc : Str) (dataspace : Bool) : Pane := ⟨doc, tabBase doc dataspace⟩

/-- `lds:base()`: the active pane's `data-base`, else `lds:origin(ldh:request-uri()) || '/'`. -/
def base (page : Str) (active : Option Pane) : Str :=
  match active.bind Pane.base with
  | some b => b
  | none => origin page ++ ['/']

/-- A pane whose base, if it has one, is on the page's origin. -/
def Pane.Local (page : Str) (p : Pane) : Prop := ∀ b, p.base = some b → (origin page ++ ['/']) <+: b

/-- **`lds:base()` is the page's origin on a local pane.** -/
theorem base_local {page : Str} {active : Option Pane} (h : ∀ p, active = some p → p.Local page) :
    (origin page ++ ['/']) <+: base page active := by
  unfold base
  split
  · rename_i b hb
    obtain ⟨p, hp, hpb⟩ := Option.bind_eq_some.1 hb
    exact h p hp b hpb
  · exact List.prefix_refl _

/-- **A pane is local when its document is.** A pane created for a document on the page's origin has a base on
the page's origin, or none. -/
theorem newPane_local {page doc : Str} {ds : Bool} (h : origin doc = origin page) : (newPane doc ds).Local page := by
  intro b hb
  simp only [newPane, tabBase] at hb
  split at hb
  · cases hb; rw [h]; exact List.prefix_refl _
  · cases hb

/-- **A proxied document's response moves `lds:base()`.** A document from another origin whose response names any
`lds:dataspace` gets a pane whose base is that origin. The Linked Data proxy forwards the origin's `Link` headers
as they are (`ProxyRequestFilter.overlayHeaders`), so the origin decides. -/
theorem newPane_base {page doc : Str} : base page (some (newPane doc true)) = origin doc ++ ['/'] := rfl

end LdhClient
