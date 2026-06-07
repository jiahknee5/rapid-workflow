# Vision

> One page. Read first by every panel and every spec section. The lens through which the PRD is reviewed.

## Company / Program

**Rapid** — a dynamic rapid-prototyping workflow that turns stakeholder ambiguity into tested, audited, shipped AI systems. Built over ~50 projects and operationalized as Claude Code skills: every phase, gate, and guardrail has a real script behind it, not a prose reminder.

## Project Objective

Take a stakeholder's idea and produce a **working, deployed, spec-compliant application** — with its tests, its documentation deck, and its audit trail — through a **fixed 12-phase scaffold with 4 human gates** (G0 Enhanced-PRD, G1 Direction, G2 Architecture / point-of-no-return, G3 Ship). The scaffold, the gates, and the safety mechanisms are deterministic; the pillars, panels, agent count, tests, and Constitution overrides are composed per project, so no two builds produce the same architecture. The build is the artifact; **the gap loop is the product** — each pass fits the product better, runs faster, and starts smarter than the last.

## North Star

The operator runs `/rapid-workflow <idea>`, watches the build at four gates, and walks away between them — because safety is **structural, not vigilance-dependent**. Trust model cuts hands-on operator time from ~8h to ~45m, and at each gate the operator sees evidence (sources, traceable spec, the running app, real test output, actual cost) — never "it works."

## Audience

| Who | What they care about |
|---|---|
| Operator / build lead | "Can I walk away between gates and trust what comes back?" |
| Agent swarm (planner, coder, tester, reviewer, watchdog) | "What's my contract, my seam, my blocking dependency?" |
| Stakeholder (founder, partner, course staff, customer) | "I gave a PRD — is it read back unchanged, and is what shipped what I asked for?" |
| Reviewer / auditor at a gate | "One combined view — app + tests + docs + cost + open gaps — all traceable, none claimed." |

## Constraints

- **Hooks over prose**: anything load-bearing is enforced by a hook, a blocking dependency, or a separate agent (R1 phase-gate, R7 stop-hook, R8 conformance, R9 stub-scan) — never a reminder that gets skipped under pressure.
- **Builder is never the auditor**: the agent writing code never audits it; the watchdog and reviewer are independent, and the eval harness is locked (`.rapid/EVAL/`) before any code so agents can't game their own success criteria.
- **Coder fan-out hard-capped at ≤4 subagents + 1 watchdog**: beyond 4, reviewers can't honestly review the diffs — need more parallelism, sequence two rounds.
- **Gap loop capped at 3 automatic BLOCKER/HIGH iterations**: remaining gaps surface at Gate 3 rather than looping forever.
- **e2e is required to ship**: a build cannot ship on a green it only *inspected*; `verify.sh` runs build/lint/unit/e2e as separate layers with genuine, unmaskable exit codes. "Compiles" ≠ "works."
- **Bounded by construction**: lifecycle/workflow tests exercise real plumbing against small apps with local/staging deploys only — no cloud, no paid services, no recursive `/rapid-workflow` build.
- **No routing around reality**: never shim/mock/skip-if-unavailable a missing runtime — that's a Gate-1 blocker, not something to code around.
- **Non-goals**: Rapid is the *methodology*, not a sales pitch, not a coding-style/framework deck, not a benchmark against named alternatives, and it carries no example domain's subject. The repo holds the **form**; generated artifacts live in the project repo.

## Success Signals

- **Coverage**: every MUST deliverable maps to ≥1 task, or it is a blocking gap; every completed module traces (spec_ref / prd_ref / arch_ref) to a real anchor via the conformance hook.
- **Ship gate is real**: `.rapid/P6_EXIT.json` shows all four assertions true (verification_real, no_open_stub_gaps, no_stubs_in_tree, no_open_conformance_gaps) before the phase-gate hook will advance to ship.
- **Gap-loop closure**: BLOCKER/HIGH gaps converge within 3 automatic iterations; the remainder are surfaced, classified, and visible — never silently dropped.
- **Watchable, evidenced builds**: every agent emits JSONL to `.rapid/observe/`, the live Observatory renders at localhost:4040, and each declared user workflow is drivable as a runnable test in the Workflow Test Theater — every surface derived from re-runnable files on disk, degrading honestly when the data isn't there.
- **Honest cost**: token counts exact, dollars labeled estimates from an overridable rate table.

## Out of Scope

- Any single example domain as the subject — Rapid is the workflow, not the math tutor, unit converter, or any build it produces.
- Cloud / paid / outward-facing deploys inside the bounded test tiers — those are an explicit opt-in "live" tier, gated.
- Inventing new protocols at runtime — dynamic components compose only from the documented framework library; unmapped needs are logged as gaps.
- Expanding the standing-authorization **stop set**: standing authorization widens what runs *without asking*, never what runs *without stopping* (destructive/irreversible, outward-facing, spends-money, undecidable-high-stakes remain non-overridable halts).

## See Also

- [`/CONSTITUTION.md`](../CONSTITUTION.md) — Articles I–X, the guardrails every agent operates under
- [`docs/methodology-deck.md`](../methodology-deck.md) — the full 18-slide methodology walkthrough
