# RAPID — Spec (implementation register)

> Each section derives from a requirement in `01-intake/PRD-ENHANCED.md` and names the
> artifact that implements it. `.rapid/TASKS.json` references these section ids as `spec_ref`.

## S-01 — Phase-gate hook  (← R-01)
`tools/phase-gate-hook.sh`. PreToolUse on `Write|Edit`. Parses the written STATE.json content
from stdin JSON, reads the target phase, and blocks (exit 2) when the prerequisite artifact
for that phase is absent (PRD-ENHANCED → synthesis → spec → EVAL+TASKS → P6_EXIT → WALKTHROUGH).

## S-02 — Watchdog protocol  (← R-02)
Spawn protocol in `skills/rapid-workflow/SKILL.md` (P6a). Separate tmux terminal; writes
`.rapid/AUDIT.json`. P6 exit assertions verify watchdog entries exist.

## S-03 — Deliverable-coverage assertion  (← R-03)
Post-decomposition step in `skills/rapid-workflow/SKILL.md`: parse PRD MUST deliverables, assert each
maps to ≥1 task, file a gap otherwise.

## S-04 — Blocking dependency graph  (← R-04)
`task-00` eval-harness is the dependency root in `.rapid/TASKS.json`; the phase gate refuses
P6 until `.rapid/EVAL/` holds test files.

## S-05 — Context-checkpoint protocol  (← R-05)
`skills/rapid-workflow/SKILL.md` R5 section: at ~200k tokens, flush state to `.rapid/` and run the
phase-completion checklist.

## S-06 — Walkthrough protocol  (← R-06)
`skills/rapid-workflow/SKILL.md` P7: explicit walkthrough steps; output `.rapid/WALKTHROUGH.md`,
enforced by S-01.

## S-07 — Continuation hook  (← R-07)
`tools/stop-hook.sh`. Synchronous Stop/SubagentStop. Logs every halt; blocks the stop with a
concrete next step when the current phase artifact is missing; loop-guard + 5-nudge escalation.

## S-08 — Module-conformance hook  (← R-08)
`tools/module-conformance-hook.sh`. PostToolUse on TASKS.json writes. Traces done tasks'
refs to anchors; writes `.rapid/CONFORMANCE.md`; files conformance gaps. Idempotent via
`.rapid/.conformance_seen`.

## S-09 — Stub scanner + ship gate  (← R-09)
`tools/stub-scan.sh` (shared net), `tools/stub-detect-hook.sh` (write-time, non-blocking),
`tools/ship-gate.sh` (P6 exit; merges stub/conformance assertions into `.rapid/P6_EXIT.json`
so S-01 blocks P7 on failure).

## S-10 — Observatory dashboard  (← R-10)
`observatory/` (Vite/TS app). Reads observe events + STATE.json; renders phase, agents,
blockers, plan completion, timeline. **Prepopulation from the plan is not yet wired** — see
gap loop.

## S-11 — Documentation system  (← R-11)
`/docs` skill + `tools/build-docs-registry.sh`, refreshed by `tools/post-write-hook.sh` on
STATE.json writes. **Automatic per-phase refresh wiring is partial** — see gap loop.

## S-12 — Test-result surfacing  (← R-12)
Eval harness output (`.rapid/EVAL/`, `.rapid/P6_EXIT.json`) surfaced into dashboard + docs.
**Surfacing into all views is not yet wired** — see gap loop.

## S-13 — Integration layer  (← R-13)
Cross-system event bus so STATE/docs/eval/dashboard update together and decision points show a
combined gate view. **This is the primary open work** (the PRD's "the gap is the integration").

## S-14 — Workflow Test Theater  (← FR-9)
`docs/workflows.json` (machine-readable user-workflow map: per node `in`/`proc`/`out`, a golden
assertion, and a bounded `exec`) is generated in P4/P5 from `04-spec/workflow.md`. `tools/workflow-runner.py`
live-drives a workflow — running each node's `exec`, threading data-out → next data-in — and streams the
trace to `.rapid/RUNS/<wf>/<run>.jsonl`, appends `.rapid/RUNS/<wf>/index.json`, and publishes
`docs/testruns.json`. `tools/observe-server.py` exposes `GET /api/runs`, `GET /api/run` (live-tail), and
`POST /api/run` (trigger). `docs/testsuite.html` renders the diagram from the map and shows, per node and in
sync, the user-facing surface (left) and the actual declared-vs-runtime data flow (right), with a per-workflow
run log. Static half (diagram + replay of `testruns.json`) deploys under `/_atlas`; the live `▶ Run` half
stays local under observe-server (the two-halves rule, S-13 / P9).
**Agent-backed nodes:** a node `exec.kind` may be `codex` (the **tester** — Codex runs/judges the test under a
sandboxed `codex exec` with a strict JSON verdict schema; `04-spec/agents/tester-codex.md`) or `human` (a guardrailed
**simulated operator** standing in for the gate human — fails safe to `hold`, never approves destructive/irreversible/
outward-facing/spends-money/deploy actions, forces `needs_real_human`; `04-spec/agents/operator-sim.md`). Every agent
node carries a deterministic `fallback`, so `--agents off`/no-Codex still completes (live ▶ Run uses `--agents auto`;
bulk republish uses `off`).

## S-15 — Project lifecycle E2E (acceptance test of the skill)  (← FR-10)
`tools/new-project.sh` is the deterministic P1 scaffold extracted as one command (structure + CONSTITUTION +
BUILD-AUTONOMY + locked PRD + `.rapid/STATE` + self-contained toolset + `atlas-init`). `tools/lifecycle-e2e.sh`
drives a fresh project through the real lifecycle in stages (`create|build|docs|deploy|verify|all`): it seeds a real
small app, builds it, populates the deck from the project's own artifacts (`tools/populate-deck.py` renders each
markdown/JSON artifact into its deck page, replacing the `atlas-stub` placeholder), deploys to a local/staging dir
(`atlas-deploy`), and **asserts the three deliverables** — documentation populated (no stub pages), local app built
(`dist/`), dev deployed (app + `/_atlas` + `env.json` dev url) — writing `.rapid/E2E.json`. Surfaced as **WF-5** in the
Test Theater (S-14): Create → Populate Docs → Build (codex tester) → Approve deploy (simulated operator, approves a
local staging deploy / would hold a real cloud one) → Deploy+verify. The full multi-agent `/rapid-workflow` build + real cloud
deploy is the separate opt-in "live" tier (gated: spends money, outward-facing).
