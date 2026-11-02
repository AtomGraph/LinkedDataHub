/-
An authorized write: a request the decision allows, and the `Write` the graph store makes of it (`LdhHttp.Write`).
What the graph store's writes keep (containment, the hierarchy, the typing of documents) is theirs; what this file
adds is what follows for the authorization decision, which reads the stores they change.
-/
import LdhAcl.Model

namespace LdhAcl

open LdhHttp

/-- One authorized write by `agent`, from `st` to `st'`, on either dataspace's store. -/
structure Step (site : Site) (rd : Reader) (agent : Option Node) (st : Store) (req : Req) (st' : Store) : Prop where
  authorized : allowRequest site rd st agent req.method req.target
  write : Write site.toTree agent st req st'

theorem Step.frame {site rd agent st req st'} (h : Step site rd agent st req st')
    {y : Node} (hy : y ≠ req.target) : st' y = st y := h.write.frame hy

/-- **The invariants hold after every write.** -/
theorem Step.inv {site rd agent st req st'} (hs : Step site rd agent st req st') (h : Inv site.toTree st) :
    Inv site.toTree st' := hs.write.inv h

/-- **Every document stays typed with a hierarchy class.** -/
theorem Step.typed {site rd agent st req st'} (hs : Step site rd agent st req st') (h : Typed st) :
    Typed st' := hs.write.typed h

/-- Admin documents carry hierarchy classes only. -/
def AdminTyped (site : Site) (st : Store) : Prop :=
  ∀ x t, site.admin x → ownTypes st x t → hierClass t

/-- **Admin documents stay typed with hierarchy classes only.** -/
theorem Step.adminTyped {site rd agent st req st'} (hs : Step site rd agent st req st')
    (h : AdminTyped site st) : AdminTyped site st' := by
  intro x c hx ht
  rcases hs.write.ownTypes ht with ht | hc
  · exact h x c hx ht
  · exact hc

theorem Write.adminTyped {site : Site} {agent st req st'} (hw : Write site.toTree agent st req st')
    (h : AdminTyped site st) : AdminTyped site st' := by
  intro x c hx ht
  rcases hw.ownTypes ht with ht | hc
  · exact h x c hx ht
  · exact hc

end LdhAcl
