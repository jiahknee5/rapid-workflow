# Build **Rapid** — a dynamic rapid-prototyping build workflow shipped as Claude Code skills + enforcement hooks + observability surfaces

You are building **Rapid**: a methodology *kit* that turns a stakeholder requirement into a tested, audited, documented, deployed application through a deterministic 12-phase / 4-gate pipeline with dynamic per-project composition. You have NO access to any prior repository. Everything you need is in this prompt. Build every file named below, in the order given.

---

## Contents

- **1. Mission & core thesis**
  - 1.1 Lineage to honor
  - 1.2 gstack — role-based governance
- **2. Non-negotiable invariants (encode these as rules everywhere)**
- **3. The deterministic 12-phase / 4-gate scaffold (reference table the SKILL.md must encode verbatim)**

**FILE MANIFEST**
- **4. `.rapid/` — runtime state contract (local-only, gitignored; documented here as runtime-generated schemas)**
  - 4.1 `.rapid/STATE.json`
  - 4.2 `.rapid/MEMORY.md`
  - 4.3 `.rapid/TASKS.json`
  - 4.4 `.rapid/EVAL/`
  - 4.5 `.rapid/AUDIT.json`
  - 4.6 `.rapid/GAPS.json`
  - 4.7 `.rapid/COST.json`
  - 4.8 `.rapid/P6_EXIT.json`
  - 4.9 `.rapid/VERIFY.json` + `.rapid/verify.cmds.json`
  - 4.10 `.rapid/DECISIONS.json`
  - 4.11 `.rapid/PREFLIGHT.json` + `.rapid/preflight.json`
  - 4.12 `.rapid/HEARTBEAT.json`
  - 4.13 `.rapid/REVIEW.json`
  - 4.14 `.rapid/CONFORMANCE.md`
  - 4.15 `.rapid/STUBS.md`
  - 4.16 `.rapid/LEARNINGS.md`
  - 4.17 `.rapid/OPTIMIZE.json`
  - 4.18 `.rapid/MESSAGES.json`
  - 4.19 `.rapid/RETRO.md`
  - 4.20 `.rapid/DEEPENING.md`
  - 4.21 `.rapid/WALKTHROUGH.md`
  - 4.22 `.rapid/DOGFOOD.md` / `.rapid/SIMPLIFY.md`
  - 4.23 `.rapid/observe/<role>.jsonl` + `.rapid/observe/seq.txt`
  - 4.24 `.rapid/RUNS/<wf>/<run>.jsonl` + `.rapid/RUNS/<wf>/index.json`
  - 4.25 `.rapid/E2E.json`
  - 4.26 `.rapid/.stop_count`, `.rapid/.stop_phase`, `.rapid/.conformance_seen`
  - 4.27 `.rapid/prompts/<role>.md`, `.rapid/worktrees/coder-N`
- **5. `tools/` — hooks (mechanical enforcement)**
  - 5.1 `tools/phase-gate-hook.sh` (R1 — phase gate)
  - 5.2 `tools/stop-hook.sh` (R7 — continuation)
  - 5.3 `tools/module-conformance-hook.sh` (R8 — conformance)
  - 5.4 `tools/stub-detect-hook.sh` (R9 — stub scan at write)
  - 5.5 `tools/stub-scan.sh` (R9 utility — shared scanner)
  - 5.6 `tools/post-write-hook.sh`
  - 5.7 `tools/install-hooks.sh`
- **6. `tools/` — operational tooling**
  - 6.1 `tools/preflight.sh`
  - 6.2 `tools/new-project.sh`
  - 6.3 `tools/verify.sh`
  - 6.4 `tools/ship-gate.sh`
  - 6.5 `tools/cost-summary.sh`
  - 6.6 `tools/observe-server.py`
  - 6.7 `tools/workflow-runner.py`
  - 6.8 `tools/rapid-team.sh`
  - 6.9 `tools/build-docs-registry.sh`
  - 6.10 `tools/populate-deck.py`
  - 6.11 `tools/apply-docs-sidebar.py`
  - 6.12 `tools/atlas-init.sh`
  - 6.13 `tools/atlas-deploy.sh`
  - 6.14 `tools/gaps-to-issues.sh`
  - 6.15 `tools/log-decision.sh`
  - 6.16 `tools/lifecycle-e2e.sh`
- **7. `skills/` — the orchestrator + supporting skills (source of truth, symlinked into `~/.claude/skills/`)**
  - 7.1 `skills/rapid-workflow/SKILL.md` (the orchestrator — Rapid's core, ~1280 lines)
  - 7.2 `skills/workflow/SKILL.md`
  - 7.3 `skills/docs/SKILL.md`
  - 7.4 `skills/decision/SKILL.md`
- **8. `docs/` & `templates/` — surfaces, decks, and reusable form**
  - 8.1 `templates/template-docs-page.html`
  - 8.2 `docs/env-links.js`
  - 8.3 `docs/sidebar.js`
  - 8.4 `docs/observatory.html`
  - 8.5 `docs/testsuite.html`
  - 8.6 `docs/workflows.json`
  - 8.7 `docs/eval.html` + `docs/eval.json`
  - 8.8 `docs/cost.html`
  - 8.9 `docs/home.html`
  - 8.10 `docs/env.json`
  - 8.11 `docs/regen.json`
  - 8.12 `docs/testruns.json`
  - 8.13 `docs.json`
  - 8.14 `templates/template-docs-deck.html`
  - 8.15 `templates/template-decision-deck.html`
  - 8.16 `templates/BUILD-AUTONOMY.md`
  - 8.17 `templates/contract-seam.md`
  - 8.18 `templates/agent-roles/{planner,coder,tester,reviewer,watchdog}.md`
  - 8.19 `docs/rapid-architecture.html` + `docs/rapid-reference.md` (+ `tools/rapid-spec.html`)
  - 8.20 `CONSTITUTION.md`
- **9. Repo layout, version control, and packaging**
  - 9.1 `.gitignore`
  - 9.2 `README.md`, `CHANGELOG.md`, `CODEBASE.md`, `ROADMAP.md`
  - 9.3 `examples/vision/{VISION.md,PILLARS.md}`
  - 9.4 `archive/`
- **10. Global acceptance criteria (self-check before declaring done)**

---

## 1. Mission & core thesis

Rapid is not a code generator — it is an **enforcement system**. Its thesis: *prose instructions fail under pressure.* An LLM agent under deadline will skip invisible safety work (tests, audits, walkthroughs) if "skip it" is cheaper than "do it." Therefore every load-bearing step is made **structural**, never behavioral:

- **Hooks** (registered in Claude Code's `settings.json`) block phase advance, block early stops, and scan every write.
- **Blocking dependencies** (`task-00` eval harness is the root of the task graph) make tests un-skippable.
- **Separate agents** (the *writer is never the auditor*) make audit a different agent with no implementation incentive.
- **Gates** (G0/G1/G2/G3) are hard stops for human judgment.

**The loop is the product; the build is the artifact.** Each build compounds (LEARNINGS.md captured at end, injected at start of next).

The pipeline shape (12 phases, 4 gates, message contract, keep-or-revert, immutable eval harness, cost breaker, shutdown handshake, fixed stop-condition set) is **deterministic — it never changes**. Everything *inside* (panel selection, reviewer weights, debug protocol, optimization strategy, pillar derivation, spec sections, task count, test cases, doc-review criteria) is **composed per project** from existing frameworks — never invented at runtime.

### 1.1 Lineage to honor

Honor these explicitly (name them; don't reinvent them): **Karpathy autoresearch** (immutable eval harness, keep-or-revert ratchet, never-stop-never-ask tactical decisions, surgical one-section changes), **TDD/Beck** (tests before code, owned by a separate concern, red-green-refactor), **Compound AI Systems / Zaharia** (inter-stage assertions, multi-model routing), **Compound Engineering** (tiered per-dimension review, learning capture, doc-review pre-screen gates, post-build optimization loops).

### 1.2 gstack — role-based governance

Honor **gstack** (Garry Tan's Claude Code setup): one agent that switches into distinct, skill-defined *personas* — Founder/CEO, Designer, Eng Manager, Release Manager, Doc Engineer, QA — each its own `SKILL.md` with a bounded mandate and explicit handoffs, rather than one undifferentiated generalist wearing every hat. Rapid already separates builder from auditor; gstack generalizes the principle: **every role is a named cognitive mode backed by its own skill file, so who-does-what is structural (which skill is invoked) — not improvised mid-task.** Apply it to Rapid's five-lead build team (planner / coder / tester / reviewer / watchdog): each lead is a persona-skill with a defined contract and seam, never a role the same context casually assumes and drops.

---

## 2. Non-negotiable invariants (encode these as rules everywhere)

1. **Builder ≠ auditor.** Coder ≠ Tester ≠ Reviewer ≠ Watchdog. No single agent both implements and audits the same work. Structural (separate tmux windows / subagents), not behavioral.
2. **Load-bearing steps are enforced by hook / dependency / separate-agent — never by prose.** If a safety step is only a sentence in a prompt, it is wrong.
3. **The eval harness is locked before code.** `task-00` (eval harness) is the root of the task graph; all tasks depend on it; it must be `status:done` before any other task starts; agents may EXTEND tests but never EDIT them to make code pass. A failing test means the code is wrong (or the spec is wrong → re-derive spec, never weaken the test).
4. **Phase order is fixed and sequential:** P0 → P1 → P1b → **G0** → P2 → P3 → **G1** → P4 → P5 → P5b → **G2** → P6 → P7 → P8 → **G3** → P9 → P10. No reordering, no cross-phase parallelism.
5. **Fan-out ≤ 4 implementors + 1 watchdog.** Beyond 4 implementors, honest review degrades. Sizing: ≤5 tasks → 1 impl; 6–12 → 2; 13+ → 3–4.
6. **Gap loop caps at 3 auto iterations** for BLOCKER/HIGH spec-level gaps. PRD-level gaps surface to G3 (never guessed). Optimization runs once (not a loop).
7. **e2e is required to ship.** `.rapid/VERIFY.json` must show `verification_real == true` (e2e green). e2e is never optional.
8. **Deterministic scaffold vs per-project dynamic composition** (the table below is the deterministic part; the SKILL.md must encode it verbatim).
9. **Standing authorization is all-or-nothing.** `CONSTITUTION.md` + locked PRD + signed `BUILD-AUTONOMY.md` present at project root = run-to-completion without per-step gates. Absent = per-step confirmation. No partial authorization.
10. **The stop-condition set is fixed and NOT overridable.** Standing authorization expands what runs without *asking*; it never expands what runs without *stopping*. Stop set: (1) destructive/irreversible (rm, force-push, DROP TABLE, history rewrite, anything `git reset --hard` can't undo); (2) outward-facing (push, deploy, publish, send mail/message — leaves the machine); (3) spends money (paid infra, metered API beyond G2 budget); (4) genuinely-undecidable high-stakes fork (both branches carry material hard-to-reverse consequence and spec gives no basis).
11. **Keep-or-revert ratchet:** after every commit, run the immutable eval harness; if it regresses from last passing state, `git reset --hard` to last green. The branch never gets worse.
12. **All state persists in `.rapid/` and `docs/`; conversation is disposable, files are the record.** When a background agent returns, the orchestrator MUST write its result to a file BEFORE consuming it.
13. **Constitution Articles I–V are inviolable** (truthfulness, user safety, data handling, reversibility, scope). **VI–X overridable only with explicit `# OVERRIDE` + log to gaps history.**
14. **Spec is derived from PRD with a maintained diff — never duplicated.** Every PRD requirement maps to a spec section OR is tagged `[OUT OF SCOPE]`. Every spec section is `[FROM PRD]` or `[DERIVED]`.
15. **Watchdog is spawned automatically at P6a** and runs independently; P6 cannot exit without `AUDIT.json`.
16. **Every live surface degrades honestly to a static fallback.** No surface may depend on JS to render its skeleton; HTML+CSS must suffice; absent data shows an honest "not set / no data yet" state, never a broken page.
17. **All hooks fail SAFE.** No `set -e`; every path ends `exit 0` (except phase-gate's deliberate `exit 2`); all reads guarded with `|| true`; no-op instantly if `.rapid/STATE.json` absent. A hook bug must never trap an unrelated Claude session.
18. **All gate/verify tooling uses genuine exit codes.** Output is *redirected* to log files, never piped (piping masks `$?`); `set -o pipefail` everywhere.

---

## 3. The deterministic 12-phase / 4-gate scaffold (reference table the SKILL.md must encode verbatim)

| Pos | Phase / Gate | Mode | Purpose | Exit artifact |
|---|---|---|---|---|
| P0 | Vision Extraction | AUTO | Extract north star, success signals, objective; derive 3–5 project pillars; compound-refresh prior LEARNINGS | `00-vision/VISION.md`, `00-vision/PILLARS.md`; optional `01-intake/BRAINSTORM.md` |
| P1 | Structure | AUTO | Scaffold numbered folders; lock PRD; draft CONSTITUTION + BUILD-AUTONOMY; init `.rapid/`; preflight runtimes; Atlas scaffold | folders + `01-intake/PRD.md` (locked) + `01-intake/DIFF.md` + `CONSTITUTION.md` + `BUILD-AUTONOMY.md` + `.rapid/STATE.json` + `.rapid/PREFLIGHT.json` (green) + live Atlas deck |
| P1b | PRD Decomposition | AUTO | Decompose raw PRD into categorized, tagged, traced checklist | `01-intake/PRD-ENHANCED.md` |
| **G0** | **Enhanced PRD Review** | **HUMAN** | Operator reviews decomposed PRD before panels (3 doc-review subagents: Feasibility, Scope Guardian, Coherence) | PRD-ENHANCED signed off |
| P2 | Expert Panels | AUTO | 1 (fast) or 3 (full) panels review through pillars | `03-panels/synthesis.md` (convergent/divergent/risks/open, with sources) |
| P3 | Grounding Research | AUTO | Resolve `[OPEN]` questions; verify external data availability | `02-grounding/{question}.md` (options/evidence/recommendation/fallback/verification/classification) |
| **G1** | **Direction** | **HUMAN** | Resolve panel/research; answer **undecidable batch**; **sign BUILD-AUTONOMY.md** (2 doc-review subagents: Adversarial, Feasibility) | Direction locked; BUILD-AUTONOMY signed → standing authorization active |
| P4 | Spec Derivation | AUTO | Derive spec; trace every req; emit contracts + workflow state machine | `04-spec/spec.md`, `workflow.md`, `architecture.md`, `CONTRACTS.md`, `docs/workflows.json` |
| P5 | Task Decomposition + Eval Harness | AUTO | Size implementors; generate immutable `task-00` eval harness; decompose with traceability; generate role files + CI config | `.rapid/TASKS.json`, `.rapid/EVAL/` (locked), `04-spec/agents/*.md`, CI config |
| P5b | Spec Deepening | AUTO | 3 subagents (flow analyzer, confidence checker, deliverable verifier) find gaps before point of no return | `.rapid/DEEPENING.md` (blocking questions for G2) |
| **G2** | **Architecture (Point of No Return)** | **HUMAN** | Approve spec/arch/tasks/eval/cost; collect creds + `.env` (3+3 doc-review subagents) | Spec locked, eval locked, cost budgeted |
| P6 | Parallel Build | AUTO | Five-lead team builds to locked spec; watchdog audits; keep-or-revert; tiered review | merged PRs (all APPROVE), passing tests, `.rapid/AUDIT.json`, `.rapid/P6_EXIT.json` (all pass), `.rapid/LEARNINGS.md` |
| P7 | Test + Visual QA | AUTO | Real test suite per-layer; visual QA 3 viewports; concrete walkthrough every surface; recorded workflow runs; extract gaps | `.rapid/VERIFY.json`, `TEST_RESULTS.md`, `WALKTHROUGH.md`, `DOGFOOD.md`, `SIMPLIFY.md`, `.rapid/RUNS/` |
| P8 | Gap Loop + Optimization | AUTO | Classify gaps; auto-fix BLOCKER/HIGH spec-level (≤3); run optimization once; surface rest | `.rapid/GAPS.json` (classified), `.rapid/OPTIMIZE.json` |
| **G3** | **Ship Decision** | **HUMAN** | Review app/audit/tests/gaps/cost; decide ship / loop / redirect / kill | operator decision recorded |
| P9 | Deploy + Document | AUTO | Deploy; README + RUNBOOK; retro; doc decks; deploy Atlas alongside product | deployed product, `README.md`, `RUNBOOK.md`, `.rapid/RETRO.md`, doc decks, Atlas at `/_atlas` |
| P10 | Product Pulse | OPTIONAL post-ship | Time-windowed usage/perf/error/feedback report feeding next P0 | `docs/pulse-reports/YYYY-MM-DD.md` |

**The 4 gates, precisely:**
- **G0** (after P1b): pre-screen with 3 doc-review subagents (Feasibility, Scope Guardian, Coherence). Approves: corrections to MUST/SHOULD/COULD priority, answers to open questions, additional reqs, out-of-scope confirmation, `[RISKY]` resolution. Redirect → re-run P1b.
- **G1** (after P3): pre-screen with 2 doc-review subagents (Adversarial, Feasibility). Approves: strategic direction on divergences, priority ranking, creds/APIs, **answers to the undecidable decision batch** (written back to spec/PRD with `basis=spec`), and **signs BUILD-AUTONOMY.md** (fills deploy target, spend ceiling, confirms stop-condition set). Presence of signed file = standing authorization. Redirect → re-run P2–P3.
- **G2** (after P5b, **POINT OF NO RETURN**): pre-screen with 3+3 doc-review subagents (Scope Guardian, Coherence, Adversarial + deepening findings). Approves: final spec/arch/tasks/eval, cost projection, deploy target, `.env` values (written gitignored). After approval, P6 proceeds; no major redirect without re-entering P4–P5.
- **G3** (after P8): review working app, spec-compliance % per domain, tests + visual QA, gaps (resolved/remaining), cost actual vs projection. Options: **Ship** (P9) / **Loop** (P8 w/ constraints) / **Redirect** (re-run from a phase) / **Kill** (stop + retro).

**Tracks:** `fast` (1 panel; P6 = planner+coder+reviewer+watchdog, tester folds into coder's keep-or-revert; 3 reviewer dimensions; skip P8 optimization + P10) and `full` (3 panels; all 5 leads; up to 9 reviewer dimensions). A `tiny` cadence runs all roles as subagents under a single planner terminal.

---

# FILE MANIFEST

Build in the order below. Foundational state contracts first, then hooks, then tools, then the orchestrator skill, then docs/surfaces, then packaging.

---

## 4. `.rapid/` — runtime state contract (local-only, gitignored; documented here as runtime-generated schemas)

> `.rapid/` is created at P1 and is **never version-controlled**. It is the build's memory. Document each as a generated schema; tools and hooks create/read/write them. All JSON files must tolerate being absent (read-guarded) and either bare-list or `{key:[...]}` shapes where noted.

### 4.1 `.rapid/STATE.json`
- **Role:** Single source of truth for build phase + config. The heartbeat everything keys off.
- **Definition:** `{ project: str, phase: 1–9, phase_name: 'structure'|'intake'|'panels'|'grounding'|'spec'|'tasks'|'build'|'test'|'gap-loop'|'deploy'|…, status: 'active'|'complete'|'blocked', track: 'fast'|'full', note?: str, updated?: date }`. Orchestrator reads it **once at start**, writes it **once per phase end** (no concurrent writes; durable checkpoints). Only hooks/gates write it user-side. Phase advance is gated by R1.
- **Depends on:** read/written by every hook and tool; `--resume` reads it to continue from the incomplete phase.

### 4.2 `.rapid/MEMORY.md`
- **Role:** Append-only prose log of every agent decision/escalation; never truncated.
- **Definition:** free-form timestamped entries. Unknown message types and escalations land here.
- **Depends on:** written by all agents and the debug protocol.

### 4.3 `.rapid/TASKS.json`
- **Role:** Build dependency graph with traceability. Locked after P1/P5.
- **Definition:** `{ phase: int, tasks: [ { id, name, spec_ref:'S-NN'|'ALL', prd_ref:'FR-N'|'ALL', arch_ref?:'C-NN', depends_on:[ids], status:'pending'|'in-progress'|'done', agent_slot?, estimated_lines? } ] }`. `task-00` (eval-harness) is the root: `spec_ref:'ALL'`, `depends_on:[]`, exempt from R8 conformance. All other tasks depend on `task-00`. Supervisor must verify `task-00` is `done` before assigning any other task.
- **Depends on:** generated P5; read by phase-gate (R1, P6 entry), conformance (R8), observatory, ship-gate.

### 4.4 `.rapid/EVAL/`
- **Role:** Immutable eval harness (test files), locked after P5. The contract.
- **Definition:** directory of executable test files generated from `04-spec/workflow.md` (each node → test: arrange from `in`, act from `proc`, assert from `out`; each branch → negative test; each failure path → recovery test). Plus `*.test.sh` runners executed by ship-gate. Agents EXTEND, never EDIT. Existence + file count is checked by R1 (P6 entry) and stop-hook.
- **Depends on:** `04-spec/workflow.md`, `docs/workflows.json` (node `exec` wires to the SAME assertion).

### 4.5 `.rapid/AUDIT.json`
- **Role:** Watchdog drift verdicts. Required for P6 exit.
- **Definition:** `{ pr_id, diff, verdict:'CLEAN'|'DRIFT'|'CRITICAL', categories:[…] }` per PR + per merge + per 30m periodic audit; plus a spec-coverage table written in P7. Drift checked in **7 categories**: structural, interface, invariant (CRITICAL), feature, test, quality, visual.
- **Depends on:** written by watchdog (R2); read by P6 exit assertions and G3.

### 4.6 `.rapid/GAPS.json`
- **Role:** Living quality ledger; input to P8 gap loop and GitHub externalization.
- **Definition:** bare list OR `{gaps:[…]}` (tolerate both). Each: `{ id, type:'stub'|'conformance'|'bug'|'spec'|'arch'|'feature'|'integration'|'optimization', severity:'BLOCKER'|'CRITICAL'|'MAJOR'|'MINOR'|'HIGH'|'MEDIUM'|'LOW', pillar, spec_ref, prd_ref?, file?, line?, marker?, description, source, status:'open'|'resolved'|'closed'|'wontfix', issue?:int, resolution? }`. Dedup by `id`. Conformance gaps `id:GAP-CONF-{tid}`; stub gaps `id:GAP-STUB-{relpath}-L{line}`.
- **Depends on:** written by R8, R9, spec-deepening, panels, P8; read by ship-gate (filters open MAJOR+ stub/conformance) and gaps-to-issues.

### 4.7 `.rapid/COST.json`
- **Role:** Real token burn (from Claude Code transcripts) + per-phase estimate.
- **Definition:** `{ project, rates_usd_per_mtok:{in,out,cr,cw5,cw1}, real:{ sessions, steps:[{n,ts,session,prompt[:70],in,out,cr,cw5,cw1,turns,cost}], by_session:{sid:{…}}, total:{…} }, rapid_estimate:{ by_phase:{Ph:int}, by_agent:{agent:int}, total_ctx_est:int, available:bool } }`. Rates default Opus 4.8 (in $5, out $25, cache-read $0.50, cache-write $6.25–$10 per Mtok), overridable via `OPUS_*` env. Rates are **labeled estimates**, not billed.
- **Depends on:** written by `cost-summary.sh`; circuit-breaker pauses at 80% budget.

### 4.8 `.rapid/P6_EXIT.json`
- **Role:** Blocking P6→P7 ship-gate assertions.
- **Definition:** bare list OR `{assertions:[…]}` of `{ name, pass:bool, detail }`. The 4 canonical assertions: `verification_real` (e2e green), `no_open_stub_gaps`, `no_stubs_in_tree`, `no_open_conformance_gaps`. R1 refuses STATE→phase 7 while ANY `pass==false`.
- **Depends on:** written by `ship-gate.sh`; read by R1 and stop-hook.

### 4.9 `.rapid/VERIFY.json` + `.rapid/verify.cmds.json`
- **Role:** Genuine per-layer verification report + its command config.
- **Definition:** `verify.cmds.json` = `{ build, lint, unit, e2e, waive:[layers] }` (stub written on first run). `VERIFY.json` = `{ generated, ok:bool, layers:[{ name:'build'|'lint'|'unit'|'e2e', status:'pass'|'fail'|'unrun'|'waived', exit:int|null, required:bool, cmd, log }] }`. Output redirected to `.rapid/verify-<layer>.log` (never piped). e2e required unless explicitly waived; unrun/empty blocks unless waived.
- **Depends on:** written by `verify.sh`; read by ship-gate.

### 4.10 `.rapid/DECISIONS.json`
- **Role:** Append-only audit of PRD-silent in-build decisions.
- **Definition:** `[{ id:'D<N>', ts:ISO, phase, decision, basis:'spec'|'interpretation', by:role }]`. `spec`=PRD-fact; `interpretation`=PRD-silent builder call. Atomic write (tmp→replace); next id = max suffix + 1.
- **Depends on:** written by `log-decision.sh` (only inside an active build).

### 4.11 `.rapid/PREFLIGHT.json` + `.rapid/preflight.json`
- **Role:** Declared-stack runtime probe; P1 blocker.
- **Definition:** `preflight.json` (config) = `{ tools:[{ name, check?:cmd (default `command -v name`), install?:cmd, required?:bool(default true) }] }`. `PREFLIGHT.json` (result) = `{ generated, ok:bool, tools:[{ name, status:'present'|'installed'|'missing'|'malformed', required, installed, check, install, check_exit, log }] }`. Genuine exit codes (output → `.rapid/preflight-<safe>.check.log`).
- **Depends on:** written by `preflight.sh`; STATE cannot leave P1 unless green. Never route around missing runtime.

### 4.12 `.rapid/HEARTBEAT.json`
- **Role:** Liveness per build lead.
- **Definition:** `{ <role>:{ task, status, last_heartbeat, files_written, tests_passing/failing, blocked_on } }`. Each lead updates own entry every ≤5m (read→update own→write). Stale >10m = STALLED → orchestrator nudges via claude-peers.
- **Depends on:** P6 leads; read by orchestrator P6d.

### 4.13 `.rapid/REVIEW.json`
- **Role:** Per-dimension review verdicts + synthesized verdict.
- **Definition:** `[{ reviewer_type, verdict:'APPROVE'|'REQUEST_CHANGES', confidence:'HIGH'|'MEDIUM'|'LOW', findings }]` plus a merged verdict. Synthesis: dedup overlapping findings, higher-confidence wins contradictions; APPROVE iff all approve or only LOW-confidence objections; any HIGH-confidence objection → REQUEST_CHANGES.
- **Depends on:** written by reviewer lead (P6).

### 4.14 `.rapid/CONFORMANCE.md`
- **Role:** Append-only traceability ledger.
- **Definition:** markdown table `| Time | Phase | Task | spec_ref | prd_ref | arch_ref | Status | Note |`; one row per completed task; Status ∈ `TRACEABLE`|`MISSING_SPEC`|`MISSING_PRD`|`MISSING_ARCH`|`ORPHAN`.
- **Depends on:** written by R8.

### 4.15 `.rapid/STUBS.md`
- **Role:** Append-only stub ledger.
- **Definition:** markdown table `| Location | Marker | Text | Status |`.
- **Depends on:** written by R9.

### 4.16 `.rapid/LEARNINGS.md`
- **Role:** Reusable insights captured at P6e, injected at next build's P0.
- **Definition:** `L-NN [title]`, `Context:`, `Learning:`, `Evidence:` (file/test/review), `Reuse:` (when to apply), `status:` (active|stale). P0 compound-refresh marks stale entries (referenced files/patterns gone). P6b learnings-researcher reads it before debug.
- **Depends on:** written P6e; read P0 + P6b.

### 4.17 `.rapid/OPTIMIZE.json`
- **Role:** P8 optimization experiment results.
- **Definition:** `{ goal, experiments:[{ approach, result_metric, kept:bool }] }`. ≤3 parallel worktree experiments, measured vs goal, keep best.

### 4.18 `.rapid/MESSAGES.json`
- **Role:** Durable fallback for claude-peers messages.
- **Definition:** `[{ type, ts, from, to, payload }]` — every send/recv also appended here (fallback if claude-peers missed).

### 4.19 `.rapid/RETRO.md`
- **Role:** Post-ship reflection (P9).
- **Definition:** `{ what_worked, what_drifted, gap_loop_caught, total_tokens, time_breakdown }` as prose.

### 4.20 `.rapid/DEEPENING.md`
- **Role:** P5b confidence/completeness findings → blocking G2 questions.
- **Definition:** `[{ section, confidence:'HIGH'|'MEDIUM'|'LOW', gaps, missing_flows }]`. Any LOW-confidence or missing flow = blocking question at G2.

### 4.21 `.rapid/WALKTHROUGH.md`
- **Role:** Concrete P7 walkthrough covering every workflow surface.
- **Definition:** `[{ surface_id, screenshot_path, pass_fail, error_description }]`. R1 blocks P8 entry unless this exists and covers every surface in `workflow.md`.

### 4.22 `.rapid/DOGFOOD.md` / `.rapid/SIMPLIFY.md`
- **Role:** P7 autonomous QA fixes / simplifications.
- **Definition:** DOGFOOD `[{ surface_id, auto_fix_commit_hash, iteration_count }]` (max 3 iter/surface). SIMPLIFY `[{ finding, applied:bool, reason }]`.

### 4.23 `.rapid/observe/<role>.jsonl` + `.rapid/observe/seq.txt`
- **Role:** Per-agent event stream feeding the Observatory; the live-surface data source.
- **Definition:** append-only JSONL, one event/line: `{ t:ISO, seq:int(monotonic, from seq.txt pre-increment), agent, role:'leader'|'subagent', event, detail, target?, from?, ctx_est?, ctx_total?, task?, phase }`. **Fixed event vocabulary:** `SPAWN, PHASE, GATE, READ, WRITE, TOOL, SEND, RECV, DECIDE, ESCALATE, LOOP_START, LOOP_ITER, LOOP_END, STOP, CONTEXT, COMPLETE, ERROR`. Per-role file (role from `RAPID_ROLE` env). `seq.txt` is the global counter. Append-only is the contract; never truncate mid-run.
- **Depends on:** written by every hook + agent; read by `observe-server.py`.

### 4.24 `.rapid/RUNS/<wf>/<run>.jsonl` + `.rapid/RUNS/<wf>/index.json`
- **Role:** Recorded workflow runs (P7 S-14) feeding Test Theater replay.
- **Definition:** `<run>.jsonl` lines `{ seq, type:'run_start'|'node_start'|'node_done'|'run_done', wf, run_id, t, node_id?, label?, status?, elapsed_s?, data_in?, data_out?, verdict? }`. `index.json` = `[{ run_id, started, finished, status, pass, fail, info, total, golden, input }]` (latest 200 per wf).
- **Depends on:** written by `workflow-runner.py`; published to `docs/testruns.json`.

### 4.25 `.rapid/E2E.json`
- **Role:** End-to-end acceptance report.
- **Definition:** `{ generated, project, project_dir, deploy_out, summary:{pass,fail,total:3}, assertions:[{name,pass,detail}] }`. 3 assertions: `documentation_populated`, `local_app_built`, `dev_deployed`.
- **Depends on:** written by `lifecycle-e2e.sh --stage verify`.

### 4.26 `.rapid/.stop_count`, `.rapid/.stop_phase`, `.rapid/.conformance_seen`
- **Role:** Hook bookkeeping.
- **Definition:** `.stop_count` = int stops in current phase (cap MAX=5); `.stop_phase` = last phase tracked (reset count on change); `.conformance_seen` = newline-delimited task IDs already R8-checked (dedup).

### 4.27 `.rapid/prompts/<role>.md`, `.rapid/worktrees/coder-N`
- **Role:** Per-build role briefs and isolated coder worktrees.
- **Definition:** prompt files written by planner (contract + build-specific paths + Decision Router D5 + observability + heartbeat + reference-project protocol + claude-peers format). Worktrees when coder runs as N terminals.

---

## 5. `tools/` — hooks (mechanical enforcement)

> **Universal hook contract:** Claude Code invokes each hook with the event JSON on **stdin** (NOT env vars). Read it with `python3 -c 'import sys,json; d=json.load(sys.stdin)'`. There is no `jq` fallback (if python3 missing, fail gracefully `exit 0`). Every hook **no-ops instantly if `.rapid/STATE.json` is absent**. Fail SAFE: no `set -e`, guard every read with `|| true`. Hooks are registered in `~/.claude/settings.json` by `install-hooks.sh` and also runnable standalone.

### 5.1 `tools/phase-gate-hook.sh` (R1 — phase gate)
- **Role:** Blocks STATE.json phase transitions when required prior-phase artifacts are missing.
- **Definition:** **Event:** `PreToolUse`. **Matcher:** `Write|Edit`. **Synchronous** (must block). Reads stdin JSON; detect a write to `.rapid/STATE.json`; extract the new `phase`. Required-artifact map (the gate condition): P2 requires `01-intake/PRD-ENHANCED.md`; P4 requires `03-panels/synthesis.md`; P5 requires `04-spec/spec.md`; P6 requires `.rapid/EVAL/` with ≥1 test file **and** `.rapid/TASKS.json` (with `task-00` done); P7 requires `.rapid/P6_EXIT.json` with 0 failing assertions; P8 requires `.rapid/WALKTHROUGH.md`. **Block:** if the target phase's required artifact is missing, **exit 2** with the missing-artifact name on **stderr** (this is the only hook that uses exit 2). **Escape hatch / pass:** if no STATE.json write detected, or artifacts present, **exit 0** (no-op). Note: the gate blocks the *write*, not the phase concept — if the agent regenerates the artifact and re-writes STATE, it passes. P6_EXIT check is defensive: missing/malformed file allows advance (assertion generation is ship-gate's job).
- **Depends on:** `.rapid/STATE.json`, the named artifacts, `.rapid/P6_EXIT.json`, `.rapid/EVAL/`, `.rapid/TASKS.json`.

### 5.2 `tools/stop-hook.sh` (R7 — continuation)
- **Role:** Logs every termination; nudges continuation while phase work remains; never traps a session.
- **Definition:** **Event:** `Stop` and `SubagentStop`. **No matcher. Synchronous** (no async flag). Reads stdin: `hook_event_name`, `stop_hook_active` (truthy values `True|true|1`), `agent_type` (default `orchestrator`; prefer `RAPID_ROLE` env). Extract current phase from STATE.json. Logic: (1) **Always** append a `STOP` event to `.rapid/observe/<role>.jsonl` (halt is never silent). (2) If `stop_hook_active` truthy → **exit 0** (never block twice — the critical loop guard). (3) If `SubagentStop` → log only, **exit 0** (parent owns the gate; a fan-out worker can't map to an artifact). (4) If `Stop`: check the current phase's completion artifact (same map as R1). If present → log STOP, **exit 0** (allow). If missing → increment `.rapid/.stop_count` (reset on phase change via `.rapid/.stop_phase`); if count ≥ **MAX=5** → log `ESCALATE`, allow stop (escalate to operator instead of re-nudging); else log `LOOP_ITER` and emit to **stdout** `{"decision":"block","reason":"P${PHASE} incomplete: ${missing} missing. Next step: ${nextstep}..."}` then **exit 0** (the JSON surfaces the reason and requests continuation; informational block, not a hard exit-code block).
- **Depends on:** `.rapid/STATE.json`, artifact map, `.rapid/observe/`, `.stop_count`/`.stop_phase`.

### 5.3 `tools/module-conformance-hook.sh` (R8 — conformance)
- **Role:** On task completion, verify each module's refs resolve to real spec/PRD/arch anchors; file orphans as gaps.
- **Definition:** **Event:** `PostToolUse`. **Matcher:** `Write|Edit`. **Async.** Guard hard: exit 0 unless both `.rapid/STATE.json` and `.rapid/TASKS.json` exist AND the write targeted `.rapid/TASKS.json`. For each task with `status ∈ {done,complete,completed,passed,merged}` not already in `.rapid/.conformance_seen`: extract `spec_ref`,`prd_ref`,`arch_ref?`. `anchor_present(doc,ref)` = literal OR normalized (`S-01` or `§S-01`) substring match anywhere in the file. **Exempt:** `spec_ref=="ALL"` (eval-harness root). If any required ref missing/unanchored → mark `ORPHAN`, append `.rapid/GAPS.json` entry `{id:GAP-CONF-{tid}, type:conformance, severity:MAJOR, pillar:'Spec Compliance', spec_ref, task, description, source:'module-conformance-hook (R8)', status:open}`; else mark TRACEABLE. Append a row to `.rapid/CONFORMANCE.md`. Record the task id in `.conformance_seen` (dedup). Log `CONFORMANCE` event with detail `checked N module(s); M orphan(s)`. **Non-blocking** (gaps flow to P8). Always **exit 0**.
- **Depends on:** `.rapid/TASKS.json`, `04-spec/spec.md`, `01-intake/PRD-ENHANCED.md`, `04-spec/architecture.md`, `.rapid/GAPS.json`, `.rapid/CONFORMANCE.md`, `.conformance_seen`.

### 5.4 `tools/stub-detect-hook.sh` (R9 — stub scan at write)
- **Role:** Detect incomplete code at write time; file stubs to the gap loop (non-blocking).
- **Definition:** **Event:** `PostToolUse`. **Matcher:** `Write|Edit`. **Async.** Guard on STATE.json. Extract `file_path` from stdin. Call `stub-scan.sh <file>`; if it exits 3 (stubs found), parse JSONL findings `{file,line,marker,text}`. For each: `relpath` via realpath normalization on both sides (symlink-stable; fall back to raw path if realpath fails); `id='GAP-STUB-{relpath}-L{line}'`; append `.rapid/GAPS.json` `{id, type:stub, severity:MAJOR, pillar:'Build Quality', spec_ref:null, file:relpath, line, marker, description, source:'stub-detect-hook (R9)', status:open}` (dedup by id); append a row to `.rapid/STUBS.md`; log `STUB` event `N new stub(s) in file`. **Always exit 0** (non-blocking by design — too noisy to block at write; enforced at ship gate).
- **Depends on:** `stub-scan.sh`, `.rapid/GAPS.json`, `.rapid/STUBS.md`.

### 5.5 `tools/stub-scan.sh` (R9 utility — shared scanner)
- **Role:** The stub detector used by the write hook AND the ship gate.
- **Definition:** CLI: `stub-scan.sh <file>` (single) or `stub-scan.sh --tree [dir]`. Only scans source files (regex of extensions: `ts|tsx|js|jsx|mjs|cjs|py|go|rs|java|rb|php|c|cc|cpp|h|hpp|cs|swift|kt|kts|scala|sh`). Markers (extended regex): `TODO|FIXME|XXX|HACK|NotImplementedError|NotImplemented|raise.*NotImplemented|not.*implemented|unimplemented|@stub|@placeholder|lorem.*ipsum|throw new Error(.*not implemented|stub`. **Exempt** any line containing `rapid:allow-stub` (documented intentional stub). Bare `placeholder` is intentionally NOT a marker (React `placeholder=` false positives). Output JSONL per matching line `{file,line,marker,text[:160]}`. Single file: exit **3** if stubs found else 0. Tree: exit **3** if any found else 0.
- **Depends on:** none (pure).

### 5.6 `tools/post-write-hook.sh`
- **Role:** Refresh derived docs and maintain the `CHANGES.md` audit trail on writes.
- **Definition:** **Event:** `PostToolUse`. **Matcher:** `Write|Edit`. **Async.** Guard on STATE.json. On a STATE.json write: call `build-docs-registry.sh` (refresh `docs.json`); if `docs/cost.html` exists, call `cost-summary.sh --html`. On writes to numbered folders (regex `[0-9]{2}-[^/]+`), `decisions/`, `panels/`, or `tests/`: ensure `CHANGES.md` (with header) then append `| timestamp | phase | relative_path | Write/Edit |` (relpath via `os.path.relpath` against cwd). **Always exit 0.**
- **Depends on:** `build-docs-registry.sh`, `cost-summary.sh`, `CHANGES.md`, `docs.json`.

### 5.7 `tools/install-hooks.sh`
- **Role:** Idempotently wire all hooks into the global Claude Code `settings.json`; portable across machines.
- **Definition:** Symlink `$TOOLS_DIR → $HOME/.claude/hooks/rapid-workflow`. Back up `settings.json`. Use Python to strip prior Rapid entries (the set: `stop-hook.sh, module-conformance-hook.sh, phase-gate-hook.sh, post-write-hook.sh, stub-detect-hook.sh`) from `hooks.{Stop,SubagentStop,PreToolUse,PostToolUse}`, then re-add canonical entries: **Stop** (sync, no matcher) → stop-hook; **SubagentStop** (sync, no matcher) → stop-hook; **PreToolUse** (`Write|Edit`, sync) → phase-gate-hook; **PostToolUse** (`Write|Edit`, async) → post-write-hook, module-conformance-hook, stub-detect-hook. Each entry `{type:'command', command:'bash $HOME/.claude/hooks/rapid-workflow/<script>', [async:true]}`. Validate JSON after write. Idempotent (strip-then-add, no duplicates).
- **Depends on:** the five hook scripts; `~/.claude/settings.json`.

---

## 6. `tools/` — operational tooling

### 6.1 `tools/preflight.sh`
- **Role:** P1 gate — probe declared runtimes, install missing, hard-fail if any required absent.
- **Definition:** Run from project root. Read `.rapid/preflight.json` (write stub if absent). For each tool: run `check` (default `command -v name`) with output redirected to `.rapid/preflight-<safe>.check.log` (genuine exit). present(0)→`present`; absent+install→attempt then re-check→`installed` or `missing`. Report `[PRESENT|INSTALLED|MISSING|MALFORMED]`. Write `.rapid/PREFLIGHT.json`. **Exit 3** (block) if any required tool missing/malformed after install attempts. `pipefail` set; never pipe.
- **Depends on:** `.rapid/preflight.json` → `.rapid/PREFLIGHT.json`.

### 6.2 `tools/new-project.sh`
- **Role:** Deterministic P1 scaffold — create a self-contained project.
- **Definition:** `new-project.sh --name <name> [--dir <parent>] [--prd <file>|--idea <one-liner>] [--force]`. Refuse non-empty target unless `--force`. Create `<parent>/<name>/` with: `00-vision, 01-intake, 02-grounding, 03-panels, 04-spec/{agents,contracts}, 05-gaps, audits, decisions, panels, tests, docs, src, .rapid`. Copy `01-intake/PRD.md` from `--prd` or generate minimal one from `--idea` (default: unit-converter boilerplate). Empty `01-intake/DIFF.md`. Seed `CONSTITUTION.md` (from kit or default). Seed `BUILD-AUTONOMY.md` from `templates/`. Write `.rapid/STATE.json {project, phase:1, phase_name:'structure', status:'complete', track:'fast'}`. Copy `tools/` + `templates/` into the project (self-contained). Call `atlas-init.sh` then `build-docs-registry.sh`. Print project path on last line. Idempotent with `--force`.
- **Depends on:** `atlas-init.sh`, `build-docs-registry.sh`, `templates/`.

### 6.3 `tools/verify.sh`
- **Role:** Genuine build/lint/unit/e2e verification with authentic exit codes.
- **Definition:** Read `.rapid/verify.cmds.json` (write stub if absent). For each of 4 layers, run the declared command via bash with output **redirected** to `.rapid/verify-<layer>.log` (so `$?` is real). Mark pass/fail/unrun/waived + exit code + log path. Write `.rapid/VERIFY.json`. e2e required to ship; layers may be waived. **Exit 0 only if all required layers green.** `set -o pipefail`; no pipe masking.
- **Depends on:** `.rapid/verify.cmds.json` → `.rapid/VERIFY.json`.

### 6.4 `tools/ship-gate.sh`
- **Role:** P6→P7 blocking gate.
- **Definition:** Read `.rapid/GAPS.json` (filter open MAJOR+ of type stub/conformance), run live `stub-scan.sh --tree`, evaluate `.rapid/VERIFY.json`, execute `.rapid/EVAL/*.test.sh`. Merge 4 assertions (`verification_real`, `no_open_stub_gaps`, `no_stubs_in_tree`, `no_open_conformance_gaps`) into `.rapid/P6_EXIT.json` (replace same-named). Publish `docs/eval.json` `{generated, summary:{pass,fail,total}, assertions:[…], harness:[{name,pass,output}]}`. **Exit 0** if all pass else **3**.
- **Depends on:** `.rapid/GAPS.json`, `stub-scan.sh`, `.rapid/VERIFY.json`, `.rapid/EVAL/`, → `.rapid/P6_EXIT.json`, `docs/eval.json`.

### 6.5 `tools/cost-summary.sh`
- **Role:** Token + cost monitor; renders `docs/cost.html`.
- **Definition:** `cost-summary.sh [/path/to/proj] [--json|--html[=path]]`. Read `~/.claude/projects/<encoded-cwd>/*.jsonl`; extract real user prompts (`type=user`, not tool_result, not sidechain) → steps; accumulate per-step tokens (in/out/cache_read/cache_write_5m/1h). Cost = tokens × rate table (Opus 4.8, `OPUS_*` overridable). Also scan `.rapid/observe/*.jsonl` for `ctx_est` → rapid estimate. Write `.rapid/COST.json`. `--html` renders styled static page at `docs/cost.html` (overview cards + per-step + per-session + per-phase rapid estimate). Footer: "Generated by tools/cost-summary.sh --html — regenerate to refresh." Rates labeled (estimates, not billed).
- **Depends on:** Claude Code transcripts, `.rapid/observe/`, → `.rapid/COST.json`, `docs/cost.html`.

### 6.6 `tools/observe-server.py`
- **Role:** Live Observatory + Test Theater backend; HTTP on `127.0.0.1:4040`.
- **Definition:** `cd <project-root> && python3 tools/observe-server.py [--port 4040]`. No auth; bind 127.0.0.1. Routes: `/` → `docs/observatory.html`; `/api/events` (merge all `.rapid/observe/*.jsonl`, sort by `(t,seq)`, `since_seq` filter); `/api/agents` (per-agent summary: last event/detail/time, ctx_est, event counts by type, status active/complete/error); `/api/meta` (phase, total_events, active_agents, ctx_total_est, eval status from `P6_EXIT.json`, docs status from `docs.json`); `/api/runs` (WF list); `/api/run?wf=X&run=Y` (live-tail a run jsonl); `POST /api/regen?page=X` (look up `docs/regen.json`, run the registered command in background — user input never becomes a command); `POST /api/run?wf=X` (spawn `workflow-runner.py` in background). Serve static `.rapid/RUNS/*.jsonl`, `docs/*.html`, `docs.json` read-only (no project-root exposure).
- **Depends on:** `.rapid/observe/`, `.rapid/RUNS/`, `docs/regen.json`, `workflow-runner.py`, `docs/observatory.html`.

### 6.7 `tools/workflow-runner.py`
- **Role:** Live-drive a user workflow as an executable test; stream to `.rapid/RUNS/`; the Test Theater engine.
- **Definition:** `workflow-runner.py --wf WF-1 [--preset id] [--input '{...}'] [--agents auto|on|off] | --all | --publish-only`. Read `docs/workflows.json`, execute nodes in sequence, thread `data-out → next data-in`. Exec kinds: `note` (info), `file` (exists/lines/grep), `glob` (pattern), `read_json` (dotted path), `cmd` (bash -c, compare exit, optional `then_read` JSON), `codex` (tester persona + verify schema OR operator persona + gate-decision schema; read-only/workspace-write sandbox; JSON schema required), `human` (operator persona, FAIL-SAFE default hold). **Every agent node carries a deterministic fallback** that completes offline (no `pending` states). Stream `.rapid/RUNS/<wf>/<run>.jsonl` (`run_start, node_start, node_done` with elapsed_s/data_in/out/verdict, `run_done`); append `index.json`; publish `docs/testruns.json` (latest snapshot per wf, max 25 runs). `--publish-only` rebuilds the static snapshot. **Bounds:** `CMD_TIMEOUT=180s`, `CODEX_TIMEOUT=300s` (hard; timeout → `{status:fail, evidence:timeout}`, run continues). Default `--agents off` (deterministic republish); agent nodes execute only on explicit run with `--agents auto`.
- **Depends on:** `docs/workflows.json` → `.rapid/RUNS/`, `docs/testruns.json`.

### 6.8 `tools/rapid-team.sh`
- **Role:** Launch the persistent 5-lead P6 build team over tmux + claude-peers.
- **Definition:** `rapid-team.sh [--track fast|full] [--dry-run|--cursor|--demo] [/path/to/proj]`. Run from project root (or pass path); verify `.rapid/STATE.json`. fast = planner, coder, reviewer, watchdog; full = + tester. Ensure `04-spec/agents/<role>.md` (seed from `templates/agent-roles/<role>.md` if missing). `--dry-run` prints commands; `--cursor` writes `.vscode/tasks.json` (one terminal per role, auto-launch on folder open); `--demo` placeholder terminals. Default (tmux): session `rapid-team`, one window per role, each exports `RAPID_ROLE=<role>` (hooks/observe/messages attribute per role), sends kickoff prompt (read brief → `claude-peers set_summary`/`list_peers` → begin). Role missions: planner (plan, decompose, gates), coder (implement, fan-out, keep-or-revert), tester (eval harness, per-surface tests), reviewer (per-dimension review), watchdog (R2 audit, write AUDIT.json).
- **Depends on:** `.rapid/STATE.json`, `04-spec/agents/`, `templates/agent-roles/`.

### 6.9 `tools/build-docs-registry.sh`
- **Role:** Scan filesystem and regenerate `docs.json`.
- **Definition:** Run from project root. Scan `docs/*.{html,md}`, `tools/*.{html,py,sh}`, `templates/*.html`, `skills/*/SKILL.md`. Load existing `docs.json` (preserve metadata/status/descriptions/categories). For each file: in old_docs → status=current; in old_archive → restore current; else new entry `generated:true`. Infer title (`SKILL.md`→`<dir> Skill`, else `stem.replace('-',' ').title()`) and category (`template|skill|rapid|workflow`) from path. Bump `version` (n→n+1), update timestamp. Missing files → archive `status:missing`. Write `docs.json v{N}` = `{version, updated, generated_by, categories{}, docs[], archive[]}`. Idempotent (running twice identical except version bump).
- **Depends on:** filesystem → `docs.json`.

### 6.10 `tools/populate-deck.py`
- **Role:** Deterministically fill a project's Atlas deck pages from its OWN artifacts (no LLM).
- **Definition:** `PROJECT=<proj> python3 populate-deck.py` (or arg 1 or cwd). **Hard-guard:** refuse the kit root (presence of `skills/rapid-workflow/SKILL.md`). For each page (`prd, prd-enhanced, spec, architecture, workflow, users, eval, documentation, observatory`): render project markdown/JSON → HTML sections, replace the page's `<div class="main">` inner HTML, rebuild the in-page sidebar TOC from sections (kill stale `#pending` stub). `md_to_sections()` parses `# title` / `## sections` → `<div class="section" id="slug">…`. `eval_sections()` reads `docs/eval.json`; `documentation_sections()` reads `docs.json`; `observatory_sections()` reads `.rapid/STATE.json`. Run 9 populate jobs; **exit 1** if any still stubbed. Deterministic (same input → byte-identical output). Always re-runnable.
- **Depends on:** project markdown, `docs/eval.json`, `docs.json`, `.rapid/STATE.json`, deck pages.

### 6.11 `tools/apply-docs-sidebar.py`
- **Role:** Apply the standard docs layout (top rapid-nav + left `.sidebar` + `.main`) to an arbitrary doc page.
- **Definition:** `apply-docs-sidebar.py docs/<page>.html --title <Title>` — wrap a page in `templates/template-docs-page.html` structure (nav + sidebar + main), ensuring it loads `env-links.js` then `sidebar.js`.
- **Depends on:** `templates/template-docs-page.html`.

### 6.12 `tools/atlas-init.sh`
- **Role:** Scaffold the per-project Atlas developer-view deck (P1, R-10).
- **Definition:** Generate a 10-page nav harness (`prd, prd-enhanced, architecture, workflow, users, spec, observatory, eval, cost, documentation`). Write the single wiring file `docs/env.json`; copy harness assets (`env-links.js`, `sidebar.js`, `home.html`) into `docs/` from `templates/`; write `docs/regen.json` (per-page regen commands); drop `.vscode` config; write stub pages. Atlas content is the **PROJECT's own** (vision, PRD, spec, architecture, users, tests, deploys), never the workflow's. **Invariant:** every emitted HTML page must load `env-links.js` then `sidebar.js`.
- **Depends on:** templates → `docs/env.json`, `docs/env-links.js`, `docs/sidebar.js`, `docs/home.html`, `docs/regen.json`, stub pages.

### 6.13 `tools/atlas-deploy.sh`
- **Role:** Deploy the Atlas static deck alongside the product at `/_atlas` (P9); verify harness scripts shipped.
- **Definition:** `atlas-deploy.sh --out <deploy_dir> --url <product_url>`. Fold the static deck (PRD/spec/arch/eval/… pages) into `<deploy_dir>/_atlas`. Write resolved `atlas.url` (dev/prod) to `docs/env.json`. **TWO-HALVES RULE:** the static deck deploys with the product; the **live-view half** (Observatory, Cost, regen, Test Theater live ▶Run) stays LOCAL under `observe-server`, never public. Verify `env-links.js` + `sidebar.js` are present and current in the deploy (no orphan HTML without both scripts).
- **Depends on:** `docs/`, `docs/env.json`.

### 6.14 `tools/gaps-to-issues.sh`
- **Role:** Externalize `.rapid/GAPS.json` to GitHub issues (dry-run / push).
- **Definition:** `gaps-to-issues.sh [--push]`. No `--push` = DRY RUN (print). With `--push` = create/close via `gh`. Open gaps without an issue number → create (labels `rapid:gap`, `sev:<severity>`, `type:<type>`; title `[<type>] <id>: <description>[:80]`; body file:line + full description). Resolved/closed gaps with an issue number → `gh issue close` with comment. Record created issue numbers back into GAPS.json. Idempotent. Requires `gh` auth. Not automatic (operator/loop-triggered; avoids tracker spam).
- **Depends on:** `.rapid/GAPS.json`, `gh`.

### 6.15 `tools/log-decision.sh`
- **Role:** Log PRD-silent in-build decisions to the audit trail.
- **Definition:** `log-decision.sh "<decision text>" {spec|interpretation}`. Run only inside a build (check `.rapid/STATE.json`, else exit 2). Append `.rapid/DECISIONS.json` `{id:'D<N>', ts:ISO, phase:from STATE, decision, basis, by:RAPID_ROLE or 'build'}`. Next id = max numeric suffix + 1 (robust to gaps). Atomic (tmp→replace). Won't overwrite corrupt JSON.
- **Depends on:** `.rapid/STATE.json`, `.rapid/DECISIONS.json`.

### 6.16 `tools/lifecycle-e2e.sh`
- **Role:** End-to-end acceptance test of the whole kit (scaffold → build → docs → deploy → verify).
- **Definition:** `lifecycle-e2e.sh --stage {create|build|docs|deploy|verify|all} --name <name> [--dir <parent>] [--deploy-out <dir>]`. Each stage **exits 1 on failure** (honest CI). create: `new-project.sh` → scaffolds project + CONSTITUTION + BUILD-AUTONOMY + `.rapid/STATE` + tools + Atlas. build: seed a real tiny app (Makefile, `src/*`, `.rapid/EVAL/build.smoke.test.sh`), run `make build`, assert `dist/index.html` + `dist/app.js`. docs: seed real PRD-ENHANCED/spec/architecture/workflow/users markdown, run ship-gate/build-docs-registry/cost-summary/populate-deck, assert 9 pages populated (no atlas-stub), distinct (prd≠prd-enhanced, workflow≠users), branded with project name, no dead `#pending`. deploy: copy `dist`→`/DEPLOY_OUT`, run atlas-deploy to stage `/_atlas`, assert `env.json dev.url` set. verify: re-check all 3 assertions, write `.rapid/E2E.json`. Final: any failed stage → exit 1.
- **Depends on:** `new-project.sh`, `ship-gate.sh`, `build-docs-registry.sh`, `cost-summary.sh`, `populate-deck.py`, `atlas-deploy.sh` → `.rapid/E2E.json`.

---

## 7. `skills/` — the orchestrator + supporting skills (source of truth, symlinked into `~/.claude/skills/`)

### 7.1 `skills/rapid-workflow/SKILL.md` (the orchestrator — Rapid's core, ~1280 lines)
- **Role:** The single skill that runs the entire 12-phase / 4-gate pipeline; the entrypoint `/rapid-workflow` (and `/workflow` alias). The methodology IS this file plus the hooks/tools it drives.
- **Definition — the sections this file MUST contain, in order:**
  1. **Invocation & flags:** `/rapid-workflow "<idea or PRD>"`, `/rapid-workflow --resume` (read STATE.json, continue incomplete phase), `/rapid-workflow --gap-loop` (re-enter P8 from GAPS.json), `/rapid-workflow pulse [--window 24h|7d|30d]`, `--track fast|full`.
  2. **Core principle: Builder ≠ Auditor** (structural enforcement, the full enforcement list: R1 phase-gate, R2 auto watchdog, R4 task-00 blocking, R7 stop-hook, task deps as blockers, tiered reviewers as subagents).
  3. **Deterministic-vs-Dynamic split table** (encode verbatim — DETERMINISTIC: 12 phases in order, 4 gates at fixed positions, 12-message contract + JSON envelope, keep-or-revert, immutable eval harness, cost breaker, shutdown handshake, fixed stop-condition set. DYNAMIC: panels 1–3, reviewer weights by domain, debug protocol by stack, optimization vs pillars, 3–5 pillars, spec sections/contracts, task count 1–4 impl, test cases from workflow state machine, doc-review criteria from pillars. Dynamic pulls from existing frameworks; never invent protocols at runtime).
  4. **The 12 phases in order**, each with its purpose, the sub-steps from the table above, and the **exit artifact(s)** that R1 enforces. Include: P0 vision + compound-refresh of LEARNINGS; P1 structure + preflight (block until PREFLIGHT green) + Atlas scaffold; P1b decomposition; P2 panels (1 fast / 3 full, review through pillars, synthesis with convergent/divergent/risks/sources); P3 grounding (VERIFIED/UNVERIFIED/OPEN classification, 15m timebox, 3+ options + trade-off matrix + evidence + fallback + verification); P4 spec derivation (every req tagged `[FROM PRD §X]`/`[DERIVED]`/`[OPEN]`, references a pillar; emit workflow.md + docs/workflows.json wired to same assertions as the harness; CONTRACTS.md; inter-stage assertion every PRD req → spec or `[OUT OF SCOPE]`); P5 task decomposition + immutable eval harness as task-00 + role files + CI config + P5 inter-stage assertions; P5b deepening; P6 five-lead build (full sub-protocol P6a–P6e below); P7 test + visual QA + walkthrough + recorded runs; P8 gap loop + optimization; P9 deploy + document + Atlas deploy; P10 pulse.
  5. **The 4 gates** (G0/G1/G2/G3) with their doc-review pre-screens, what is presented, what the operator approves, redirect behavior. Gates use `AskUserQuestion`; no operator response → build halts (by design). Standing authorization charter at G1.
  6. **P6 detailed sub-protocol:** P6a-gate (pin every seam in `04-spec/contracts/{api,dom,events,schema,e2e}.md` before fan-out; these supersede abstract CONTRACTS.md; e2e derives from seam contracts; R8 traces to seam contract). P6b (supervisor delegates: task assignment with `isolation:worktree`, commit `[SPEC §X.Y]`, branch `rapid/phase-6/{task-slug}`; keep-or-revert after each commit; mandatory smoke test; tiered 3–5 (fast) / up to 9 (full) reviewer subagents → single APPROVE/REJECT to REVIEW.json; watchdog coordination via messages; learnings-researcher checks LEARNINGS.md before debug; structured debug protocol; stall detection; cost tracking; completion). P6c (watchdog: drift on PR_SUBMITTED diff, on PR_MERGED integrated main, /loop 30m full audit, CRITICAL → immediate DRIFT_CRITICAL; write AUDIT.json; never check in-progress worktrees). P6d (orchestrator: liveness `list_peers` every 5m + re-spawn missing watchdog, HEARTBEAT >10m stale flag, message listen, cost BUILD_HALT). P6e (shutdown handshake: SHUTDOWN → ACK_SHUTDOWN → 60s timeout → tmux kill; capture LEARNINGS.md; kill session). **P6 exit assertions** (blocking, write P6_EXIT.json via ship-gate): every spec section has code, every CONTRACTS interface exists, architecture matches repo, external APIs verified by calling, every task APPROVE, smoke passed, secret scan passed, ship-gate merged assertions pass.
  7. **The 12-message contract + JSON envelope:** `{type, from, ts, payload}`; the 12 types `TASK_ASSIGNED, TASK_COMPLETE, PR_SUBMITTED, PR_MERGED, DRIFT_RESULT, DRIFT_CRITICAL, AUDIT_PERIODIC, STALL_NUDGE, BUILD_HALT, P6_COMPLETE, SHUTDOWN, ACK_SHUTDOWN`. Every send emits observe SEND, every recv RECV; durability fallback to `.rapid/MESSAGES.json`; unknown types logged to MEMORY.md (forward-compat).
  8. **Five-lead team + cadences** (FULL=5, FAST=4 fold tester, TINY=subagents). Role definitions, topology (planner⟷coder⟷tester⟷reviewer loop, watchdog observes all), Writer≠Auditor as structural law, subagents=parallel muscle / terminals=coordination spine. Context tuned for Opus 4.8 1M (planner holds full spec + TASKS.json resident).
  9. **Reviewer tiers** (5–9 dimensions: Correctness, Spec Compliance, Security, Performance, Maintainability + optional API Contract, Reliability, Pattern Recognition, Standards), each verdict + HIGH/MEDIUM/LOW confidence; dedup/synthesis; weights shift by domain.
  10. **Panel selection + synthesis** (1st-order 3 panels default: Business/Technical/SME; 2nd-order escalation rule: internal disagreement on load-bearing + irreversible + stakes-threshold).
  11. **Debug protocol** (Reproduce→Trace→Hypothesis→Test-first fix→Verify; learnings-researcher first; escalate if no hypothesis).
  12. **Optimization loop** (P8: ≤3 parallel worktree experiments, measure vs goal, keep best → OPTIMIZE.json; runs once).
  13. **Eval harness** rules (immutable, task-00, keep-or-revert, P5 coverage assertions, R4).
  14. **Learnings + compound loop** (capture P6e, refresh P0, inject non-stale into prompts).
  15. **Standing authorization + fixed stop-condition set** (full text).
  16. **Cadences/heartbeat/checkpoint:** heartbeat ≤5m; **R5 context-long checkpoint at ~200k tokens** (flush all state to .rapid/, run phase-completion checklist, log skipped steps to MEMORY.md, then continue — automatic).
  17. **Agent-output-persistence rule** (write result to a file before consuming it).
  18. **Reference table** of the 12 phases / 4 gates / tracks (the deterministic scaffold above).
- **Depends on:** every hook and tool above; `.rapid/` data model; `templates/agent-roles/`; `04-spec/`.

### 7.2 `skills/workflow/SKILL.md`
- **Role:** `/workflow` — a thin passthrough alias that invokes `/rapid-workflow`.
- **Definition:** a short SKILL.md that documents the alias and defers entirely to `skills/rapid-workflow/SKILL.md`.
- **Depends on:** `skills/rapid-workflow/SKILL.md`.

### 7.3 `skills/docs/SKILL.md`
- **Role:** `/docs` — universal documentation deck generator.
- **Definition:** `/docs build` → per-folder Reveal.js decks + master hub `docs/hub.html`; every folder navigable with diagrams, change tracking, cross-links. Documentation pages (PRD/spec/arch/eval/…) use the standard layout from `templates/template-docs-page.html` (top rapid-nav + left `.sidebar` + `.main`); apply via `apply-docs-sidebar.py`. Calls `build-docs-registry.sh` to keep `docs.json` current. Style discipline: **plain-English-first** with inline `Technically:` precision lines, **McKinsey action titles** (conclusions not topics), **evidence not claims**.
- **Depends on:** `templates/template-docs-deck.html`, `templates/template-docs-page.html`, `build-docs-registry.sh`, `apply-docs-sidebar.py`.

### 7.4 `skills/decision/SKILL.md`
- **Role:** `/decision` — decision + panel documentation deck generator (McKinsey-style).
- **Definition:** produces structured decision decks (options, recommendation, reversibility, escalation format) from `templates/template-decision-deck.html`; carries the panel corpus the orchestrator's P2 draws on.
- **Depends on:** `templates/template-decision-deck.html`.

---

## 8. `docs/` & `templates/` — surfaces, decks, and reusable form

> **Atlas invariant (applies to every emitted HTML page):** the page must load exactly two scripts at the bottom, in this order: `<script src="env-links.js" defer></script>` then `<script src="sidebar.js" defer></script>`. Both must sit in the same directory. The four required layers for a complete page: **data** (JSON), **structure** (template), **content** (rendered), **harness** (the two scripts).

### 8.1 `templates/template-docs-page.html`
- **Role:** Single source of styling + structure for ALL project doc pages.
- **Definition:** `rapid-nav` (sticky top bar, navy, brand + cross-page links, current page active) + `spec-layout` (flex 2-col: sidebar + main). Sidebar: `.sidebar-brand` + `.sidebar-sub` + `.sidebar-section` headers + `<a href="#id">` in-page anchors. Main: `.section` blocks with `.section-id`/`.section-title`/`.section-desc`. Placeholders `{{TITLE}}`, `{{NAV}}` (cross-page list), `{{SIDEBAR}}` (in-page menu), `{{MAIN}}`. Must load the two harness scripts. The CSS block is the single source — tools copy it verbatim.
- **Depends on:** `env-links.js`, `sidebar.js`.

### 8.2 `docs/env-links.js`
- **Role:** Client-side injector of environment + source links + Regenerate button.
- **Definition:** read `docs/env.json`; extract `product{local{url,launch},dev{url},prod{url}}` + `source{github,gitlab}`; inject a "Developer View" tag + Product cluster (Local/Dev/Production with colored dots — live=color, off=gray) into `.rapid-nav`. Add a per-page **Regenerate** button wired to `POST /api/regen?page=<file>` (reads `docs/regen.json` for the command). Runs on page load AND on every navigate (always read env.json fresh; `local.launch` is a copyable command, not a link). If `env.json` absent → "not set" placeholders (page does NOT error).
- **Depends on:** `docs/env.json`, `docs/regen.json`, observe-server.

### 8.3 `docs/sidebar.js`
- **Role:** Build the left sidebar (Deployments + Pages tree + nested Sections) at runtime from the DOM.
- **Definition:** **Derive the page list from the actual `<a href="*.html">` links in `.rapid-nav`** (never hardcode — change `{{NAV}}` and the sidebar auto-adapts). Mark current page active. Populate the Deployments block from `env.json` (always 3 entries Local/Dev/Production; grayed "not set" if absent). For non-active pages, lazy-fetch each page's HTML and parse its sections (both `.section[id]` and heading-based) as nested deep links (`.atlas-sub`); collapse/expand toggles; failed fetch → "unavailable"; page with no anchors → `.atlas-secs-empty` "no sections" placeholder. Active page's sections come from the authored `.sidebar-section` menu (never lazy).
- **Depends on:** `.rapid-nav` links, `env.json`.

### 8.4 `docs/observatory.html`
- **Role:** Real-time build dashboard (the Observatory).
- **Definition:** self-contained HTML + embedded CSS (renders even if server down). 2-column: left = arc topology (collapsed summary → expanded agent cards: row-1 name/task/tokens, row-2 activity timeline of stacked event-type segments) for roles (orchestrator/planner, supervisor/coder, impl1-4, tester, reviewer, watchdog, panel, rsrch). Right = tab bar (Arc / Phases / Metrics) + log table (`time | seq | agent | type | description | deps | status`), color-coded by the fixed event vocabulary, rows flash on arrival. Polls `/api/events`, `/api/agents`, `/api/meta`. Phase indicator derived from latest observe event; heartbeat threshold flags stale agents. **Static fallback:** if `observe-server` down, still renders with an empty state (no JS errors).
- **Depends on:** `observe-server.py`, `.rapid/observe/*.jsonl`.

### 8.5 `docs/testsuite.html`
- **Role:** Workflow Test Theater UI.
- **Definition:** theater-controls (wf-tabs, preset selector, play/pause/restart, transport slider). Hflow diagram (nodes + arrows, active node highlighted, status badges pass/fail/info/live). Two panes: **user-view** (iframe rendering the node's `view.src`) + **dataflow panel** (declared `in/proc/out` as `.flow-declared` + actual JSON as `.flow-json`, with `↓` between in→out — divergence is visible and flags the run). Run log table below. Loads `docs/testruns.json` on init; `POST /api/run` for live; if no server (404/timeout), **replay from `testruns.json`** with controls disabled and a clear "Offline mode: showing cached data" indication. `docs/workflows.json` is the single source — the JSON IS the test map = the diagram = the executable flow.
- **Depends on:** `docs/workflows.json`, `docs/testruns.json`, `observe-server.py`, `workflow-runner.py`.

### 8.6 `docs/workflows.json`
- **Role:** Machine-readable workflow state machine — single source for Theater diagram, `task-00`, and recorded runs.
- **Definition:** `{ schema, project, note, view_kinds:{enum}, exec_kinds:{enum}, workflows:[{ id, title, actor, golden:{assertion}, presets:[{id,label,input}], nodes:[{ id, label, lane:'system'|'actor', node_class:'n-auto'|'n-gate'|'n-guard'|'n-primary'|'n-blue'|'n-purple', in, proc, out, exec:{kind,…}, view:{kind,src?}, fallback?, required? }] }] }`. Each node's `exec` is wired to the SAME assertion as the immutable harness (S-14: runnable diagram + executable test share source of truth). The reference workflows WF-1..WF-5: WF-1 idea→app (read PRD-ENHANCED, read eval count, codex ship-gate, simulated-op ship decision), WF-2 PRD→gated→gaps→reconverge (stub-scan, read GAPS, re-run ship-gate), WF-3 stakeholder docs (read docs.json count + nav test), WF-4 monitor+stall (read observe count, read HEARTBEAT, test stop-hook), WF-5 e2e scaffold→docs→build→deploy (run lifecycle-e2e stages, codex judges dist/, simulated-op approves dev deploy, write E2E.json).
- **Depends on:** `04-spec/workflow.md`; produced P4.

### 8.7 `docs/eval.html` + `docs/eval.json`
- **Role:** Test harness status + assertion verdicts page.
- **Definition:** `eval.json` (written by ship-gate) = `{ generated, summary:{pass,fail,total}, assertions:[{name,pass,detail}], harness:[{name,pass,output}] }`. `eval.html` static (uses spec template + sidebar.js): heading + 4 summary cards (pass/fail/total/status) + Assertions table + Harness cards. Absent json → "No eval data yet" placeholder (no JS errors). Assertion names stable across runs.
- **Depends on:** `ship-gate.sh` → `eval.json`.

### 8.8 `docs/cost.html`
- **Role:** Token usage + estimated cost page (pure static, no JS).
- **Definition:** rendered by `cost-summary.sh --html`: overview cards (total est cost / output tokens / step count / session count) + per-step table + per-session table + Rapid per-phase estimate. Absent data → zeros/empty, no errors. Embedded CSS, no external deps.
- **Depends on:** `cost-summary.sh`.

### 8.9 `docs/home.html`
- **Role:** Atlas per-project landing hub.
- **Definition:** template running `env-links.js` + `sidebar.js`; describes THIS project; links to key pages via `{{NAV}}`; if `docs.json` present, lists registered docs; anchors Overview | Getting Started | Architecture | Documentation | Try it out (Local link). Renders even with `env.json` absent (grayed env links).
- **Depends on:** `env-links.js`, `sidebar.js`, `docs.json`, `env.json`.

### 8.10 `docs/env.json`
- **Role:** Single per-project wiring file for environment + source links.
- **Definition:** `{ product:{ local:{url,launch?}, dev:{url}, prod:{url} }, source:{ github?, gitlab? }, atlas:{url} }` (or flat `{local/dev/prod}`). All three env keys optional → "not set". URLs absolute or absent. Written by deploy tooling (`atlas-deploy.sh`) and committed at P9.
- **Depends on:** read by `env-links.js`, `sidebar.js`.

### 8.11 `docs/regen.json`
- **Role:** Per-page regeneration command registry; drives `POST /api/regen`.
- **Definition:** `{ "<page>.html":{ kind:'deterministic'|'prompt'|'manual', cmd?:str, prompt?:str } }`. deterministic = run side-effect-free idempotent cmd; prompt = invoke claude with the prompt; manual = button only. observe-server runs ONLY registered commands (user input never becomes a command); runs in background; deterministic regen ≤30s, prompt ≤5min. Example: `{"prd-enhanced.html":{"kind":"deterministic","cmd":"tools/populate-deck.py prd-enhanced.html"}}`.
- **Depends on:** observe-server, `populate-deck.py`.

### 8.12 `docs/testruns.json`
- **Role:** Static snapshot of latest test runs (offline Theater replay).
- **Definition:** `{ generated, generated_by, note, workflows:{ <wf>:{ runs:[…], latest:{run_id, summary, nodes[]} } } }`, max 25 runs/wf (oldest pruned). Published by `workflow-runner.py` on completion / `--publish-only`. Overwritten each run — never hand-edit (canonical source is `.rapid/RUNS/`).
- **Depends on:** `workflow-runner.py`.

### 8.13 `docs.json`
- **Role:** Machine-readable doc registry.
- **Definition:** `{ version:int(≥6), updated, generated_by, categories:{key:{label,description}}, docs:[{file,title,category,description,status:'current'|'new'|'missing',generated?}], archive:[{file,title,category,superseded_by?}] }`. Generated by `build-docs-registry.sh` (scans filesystem). Version bumps each run.
- **Depends on:** `build-docs-registry.sh`.

### 8.14 `templates/template-docs-deck.html`
- **Role:** Master CSS for all generated Reveal.js documentation decks.
- **Definition:** the `<style>` block every deck (vision/intake/grounding/panels/spec/gaps/tests/decisions) copies verbatim. Single source of deck styling.

### 8.15 `templates/template-decision-deck.html`
- **Role:** Base template for `/decision` output decks.
- **Definition:** McKinsey-style decision deck shell (action titles, options/recommendation/reversibility layout).

### 8.16 `templates/BUILD-AUTONOMY.md`
- **Role:** Seeded standing-authorization charter.
- **Definition:** the fixed stop-condition set (destructive/irreversible, outward-facing, spends money, genuinely-undecidable high-stakes — text of each), plus operator-signed fields left blank: deploy target, spend ceiling, undecidable-batch answers. Written at P1; signed at G1. Its PRESENCE (signed) authorizes run-to-completion.
- **Depends on:** copied by `new-project.sh`; signed at G1.

### 8.17 `templates/contract-seam.md`
- **Role:** Scaffold for pinned per-seam interface contracts.
- **Definition:** markdown scaffold instantiated at P6a into `04-spec/contracts/{api,dom,events,schema,e2e}.md`: api (requests/responses/status/envelopes), dom (selectors/ARIA/data-testid/structure), events (names/payloads/ordering/emitter-consumer), schema (DB tables/columns/message/file formats), e2e (concrete selectors+flows the suite drives, derived from api+dom). These supersede abstract CONTRACTS.md for cross-boundary work; fan-out is impossible without them.

### 8.18 `templates/agent-roles/{planner,coder,tester,reviewer,watchdog}.md`
- **Role:** Five template role contracts instantiated at P6a.
- **Definition:** each carries its R/W contract (YAML frontmatter scope), Decision Router (D5) rules, and role mission. planner (plan/decompose/gates/operator relationship; owns STATE/TASKS/HEARTBEAT). coder (task assignment, keep-or-revert, commit `[SPEC §X.Y]`, never self-approve, send PR_SUBMITTED). tester (owns immutable eval harness task-00, per-surface test subagents, never alter harness). reviewer (per-dimension review → APPROVE/REJECT; drift is NOT reviewer's job). watchdog (R2; drift-check 7 categories; NEVER implement; never check in-progress worktrees). Instantiated into `04-spec/agents/<role>.md` with build-specific paths.

### 8.19 `docs/rapid-architecture.html` + `docs/rapid-reference.md` (+ `tools/rapid-spec.html`)
- **Role:** The kit's OWN methodology reference (the D0–D19/D21 system reference).
- **Definition:** D0 master architecture (Agents | Pipeline | Safety & Guards | Data Stores; legend 🟢autonomous 🟡human-gate 🔴safety-guard 🔵data-store 🔄loop ⚪prompt-injection) and detail diagrams D1–D16 (D1 master pipeline 12 phases/4 arcs/4 gates; D2 agent topology + primitive decision tree skill/subagent/agent/terminal; D3 human gates; D4 drift detection 7 categories/3 triggers; D5 decision router tactical/technical/architectural/strategic; D6 research protocol VERIFIED/UNVERIFIED/OPEN; D7 fan-out sizing; D7b TDD; D8 build & bug-fix loop keep-or-revert; D9 gap loop max 3; D10 visual QA 3 viewports; D11 CI/CD; D12 economics 3 cost layers + 80% breaker; D13 observability 2 channels + agent-output-persistence; D14 config 3-level cascade `~/.rapid/rapid.yaml` → `.rapid/rapid.yaml` → CLI flags; D15 trust model evidence-not-claims; D16 methodology provenance). `tools/rapid-spec.html` is the full HTML reference (supersedes the text form).
- **Depends on:** none at runtime; reference material. NOTE: this is the KIT's docs/, distinct from a built project's generated docs/.

### 8.20 `CONSTITUTION.md`
- **Role:** Governance — Articles I–X.
- **Definition:** **I–V inviolable** (I Truthfulness — no invented facts/citations, uncertain → "I don't know" + gap; II User Safety; III Data Handling — no PII without consent, COPPA/FERPA; IV Reversibility — destructive actions need confirmation, watchdog blocks `--no-verify`; V Scope Discipline — stay within R/W contract). **VI–X overridable with explicit `# OVERRIDE` + log to gaps history** (VI Spec Authority; VII No Test Theater — tests hit real sandboxed systems, failing tests stay failing if system is wrong; VIII Honest Reporting — "done" requires verification in the actual file; IX Pushback Discipline; X Root-Cause Discipline — no try/except papering). Violation of I–V = blocking, watchdog refuses merge until fixed.
- **Depends on:** checked before every merge (watchdog, CI constitution stage).

---

## 9. Repo layout, version control, and packaging

### 9.1 `.gitignore`
- **Role:** Keep runtime state local.
- **Definition:** ignore `.DS_Store`, `Thumbs.db`, `.rapid/` (runtime state — generated per project), `*.pptx` (regenerable), `.claude/settings.local.json`, `CHANGES.md` (generated by post-write-hook).

### 9.2 `README.md`, `CHANGELOG.md`, `CODEBASE.md`, `ROADMAP.md`
- **Role:** Kit meta-documentation.
- **Definition:** **README** — repo structure + quick start: clone, **re-create the skill symlinks** (`for s in rapid workflow decision docs; do ln -sf "$PWD/skills/$s" "$HOME/.claude/skills/$s"; done`), register hooks (`bash tools/install-hooks.sh`), invoke `/rapid-workflow "idea"`. **CHANGELOG** — append-only semver history. **CODEBASE** — structure of the kit itself. **ROADMAP** — forward plan.
- **Depends on:** the symlink + install-hooks setup must be documented because skills/ is the source of truth and `~/.claude/skills/` is a symlink target re-created on clone.

### 9.3 `examples/vision/{VISION.md,PILLARS.md}`
- **Role:** Frozen reference output of P0.
- **Definition:** `VISION.md` (north star + success signals + objective); `PILLARS.md` (3–5 pillars derived from project risks/goals). A rebuild agent uses these to match expected format/depth. Never auto-updated.

### 9.4 `archive/`
- **Role:** Superseded versions kept for lineage (e.g., `deck-v1.html`, `rapid-comparison.html`, `rapid-dashboard.html`, old `docs.json`). Stable reference; never executed during builds.

> **What is version-controlled vs local-only:** version-controlled = `skills/`, `tools/`, `templates/`, kit `docs/` (methodology reference), `examples/`, `archive/`, `CONSTITUTION.md`, README/CHANGELOG/CODEBASE/ROADMAP, `.gitignore`, `docs.json`. **Local-only (gitignored):** `.rapid/` (all runtime state), `CHANGES.md`, `*.pptx`, `.claude/settings.local.json`. A **built project** generates its OWN `00-vision/`, `01-intake/`, `02-grounding/`, `03-panels/`, `04-spec/`, `docs/` (project Atlas), `.rapid/` — these are distinct from the kit's files and are created at runtime by the orchestrator + tools.

---

## 10. Global acceptance criteria (self-check before declaring done)

**Hooks & enforcement**
- [ ] `bash tools/install-hooks.sh` is idempotent; `~/.claude/settings.json` ends with Stop+SubagentStop→stop-hook, PreToolUse(Write|Edit)→phase-gate, PostToolUse(Write|Edit)→post-write+conformance+stub (async), all via the stable symlink path.
- [ ] Every hook no-ops (`exit 0`) instantly when `.rapid/STATE.json` is absent; reads stdin JSON (no env-var inputs); fails safe (a hook bug never traps an unrelated session).
- [ ] phase-gate blocks a STATE→phase-N write with **exit 2** + missing-artifact on stderr when the prior artifact is missing; passes (exit 0) once present.
- [ ] stop-hook: always logs STOP to observe; never blocks twice when `stop_hook_active`; logs-only on SubagentStop; emits `{"decision":"block","reason":…}` on Stop while phase artifact missing; allows after 5 nudges (`.stop_count`/`.stop_phase`).
- [ ] conformance hook files `GAP-CONF-*` for orphan refs, appends CONFORMANCE.md, dedups via `.conformance_seen`, exempts `spec_ref:ALL`.
- [ ] stub hook + `stub-scan.sh` detect well-marked stubs, exempt `rapid:allow-stub`, file `GAP-STUB-*` (non-blocking at write); ship-gate blocks on open stub/conformance gaps in MUST modules.

**Pipeline & gates**
- [ ] `skills/rapid-workflow/SKILL.md` encodes all 12 phases in order with exit artifacts, all 4 gates with pre-screens + approvals, the deterministic/dynamic split, the 12-message contract, the P6 sub-protocol (P6a–P6e), reviewer tiers, keep-or-revert, R5 checkpoint, standing authorization + fixed stop-set, agent-output-persistence.
- [ ] `/rapid-workflow`, `/workflow` (alias), `/decision`, `/docs` resolve via symlinks; README documents symlink re-creation.
- [ ] `task-00` is the eval-harness root; all tasks depend on it; supervisor verifies it `done` before any other; agents extend never edit `.rapid/EVAL/`.

**Tools (genuine exit codes, no pipe masking)**
- [ ] `preflight.sh` exits 3 + blocks on missing required runtime; `verify.sh` writes per-layer VERIFY.json with real exit codes, e2e required; `ship-gate.sh` merges the 4 assertions into P6_EXIT.json + publishes eval.json, exits 3 on any fail; `cost-summary.sh` parses real transcripts + renders cost.html.
- [ ] `new-project.sh` scaffolds a self-contained project (folders, locked PRD, CONSTITUTION, BUILD-AUTONOMY, STATE, tools, templates, live Atlas) and is idempotent with `--force`.
- [ ] `lifecycle-e2e.sh --stage all` runs create→build→docs→deploy→verify, each exits 1 on failure, writes E2E.json with 3 passing assertions.
- [ ] `workflow-runner.py` runs WF-1..WF-5 with deterministic fallbacks completing offline; bounded by CMD_TIMEOUT/CODEX_TIMEOUT; publishes testruns.json (≤25/wf).

**Live surfaces & Atlas (honest degradation)**
- [ ] `observe-server.py` serves `/`, `/api/events`, `/api/agents`, `/api/meta`, `/api/runs`, `/api/run`, `POST /api/regen` (registered commands only), `POST /api/run` on 127.0.0.1:4040.
- [ ] Observatory renders with server down (empty state); Test Theater replays from testruns.json offline with a clear offline indicator; eval.html/cost.html/home.html render with their JSON absent (no JS errors).
- [ ] EVERY emitted HTML page loads `env-links.js` then `sidebar.js`; `sidebar.js` derives the page list from rapid-nav DOM links; Deployments block always shows 3 entries (grayed "not set" if `env.json` absent).
- [ ] `atlas-deploy.sh` folds the static deck into `/_atlas` and keeps the live-view half local (two-halves rule); `populate-deck.py` refuses the kit root and produces stub-free pages.

**Governance & traceability**
- [ ] `CONSTITUTION.md` has Articles I–V inviolable / VI–X overridable-with-logging.
- [ ] Every PRD requirement maps to a spec section or `[OUT OF SCOPE]`; every spec section is `[FROM PRD]` or `[DERIVED]`; tasks carry `spec_ref`/`prd_ref`/`arch_ref`; conformance hook verifies the chain.
- [ ] `.gitignore` excludes `.rapid/`, `CHANGES.md`, `*.pptx`, `.claude/settings.local.json`; skills/tools/templates/examples are version-controlled.

When all boxes pass, Rapid is built: a deterministic 12-phase / 4-gate pipeline whose load-bearing steps are enforced by hooks, blocking dependencies, and separate agents — with live surfaces that degrade honestly and a gap loop that compounds across builds.