# FORGE — Spec (implementation register)

> Each section derives from a requirement in `01-intake/PRD-ENHANCED.md` and names the
> artifact that implements it. `.forge/TASKS.json` references these section ids as `spec_ref`.

## S-01 — Phase-gate hook  (← R-01)
`tools/phase-gate-hook.sh`. PreToolUse on `Write|Edit`. Parses the written STATE.json content
from stdin JSON, reads the target phase, and blocks (exit 2) when the prerequisite artifact
for that phase is absent (PRD-ENHANCED → synthesis → spec → EVAL+TASKS → P6_EXIT → WALKTHROUGH).

## S-02 — Watchdog protocol  (← R-02)
Spawn protocol in `skills/forge/SKILL.md` (P6a). Separate tmux terminal; writes
`.forge/AUDIT.json`. P6 exit assertions verify watchdog entries exist.

## S-03 — Deliverable-coverage assertion  (← R-03)
Post-decomposition step in `skills/forge/SKILL.md`: parse PRD MUST deliverables, assert each
maps to ≥1 task, file a gap otherwise.

## S-04 — Blocking dependency graph  (← R-04)
`task-00` eval-harness is the dependency root in `.forge/TASKS.json`; the phase gate refuses
P6 until `.forge/EVAL/` holds test files.

## S-05 — Context-checkpoint protocol  (← R-05)
`skills/forge/SKILL.md` R5 section: at ~200k tokens, flush state to `.forge/` and run the
phase-completion checklist.

## S-06 — Walkthrough protocol  (← R-06)
`skills/forge/SKILL.md` P7: explicit walkthrough steps; output `.forge/WALKTHROUGH.md`,
enforced by S-01.

## S-07 — Continuation hook  (← R-07)
`tools/stop-hook.sh`. Synchronous Stop/SubagentStop. Logs every halt; blocks the stop with a
concrete next step when the current phase artifact is missing; loop-guard + 5-nudge escalation.

## S-08 — Module-conformance hook  (← R-08)
`tools/module-conformance-hook.sh`. PostToolUse on TASKS.json writes. Traces done tasks'
refs to anchors; writes `.forge/CONFORMANCE.md`; files conformance gaps. Idempotent via
`.forge/.conformance_seen`.

## S-09 — Stub scanner + ship gate  (← R-09)
`tools/stub-scan.sh` (shared net), `tools/stub-detect-hook.sh` (write-time, non-blocking),
`tools/ship-gate.sh` (P6 exit; merges stub/conformance assertions into `.forge/P6_EXIT.json`
so S-01 blocks P7 on failure).

## S-10 — Observatory dashboard  (← R-10)
`observatory/` (Vite/TS app). Reads observe events + STATE.json; renders phase, agents,
blockers, plan completion, timeline. **Prepopulation from the plan is not yet wired** — see
gap loop.

## S-11 — Documentation system  (← R-11)
`/docs` skill + `tools/build-docs-registry.sh`, refreshed by `tools/post-write-hook.sh` on
STATE.json writes. **Automatic per-phase refresh wiring is partial** — see gap loop.

## S-12 — Test-result surfacing  (← R-12)
Eval harness output (`.forge/EVAL/`, `.forge/P6_EXIT.json`) surfaced into dashboard + docs.
**Surfacing into all views is not yet wired** — see gap loop.

## S-13 — Integration layer  (← R-13)
Cross-system event bus so STATE/docs/eval/dashboard update together and decision points show a
combined gate view. **This is the primary open work** (the PRD's "the gap is the integration").
