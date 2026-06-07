---
name: test-theater
description: >
  Build a project-tailored **Workflow Test Theater** — the test suite as the user
  workflows made runnable. When applied to a project it INSPECTS that project (its
  workflow map, its screens, and the REAL function inventory of every page/module) and
  GENERATES the runnable workflows, the node-by-node theater, and a coverage matrix that
  proves every function is exercised — not a copied generic shell. The deterministic
  invariant never changes: each workflow node's `exec` IS the walkable/recorded form of
  that node's immutable eval test — one source of truth shared by the locked harness and
  the theater, so tests can't drift from the spec. Acceptance is provable, not asserted:
  `untouched_functions == 0`. Use at P4/P5 (derive), P7 (record), P9 (deploy). Triggers:
  "build the test theater", "generate the test suite for this project", "make the
  workflows runnable", "prove every function is tested", "/test-theater".
---

# /test-theater — the Dynamic Test Theater Builder

> Plain English: this turns the project's user workflows into a test suite you can
> *watch run* — pick an input, walk the flow node by node, and see both what the user
> sees and the real data moving underneath. It also proves the suite is complete: every
> function on every page is touched, or it tells you which ones aren't.
>
> **Technically:** it derives `docs/workflows.json` from `04-spec/workflow.md`, parses
> the built code for a function inventory, builds a coverage matrix, generates a tailored
> `docs/testsuite.html`, and wires `workflow-runner.py` to replay + record. Node `exec`
> == eval test (one source of truth).

## When to use

- **P4 — Derive.** As the workflow map (`workflow.md`) is written, emit its machine form (`workflows.json`) so the theater and the eval harness are born from the same map.
- **P5 — Lock.** Wire each node's `exec` to the immutable `task-00` eval test, so the runnable test and the locked test are one definition.
- **P7 — Record.** Replay every workflow node-by-node against the live app; record the runs; compute coverage.
- **P9 — Deploy.** Ship the theater next to the product at `/_atlas`, with the static `testruns.json` fallback so it works even with no server.
- Standalone, on any app with a declared user-journey map — the theater is product-agnostic.

## Core thesis — the test suite IS the workflows, so it can't drift

A test suite written *separately* from the spec drifts from the spec within a week — the code changes, the tests calcify, and the gap between "what we test" and "what we built" is invisible until production. Rapid closes that gap structurally with two moves:

1. **One source of truth.** Each user-journey node in `workflow.md` becomes (a) an immutable eval test in `.rapid/EVAL/` (arrange from `in`, act from `proc`, assert on `out`) **and** (b) a runnable `exec` in `workflows.json`. These are not two definitions of the same thing — the node's `exec` *is* the walkable, recorded form of its eval test. You cannot change the test without changing the workflow, and vice versa.
2. **Completeness is provable, not asserted.** "We have good coverage" is a claim. **`untouched_functions == 0`** is a proof: enumerate every function on every page/module, map each to a node/test, and surface any function no workflow exercises as a gap. A function nothing touches is either dead code (delete it) or an untested path (test it) — never silently "covered."

The theater makes the test *legible*: walk the flow node by node with two synced panels — **what the user sees** and **the real data-in / processing / data-out** — so a failing test points at the exact node and the exact data, not a stack trace.

## Fixed vs. dynamic — what the skill must NOT reinvent, and what it composes

| Layer | **Fixed** (the deterministic invariant — identical every project) | **Dynamic** (composed from THIS project) |
|---|---|---|
| Source of truth | Each `workflows.json` node's `exec` == that node's immutable eval test (`.rapid/EVAL/`); change one ⇒ change both | The nodes themselves (from this project's `workflow.md`) |
| Node shape | `{ id, in, proc, out, golden, view, exec }`; data-out of node N threads into data-in of node N+1 | The in/proc/out, the golden assertion, the surface, the command — all project-specific |
| Runner | `tools/workflow-runner.py` replays a workflow's nodes in sequence → `.rapid/RUNS/<wf>/<run>.jsonl` + `index.json` → publishes `docs/testruns.json` (≤25 runs/wf) | The `exec` commands point at THIS project's real test/e2e/UI surface |
| Agent nodes | Two personas on one engine (`codex exec`): a **codex tester** and a **simulated operator** at gates; each guarded by a JSON output schema, read-only/sandboxed exec, and a **deterministic `fallback`** so the run completes with no codex | The personas' project context; which gate nodes need a simulated operator |
| Refresh | The theater polls `testruns.json` incrementally (same poll-since style as the Observatory) and falls back to the static file when no server | The poll target if tuned |
| Acceptance | `untouched_functions == 0` over the real function inventory | The inventory itself (this project's pages/modules) |

The rule: **never reimplement the invariant or the runner; always regenerate the workflows, the inventory, the matrix, and the theater from the project.**

## Construction protocol — the skill's core loop (this is what "builds itself" means)

**1. Inspect the project.** Read, do not assume:
- `04-spec/workflow.md` → every user-journey node (`in`/`proc`/`out`), its branches (edge cases) and failure/recovery paths. This is the authoritative test plan.
- `04-spec/screens.md` (UI projects) → the surfaces and their `data-testid`/roles, so a node's `view` can point at the real screen.
- **Parse the built code → the function inventory.** Walk the project's pages/modules and enumerate every function/handler/exported symbol (per page, per module). This is the denominator for the coverage proof — derived from the code that exists, not a wish-list.
- `04-spec/agents/tester-codex.md`, `operator-sim.md` → the agent personas the runner drives.

**2. Generate `docs/workflows.json`.** One entry per workflow; per node `{id, in, proc, out, golden, view, exec}`. Thread each node's data-out into the next node's data-in. Point each `exec` at THIS project's own test/e2e command or UI driver — never a real `/rapid-workflow` build (bounded by construction: seconds-scale commands only). Each `golden` is the workflow's end-to-end success assertion.

**3. Wire node `exec` ⇒ eval test (the invariant).** For each node, its `exec` must be the runnable form of the same assertion the immutable `task-00` eval test makes (arrange/act/assert from in/proc/out). If P5 hasn't locked the harness yet, this skill emits the node tests *as* the harness seed; if it has, this skill binds to it. One definition, two faces.

**4. Build the coverage matrix.** Map every function in the inventory → the node(s)/test(s) that exercise it. Compute `untouched_functions` = inventory − touched. Write `.rapid/COVERAGE.json` (per page: functions, touched, untouched) and the human view into the theater. **`untouched_functions != 0` is a P6/P7 blocker** — each untouched function is triaged (dead → delete; path → add a node/test), never waived silently. Log what was dropped if anything is.

**5. Generate the tailored theater.** Fill `docs/testsuite.html` from `workflows.json` + the coverage matrix: the workflow picker, the node-by-node walk with the two synced panels (what-the-user-sees · the real in/proc/out), the gate stops (simulated operator), the run log, and the coverage view — all derived from THIS project's workflows and surfaces. Keep the deterministic spine (poll `testruns.json` incrementally; static-file fallback; unified header).

**6. Wire + record.** `workflow-runner.py` replays each workflow (live `--input`/`--preset`, or `--publish-only` to rebuild `testruns.json`). Confirm the codex tester + simulated-operator nodes run when `codex` is present and fall back deterministically when it isn't — the run must complete either way.

**7. Verify (acceptance — see below).**

## The two synced panels (why the theater, not just a pass/fail log)

For each node the theater renders, side by side:
- **What the user sees** — the node's `view` (the real screen/surface, or a faithful depiction of it).
- **The real data-in / processing / data-out** — the actual `in` threaded from the prior node, the `proc`, and the `out` that threads onward.

A red node shows *both* its rendered state and its data, so failure localizes to a node + a value instead of a stack trace. This is what makes the suite legible to a human reviewer and to the gap loop.

## Output contract

- `docs/workflows.json` — the per-project runnable workflows (the single map the theater, the per-node breakdown, and the eval tests all derive from).
- `docs/testsuite.html` — the generated, project-tailored theater (dark theme, unified header).
- `docs/testruns.json` — the published static run log (≤25 runs/wf), the no-server fallback.
- `.rapid/RUNS/<wf>/{<run>.jsonl,index.json}` — the recorded node-by-node traces.
- `.rapid/COVERAGE.json` — the function inventory, touched/untouched per page, and the `untouched_functions` count.
- `.rapid/EVAL/` binding — each node's `exec` tied to its immutable test.
- A line in `MEMORY.md`: `[ts] /test-theater — <W> workflows, <N> nodes, coverage <touched>/<total> (untouched=<k>)`.

## Verification & acceptance (the watchdog for this skill)

- **`untouched_functions == 0`** over the real inventory — or every exception is named and triaged (no silent truncation, no top-N cap without a logged note).
- **One source of truth holds.** Pick a node; confirm its `exec` and its `.rapid/EVAL/` test make the same assertion. If you can change one without the other, the invariant is broken.
- **Every node is walkable.** Each node renders in the theater with both panels and an honest pass/fail; the run threads data end-to-end (node N's out == node N+1's in).
- **Completes with no codex.** Run with `codex` absent; the deterministic fallbacks carry every agent node to completion.
- **No-server fallback.** Load the theater with no `/api` available; it renders from `testruns.json` with zero console errors.
- **Tailored, not copied.** The workflows, nodes, and coverage matrix match THIS project — diff against the kit's demo to prove it isn't the generic shell.

## Anti-patterns

- **Writing tests separately from the workflow.** Two definitions drift; the whole point is one source of truth (node `exec` == eval test).
- **Claiming coverage instead of proving it.** "Looks well-covered" is not `untouched_functions == 0`. Enumerate the real inventory; surface the gaps.
- **Waiving untouched functions silently.** Each is dead code or an untested path — triage it, log it; never let a top-N or a sampling cap quietly hide the tail.
- **Unbounded `exec`.** A node that triggers a real build (minutes) instead of a seconds-scale command breaks "bounded by construction."
- **A theater that can't fail.** If a node has no honest red state, it's a demo, not a test.
- **Copying the kit's `testsuite.html`.** That's the static shell this skill replaces — generate from the project's workflows or new surfaces silently fall out of the suite.

## Relationship to Rapid & lineage

Pairs with **[[observe]]** (the live-build surface) — together "watch the build, then prove it works"; they share the JSONL/poll-since plumbing and the unified header, keep them in lockstep. The eval-harness binding is the **[[refine]]** keep-or-revert ratchet's contract (only verified improvement advances). Lineage: tests-from-the-spec is Beck's TDD with the test surface owned by a separate concern (the workflow map, not the implementing agent — Karpathy's "prepare.py is read-only"); the workflow-state-machine→test mapping is the Compound-AI inter-stage-assertion idea applied to the user journey; `untouched_functions == 0` is the no-test-theater Constitution article made mechanical.
