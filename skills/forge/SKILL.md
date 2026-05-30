# FORGE — Autonomous Build Skill

## The Core Principle: Separate the Builder from the Auditor

The single most important design decision in FORGE is that **the agent implementing the code must never be the same agent auditing the code.** When one agent does both, the implementor always wins — it produces visible progress (working app, screenshots, deploy), while the auditor produces invisible safety (tests, assertions, coverage checks). Under time pressure or context pressure, invisible work gets skipped. Every time.

This isn't a discipline problem. It's an incentive misalignment:
1. The protocol says "do X before proceeding"
2. X doesn't produce visible output (tests, reviews, assertions)
3. The next step DOES produce visible output (working code, deploy)
4. The implementor skips X and does the exciting thing instead

The fix is structural, not behavioral:
- **Hooks (R1)** make it mechanically impossible to advance without artifacts
- **A separate watchdog (R2)** whose only job is auditing — no implementation incentive
- **Blocking dependencies (R4)** make safety steps tasks in the dependency graph, not prose reminders
- **Tiered reviewers (CE)** run as separate subagents that can't be pressured by the implementor's context
- **A continuation hook (R7)** makes it mechanically impossible to *stop early* — the inverse of R1
- **A conformance hook (R8)** traces every *completed* module back to spec → PRD → architecture, filing a gap on any break
- **A stub scanner (R9)** detects placeholder code as it's written and the ship gate blocks release on unresolved stubs in required modules

**Every enforcement mechanism in FORGE exists because prose instructions fail under pressure.** When reading this skill, if you see a step described in words but not enforced by a hook, a dependency, or a separate agent — that step will eventually be skipped. Flag it.

---

You are the Forge orchestrator. FORGE is not a fixed system — it is a **dynamic workflow template** that generates a project-specific build system every time it runs. The pipeline structure (12 phases, 4 gates) is the deterministic scaffold. Everything inside is composed dynamically from the input and from a library of thinking frameworks (panels, reviewers, debug protocols, optimization strategies).

Your job at each phase: select the right framework for this project, configure it with project-specific parameters, execute it, and feed the output to the next phase. No two FORGE builds produce the same architecture.

> Reference: `~/projects/workflow/docs/forge-architecture.html` (diagrams D0–D19)
> Lineage: 12-phase methodology (vision→panels→spec→swarm→gap loop→pulse) + Karpathy autoresearch (eval-first, keep-or-revert) + Compound AI Systems (inter-stage assertions, model routing) + Compound Engineering (tiered review, learning capture, doc review agents, optimization loops) + TDD (immutable test harness)
> Documentation style: McKinsey aesthetic (action titles, exhibit labels, executive summaries) + plain-English-first pattern. All generated HTML uses CSS from `~/projects/workflow/docs/forge-architecture.html`. All generated markdown follows: plain English paragraph → "**Technically:**" line → detail.

## Deterministic vs. Dynamic Components

The orchestrator must understand which parts of the system are fixed and which are composed per project:

| Layer | Deterministic (never changes) | Dynamic (composed per project from framework library) |
|---|---|---|
| **Pipeline** | 12 phases in fixed order, 4 gates at fixed positions | — |
| **Message contract** | 12 message types, JSON envelope format | — |
| **Safety mechanisms** | Keep-or-revert, immutable eval harness, cost breaker, shutdown handshake | — |
| **Terminal architecture** | Five-lead build team during P6: one long-lived terminal per lead (planner, coder, tester, reviewer, watchdog), connected via claude-peers; the writer is never the auditor (coder ≠ tester/reviewer/watchdog) | Track: full = all 5 leads, fast = planner+coder+reviewer+watchdog (tester folds into coder), tiny = whole loop as subagents under the planner. Coder may run 1–4 coder terminals only for long, interdependent tasks; otherwise fans out coding subagents. Addressing derives from `FORGE_ROLE` per terminal |
| **Pillars** | 3–5 pillars derived at P0 | Content: from project risks + goals. Framework: pillar derivation protocol. |
| **Constitution** | Articles I–V inviolable | Articles VI–X: tailored to project's specific safety domain |
| **Panels** | 1–3 panels, synthesis protocol | Which panels: selected from skill library by domain. Which panelists: named per project. |
| **Reviewer tiers** | 5 reviewer types, confidence gating, dedup | Reviewer weights: shift by domain (security heaviest for healthcare, performance for real-time, correctness for financial) |
| **Debug protocol** | reproduce→trace→hypothesis→test-first-fix | How to trace: depends on stack (browser devtools vs. server logs vs. on-chain explorer) |
| **Optimization strategy** | 3 parallel experiments, measure, keep best | What to measure: from the project's performance pillars (LCP for web, TPS for blockchain, latency for API) |
| **Document review agents** | Feasibility + Scope Guardian + Coherence + Adversarial | Review criteria: derived from the project's pillars and constraints |
| **Eval harness** | Generated from workflow, immutable | Test cases: from the project's specific workflow state machine |
| **Learnings** | Structured format, compound loop | Content: from this build and prior builds of the same project |
| **Product Pulse** | Report format, pulse→vision loop | Data sources: from the project's deployment (analytics, error tracking, logs) |

**When composing dynamic components, always pull from existing frameworks defined in this document.** Do not invent new protocols at runtime. If a project needs a capability that doesn't map to an existing framework, log it as a gap in MEMORY.md and use the closest available framework with documented adaptations.

## Invocation

```
/forge <idea or PRD path> [--track fast|full] [--resume] [--gap-loop]
/forge status                — dashboard: phase, agents, tasks, costs, alerts
```

- **idea**: Free text describing the product, or a file path to a PRD
- **--track fast**: 1 panel, 1 implementor, golden-path tests, inline gap fixes (default)
- **--track full**: 3 panels, up to 4 implementors, full test generation, spec re-derivation
- **--resume**: Read .forge/STATE.json, continue from last checkpoint
- **--gap-loop**: Re-enter from .forge/GAPS.json, re-derive affected spec sections
- **status**: Read all `.forge/` state files + claude-peers and produce a structured dashboard (see Observability)

## First Actions on Invocation

1. Read forge.yaml config: `~/.forge/forge.yaml` (global) → `.forge/forge.yaml` (project override) → CLI flags
2. If `--resume`: read `.forge/STATE.json`, skip to the incomplete phase
3. If new build: create `.forge/` directory with STATE.json, MEMORY.md, COST.json, `observe/`
4. Log to MEMORY.md: `[timestamp] FORGE STARTED — track: {track}, input: {idea|prd_path}`
5. Start the observe server: `python3 ~/projects/workflow/tools/observe-server.py &` (runs at localhost:4040)
6. Emit first observe event: `SPAWN` for orchestrator

## Observability Protocol (D19)

Every agent writes structured events to `.forge/observe/{agent-name}.jsonl`. A live HTML dashboard at `localhost:4040` merges and displays all events in real time.

**To start the dashboard:** `python3 ~/projects/workflow/tools/observe-server.py` (from project root)

### Event Schema

Every line in a `.jsonl` file is one event:

```json
{"t":"2026-05-27T14:08:12.123Z","seq":42,"agent":"impl-1","role":"implementor","event":"WRITE","detail":"src/App.tsx (47 lines)","target":null,"ctx_est":62000,"ctx_total":184000,"task":"T-03","phase":"P6"}
```

| Field | Type | Description |
|---|---|---|
| `t` | ISO-8601 | Timestamp (UTC) |
| `seq` | int | Global sequence number (monotonic across all agents) |
| `agent` | string | Agent identifier (orchestrator, supervisor, impl-1, watchdog, etc.) |
| `role` | string | Agent role (orchestrator, implementor, reviewer, tester, etc.) |
| `event` | string | Event type (see below) |
| `detail` | string | Human-readable description |
| `target` | string? | Target agent for SEND events |
| `from` | string? | Source agent for RECV events |
| `ctx_est` | int | Estimated context tokens for this agent |
| `ctx_total` | int | Estimated total context across all active agents |
| `task` | string? | Current task ID (e.g., T-03) |
| `phase` | string | Current pipeline phase (e.g., P6) |

### Event Types

| Event | When to emit | Detail content |
|---|---|---|
| `SPAWN` | Agent starts | Agent name, role, assigned task |
| `PHASE` | Pipeline phase transition | Phase name, what it will do |
| `GATE` | Human gate reached | Gate ID, what operator is asked |
| `READ` | File read | File path, line count |
| `WRITE` | File written/edited | File path, lines changed |
| `TOOL` | Tool call (Bash, MCP, etc.) | Tool name, command summary |
| `SEND` | Message sent to another agent | Target agent, message summary |
| `RECV` | Message received from another agent | Source agent, message summary |
| `LOOP_START` | Loop begun | Loop purpose, max iterations |
| `LOOP_ITER` | Loop iteration | Iteration number, what changed |
| `LOOP_END` | Loop completed | Total iterations, outcome |
| `DECIDE` | Decision made (D5 router) | Decision level, choice, rationale |
| `ESCALATE` | Decision escalated | To whom, why |
| `ERROR` | Error occurred | Error description |
| `CONTEXT` | Context checkpoint | Current estimate, % of window |
| `COMPLETE` | Agent finished | Summary of what was done |

### How to Emit Events

Use this Bash one-liner inside the FORGE skill and in agent instructions:

```bash
echo '{"t":"'$(date -u +%Y-%m-%dT%H:%M:%S.000Z)'","seq":'$SEQ',"agent":"'$AGENT'","role":"'$ROLE'","event":"'$EVENT'","detail":"'$DETAIL'","ctx_est":'$CTX',"phase":"'$PHASE'"}' >> .forge/observe/$AGENT.jsonl
```

Or append via Python/Node if available. The sequence counter should be read from and incremented in `.forge/observe/seq.txt` (atomic increment).

### Context Estimation

There is no real-time context counter. Estimate using:
- **Message count × 1500** (avg tokens per message for Opus)
- Cross-reference with `~/.claude/stats-cache.json` → `modelUsage` for actuals after the fact
- Emit a `CONTEXT` event every 10 messages or every 5 minutes, whichever comes first
- The `contextWindow` field in stats-cache.json is reserved but currently unused (zeros)

### When to Emit (Rules for All Agents)

1. **On spawn:** `SPAWN` event with role and assigned task
2. **On every file read:** `READ` with path
3. **On every file write/edit:** `WRITE` with path and change summary
4. **On every Bash/tool call:** `TOOL` with command summary (truncated to 100 chars)
5. **On claude-peers send_message:** `SEND` with target agent and message summary
6. **On claude-peers message received:** `RECV` with source agent
7. **On loop start/iteration/end:** `LOOP_START`, `LOOP_ITER`, `LOOP_END`
8. **On decision (D5 router):** `DECIDE` for technical+, `ESCALATE` for architectural+
9. **On error:** `ERROR` with description
10. **On completion:** `COMPLETE` with summary
11. **Every 10 messages:** `CONTEXT` checkpoint with estimate

## The Pipeline (D1)

Execute these phases in order. Write a checkpoint to `.forge/STATE.json` after each phase completes. **Phase gate hook (R1):** STATE.json writes are blocked by `forge-phase-gate.sh` unless required artifacts exist. This is the enforcement mechanism — prose won't prevent phase-skipping, a hook will.

**Continuation hook (R7):** R1 stops an agent from skipping *ahead* without artifacts; R7 stops an agent from quitting *early* while work remains. `tools/stop-hook.sh` is registered synchronously on `Stop` and `SubagentStop` in `~/.claude/settings.json` (alongside the async clorch/notification hooks, which cannot block). On every turn-end it (1) appends a `STOP` event to `.forge/observe/<role>.jsonl` so a halt is never silent, then (2) if the current phase's completion artifact is missing, returns `{"decision":"block","reason":...}` with the concrete next step, forcing the agent to continue. It no-ops instantly outside an active build (`.forge/STATE.json` absent), respects `stop_hook_active` (never blocks twice), logs-only on `SubagentStop` (a fan-out worker can't be mapped to an orchestrator artifact), and after 5 consecutive same-phase nudges escalates to the operator instead of looping. Set `FORGE_ROLE` per terminal (orchestrator/supervisor/watchdog/impl-N) so observe events are attributed. This is the deterministic backstop *under* the heartbeat/claude-peers coordination — those still drive normal operation; R7 catches the silent halt when they don't fire.

**Conformance hook (R8):** Inter-stage assertions (P4/P5) verify traceability *before* the build; R8 verifies it *as each module completes*. `tools/module-conformance-hook.sh` is registered async on `Write|Edit` (PostToolUse). When a task in `.forge/TASKS.json` flips to a done state, it checks that the task's `spec_ref` / `prd_ref` / `arch_ref` each resolve to a real anchor in `04-spec/spec.md` / `01-intake/PRD-ENHANCED.md` / `04-spec/architecture.md`. Every completed module gets a row in `.forge/CONFORMANCE.md`; an orphan (missing or dangling ref) is filed to `.forge/GAPS.json` as a `conformance` gap (it does **not** block — it flows into the P8 gap loop / GitHub ticketing). The `task-00` eval-harness (`spec_ref: ALL`) is exempt. The hook is idempotent (a `.conformance_seen` ledger checks each task once) and structural only — *semantic* conformance (does the code actually satisfy the requirement) remains the watchdog's job. Fails safe: no-ops if it can't read its input.

**Stub scanner (R9):** The *primary* defense against placeholder code is behavior-asserting tests + keep-or-revert — a stub only survives a weak harness. R9 is the secondary net for what tests miss. `tools/stub-detect-hook.sh` is registered async on `Write|Edit`: when a source file is written inside a build, `tools/stub-scan.sh` scans it for high-signal markers (`TODO`/`FIXME`/`XXX`/`HACK`, `NotImplementedError`, `throw new Error("not implemented")`, `@stub`, `@placeholder`, …). New stubs are logged to `.forge/STUBS.md` and filed to `.forge/GAPS.json` as `type:"stub"` gaps — **non-blocking at write time** (too noisy; false positives would stall the build). Enforcement is at the **ship gate**: P6 exit assertions / G3 run `stub-scan.sh --tree` and **block release if any open `stub` gap maps to a MUST module**. A line tagged `// forge:allow-stub <reason>` is exempt (intentional, logged). Honest scope: a regex net has false positives/negatives and covers source files only — it is a net plus a ledger, not a correctness proof. Stub gaps are resolved through the P8 gap loop / GitHub ticketing; the gate stays red until MUST stubs reach zero.

**Context-long checkpoint protocol (R5):** When the conversation exceeds ~200k tokens (roughly where urgency bias starts), the skill MUST:
1. Write all current state to `.forge/` (STATE.json, MEMORY.md, TASKS.json, COST.json)
2. Run a phase-completion checklist for the current phase — enumerate every required output and check if it exists
3. Log any skipped steps to MEMORY.md: `[timestamp] CONTEXT CHECKPOINT — skipped: [list]`
4. Only then continue (or instruct operator to `/forge --resume`)
This counters urgency bias by forcing a deliberate pause at the moment when shortcuts are most tempting. The checkpoint is not optional — it fires automatically based on estimated context size.

---

### Phase 0 — Vision Extraction [AUTO]

**Input:** Product idea or PRD text
**Output:** `00-vision/VISION.md`, `00-vision/PILLARS.md`

1. Extract from the input:
   - **North star**: one sentence describing the end state
   - **Success signals**: 3–5 observable indicators that the build succeeded
   - **Project objective**: what a user can do when this ships
2. Derive 3–5 **evaluation pillars** specific to this project (not generic). Examples: Correctness, Liveness, Operability, Defensibility. These pillars will be referenced by every panel, spec section, and gap classification.
3. Write `00-vision/VISION.md` and `00-vision/PILLARS.md`
4. **Strategy as living doc (CE #13):** VISION.md and PILLARS.md are not write-once artifacts. They are re-runnable — `/forge` can be invoked with `--resume` to update them when direction changes. All downstream phases (panels, spec, gap loop) read these files as grounding on every invocation. If a previous build exists for this project, read its VISION.md and PILLARS.md first and present the diff to the operator: "Last build's vision was X. Is this still correct, or has direction changed?"
5. **Compound refresh (CE #9):** If a previous build's `.forge/LEARNINGS.md` exists, run a refresh pass before reading it: check each learning against the current codebase — are the files/functions it references still there? Is the pattern still applicable? Mark stale entries with `status: stale` and a reason. Only inject non-stale learnings into agent prompts.
6. **Interactive brainstorm (CE #14):** If the input is vague (a rough idea rather than a PRD), engage the operator in a collaborative Q&A before proceeding: "What problem does this solve? Who is the user? What does success look like? What's out of scope?" Surface ambiguities through dialogue, not assumptions. Write the output as `01-intake/BRAINSTORM.md` and use it as input for P1b (PRD Decomposition).

**Do not use generic pillars.** Derive them from the specific risks and goals of this project.

---

### Phase 1 — Structure [AUTO]

**Output:** Folder structure, locked PRD, CONSTITUTION.md, .forge/ initialized

1. Create the numbered folder structure:
   ```
   00-vision/  01-intake/  02-grounding/  03-panels/  04-spec/  05-gaps/
   04-spec/agents/  audits/  decisions/  panels/  tests/  docs/  .forge/
   ```
2. Copy or write the PRD to `01-intake/PRD.md` — this file is **immutable** from this point
3. Create `01-intake/DIFF.md` (empty — will track divergences from PRD)
4. Generate `CONSTITUTION.md` at project root with Articles I–X tailored to this project's risks:
   - Articles I–V: **inviolable** (truthfulness, user safety, data handling, reversibility, scope discipline)
   - Articles VI–X: **overridable with logging** (spec authority, no test theater, honest reporting, pushback discipline, root-cause discipline)
5. Initialize `.forge/STATE.json`: `{ "phase": 1, "status": "complete", "track": "fast|full" }`

---

### Phase 1b — PRD Decomposition [AUTO]

Every stakeholder PRD is written differently — some are bullet lists, some are prose, some mix requirements with aspirations. This step converts whatever you received into a structured, reviewable checklist so nothing falls through the cracks and the operator can verify completeness before panels start working.

**Technically:** Decomposes the raw PRD into a categorized requirements checklist with priority, acceptance criteria, and dependency mapping. Produces `01-intake/PRD-ENHANCED.md`.

**Input:** `01-intake/PRD.md` (immutable raw PRD) + `00-vision/VISION.md` + `00-vision/PILLARS.md`
**Output:** `01-intake/PRD-ENHANCED.md`

1. Read the raw PRD and extract every requirement, constraint, and assumption — stated or implied.
2. Categorize each item:

   **Functional Requirements** — what the system must do
   - Tag each: `[MUST]` (blocking), `[SHOULD]` (important), `[COULD]` (nice-to-have)
   - Write one acceptance criterion per requirement (how do we know it's done?)
   - Note dependencies between requirements (e.g., "R3 requires R1 to be complete")

   **Non-Functional Requirements** — how the system must behave
   - Performance, security, accessibility, compatibility, scalability
   - Each with a measurable threshold where possible

   **Constraints** — hard boundaries the build cannot cross
   - Technical (browser-only, no backend, specific framework)
   - Business (timeline, budget, compliance, licensing)
   - User (age, accessibility, device)

   **Assumptions** — things the PRD takes for granted
   - Tag each: `[VERIFIED]` (confirmed), `[UNVERIFIED]` (needs research in P3), `[RISKY]` (could invalidate the build)

   **Out of Scope** — explicitly what this build does NOT include
   - Extract from PRD language like "not required," "future work," "out of scope"
   - Add anything the PRD is silent on that panels might expect

   **Open Questions** — ambiguities or contradictions in the PRD
   - Things the PRD doesn't specify but the build will need to decide
   - Contradictions between different sections
   - Requirements that conflict with constraints

3. Generate a summary table at the top:
   ```
   | Category              | Count | MUST | SHOULD | COULD |
   | Functional            |    12 |    8 |      3 |     1 |
   | Non-Functional        |     5 |    3 |      2 |     0 |
   | Constraints           |     4 |    — |      — |     — |
   | Assumptions           |     3 |    — |      — |     — |
   | Out of Scope          |     6 |    — |      — |     — |
   | Open Questions        |     2 |    — |      — |     — |
   ```

4. Write `01-intake/PRD-ENHANCED.md`. The raw PRD stays immutable — this is a derivative artifact.
5. Log to MEMORY.md: `[timestamp] P1b complete — {N} requirements extracted, {M} open questions, {K} risky assumptions`

---

### ▸ GATE 0 — Enhanced PRD Review [HUMAN]

The operator reviews the enhanced PRD before expert panels use it. This is the cheapest possible correction point — fixing a misunderstood requirement here costs nothing. Fixing it after panels have run costs a full re-run. Fixing it after build has started costs real money.

**Technically:** Human gate between PRD decomposition and expert panels. Validates completeness, priority, and scope before downstream phases consume the requirements.

**Document review agents (pre-screen before operator):** Before presenting to the operator, spawn 3 parallel document review subagents (inspired by CE's document review personas). Each reviews PRD-ENHANCED.md through a single lens:

| Reviewer | Lens | What it catches |
|---|---|---|
| **Feasibility** | Can this actually be built with the stated constraints? | Requirements that sound good but are technically impossible or wildly expensive |
| **Scope Guardian** | Is anything here unjustified complexity or scope creep? | Gold-plating, premature features, requirements that don't serve the pillars |
| **Coherence** | Do the requirements contradict each other? Is terminology consistent? | Section A says "real-time" but Section B says "batch"; MUST items that conflict |

Each returns structured findings: `{ finding, severity, section_ref, recommendation }`. Merge into a pre-screen report that the operator sees alongside the enhanced PRD.

**Present to operator using AskUserQuestion:**
- Document review pre-screen report (feasibility, scope, coherence findings)
- Summary table (counts by category and priority)
- Any `[RISKY]` assumptions that could invalidate the build
- Open questions that need stakeholder input
- The full `PRD-ENHANCED.md` for line-by-line review

**Collect from operator:**
- Corrections to requirement priority (MUST/SHOULD/COULD)
- Answers to open questions
- Additional requirements the PRD missed
- Confirmation that out-of-scope list is correct
- Resolution of any `[RISKY]` assumptions
- Response to document review findings (accept/reject each)

**On redirect:** Re-run P1b with operator notes merged into the enhanced PRD.

After approval, update `01-intake/PRD-ENHANCED.md` with operator corrections. This becomes the input for P2 (Expert Panels) and P4 (Spec Derivation).

---

### Phase 2 — Expert Panels [AUTO]

**Output:** `03-panels/synthesis.md`

**Fast track (1 panel):** Run the most relevant panel as a skill (stays in your context — no context duplication). Choose: technical-expert-panel, business-expert-panel, or domain-specific panel based on the project type.

**Full track (3 panels):** Spawn 3 parallel subagents, one per panel type (technical, business, domain SME). Each receives: VISION.md, PILLARS.md, PRD-ENHANCED.md. Each reviews through the pillars, not generically.

After panels complete, **synthesize** into `03-panels/synthesis.md`:
- **Convergent findings**: where all panels agree
- **Divergent findings**: where panels disagree (flag for Gate 1)
- **Critical risks**: ranked by severity
- **Open questions**: things no panel could answer (route to Phase 3)

---

### Phase 3 — Grounding Research [AUTO]

**Output:** `02-grounding/*.md` (one file per question)

For each [OPEN] question from the panel synthesis:
1. Spawn a research subagent with WebSearch access
2. Timebox: 15 minutes per question
3. Required output format per question:
   - **Question**: exact question from panel synthesis
   - **Options**: minimum 3, with cost/performance/complexity trade-off matrix
   - **Evidence**: primary sources only (docs, RFCs, papers — not blog posts). Version-pinned, date-checked.
   - **Recommendation**: with explicit falsifiable assumptions
   - **Fallback**: what to do when the recommendation fails at runtime
   - **Verification**: how to confirm (spike test, devnet deploy, API call)
4. Classify each answer: `[VERIFIED]` (source confirmed, API tested), `[UNVERIFIED]` (assumption flagged, fallback required), or `[OPEN]` (timebox expired, surface at Gate 1)

**Data availability check**: If the project depends on external data (training data, API feeds, third-party services), verify actual availability in this phase. Do not assume. (Lesson: ASL project expected 200 training clips, actual was 52.)

---

### ▸ GATE 1 — Direction [HUMAN] (D3)

**Document review agents (pre-screen):** Before presenting to operator, spawn 2 parallel doc review subagents on the panel synthesis + research decisions:
- **Adversarial reviewer**: Challenge premises, surface unstated assumptions, stress-test decisions. "What breaks if this assumption is wrong?"
- **Feasibility reviewer**: Given the research findings, can the proposed spec outline actually be built within constraints?

Each returns findings with severity. Merge into pre-screen report.

**Present to operator using AskUserQuestion:**
- Document review pre-screen (adversarial + feasibility findings)
- Vision + pillars (from P0)
- Panel synthesis: convergent/divergent/risks (from P2)
- Research decisions with trade-off matrices (from P3)
- Any [OPEN] or [UNVERIFIED] items that need operator judgment
- Spec outline (proposed sections)

**Collect from operator:**
- Strategic direction on panel divergences
- Domain constraints the system cannot discover
- Priority ranking of conflicting requirements
- Any context, API keys, or credentials available now
- Response to adversarial/feasibility findings

**On redirect:** Re-run P2–P3 with operator notes as additional constraint.

---

### Phase 4 — Spec Derivation [AUTO]

**Output:** `04-spec/spec.md`, `04-spec/workflow.md`, `04-spec/architecture.md`, `04-spec/CONTRACTS.md`

1. **spec.md**: Derive from PRD + panel synthesis + research. Every requirement tagged:
   - `[FROM PRD §X]` — directly from the stakeholder PRD
   - `[DERIVED]` — inferred from panels/research, not in PRD
   - `[OPEN — needs decision]` — ambiguous, flagged
   - Each section references its pillar (P1/P2/P3/etc.)

2. **workflow.md**: State machine for the user experience. Every node declares:
   - `in:` what data/state enters this node
   - `proc:` what processing happens
   - `out:` what data/state exits
   - Golden path + named edge cases + failure paths + recovery

3. **architecture.md**: File structure, layer boundaries, interface contracts, schema/PDA design

4. **CONTRACTS.md**: Interface boundaries between layers. Function signatures, type exports, API endpoints. This is what the drift checker (D4) validates against.

**Inter-stage assertion (Compound AI):** After this phase, programmatically verify: every PRD requirement maps to a spec section OR has an explicit `[OUT OF SCOPE]` tag. If any requirement is unmapped, retry with the violation appended.

---

### Phase 5 — Task Decomposition + Eval Harness [AUTO]

**Output:** `.forge/TASKS.json`, `04-spec/agents/*.md`, `.forge/EVAL/`

1. **Analyze spec complexity** and determine implementor count (D7):
   - ≤5 tasks with linear deps → 1 implementor
   - 6–12 tasks with 2–3 parallel → 2 implementors
   - 13+ tasks with 3+ parallel → 3–4 implementors
   - Cap: ≤4 concurrent (reviewer capacity constraint)

2. **task-00: eval-harness (BLOCKING — R4).** The eval harness is not a step the orchestrator performs. It is the **first task** in TASKS.json, and every other task depends on it. The build literally cannot start until tests are generated. This turns a skippable step into a blocking dependency.
   ```json
   { "id": "task-00", "name": "eval-harness", "spec_ref": "ALL",
     "depends_on": [], "estimated_lines": 0, "agent_slot": 0,
     "description": "Generate immutable eval harness from workflow state machine" }
   ```
   - From workflow.md: each node → test case (arrange from `in`, act from `proc`, assert from `out`)
   - Each branch → negative test
   - Each failure path → recovery test
   - Output: `.forge/EVAL/` directory with test files
   - **Lock this directory. Agents cannot modify it.** Tests are the contract.
   - task-00 must be status "done" before any other task can begin.

3. **Decompose remaining work into tasks** with dependency graph (all depend on task-00):
   ```json
   { "id": "task-01", "name": "init-config", "spec_ref": "S3.1",
     "prd_ref": "R-12", "arch_ref": "C2",
     "depends_on": ["task-00"], "estimated_lines": 150, "agent_slot": 1 }
   ```
   Every non-eval task MUST carry `spec_ref` (a section id in `04-spec/spec.md`) and `prd_ref` (a requirement id in `01-intake/PRD-ENHANCED.md`); `arch_ref` (a component id in `04-spec/architecture.md`) is optional. These are what the module-conformance hook (R8) traces when the task completes — a task with a missing or dangling ref is filed as a conformance gap.

4. **Deliverable coverage assertion (R3).** After task decomposition, verify that every deliverable listed in the PRD's "Deliverables" section maps to at least one task:
   - Parse the deliverables from `01-intake/PRD-ENHANCED.md` (MUST items)
   - For each deliverable: assert at least one task in TASKS.json references it
   - If a deliverable has no corresponding task: **create one before proceeding**
   - This is a hard check, not advisory. Missing deliverable coverage = phase fails.

5. **Generate agent role files** in `04-spec/agents/`: implementor.md, reviewer.md, watchdog.md. Each includes R/W contract (which files the agent may modify) and the Decision Router rules (D5).

6. **Generate CI/CD config** (D11): `.github/workflows/forge-ci.yml` or `.gitlab-ci.yml` based on forge.yaml `ci_platform` setting. Stages: lint → test → build → drift-check → constitution → visual-qa → deploy.

**Inter-stage assertion (blocking — P5 cannot complete until all pass):**
- Every task references a spec section. Dependency graph has no cycles.
- Every spec section is covered by at least one task.
- **Every PRD deliverable maps to at least one task** (R3 — the assertion that catches missing deliverables).
- **task-00 (eval-harness) exists and is the root of the dependency graph** (R4).
- **Eval completeness:** Every node in workflow.md has a corresponding test file and at least one test function. Every spec section (S1, S2, ...) has at least one test that exercises it. Missing coverage = phase fails, orchestrator generates the missing test stub before proceeding.
- **Phase gate hook enforced:** STATE.json cannot advance to phase 6 unless `.forge/EVAL/` has test files (R1).

---

### Phase 5b — Spec Deepening Pass [AUTO] (CE #12)

Before the operator sees the spec at G2, run a **deepening pass** — sub-agents review the spec for gaps, weak assumptions, and missing edge cases. This catches spec problems before the point of no return, where they're cheap to fix. After the point of no return, spec problems become build problems.

1. Spawn 3 parallel deepening subagents:
   - **Spec flow analyzer** (CE #15): Analyze the workflow state machine for unreachable states, missing error paths, and edges that don't connect. Report: "State S3 has no error path — what happens when the API call fails?"
   - **Confidence checker**: For each spec section, rate confidence HIGH/MEDIUM/LOW. LOW = based on an unverified assumption or missing research. MEDIUM = reasonable but untested. HIGH = verified or deterministic.
   - **Deliverable verifier**: Cross-check spec → tasks → deliverables → PRD. Every PRD deliverable must trace through to a task. Flag orphaned deliverables.

2. Merge findings into `.forge/DEEPENING.md`: section, confidence, gaps found, missing flows.

3. Any LOW-confidence finding or missing flow becomes a **blocking question** for G2 — the operator must resolve it before approving the build.

**Inter-stage assertion:** P5b cannot complete until every spec section has a confidence rating and every deliverable traces to a task.

---

### ▸ GATE 2 — Architecture [HUMAN] (D3)

**This is the point of no return. Implementation starts after this.**

**Document review agents (pre-screen):** Before presenting to operator, spawn 3+3 parallel doc review subagents — the standard 3 (scope, coherence, adversarial) plus the deepening findings from P5b:
- **Scope Guardian**: Is the spec overbuilt for the stated timeline? Are there tasks that don't serve any pillar?
- **Coherence reviewer**: Do spec sections contradict each other? Does the architecture match the workflow state machine?
- **Adversarial reviewer**: What's the most likely way this build fails? Which assumption is weakest?

Each returns findings with severity. Merge into pre-screen report.

**Present to operator using AskUserQuestion:**
- Document review pre-screen (scope, coherence, adversarial findings)
- Full spec with workflow state machine
- Architecture diagram + interface contracts
- Task decomposition with dependency graph and estimated implementor count
- Eval harness summary (test count, coverage map)
- Cost projection: estimated build tokens + runtime infra (from P3 research)

**Collect from operator:**
- Response to doc review findings
- API keys, service credentials, external accounts
- Deploy target confirmation (Vercel, Railway, devnet, etc.)
- Final architecture sign-off
- `.env` values → write to `.env` (gitignored)

---

### Phase 6 — Parallel Build [AUTO] — The Five-Lead FORGE Build Team

Phase 6 runs as the **FORGE build team**: five named **lead agents**, each in its OWN long-lived terminal, connected as a team over the claude-peers bus. The five leads are **planner**, **coder**, **tester**, **reviewer**, and **watchdog**. Each is a persistent terminal that *fans out subagents* — it is the coordination spine for its concern, not a solo worker. The five leads map onto the prior naming as follows: **planner = orchestrator** (team lead), **coder + tester = supervisor/implementors** (build + test leads), **reviewer = the tiered CE reviewer**, **watchdog = R2 auditor** (unchanged).

The five lead roles:

- **planner** = team lead: owns the plan, task decomposition, the 4 human gates, and the operator relationship. Creates the team at P6a, monitors it during the build, and tears it down at P6 end.
- **coder** = build lead: implements tasks; **fans out coding subagents** for independent tasks (or runs 1–4 coder terminals only when tasks are long AND interdependent); keep-or-revert ratchet; never self-approves.
- **tester** = test lead: owns the immutable eval harness (task-00); runs and extends behavior tests, **fanning out per-surface test subagents**.
- **reviewer** = review lead: tiered code review of every diff via **per-dimension subagents** (correctness / security / performance); returns APPROVE / REJECT.
- **watchdog** = R2 auditor: independently audits completed work against spec/architecture for drift; writes `.forge/AUDIT.json`; **NEVER implements**.

**CORE PRINCIPLE — the writer is never the auditor.** The **coder** is a different agent from the **tester**, the **reviewer**, and the **watchdog**. The reviewer checks the *diff*; the watchdog independently checks *drift against spec*. These are not merged — they catch different failures.

**Subagents are the parallel muscle; terminals are the coordination spine.** The leads dispatch **ephemeral subagents** (via the Workflow/Agent tools) for the bounded, parallel, independent work: coding tasks, per-surface tests, per-dimension reviews, plus expert panels, grounding research, doc-review, and deepening passes.

**Subagent vs. agent-team — the decision rule.** Own terminal IF the role is singular, long-lived, and coordinates continuously (the 5 leads). Subagent IF the work is bounded, parallel, and independent (everything the leads dispatch).

| Concern | Own terminal (lead) | Subagent (muscle) |
|---|---|---|
| Plan / decomposition / gates / operator | **planner** | — |
| Implementation | **coder** (build lead) | coding subagents (per independent task) |
| Behavior tests / eval harness | **tester** | per-surface test subagents |
| Code review of diffs | **reviewer** | per-dimension review subagents (correctness/security/perf) |
| Drift audit vs. spec | **watchdog** | — |
| Expert panels / research / doc-review / deepening | — | dispatched by whichever lead needs them |

**Scale to track.** Don't pay for 5 live sessions on a 2-file change:
- **Full track** = all 5 lead terminals (planner + coder + tester + reviewer + watchdog).
- **Fast track** = planner + coder + reviewer + watchdog (tester folds into the coder's keep-or-revert ratchet).
- **Tiny change** = run the whole loop as subagents under the planner/orchestrator — no live lead terminals.

**Topology.** planner ⟷ coder ⟷ tester ⟷ reviewer form the build loop over claude-peers (plan → build → test → review → re-plan). **watchdog observes all** and reports drift to the planner. The **planner owns the human gates**.

**R2: Watchdog spawn is automatic, not discretionary.** The watchdog MUST be spawned at P6a as its own terminal. It is not something the planner "may" do — it is a required step. The phase gate hook (R1) cannot be fooled because the watchdog writes to `.forge/AUDIT.json`, and P6 exit assertions check that AUDIT.json exists with watchdog entries. If the watchdog was never spawned, P6 cannot exit.

In plain terms: the planner is the project manager who owns the plan and the operator's gates. The coder is the build lead with a bench of builder-subagents; the tester is the QA lead with a bench of test-subagents; the reviewer inspects every delivery with a panel of specialist reviewer-subagents; the watchdog independently checks every delivery against the original plan for drift. Everyone sits in the same room (the claude-peers team bus) and answers a shoulder-tap immediately.

**Launch.** `tools/forge-team.sh` (tmux) brings up one terminal per lead; `tools/forge-team.sh --cursor` writes `.vscode/tasks.json` so **Run Task → "FORGE: launch team"** opens each role in its own Cursor terminal. Each role reads its contract at `04-spec/agents/<role>.md` (seeded from `templates/agent-roles/<role>.md`).

**Technically:** one tmux session `forge-build` with one window per lead (planner, coder, tester, reviewer, watchdog), created at P6a and torn down at P6 end. Each lead exports `FORGE_ROLE` so the global hooks attribute themselves per role. All terminals form one agent team on the claude-peers MCP bus — on start each calls `set_summary(role + current task)` and `list_peers` to discover teammates, then coordinates via structured `send_message`/`check_messages` (shoulder-tap protocol). The leads dispatch subagents for review/test/coding fan-out. All state in `.forge/` files.

**Output:** Working code, merged PRs, passing tests

---

#### P6a — Team Setup (the five-lead team) [planner]

The planner stands up the build team via `tools/forge-team.sh`: one tmux session, one long-lived window per lead — planner, coder, tester, reviewer, watchdog (full track) or the fast-track subset. Each window exports `FORGE_ROLE` so the global hooks, observe events, and claude-peers addressing are attributed per role. When the coder runs as 1–4 coder terminals (long, interdependent tasks only), each coder terminal is bound to its own git worktree; otherwise the coder fans out coding subagents that carry their own isolation. `tools/forge-team.sh --cursor` instead writes `.vscode/tasks.json` so the operator can **Run Task → "FORGE: launch team"** to open each role in its own Cursor terminal. Each role reads its contract from `04-spec/agents/<role>.md` (seeded from `templates/agent-roles/<role>.md`).

1. **Check tmux:** `which tmux || { log "FORGE P6 requires tmux. Install: brew install tmux"; halt; }`

2. **Generate prompt files** — the planner writes one brief per lead for this specific build. Each lead's brief points at its contract `04-spec/agents/<role>.md` (seeded from `templates/agent-roles/<role>.md`) and adds the build-specific paths:

   `.forge/prompts/coder.md` — contains:
   - Role: "You are the FORGE coder (build lead) for this build. Read your contract at 04-spec/agents/coder.md."
   - TASKS.json path and format
   - Spec section references for each task
   - CONTRACTS.md / architecture.md / eval-harness paths
   - Decision Router rules (D5)
   - Observability protocol: emit events to `.forge/observe/coder.jsonl`
   - Claude-peers message format contract (see below)
   - Heartbeat: update `.forge/HEARTBEAT.json` every 5 minutes
   - Reference project protocol (if applicable)
   - Instructions: "Read TASKS.json. For each ready task in dependency order, FAN OUT a coding subagent (worktree-isolated); only run sibling coder terminals when tasks are long AND interdependent. Apply keep-or-revert; never self-approve. On a task's completion send PR_SUBMITTED to the reviewer and watchdog. Send P6_COMPLETE to the planner when all tasks have APPROVE verdicts."

   `.forge/prompts/tester.md` — contains:
   - Role: "You are the FORGE tester (test lead) for this build. Read your contract at 04-spec/agents/tester.md."
   - Eval-harness (task-00) path — the harness is immutable; tester extends behavior tests, never weakens them
   - workflow.md / spec section references (one test per node, one per spec section)
   - Observability protocol: emit events to `.forge/observe/tester.jsonl`
   - Claude-peers message format contract; heartbeat every ≤5 minutes
   - Instructions: "Own the immutable eval harness. On each PR_SUBMITTED, FAN OUT per-surface test subagents to run + extend behavior tests against the diff. Report PASS/FAIL to the coder and planner. Never alter the harness to make a test pass (R4)."

   `.forge/prompts/reviewer.md` — contains:
   - Role: "You are the FORGE reviewer (review lead) for this build. Read your contract at 04-spec/agents/reviewer.md."
   - CONTRACTS.md / spec section paths; review-dimension list (correctness / security / performance / …)
   - Observability protocol: emit events to `.forge/observe/reviewer.jsonl`
   - Claude-peers message format contract; heartbeat every ≤5 minutes
   - Instructions: "On each PR_SUBMITTED, FAN OUT one review subagent per dimension over the diff. Aggregate to a single APPROVE/REJECT verdict and send it to the coder and planner. You review the DIFF only — drift-vs-spec is the watchdog's job, do not duplicate it."

   `.forge/prompts/watchdog.md` — contains:
   - Role: "You are the FORGE watchdog (R2 auditor) for this build. Read your contract at 04-spec/agents/watchdog.md. You NEVER implement."
   - Drift check protocol (D4): 7 categories, 3 trigger points
   - AUDIT.json format
   - Spec.md and CONTRACTS.md paths
   - Observability protocol: emit events to `.forge/observe/watchdog.jsonl`
   - Claude-peers message format contract
   - Instructions: "On PR_SUBMITTED message: drift-check the PR diff against the spec/architecture (this is drift, NOT the reviewer's per-dimension diff review). On PR_MERGED: check integrated repo state. Run /loop 30m for periodic full-repo audit. Write findings to `.forge/AUDIT.json`. On CRITICAL: send DRIFT_CRITICAL to the planner immediately."

   The `planner` runs in the first window and needs no separate prompt file beyond its contract `04-spec/agents/planner.md`. When the coder is run as 1–4 coder terminals (long, interdependent tasks only), the planner writes a `.forge/prompts/coder-N.md` per coder terminal carrying its bound worktree path, branch naming `forge/phase-6/{task-slug}`, `[SPEC §X.Y]` commit convention, and its `.forge/observe/coder-N.jsonl` stream. Otherwise the single coder lead fans out coding subagents that carry their own worktree isolation.

3. **Spawn the team — one window per lead, via `tools/forge-team.sh` (tmux):**

   ```bash
   # forge-team.sh creates the session and one window per lead, exporting FORGE_ROLE in each.
   # planner runs in the first window; coder/tester/reviewer/watchdog each get their own.

   tmux new-session -d -s forge-build -n planner

   for role in coder tester reviewer watchdog; do
     tmux new-window -t forge-build -n "$role"
     tmux send-keys -t "forge-build:$role" \
       "FORGE_ROLE=$role claude --name \"forge-$role\" --dangerously-skip-permissions \
         --append-system-prompt-file .forge/prompts/$role.md \
         'Begin FORGE P6 $role. Read your contract at 04-spec/agents/$role.md, set your summary, list_peers to find the team, then start your loop.'" ENTER
   done

   # Fast track: omit the tester window (tester folds into the coder's keep-or-revert ratchet).
   # Long, interdependent tasks only: replace the single coder window with coder-1..coder-N (N ≤ 4),
   # each cd'd into its own `.forge/worktrees/coder-$i` git worktree.
   ```

   `tools/forge-team.sh --cursor` instead writes `.vscode/tasks.json` with a "FORGE: launch team" task that opens each role in its own Cursor terminal (same `FORGE_ROLE` + contract wiring).

   **Permission model:** `--dangerously-skip-permissions` is used because the operator approved the build at Gate 2 (point of no return). Every lead — planner, coder, tester, reviewer, watchdog — operates within the scope approved at G2.

4. **Verify spawn:** Wait 15 seconds, then call `list_peers(scope: "repo")`. Assert that the launched leads (`forge-coder`, `forge-tester`, `forge-reviewer`, `forge-watchdog` on full track; the fast-track subset otherwise) all appear. If any is missing after 30 seconds, retry the spawn for that window once. If still missing after 60 seconds, halt P6 and alert operator.

5. **Log:** Emit `SPAWN` observe events for each launched lead. Write to MEMORY.md: `[timestamp] P6a complete — build team spawned (planner + {leads on this track})`

---

#### Per-terminal hooks (status / monitoring / continuous build)

Because each lead lives in its own terminal, the planner wires the same three hook families into every window, keyed by `FORGE_ROLE`. The hooks make the lead team observable and self-healing without changing what R1/R7/R8/R9 already do — they attribute the existing machinery per role.

In plain terms: each terminal wears a name tag, raises its hand when it's working, and isn't allowed to walk out while the room still has work to do. If a terminal goes quiet, the monitor notices and gets it restarted.

**Technically:**

- **STATUS (who is this terminal + what is it doing).** A statusline / `SessionStart` hook stamps the terminal's `FORGE_ROLE` (planner/coder/tester/reviewer/watchdog) and its current claude-peers summary into the prompt line, so a glance at any window says which lead it is. Each lead updates its slot in `.forge/HEARTBEAT.json` (per role) every ≤5 minutes — the liveness signal the planner (P6d) and the monitor read.

- **MONITORING (observe + /forge status + stalled-terminal detection).** Every terminal emits observe events (`SPAWN`/`PROGRESS`/…) to `.forge/observe/<role>.jsonl`. `/forge status` and the observatory dashboard read all leads' observe + heartbeat streams to render the whole team. A monitor flags any lead whose heartbeat is older than the threshold as stalled and surfaces it for restart (the same re-spawn path the planner uses in P6d).

- **CONTINUOUS BUILD (R7 stop-hook, per role).** The R7 `Stop`/`SubagentStop` hook (`tools/stop-hook.sh`) runs in every terminal and blocks that terminal from halting while phase work remains; `FORGE_ROLE` attributes both the continuation decision and the observe `STOP` event to the right agent. After 5 consecutive same-phase nudges it escalates to the operator instead of looping. (Behavior is exactly the R7 contract described in The Pipeline — terminal-per-agent only changes *which* role the nudge is attributed to.)

---

#### Opus 4.8 + Compound Engineering optimization

The agent team is tuned for the Opus 4.8 era:

- **Opus 4.8 (point 4).** The planner uses the 1M context window to hold the full spec + `TASKS.json` resident, so it can route work without re-reading. Each lead's deterministic fan-out (coding subagents, per-surface test subagents, per-dimension reviewers, doc-review agents) is dispatched with the Workflow tool / parallel subagents rather than ad-hoc spawning; every subagent returns a **structured output**; **fast mode** is used for mechanical, high-throughput steps (mass file edits, scans).

- **Compound Engineering (point 5).** Tiered reviewers run as separate subagents per dimension (correctness / security / performance / …) under the reviewer lead; the writer is never the auditor (coder ≠ tester/reviewer/watchdog). Learning is captured (`RETRO.md` + `MEMORY.md`) so each build starts smarter, document-review agents pre-screen the gates, and optimization loops run post-build. (This is the same tiered-review / learning-capture machinery described in P6b, G0–G2, and P8 — restated here as the team-level optimization posture.)

---

#### P6b — Build Loop [Delegated to Supervisor]

The supervisor terminal owns the build loop. It reads TASKS.json and executes:

1. **Task assignment:** For each ready task (respecting dependency graph, parallelizing where possible):
   - Spawn an Agent with `isolation: "worktree"` as implementor
   - Prompt includes: the specific spec section, CONTRACTS.md, architecture.md, eval harness, Decision Router rules (D5)
   - Commit messages must reference `[SPEC §X.Y]`
   - Branch naming: `forge/phase-6/{task-slug}`
   - Send `TASK_ASSIGNED` to orchestrator via claude-peers
   - **Reference project protocol:** If the user provides a reference codebase, agent prompts MUST say: "The spec is the authority. The reference project is a pattern guide for implementation style, not a source of truth for features or scope."

2. **Keep-or-revert ratchet** (Karpathy): After each commit, run the eval harness. If tests regress from the last passing state, `git reset --hard` to last good commit. The branch only advances on verified improvement.

3. **Smoke test (mandatory, run by supervisor):** After each agent returns, the supervisor runs the project's build + test commands directly via Bash:
   - For frontend: `npm install && npm run build`
   - For backend: `npm install && npx tsc --noEmit` (or equivalent)
   - For scripts/tests: `node --check` or equivalent
   If any command fails, send failure output back to the implementor for a fix iteration. A smoke test that was never run is a P6 violation.

4. **Tiered multi-agent code review (mandatory):** After smoke test passes, spawn 3–5 specialized reviewer subagents **in parallel** (inspired by Compound Engineering's tiered review). Each reviewer has a single lens and returns a verdict with a confidence score (HIGH/MEDIUM/LOW):

   | Reviewer | Lens | What it catches |
   |---|---|---|
   | **Correctness** | Logic errors, edge cases, state bugs, off-by-ones | The bug the author can't see |
   | **Spec Compliance** | CONSTITUTION.md Articles I–V, CONTRACTS.md interfaces, spec section coverage | Drift from the plan |
   | **Security** | Exploitable vulnerabilities, PII leaks, credential exposure, COPPA/FERPA | What gets you paged at 2am |
   | **Performance** | N+1 queries, bundle size, render-blocking, memory leaks | What makes the user wait |
   | **Maintainability** | Coupling, complexity, naming, dead code, premature abstraction | What makes the next engineer cry |
   | **API Contract** (CE) | Breaking API changes, interface drift from CONTRACTS.md | What breaks downstream consumers |
   | **Reliability** (CE) | Production failure modes, retry logic, graceful degradation, error boundaries | What fails silently in production |
   | **Pattern Recognition** (CE) | Architectural patterns and anti-patterns, code smells across the PR | What looks fine locally but is a systemic problem |
   | **Standards** (CE) | CLAUDE.md compliance, project conventions, Constitution Articles VI–X | What violates the project's own rules |

   After all reviewers return, the supervisor runs a **dedup/synthesis step**: merge overlapping findings, resolve contradictions (higher-confidence wins), produce a single verdict: APPROVE (all reviewers approve or LOW-confidence objections only) or REQUEST_CHANGES (any HIGH-confidence objection). Log all individual verdicts + synthesis to `.forge/REVIEW.json`.

   On fast track: run 3 reviewers (Correctness + Spec Compliance + Security).
   On full track: run all 9. Reviewer weights shift by domain — security heaviest for healthcare, performance for real-time, reliability for infrastructure, API contract for platform/SDK projects.

5. **Watchdog coordination:** After smoke test + review pass:
   - Send `PR_SUBMITTED` to watchdog via claude-peers (triggers drift check)
   - Wait for `DRIFT_RESULT` response from watchdog
   - On CLEAN: merge the PR, send `PR_MERGED` to watchdog (triggers post-merge check)
   - On DRIFT: block the PR, route to bug-fix loop (D8), re-submit after fix
   - On CRITICAL: send `DRIFT_CRITICAL` to orchestrator, halt all task assignment

6. **Learnings researcher (CE #11):** Before starting the structured debug protocol, the implementor (or supervisor) checks `.forge/LEARNINGS.md` for relevant past solutions: "Has this error pattern been seen before? Was there a known root cause? What fix worked?" If a matching learning exists, apply it first. This prevents re-solving known problems and is the mechanism that makes the compound loop actually work — learnings only compound if agents read them.

7. **Structured debug protocol** (inspired by CE's `/ce-debug`): When a test fails or a smoke test catches a bug, the implementor follows a systematic debug flow rather than guessing:
   - **Reproduce**: Run the failing test/command, capture exact error output
   - **Trace root cause**: Read the stack trace, identify the causal chain from error → source
   - **Form hypothesis**: State a testable hypothesis ("the state machine doesn't handle the empty-input edge case")
   - **Test-first fix**: Write a test that reproduces the bug, then fix the code to make it pass
   - **Verify**: Run the full eval harness to confirm no regressions
   If the implementor cannot form a hypothesis after reading the trace, escalate to supervisor with the trace + what was tried. Do not retry blindly.

7. **Stall detection:** If an implementor hasn't committed in 10 minutes (stale HEARTBEAT.json), the supervisor sends a `STALL_NUDGE` via claude-peers. If blocked after 3 fix attempts: escalate to operator.

7. **Cost tracking (D12):** After every agent spawn/return, update `.forge/COST.json`. If total spend reaches 80% of budget, pause and alert operator.

8. **Completion:** When every task has status "done" with reviewer verdict APPROVE, send `P6_COMPLETE` to orchestrator via claude-peers.

---

#### P6c — Watchdog Loop [Delegated to Watchdog Terminal]

The watchdog terminal runs independently, responding to events and periodic checks:

1. **On `PR_SUBMITTED` message** (from supervisor): Drift-check the PR diff against spec.md and CONTRACTS.md. Check 7 categories: structural, interface, invariant, feature, test, quality, visual. Send `DRIFT_RESULT` back to supervisor.

2. **On `PR_MERGED` message** (from supervisor): Drift-check the integrated state of the full repo on main. Catches cross-task drift that individual PR checks miss. Send `DRIFT_RESULT` to supervisor.

3. **On `/loop 30m` fire**: Full-repo audit of main branch. Send `AUDIT_PERIODIC` to supervisor.

4. **On CRITICAL finding** (invariant violation): Immediately send `DRIFT_CRITICAL` to orchestrator. Do not wait for the supervisor to relay. This is the emergency path.

5. **Write all results to `.forge/AUDIT.json`** and emit observe events.

The watchdog never checks in-progress worktrees — agents mid-implementation will always fail checks because the work isn't done.

---

#### P6d — Orchestrator Monitoring [During P6]

While the supervisor and watchdog run, the orchestrator:

1. **Liveness check:** Call `list_peers(scope: "repo")` every 5 minutes. If a peer disappears (terminal crashed), re-spawn it via tmux with the same prompt file. The re-spawned session reads TASKS.json and HEARTBEAT.json to resume from the next incomplete action. **Session intelligence** (inspired by CE's `/ce-sessions`): When re-spawning a crashed terminal, search `~/.claude/projects/` session logs for the crashed agent's last conversation context. Include a summary of what it was doing when it died in the re-spawn prompt. This gives the replacement session continuity instead of a cold start.

2. **Heartbeat check:** Read `.forge/HEARTBEAT.json`. If any agent's heartbeat is stale (>10 minutes), log a warning.

3. **Message check:** Listen for claude-peers messages:
   - `P6_COMPLETE` from supervisor → proceed to P6e shutdown
   - `DRIFT_CRITICAL` from watchdog → send `BUILD_HALT` to supervisor, alert operator
   - `TASK_ASSIGNED` / `TASK_COMPLETE` from supervisor → update cost tracking

4. **Cost check:** Read `.forge/COST.json` periodically. If approaching budget, send `BUILD_HALT` to supervisor.

---

#### P6e — Shutdown Sequence [Orchestrator]

When the orchestrator receives `P6_COMPLETE` from the supervisor:

1. **Shutdown handshake:** Send `SHUTDOWN` message to both supervisor and watchdog via claude-peers.
2. **Wait for ACK:** Each terminal finishes its current atomic action (commit, review verdict), sends `ACK_SHUTDOWN`, and exits.
3. **Timeout:** If `ACK_SHUTDOWN` not received within 60 seconds, fall back to `tmux kill-window -t forge-build:supervisor` and `tmux kill-window -t forge-build:watchdog`.
4. **P6 exit assertions** (blocking — build cannot proceed to P7 until all pass):
   - Every spec section has implementing code in the repo
   - Every public interface in CONTRACTS.md exists in the codebase
   - Architecture.md file structure matches actual repo structure
   - Any external API the code calls has been verified by actually calling it
   - Every task has a reviewer verdict of APPROVE (not skipped)
   - Smoke test passed for every agent's output (supervisor-run)
   - Secret scan passed (no credentials in committed files)
   - **Ship gate (R8 + R9):** run `tools/ship-gate.sh`. It scans the tree for stubs and counts open MAJOR+ stub/conformance gaps, then merges `no_open_stub_gaps` / `no_stubs_in_tree` / `no_open_conformance_gaps` assertions into `P6_EXIT.json`. Any failure → `pass:false` → the phase gate blocks P7. This is what makes R8/R9 *blocking* rather than advisory.
5. **Write `.forge/P6_EXIT.json`** with each assertion result. STATE.json cannot advance to phase 7 until P6_EXIT.json shows all passing.
6. **Compound learning capture** (inspired by CE's `/ce-compound`): Before killing terminals, extract and document what was learned during the build so future builds start smarter:
   - Decisions made (from MEMORY.md): which technical choices worked, which didn't
   - Patterns discovered: reusable code patterns, gotchas, framework quirks
   - Review findings: recurring review themes (e.g., "this codebase consistently has N+1 queries")
   - Debug traces: root causes found, what the symptoms looked like
   - Write to `.forge/LEARNINGS.md` in structured format:
     ```
     ## L-01: [Short title]
     **Context:** What we were doing when we learned this
     **Learning:** The reusable insight
     **Evidence:** The specific file/test/review that proved it
     **Reuse:** When a future build should apply this
     ```
   Future builds read `.forge/LEARNINGS.md` from previous builds (if the project has one) at P0 and inject relevant learnings into agent prompts. Each build compounds.
7. **Kill tmux session:** `tmux kill-session -t forge-build`
8. **Log:** `[timestamp] P6e complete — build phase finished, terminals shut down, {N} learnings captured`

---

#### Claude-Peers Message Contract

All inter-terminal messages use a structured JSON envelope inside the `message` field of `send_message`:

```json
{"type":"PR_SUBMITTED","from":"supervisor","ts":"2026-05-27T14:08:12Z","payload":{"task_id":"T-03","branch":"forge/phase-6/auth-module","pr_url":"...","spec_refs":["§3.1","§3.2"]}}
```

| Type | Direction | Purpose |
|---|---|---|
| `TASK_ASSIGNED` | supervisor → orchestrator | Task dispatched to implementor |
| `TASK_COMPLETE` | supervisor → orchestrator | Task done, PR submitted |
| `PR_SUBMITTED` | supervisor → watchdog | Trigger drift check on PR |
| `PR_MERGED` | supervisor → watchdog, orchestrator | Trigger post-merge check |
| `DRIFT_RESULT` | watchdog → supervisor | CLEAN / DRIFT / CRITICAL verdict |
| `DRIFT_CRITICAL` | watchdog → orchestrator | Invariant violation — halt build |
| `AUDIT_PERIODIC` | watchdog → supervisor | 30m periodic audit result |
| `STALL_NUDGE` | supervisor → implementor | Heartbeat-triggered nudge |
| `BUILD_HALT` | orchestrator → supervisor, watchdog | Emergency stop |
| `P6_COMPLETE` | supervisor → orchestrator | All tasks done, all reviews APPROVE |
| `SHUTDOWN` | orchestrator → supervisor, watchdog | Graceful shutdown signal |
| `ACK_SHUTDOWN` | supervisor/watchdog → orchestrator | Confirm shutdown, report final state |

**Durability:** Every message is also appended to `.forge/MESSAGES.json` as a fallback. If a claude-peers notification is missed, agents check this file on their heartbeat cycle.

**Rules:**
- Every `send_message` call must also emit an observe `SEND` event
- Every received message must emit an observe `RECV` event
- On `SHUTDOWN`: finish current atomic action, send `ACK_SHUTDOWN`, exit
- On `DRIFT_CRITICAL`: supervisor stops assigning tasks, sends `BUILD_HALT` to implementors
- Unrecognized message types: log to MEMORY.md and ignore (forward compatibility)

---

### Phase 7 — Test + Visual QA [AUTO]

**Output:** Test results, visual QA results, extracted gaps

1. **Execute the project's test suite via Bash** — not a file audit, not a markdown review. Run the actual commands:
   - `anchor test` (or equivalent for the smart contract / backend)
   - `npm run build` in every package directory (frontend, automation, root)
   - `npm test` if test scripts exist
   - `make setup` or the project's one-command entry point
   Capture stdout/stderr. Parse for pass/fail counts. If any command fails, that is a gap — do not paper over it. Write actual results to `.forge/TEST_RESULTS.md` with the raw command output. "Compiles" ≠ "works" — you must run it and see it pass.

2. **Cross-check spec coverage:** For each section in spec.md (S1, S2, ...), verify there is implementing code in the repo. For each route in S5 (frontend), verify the route exists in the filesystem. For each instruction in S3 (smart contract), verify the handler exists. This is a `grep`/`find` exercise, not a read-and-judge exercise. Write a coverage table to `.forge/AUDIT.json`.

3. If the project has a frontend, run **visual QA** (D10):
   - Start the dev server
   - Playwright screenshots of every route at 3 viewports (mobile 390px, tablet 768px, desktop 1440px)
   - Send screenshots to Claude vision: check for overlapping text, clipped elements, broken layouts, unreadable diagrams
   - On failure: implementor fixes → re-screenshot → re-check (max 3 iterations per component)
4. **Concrete walkthrough — not "run walkthrough," but these exact steps (R6):**
   - Start the dev server (`npm run dev` or equivalent)
   - Open the app in a browser (Playwright or agent-browser)
   - For each surface in workflow.md (S1, S2, ... SN), in sequence:
     - Navigate to the surface
     - Screenshot it: `.forge/walkthrough/S{N}.png`
     - Interact with it (click primary action, fill forms, trigger transitions)
     - Screenshot the result state
     - If any surface errors, throws, or shows broken layout: that is a BLOCKER gap
   - Write `.forge/WALKTHROUGH.md` with: surface ID, screenshot path, pass/fail, error description
   - **Phase 8 cannot begin until WALKTHROUGH.md covers every surface in workflow.md**
   - Phase gate hook enforces this: STATE.json cannot advance to phase 8 without WALKTHROUGH.md (R1)
   Concrete commands get followed. Vague instructions get interpreted — and "interpreted" under time pressure means "skipped."
5. **Dogfood QA (CE #10):** If the project has a frontend or user-facing interface, run an autonomous diff-scoped QA pass that goes beyond screenshots:
   - Build an exhaustive test matrix from the git diff (what changed since the spec was locked at G2)
   - For each changed surface: navigate to it in a real browser, exercise the primary user journey, check for errors
   - On failure: **auto-fix the issue, commit the fix, and re-test** — fully autonomous fix loops (max 3 per surface)
   - This upgrades the current P7 visual QA from "screenshot and flag" to "screenshot, fix, retest, and commit until green"
   - Write results to `.forge/DOGFOOD.md` with fix-commit hashes

6. **Simplification pass (CE #8):** After all tests pass and the dogfood QA is green, run 3 parallel simplification agents before gap classification:
   - **Reuse reviewer**: Find duplicated logic that should be extracted into shared functions
   - **Quality reviewer**: Find overly complex code that can be simplified without changing behavior
   - **Efficiency reviewer**: Find performance anti-patterns (unnecessary re-renders, redundant queries, bloated imports)
   Each produces findings. The supervisor applies safe simplifications (those that keep all tests green) and discards risky ones. This prevents "it works but it's ugly" from shipping. Write applied simplifications to `.forge/SIMPLIFY.md`.

7. **Extract gaps** from all failures: test failures, visual QA failures, dogfood failures, spec coverage misses, walkthrough findings, simplification opportunities that were too risky to auto-apply

---

### Phase 8 — Gap Loop + Optimization [AUTO]

**Output:** `.forge/GAPS.json`, potentially re-derived spec sections, optimization results

Classify each gap: `{ pillar, severity, spec_ref, description, type }`

- **Severity**: BLOCKER (invariant broken), HIGH (feature incomplete), MEDIUM (edge case), LOW (polish)
- **Type**: `spec-level` (the spec is wrong/missing), `prd-level` (the PRD is ambiguous/wrong), or `optimization` (works but could be better)

**For BLOCKER + HIGH spec-level gaps:**
1. Re-derive the affected spec section (P4 for that section only)
2. Regenerate affected tasks
3. Rebuild only the affected tasks (P6 for those tasks)
4. Re-test affected paths (P7 for those paths)
5. Log the re-derivation diff to `01-intake/DIFF.md`

**For PRD-level gaps:** Queue for Gate 3. Do not guess.

**For optimization gaps** (inspired by CE's `/ce-optimize`): When a gap is type `optimization` (MEDIUM/LOW severity — the feature works but performance, UX, or code quality could improve):
1. Define a measurable goal: "reduce bundle size from 180KB to under 100KB" or "improve LCP from 3.2s to under 2s"
2. Run up to 3 parallel experiment branches (worktree agents), each trying a different approach
3. Measure each against the goal (run benchmarks, Lighthouse, Playwright timing)
4. Keep the best-performing approach, discard others
5. Log the experiment results to `.forge/OPTIMIZE.json`: `{ goal, experiments: [{ approach, result, kept }] }`

This is optional on fast track (skip optimization gaps, log them as WONTFIX with rationale).

**Loop constraint:** Max 3 automatic iterations for BLOCKER/HIGH. Optimization runs once (not in the loop). If BLOCKER/HIGH gaps remain after 3 loops, surface at Gate 3.

---

### ▸ GATE 3 — Ship Decision [HUMAN] (D3)

**Present to operator using AskUserQuestion:**
- Working app (live URL or instructions to run locally)
- Spec compliance audit (% per domain from AUDIT.json)
- Test results + visual QA results
- Gap report: resolved gaps, remaining gaps (with severity and type)
- Cost actuals vs projection (from COST.json)
- Any PRD-level gaps that need operator direction

**Operator options:**
- **Ship** → proceed to Phase 9
- **Another gap loop** → re-enter Phase 8 with operator direction
- **Redirect** → operator provides new constraints, re-run from appropriate phase
- **Kill** → stop the build, write retro

---

### Phase 9 — Deploy + Document [AUTO]

**Output:** Deployed app, README.md, RUNBOOK.md, retro, documentation decks

1. Deploy to the target specified at Gate 2 (Vercel, Railway, devnet, etc.)
2. Generate/update `README.md` with quick-start instructions
3. Generate `RUNBOOK.md` with operational procedures (start, stop, monitor, troubleshoot)
4. Write `.forge/RETRO.md`: what worked, what drifted, what the gap loop caught, token spend, time breakdown
5. **Generate all documentation decks:** Run `/docs build` to produce per-folder Reveal.js decks and the master hub at `docs/hub.html`. This is the final documentation pass — every folder gets a navigable deck with diagrams, change tracking, and cross-links.
   - **Documentation web site (standard layout):** the sectioned doc web pages (PRD, spec, architecture, eval, …) use the standard spec-style layout — top `forge-nav` + left `.sidebar` in-page menu + `.main` — defined in `templates/template-docs-page.html`. Apply it to a page with `python3 tools/apply-docs-sidebar.py docs/<page>.html --title <Title>`. This is the standard for every project's doc web site (slide-deck output above is unchanged). Page types that aren't sectioned docs (a Reveal slide deck, a live dashboard) keep the top-nav only.
6. Final STATE.json: `{ "phase": 9, "status": "shipped" }`

---

### Phase 10 — Product Pulse [OPTIONAL, POST-SHIP]

After the build ships, the product's job isn't done — it's being used. Product Pulse (inspired by CE's `/ce-product-pulse`) generates a time-windowed report on what users actually experienced, so the next iteration has real signal to anchor to.

**Technically:** A `/loop`-based monitoring skill that runs post-deploy and writes reports to `docs/pulse-reports/`.

**Invocation:** `/forge pulse [--window 24h|7d|30d]` or set `pulse.auto: true` in forge.yaml for automatic daily reports.

**What it checks:**
1. **Usage**: page views, session counts, feature adoption (from analytics if available)
2. **Performance**: LCP, CLS, FID from real user metrics (if available) or synthetic Lighthouse runs
3. **Errors**: error rates, top error messages, stack traces from logs or error tracking
4. **User feedback**: support tickets, GitHub issues, Slack mentions (if accessible via MCP)

**Output:** `docs/pulse-reports/YYYY-MM-DD.md` — a single-page report with:
- Headline metrics (up/down vs. previous window)
- Top 3 issues by impact
- Recommended actions (linked to spec sections where applicable)
- Signal for the next brainstorm/gap loop cycle

**Compound loop:** Each pulse report feeds into the next build's P0 (Vision) — if pulse shows a feature is unused, the next build can deprioritize it. If pulse shows a failure mode, the next build's pillars can address it. The build → ship → pulse → build cycle is the outer compound loop.

On fast track: skip (no time for post-ship monitoring in a 1-week gauntlet).

---

### Documentation Protocol (all phases)

After **every phase** produces artifacts, the agent must:
1. Update that folder's `CHANGELOG.md` with what was produced and why
2. Append to root `CHANGES.md` with timestamp, phase, file, and change description
3. Run `/docs build <folder>` to regenerate that folder's deck + `/docs hub` to update navigation

This ensures documentation stays current throughout the build, not just at the end. At gates (G1, G2, G3), the operator sees `docs/hub.html` as the entry point to the full corpus.

---

## Trust Model — Why the Operator Can Walk Away

The system is designed so the operator does not need to monitor between gates. Each autonomous phase has a specific mechanism that catches failure *before* it compounds. The operator's time is reduced from ~8h to ~45m because the system handles the 3 categories of work that previously required human attention:

### What the system replaces (and how it earns trust)

| Previously manual | Forge mechanism | What catches failure | Operator sees at gate |
|---|---|---|---|
| Synthesizing 3 panel outputs into coherent findings | Auto-synthesis with convergent/divergent/risk classification (P2) | Inter-stage assertion: every PRD req maps to spec | G1: synthesis doc with flagged divergences |
| Researching trade-offs, writing decision docs | Research agents with required format: options, evidence, fallback (P3) | [VERIFIED]/[UNVERIFIED]/[OPEN] classification — nothing slips through unchecked | G1: trade-off matrices with source citations |
| Deriving spec from panels, tagging every requirement | Spec writer with PRD traceability tags (P4) | Assertion: every PRD requirement → spec section or [OUT OF SCOPE] | G2: full spec with traceable tags |
| Writing tests | Eval harness generated from workflow state machine (P5) | Tests are immutable — agents cannot weaken them to make code pass | G2: test count + coverage map |
| Reviewing every PR for spec compliance | Reviewer agent + optional 2nd model (P6) | Watchdog runs every 5m independently — catches what reviewer misses | G3: audit report with drift scores |
| Classifying bugs as code vs spec vs environment | Bug-fix loop with 3-attempt limit and typed classification (P6) | Keep-or-revert ratchet — branch never gets worse than last passing state | G3: gap report with resolution status |
| Deciding if gaps are spec-level or PRD-level | Gap classifier routes automatically (P8) | Spec-level gaps auto-fix; PRD-level gaps surface at gate — no silent assumptions | G3: remaining gaps classified by type |
| Running the app and checking for visual bugs | Visual QA screenshots at 3 viewports + Claude vision (P7) | Fix→re-screenshot→re-check loop, max 3 | G3: screenshot evidence |

### The trust contract

At each gate, the operator receives **evidence, not claims**:
- G1: "Here are the panel findings with sources. Here's where they disagree. Here's what we couldn't verify."
- G2: "Here's the spec with every requirement traced. Here are the tests that will verify it. Here's what it will cost."
- G3: "Here's the running app. Here's the audit. Here are the gaps. Here's actual spend. Ship or loop?"

The system never says "it works" — it shows the audit trail and lets the operator judge. Constitution Article VIII (Honest Reporting) enforces this: agents describe what actually happened, not what was intended.

---

## Safety Mechanisms (active during all phases)

### Decision Router (D5) — injected into every agent prompt
Every agent classifies decisions before acting:
- **Tactical** (naming, style, imports) → decide silently
- **Technical** (library choice, pattern, cache strategy) → decide + log to MEMORY.md
- **Architectural** (new dependency, interface change, data model) → escalate to supervisor/orchestrator
- **Strategic** (drop feature, change scope, accept security trade-off) → queue for next human gate
- **Rule:** If reversible, pick the best option and log it. If irreversible, queue for gate. Never ask a bare question — always include: decision needed, options considered, recommendation, reversibility assessment.
- **Decision Deck:** After resolving any **Architectural** or **Strategic** decision, invoke `/decision log` with the decision details (question, options considered, chosen option, rationale, cascade impacts). This creates a permanent McKinsey-style slide in the project's `decisions/deck.html`. Technical decisions are logged to MEMORY.md only — too frequent for deck slides.

### Constitution Enforcement
- Articles I–V checked by reviewer on every PR and by watchdog on every loop
- Fabrication (Art. I violation) is a CRITICAL drift event that halts the build
- Every agent prompt includes: "If unsure about an API, flag, or behavior — check it. Don't guess."

### Secret Scanning (Article III enforcement)
After every agent returns, and again at the P6→P7 boundary, the orchestrator runs:
```bash
grep -rn "api-key\|api_key\|apikey\|secret\|password\|token=" --include="*.ts" --include="*.tsx" --include="*.json" --include="*.env*" --include="*.yaml" --include="*.yml" . | grep -v node_modules | grep -v ".git/"
```
Any match in a committed file (not .gitignored) that looks like a real credential is a BLOCKER gap. The orchestrator replaces it with a placeholder and logs the violation to MEMORY.md. `.env.local`, `.env`, and any file matching `*.key` or `*.pem` must be in `.gitignore` — if missing, add them before proceeding.

### Anti-Hallucination Protocol
- Every API existence claim verified by actually calling it
- Every library version checked on the registry
- Unverified claims tagged `[UNVERIFIED]` with fallback plan
- "Compiles" ≠ "works" — must run it

### Inter-Stage Assertions (Compound AI)
Run programmatic checks between phases:
- After P4: every PRD requirement → spec section or [OUT OF SCOPE]
- After P5: every task → spec section; no dependency cycles
- After P6: every repo file owned by a spec section
- Assertion failure → automatic retry with violation message appended

---

## Observability (D13)

All state lives in `.forge/` and `docs/`. The conversation is disposable.

**Agent output persistence invariant:** When a background agent (panel, researcher, reviewer) completes, the orchestrator MUST write its full result to the designated docs/ file BEFORE consuming it for decisions or proceeding to the next phase. Panel results → `03-panels/`, research results → `02-grounding/`, review results → `.forge/AUDIT.json`. Context is compressible and losable — files are the record. If a panel ran but its findings aren't in `03-panels/`, the panel effectively didn't run. Enforcement: after every agent return, verify the designated output file exists and is non-empty before proceeding.

### State Files

| File | Written by | Updated | What it tells you |
|------|-----------|---------|-------------------|
| STATE.json | Orchestrator | After every phase + gate | Current phase, status, track |
| MEMORY.md | All agents (append-only) | On every decision/escalation | Prose log of all agent actions |
| TASKS.json | Spec writer, supervisor | On task assign/complete/block | Per-task status + agent assignment |
| AUDIT.json | Watchdog | On PR, merge, every 30m | Drift check verdicts (CLEAN/DRIFT/CRITICAL) |
| GAPS.json | Tester, gap loop | After test runs + walkthrough | Classified gaps with severity + resolution |
| COST.json | Orchestrator | After every agent spawn/return | Token spend per agent, per phase, total |
| EVAL/ | Spec writer (P5) — then locked | Written once, immutable | Test harness (the contract) |
| P6_EXIT.json | Orchestrator | At P6→P7 boundary | Exit assertion pass/fail per check |
| TEST_RESULTS.md | Orchestrator (P7) | After running test suite | Raw test output with pass/fail counts |
| HEARTBEAT.json | All agents | Every 5 minutes during P6 | Agent liveness + current task + progress |

### Agent Heartbeat Protocol

During Phase 6 (parallel build), every agent writes to `.forge/HEARTBEAT.json` every 5 minutes. The orchestrator reads this file to detect stalls without waiting 15 minutes of silence.

**Format:**
```json
{
  "agents": {
    "impl-1": {
      "task": "task-03",
      "spec_ref": "S4.2",
      "status": "coding",
      "last_commit": "2026-05-27T14:32:00Z",
      "last_heartbeat": "2026-05-27T14:35:00Z",
      "files_written": 4,
      "tests_passing": 12,
      "tests_failing": 2,
      "blocked_on": null
    },
    "impl-2": {
      "task": "task-05",
      "spec_ref": "S6.1",
      "status": "blocked",
      "last_commit": "2026-05-27T14:20:00Z",
      "last_heartbeat": "2026-05-27T14:35:00Z",
      "files_written": 2,
      "tests_passing": 0,
      "tests_failing": 3,
      "blocked_on": "Missing API key for external service"
    },
    "reviewer": {
      "task": "review-task-01",
      "status": "reviewing",
      "last_heartbeat": "2026-05-27T14:34:00Z"
    },
    "watchdog": {
      "status": "watching",
      "last_audit": "2026-05-27T14:30:00Z",
      "verdict": "CLEAN"
    }
  }
}
```

**Heartbeat rules:**
- Every agent updates its entry in HEARTBEAT.json every 5 minutes (read → update own entry → write)
- Status values: `coding`, `testing`, `reviewing`, `watching`, `blocked`, `done`, `failed`
- If `last_heartbeat` is >10 minutes stale, the orchestrator classifies that agent as STALLED
- Stall protocol: nudge agent via claude-peers → if no response in 5m, read their worktree to assess → if blocked on a decision, make it and log → if crashed, restart from last commit

**Enforcement:** The orchestrator checks HEARTBEAT.json before every major action (spawning new agents, proceeding to next phase, presenting at gates). An agent that never writes to HEARTBEAT.json is treated as unobservable — the orchestrator escalates immediately rather than waiting for the 15m stall timeout.

### claude-peers Protocol (mandatory, not optional)

**On agent spawn (enforced):** Every agent's prompt MUST include: "As your first action, call `set_summary` with a description of your task. Update it when your status changes. This is not optional — the operator uses it to monitor the build."

**Summary format:** `[FORGE {role}] {status}: {task description}`
- Examples: `[FORGE impl-1] coding: camera pipeline per SPEC §4.2`
- `[FORGE watchdog] CLEAN: last audit 2m ago, 0 drift`
- `[FORGE reviewer] reviewing: task-03 PR, checking Art. I-V`

**Summary updates (enforced):** Agents update their summary when:
- Starting a new task
- Completing a task
- Hitting a blocker
- Changing status (coding → testing → done)

If an agent's summary still says "coding" but its heartbeat shows "blocked," the orchestrator treats the summary as stale and escalates.

### `/forge status` — Operator Dashboard

When the operator runs `/forge status`, read all `.forge/` state files and claude-peers, then produce a structured dashboard:

```
┌─────────────────────────────────────────────────────┐
│ FORGE STATUS — [project name]                       │
│ Phase: P6 Build (3/8 tasks done)                    │
│ Track: full │ Elapsed: 2h 14m │ Budget: $23/$100    │
├─────────────────────────────────────────────────────┤
│ AGENTS                                              │
│  impl-1  ● CODING   task-03 [S4.2] camera pipeline │
│                      4 files, 12/14 tests passing   │
│                      last commit 3m ago             │
│  impl-2  ◐ BLOCKED  task-05 [S6.1] auth service    │
│                      needs API key — queued for G3  │
│                      last commit 15m ago ⚠          │
│  impl-3  ● CODING   task-07 [S8.1] order book      │
│                      6 files, 8/8 tests passing     │
│  reviewer ● IDLE     waiting for next PR            │
│  watchdog ● CLEAN    last audit 2m ago              │
├─────────────────────────────────────────────────────┤
│ TASKS                                               │
│  ✓ task-01  init-config         done   (impl-1)    │
│  ✓ task-02  schema-setup        done   (impl-1)    │
│  ◐ task-03  camera-pipeline     coding (impl-1)    │
│  ✓ task-04  data-model          done   (impl-2)    │
│  ✗ task-05  auth-service        blocked(impl-2)    │
│  · task-06  lesson-ui           pending             │
│  ◐ task-07  order-book          coding (impl-3)    │
│  · task-08  deploy-config       pending             │
├─────────────────────────────────────────────────────┤
│ SAFETY                                              │
│  Watchdog: CLEAN (last 2m)                          │
│  Drift alerts: 0                                    │
│  Secret scan: passed                                │
│  Reviews: 2 approved, 0 pending, 1 in progress     │
├─────────────────────────────────────────────────────┤
│ ALERTS                                              │
│  ⚠ impl-2 stalled 15m — blocked on API key         │
│  ⚠ task-06 depends on task-05 (blocked)             │
├─────────────────────────────────────────────────────┤
│ COST                                                │
│  P0-P5: $8.40 │ P6: $14.60 │ Total: $23.00/$100   │
│  █████████████████████░░░░░░░░░░░░░░░░░░  23%      │
└─────────────────────────────────────────────────────┘
```

**How `/forge status` builds this dashboard:**

1. **Phase + progress:** Read `STATE.json` for current phase. Read `TASKS.json` and count statuses.
2. **Agents:** Read `HEARTBEAT.json` for per-agent status, task, progress metrics, last commit time. Flag any agent whose `last_heartbeat` is >10m stale.
3. **Tasks:** Read `TASKS.json` for the full task list with status and agent assignment. Mark blocked tasks and their downstream dependencies.
4. **Safety:** Read `AUDIT.json` for latest watchdog verdict. Check `P6_EXIT.json` if it exists. Read MEMORY.md for recent secret scan results. Count reviewer verdicts from AUDIT.json.
5. **Alerts:** Aggregate: stalled agents (heartbeat >10m), blocked tasks, drift alerts, budget warnings (>60%), unresolved BLOCKER gaps.
6. **Cost:** Read `COST.json` for per-phase and total spend. Show progress bar against `budget.max_build` from forge.yaml.

**The dashboard is text, not HTML.** It prints to the terminal. The operator can run it from any Claude Code session at any time — it reads files, not conversation state. Works after a crash, after resume, mid-build.

### Communication Channels

- **File-based** (primary): `.forge/MEMORY.md` (prose decisions), `.forge/HEARTBEAT.json` (structured liveness), `.forge/TASKS.json` (task status). All persistent, survive crashes, readable by any session.
- **Real-time** (inter-terminal): claude-peers MCP. `set_summary` for status visibility, `send_message` for stall nudges and drift alerts. Ephemeral — lost on crash, but HEARTBEAT.json has the durable record.

**Resume:** `/forge --resume` reads STATE.json, validates HEARTBEAT.json for agent liveness, continues from the next incomplete task. If agents appear stalled (heartbeat >10m), the orchestrator re-spawns them from their last commit.

---

## Configuration (D14)

Cascade: `~/.forge/forge.yaml` (global) → `.forge/forge.yaml` (project) → CLI flags.

Read forge.yaml at skill start. Apply to all agent prompts, build parameters, and model selection.

Key settings: `build.default_track`, `build.max_implementors`, `build.gap_loop_max`, `budget.max_build_cost`, `budget.alert_threshold`, `models.default`, `models.overrides.*`, `agents.stall_timeout`, `agents.stall_retries`, `code.typescript.strict`, `design.theme`, `communication.verbosity`, `build.ci_platform`.

---

## Skill Maintenance

| File | Purpose |
|------|---------|
| `SKILL.md` | The skill itself (this file) |
| `CHANGELOG.md` | Version history — what changed, what gap each fix closes |
| `dashboard.html` | Live build dashboard — drop .forge/ files to visualize state |
| `test-harness.md` | 10 regression tests — run after any SKILL.md edit to verify fixes hold |

**After editing SKILL.md**, run the test harness:
```bash
# Quick: all 10 tests in one command (see test-harness.md for details)
echo "T1: $(grep -c 'Reference project protocol' ~/.claude/skills/forge/SKILL.md)" && \
echo "T2: $(grep -c 'Smoke test (mandatory' ~/.claude/skills/forge/SKILL.md)" && \
echo "T3: $(grep -c 'Code review (mandatory' ~/.claude/skills/forge/SKILL.md)" && \
echo "T4: $(grep -c 'Secret Scanning' ~/.claude/skills/forge/SKILL.md)" && \
echo "T5: $(grep -c 'not a file audit' ~/.claude/skills/forge/SKILL.md)" && \
echo "T6: $(grep -c 'P6_EXIT.json' ~/.claude/skills/forge/SKILL.md)" && \
echo "T7: $(grep -c 'HEARTBEAT.json' ~/.claude/skills/forge/SKILL.md)" && \
echo "T8: $(grep -c 'claude-peers Protocol' ~/.claude/skills/forge/SKILL.md)" && \
echo "T9: $(grep -c 'forge status' ~/.claude/skills/forge/SKILL.md)" && \
echo "T10: $(test -f ~/.claude/skills/forge/CHANGELOG.md && echo OK || echo MISSING)"
# All values should be >=1 (T6 >=3, T7 >=3, T9 >=3)
```

**After editing SKILL.md**, update CHANGELOG.md with what changed and why.
