/-
What the authorization decision guarantees.
-/
import LdhAcl.Step

namespace LdhAcl

/-! ## Modes -/

/-- **`acl:Control` is inert.** It covers no mode a request requires: `allowRequest` asks only for
`acl:Read`, `acl:Append` and `acl:Write`. -/
theorem control_inert {m : Mode} (hm : m ≠ .control) : ¬ Mode.covers .control m := by
  rintro (h | ⟨h, _⟩)
  · exact hm h.symm
  · cases h

/-! ## Monotonicity -/

/-- **Monotonicity.** More authorizations, or more memberships, never take access away. Union semantics
for `acl:default` is what keeps this true: no grant overrides another. -/
theorem grantWith_mono {A A' : Auth → Prop} {M M' : Node → Node → Prop} {sub look agent m}
    (hA : ∀ au, A au → A' au) (hM : ∀ g a, M g a → M' g a)
    (h : grantWith A M sub look agent m) : grantWith A' M' sub look agent m := by
  obtain ⟨au, hau, hp, hc, hm⟩ := h
  refine ⟨au, hA _ hau, ?_, hc, hm⟩
  cases agent with
  | none => exact hp
  | some a =>
    rcases hp with h | ⟨grp, hg, hmem⟩ | h | h | h
    · exact Or.inl h
    · exact Or.inr (Or.inl ⟨grp, hg, hM _ _ hmem⟩)
    · exact Or.inr (Or.inr (Or.inl h))
    · exact Or.inr (Or.inr (Or.inr (Or.inl h)))
    · exact Or.inr (Or.inr (Or.inr (Or.inr h)))

/-! ## What the target part means -/

/-- **The lookup is WAC.** Matching the tagged rows is exactly: the document is named, or one of its
ancestors carries a default grant, or one of its own types is a subclass of a granted class. -/
theorem covers_context {au : Auth} {sub st x} :
    au.covers sub (context st x) ↔
      x ∈ au.accessTo ∨ (∃ c ∈ au.default, ancestor st x c) ∨
      (∃ c ∈ au.accessToClass, ∃ t, ownTypes st x t ∧ sub t c) := by
  constructor
  · rintro ⟨r, t, hl, hm⟩
    cases r with
    | accessTo => simp [context] at hl; subst hl; exact Or.inl hm
    | default => exact Or.inr (Or.inl ⟨t, hm, hl⟩)
    | accessToClass =>
      obtain ⟨c, hc, hs⟩ := hm
      exact Or.inr (Or.inr ⟨c, hc, t, hl, hs⟩)
    | owner => exact hm.elim
  · rintro (h | ⟨c, hc, ha⟩ | ⟨c, hc, t, ht, hs⟩)
    · exact ⟨.accessTo, x, rfl, h⟩
    · exact ⟨.default, c, ha, hc⟩
    · exact ⟨.accessToClass, t, ht, c, hc, hs⟩

/-- `UNDEF` joins with any binding: the cell of an untagged `VALUES` row a variable leaves unbound. -/
def joins (v : Option Node) (n : Node) : Prop := v = none ∨ v = some n

/-- The target part over an untagged `VALUES (?Type ?Ancestor)` table, the shape the lookup does *not* use.
A types-only row leaves `?Ancestor` as `UNDEF`. -/
def Auth.coversUntagged (au : Auth) (sub : Node → Node → Prop) (x : Node)
    (rows : List (Option Node × Option Node)) : Prop :=
  x ∈ au.accessTo ∨ ∃ row ∈ rows,
    (∃ c ∈ au.accessToClass, ∃ t, joins row.1 t ∧ sub t c) ∨ (∃ c ∈ au.default, joins row.2 c)

/-- **An untagged table fails open.** A document with a type and no ancestors yields the row
`(type, UNDEF)`, which joins any `acl:default` grant: the authorization matches a document that is not
below the container it names. The tagged rows bind both columns, so no row joins a branch it was not
meant for. -/
theorem untagged_fails_open :
    ∃ (au : Auth) (sub : Node → Node → Prop) (x t : Node) (look : Rel → Node → Prop),
      (∀ r n, look r n ↔ (r = .accessTo ∧ n = x) ∨ (r = .accessToClass ∧ n = t)) ∧
      au.coversUntagged sub x [(some t, none)] ∧ ¬ au.covers sub look := by
  let au : Auth := ⟨[], [], [.anyone], [.read], [], [.iri 2], []⟩
  refine ⟨au, Eq, .iri 0, .iri 1, fun r n => (r = .accessTo ∧ n = .iri 0) ∨ (r = .accessToClass ∧ n = .iri 1),
    fun _ _ => Iff.rfl, ?_, ?_⟩
  · exact Or.inr ⟨_, List.Mem.head _, Or.inr ⟨.iri 2, List.Mem.head _, Or.inl rfl⟩⟩
  · rintro ⟨r, n, hl, hm⟩
    rcases hl with ⟨rfl, _⟩ | ⟨rfl, _⟩
    · simp [Auth.matchRow, au] at hm
    · simp [Auth.matchRow, au] at hm

/-! ## Ancestry through the union graph -/

/-- **Under the write rule, the union graph's containment is the own graph's.** -/
theorem parentU_iff {st : Store} (h : OwnGraphContainment st) {d p : Node} :
    parentU st d p ↔ parentO st d p := by
  constructor
  · rintro ⟨y, g, hy, hc⟩
    have hs : d = y := by
      rcases hc with hc | hc
      · exact h y g _ hy hc (Or.inl rfl)
      · exact h y g _ hy hc (Or.inr rfl)
    subst hs; exact ⟨g, hy, hc⟩
  · rintro ⟨g, hg, hc⟩; exact ⟨d, g, hg, hc⟩

/-- Ancestors found through the union graph are on the URI-parent chain. -/
theorem ancestor_chain {site st} (h : Inv site st) {x a : Node} (ha : ancestor st x a) :
    site.chain x a := by
  induction ha with
  | step hr =>
    obtain ⟨g, hg, hc⟩ := (parentU_iff h.own).1 hr
    obtain ⟨hn, hp⟩ := h.exact _ _ _ hg hc
    exact .step ⟨hn, hp⟩
  | trans hr _ ih =>
    obtain ⟨g, hg, hc⟩ := (parentU_iff h.own).1 hr
    obtain ⟨hn, hp⟩ := h.exact _ _ _ hg hc
    exact .trans ⟨hn, hp⟩ ih

/-- A node the store does not have has no ancestors: nothing outside its own graph can give it any. -/
theorem ancestor_absent {site st} (h : Inv site st) {x a : Node} (hx : ¬ present st x) :
    ¬ ancestor st x a := by
  intro ha
  cases ha with
  | step hr | trans hr _ =>
    obtain ⟨g, hg, _⟩ := (parentU_iff h.own).1 hr
    exact hx ⟨g, hg⟩

/-- A present document's ancestors are exactly its URI-parent chain. -/
theorem ancestor_iff_chain {site st} (h : Inv site st) {x a : Node} (hx : present st x) :
    ancestor st x a ↔ site.chain x a := by
  refine ⟨ancestor_chain h, fun hc => ?_⟩
  induction hc with
  | @step d p hr =>
    obtain ⟨hn, rfl⟩ := hr
    obtain ⟨g, hg⟩ := hx
    exact .step ((parentU_iff h.own).2 ⟨g, hg, h.contained d g hg hn⟩)
  | @trans d p c hr _ ih =>
    obtain ⟨hn, rfl⟩ := hr
    obtain ⟨g, hg⟩ := hx
    exact .trans ((parentU_iff h.own).2 ⟨g, hg, h.contained d g hg hn⟩) (ih (h.hier d ⟨g, hg⟩ hn))

/-- **Ancestry is a function of presence.** Under the invariants, what the union-graph path finds for `x`
depends on nothing but whether `x` is in the store. -/
theorem ancestor_iff {site st} (h : Inv site st) {x a : Node} :
    ancestor st x a ↔ present st x ∧ site.chain x a := by
  by_cases hx : present st x
  · rw [ancestor_iff_chain h hx]; exact ⟨fun hc => ⟨hx, hc⟩, fun ⟨_, hc⟩ => hc⟩
  · exact ⟨fun ha => absurd ha (ancestor_absent h hx), fun ⟨hp, _⟩ => absurd hp hx⟩

/-- **Ancestry is stable.** A write leaves the ancestors of every document that is present before and
after it as they were. -/
theorem ancestor_stable {site rd agent st req st'} (hs : Step site rd agent st req st') (h : Inv site st)
    {x a : Node} (hx : present st x) (hx' : present st' x) :
    ancestor st' x a ↔ ancestor st x a := by
  rw [ancestor_iff_chain (hs.inv h) hx', ancestor_iff_chain h hx]

/-! ## Locality -/

/-- **The lookup is local.** Under the invariants, everything the lookup returns for `x` is read from
`x`'s own graph. -/
theorem context_local {site st st'} (h : Inv site st) (h' : Inv site st') {x : Node}
    (hx : st' x = st x) : context st' x = context st x := by
  have hp : present st' x ↔ present st x := by simp [present, hx]
  funext r n
  cases r with
  | accessTo => rfl
  | default =>
    simp only [context]
    rw [ancestor_iff h', ancestor_iff h, hp]
  | accessToClass => simp [context, ownTypes, hx]
  | owner => simp [context, owner, hx]

/-- The authorizations and memberships in force are read from admin graphs only. -/
theorem acl_local {site rd} {st st' : Store} (h : ∀ d, site.admin d → st' d = st d) :
    authIn site rd st' = authIn site rd st ∧ memberIn site rd st' = memberIn site rd st := by
  constructor
  · funext au
    apply propext
    constructor
    · rintro ⟨d, g, hd, hg, ha⟩; exact ⟨d, g, hd, by rw [← h d hd]; exact hg, ha⟩
    · rintro ⟨d, g, hd, hg, ha⟩; exact ⟨d, g, hd, by rw [h d hd]; exact hg, ha⟩
  · funext grp a
    apply propext
    constructor
    · rintro ⟨d, g, hd, hg, ha⟩; exact ⟨d, g, hd, by rw [← h d hd]; exact hg, ha⟩
    · rintro ⟨d, g, hd, hg, ha⟩; exact ⟨d, g, hd, by rw [h d hd]; exact hg, ha⟩

/-- **A write to an end-user document changes no authorization and no membership.** -/
theorem endUser_step_preserves_acl {site rd agent st req st'} (hs : Step site rd agent st req st')
    (hx : ¬ site.admin req.target) :
    authIn site rd st' = authIn site rd st ∧ memberIn site rd st' = memberIn site rd st :=
  acl_local fun _ hd => hs.frame fun e => hx (e ▸ hd)

/-- **A write to an end-user document changes no decision about any other document.** Together with
`endUser_step_preserves_acl`, every change of access to a document other than the one written goes through
a write to the admin dataspace. -/
theorem endUser_step_preserves_other_grants {site rd agent st req st'}
    (hs : Step site rd agent st req st') (h : Inv site st) (hx : ¬ site.admin req.target)
    {y : Node} (hy : y ≠ req.target) {agent' m} :
    grant site rd st' agent' m y ↔ grant site rd st agent' m y := by
  obtain ⟨hA, hM⟩ := endUser_step_preserves_acl hs hx
  simp only [grant, hA, hM, context_local h (hs.inv h) (hs.frame hy)]

/-! ## The admin role is derived -/

/-- The reader can find any authorization in a graph that contains its description, and the description
states no ownership or containment, which the store would strip or refuse, and types the document with a
hierarchy class and nothing else, as the store requires. -/
def Reader.Expressive (rd : Reader) : Prop :=
  ∀ d au, ∃ p : Graph, (∀ t, p t → ¬ ownership d t ∧ ¬ isContainment t) ∧ HierTypes d p ∧ TypedBy d p ∧
    ∀ g : Graph, (∀ t, p t → g t) → rd.auths d g au

/-- **acl:Write on any admin document is the admin role.** An agent the decision lets `PUT` an existing
admin document can put any authorization in force, for any agent, mode and target. No mode or class
marks an admin: whoever may write the admin dataspace is one. -/
theorem admin_write_grants_anything {site rd agent st d g} (hex : rd.Expressive) (hd : site.admin d)
    (hg : st d = some g) (ha : allowRequest site rd st agent .put d) (au : Auth) :
    ∃ p st', Step site rd agent st (.put d p false) st' ∧ authIn site rd st' au := by
  obtain ⟨p, hp, hty, htb, hread⟩ := hex d au
  let g' : Graph := fun t =>
    (p t ∧ ¬ ownership d t ∧ ¬ containment d t) ∨ containedIn site d t ∨ (g t ∧ ownership d t) ∨
      itemTyped site d p t
  have hstep : Step site rd agent st (.put d p false) (st.set d (some g')) :=
    Step.putExisting ha hg rfl (fun t ht hc => absurd hc (hp t ht).2) hty fun _ => htb
  refine ⟨p, _, hstep, d, g', hd, by simp [Store.set], hread _ fun t ht => Or.inl ⟨ht, (hp t ht).1, ?_⟩⟩
  rintro ⟨_, hc⟩; exact (hp t ht).2 hc

/-! ## Dataspace confinement -/

/-- An authorization scoped to the end-user dataspace: it names no admin node, gives no default on an admin
container, and grants no class that a hierarchy class is a subclass of. -/
def EndUserOnly (site : Site) (sub : Node → Node → Prop) (au : Auth) : Prop :=
  (∀ t ∈ au.accessTo, ¬ site.admin t) ∧ (∀ c ∈ au.default, ¬ site.admin c) ∧
  ∀ c ∈ au.accessToClass, ∀ t, hierClass t → sub t c → False

theorem chain_admin {site : Site} {d c : Node} (h : site.chain d c) : (site.admin c ↔ site.admin d) := by
  induction h with
  | step hr =>
    obtain ⟨hn, rfl⟩ := hr
    exact site.parent_admin _ (fun e => hn (Or.inl e)) (fun e => hn (Or.inr e))
  | trans hr _ ih =>
    obtain ⟨hn, rfl⟩ := hr
    exact ih.trans (site.parent_admin _ (fun e => hn (Or.inl e)) (fun e => hn (Or.inr e)))

/-- **Dataspace confinement.** An authorization scoped to the end-user dataspace covers no admin document.
`make-public` and the owner-access authorization are of that kind. -/
theorem endUserOnly_confined {site : Site} {rd : Reader} {st : Store} (h : Inv site st) (ht : AdminTyped site st) {au : Auth}
    (hau : EndUserOnly site rd.sub au) {x : Node} (hx : site.admin x) :
    ¬ au.covers rd.sub (context st x) := by
  rw [covers_context]
  rintro (hm | ⟨c, hc, ha⟩ | ⟨c, hc, t, hty, hs⟩)
  · exact hau.1 x hm hx
  · exact hau.2.1 c hc ((chain_admin (ancestor_chain h ha)).2 hx)
  · exact hau.2.2 c hc t (ht x t hx hty) hs

/-- **Access to the admin dataspace comes only from authorizations scoped into it.** Any request the
decision allows on an admin node, including a create below an admin container, is allowed by an
authorization in force that is not scoped to the end-user dataspace. -/
theorem admin_allow_needs_admin_scope {site rd st agent isPut m x} (h : Inv site st)
    (ht : AdminTyped site st) (hx : site.admin x) (ha : allow site rd st agent isPut m x) :
    ∃ au, authIn site rd st au ∧ ¬ EndUserOnly site rd.sub au := by
  have viaAdmin : ∀ y, site.admin y → grant site rd st agent m y →
      ∃ au, authIn site rd st au ∧ ¬ EndUserOnly site rd.sub au := by
    rintro y hy ⟨au, hau, _, hc, _⟩
    exact ⟨au, hau, fun he => endUserOnly_confined h ht he hy hc⟩
  rcases ha with ⟨_, hg⟩ | ⟨hn, _, _, hg⟩
  · exact viaAdmin x hx hg
  · have hnr : ¬ site.isRoot x := by
      rintro (rfl | rfl)
      · exact hn h.roots.1
      · exact hn h.roots.2
    refine viaAdmin _ ?_ hg
    exact (site.parent_admin x (fun e => hnr (Or.inl e)) (fun e => hnr (Or.inr e))).2 hx

/-! ## Ownership -/

/-- **Ownership confinement.** Whoever owns a document after a write owned it before, or created it with
that write. `lacl:OwnerAgent` membership is therefore fixed for the life of a document. -/
theorem owner_confined {site rd agent st req st'} (hs : Step site rd agent st req st')
    {y b : Node} (ho : owner st' y b) :
    owner st y b ∨ (y = req.target ∧ st y = none ∧ agent = some b) := by
  by_cases hy : y = req.target
  · subst hy
    cases hs with
    | post _ hg =>
      obtain ⟨g', hg', hb⟩ := ho
      simp [Store.set, Req.target] at hg'
      subst hg'
      rcases hb with hb | ⟨_, hno, _⟩
      · exact Or.inl ⟨_, hg, hb⟩
      · exact absurd ⟨rfl, Or.inl rfl⟩ hno
    | putExisting _ hg _ =>
      obtain ⟨g', hg', hb⟩ := ho
      simp [Store.set, Req.target] at hg'
      subst hg'
      rcases hb with ⟨_, hno, _⟩ | ⟨_, _, hp, _⟩ | ⟨hb, _⟩ | ⟨_, _, he⟩
      · exact absurd ⟨rfl, Or.inl rfl⟩ hno
      · rcases hp with hp | hp <;> cases hp
      · exact Or.inl ⟨_, hg, hb⟩
      · cases he
    | putNew _ hn =>
      obtain ⟨g', hg', hb⟩ := ho
      simp [Store.set, Req.target] at hg'
      subst hg'
      rcases hb with ⟨_, hno, _⟩ | ⟨_, _, hp, _⟩ | ⟨a, ha, _, _, hab⟩ | ⟨_, _, he⟩
      · exact absurd ⟨rfl, Or.inl rfl⟩ hno
      · rcases hp with hp | hp <;> cases hp
      · simp at hab; subst hab
        exact Or.inr ⟨rfl, hn, ha⟩
      · cases he
    | patch _ hg _ hkeep =>
      obtain ⟨g', hg', hb⟩ := ho
      simp [Store.set, Req.target] at hg'
      subst hg'
      exact Or.inl ⟨_, hg, (hkeep _ (Or.inl ⟨rfl, Or.inl rfl⟩)).1 hb⟩
    | delete =>
      obtain ⟨g', hg', _⟩ := ho
      simp [Store.set, Req.target] at hg'
  · obtain ⟨g, hg, hb⟩ := ho
    exact Or.inl ⟨g, by rw [← hs.frame hy]; exact hg, hb⟩

end LdhAcl
