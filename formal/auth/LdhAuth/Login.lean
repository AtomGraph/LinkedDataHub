/-
The OAuth callback's first login (`LoginBase.get`): what it writes into the root admin dataset, and so whom a later
token names. It reads the dataspace's own admin dataset only to find an account made there before accounts moved to
root, and writes nothing to it. Only the triples the token path reads are modelled: the account's `sioc:id`,
`lacl:issuer` and `sioc:account_of`.
-/
import LdhAuth.Theorems

namespace LdhAuth

open LdhHttp

/-- `findAgentByEmail`: `agentQuery`'s first row, an agent with the `foaf:mbox` in any admin graph. -/
def agentByMbox (V : Vocab) (fs : FinStore) (mbox : Node) : Option Node :=
  (fs.flatMap fun p => p.2.filterMap fun t => if t.p = V.foafMbox ∧ t.o = mbox then some t.s else none).head?

/-- The root admin dataset after a callback, on a dataspace with admin dataset `fs`, for a verified token of `iss`
and `sub`, with the `mailto:` of the email the provider's claims carry, if any, and whether they say the provider
verified it (`email_verified`). An address the provider has not verified counts as none. A subject with an account in
either dataset changes nothing (`isKnownSubject`); otherwise the new account, in a graph of its own in root, is the
account of the root's agent with that mailbox if there is one, else of a new agent. -/
def login (V : Vocab) (fs root : FinStore) (iss sub : Node) (email : Option Node) (verified : Bool)
    (accountDoc account newAgent : Node) : FinStore :=
  let mbox := if verified then email else none
  if (accountRows V fs iss sub).isEmpty ∧ (accountRows V root iss sub).isEmpty then
    let agent := match mbox.bind (agentByMbox V root) with
      | some a => a
      | none => newAgent
    (accountDoc, [⟨account, V.siocId, sub⟩, ⟨account, V.laclIssuer, iss⟩, ⟨account, V.siocAccountOf, agent⟩]) :: root
  else root

/-- **An unverified email claims nothing.** A first login whose provider has not verified the address it claims
writes what a login with no address writes: the account is a new agent's, whoever's `foaf:mbox` the address is.
Until the callback read `email_verified`, the account was linked to that agent, and a token of the subject
authenticated as it (`email_link_takeover`). -/
theorem unverified_email_ignored (V : Vocab) (fs root : FinStore) (iss sub : Node) (email : Option Node)
    (accountDoc account newAgent : Node) :
    login V fs root iss sub email false accountDoc account newAgent =
      login V fs root iss sub none true accountDoc account newAgent := by
  simp [login]

/-- **A verified email links the agent with that mailbox.** The first login of a subject the dataset has no account
for, whose provider verified an email that is the `foaf:mbox` of an existing agent, links the new account to that
agent: the provider vouches the subject holds the mailbox. -/
theorem verified_email_links {V : Vocab} {fs root : FinStore} {iss sub m a accountDoc account newAgent : Node}
    (hlocal : accountRows V fs iss sub = []) (hnew : accountRows V root iss sub = [])
    (ha : agentByMbox V root m = some a) :
    (account, a) ∈ accountRows V (login V fs root iss sub (some m) true accountDoc account newAgent) iss sub := by
  simp only [login, hlocal, hnew, List.isEmpty_nil, and_self, if_true, Option.bind_some, ha]
  simp only [accountRows, List.flatMap_cons, List.mem_append]
  left
  simp only [List.mem_filterMap]
  refine ⟨⟨account, V.siocAccountOf, a⟩, by simp [ha], ?_⟩
  simp

/-- **A known subject writes nothing.** A subject with an account the dataspace made before accounts moved to root
keeps it: the callback leaves the root admin dataset as it was, so no second agent is made. -/
theorem legacy_subject_unchanged {V : Vocab} {fs root : FinStore} {iss sub : Node} {email : Option Node}
    {verified : Bool} {accountDoc account newAgent : Node} (h : accountRows V fs iss sub ≠ []) :
    login V fs root iss sub email verified accountDoc account newAgent = root := by
  simp [login, List.isEmpty_iff, h]

end LdhAuth
