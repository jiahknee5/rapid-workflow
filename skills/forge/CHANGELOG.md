# Forge Changelog

## v2.5.0 — 2026-05-27 (Full Compound Engineering Integration)

### Added — 8 additional CE capabilities (CE #8–15)
- **CE #8: Simplification pass** (P7 step 6) — 3 parallel agents (reuse, quality, efficiency) simplify code after tests pass, before gap classification. Only applies simplifications that keep tests green.
- **CE #9: Compound refresh** (P0 step 5) — refreshes stale LEARNINGS.md entries against current codebase before reading them into the new build. Marks stale entries so they don't mislead agents.
- **CE #10: Dogfood QA** (P7 step 5) — autonomous diff-scoped browser QA with auto-fix loops. Upgrades P7 from "screenshot and flag" to "screenshot, fix, retest, commit until green."
- **CE #11: Learnings researcher** (P6b step 6) — before debug protocol, search LEARNINGS.md for matching past solutions. Prevents re-solving known problems.
- **CE #12: Spec deepening pass** (P5b, new phase) — sub-agent review of spec for confidence ratings, missing flows, and orphaned deliverables before G2 (point of no return).
- **CE #13: Strategy as living doc** (P0 step 4) — VISION.md and PILLARS.md are re-runnable. Subsequent builds diff against previous vision and present changes to operator.
- **CE #14: Interactive brainstorm** (P0 step 6) — for vague inputs, collaborative Q&A before mechanical PRD decomposition. Writes BRAINSTORM.md as input for P1b.
- **CE #15: Spec flow analyzer** (P5b step 1) — analyzes workflow state machine for unreachable states, missing error paths, and disconnected edges.

### Added — 4 additional reviewer agents (tiered review expanded from 5 to 9)
- **API Contract reviewer** — breaking API changes, interface drift from CONTRACTS.md
- **Reliability reviewer** — production failure modes, retry logic, graceful degradation
- **Pattern Recognition reviewer** — architectural patterns/anti-patterns, systemic code smells
- **Standards reviewer** — CLAUDE.md compliance, Constitution Articles VI–X

### Changed
- Pipeline expanded to 13 phases (added P5b: Spec Deepening)
- Fast track tiered review: 3 reviewers (was 2). Full track: 9 reviewers (was 5).
- P7 upgraded: dogfood QA (auto-fix loops) + simplification pass before gap classification

## v2.4.0 — 2026-05-27 (Structural Enforcement — R1-R6)

### Added — 6 enforcement mechanisms replacing prose with structural guarantees
- **R1: Phase gate hook** (`forge-phase-gate.sh`) — blocks STATE.json writes unless required phase artifacts exist. Checks: PRD-ENHANCED.md before P2, synthesis.md before P4, spec.md before P5, EVAL/ with tests before P6, P6_EXIT.json before P7, WALKTHROUGH.md before P8. Prose won't prevent phase-skipping; a hook will.
- **R3: Deliverable coverage assertion** (Phase 5) — every PRD deliverable must map to at least one task in TASKS.json. Missing coverage = phase fails, task auto-created.
- **R4: Eval harness as task-00** (Phase 5) — eval harness is no longer a step the orchestrator performs. It is `task-00` in TASKS.json with every other task depending on it. The build literally cannot start until tests are generated.
- **R5: Context-long checkpoint protocol** — at ~200k tokens, the skill MUST: write all state, run phase-completion checklist, log skipped steps. Counters urgency bias at the moment shortcuts are most tempting.
- **R6: Concrete walkthrough commands** (Phase 7) — replaces "run agent walkthrough of the golden path" with exact steps: open app, navigate each surface, screenshot, pass/fail. WALKTHROUGH.md with screenshot paths required before Phase 8.

### Changed
- **R2: Watchdog spawn made mandatory** — was already automatic in v2.2.0, now explicitly enforced: P6 exit assertions check AUDIT.json has watchdog entries. If watchdog was never spawned, P6 cannot exit.
- Phase 5 inter-stage assertions expanded: deliverable coverage (R3) + task-00 root check (R4)

### Philosophy
The workflow has the right ideas but the wrong enforcement model. It relied on the orchestrator being disciplined when the orchestrator is also the one under pressure to deliver. These fixes move enforcement from prose instructions to: hooks that block advancement, dependency graphs that make safety steps blocking, separate agents that audit independently, and concrete commands instead of vague directives.

## v2.3.0 — 2026-05-27 (Compound Engineering Integration)

### Added — 7 capabilities from Compound Engineering (Every Inc.)
- **Tiered multi-agent code review** (P6b step 4) — 5 parallel specialized reviewer subagents (Correctness, Spec Compliance, Security, Performance, Maintainability) with confidence gating and dedup synthesis. Replaces single reviewer. Fast track: 2 reviewers.
- **Compound learning capture** (P6e step 6) — structured `.forge/LEARNINGS.md` documenting decisions, patterns, gotchas, and debug traces from each build. Future builds read learnings at P0. Each build makes the next one smarter.
- **Document review agents at gates** (G0, G1, G2) — parallel persona-based pre-screening (Feasibility, Scope Guardian, Coherence, Adversarial) before operator reviews gate artifacts. Operator sees higher-quality material.
- **Product Pulse** (P10, optional post-ship) — time-windowed monitoring reports on usage, performance, errors, and feedback. Saves to `docs/pulse-reports/`. Feeds into next build's P0 vision. The build→ship→pulse→build outer compound loop.
- **Session intelligence** (P6d crash recovery) — searches past session logs for crashed agent's last context, includes summary in re-spawn prompt. Replacement gets continuity, not a cold start.
- **Structured debug protocol** (P6b step 6) — systematic reproduce→trace→hypothesis→test-first-fix flow. Replaces "try 3 times and escalate."
- **Optimization loops** (P8) — for MEDIUM/LOW optimization gaps: 3 parallel experiment branches, measure against goal, keep best. Optional on fast track.

### Attribution
Inspired by the [Compound Engineering plugin](https://github.com/everyinc/compound-engineering-plugin) by Every Inc. — "Each unit of engineering work should make subsequent units easier, not harder."

## v2.2.0 — 2026-05-27 (3-Terminal Architecture)

### Added
- **3-terminal architecture for Phase 6** — orchestrator, supervisor, and watchdog run as persistent tmux-managed Claude Code sessions during the build phase.
- **P6 sub-phases** (P6a–P6e) — Terminal Setup, Build Loop, Watchdog Loop, Orchestrator Monitoring, Shutdown Sequence.
- **Claude-peers message contract** — 12 structured JSON message types with durability fallback to `.forge/MESSAGES.json`.
- **Prompt file generation** — `.forge/prompts/supervisor.md` and `.forge/prompts/watchdog.md` generated dynamically at P6a.
- **Shutdown handshake** — SHUTDOWN → ACK_SHUTDOWN within 60s, fallback to tmux kill-window.
- **Crash recovery** — orchestrator polls `list_peers` every 5m, re-spawns crashed terminals from state files.

### Changed
- **Smoke test ownership** transferred from orchestrator to supervisor. Orchestrator's P6 exit assertions remain as trust boundary.
- **Watchdog** upgraded from event-triggered to persistent tmux terminal.

## v2.1.0 — 2026-05-27 (Post-Meridian retro)

### Added
- **Reference project protocol** (Phase 6 step 1) — Spec is the authority, reference is a pattern guide. Agents cross-check every spec requirement before reporting done.
- **Mandatory smoke test** (Phase 6 step 3) — Orchestrator runs build+test commands directly via Bash after each agent returns. Not delegated.
- **Secret scanning** (Safety Mechanisms) — grep for credentials after every agent return and at P6→P7 boundary. Real keys in committed files = BLOCKER.
- **P6_EXIT.json** (Phase 6 exit) — Orchestrator writes proof that every exit assertion passed. STATE.json can't advance without it.
- **TEST_RESULTS.md** (Phase 7) — Raw test output with pass/fail counts. Evidence, not claims.
- **HEARTBEAT.json** (Observability) — Agents write liveness every 5 minutes during Phase 6.
- **claude-peers protocol** (Observability) — Mandatory set_summary on spawn, update on status change.
- **`/forge status` dashboard** (Observability) — Reads all .forge/ files and produces a structured terminal dashboard.
- **Documentation Protocol** (Phase 9) — /docs build for per-folder Reveal.js decks after every phase.

### Changed
- **Phase 6 step 4**: Code review marked "mandatory, not skippable." Phase 7 blocked until all tasks have APPROVE verdict.
- **Phase 7 step 1**: Rewritten to require actual command execution, not file audits. "Not a file audit, not a markdown review."
- **P6 exit assertions**: Added 3 new: reviewer APPROVE, smoke test passed, secret scan passed.

### Fixed
- Gap: Agents copied reference code instead of building from spec → trade/[id] route missing
- Gap: Root npm install never ran → anchor test would have failed
- Gap: .env.local leaked a real Helius API key → no secret scanning existed
- Gap: tests/RESULTS.txt fabricated by agent → no reviewer to catch Article I violation
- Gap: Phase 7 audited files instead of executing tests → "compiles ≠ works" was aspirational, not enforced

### Root cause
Every safeguard was advisory, not enforced. The orchestrator took shortcuts and the skill let it. Fixes add proof files (.forge/P6_EXIT.json, .forge/TEST_RESULTS.md) that must exist before phase transitions.

---

## v2.0.0 — 2026-05-26 (Initial forge skill)

### Added
- 10-phase pipeline: vision → panels → research → spec → tasks → build → test → gaps → ship → deploy
- 3 human gates: Direction (G1), Architecture (G2), Ship Decision (G3)
- Parallel build with worktree isolation
- Keep-or-revert ratchet (Karpathy)
- Constitution enforcement (Articles I–X)
- Decision Router (D5): tactical/technical/architectural/strategic classification
- Inter-stage assertions between phases
- Anti-hallucination protocol
- Fast/full track modes
- Resume from checkpoint (--resume)
- Gap loop with spec re-derivation (--gap-loop)
