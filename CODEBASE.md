# rapid-workflow — Codebase Guide

> A walkthrough of what this repository is, what lives in it, and how the pieces fit together.
> Written 2026-05-29. Current version: **v0.5.0**.

---

## 1. What this repo is

`rapid-workflow` is **not a product repo** — it contains no shipped application. It is the home of **FORGE**, Johnny's operationalized methodology for autonomous, AI-driven product builds. The repo holds the *method* (skills, hooks, tools, templates, docs); when you actually run FORGE, it generates the build artifacts (specs, tests, decks) **inside the target project's repo**, not here.

The one-line thesis behind everything:

> **The agent that writes the code must never be the agent that audits it.** When one agent does both, visible progress (a working app) always beats invisible safety (tests, reviews). FORGE separates those roles *structurally* — via hooks, separate terminals, and tiered reviewers — not with prose instructions that fail under pressure.

FORGE turns a vague idea or a PRD into a tested, deployed system through a deterministic, gate-enforced pipeline. Its design draws on Karpathy (eval-first, keep-or-revert), Beck (TDD), Zaharia et al. (Compound AI Systems), and Every Inc. (Compound Engineering — tiered review, learning capture, doc agents, optimization loops).

---

## 2. The pipeline at a glance

FORGE runs as **12 phases** punctuated by **4 human gates**, organized into three arcs:

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
[G2] Architecture  operator approves spec, hands over keys — point of no return
   │
   ▼  ── Arc 3: EXECUTE & CONVERGE ────────────────────────
 P6  Build         3-terminal swarm (see §6)
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
├── CHANGELOG.md           version history (currently v0.5.0)
├── CODEBASE.md            ← this file
├── docs.json              docs registry snapshot
│
├── skills/                the four Claude Code skills (symlinked to ~/.claude/skills/)
│   ├── forge/SKILL.md       orchestrator — runs the 12-phase pipeline
│   ├── workflow/SKILL.md     alias → /forge
│   ├── decision/SKILL.md     /decision — decision + panel documentation
│   └── docs/SKILL.md         /docs — generates Reveal.js documentation decks
│
├── tools/                 operational scripts (run from a target project root)
│   ├── observe-server.py     live observability dashboard server (:4040)
│   ├── phase-gate-hook.sh    PreToolUse hook — BLOCKS phase advance w/o artifacts
│   ├── post-write-hook.sh    PostToolUse hook — updates registry + CHANGES.md
│   ├── build-docs-registry.sh helper for the post-write hook
│   └── forge-spec.html       large HTML reference (superseded by docs/architecture.html)
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
│   ├── PRD.md                FORGE's own product requirements
│   ├── methodology-deck.md   18-slide methodology walkthrough (source)
│   ├── forge-reference.md    text version of the system reference (D0–D16)
│   ├── architecture.html     interactive system reference (D0–D21)
│   ├── workflow.html, specification.html, prd.html, prd-enhanced.html,
│   ├── eval.html, users.html, documentation.html, observatory.html
│
├── examples/vision/       reference VISION.md + PILLARS.md (SuperBuilders tutor)
└── archive/               superseded decks/dashboards kept for reference
```

---

## 4. The four skills

All four live in `skills/` (the source of truth) and are symlinked into `~/.claude/skills/` so Claude Code can find them. Editing here and committing tracks the change in git.

### `/forge` — the orchestrator
`skills/forge/SKILL.md` (~1100+ lines). Runs the full pipeline.

```
/forge <idea or PRD path> [--track fast|full] [--resume] [--gap-loop]
/forge status
```

It separates **deterministic** components (same every run — the 12 phases, 4 gates, 4 safety mechanisms) from **dynamic** components composed per project:

| Dynamic per project | Example |
|---|---|
| Pillars (3–5) | derived from the project's risks + goals |
| Constitution Articles VI–X | tailored to the safety domain |
| Panels (1–3) | domain-selected, panelists named per project |
| Reviewer weights | security-heavy for healthcare, perf-heavy for real-time |
| Agent topology | orchestrator + supervisor + ≤4 implementors + watchdog |
| Eval harness | generated from the workflow state machine, then locked |

### `/workflow` — alias
`skills/workflow/SKILL.md`. Passes all arguments straight through to `/forge`.

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

This is where FORGE's safety thesis becomes mechanical. Prose can be ignored under pressure; hooks cannot.

- **`tools/phase-gate-hook.sh`** — Installed as a **PreToolUse** hook on writes to `.forge/STATE.json`. It *blocks* a phase transition unless that phase's required artifacts already exist. E.g. you cannot enter Phase 6 (Build) without `.forge/EVAL/` containing ≥1 test file and `.forge/TASKS.json`; you cannot enter Phase 7 without `.forge/P6_EXIT.json` showing all assertions passing.

- **`tools/post-write-hook.sh`** — A **PostToolUse** hook. On a `STATE.json` write it refreshes the docs registry; on writes to numbered folders / `decisions/` / `panels/` / `tests/` it appends a timestamped row to `CHANGES.md`. Keeps docs and changelog live, with no post-build cleanup.

- **`tools/observe-server.py`** — A Python HTTP server (default `:4040`). Agents emit JSONL events to `.forge/observe/{agent}.jsonl`; the server merges/sorts them and serves a dashboard plus a REST API (`/api/events`, `/api/agents`, `/api/meta`). Event types include SPAWN, PHASE, GATE, READ, WRITE, TOOL, SEND/RECV, LOOP_*, DECIDE, ESCALATE, ERROR, CONTEXT, COMPLETE.

- **`observatory/`** — A React 19 + Vite + XYFlow front-end that consumes the observe-server API to draw the live agent topology, an event stream, and a health view (phase / tasks / tests / doc staleness). Components are scaffolded; the data layer (`observe-server.py`) is the working source.

---

## 6. The build phase (P6) in detail

P6 is the riskiest phase, so it uses a **3-terminal architecture** with roles that cannot collapse into each other:

- **Orchestrator** — monitors, manages the tmux session, routes messages.
- **Supervisor** (separate terminal) — assigns tasks, runs smoke tests.
- **Implementors** — up to **4** worktree agents writing code in parallel (isolated git worktrees so they don't conflict).
- **Watchdog** (separate terminal) — runs on a `/loop 30m`, drift-checks every PR/merge against the spec and Constitution. It is *never* an implementor.

Supporting roles: 5 tiered **reviewers** (confidence-gated, different lenses), a **tester** (Playwright, screenshots across 3 viewports), and **visual QA**.

The four safety mechanisms operating here:

| Mechanism | What it does |
|---|---|
| Separate auditor (R2) | Watchdog ≠ implementor — builder can't skip its own safety checks |
| Immutable eval harness (R4) | `.forge/EVAL/` is locked after P5 — tests are the spec, code follows |
| Keep-or-revert ratchet | On any regression after a merge, `git reset --hard` — only improvements survive |
| Cost breaker | Pauses at 80% of token budget, forcing an explicit human choice |

---

## 7. State & persistence

A running build keeps its state in a `.forge/` directory inside the *target* project:

| File | Role |
|---|---|
| `.forge/STATE.json` | current phase + progress (the file the phase-gate hook guards) |
| `.forge/TASKS.json` | task graph + per-task status |
| `.forge/EVAL/` | test files, immutable after P5 |
| `.forge/MEMORY.md` | append-only decisions / blockers / learnings (all agents) |
| `.forge/COST.json` | token spend per agent vs. budget |
| `.forge/observe/{agent}.jsonl` | per-agent event stream (→ observe-server) |
| `.forge/AUDIT.json`, `GAPS.json`, `P6_EXIT.json`, `WALKTHROUGH.md`, `LEARNINGS.md` | watchdog findings, gap classification, build-exit assertions, walkthrough notes, compound learnings |

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
| The system reference (agents, phases, primitives) | `docs/forge-reference.md` / `docs/architecture.html` |
| How a build is actually orchestrated | `skills/forge/SKILL.md` |
| What FORGE itself still needs | `docs/PRD.md` |
| A concrete example of a vision + pillars | `examples/vision/` |
| What changed and when | `CHANGELOG.md` |

---

*RAPID = the repo; FORGE = the methodology; `/forge` = the skill that runs it; the 12-phase pipeline + 4 gates + 3-terminal swarm + 4 safety mechanisms = the machine.*
