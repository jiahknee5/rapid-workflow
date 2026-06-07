---
name: expert-panel
description: >
  Build a rigorous, product-agnostic expert panel for any of the four Rapid review
  areas — Business, Technical, SME (domain), Users. For each area it generates
  1st-, 2nd-, and 3rd-order candidate experts, scores them, and pares to the most
  relevant ~6–8, then runs the panel through the project's pillars and synthesizes
  convergent / divergent / risks / open. Names disciplines, not products — it is
  instantiated per project and never hardcodes a particular product (no ASL, no
  SuperBuilders). Used at Phase 2 of a Rapid build; also usable standalone for any
  multi-perspective review that must not be an echo chamber.
---

# Expert Panel — generic panel builder (P2)

> **What it is.** A reusable method for assembling an expert panel in any of four
> areas and for any product. It overproduces candidate experts across three "orders"
> of distance from the work, scores them, and pares to the load-bearing set — so the
> panel is grounded *and* hard to fool. It outputs disciplines/archetypes that the
> orchestrator instantiates against the project's domain and pillars; it contains no
> product-specific content.
>
> **What it is NOT.** Not a fixed roster of named people. Not tied to any product.
> Not a single mega-panel — it builds one panel per area, on demand.

---

## When to use

- **Phase 2 of a Rapid build** — challenge the decomposed PRD (`01-intake/PRD-ENHANCED.md`)
  through the pillars (`00-vision/PILLARS.md`). Output → `03-panels/synthesis.md`, read at **Gate 1**.
- **Standalone** — any time you need a structured, multi-perspective critique that won't
  collapse into agreement (a design review, a strategy doc, a go/no-go).

---

## Core thesis — why this method, not "ask some experts"

1. **Named, opinionated personas beat "an expert."** A persona with a stake argues and
   makes a falsifiable ask; "an expert" hedges. *Generic ≠ vague:* the persona is an
   **archetype** (a role + a stake), instantiated per project — not a real named person
   for a specific product.
2. **Insiders share blind spots.** A panel of only hands-on practitioners agrees too
   easily and misses what its own discipline is structurally blind to. Forcing in 2nd-
   and 3rd-order voices is how the outside view gets a seat.
3. **Generate wide, then pare.** You don't find the load-bearing expert by guessing six
   up front — you overproduce candidates across three orders and cut. The cut is where
   the rigor lives.
4. **Score against the pillars, not in the abstract.** Relevance is relative to *this*
   project's pillars and risk surface, so the same area produces a different panel for a
   kids' app than for a clearing house.

---

## The three orders of expertise (consistent across all four areas)

Distance from the day-to-day work increases 1 → 3; per-head relevance falls, surprise rises.

| Order | Name | Who they are | What they add | Risk if omitted |
|---|---|---|---|---|
| **1st** | **Practitioners** | Do the work in this area, hands-on, now | Ground truth, real costs, "where it rots" | Panel floats free of reality |
| **2nd** | **Shapers & Critics** | Fund, regulate, standardize, audit, or critique the area without doing the day-to-day | Authority + external constraint the practitioner internalizes and stops seeing | Panel ignores the rules and forces acting on it |
| **3rd** | **Outsiders & Long-horizon** | Adjacent fields, contrarians, systemic / ethical / historical / failure-mode lenses | The one voice that catches the flaw insiders are structurally blind to | The fatal, non-obvious flaw ships |

> **The 3rd order earns its single seat.** It has the lowest relevance per head and the
> highest payoff variance — most builds, it confirms; occasionally it saves the build.
> Cutting it to "save time" is cutting exactly the insurance you're paying for.

---

## Construction protocol — the skill's core loop

```
frame → generate(1st,2nd,3rd) → score → pare → instantiate → run → synthesize
```

1. **Frame.** Read the area's charge (below), the project's pillars, and the enhanced PRD.
   The panel reviews *through the pillars* — every prompt names them.
2. **Generate 1st order** — 4–6 practitioner archetypes who'd have hands-on judgment here.
3. **Generate 2nd order** — 4–6 shaper/critic archetypes.
4. **Generate 3rd order** — 3–5 outsider / long-horizon archetypes.
   *Overproduce:* aim for ~12–16 candidates before paring. Cheap to list, expensive to skip.
5. **Score** each candidate on the paring rubric (below).
6. **Pare to the panel** — keep the top 6–8, subject to the composition rule (below).
7. **Instantiate** — turn each kept archetype into a concrete persona for *this* project:
   a name, a plausible background, a stake — **without inventing product facts**
   (Constitution Art. I: an opinion is fine; a fabricated statistic is not).
8. **Run** — each panelist reacts to a **specific PRD requirement or pillar**, in voice,
   with **one concrete, falsifiable ask** (a change they'd make and how you'd know it worked).
9. **Synthesize** — convergent / divergent / risks / open, each line carrying its source panelist.

---

## Paring rubric — score each candidate 0–2, keep the highest totals

| Criterion | 0 | 1 | 2 |
|---|---|---|---|
| **Pillar relevance** | Touches no pillar | Touches a pillar indirectly | Maps directly to a pillar or a top-3 risk |
| **Unique coverage** | Lens fully covered by a stronger candidate | Partial overlap | Covers a risk no one else on the shortlist covers |
| **Concrete ask** | Can only offer platitudes | Directional advice | A falsifiable, actionable ask |
| **Perspective distance** | Pure consensus with the 1st order | Some divergence | Genuinely moves the panel off the consensus |

Ties broken toward the **more concrete ask** and the **higher order** (to protect diversity).

## Composition rule — so the pared panel can't become an echo chamber

- Keep **6–8** experts (full track) or **~4** (fast track).
- **≥3 from 1st order** (the panel must be grounded), **≥2 from 2nd order**, **≥1 from 3rd order**.
- **No two experts with the same lens** — if two overlap, keep the one with the more concrete ask and drop the other (it's a wasted seat).
- At least one panelist must be positioned to say *"don't build this"* — a panel that can only say "build it better" isn't a review.

---

## The four areas

Each module gives the area's **charge**, its candidate roster **by order** (archetypes, not
people), and **relevance weighting** — what to score up given the project's pillars. The
roster is the generation menu for steps 2–4; the weighting tunes the scoring in step 5.

### A · Business — *"Is this viable, fundable, and defensible?"*

**Charge:** market & timing, GTM motion, pricing & packaging, unit economics, regulatory
exposure, moat/defensibility, and the 2nd-order effects of success at scale.

- **1st order — practitioners**
  - **Startup founder / 0→1 operator** — the survival lens: speed, runway, fundraising, what to cut to stay alive.
  - **Category operator (scale-up exec)** — has built & shipped this *kind* of product past 0→1; knows the real cost and the hidden work.
  - **Pricing & packaging strategist** — tiers, willingness-to-pay, expansion, discount leakage.
  - **Growth / acquisition lead** — the funnel for *this* motion (product-led / sales-led / marketplace / community).
  - **Unit-economics owner (finance)** — CAC, payback, gross margin, contribution, the path to it penciling out.
  - **GTM / sales lead** — the actual selling motion, cycle length, and who signs.
- **2nd order — shapers, funders & critics**
  - **Venture capitalist** — the power-law / fund-returner lens: TAM, growth rate, the next-round bar, "why is this a $1B+ outcome." *Tune to stage:* seed weighs team + wedge; growth weighs efficient scale.
  - **Private equity investor** — the cash-flow & efficiency lens: durable margins, multiple expansion, rollup / consolidation potential, "does this throw off money or just burn it."
  - **Corporate C-suite (incumbent executive)** — the CEO / CFO / Chief-Strategy view from an established player: build / buy / partner, competitive response, "would a big incumbent crush, acquire, or ignore this."
  - **Strategic advisor / board member / fractional exec** — the cross-company pattern-matcher: governance, "I've seen this movie," the un-sexy operational risk insiders rationalize away.
  - **Category / industry analyst** — the landscape, the incumbents, who else is moving.
  - **Regulatory & compliance counsel** — the legal surface for the domain (privacy, consumer, sector rules).
  - **Partnerships / BD lead** — channels, integrations, and platform-dependency risk.
  - **Moat / network-effects strategist** — what compounds, what's defensible, what's a feature not a company.
- **3rd order — outsiders & long-horizon**
  - **Behavioral economist** — how *real* humans (not rational agents) adopt, pay, and churn.
  - **Market historian / antitrust lens** — how this category's incumbents won and lost before.
  - **2nd-order-effects ethicist** — who is harmed if this *succeeds* at scale.
  - **Macro / contrarian skeptic** — "why now," and what kills this in a downturn.

**Relevance weighting:** pricing & unit-economics ↑ for consumer/SMB; regulatory counsel ↑
for health / finance / education / minors; moat & network-effects ↑ for platform/marketplace
plays; ethicist ↑ where scale has externalities. **The capital lens follows the likely
funding/exit path** — the venture capitalist ↑ for power-law, venture-scale bets; the PE
investor ↑ for cash-generative / mature / consolidation plays; the incumbent C-suite ↑ where a
big player is the probable acquirer or competitor; the founder lens is always in (it's the
builder's own reality check).

### B · Technical — *"Will it hold up, and is it sound and testable?"*

**Charge:** architecture, testability, performance, security, privacy, accessibility,
reliability, DevEx/CI, data, and (only if the build is AI) model/inference design.

- **1st order — practitioners**
  - **Senior engineer in the primary stack** — the architecture and "where does this rot in a year."
  - **Test / QA engineer** — is it testable; what's the failure surface; what's flaky-by-design.
  - **Platform / runtime specialist** — the constraints of the target (mobile / browser / embedded / cloud).
  - **Data / storage engineer** — schema, consistency, migration, scale, the query that melts.
  - **ML / inference engineer** — model choice, eval harness, drift, cost-per-call *(only if AI)*.
- **2nd order — shapers & critics**
  - **Security auditor / threat modeler** — trust boundaries and the attack surface.
  - **SRE / reliability engineer** — what pages someone at 3am; SLOs; the blast radius.
  - **Accessibility specialist** — can *everyone* use it (WCAG, assistive tech, no-mouse/no-color paths).
  - **Standards / interoperability owner** — does it play with the ecosystem it must.
  - **DevEx / CI architect** — can the team ship safely and fast, or will velocity die.
- **3rd order — outsiders & long-horizon**
  - **Adversary / abuse modeler** — how a bad actor turns the feature into a weapon.
  - **Performance-&-cost-at-scale economist** — what this costs and does at 100×.
  - **Incident / post-mortem historian** — the *class* of outage this design invites.
  - **Formal-methods / correctness skeptic** — where "it compiles" hides "it's wrong."
  - **Privacy engineer** — data minimization, retention, consent (overlaps security; keep separate when data is sensitive).

**Relevance weighting:** security & privacy ↑ for sensitive/regulated data; performance &
cost-at-scale ↑ for real-time or high-volume; accessibility ↑ (and never 0) for any
consumer/public surface; the ML engineer & correctness skeptic in only when the build is AI.

### C · SME (domain) — *"Is it right, legitimate, and credible in the domain?"*

**Charge:** domain correctness, accepted practice / pedagogy, legitimacy & credibility,
cultural soundness, and the domain's real edge cases and failure modes.

> **The most parameterized module.** "The domain" is whatever the project serves — instantiate
> it per project (a clinical area, a financial instrument, a craft, a regulated activity). The
> archetypes below are roles *within whatever that domain is*; this skill names no fixed field.

- **1st order — practitioners**
  - **Senior domain practitioner** — does the real thing at a high level, daily.
  - **Frontline domain worker** — applies domain knowledge at the coalface; sees what breaks in practice, not theory.
  - **Domain educator / trainer** — knows how the domain is taught — and how it's commonly *mis*-learned.
- **2nd order — shapers & critics**
  - **Domain academic / researcher** — the evidence base; what's actually known vs. folklore.
  - **Domain regulator / standards body** — the binding rules, certifications, and liability.
  - **Domain ethicist / community advocate** — whose interests the domain must protect; the harms of getting it wrong.
  - **Domain historian** — how the domain's practices and tools evolved, and which "obvious" ideas already failed.
- **3rd order — outsiders & long-horizon**
  - **Cross-domain analogist** — has solved this *shape* of problem in a different field; imports the non-obvious fix.
  - **Domain failure-mode expert** — the incidents, the malpractice, the cases that ended up in court or the news.
  - **Heterodox / contrarian domain voice** — disagrees with the mainstream consensus and can say why.
  - **Affected non-expert stakeholder** — the person the domain *acts upon* but rarely consults.

**Relevance weighting:** regulator & ethicist ↑ for regulated or vulnerable-population domains;
cross-domain analogist ↑ for novel applications; community advocate ↑ where the domain has a
represented community with standing; failure-mode expert ↑ where mistakes are costly or unsafe.

### D · Users — *"Does it actually work for the people who'll touch it?"*

**Charge:** usability, felt experience, adoption & abandonment, and the *full cast* of
hands-on personas — not just the primary user. Feeds the persona → scenario → test chain (P5).

- **1st order — practitioners (of using it)**
  - **Primary end user** — the person the product is for, speaking in the first person ("I'd…", not "users would…").
  - **Secondary end user** — a distinct segment with different goals and constraints.
  - **Daily operator / admin** — configures and runs it (the most-forgotten hands-on persona).
- **2nd order — shapers & critics**
  - **Power user / early adopter** — pushes it to its limits, wants the escape hatches.
  - **Reluctant / skeptical user** — would rather not change; the real adoption test.
  - **Accessibility-needs user** — a concrete disability or context constraint, in voice (not "users with disabilities" in the abstract).
  - **Support / CS rep** — hears every complaint first; the canary for what's confusing.
- **3rd order — outsiders & long-horizon**
  - **The churned / never-started** — was supposed to adopt and didn't; says exactly why.
  - **The buyer-not-user** — pays or approves but doesn't touch it (parent, manager, procurement, admin) — their criteria differ from the user's.
  - **The adversarial / misusing user** — the abuse, harassment, and harm lens.
  - **The future user** — how the need shifts in 12–24 months once the easy wins are spent.

**Relevance weighting:** buyer-not-user ↑ for B2B / B2B2C and anything involving minors;
accessibility-needs user always ≥1; adversarial/misuse user ↑ for social, UGC, or
safety-critical products; operator/admin ↑ for anything configurable or multi-tenant.

---

## Instantiation — how "product-agnostic" is enforced

- The rosters are **archetypes (a role + a stake), not people and not products.** At P2, the
  orchestrator instantiates each *kept* archetype against this project's domain + pillars,
  giving it a name and a plausible background. The **skill file stays clean of any product.**
- A panelist must reference a **specific PRD requirement or pillar** — never "the doc in general."
- The same skill serves any product: a language-learning app and a settlement system each get a
  Business / Technical / SME / Users panel from these rosters, instantiated differently. If a
  product name ever appears *in this file*, that's a bug — it belongs in the generated
  `03-panels/synthesis.md`, not here.
- **No invented facts.** A panelist's judgment and priorities are theirs to assert; a specific
  number, citation, or claim about the world must be VERIFIED (route to P3 grounding) or flagged
  UNVERIFIED. The panel produces *opinions and asks*, not fabricated evidence.

---

## Output contract — `03-panels/synthesis.md`

The deliverable is the **synthesis**, not the transcripts:

| Section | Contents |
|---|---|
| **Convergent** | Where the panel agrees — the consensus the spec can rely on. |
| **Divergent** | Where it disagrees — surfaced for the operator at **Gate 1**, never averaged away. |
| **Risks** | Named failure modes, each tagged with the panelist who raised it, ranked by stakes. |
| **Open** | Questions the panel couldn't settle → routed to **P3 grounding** or the **Gate-1 undecidable batch**. |

Every line carries its **source persona + order**, so a divergence can be weighed by who's
raising it and from what distance.

---

## Tracks

| | Panels run | Experts each | Orders required |
|---|---|---|---|
| **full** | all four areas | 6–8 | ≥3 / ≥2 / ≥1 |
| **fast** | the single most pillar-relevant area | ~4 | ≥1 non-1st-order (never all insiders) |

Escalate to a **2nd-order *panel*** (experts critiquing the panel's *output* — distinct from the
3rd-*order* expert) only when: a panel disagrees internally on a load-bearing, irreversible
decision; the stakes cross a defined threshold (safety, compliance, reputation); or two areas'
panels contradict each other. Default is no 2nd-order panel — it roughly doubles cost.

---

## Anti-patterns (the watchdog for this skill)

- **All-1st-order panel** — grounded but blind; it will agree with the builder.
- **"An expert says…"** — no name, no stake, no falsifiable ask; delete it.
- **Product-specific hardcoding** — names a product/feature in the skill; defeats reuse.
- **Skipping the 3rd order** — that's the seat that catches the non-obvious, fatal flaw.
- **Averaging divergence** — collapsing a real disagreement into a bland middle instead of
  surfacing it to Gate 1.
- **Roster theater** — listing 16 candidates and keeping all 16; the pare *is* the method.
- **Fabricated evidence** — a panelist citing a number they made up; route real claims to P3.

---

*This skill is the generic source of truth for Rapid's P2 panels. Product-specific panels
(e.g. any built project's instantiated panel) are **outputs** of running it — they live in that
project's `03-panels/`, never in this file.*
