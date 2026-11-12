/-
What a server-side `document()` or `doc-available()` reaches: the resolver the platform gives Saxon,
`SameSiteSourceResolver` (writer/impl), over Web-Client's `RDFSourceResolver.resolve`.

The parent reads a cached or mapped graph locally; an `http` or `https` URI it fetches when `resolvingUncached` allows,
and otherwise answers an empty document; anything else it answers `null`, which hands the URI back to Saxon, and
Saxon opens it with whatever the JVM has a handler for - `file:` reads the server's files and `jar:http:` fetches
directly, past the egress proxy (`parent_hands_back`). The scheme is compared case-sensitively, so `HTTP:` is
anything else too. Rendering asks for such URIs whenever stored data names one: a resource's label is looked up in
its own document. The platform's resolver turns that `null` into an empty document:

* `resolve_confined`: no URI is handed back to Saxon, and only a same-site `http(s)` URI is fetched.
-/
namespace LdhXslt

inductive Source where
  /-- a cached or mapped graph, read from the repository -/
  | repository
  /-- fetched over HTTP by the platform's client, through the egress proxy -/
  | fetched
  | empty
  /-- `null`: Saxon resolves it itself -/
  | saxon
deriving DecidableEq, Repr

structure Site where
  cached : String → Bool
  mapped : String → Bool
  /-- `isSameSite(rootContextURI, uri)` -/
  sameSite : String → Bool
  /-- the parent's `isResolvingUncached()` -/
  uncached : Bool

/-- `uri.getScheme().equals("http") || uri.getScheme().equals("https")` -/
def httpScheme (scheme : String) : Bool := scheme == "http" || scheme == "https"

/-- `SameSiteSourceResolver.resolvingUncached` -/
def resolvingUncached (s : Site) (uri : String) : Bool := s.uncached && !s.mapped uri && s.sameSite uri

/-- `RDFSourceResolver.resolve`, with the subclass's `resolvingUncached`. -/
def parentResolve (s : Site) (scheme uri : String) : Source :=
  if s.cached uri || s.mapped uri then .repository
  else if httpScheme scheme then (if resolvingUncached s uri then .fetched else .empty)
  else .saxon

/-- `SameSiteSourceResolver.resolve` -/
def resolve (s : Site) (scheme uri : String) : Source :=
  match parentResolve s scheme uri with
  | .saxon => .empty
  | r => r

/-- Without the override, a URI that is not mapped or cached and not `http(s)` reaches Saxon. -/
theorem parent_hands_back (s : Site) (scheme uri : String) (hc : s.cached uri = false) (hm : s.mapped uri = false)
    (hs : httpScheme scheme = false) : parentResolve s scheme uri = .saxon := by
  simp [parentResolve, hc, hm, hs]

theorem resolve_confined (s : Site) (scheme uri : String) :
    resolve s scheme uri ≠ .saxon ∧
    (resolve s scheme uri = .fetched → httpScheme scheme = true ∧ s.sameSite uri = true) := by
  unfold resolve parentResolve
  by_cases hr : (s.cached uri || s.mapped uri) = true
  · simp [hr]
  · by_cases hh : httpScheme scheme = true
    · by_cases hu : resolvingUncached s uri = true
      · simp only [hr, hh, hu, if_true, if_false, Bool.false_eq_true]
        refine ⟨by simp, fun _ => ⟨trivial, ?_⟩⟩
        simp only [resolvingUncached, Bool.and_eq_true] at hu
        exact hu.2
      · simp [hr, hh, hu]
    · simp [hr, hh]

end LdhXslt
