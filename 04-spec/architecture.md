# RAPID — Architecture (component register)

> Component ids referenced by `.rapid/TASKS.json` as `arch_ref` (optional).

## C-01 — Enforcement hooks
The deterministic layer wired into global Claude Code config via `tools/install-hooks.sh`:
PreToolUse (`phase-gate-hook.sh`), PostToolUse (`post-write-hook.sh`,
`module-conformance-hook.sh`, `stub-detect-hook.sh`), and synchronous Stop/SubagentStop
(`stop-hook.sh`). Implements R-01, R-07, R-08, R-09.

## C-02 — RAPID skill
`skills/rapid-workflow/SKILL.md` — the phase pipeline, role separation, watchdog spawn, checkpoint and
walkthrough protocols. Implements R-02, R-03, R-04, R-05, R-06.

## C-03 — Observatory
`observatory/` — self-contained dashboard over observe events and STATE.json. Implements
R-10, R-12 (surfacing side).

## C-04 — Documentation system
`/docs` skill + `tools/build-docs-registry.sh` — generates the docs deck from build state.
Implements R-11.

## C-05 — Eval harness
`task-00` immutable tests under `.rapid/EVAL/` — the dependency-graph root and source of
truth for "done." Implements R-04 (root), R-12 (data).

## C-06 — Gap loop + GitHub externalization
`.rapid/GAPS.json` (in-build truth) + `tools/gaps-to-issues.sh` (externalize to GitHub) +
`tools/ship-gate.sh` (blocking gate). The feedback loop that ties R-08/R-09 findings to
resolution. Implements R-13 (in part).

## C-07 — Workflow Test Theater
`docs/workflows.json` (the generated workflow map) + `tools/workflow-runner.py` (live-drive runner;
streams `.rapid/RUNS/<wf>/<run>.jsonl`, publishes `docs/testruns.json`) + the `/api/runs`,
`/api/run`, `POST /api/run` endpoints on `tools/observe-server.py` + `docs/testsuite.html` (diagram +
synchronized user-view / data-flow theater + run log). Turns the user workflows (C-02 / users.html) into
runnable, recorded tests over the eval harness (C-05) and live surfaces (C-03). Implements FR-9.

## C-08 — Project lifecycle E2E
`tools/new-project.sh` (deterministic P1 scaffold = "create a new project using this skill") +
`tools/lifecycle-e2e.sh` (staged create→build→docs→deploy→verify harness that asserts the three deliverables and
writes `.rapid/E2E.json`) + `tools/populate-deck.py` (renders a project's own markdown/JSON artifacts into its deck
pages). Surfaced as WF-5 in the Test Theater (C-07). The acceptance test of the skill itself. Implements FR-10.
