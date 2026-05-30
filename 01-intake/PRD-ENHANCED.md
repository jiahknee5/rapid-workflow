# FORGE — Enhanced PRD (requirements register)

> Derived from `docs/PRD.md` + `skills/forge/SKILL.md`. This is the machine-traceable
> requirements doc that `04-spec/spec.md` and `.forge/TASKS.json` reference. The HTML
> decks under `docs/` are the human-facing presentation of the same content.
>
> rapid-workflow dogfoods FORGE: it tracks its own requirements, conformance, and gaps
> with the exact mechanisms FORGE applies to the projects it builds.

## Pillars

1. **Enforcement over prose** — every safety step is a hook, a dependency, or a separate
   agent. A step described only in words will eventually be skipped under pressure.
2. **The writer is never the auditor** — implementation and review are structurally split.
3. **The gap loop is the product** — the build is the artifact; surfacing and closing gaps
   is the value.

---

## MUST

### R-01 — Phase-gate enforcement
STATE.json cannot advance to a phase whose required artifacts are missing. Enforced by a
PreToolUse hook that blocks on exit 2, not by prose.

### R-02 — Independent watchdog
A separate auditing agent (no implementation incentive) is spawned automatically at P6a and
writes `.forge/AUDIT.json`. P6 cannot exit without watchdog entries.

### R-03 — Deliverable coverage
After task decomposition, every MUST deliverable in the PRD maps to at least one task. An
unmapped deliverable is a blocking gap.

### R-04 — Blocking dependency graph
Safety steps are nodes in the dependency graph, not reminders. The eval harness (`task-00`)
is the root; everything depends on it.

### R-06 — Concrete walkthrough
P7 runs an explicit, step-by-step walkthrough across every surface and writes
`.forge/WALKTHROUGH.md`. The phase gate blocks P8 without it.

### R-07 — Continuation enforcement
A synchronous Stop/SubagentStop hook makes it mechanically impossible to stop early while the
current phase's completion artifact is missing. Every halt is logged to
`.forge/observe/<role>.jsonl`; escalates to the operator after 5 same-phase nudges.

### R-08 — Module conformance tracing
As each module completes, its `spec_ref`/`prd_ref`/`arch_ref` must resolve to real anchors in
the spec/PRD/architecture. Orphans are filed as conformance gaps and recorded in
`.forge/CONFORMANCE.md`.

### R-09 — Stub detection and ship gate
Placeholder code is detected at write time (non-blocking) and the ship gate blocks release on
any open stub gap mapped to a MUST module.

### R-10 — Prepopulated live dashboard
The observability dashboard shows the full build plan the moment a build starts — phase,
agents, blockers, plan completion, and a Gantt-style timeline — not an empty screen.

### R-11 — Documentation generated as the build runs
Each phase produces documentation automatically; mid-build docs reflect everything completed
so far. No separate command. At the end, docs reorganize into a navigable site.

### R-12 — Test results visible in every view
Eval pass/fail status surfaces in the dashboard, the documentation, and at every decision
point — never buried in a log.

### R-13 — Cross-system integration / combined gate view
Build status, documentation, test results, and dashboard know about each other; a phase
completion updates all four, and each decision point shows one combined gate view.

---

## SHOULD

### R-05 — Context-checkpoint protocol
Above ~200k tokens the skill checkpoints all state to `.forge/` and runs a phase-completion
checklist before continuing, to counter urgency bias.

---

## COULD

### R-14 — Configurable artifact paths
The enforcement hooks currently hardcode `01-intake/`, `03-panels/`, `04-spec/`. Making these
configurable would let a repo dogfood FORGE without root-level numbered folders.

---

## Deliverables (MUST)

- D1: Enforcement hook suite (R-01, R-07, R-08, R-09)
- D2: FORGE skill orchestration (R-02, R-03, R-04, R-05, R-06)
- D3: Observatory dashboard (R-10, R-12)
- D4: Documentation system (R-11)
- D5: Integration layer + combined gate (R-13)
