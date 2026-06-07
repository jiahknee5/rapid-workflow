# RAPID — Methodology Deck

> **Audience:** Johnny (reference artifact) + senior technical / AI-engineering-lead interviewers
> **Format:** 18 slides — 5–10 minute walkthrough with a 60-second fallback
> **Decision asked (interview frame):** Trust this candidate to lead AI build engagements end-to-end — from stakeholder ambiguity to a tested, audited, shipped system
> **Author:** Johnny Chung — AI Engineering Lead
> **What this is:** Johnny's AI Build Workflow, operationalized as **RAPID**

---

## Contents

1. RAPID — Johnny's AI Build Workflow
2. I treat AI builds as a layered pipeline from vision to test suite, with a five-lead build team doing the work and humans gating the loop at four gates
3. Three moves separate this from vibe-coding: vision-as-lens, tiered panels, and the gap loop as product
4. Vision precedes intake because panels without a lens give generic advice
5. The stakeholder PRD is the input contract, not the source of truth
6. Five panel areas — business, technical, design, SME, users — each built 1st/2nd/3rd-order then pared to a working panel
7. Academic and recent research live as a cite-on-demand tool, not a front-loaded artifact
8. The expanded spec is derived from the PRD with a maintained diff, never duplicated
9. Every user-journey node declares its data-in, processing, and data-out to make state legible
10. The build is run by a five-lead team — planner, coder, tester, reviewer, watchdog — with the coder fanning out ≤4 worktree-isolated subagents
11. Coder subagents build in parallel while the watchdog audits against spec as a CI hook with teeth
12. Agents walk the app first; the human is the final gap filter, not the first
13. Gaps feed back into the PRD — the loop is the product, the build is the artifact
14. The test suite is generated from the user workflow map, not written separately
15. The full pipeline is for production; the fast track collapses to one panel area and one coder subagent for weekly gauntlets
16. Three weaknesses I'd flag before anyone else does
17. Every phase has a real rapid-workflow skill behind it — the workflow is deployed, not aspirational
18. Sixty seconds: vision → panels → derived spec → five-lead build team → gap loop — tiered, with the loop as the product

---

## 1. RAPID — Johnny's AI Build Workflow

**A repeatable methodology for turning stakeholder ambiguity into a tested, audited AI system — operationalized as RAPID.**

- Built over ~50 projects across AI agents, trading, climate, and education
- Operationalized as Claude Code skills — every phase has a tool behind it
- Designed for two cadences: production builds (full pipeline) and weekly gauntlets (fast track)

*This is a reference deck for myself. It's also the answer to "walk me through how you build."*

---

## 2. I treat AI builds as a layered pipeline from vision to test suite, with a five-lead build team doing the work and humans gating the loop at four gates

**Anchor — the system on one page:**

```
                              [ VISION ]                      ◄── lens for everything below
                                  │
                                  ▼
            [ Stakeholder ] ──► [ PRD ] ──► [ Panels ] ──► [ Expanded Spec ]
                                                                  │
                                          ┌───────────────────────┴───────────────────────┐
                                          ▼                                               ▼
                              [ User Workflow Map ]                          [ Design Spec + Mockups ]
                                                                                          │
                                                          ┌──────────┬────────────┼────────────┬──────────┐
                                                          ▼          ▼            ▼            ▼          ▼
                                                     [ Planner ] [ Coder ]   [ Tester ]  [ Reviewer ] [ Watchdog ]
                                                                     │
                                                                     ▼
                                                               [ ≤4 subagents ]
                                                                     │
                                                                     ▼
                                                                [ Built App ]
                                                                     │
                                                  ┌──────────────────┴──────────────────┐
                                                  ▼                                     ▼
                                         [ Agent Walkthrough ]                 [ Human Walkthrough ]
                                                                     │
                                                                     ▼
                                                                 [ GAP LOOP ] ─────► back to PRD
```

*Every later slide is a zoom into one region of this anchor. Humans gate the flow at four points — G0 PRD Review, G1 Direction, G2 Architecture, G3 Ship.*

---

## 3. Three moves separate this from vibe-coding: vision-as-lens, tiered panels, and the gap loop as product

1. **Vision-as-lens, not artifact** — pillars and project objective sit *above* the PRD so panels review through them instead of generating generic advice
2. **Tiered panels** — five panel areas (business / technical / design / SME / users), each built across 1st/2nd/3rd-order rosters and then *pared* to a working panel per project. Most workflows max out panels and drown in synthesis; paring is the discipline
3. **The gap loop is the product** — human + agent walkthroughs generate gaps that re-derive the spec. The build is the artifact; the loop is what gets better

*Sub-moves: expanded spec is derived (diffed) not duplicated; coder-subagent fan-out is bounded at 4; watchdog is CI-with-teeth, not advisory.*

---

## 4. Vision precedes intake because panels without a lens give generic advice

**Phase 0 — Vision as Lens**

```
┌──────────────────────────────────────────────────────────────┐
│                      COMPANY-LEVEL VISION                    │
│   (e.g., a company's 4 pillars: mission, rigor, build        │
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

## 6. Five panel areas — business, technical, design, SME, users — each built 1st/2nd/3rd-order then pared to a working panel

**Phase 2 — Panels**

Every area is rostered across three orders — **1st-order Practitioners → 2nd-order Shapers & Critics → 3rd-order Outsiders & Long-horizon** — then *pared* to the most relevant ~6–8 voices that actually serve this project's pillars.

| Area | Role | Skill |
|---|---|---|
| Business | Market, GTM, pricing, unit economics, regulatory exposure | `/expert-panel` (business) |
| Technical | Architecture, testability, perf, security, DevEx | `/expert-panel` (technical) |
| Design | UX flow, information architecture, interaction, visual craft | `/expert-panel` (design) |
| SME | Domain experts speaking in voice (clinicians, linguists, teachers, end users) | `/expert-panel` (SME) |
| Users | The people who actually use it, in first person | `/expert-panel` (users) |

**Tiering rule (how far down the orders to go):**
- Area disagrees internally on a load-bearing decision → pull in 2nd/3rd-order voices
- Decision is irreversible (architecture lock-in, public commitment, contract)
- Stakes cross a defined threshold (compliance, safety, reputation)

*Default is five areas, pared per project. Each area is a single product-agnostic skill (`/expert-panel`) instantiated per build — not seven hardcoded product panels.*

---

## 7. Academic and recent research live as a cite-on-demand tool, not a front-loaded artifact

**Phase 3 — Grounding**

- Knowledge base is **a tool the panels and spec writers reach for**, not a phase artifact
- Citations land *in the spec* where they support a decision, not in a separate "research doc"
- Recent research (last 12 months) gets a higher weight than canonical references for AI/agent work

**What goes in:**
- Methodology papers relevant to the specific build (e.g., instruction-design methods, agent-eval benchmarks for multi-agent build work)
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
- The spec is approved at **G2 (Architecture — the point of no return)** alongside hi-fi UI mockups (P5c); only then does the build begin

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

## 10. The build is run by a five-lead team — planner, coder, tester, reviewer, watchdog — with the coder fanning out ≤4 worktree-isolated subagents

**Phase 6 — Design Spec + Agent Topology**

Five named lead agents, each in its own terminal over claude-peers. The **coder** (build lead) is the only one that fans out — it spawns the parallel muscle.

```
   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
   │ PLANNER  │  │  CODER   │  │  TESTER  │  │ REVIEWER │  │ WATCHDOG │   ◄── five leads,
   │ team lead│  │build lead│  │eval lead │  │ rev lead │  │ CI w/teeth│       own terminals
   └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘
        │             │             │             │             │
   plan, decomp,      │        immutable     fans out a    blocks merge
   4 gates,           │        eval harness  review subagent on spec
   operator           │                      per dimension violation
                      ▼
       ┌──────────┬───────┴───────┬──────────┐
       ▼          ▼               ▼          ▼
  ┌────────┐ ┌────────┐      ┌────────┐ ┌────────┐
  │ sub 1  │ │ sub 2  │      │ sub 3  │ │ sub 4  │   (≤4 coder subagents,
  └────────┘ └────────┘      └────────┘ └────────┘    git-worktree isolated)
```

**Why coder-subagent fan-out is capped at 4:**
- The reviewer/planner can't honestly review more than ~4 parallel diffs in any one cycle
- Worktree isolation keeps subagents from stepping on each other — but only up to a point
- Claude Code subagent context budget is finite

*If you need more parallelism, sequence two rounds of 4. Don't fan out 8.*

---

## 11. Coder subagents build in parallel while the watchdog audits against spec as a CI hook with teeth

**Phase 7 — Build + Continuous Audit**

- Coder subagents run in parallel in isolated git worktrees, coordinated by the coder lead (who also owns smoke tests and build coordination)
- Watchdog runs **as a CI / pre-merge hook** — not an advisory comment, and never a coder
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
   [ Agent Walkthrough ]            ◄── tester lead (P7): Playwright + Claude
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

## 15. The full pipeline is for production; the fast track collapses to one panel area and one coder subagent for weekly gauntlets

**Tiered workflow — judgment about when *not* to use the methodology:**

| Phase | Full track (production) | Fast track (1-week gauntlet) |
|---|---|---|
| Vision | Company pillars + project objective | Project objective only |
| PRD intake | Immutable + diff'd | Same |
| Panels | 5 areas (B / T / Design / SME / Users), each pared per project | 1 area — pick the one most relevant |
| Knowledge base | Cite-on-demand from full library | Skip unless a panel explicitly cites |
| Expanded spec | Full derivation w/ diff | Lightweight — bullet-level spec |
| Workflow map | Full state machine | Golden path only |
| Agent topology | Five leads (planner, coder, tester, reviewer, watchdog) + ≤4 coder subagents | Coder lead + single subagent + watchdog |
| Walkthrough | Agent + human | Human only (no time to build the agent runner) |
| Gap loop | Full re-derivation | Inline fixes — no re-derivation cycle |
| Test suite | Generated from workflow map | Smoke tests only |

*The fast track is not a degraded full track — it's a different workflow that admits its constraints up front.*

---

## 16. Three weaknesses I'd flag before anyone else does

1. **The academic-KB layer hasn't proven it pays for itself.** I can't show a build where a cited paper changed an architectural decision in a way that mattered. Until I can, the layer is on probation.
2. **Coder-subagent fan-out coordination is not load-tested.** Fan-out of 4 is a guess, not a measurement. I haven't run the coder lead against 4 worktree-isolated subagents producing conflicting diffs at scale, with the reviewer and watchdog gating merges in real time. It might fail open or fail loud — I don't yet know which.
3. **Human walkthrough is still the slowest link.** Even with the tester lead's P7 agent walkthrough (Playwright + Claude), my felt-sense filter is the bottleneck. I haven't found a way to make that faster without compromising it. Acknowledging it is the move; pretending I've solved it would be dishonest.

*If an interviewer asks "what would you change," these are the three answers.*

---

## 17. Every phase has a real rapid-workflow skill behind it — the workflow is deployed, not aspirational

The repo's `skills/` directory holds exactly these: **`/rapid-workflow`** (the orchestrator that runs the whole pipeline), **`/workflow`** (alias), **`/expert-panel`** (the five panel areas), **`/refine`** (goal-directed propose → measure → keep-or-revert loop), **`/decision`** (decision + panel documentation), **`/docs`** (Reveal.js doc decks), plus the bundled **`/loop`** and **`/schedule`**.

| Phase | Skill(s) |
|---|---|
| 0 — Vision | runs inside `/rapid-workflow` (doc template, no dedicated skill) |
| 1 — PRD intake | runs inside `/rapid-workflow` (input artifact, no dedicated skill) |
| 2 — Panels | `/expert-panel` (instantiated per area: business, technical, design, SME, users) |
| 3 — Grounding | runs inside `/rapid-workflow` — cite-on-demand (no dedicated skill, gap) |
| 4 — Expanded spec | runs inside `/rapid-workflow`; decisions logged via `/decision` |
| 5 — Workflow map + mockups | runs inside `/rapid-workflow`; P5c mockups iterated with `/refine` |
| 6 — Design + topology | runs inside `/rapid-workflow` |
| 7 — Build + audit | `/rapid-workflow` drives the five-lead build; quality loop via `/refine` |
| 8 — Walkthrough | `/rapid-workflow` runs the agent + human walkthroughs |
| 9 — Gap loop | `/rapid-workflow` runs it; `/refine` for keep-or-revert iteration, `/loop` + `/schedule` for cadence |
| 10 — Test suite | runs inside `/rapid-workflow` (derived from workflow map; no dedicated runner skill, gap) |
| Decisions / panels documentation | `/decision` |
| Documentation decks | `/docs` (Reveal.js) |

*Gaps are visible: grounding/knowledge-base ingestion and test-suite generation don't have dedicated skills yet — they run inside `/rapid-workflow`. That's the build plan.*

---

## 18. Sixty seconds: vision → panels → derived spec → five-lead build team → gap loop — tiered, with the loop as the product

> *"I treat AI builds as a layered pipeline — RAPID. A project vision sets the lens, five areas of expert panels (business, technical, design, SME, users) review the stakeholder PRD through it, and an expanded spec gets derived as a diff against the PRD. Humans gate at four points — PRD review, direction, architecture, ship. The build runs as a five-lead team — planner, coder, tester, reviewer, watchdog — each in its own terminal, with the coder fanning out up to four worktree-isolated subagents as the parallel muscle. Agents walk the app first; I'm the final gap filter. Gaps feed back into the PRD and re-derive the spec — the loop is the product, the build is the artifact. The full pipeline is for production; for weekly gauntlets I collapse to a single panel area and a single coder subagent. The weakness I'd flag first is that the academic-KB layer hasn't yet earned its keep."*

---

# Appendix

## A. Glossary

- **Vision-as-lens** — positioning company pillars and project objective *above* the PRD so panels review through them rather than generating generic advice.
- **Panel area** — one of five review areas (Business, Technical, Design, SME, Users), each rostered across 1st/2nd/3rd-order voices and pared to a working panel per project.
- **1st / 2nd / 3rd order** — within a panel area: Practitioners (direct subject experts in voice) → Shapers & Critics (the meta-review) → Outsiders & Long-horizon. Deeper orders are pulled in as stakes warrant.
- **Five-lead build team** — the build is run by five named lead agents, each in its own terminal over claude-peers: **planner** (team lead — plan, decomposition, the four gates, operator relationship), **coder** (build lead — fans out subagents, owns smoke tests and build coordination), **tester** (owns the immutable eval harness), **reviewer** (fans out a review subagent per dimension), **watchdog** (CI-with-teeth, blocks merge, never a coder).
- **Coder subagent** — the parallel muscle fanned out by the coder lead (≤4), each isolated in its own git worktree.
- **Four gates (G0–G3)** — the four human gates: **G0** PRD Review (faithful decomposition), **G1** Direction (priority), **G2** Architecture (point of no return — spec + hi-fi mockups approved), **G3** Ship.
- **Derived spec** — the expanded spec, derived from the PRD with a maintained diff. Single source of truth. Approved at G2 alongside hi-fi UI mockups (P5c).
- **Cite-on-demand** — knowledge base referenced *inside* specs and panels at the moment it's needed, not loaded up-front.
- **Fan-out cap** — bounded parallelism for coder subagents (≤4) — the limit is that the reviewer/planner can't honestly review more than ~4 parallel diffs at once.
- **Watchdog with teeth** — the spec-audit lead runs as a CI / pre-merge hook that blocks merge on violation, not an advisory comment.
- **Gap loop** — the feedback loop where walkthrough-discovered gaps feed back into PRD and spec, triggering re-derivation.
- **Agent walkthrough** — agent-driven harness that exercises user-workflow scenarios before the human walkthrough.

## B. Out of scope

- This deck is not a sales pitch for a specific build — it's the methodology. Specific builds use this methodology but keep their own decks.
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
2. Decide whether to draw the *project pillar examples* explicitly on slide 4 (a company's 4 pillars by name?) or keep them generic
3. Test the 60-second version out loud with a stopwatch — current draft may run long
4. Decide which of the three "what I'd change" weaknesses to lead with if the interviewer asks for only one
