/-
The OAuth callback's first login (`LoginBase.get`): what it writes into the admin dataset, and so whom a later token
names. Only the triples the token path reads are modelled: the account's `sioc:id`, `lacl:issuer` and
`sioc:account_of`.
-/
import LdhAuth.Theorems

namespace LdhAuth

open LdhHttp

/-- `findAgentByEmail`: `agentQuery`'s first row, an agent with the `foaf:mbox` in any admin graph. -/
def agentByMbox (V : Vocab) (fs : FinStore) (mbox : Node) : Option Node :=
  (fs.flatMap fun p => p.2.filterMap fun t => if t.p = V.foafMbox ∧ t.o = mbox then some t.s else none).head?

/-- The admin dataset after a callback for a verified token of `iss` and `sub`, with the `mailto:` of the email
the provider's claims carry, if any. A subject with an account changes nothing; otherwise the new account, in a
graph of its own, is the account of the agent with that mailbox if there is one, else of a new agent. Nothing reads
`email_verified`. -/
def login (V : Vocab) (fs : FinStore) (iss sub : Node) (mbox : Option Node) (accountDoc account newAgent : Node) :
    FinStore :=
  if (accountRows V fs iss sub).isEmpty then
    let agent := match mbox.bind (agentByMbox V fs) with
      | some a => a
      | none => newAgent
    (accountDoc, [⟨account, V.siocId, sub⟩, ⟨account, V.laclIssuer, iss⟩, ⟨account, V.siocAccountOf, agent⟩]) :: fs
  else fs

/-- **An email claim takes over the agent with that mailbox.** The first login of a subject the dataset has no
account for, whose provider claims an email that is the `foaf:mbox` of an existing agent, links the new account to
that agent, whether or not the provider verified the address; a token of that subject then authenticates as the
agent. -/
theorem email_link_takeover {V : Vocab} {fs : FinStore} {iss sub m a accountDoc account newAgent : Node}
    (hnew : accountRows V fs iss sub = []) (ha : agentByMbox V fs m = some a) :
    (account, a) ∈ accountRows V (login V fs iss sub (some m) accountDoc account newAgent) iss sub := by
  simp only [login, hnew, List.isEmpty_nil, if_true, Option.bind_some, ha]
  simp only [accountRows, List.flatMap_cons, List.mem_append]
  left
  simp only [List.mem_filterMap]
  refine ⟨⟨account, V.siocAccountOf, a⟩, by simp [ha], ?_⟩
  simp

end LdhAuth
