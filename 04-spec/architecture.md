# FORGE — Architecture (component register)

> Component ids referenced by `.forge/TASKS.json` as `arch_ref` (optional).

## C-01 — Enforcement hooks
The deterministic layer wired into global Claude Code config via `tools/install-hooks.sh`:
PreToolUse (`phase-gate-hook.sh`), PostToolUse (`post-write-hook.sh`,
`module-conformance-hook.sh`, `stub-detect-hook.sh`), and synchronous Stop/SubagentStop
(`stop-hook.sh`). Implements R-01, R-07, R-08, R-09.

## C-02 — FORGE skill
`skills/forge/SKILL.md` — the phase pipeline, role separation, watchdog spawn, checkpoint and
walkthrough protocols. Implements R-02, R-03, R-04, R-05, R-06.

## C-03 — Observatory
`observatory/` — self-contained dashboard over observe events and STATE.json. Implements
R-10, R-12 (surfacing side).

## C-04 — Documentation system
`/docs` skill + `tools/build-docs-registry.sh` — generates the docs deck from build state.
Implements R-11.

## C-05 — Eval harness
`task-00` immutable tests under `.forge/EVAL/` — the dependency-graph root and source of
truth for "done." Implements R-04 (root), R-12 (data).

## C-06 — Gap loop + GitHub externalization
`.forge/GAPS.json` (in-build truth) + `tools/gaps-to-issues.sh` (externalize to GitHub) +
`tools/ship-gate.sh` (blocking gate). The feedback loop that ties R-08/R-09 findings to
resolution. Implements R-13 (in part).
