---
name: expert-panel
description: >
  Build a rigorous, product-agnostic expert panel for any of the five Rapid review
  areas — Business, Technical, Design, SME (domain), Users. For each area it generates
  1st-, 2nd-, and 3rd-order candidate experts (each wielding named frameworks and an
  outside-view lens), scores them, and pares to the most relevant ~6–8, then runs the
  panel through the project's pillars and synthesizes convergent / divergent / risks /
  open. Names disciplines and the frameworks they apply, not products — it is
  instantiated per project and never hardcodes a particular product. Used at Phase 2
  of a Rapid build; also usable standalone for any
  multi-perspective review that must not be an echo chamber.
---

# Expert Panel — generic panel builder (P2)

> **What it is.** A reusable method for assembling an expert panel in any of **five
> areas** (Business · Technical · Design · SME · Users) and for any product. It
> overproduces candidate experts across three "orders" of distance from the work, scores
> them, and pares to the load-bearing set — so the panel is grounded *and* hard to fool.
> Each panelist brings not just a voice but a **named discipline, the frameworks that
> discipline wields, and an outside-view lens.** It outputs disciplines/archetypes the
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
5. **A panelist is a lens *plus a toolkit*.** The value isn't the person — it's the
   **discipline + the named frameworks it wields + the outside view it imports.** A panel
   that brings JTBD, Five Forces, Nielsen's heuristics, STRIDE, and the Double Diamond to
   bear *shapes the app*; a panel that only voices opinions just grades it. Each area below
   lists the frameworks its panel should apply by name.

---

## The five areas — and what each is for

The five areas map cleanly onto the classic product lenses (Desirability · Feasibility ·
Viability), extended with Legitimacy for regulated/expert domains:

| Area | Question it owns | Lens |
|---|---|---|
| **Business** | Is this viable, fundable, defensible? | **Viability** |
| **Technical** | Will it hold up; is it sound and testable? | **Feasibility** |
| **Design** | Is it usable, coherent, and desirable to use? | **Desirability** (craft) |
| **Users** | Does it actually work for the people who touch it? | **Desirability** (felt experience) |
| **SME (domain)** | Is it right, credible, and legitimate in the domain? | **Legitimacy / validity** |

> **Design and Users are siblings, not duplicates.** Design owns the *artifact* — IA,
> interaction, hierarchy, the craft and the heuristics. Users owns the *people* — adoption,
> felt experience, the full cast of personas. A beautiful interface no one adopts fails the
> Users panel; a beloved product that's an accessibility and consistency mess fails the
> Design panel. You want both.

---

## The three orders of expertise (consistent across all five areas)

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

## The five areas

Each module gives the area's **charge**, its candidate roster **by order** (archetypes, not
people), the **frameworks** that area's panel should wield by name, and **relevance weighting**
— what to score up given the project's pillars. The roster is the generation menu for steps 2–4;
the frameworks are the tools each panelist brings; the weighting tunes the scoring in step 5.

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

**Frameworks the panel wields:** Jobs-to-be-Done · Porter's Five Forces · Business Model /
Lean Canvas · unit economics (CAC · LTV · payback · contribution margin) · the Rule of 40 ·
Helmer's *7 Powers* · Christensen's Disruption Theory · Wardley Mapping · TAM/SAM/SOM ·
network-effects taxonomy (NFX 16) · cohort & retention curves · the Bullseye GTM framework.

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

**Frameworks the panel wields:** the C4 model · the Test Pyramid · STRIDE threat modeling ·
SOLID + coupling/cohesion · CAP / PACELC · the Twelve-Factor App · SRE SLOs & error budgets ·
FMEA / fault trees · Conway's Law · resilience patterns (circuit breaker · bulkhead · backpressure) ·
privacy-by-design · the OWASP Top 10 · (for AI) eval-harness + offline/online metrics + drift monitoring.

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

**Frameworks the panel wields:** the domain's own canon & standards of evidence · evidence
hierarchies (what counts as "known" here) · precedent / case / incident review · first-principles
vs. received practice · analogical transfer from adjacent domains · the precautionary principle
(for high-stakes/irreversible) · ethics review (consent, equity, "nothing about us without us").

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

**Frameworks the panel wields:** Jobs-to-be-Done · personas & anti-personas · journey mapping ·
the Kano model · the Fogg Behavior Model (B = MAP) · the Hook model *(and its ethics)* ·
laddering / the 5 Whys · Rogers' Diffusion of Innovations (the adoption curve) · accessibility
personas · day-in-the-life narrative.

### E · Design — *"Is it usable, coherent, and desirable to use?"*

**Charge:** product/UX design, interaction & information architecture, visual hierarchy & craft,
design systems & consistency, content/UX writing, design research, accessibility-as-design,
the end-to-end service experience, and desirability/emotional resonance. (Design owns the
*artifact*; Users owns the *people* — see "Design and Users are siblings" above.)

- **1st order — practitioners (do design)**
  - **Product / UX designer** — flows, information architecture, interaction; "where does the user get stuck."
  - **UI / visual designer** — hierarchy, type, color, spacing, the craft of the surface.
  - **Interaction / motion designer** — states, transitions, feedback; the *feel* of using it.
  - **UX researcher** — what users actually *do* vs. say; usability tests, the evidence behind the design.
  - **Content designer / UX writer** — clarity, voice, labels, empty states, error messages — the words.
  - **Design technologist / front-end-design** — design-to-code fidelity; what's actually buildable.
- **2nd order — shapers & critics**
  - **Design systems lead** — tokens, components, consistency at scale; the anti-entropy force.
  - **Accessibility / inclusive-design specialist** — WCAG as *design intent*, not a bolt-on audit.
  - **Brand / creative director** — identity, differentiation, the emotional and desirability bar.
  - **Service designer** — the end-to-end journey across touchpoints and time, not one screen.
  - **Design-ops / critique facilitator** — the quality bar and how critique actually runs.
- **3rd order — outsiders & long-horizon**
  - **Cognitive / perceptual psychologist** — attention, memory, perception (Gestalt, signal detection).
  - **Behavioral designer (ethical)** — habit & motivation, and *dark-pattern avoidance*, not exploitation.
  - **Anthropologist / ethnographer** — how the artifact actually lives in real context and culture.
  - **Critical / adversarial designer** — who's excluded, what harm the design enables, the deceptive-pattern lens.
  - **Cross-medium designer** (game / industrial / architecture / typography) — imports a non-software design tradition.

**Frameworks the panel wields:** the Double Diamond · Design Thinking (IDEO) · Nielsen's 10
usability heuristics · Norman's affordances & signifiers + the Gulfs of Execution/Evaluation ·
Gestalt principles · Fitts's & Hick's laws · the Laws of UX · Jobs-to-be-Done · the Kano model
(expected vs. delight) · journey & service blueprints · WCAG / inclusive design · Atomic Design
& design tokens · the serial-position & von Restorff effects · desirability testing.

**Relevance weighting:** visual & interaction craft ↑ for consumer / brand-forward products;
accessibility-as-design always ≥1; service designer ↑ for multi-touchpoint / omni-channel;
content designer ↑ for information-dense or high-stakes flows; the critical/adversarial designer
↑ for persuasive or engagement-driven products (the dark-pattern risk).

---

## Instantiation — how "product-agnostic" is enforced

- The rosters are **archetypes (a role + a stake), not people and not products.** At P2, the
  orchestrator instantiates each *kept* archetype against this project's domain + pillars,
  giving it a name and a plausible background. The **skill file stays clean of any product.**
- A panelist must reference a **specific PRD requirement or pillar** — never "the doc in general."
- The same skill serves any product: a language-learning app and a settlement system each get a
  Business / Technical / Design / SME / Users panel from these rosters, instantiated differently. If a
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

## Panel observability — the roster, the cuts, and the contributions

Paring is a decision, and decisions must be **auditable**. Alongside the synthesis, the panel
emits a **roster record** so you can see, after the fact: **who survived, who was cut and why,**
and — for each survivor — **what they asked and how it changed the spec/design.** A panel that
can't show its cuts is roster theater; a survivor whose ask changed nothing was a wasted seat.

**Output:** `03-panels/roster.json` (one block per area), beside `synthesis.md`.

```json
{
  "area": "Business",
  "candidates": [
    { "order": 1, "archetype": "Unit-economics owner",
      "scores": {"pillar":2,"coverage":2,"ask":2,"distance":0}, "total": 6,
      "kept": true,  "reason": "covers the unit-economics pillar; concrete, falsifiable ask" },
    { "order": 2, "archetype": "Category analyst",
      "scores": {"pillar":1,"coverage":0,"ask":1,"distance":1}, "total": 3,
      "kept": false, "reason": "lens fully covered by the VC — wasted seat (dedup)" }
  ],
  "panel": [
    { "archetype": "Unit-economics owner", "persona": "…", "order": 1,
      "ask": "tie pricing to a CAC-payback under 6 months",
      "changed": [
        { "what": "added pricing-guardrail requirement", "ref": "01-intake/PRD-ENHANCED.md#FR-12" },
        { "what": "spec section now caps trial length",   "ref": "04-spec/spec.md#S-07" }
      ] }
  ]
}
```

**Visible live in the Observatory** (`.rapid/observe/*.jsonl` → the dashboard):
- **`DECIDE` per candidate** — `kept` / `cut` + the one-line reason, so every cut is on the
  timeline, not buried in a file. (`detail: "cut: Category analyst — overlaps the VC"`.)
- **`DECIDE` per survivor ask that lands a change** — `basis:"panel"`, pointing at the
  spec / PRD / mock anchor it changed, so a panelist's *influence on the build* is traceable.

**The two questions it answers, by construction:**
1. *Who survived, who was cut, and why?* → `candidates[]` with `kept` + `reason` (and the score breakdown).
2. *For survivors, what did they contribute and how did it improve the design/spec?* →
   `panel[].ask` + `panel[].changed[]` with refs into the actual spec/PRD/mock.

This makes the panel's value **measurable**: a survivor with an empty `changed[]` is a flag (did
the panel cost buy anything?), and a high-scoring cut candidate is a note for next time.

---

## Tracks

| | Panels run | Experts each | Orders required |
|---|---|---|---|
| **full** | all five areas | 6–8 | ≥3 / ≥2 / ≥1 |
| **fast** | the 1–2 most pillar-relevant areas | ~4 | ≥1 non-1st-order (never all insiders) |

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
