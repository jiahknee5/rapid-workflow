# rapid-workflow — Codebase Guide

> A walkthrough of what this repository is, what lives in it, and how the pieces fit together.
> Written 2026-05-29. Current version: **v0.6.0**.

---

## 1. What this repo is

`rapid-workflow` is **not a product repo** — it contains no shipped application. It is the home of **RAPID**, Johnny's operationalized methodology for autonomous, AI-driven product builds. The repo holds the *method* (skills, hooks, tools, templates, docs); when you actually run RAPID, it generates the build artifacts (specs, tests, decks) **inside the target project's repo**, not here.

The one-line thesis behind everything:

> **The agent that writes the code must never be the agent that audits it.** When one agent does both, visible progress (a working app) always beats invisible safety (tests, reviews). RAPID separates those roles *structurally* — via hooks, separate terminals, and tiered reviewers — not with prose instructions that fail under pressure.

RAPID turns a vague idea or a PRD into a tested, deployed system through a deterministic, gate-enforced pipeline. Its design draws on Karpathy (eval-first, keep-or-revert), Beck (TDD), Zaharia et al. (Compound AI Systems), and Every Inc. (Compound Engineering — tiered review, learning capture, doc agents, optimization loops).

---

## 2. The pipeline at a glance

RAPID runs as **12 phases** punctuated by **4 human gates**, organized into three arcs:

```
IDEA / PRD
   │
   ▼  ── Arc 1: UNDERSTAND ────────────────────────────────
 P0  Vision        define pillars, constraints, north star
 P1  Structure     scaffold folders + CONSTITUTION, lock PRD
 P1b Decompose     split PRD into MUST / SHOULD / COULD
[G0] PRD Review    doc-review agent pre-screens → operator approves
 P2  Panels        1–3 expert panels review PRD through the pillars
 P3  Research       timeboxed, VERIFIED / UNVERIFIED protocol
[G1] Direction     operator approves panel synthesis or redirects
   │
   ▼  ── Arc 2: SPECIFY ───────────────────────────────────
 P4  Spec          derive spec from PRD with a maintained diff
 P5  Tasks + Eval  decompose tasks, generate IMMUTABLE eval harness
 P5b Deepen        re-derive / expand spec sections
 P5c Mockups       hi-fi UI mockups + clickable prototype, approved before build
[G2] Architecture  operator approves spec + mockups, hands over keys — point of no return
   │
   ▼  ── Arc 3: EXECUTE & CONVERGE ────────────────────────
 P6  Build         five-lead build team (see §6)
 P7  Test + QA     immutable evals, Playwright, screenshot evidence
 P8  Gap Loop ↻    classify gaps by pillar + severity, re-derive (max ×3)
[G3] Ship          operator reviews app, audit, gaps, tests, cost
 P9  Deploy        CI/CD, README, RUNBOOK, retrospective
 P10 Pulse         post-ship monitoring → feeds the next build's P0
   │
   ▼
DEPLOYED APP
```

**The compound loop:** P10 (Pulse) of one project flows into P0 (Vision) of the next. Prior learnings, gap patterns, and pulse reports make each subsequent build smarter. *The loop is the product; any single build is just an artifact.*

---

## 3. Directory map

```
rapid-workflow/
├── README.md              high-level overview + quick start
├── CHANGELOG.md           version history (currently v0.6.0)
├── CODEBASE.md            ← this file
├── docs.json              docs registry snapshot
│
├── skills/                the eight Claude Code skills (symlinked to ~/.claude/skills/)
│   ├── rapid-workflow/SKILL.md orchestrator — runs the 12-phase pipeline
│   ├── workflow/SKILL.md     alias → /rapid-workflow
│   ├── expert-panel/SKILL.md  five panel areas (Business·Technical·Design·SME·Users), 1st/2nd/3rd-order
│   ├── refine/SKILL.md        goal-directed propose→measure→keep-or-revert loop (Karpathy-style)
│   ├── observe/SKILL.md       generates the project-tailored Observatory (live build view)
│   ├── test-theater/SKILL.md  generates the project-tailored Test Theater + coverage proof
│   ├── decision/SKILL.md     /decision — decision + panel documentation
│   └── docs/SKILL.md         /docs — generates Reveal.js documentation decks
│
├── tools/                 operational scripts (run from a target project root)
│   ├── observe-server.py     live observability dashboard server (:4040)
│   ├── rapid-team.sh         brings up the five-lead build team (tmux / --cursor)
│   ├── phase-gate-hook.sh    PreToolUse hook — BLOCKS phase advance w/o artifacts
│   ├── inputs-check.sh       fail-closed human-input gate (blocks P6 entry)
│   ├── trace-check.sh        G2 traceability gate (every req → spec, every screen → req)
│   ├── worktree-check.sh     P6-exit isolation verifier (each writer in its own worktree)
│   ├── post-write-hook.sh    PostToolUse hook — updates registry + CHANGES.md
│   ├── build-docs-registry.sh helper for the post-write hook
│   └── rapid-spec.html       large HTML reference (superseded by docs/architecture.html)
│
├── observatory/           Vite + React 19 + XYFlow live dashboard (consumes observe-server)
│   ├── src/components/       EventStream, AgentGraph, AgentNode, HealthView
│   ├── src/hooks/            useForgeData.ts (fetches /api/events, /api/agents, /api/meta)
│   └── src/types, src/themes
│
├── templates/             single-source-of-truth CSS/HTML for all generated decks
│   ├── template-docs-deck.html          universal deck template
│   ├── template-decision-deck.html      decision-deck template
│   └── template-docs-deck-showcase.html example output (all slide types)
│
├── docs/                  the methodology, as HTML decks + markdown reference
│   ├── CONSTITUTION.md       10 governance articles
│   ├── PRD.md                RAPID's own product requirements
│   ├── methodology-deck.md   18-slide methodology walkthrough (source)
│   ├── rapid-reference.md    text version of the system reference (D0–D16)
│   ├── architecture.html     interactive system reference (D0–D32)
│   ├── workflow.html, specification.html, prd.html, prd-enhanced.html,
│   ├── eval.html, users.html, documentation.html, observatory.html
│
├── examples/vision/       reference VISION.md + PILLARS.md (SuperBuilders tutor)
└── archive/               superseded decks/dashboards kept for reference
```

---

## 4. The eight skills

All eight live in `skills/` (the source of truth) and are symlinked into `~/.claude/skills/` so Claude Code can find them. Editing here and committing tracks the change in git.

### `/rapid-workflow` — the orchestrator
`skills/rapid-workflow/SKILL.md` (~1100+ lines). Runs the full pipeline.

```
/rapid-workflow <idea or PRD path> [--track fast|full] [--resume] [--gap-loop]
/rapid-workflow status
```

It separates **deterministic** components (same every run — the 12 phases, 4 gates, 4 safety mechanisms) from **dynamic** components composed per project:

| Dynamic per project | Example |
|---|---|
| Pillars (3–5) | derived from the project's risks + goals |
| Constitution Articles VI–X | tailored to the safety domain |
| Panels (Business·Technical·Design·SME·Users) | 1st/2nd/3rd-order rosters built, then pared per project |
| Reviewer weights | security-heavy for healthcare, perf-heavy for real-time |
| Agent topology | five-lead build team (planner·coder·tester·reviewer·watchdog) + ≤4 worktree coder subagents |
| Eval harness | generated from the workflow state machine, then locked |

### `/workflow` — alias
`skills/workflow/SKILL.md`. Passes all arguments straight through to `/rapid-workflow`.

### `/expert-panel` — the panel builder (P2)
`skills/expert-panel/SKILL.md`. The differentiator skill. Instantiates **five panel areas** — Business, Technical, Design, SME, Users — each as a **1st/2nd/3rd-order** roster (Practitioners → Shapers & Critics → Outsiders & Long-horizon), then **pares** to a working panel via an explicit rubric (composition rule ≥3 / ≥2 / ≥1). Each area carries named frameworks (Five Forces, JTBD, Test Pyramid, STRIDE, Double Diamond, Nielsen heuristics, Kano) and the Business area adds capital lenses (founder / VC / PE / corporate C-suite / advisor). It maps to the four risk lenses — Desirability, Feasibility, Viability, Legitimacy — and writes panel observability to `03-panels/roster.json` (candidates with scores/kept/reason; panel members with ask/changed[]). Generic by construction: it names no product.

### `/refine` — the goal-directed loop primitive (P8)
`skills/refine/SKILL.md`. Karpathy's autoresearch loop, generalized: **propose → measure → keep-or-revert** against an explicit goal and eval. Used by the P8 gap loop so only improvements survive (regression ⇒ `git reset --hard`).

### `/observe` — the dynamic Observability builder (P1·P6·P9)
`skills/observe/SKILL.md`. Generates a **project-tailored Observatory** — it inspects the project's agent roster (`04-spec/agents/`), phases, and acceptance signals and *generates* the dashboard + the event-logging contract + the polling wiring for that project, rather than copying a generic shell. The deterministic spine (append-only JSONL per role, monotonic `seq`, `observe-server.py` merge/serve, poll-since-seq, hooks auto-emit) is fixed; the topology, health signals, and phase ribbon are composed from the project. Observability = the trust mechanism for hands-off autonomy.

### `/test-theater` — the dynamic Test Theater builder (P4·P5·P7·P9)
`skills/test-theater/SKILL.md`. Generates a **project-tailored Workflow Test Theater** — the test suite *is* the user workflows made runnable. It derives `docs/workflows.json` from `04-spec/workflow.md`, **parses the built code for a function inventory**, builds a coverage matrix, and generates `docs/testsuite.html` + the `workflow-runner.py` wiring. The invariant is fixed: each node's `exec` **is** the walkable/recorded form of that node's immutable eval test (one source of truth, so tests can't drift). Acceptance is provable: **`untouched_functions == 0`**.

### `/decision` — decision & panel documentation
`skills/decision/SKILL.md`. Two corpora in one skill: resolved **decisions** and expert **panel findings**. Each decision is a `D-NN.md` file with YAML frontmatter (question, phase, pillars, options w/ pros/cons, rationale + sources, panel input, cascade impacts). Regenerates McKinsey-style Reveal.js decks (`decisions/deck.html`, `panels/deck.html`).

```
/decision log|rebuild|status
/decision panel [rebuild|status]
```

### `/docs` — documentation decks
`skills/docs/SKILL.md`. Generates one navigable Reveal.js deck per numbered phase folder (`00-vision/`, `01-intake/`, … `07-gaps/`, `tests/`) plus a master `hub.html`. All decks inherit CSS from `templates/template-docs-deck.html`. House style: McKinsey **action titles** (conclusions, not topics) and a **plain-English-first** pattern (accessible explanation, then a `**Technically:**` precision line).

```
/docs build [<folder>] | hub | changelog | status
```

---

## 5. The enforcement layer (tools + hooks)

This is where RAPID's safety thesis becomes mechanical. Prose can be ignored under pressure; hooks cannot.

- **`tools/phase-gate-hook.sh`** — Installed as a **PreToolUse** hook on writes to `.rapid/STATE.json`. It *blocks* a phase transition unless that phase's required artifacts already exist. E.g. you cannot enter Phase 6 (Build) without `.rapid/EVAL/` containing ≥1 test file, `.rapid/TASKS.json`, **and a `.rapid/INPUTS.json` whose every required human input is resolved**; you cannot enter Phase 7 without `.rapid/P6_EXIT.json` showing all assertions passing.

- **`tools/inputs-check.sh`** — The fail-closed human-input gate (B). Reads the `.rapid/INPUTS.json` ledger and blocks P6 entry until every required input (credentials, deploy target, spend ceiling, resolved undecidables) is `resolved`/`waived` — a credential row only counts resolved once its `.env:KEY` actually exists. Run at GATE 2; the phase-gate hook runs the same check independently. This is what makes "gather all human input up front, then run to completion" mechanical instead of hoped-for.

- **`tools/worktree-check.sh`** — Worktree-isolation verifier (C). Run at P6 exit: reads the observe log and asserts every parallel build writer ran in its own declared git worktree (no missing worktree, no two writers sharing one), merging a `build_writers_isolated` assertion into `.rapid/P6_EXIT.json` — so a build that fanned writers into the shared tree mechanically fails the phase gate. Verifies what the skill only instructed.

- **`tools/cost-summary.sh`** — Token/cost monitor. Parses real billed tokens from Claude Code transcripts per step/session/project, **and attributes them per RAPID phase** by bucketing each step into the phase active in the observe timeline, plus **human touchpoints per phase** (GATE + ESCALATE events, + needs-real-human flags). Writes `.rapid/COST.json` and regenerates `docs/cost.html`. The two metrics you optimize a build on — $ per phase and how often it stopped you — come from here.

- **`tools/mock-init.sh`** — Plan-phase design scaffolder (E). Run at P4 for UI projects: lays down a design-token system (`04-spec/mocks/_tokens.css`), a hi-fi screen template, a gallery, and the `04-spec/screens.md` inventory. Hi-fi comps of every screen are built before architecture; the DOM/API/data seam contracts are derived from the screens, so the backend is built to serve real screens. The comps are approved at GATE 2 and become P7's visual target.

- **`tools/post-write-hook.sh`** — A **PostToolUse** hook. On a `STATE.json` write it refreshes the docs registry; on writes to numbered folders / `decisions/` / `panels/` / `tests/` it appends a timestamped row to `CHANGES.md`. Keeps docs and changelog live, with no post-build cleanup.

- **`tools/observe-server.py`** — A Python HTTP server (default `:4040`). Agents emit JSONL events to `.rapid/observe/{agent}.jsonl`; the server merges/sorts them and serves a dashboard plus a REST API (`/api/events`, `/api/agents`, `/api/meta`). Event types include SPAWN, PHASE, GATE, READ, WRITE, TOOL, SEND/RECV, LOOP_*, DECIDE, ESCALATE, ERROR, CONTEXT, COMPLETE.

- **`observatory/`** — A React 19 + Vite + XYFlow front-end that consumes the observe-server API to draw the live agent topology, an event stream, and a health view (phase / tasks / tests / doc staleness). Components are scaffolded; the data layer (`observe-server.py`) is the working source.

---

## 6. The build phase (P6) in detail

P6 is the riskiest phase, so it runs as a **five-lead build team** — five named lead agents, each in its OWN long-lived terminal, connected over claude-peers. Roles that cannot collapse into each other:

- **planner** (team lead) — owns the plan, task decomposition, the 4 human gates, and the operator relationship.
- **coder** (build lead) — implements tasks and **fans out coding subagents** for independent work (each in an isolated git worktree so they don't conflict); 1–4 coder terminals.
- **tester** (test lead) — owns the immutable eval harness (task-00), fans out per-surface test subagents (Playwright, screenshots across viewports).
- **reviewer** (review lead) — tiered code review of every diff via **per-dimension subagents** (correctness / security / …), aggregated to one confidence-gated verdict.
- **watchdog** — auto-spawned at P6a in its own terminal; drift-checks every PR/merge against the spec and Constitution. It is *never* a coder.

**Subagents are the parallel muscle; terminals are the coordination spine.** Tracks scale the team: **full** = all five lead terminals; **fast** = planner + coder + reviewer + watchdog (tester folds into the coder's keep-or-revert ratchet); **tiny** = the whole loop as subagents under the planner. Launched via `tools/rapid-team.sh` (one tmux window per lead, or `--cursor` for VS Code tasks).

The four safety mechanisms operating here:

| Mechanism | What it does |
|---|---|
| Separate auditor (R2) | Watchdog ≠ coder — the builder can't skip its own safety checks |
| Immutable eval harness (R4) | `.rapid/EVAL/` is locked after P5 — tests are the spec, code follows |
| Keep-or-revert ratchet | On any regression after a merge, `git reset --hard` — only improvements survive |
| Worktree isolation, verified (C) | Each parallel writer records its `worktree`/`branch` on SPAWN; `tools/worktree-check.sh` fails the P6 exit gate if any writer skipped isolation or two shared one |
| Cost breaker | Pauses at 80% of token budget, forcing an explicit human choice |

---

## 7. State & persistence

A running build keeps its state in a `.rapid/` directory inside the *target* project:

| File | Role |
|---|---|
| `.rapid/STATE.json` | current phase + progress (the file the phase-gate hook guards) |
| `.rapid/TASKS.json` | task graph + per-task status |
| `.rapid/EVAL/` | test files, immutable after P5 |
| `.rapid/MEMORY.md` | append-only decisions / blockers / learnings (all agents) |
| `.rapid/COST.json` | token spend per agent, **per phase**, + **human touchpoints per phase** vs. budget |
| `.rapid/INPUTS.json` | human-input ledger — blocks P6 entry until every required input is resolved (B) |
| `.rapid/observe/{agent}.jsonl` | per-agent event stream (→ observe-server); build-writer SPAWNs carry `worktree`/`branch` (C) |
| `.rapid/AUDIT.json`, `GAPS.json`, `P6_EXIT.json`, `WALKTHROUGH.md`, `LEARNINGS.md` | watchdog findings, gap classification, build-exit assertions, walkthrough notes, compound learnings |

Phase folders (`00-vision/` … `07-gaps/`, `tests/`) hold the human-readable artifacts that the gates and `/docs` consume.

---

## 8. Governance — the Constitution

`docs/CONSTITUTION.md` defines 10 articles:

- **Articles I–V are inviolable** (truthfulness, user safety, data handling, reversibility, scope discipline). The watchdog audits these.
- **Articles VI–X are overridable with logging** (spec authority, no test theater, honest reporting, pushback, root-cause-not-symptom). The gap classifier tags violations; retrospectives review any overrides.

A copy also exists at each generated project's root so agents are checked against it before merge.

---

## 9. Where to start reading

| If you want… | Read |
|---|---|
| The pitch in 5 minutes | `README.md` |
| The full methodology narrative | `docs/methodology-deck.md` (or `docs/workflow.html`) |
| The system reference (agents, phases, primitives) | `docs/rapid-reference.md` / `docs/architecture.html` |
| How a build is actually orchestrated | `skills/rapid-workflow/SKILL.md` |
| What RAPID itself still needs | `docs/PRD.md` |
| A concrete example of a vision + pillars | `examples/vision/` |
| What changed and when | `CHANGELOG.md` |

---

*`rapid-workflow` = the repo; RAPID = the methodology; `/rapid-workflow` = the skill that runs it; the 12-phase pipeline + 4 gates + five-lead build team + safety mechanisms (R1–R9) = the machine.*
