# FORGE — Autonomous Build System Reference

## The Core Principle: Separate the Builder from the Auditor

The agent implementing the code must never be the same agent auditing the code. When one agent does both, the implementor always wins — it produces visible progress, while the auditor produces invisible safety. Under pressure, invisible work gets skipped. Every time. This isn't a discipline problem. It's an incentive misalignment that prose instructions cannot fix.

Every enforcement mechanism in FORGE exists because of this principle: hooks that block advancement (R1), a separate watchdog terminal (R2), blocking task dependencies (R4), tiered reviewers as independent subagents, and document review agents that pre-screen before the operator sees anything. If a step is described in words but not enforced structurally — that step will eventually be skipped.

---

FORGE is not a fixed system — it's a **template that generates a project-specific build system** every time it runs. The pipeline structure (12 phases, 4 gates) is constant, but everything inside is derived dynamically from the input: the pillars come from the project's risks, the panels come from the project's domain, the agent count comes from the task graph's parallelism, the tests come from the workflow state machine, and the Constitution's Articles VI–X are tailored to the project's specific safety concerns.

This means no two FORGE builds produce the same architecture. A healthcare AI security platform generates different pillars, different panels (security-expert-panel, not user-panel), different reviewer configurations (Security reviewer weighted highest), and different Constitution overridables than a children's math tutor. The pipeline is the scaffold; the project fills it.

**Technically:** A 12-phase autonomous build pipeline with 4 human gates, 4 safety mechanisms, a 3-terminal architecture during build phase, tiered multi-agent code review, compound learning capture, and document review agents at every gate. Takes a product idea or PRD, produces a deployed, spec-compliant application. Start with D0 (full architecture), then drill into D1–D19 for detail.

### How the architecture adapts per project

| Component | What's constant (the template) | What's derived per project |
|---|---|---|
| **Pipeline** | 12 phases in fixed order, 4 gates | — |
| **Pillars** (P0) | Format: 3–5 evaluation questions | Content: derived from project risks and goals — never generic |
| **Constitution** (P1) | Articles I–V inviolable | Articles VI–X tailored to project safety concerns |
| **PRD Decomposition** (P1b) | MUST/SHOULD/COULD categorization | Requirements, assumptions, constraints from the specific PRD |
| **Panels** (P2) | 1–3 panels, convergent/divergent synthesis | Which panels: technical, business, SME — chosen by domain. Panelists named per project. |
| **Research** (P3) | VERIFIED/UNVERIFIED/OPEN protocol | Questions from the specific panel synthesis |
| **Spec** (P4) | Derived from PRD with maintained diff | Sections, workflow nodes, interfaces — all project-specific |
| **Agent topology** (P5) | Orchestrator + supervisor + ≤4 impl + watchdog | Fan-out count from task dependency graph. Reviewer weights from project domain. |
| **Eval harness** (P5) | Generated from workflow state machine, immutable | Tests are project-specific — every workflow node becomes a test case |
| **Code review** (P6) | 5 reviewer types with confidence gating | Reviewer weights shift by domain (security heaviest for healthcare, performance heaviest for real-time) |
| **Learnings** (P6e) | Structured format: context, learning, evidence, reuse | Content from the specific build. Future builds of the same project read prior learnings. |
| **Prompt files** (P6a) | Role definitions, message contract | Task references, spec sections, project paths — all project-specific |
| **Product Pulse** (P10) | Report format: metrics, issues, actions | Data sources, dashboards, thresholds — from the specific deployment |

The compound loop (P10 → P0) means each build of the same project starts with more context: prior learnings, prior pulse reports, prior gap patterns. The system gets smarter per project, not just per build.

---

## D0 — Full System Architecture

**The complete system: pipeline, agents, safety mechanisms, data flows, and communication — all in one view.**

Every other diagram (D1–D16) is a detail view of a region in this diagram. Columns: left = agents, center = pipeline phases, right = safety & data. Read top to bottom.

Legend: 🟢 Autonomous phase · 🟡 Human gate · 🔴 Safety / guard · 🔵 Data store · 🔄 Feedback loop · ⚪ Prompt injection (all agents)

### Config Layer

| Agents | Pipeline Phase | Safety & Guards | Data Written |
|---|---|---|---|
| — | forge.yaml loaded (D14) | ⚪ Decision Router (D5) injected into all agents | .forge/STATE.json, .forge/MEMORY.md, .forge/COST.json |

### Arc 1: Understand

| Agents | Pipeline Phase | Safety & Guards | Data Written |
|---|---|---|---|
| **Orchestrator** (skill) | P0: Vision → P1: Structure | — | 00-vision/*.md, 01-intake/PRD.md (locked), CONSTITUTION.md |
| **Panelist** (skill ×1 fast / subagent ×3 full) | P2: Expert Panels | 🔴 Anti-hallucination (D6): source citation required | 03-panels/synthesis.md |
| **Researcher** (subagent ×N, 15m timebox each) | P3: Research | 🔴 VERIFIED / UNVERIFIED / OPEN classification (D6) | 02-grounding/*.md, vendor cost projections |
| ⏸ **OPERATOR** | **G1: Direction (D3)** | Approve / Redirect / Add context | operator notes → MEMORY.md |

### Arc 2: Specify

| Agents | Pipeline Phase | Safety & Guards | Data Written |
|---|---|---|---|
| **Spec Writer** (subagent) | P4: Spec Derivation | 🔴 Inter-stage assertion: every PRD req → spec section | 04-spec/spec.md, 04-spec/workflow.md, 04-spec/architecture.md, 04-spec/CONTRACTS.md |
| **Spec Writer** (continues) | P5: Tasks + Eval + CI | 🔴 Assertion: tasks cover spec · 🔴 Eval harness LOCKED (D7b) — agents cannot modify tests | .forge/TASKS.json, .forge/EVAL/ (immutable), 04-spec/agents/*.md, .github/workflows/ (D11) |
| ⏸ **OPERATOR** (point of no return) | **G2: Architecture (D3)** | Approve / Modify / Rescope · Provide API keys + .env | .env (gitignored) |

### Arc 3: Execute + Converge

| Agents | Pipeline Phase | Safety & Guards | Data Written |
|---|---|---|---|
| **Orchestrator** (monitors, tmux manager) · **Supervisor** (tmux terminal, spawned P6a, killed P6e) → **Impl 1–4** (worktree agents, fan-out 1–4, D7) · **Watchdog** (tmux terminal, spawned P6a, killed P6e, /loop 30m) | P6: Build (D8) — 3-terminal architecture: orchestrator monitors, supervisor assigns tasks + runs smoke tests, watchdog drift-checks on PR/merge/30m. Communication via claude-peers (11 message types). Shutdown handshake at P6 end. | 🔴 Watchdog (D4) on PR_SUBMITTED + PR_MERGED + /loop 30m · 🔴 Reviewer: spec + constitution per PR · 🔴 Keep-or-revert: regression = git reset · 🔴 Cost breaker (D12): pause at 80% · 🔴 DRIFT_CRITICAL → orchestrator (emergency halt) | git branches, .forge/AUDIT.json, .forge/MEMORY.md, .forge/COST.json, .forge/MESSAGES.json, .forge/prompts/, TASKS.json (status) |
| **Tester** (subagent + Playwright), **Visual QA** (screenshots + vision) | P7: Test + Visual QA (D10) | 🔴 Immutable eval harness · 🔴 Visual: 3 viewports · fix → screenshot → check ×3 | test results, screenshot evidence, .forge/GAPS.json |
| **Orchestrator** (classifies gaps) | P8: Gap Loop (D9) — classify by pillar + severity · spec-level: re-derive § → rebuild · PRD-level: queue for G3 · 🔄 loop to P6 (×3 max) | 🔴 Auto re-derivation (spec-level only) · PRD gaps → operator | .forge/GAPS.json (updated), 01-intake/DIFF.md, 04-spec/spec.md (re-derived) |
| ⏸ **OPERATOR** | **G3: Ship Decision (D3)** | Evidence: app, audit, gaps, tests, screenshots, cost | Ship / Loop / Redirect / Kill |
| **Orchestrator** (deploys) | P9: Deploy + Document | CI/CD pipeline (D11) runs on final merge | README.md, RUNBOOK.md, .forge/RETRO.md, STATE: shipped |

### Cross-cutting: Communication & Observability (D13)

- **.forge/MEMORY.md** — append-only · all agents · persistent
- **claude-peers MCP** — real-time nudges · inter-terminal
- **forge.yaml config (D14)** — 3-level cascade · model routing
- **CONSTITUTION.md** — Art. I–V inviolable · checked every PR

---

## D1 — Master Pipeline

**The complete pipeline: 10 phases, 3 gates, 1 feedback loop.**

```
Idea/PRD → P0:Vision → P1:Structure → P2:Panels → P3:Research → [G1] → P4:Spec → P5:Tasks → [G2] → P6:Build → P7:Test → P8:Gaps ↻ → [G3] → P9:Deploy → Ship
```

Legend: 🟢 Autonomous · 🟡 Human gate · 🔄 Gap loop (×3 max)

**Three arcs.** P0–P3 = Understand (challenge requirements). P4–P5 = Specify (derive buildable contract). P6–P9 = Execute + Converge (build, test, loop, ship). The gap loop (P8) re-derives the spec on failure — the code follows. Arc 3 is cyclical; Arcs 1–2 are linear.

**Eval-first / TDD invariant.** Before P6 begins, P5 generates an immutable eval harness from the workflow state machine (P4). Tests are written before code, generated from spec — not by the implementing agent. Agents cannot modify their own success criteria. The branch only advances on verified improvement (keep-or-revert ratchet). *Sources: Karpathy autoresearch loop (program.md: "prepare.py is read-only"); Kent Beck, Test-Driven Development (2002): red-green-refactor with the test surface owned by a separate concern.*

**Inter-stage assertions.** Between each phase, programmatic contract checks run automatically. These are blocking — the pipeline cannot advance until the assertion passes. Assertion failure = automatic retry with the violation message appended.

- **After P2/P3 (agent output persistence):** Every background agent's result must be written to its designated docs/ file before the orchestrator proceeds. Panel results → `03-panels/`, research results → `02-grounding/`. The orchestrator must not consume agent output only in context — context is disposable, files are the record.
- **After P4:** Every PRD requirement maps to a spec section or explicit `[OUT OF SCOPE]` tag.
- **After P5 (eval completeness):** Every node in workflow.md has a corresponding test file and at least one test function. Every spec section (S1, S2, ...) has at least one test that exercises it. The orchestrator enumerates workflow nodes and spec sections, then verifies test file existence. Missing coverage = phase fails.
- **After P6 (spec coverage):** Every spec section has implementing code. Every public interface in CONTRACTS.md exists in the codebase. Architecture.md file structure matches actual repo structure. Any external API the code calls has been verified by actually calling it (mock or real).

*Source: Zaharia et al., "The Shift from Models to Compound AI Systems" (Berkeley AI Research, 2024); DSPy Assert/Suggest pattern.*

---

## D2 — Agent Topology

**10 agents mapped to pipeline phases, each selected for isolation and cost.**

Three primitives: skill (orchestrator's context), agent/subagent (own context), prompt injection (behavioral rule). See D7 for fan-out sizing.

```
                    Forge Orchestrator (Skill · persistent · all phases)
                                    │
              ─────────── Arc 1: Understand (P0–P3) ───────────
              │                                                │
     Panelist (skill×1 or subagent×3, P2)        Researcher (subagent×N, P3)
                                    │
                            [Gate 1: Direction]
                                    │
              ─────────── Arc 2: Specify (P4–P5) ──────────
                                    │
                        Spec Writer (subagent, P4–P5)
                                    │
                          [Gate 2: Architecture]
                                    │
          ──────── Arc 3: Execute + Converge (P6–P9) ────────
                                    │
                    Supervisor (separate terminal, P6)
                        │       │       │       │
                     Impl 1  Impl 2  Impl 3  Impl 4  (worktrees)
                                    │
                   Reviewer · Watchdog · Tester · Visual QA
                                    │
                          [Gate 3: Ship Decision]
```

### D2b: Primitive selection rationale

| Role | Primitive | Rationale | Observability |
|---|---|---|---|
| Orchestrator | Skill | Needs operator context, approvals, API keys | .forge/STATE.json |
| Panelist ×1–3 | Skill (fast: 1) / Subagent (full: 3) | Fast: stays in orchestrator context. Full: 3 agents parallel, 3x context cost. | 03-panels/*.md |
| Researcher | Subagent | Needs WebSearch, 15m timebox | 02-grounding/*.md |
| Supervisor | Terminal | Long-running, manages task queue | .forge/MEMORY.md |
| Implementor ×4 | Agent (worktree) | Parallel code; git isolation prevents conflicts | Branch git log |
| Reviewer | Subagent | Reads PR + spec, returns verdict. Optional 2nd model (Codex). | .forge/MEMORY.md |
| Watchdog | Event + /loop 30m | On PR submit, on merge, every 30m on main. Never checks WIP. | .forge/AUDIT.json |
| Tester | Subagent + Playwright | Runs tests + screenshots | .forge/GAPS.json |
| Decision Router | Prompt injection | Behavioral rule, no tools, all agents | MEMORY.md |

Communication: .forge/MEMORY.md (append-only, all agents) + claude-peers MCP (real-time nudges between terminals). Naming: forge/{phase}/{task-slug} branches, [SPEC §X.Y] commits.

### D2c: Primitive decision tree

```
New role needed. Which primitive?
    │
Does it need to take actions (tools, file writes, shell)?
    │
    ├── No → Is it a behavioral rule or a task?
    │         ├── Rule → PROMPT INJECTION (zero cost, baked into every agent prompt)
    │         └── Task → SKILL (runs in orchestrator's context, no duplication)
    │
    └── Yes → Does it need the orchestrator's conversation context?
              ├── Yes → SKILL (sees approvals, API keys, prior conversation, sequential)
              └── No → Does it write files that could conflict with others?
                        ├── No → SUBAGENT (own context, parallelizable, short-lived)
                        └── Yes → Long-running (>1 task)?
                                  ├── No → AGENT (worktree) (git-isolated, one task, PR on completion)
                                  └── Yes → SEPARATE TERMINAL (persistent session, claude-peers)
```

**Cost implications:** Prompt injection = free. Skill = orchestrator's context (no duplication). Subagent = own context window (~1x duplication). Agent (worktree) = own context + git branch overhead. Separate terminal = fully independent, highest cost.

**Parallelism:** Skills are sequential. Subagents and worktree agents can run in parallel. Separate terminals are fully independent.

---

## D3 — Human Gates

**3 decision points where the pipeline pauses for operator input.**

Escalation format enforced: every question includes options, recommendation, reversibility. See D5 for how non-gate decisions are routed.

```
Phase completes → System presents structured artifacts → Operator reviews
    │
    ├── Approve → Pipeline continues
    ├── Redirect → Re-run prior phases with operator notes
    └── Kill → (Gate 3 only)
```

### G1: Direction
- **System presents:** Vision, pillars, panel synthesis, research decisions, spec outline
- **Operator provides:** Strategic direction, domain constraints, priority ranking
- **Position:** Cheapest change point (D1 between P3–P4)

### G2: Architecture
- **System presents:** Full spec, workflow, architecture, tasks, cost projection
- **Operator provides:** API keys, credentials, deploy target, sign-off
- **Position:** Point of no return (D1 between P5–P6)

### G3: Ship
- **System presents:** Working app, compliance audit, test results, gap report, cost actuals
- **Operator provides:** Ship / another gap loop / redirect / kill
- **Position:** Final approval (D1 between P8–P9)

---

## D4 — Drift Detection

**7-category watchdog: triggered on PR submission, merge, and periodic audit — never on work-in-progress.**

The watchdog does not run on a blind timer against in-progress worktrees — agents mid-implementation will always fail checks because the work isn't done. It triggers at 3 specific points where the code is claimed to be complete.

### D4a: Trigger points

1. **On PR submission** — Check the PR diff only. Primary gate — catches drift before it merges.
2. **On merge to main** — Check integrated state of full repo. Catches cross-task drift.
3. **Periodic (every 30m)** — Main branch only. Full-repo audit. Catches accumulated drift across merges.

### D4b: Drift-detection flow

```
Read target (PR diff or main HEAD) → Diff vs spec.md → Diff vs CONTRACTS.md → Check 7 categories → Classify
    │
    ├── CLEAN → PR approved to proceed to reviewer. Log to AUDIT.json.
    ├── DRIFT → Block PR. Notify supervisor. Trigger D8 bug-fix loop.
    └── CRITICAL → Halt build. Alert operator. Invariant violated. Cannot be auto-fixed.
```

**7 categories:**
- 🔴 **Structural** — files match architecture.md
- 🔴 **Interface** — APIs match CONTRACTS.md
- 🔴 **Invariant** — core rules hold (CRITICAL)
- 🟡 **Feature** — no unspec'd additions
- 🟡 **Test** — coverage, no weakened assertions
- 🟡 **Quality** — strict types, no `any`
- 🟣 **Visual** — screenshot at 3 viewports, Claude vision checks for overlaps/clips/breaks (see D10)

---

## D5 — Decision Router

**How agents classify decisions: act silently, log, escalate, or queue for gate.**

Injected into every agent prompt (D2). Prevents agents from pausing the build for trivial decisions or making irreversible choices without approval.

```
Agent encounters decision → Classify: reversible?
    │
    ├── Tactical (naming, style, imports) → Decide silently
    ├── Technical (library, pattern, cache) → Decide + log to MEMORY.md
    ├── Architectural (new dep, interface change) → Escalate to supervisor (with options + rec)
    └── Strategic (scope, pivot, drop) → Queue for gate (irreversible, D3)
```

**Stall protocol:** no commit in 15m → supervisor checks → 3 retries → escalate with what was tried. See D8.

---

## D6 — Research Protocol

**How panels and research agents produce grounded, traceable evidence.**

Every claim classified as VERIFIED, UNVERIFIED, or OPEN. OPEN questions surface at G1 (D3).

```
Panel flags question → Spawn researcher → WebSearch + docs → 3+ options + matrix → Classify
    │
    ├── VERIFIED — Source confirmed, API tested. Include in spec (P4).
    ├── UNVERIFIED — Assumption flagged. Fallback plan required.
    └── OPEN — 15m timebox expired. Surface at Gate 1 (D3).
```

**Research agent output format:** Question (from panel), Options (min 3 with cost/perf/complexity matrix), Evidence (primary sources, version-pinned), Recommendation (with falsifiable assumptions), Fallback (what to do when recommendation fails), Verification (how to confirm at runtime).

**Three review lenses:** Technical (benchmarks, not intuition), Business (TAM, unit economics, regulatory), Domain SME (what tech panels miss: microstructure, clinical safety, cultural sensitivity). Domain errors = BLOCKER severity.

*Lesson from ASL project: research assumed 200 training clips available; actual was 52. Forge verifies data availability in P3, not P6.*

---

## D7 — Fan-Out Sizing

**How the system determines implementor count during P5 (Task Decomposition).**

Based on task count, dependency parallelism, and reviewer capacity. Cap: ≤4 (beyond 4, review quality degrades).

```
Analyze spec: count tasks, map dependencies → Identify max parallelizable tasks
    │
    ├── ≤5 tasks, linear → 1 impl (fast track)
    ├── 6–12 tasks, 2–3 parallel → 2 impl (moderate)
    └── 13+ tasks, 3+ parallel → 3–4 impl (complex)
```

Constraint: reviewer (D2) must honestly review all PRs. >4 concurrent implementors degrades review quality.

---

## D7b — Test-Driven Development

**Tests generated from workflow state machine before any code is written.**

The eval harness is immutable once generated — implementing agents cannot weaken, skip, or modify tests. This is the TDD red-green-refactor cycle, enforced structurally rather than by discipline. *Sources: Kent Beck, TDD (2002); Karpathy autoresearch "prepare.py is read-only."*

```
P4: Workflow state machine (every node = in / proc / out)
    │
    ▼
Generate eval harness
    │
    ├── Each node (golden path) → arrange: from "in" · act: from "proc" · assert: from "out"
    ├── Each branch (edge case) → negative test: invalid input → expected error
    └── Each failure path (recovery) → failure → retry → fallback → verify recovery state
    │
    ▼
Lock eval harness → .forge/EVAL/ (immutable — agents cannot modify)
```

The eval harness is the contract between spec and implementation. Tests fail red before code exists (TDD). Code must make them green. Agents refactor freely as long as tests stay green. Regressions trigger git reset (D8 keep-or-revert).

**P5 exit gate (blocking):** Before P5 completes, the orchestrator must verify:
1. Every node in workflow.md has at least one test function in `.forge/EVAL/` or the project test directory.
2. Every spec section (S1, S2, ...) is referenced by at least one test.
3. If a workflow node or spec section has no test, the orchestrator generates the missing test stub and flags it — P5 does not complete until coverage is verified.

This prevents the failure mode where the orchestrator writes tests for the components it finds interesting and silently skips the rest. The workflow state machine is the authoritative test plan — if a node exists, a test must exist.

---

## D8 — Build & Bug-Fix Loop

**How code is written, reviewed, and fixed without human intervention.**

Implements keep-or-revert ratchet: the branch only advances on verified improvement. Failed tests trigger a 3-attempt fix loop before escalation. *Source: Karpathy autoresearch (program.md: "improvements advance the branch; regressions git reset --hard").*

```
Supervisor assigns task to implementor (includes spec section, contracts, eval harness)
    │
    ▼
Implementor writes code in worktree (commits reference [SPEC §X.Y])
    │
    ▼
Run eval harness (immutable tests from P5 — agents cannot modify)
    │
    ▼
Tests pass?
    │
    ├── Yes → Submit PR → Reviewer checks (spec, constitution, types) → Watchdog clears (D4) → Merge · advance branch
    │
    └── No → Classify failure
              ├── Code bug → Fix + re-test (↻ ×3 max)
              ├── Spec gap → Route to D9
              └── Environment → Escalate (with 3 attempts documented)
```

**Keep-or-revert (Karpathy):** if tests regress from last passing commit, git reset --hard to last good state. Branch never gets worse.

---

## D9 — Gap Loop

**The convergence mechanism: classify failures, re-derive spec, rebuild.**

The core mechanism that separates Forge from a one-shot build. Spec-level gaps auto-rederive. PRD-level gaps surface at G3 (D3). Max 3 iterations.

```
Build (P6) → Test + Walk (P7) → Extract gaps → Classify by pillar + severity
    │
    ├── Spec-level gap (missing requirement, wrong interface)
    │       → Re-derive spec §X.Y → Rebuild affected tasks only → Re-test → ↻ Loop to Build (×3 max)
    │
    └── PRD-level gap (missing context, wrong requirement)
            → Queue for Gate 3 (D3) — operator decides direction
```

**Severity levels:**
- 🔴 **BLOCKER** — Invariant broken. Build halted.
- 🟡 **HIGH** — Feature incomplete. Auto re-derive.
- 🔵 **MEDIUM** — Edge case. Next loop.
- ⚪ **LOW** — Polish. Can ship.

---

## D10 — Visual QA Loop

**Screenshot-driven UI verification at 3 viewports.**

Catches overlapping text, clipped elements, broken layouts that code review cannot see.

```
UI change merged → Playwright screenshots (mobile / tablet / desktop) → Claude vision analysis (overlaps? clips? breaks?)
    │
    ├── Pass → Continue to next task
    └── Fail → Implementor fixes UI → Re-screenshot → Re-check (↻ ×3 max) → Still failing? Escalate with screenshots
```

---

## D11 — CI/CD Pipeline

**Auto-generated pipeline that makes D4 (watchdog) permanent infrastructure.**

Generated during D1 P5. Runs on every PR and every merge to main. The drift-check stage reads spec.md directly. Platform: GitHub Actions or GitLab CI (configurable).

```
PR opened → lint → test → build → drift-check (D4) → constitution (Art. I–V) → visual-qa (D10) → deploy (preview on PR, prod on main)
```

Any stage failure = blocked merge. Spec changes trigger re-validation of all existing code. Inputs: spec.md, CONTRACTS.md, workflow.md.

---

## D12 — Economics

**Three cost layers tracked at different timescales.**

Build tokens (one-time), runtime infra (monthly), deployed agent effectiveness (per-request). Each layer surfaces at a specific gate (D3). Cost circuit-breaker halts build at 80% of budget cap.

```
P3: Research (vendor comparison) → G1 (cost projection) → P5: Tasks (token budget per phase/agent) → G2 (infra cost approved) → P6: Build (COST.json updated per call) → 80% budget? (circuit-breaker) → G3 (actual vs projected)
```

### Build Tokens
$15–$80 per build (Claude Max). Levers: subagents (short context), checkpoint+resume, model routing (Sonnet for panels, Opus for code).

### Runtime Infra
Projected at P3, locked at G2. Vendor eval: cost at 1K/10K/100K MAU, lock-in risk, latency p50/p99, DX.

### Agent Effectiveness
If app ships with AI: $/request, cache hit rate (90% = 90% savings), model routing (Haiku/Sonnet/Opus), token budget per endpoint.

---

## D13 — Observability

**How every agent, phase, and safety mechanism writes to a shared state layer.**

Two communication channels: file-based (persistent, survives crashes) and claude-peers (real-time, inter-terminal). The operator queries state from any terminal at any time.

### D13a: Data flow

| .forge/ file | Written by | Read by | Update frequency |
|---|---|---|---|
| STATE.json | Orchestrator | All agents, /forge --resume | After every phase + gate |
| MEMORY.md | All agents (append-only) | All agents, operator | On every decision, assignment, escalation |
| TASKS.json | Spec writer (P5), supervisor (P6) | Supervisor, implementors, operator | On task assign/complete/block |
| AUDIT.json | Watchdog | Supervisor, reviewer, operator | On PR submit, merge, and every 30m |
| GAPS.json | Tester (P7), gap loop (P8) | Orchestrator, operator | After test runs + walkthrough |
| COST.json | Orchestrator (per agent call) | Budget circuit-breaker, operator | After every agent spawn/return |
| EVAL/ | Spec writer (P5) — then locked | All implementors, tester | Written once, immutable |

### D13b: Agent output persistence invariant

**When a background agent completes, the orchestrator MUST write its full result to the designated docs/ file BEFORE consuming it for decisions or proceeding to the next phase.** This is a blocking invariant, not a best practice.

Rationale: Agent results returned to the orchestrator live only in the conversation context. Context is compressible, losable, and invisible to future sessions. Files are the record. If a panel ran but its findings aren't in `03-panels/`, the panel effectively didn't run — the gap loop, the operator at gates, and future `/forge --resume` runs all read from files, not from conversation history.

Enforcement: After every agent spawn/return, the orchestrator checks that the designated output file exists and is non-empty. If not, the orchestrator writes it immediately. This is logged to MEMORY.md.

### D13c: Communication channels

**File-based (.forge/)** — persistent, survives crashes
- MEMORY.md: append-only, timestamped
- Contents: Decisions, Assignments, Escalations, Drift reports
- All agents read before acting. All agents write under own heading. No overwrites, no deletions.

**claude-peers MCP** — real-time, inter-terminal
- send_message / check_messages: nudges between terminals
- Types: Stall nudge, Drift alert, Build halt
- set_summary on spawn so operator sees what each terminal is doing.

### D13d: Health signals

| Status | Condition | Action |
|---|---|---|
| HEALTHY | All impl committing. Watchdog: CLEAN. Cost: under budget. | Continue |
| STALLED | No commit in 15m | Supervisor nudges (D5). 3 nudges unanswered → escalate to operator. |
| DRIFTED | Spec violation (D4) | PR blocked. If invariant: halt build. Trigger D8 bug-fix. |
| BLOCKED | Needs external input (API key, service acct) | Queued for next gate (D3). Build continues elsewhere. |
| OVER BUDGET | COST.json ≥ 80% cap | Circuit-breaker (D12). Pause build, alert operator. Resume or kill. |

### D13e: Operator queries

```bash
# Current phase and status
cat .forge/STATE.json | jq '.phase, .status'

# Any blockers or escalations?
grep "ESCALATE\|BLOCKED\|STALL" .forge/MEMORY.md

# Incomplete tasks
cat .forge/TASKS.json | jq '[.[]|select(.status!="done")]'

# Latest drift report
cat .forge/AUDIT.json | jq '.latest'

# Token spend so far
cat .forge/COST.json | jq '.total, .by_phase'

# Who's running? (inter-terminal)
claude-peers list_peers --scope repo

# Resume after crash or context limit
/forge --resume
```

---

## D14 — Configuration

**forge.yaml: 3-level override cascade controlling all agent and build behavior.**

```
~/.forge/forge.yaml (global defaults) → .forge/forge.yaml (project overrides) → CLI flags (invocation overrides) → Merged config (read by all agents on spawn)
```

```yaml
# Code, Design, Communication
code:  { typescript: { strict: true, no_any: true }, comments: minimal }
design: { theme: dark, viewport: single-screen, density: compact }
communication: { verbosity: terse, summaries: false, emojis: false }
agents: { stall: "15m", retries: 3, prefix: "[SPEC §X.Y]" }

# Build, Budget, Models
build:  { track: fast, max_impl: 4, gap_max: 3, ci: github }
budget: { max_build: "$100", alert: "$50", runtime_cap: "$200" }
models:
  default: claude-opus
  overrides:
    panelist: claude-sonnet
    code_reviewer: { primary: claude-opus, secondary: codex }
```

---

## D15 — Trust Model

**Why the operator can walk away between gates: every autonomous phase has a catch mechanism.**

Each row shows what was previously manual, what replaces it, what catches failure, and what evidence the operator sees.

| Previously manual | Forge mechanism | What catches failure | Operator sees at gate |
|---|---|---|---|
| Synthesize 3 panel outputs | Auto-synthesis (P2) | Inter-stage assertion: every PRD req → spec section | G1: synthesis with flagged divergences |
| Research trade-offs | Research agents with required format (D6) | VERIFIED / UNVERIFIED / OPEN classification | G1: trade-off matrices with sources |
| Derive spec, tag every requirement | Spec writer with PRD trace (P4) | Assertion: every PRD req → spec or [OUT OF SCOPE] | G2: full spec with traceable tags |
| Write tests manually | Eval harness from workflow (D7b) | Tests are immutable — agents cannot weaken them | G2: test count + coverage map |
| Review every PR for compliance | Reviewer + optional 2nd model (D8) | Watchdog on PR submit + merge + 30m audit (D4) | G3: audit report with drift scores |
| Classify bugs: code vs spec vs env | Bug-fix loop with typed classification (D8) | Keep-or-revert: branch never gets worse | G3: gap report with resolution status |
| Decide if gap is spec vs PRD level | Gap classifier routes automatically (D9) | Spec-level auto-fixes; PRD-level surfaces at gate | G3: remaining gaps classified by type |
| Check UI for visual bugs | Visual QA screenshots + vision (D10) | Fix → re-screenshot → re-check ×3 | G3: screenshot evidence |
| Track costs, compare to budget | COST.json per agent call (D12) | Circuit-breaker at 80% budget cap | G3: actual vs projected spend |

**The trust contract.** At each gate, the operator receives evidence, not claims. Constitution Article VIII (Honest Reporting) enforces this: agents describe what actually happened, not what was intended.

---

## D16 — Methodology Provenance

**Where each borrowed mechanism lives in the pipeline, and what it prevents.**

### D16a: Incorporated mechanisms

| Source | Principle | Where in Forge | Failure mode prevented |
|---|---|---|---|
| **Karpathy** (autoresearch) | Immutable eval harness ("prepare.py is read-only") | D7b (TDD) → .forge/EVAL/ · D8 reads it | **Metric gaming.** Agents cannot weaken tests to make code pass. |
| **Karpathy** | Keep-or-revert ratchet ("improvements advance; regressions reset") | D8 (build loop) git reset --hard on regression | **Regression accumulation.** Branch only moves forward on verified improvement. |
| **Karpathy** | Never stop, never ask ("when stuck, think harder") | D5 (decision router) Tactical + technical: decide, don't ask | **Analysis paralysis.** Only strategic/irreversible decisions pause the build. |
| **Karpathy** | Surgical changes + explicit assumptions | D8 (implementor prompt) Each task → one spec section | **Silent assumptions becoming bugs.** Every change traces to a spec section. |
| **Compound AI** (Zaharia et al.) | Inter-stage assertions (DSPy Assert/Suggest) | D1 between P4, P5, P6 | **Silent contract violations.** Bad output caught at boundary before it propagates. |
| **Compound AI** | Multi-model routing | D14 (forge.yaml) models.overrides per role | **Uniform cost for non-uniform tasks.** Panels use Sonnet; implementors use Opus. |
| **Compound AI** | Program logic between model calls | D4 (watchdog), D12 (cost), D5 (routing) | **Over-reliance on LLM judgment.** Drift checks use programmatic rules. |
| **Beck** (TDD, 2002) | Red-green-refactor | D7b → D8 Tests from workflow, fail red, code makes green | **Tests drift to match implementation.** Tests derived from spec, not by implementing agent. |
| **Forge-native** | Gap loop as convergence | D9 P7–P8 feedback to P4 | **One-shot builds with no feedback.** Quality converges over iterations. |
| **Forge-native** | Constitution as pre-merge gate | D4 (drift check), D11 (CI/CD) | **Agents rationalizing away safety rules.** Hard guardrails on every PR. |
| **Forge-native** | Vision-as-lens, not artifact | D1 P0 → P2 (panels review through pillars) | **Generic advice.** Pillars force every finding to cite project criteria. |

### D16b: Acknowledged gaps (not yet implemented)

| Source | Principle | Why not in v1 | Implementation path |
|---|---|---|---|
| Karpathy | Simplicity criterion ("equal perf + less code wins") | Requires judgment call — hard to make deterministic | Add to reviewer prompt |
| Compound AI | Pipeline-level optimization | Requires persistence across builds | Track outcomes in ~/.forge/history.json over N builds |
| Compound AI | Few-shot example banks (DSPy BootstrapFewShot) | Cold-start on first build | After each build, retro extracts best outputs per role |
| Karpathy | Structured experiment log (TSV) | MEMORY.md partially covers but isn't machine-parseable | Add .forge/EXPERIMENTS.tsv (untracked) |

---

## Cross-Reference Index

| Diagram | Subject | D1 Phase | References | Referenced By |
|---|---|---|---|---|
| D0 | Full system architecture | All | — | — |
| D1 | Master pipeline | All | — | All others |
| D2 | Agent topology + primitive decision tree | All | D1 | D3, D4, D5, D7, D8, D10 |
| D3 | Human gates | G1, G2, G3 | D1, D5 | D6, D9, D12 |
| D4 | Drift detection | P6 | D1, D2 | D8, D10, D11 |
| D5 | Decision router | All agents | D2, D3 | D8 |
| D6 | Research protocol | P2–P3 | D1, D3 | — |
| D7 | Fan-out sizing | P5 | D1, D2 | D8 |
| D7b | TDD: test generation from spec | P4–P5 | D1 | D8, D9 |
| D8 | Build + bug-fix loop | P6 | D1, D4, D5, D7, D7b, D9 | — |
| D9 | Gap loop | P7–P8 | D1, D3 | D8 |
| D10 | Visual QA | P7 | D1, D4 | D11 |
| D11 | CI/CD pipeline | P5+ | D1, D4, D10 | — |
| D12 | Economics | P3–G3 | D1, D3 | D13 |
| D13 | Observability | All | D1, D2, D4, D5, D7b, D8, D9, D12 | — |
| D14 | Configuration cascade | All | D1, D2 | D13 |
| D15 | Trust model | All | D1–D14 | — |
| D16 | Methodology provenance | All | All | — |

---

*Validated across 589 commits, 5 projects. Sources: Karpathy autoresearch (2025), Beck TDD (2002), Zaharia et al. Compound AI Systems (2024), Karpathy Guidelines, Forge-native (gap loop, constitution, vision-as-lens, bounded fan-out).*
