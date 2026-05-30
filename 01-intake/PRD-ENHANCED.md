# FORGE — Enhanced PRD (requirements register)

> Derived from `docs/PRD.md` + `skills/forge/SKILL.md`. The machine-traceable
> requirements doc that `04-spec/spec.md` and `.forge/TASKS.json` reference.
> The HTML deck under `docs/` is the developer-view presentation of this content.
>
> **Organization (layered pyramid):** requirements live at one of three altitudes —
> **Business (BR)** = why/outcomes → **Functional (FR)** = what the system does →
> **Technical/NFR (TR)** = how + constraints. Each lower requirement traces **up** to
> its parent and (for TR) **down** to spec/architecture. Priority (MUST/SHOULD/COULD)
> is an attribute on each requirement, not the grouping.
>
> **Change tracking:** every requirement carries a change history; all changes are
> consolidated in the [Change Log](#change-log). A change is logged when it is
> *requested* (date, who, what, status: requested → accepted → implemented), so the
> PRD is an auditable diff, never silently edited.

## Pillars

1. **Enforcement over prose** — every safety step is a hook, a dependency, or a separate agent.
2. **The writer is never the auditor** — implementation and review are structurally split.
3. **The gap loop is the product** — the build is the artifact; surfacing and closing gaps is the value.

---

## §1 — Business Requirements (BR)

The outcomes and value. The "why" everything below serves.

### BR-1 — Idea/PRD → shipped, tested, documented app, minimal human input
Turn a stakeholder's requirements into a deployed, tested, documented application with the operator checking in at only four decision points. *(north star, docs/PRD.md)*

### BR-2 — Trustworthy autonomy
The operator can walk away between gates because safety is **structural** (the writer is never the auditor), not dependent on vigilance. *(pillar 2)*

### BR-3 — Enforcement over prose
Every safety-critical step is mechanically enforced (hook / dependency / separate agent), so nothing load-bearing rests on a prose reminder that fails under pressure. *(pillar 1)*

### BR-4 — Live visibility & honest progress
At any moment the operator can see phase, agents, blockers, plan completion, test status, docs currency, and cost — in one place, prepopulated, not buried in logs. *(docs/PRD.md)*

### BR-5 — Compounding gap loop
Failures become tracked, classified gaps that converge to resolution and feed learning, so each build starts smarter than the last. *(pillar 3)*

---

## §2 — Functional Requirements (FR)

What the system does. Each traces ↑ to a Business Requirement; priority in brackets.

### FR-1 — Build pipeline  [MUST] ↑BR-1
Given an idea or PRD, the system understands (panels + research), plans for approval, builds with a parallel agent team, reviews, tests, fixes or flags, and deploys.

### FR-2 — Deliverable coverage  [MUST] ↑BR-1, BR-3
Every MUST deliverable in the PRD maps to at least one task; an unmapped deliverable is a blocking gap.

### FR-3 — Concrete walkthrough  [MUST] ↑BR-2
P7 runs an explicit step-by-step walkthrough across every surface and records `.forge/WALKTHROUGH.md`.

### FR-4 — Prepopulated live dashboard  [MUST] ↑BR-4
The observability dashboard shows the full build plan the moment a build starts (phase, agents, blockers, plan completion, timeline) and updates in real time.

### FR-5 — Documentation generated as the build runs  [MUST] ↑BR-4
Each phase produces documentation automatically; mid-build docs reflect everything completed so far; at the end they reorganize into a navigable developer-view site.

### FR-6 — Test results visible everywhere  [MUST] ↑BR-4
Eval pass/fail status surfaces in the dashboard, the documentation, and at every decision point.

### FR-7 — Cross-system integration / combined gate view  [MUST] ↑BR-4
Build status, docs, test results, and dashboard update together on phase completion; each decision point shows one combined gate view.

### FR-8 — Cost & token visibility  [SHOULD] ↑BR-4
Token/cost burn is tracked and shown per step, per phase/section, and per project; the developer view surfaces it.

---

## §3 — Technical Requirements & NFRs (TR)

How it works + constraints. Each traces ↑ to a Functional Requirement and ↓ to spec/architecture; priority in brackets.

### TR-1 — Phase-gate enforcement  [MUST] ↑BR-3 ↓S-01
STATE.json cannot advance to a phase whose required artifacts are missing — a PreToolUse hook blocks on exit 2.

### TR-2 — Independent watchdog  [MUST] ↑BR-2 ↓S-02
A separate auditing agent (no implementation incentive) is spawned automatically at P6a and writes `.forge/AUDIT.json`; P6 cannot exit without it.

### TR-3 — Blocking dependency graph (eval-first)  [MUST] ↑FR-1 ↓S-04
Safety steps are nodes in the dependency graph; the immutable eval harness (`task-00`) is the root everything depends on.

### TR-4 — Continuation enforcement  [MUST] ↑BR-3 ↓S-07
A synchronous Stop/SubagentStop hook prevents stopping early while the current phase's artifact is missing; logs every halt; escalates after 5 nudges.

### TR-5 — Module conformance tracing  [MUST] ↑FR-2 ↓S-08
As each module completes, its `spec_ref`/`prd_ref`/`arch_ref` must resolve to real anchors; orphans are filed as conformance gaps.

### TR-6 — Stub detection + ship gate  [MUST] ↑FR-6 ↓S-09
Placeholder code is detected at write time; the ship gate blocks release on any open stub gap in a MUST module.

### TR-7 — Terminal-per-agent + agent teams  [MUST] ↑FR-1 ↓S-02
Each persistent agent runs in its own terminal, connected as one team over the claude-peers bus, with per-terminal status/monitoring/continuous-build hooks keyed by FORGE_ROLE.

### TR-8 — Context-checkpoint protocol  [SHOULD] ↑BR-2
Above ~200k tokens the skill checkpoints all state to `.forge/` and runs a phase-completion checklist before continuing.

### TR-9 — Configurable artifact paths  [COULD] ↑FR-5
The enforcement hooks' artifact paths (`01-intake/`, `03-panels/`, `04-spec/`) should be configurable so a repo can dogfood FORGE without root-level numbered folders.

### NFR — Constraints  [MUST]
- **NFR-1:** No external dependencies beyond Python 3 and Claude Code.
- **NFR-2:** The dashboard/docs work offline — self-contained HTML.
- **NFR-3:** Integration over redesign — must work with the existing pipeline.
- **NFR-4:** Documentation generation must not block the build (runs in background).
- **NFR-5:** Everything the system produces is explainable in plain English.

---

## Traceability matrix (BR → FR → TR → test)

| Business | Functional | Technical / NFR | Verified by |
|----------|------------|------------------|-------------|
| BR-1 | FR-1, FR-2 | TR-3, TR-7 | task-00 eval; ship-gate |
| BR-2 | FR-3 | TR-2, TR-4, TR-8 | AUDIT.json; stop-hook smoke |
| BR-3 | FR-2 | TR-1, TR-5 | phase-gate smoke; CONFORMANCE.md |
| BR-4 | FR-4, FR-5, FR-6, FR-7, FR-8 | TR-6 | observatory; P6_EXIT.json; cost-summary |
| BR-5 | — | TR-5, TR-6 | GAPS.json → issues; gap-loop |

---

## Deliverables (MUST)

- D1: Enforcement hook suite (TR-1, TR-4, TR-5, TR-6)
- D2: FORGE skill orchestration + agent-team build (FR-1, TR-2, TR-3, TR-7, TR-8)
- D3: Observatory dashboard (FR-4, FR-6)
- D4: Documentation system / developer view (FR-5)
- D5: Integration layer + combined gate (FR-7), cost visibility (FR-8)

---

## Old → new id map

The pre-pyramid register used `R-01..R-14`. Mapping (no requirement lost):

| Old | New | Old | New |
|-----|-----|-----|-----|
| R-01 | TR-1 | R-08 | TR-5 |
| R-02 | TR-2 | R-09 | TR-6 |
| R-03 | FR-2 | R-10 | FR-4 |
| R-04 | TR-3 | R-11 | FR-5 |
| R-05 | TR-8 | R-12 | FR-6 |
| R-06 | FR-3 | R-13 | FR-7 |
| R-07 | TR-4 | R-14 | TR-9 |
| (new) | FR-1, FR-8, TR-7, BR-1..5, NFR-1..5 | | |

---

## Change Log

Append-only audit of requirement changes, **aligned with the GitHub issue tracker**.
A requirement change originates from the gap loop: `.forge/GAPS.json` → `tools/gaps-to-issues.sh`
→ GitHub issues. Each entry records the **source/issue** that drove it and the **requirement(s)**
it updated, so any GitHub issue traces to exactly where the PRD changed — and back. A change is
logged when **requested** (status: requested → accepted → implemented).

| Date | Req(s) | Change | Source / Issue | Status |
|------|--------|--------|----------------|--------|
| 2026-05-30 | ALL | Genesis — derived from docs/PRD.md + SKILL.md as R-01..R-14 (flat, grouped by MUST/SHOULD/COULD). | derivation | implemented |
| 2026-05-30 | FR-4, FR-7 | Dashboard prepopulation + cross-system integration. | issues #1, #2 (GAP-INT-01, GAP-DASH-01) | implemented |
| 2026-05-30 | FR-5 | Per-phase docs auto-refresh wired. | issue #3 (GAP-DOCS-01) | implemented |
| 2026-05-30 | TR-6 | Stub-scan placeholder false-positive fixed; stub gap-id path stabilized. | issues #4, #5 (GAP-R9-REGEX, GAP-R9-PATH) | implemented |
| 2026-05-30 | TR-7 | Added — terminal-per-agent + agent teams + per-terminal hooks. | operator (GAP-BUILD-TERMINALS, GAP-BUILD-HOOKS) | implemented |
| 2026-05-30 | FR-8 | Added — cost & token visibility (cost-summary + dashboard cards). | operator | implemented |
| 2026-05-30 | ALL | Reorganized into the Business→Functional→Technical pyramid; priority moved from grouping to a per-requirement badge; added BR-1..BR-5, FR-1, NFR-1..5; renumbered per the old→new map. | operator | implemented |
| 2026-05-30 | (doc) | Per-requirement change history + this issue-aligned Change Log made first-class. | operator | implemented |

> **Change-request protocol.** When a requirement is *requested* to change: (1) file/identify
> the GitHub issue (gap loop), (2) add a row here with `requested` status naming the issue and
> the affected BR/FR/TR, (3) update the requirement + its per-requirement change history, (4) flip
> the row to `implemented` when shipped (and `gaps-to-issues.sh` closes the issue). This is the
> single place "where the PRD gets updated" is recorded.
