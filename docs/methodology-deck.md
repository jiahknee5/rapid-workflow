# Johnny's AI Build Workflow — Methodology Deck

> **Audience:** Johnny (reference artifact) + senior technical / AI-engineering-lead interviewers
> **Format:** 18 slides — 5–10 minute walkthrough with a 60-second fallback
> **Decision asked (interview frame):** Trust this candidate to lead AI build engagements end-to-end — from stakeholder ambiguity to a tested, audited, shipped system
> **Author:** Johnny Chung — AI Engineering Lead

---

## Contents

1. Johnny's AI Build Workflow
2. I treat AI builds as a layered pipeline from vision to test suite, with bounded agent swarms doing the work and humans gating the loop
3. Three moves separate this from vibe-coding: vision-as-lens, tiered panels, and the gap loop as product
4. Vision precedes intake because panels without a lens give generic advice
5. The stakeholder PRD is the input contract, not the source of truth
6. Three 1st-order panels cover business, technical, and SME — 2nd-order is escalation, not default
7. Academic and recent research live as a cite-on-demand tool, not a front-loaded artifact
8. The expanded spec is derived from the PRD with a maintained diff, never duplicated
9. Every user-journey node declares its data-in, processing, and data-out to make state legible
10. The build is run by orchestrator + supervisor + ≤4 implementors + watchdog + tester — fan-out is capped to keep review honest
11. Implementors build in parallel while the watchdog audits against spec as a CI hook with teeth
12. Agents walk the app first; the human is the final gap filter, not the first
13. Gaps feed back into the PRD — the loop is the product, the build is the artifact
14. The test suite is generated from the user workflow map, not written separately
15. The full pipeline is for production; the fast track collapses to one panel and one implementor for weekly gauntlets
16. Three weaknesses I'd flag before anyone else does
17. Every phase has an existing skill behind it — the workflow is deployed, not aspirational
18. Sixty seconds: vision → panels → derived spec → bounded swarm → gap loop — tiered, with the loop as the product

---

## 1. Johnny's AI Build Workflow

**A repeatable methodology for turning stakeholder ambiguity into a tested, audited AI system.**

- Built over ~50 projects across AI agents, trading, climate, and education
- Operationalized as Claude Code skills — every phase has a tool behind it
- Designed for two cadences: production builds (full pipeline) and weekly gauntlets (fast track)

*This is a reference deck for myself. It's also the answer to "walk me through how you build."*

---

## 2. I treat AI builds as a layered pipeline from vision to test suite, with bounded agent swarms doing the work and humans gating the loop

**Anchor — the system on one page:**

```
                              [ VISION ]                      ◄── lens for everything below
                                  │
                                  ▼
            [ Stakeholder ] ──► [ PRD ] ──► [ Panels ] ──► [ Expanded Spec ]
                                                                  │
                                          ┌───────────────────────┴───────────────────────┐
                                          ▼                                               ▼
                              [ User Workflow Map ]                          [ Design Spec + Topology ]
                                                                                          │
                                                                ┌─────────────────────────┼─────────────────────────┐
                                                                ▼                         ▼                         ▼
                                                       [ Orchestrator ]         [ ≤4 Implementors ]            [ Watchdog ]
                                                                                          │
                                                                                          ▼
                                                                                     [ Built App ]
                                                                                          │
                                                                ┌─────────────────────────┴─────────────────────────┐
                                                                ▼                                                   ▼
                                                       [ Agent Walkthrough ]                              [ Human Walkthrough ]
                                                                                          │
                                                                                          ▼
                                                                                      [ GAP LOOP ] ─────► back to PRD
```

*Every later slide is a zoom into one region of this anchor.*

---

## 3. Three moves separate this from vibe-coding: vision-as-lens, tiered panels, and the gap loop as product

1. **Vision-as-lens, not artifact** — pillars and project objective sit *above* the PRD so panels review through them instead of generating generic advice
2. **Tiered panels** — 1st-order business / technical / SME by default; 2nd-order panels exist but only escalate when stakes warrant. Most workflows max out panels and drown in synthesis
3. **The gap loop is the product** — human + agent walkthroughs generate gaps that re-derive the spec. The build is the artifact; the loop is what gets better

*Sub-moves: expanded spec is derived (diffed) not duplicated; agent fan-out is bounded at 4; watchdog is CI-with-teeth, not advisory.*

---

## 4. Vision precedes intake because panels without a lens give generic advice

**Phase 0 — Vision as Lens**

```
┌──────────────────────────────────────────────────────────────┐
│                      COMPANY-LEVEL VISION                    │
│   (e.g., SuperBuilders 4 pillars: mission, rigor, build      │
│    quality, integration-readiness)                           │
├──────────────────────────────────────────────────────────────┤
│                      PROJECT-LEVEL VISION                    │
│   (the objective: what this specific build must accomplish,  │
│    and which pillar(s) it serves)                            │
├──────────────────────────────────────────────────────────────┤
│                           PRD INTAKE                         │
└──────────────────────────────────────────────────────────────┘
```

- Vision is a *short* document — 1 page max for company, 1 paragraph for project
- It is referenced *by name* in every panel prompt and every spec section
- A PRD that violates a pillar is sent back before panels even run

*Why this matters: panels prompted without a lens produce generic best-practice advice. Panels prompted through pillars produce advice you can actually use.*

---

## 5. The stakeholder PRD is the input contract, not the source of truth

**Phase 1 — Intake**

- PRD comes from stakeholder (founder, partner, course staff, customer)
- I do **not** edit the PRD — it stays immutable as the input contract
- The expanded spec (Phase 4) becomes the working source of truth, with a maintained diff back to the PRD

**Why immutable:**
- The diff is the audit trail of decisions
- Stakeholders can re-read their own doc and trust nothing changed under them
- Re-runs of the pipeline always start from the same input

*Treating the PRD as immutable input is a small move that prevents large amounts of drift downstream.*

---

## 6. Three 1st-order panels cover business, technical, and SME — 2nd-order is escalation, not default

**Phase 2 — Panels**

| Panel | Role | Skill |
|---|---|---|
| Business | Market, GTM, pricing, unit economics, regulatory exposure | `business-expert-panel` |
| Technical | Architecture, testability, perf, security, DevEx | `technical-expert-panel`, `asl-technical-panel`, `security-expert-panel` |
| SME | Domain experts speaking in voice (ASL linguists, Deaf engineers, teachers, kids) | `asl-expert-panel`, `user-panel`, `superbuilders-patrick-panel` |

**Escalation rule (when to add 2nd-order panels):**
- 1st-order panel disagrees internally on a load-bearing decision
- Decision is irreversible (architecture lock-in, public commitment, contract)
- Stakes cross a defined threshold (compliance, safety, reputation)

*Default is 3 panels. Adding 2nd-order doubles cost for marginal gain on most builds.*

---

## 7. Academic and recent research live as a cite-on-demand tool, not a front-loaded artifact

**Phase 3 — Grounding**

- Knowledge base is **a tool the panels and spec writers reach for**, not a phase artifact
- Citations land *in the spec* where they support a decision, not in a separate "research doc"
- Recent research (last 12 months) gets a higher weight than canonical references for AI/agent work

**What goes in:**
- Methodology papers relevant to the specific build (e.g., DI for instruction design, agent-eval benchmarks for swarm work)
- Recent ablations / failure-mode studies
- Domain papers when an SME panel cites them

*Front-loaded knowledge bases get read once and ignored. Cite-on-demand knowledge is referenced in every spec it touches.*

---

## 8. The expanded spec is derived from the PRD with a maintained diff, never duplicated

**Phase 4 — Expanded Spec**

```
   [ PRD ] ─────────► [ Expanded Spec ]
       │                     │
       │   ◄── diff ──►     │   (auto-tracked: which sections expand which PRD requirements,
       │                     │    which are new derivations, which are open questions)
       ▼                     ▼
   immutable             evolves
```

- One document. Not two parallel docs that drift
- Diff sections are tagged: `[FROM PRD §2.1]`, `[DERIVED]`, `[OPEN — needs decision]`
- Every PRD requirement maps to a spec section or an explicit out-of-scope tag
- The diff becomes the change log when the gap loop fires

*Two docs drift within a week. The diff is the value.*

---

## 9. Every user-journey node declares its data-in, processing, and data-out to make state legible

**Phase 5 — User Workflow Map**

```
┌─────────────────┐        ┌─────────────────┐        ┌─────────────────┐
│   Node A        │        │   Node B        │        │   Node C        │
│ ─────────────── │   ──►  │ ─────────────── │   ──►  │ ─────────────── │
│ in:  <data>     │        │ in:  <data>     │        │ in:  <data>     │
│ proc: <thinking>│        │ proc: <thinking>│        │ proc: <thinking>│
│ out: <data>     │        │ out: <data>     │        │ out: <data>     │
└─────────────────┘        └─────────────────┘        └─────────────────┘
```

- Every state transition is visible
- "Processing" includes the *thinking* — what the user is reasoning about, not just what the system does
- Branches and failure paths are nodes, not annotations
- This becomes the source for the test suite (Phase 10)

*State that isn't drawn is state that breaks in production.*

---

## 10. The build is run by orchestrator + supervisor + ≤4 implementors + watchdog + tester — fan-out is capped to keep review honest

**Phase 6 — Design Spec + Agent Topology**

```
                            ┌──────────────────┐
                            │   ORCHESTRATOR   │  decomposes spec into 2–4 work units
                            └────────┬─────────┘
                                     │
                            ┌────────▼─────────┐
                            │    SUPERVISOR    │  spec-of-record, arbitration
                            └────────┬─────────┘
              ┌──────────────┬───────┴───────┬──────────────┐
              ▼              ▼               ▼              ▼
         ┌────────┐     ┌────────┐      ┌────────┐     ┌────────┐
         │ Impl 1 │     │ Impl 2 │      │ Impl 3 │     │ Impl 4 │   (max 4 — no more)
         └────┬───┘     └────┬───┘      └────┬───┘     └────┬───┘
              └──────────────┴───────┬───────┴──────────────┘
                                     ▼
                            ┌──────────────────┐
                            │     WATCHDOG     │  CI hook — blocks merge on spec violation
                            └────────┬─────────┘
                                     ▼
                            ┌──────────────────┐
                            │      TESTER      │  runs suite derived from workflow map
                            └──────────────────┘
```

**Why fan-out is capped at 4:**
- The supervisor has to arbitrate every conflict — beyond 4, arbitration becomes noise
- The reviewer can't actually review 8 parallel diffs in any one cycle
- Claude Code subagent context budget is finite

*If you need more parallelism, sequence two rounds of 4. Don't fan out 8.*

---

## 11. Implementors build in parallel while the watchdog audits against spec as a CI hook with teeth

**Phase 7 — Build + Continuous Audit**

- Implementors run in parallel under the supervisor's arbitration
- Watchdog runs **as a CI / pre-merge hook** — not an advisory comment
- A spec violation blocks merge until either (a) the implementation conforms or (b) the spec is updated through the proper channel (Phase 9)

**What the watchdog checks:**
- Spec coverage — every spec section has implementing code
- Spec violation — no code contradicts a spec decision
- Naming / interface contracts honored
- Test coverage hits the bar set in the spec

*An advisory watchdog gets ignored. A blocking watchdog forces the conversation back to the spec, which is where it belongs.*

---

## 12. Agents walk the app first; the human is the final gap filter, not the first

**Phase 8 — Automated + Human Walkthrough**

```
   [ Built App ]
        │
        ▼
   [ Agent Walkthrough ]            ◄── usability-testing skill: Playwright + Claude
        │                              runs the scenarios derived from the user workflow map
        ▼
   [ Auto-flagged gaps ]
        │
        ▼
   [ Human Walkthrough ]            ◄── Johnny, with a list of what the agent already found
        │
        ▼
   [ Human-only gaps ]              ◄── felt-sense, aesthetic, edge cases agents miss
        │
        ▼
   [ Gap list ]                     ◄── feeds the gap loop (Phase 9)
```

**Why agent-first:**
- Agents are faster and don't get bored
- They exercise the golden path + named edge cases mechanically
- The human becomes the felt-sense filter — does this *feel* right? — not the regression hunter

*Human time spent on regressions is human time wasted.*

---

## 13. Gaps feed back into the PRD — the loop is the product, the build is the artifact

**Phase 9 — Gap Loop**

```
   ┌──────────────────────────────────────────────────────────────────┐
   │                                                                  │
   ▼                                                                  │
[ PRD ] ──► [ Expanded Spec ] ──► [ Build ] ──► [ Walkthrough ] ──► [ GAPS ]
                                                                      │
                                                  (gap classification)
                                                                      │
                                  ┌───────────────────────────────────┤
                                  │                                   │
                                  ▼                                   ▼
                          [ Spec-level gap ]                  [ PRD-level gap ]
                          (re-derive spec)                    (back to stakeholder)
```

- Every gap is classified: is this a spec issue (we missed something in derivation) or a PRD issue (the stakeholder needs to make a call)?
- PRD-level gaps go back to the stakeholder as an explicit ask, not a silent assumption
- Spec-level gaps re-trigger phases 4–7 with the diff log intact

*The loop is what makes the methodology — each pass produces a better-fitting product, and the loop itself gets faster.*

---

## 14. The test suite is generated from the user workflow map, not written separately

**Phase 10 — Test Suite**

- Each node in the workflow map (Phase 5) becomes one or more test cases
- Inputs / processing assertions / outputs translate directly to arrange / act / assert
- Branches and failure paths in the map become the negative test cases
- Test coverage *by node* is reportable — gaps in coverage map back to gaps in the workflow itself

**Two consequences:**
- Writing the workflow map *is* writing the test plan
- A node missing from the map is a test you weren't going to write — and a bug you won't catch

*Tests written separately from the workflow drift from the workflow. Tests generated from the workflow can't.*

---

## 15. The full pipeline is for production; the fast track collapses to one panel and one implementor for weekly gauntlets

**Tiered workflow — judgment about when *not* to use the methodology:**

| Phase | Full track (production) | Fast track (1-week gauntlet) |
|---|---|---|
| Vision | Company pillars + project objective | Project objective only |
| PRD intake | Immutable + diff'd | Same |
| Panels | 3 panels (B / T / SME), escalate to 2nd-order on conflict | 1 panel — pick the one most relevant |
| Knowledge base | Cite-on-demand from full library | Skip unless a panel explicitly cites |
| Expanded spec | Full derivation w/ diff | Lightweight — bullet-level spec |
| Workflow map | Full state machine | Golden path only |
| Agent topology | Orchestrator + supervisor + ≤4 impl + watchdog + tester | Single implementor + watchdog |
| Walkthrough | Agent + human | Human only (no time to build the agent runner) |
| Gap loop | Full re-derivation | Inline fixes — no re-derivation cycle |
| Test suite | Generated from workflow map | Smoke tests only |

*The fast track is not a degraded full track — it's a different workflow that admits its constraints up front.*

---

## 16. Three weaknesses I'd flag before anyone else does

1. **The academic-KB layer hasn't proven it pays for itself.** I can't show a build where a cited paper changed an architectural decision in a way that mattered. Until I can, the layer is on probation.
2. **Supervisor arbitration logic is not load-tested.** Fan-out of 4 is a guess, not a measurement. I haven't run the supervisor against 4 implementors producing conflicting diffs at scale. It might fail open or fail loud — I don't yet know which.
3. **Human walkthrough is still the slowest link.** Even with the usability-testing agent runner, my felt-sense filter is the bottleneck. I haven't found a way to make that faster without compromising it. Acknowledging it is the move; pretending I've solved it would be dishonest.

*If an interviewer asks "what would you change," these are the three answers.*

---

## 17. Every phase has an existing skill behind it — the workflow is deployed, not aspirational

| Phase | Skill(s) |
|---|---|
| 0 — Vision | (doc template, no skill) |
| 1 — PRD intake | (input artifact, no skill) |
| 2 — Panels | `business-expert-panel`, `technical-expert-panel`, `asl-expert-panel`, `asl-technical-panel`, `security-expert-panel`, `superbuilders-patrick-panel`, `user-panel` |
| 3 — Grounding | (cite-on-demand — no dedicated skill yet, gap) |
| 4 — Expanded spec | `grill-me` (stress-test the spec), `blueprint` (production build framing) |
| 5 — Workflow map | (doc artifact, no skill) |
| 6 — Design + topology | `blueprint`, `ai-lead-deck` (when the spec needs to be presented) |
| 7 — Build + audit | `review`, `simplify`, `security-review`, `eval` |
| 8 — Walkthrough | `usability-testing` (agent runner) |
| 9 — Gap loop | `loop`, `schedule`, `loop-recipes` (automation cadence) |
| 10 — Test suite | (derived from workflow map; runner skill is gap) |
| Communication | `ai-lead-deck`, `ai-product-pitch`, `startup-package` |
| Output polish | `style`, `frontend-design` |

*Gaps are visible: knowledge-base ingestion and test-suite generation don't have dedicated skills yet. That's the build plan.*

---

## 18. Sixty seconds: vision → panels → derived spec → bounded swarm → gap loop — tiered, with the loop as the product

> *"I treat AI builds as a layered pipeline: a project vision sets the lens, panels of subject experts review the stakeholder PRD through it, and an expanded spec gets derived as a diff against the PRD. The build runs as a bounded agent swarm — orchestrator, supervisor, up to four implementors, a watchdog with CI-level teeth, and a tester. Agents walk the app first; I'm the final gap filter. Gaps feed back into the PRD and re-derive the spec — the loop is the product, the build is the artifact. The full pipeline is for production; for weekly gauntlets I collapse to a single panel and a single implementor. The weakness I'd flag first is that the academic-KB layer hasn't yet earned its keep."*

---

# Appendix

## A. Glossary

- **Vision-as-lens** — positioning company pillars and project objective *above* the PRD so panels review through them rather than generating generic advice.
- **1st-order panel** — direct subject experts speaking in voice (e.g., business, technical, SME).
- **2nd-order panel** — meta-review: experts critiquing the 1st-order panel's output. Used on escalation only.
- **Derived spec** — the expanded spec, derived from the PRD with a maintained diff. Single source of truth.
- **Cite-on-demand** — knowledge base referenced *inside* specs and panels at the moment it's needed, not loaded up-front.
- **Fan-out cap** — bounded parallelism for implementor agents (≤4) to keep supervisor arbitration and watchdog review tractable.
- **Supervisor arbitration** — the supervisor agent's job of resolving conflicts between parallel implementors against the spec-of-record.
- **Watchdog with teeth** — the spec-audit agent runs as a CI / pre-merge hook that blocks merge on violation, not an advisory comment.
- **Gap loop** — the feedback loop where walkthrough-discovered gaps feed back into PRD and spec, triggering re-derivation.
- **Usability-testing runner** — agent-driven Playwright + Claude harness that exercises user-workflow scenarios before the human walkthrough.

## B. Out of scope

- This deck is not a sales pitch for a specific build — it's the methodology. Specific builds (e.g., Synthesis-Tutor clone, AgentForge, ASL Learning) use this methodology but their own decks.
- This is not a coding-style or framework deck. Stack choices (Next.js, Python, MLX, Ollama) are project-level decisions, not workflow-level.
- This deck does not benchmark this workflow against named alternatives (Anthropic's prompt engineering guide, OpenAI's agent design patterns, etc.). That comparison is a separate exercise.

## C. Frameworks used in this deck

- **SCR / Pyramid Principle** — overall narrative arc (situation: AI builds need structure; complication: vibe-coding doesn't scale; resolution: this layered workflow)
- **MECE** — 18-slide structure is decomposed into Vision → Intake → Review → Spec → Build → Audit → Walkthrough → Loop → Test → Tiered (non-overlapping phases)
- **Layered architecture view** — anchor diagram and agent topology
- **State machine** — user workflow map
- **Feedback loop diagram** — gap loop
- **Comparison table** — tiered workflow
- **Capability map (implicit)** — tooling map slide

## D. Open asks (what to refine before delivering this in an actual interview)

1. Tighten the thesis sentence to under 25 words — current draft is 28
2. Decide whether to draw the *project pillar examples* explicitly on slide 4 (SuperBuilders 4 pillars by name?) or keep them generic
3. Test the 60-second version out loud with a stopwatch — current draft may run long
4. Decide which of the three "what I'd change" weaknesses to lead with if the interviewer asks for only one
