# RAPID — AI Build Workflow

A repeatable methodology for turning stakeholder ambiguity into tested, audited AI systems. Built over ~50 projects across AI agents, trading, climate, and education. Operationalized as Claude Code skills — every phase has a tool behind it.

## Core Principle

The agent implementing the code must never be the same agent auditing the code. When one agent does both, the builder always wins — it produces visible progress while the auditor produces invisible safety. Under pressure, invisible work gets skipped. Every enforcement mechanism in RAPID exists because prose instructions fail under pressure.

## What This Repo Contains

This repo defines **the methodology** — how RAPID works. It does NOT contain project-specific output. When RAPID runs, it generates artifacts (specs, tests, panel records, documentation decks) in the **project repo**, not here.

```
rapid-workflow/
├── skills/                            Claude Code skills (source of truth, symlinked)
│   ├── rapid-workflow/SKILL.md        The RAPID orchestrator
│   ├── expert-panel/SKILL.md          Five panel areas (Business·Technical·Design·SME·Users)
│   ├── refine/SKILL.md                Goal-directed propose→measure→keep-or-revert loop
│   ├── observe/SKILL.md               Generates the project-tailored Observatory (live build view)
│   ├── test-theater/SKILL.md          Generates the project-tailored Test Theater + coverage proof
│   ├── decision/SKILL.md              Decision & panel documentation
│   ├── docs/SKILL.md                  Documentation deck generator
│   └── workflow/SKILL.md              Alias → /rapid-workflow
│
├── docs/                              Documentation of the methodology
│   ├── architecture.html              D0–D32 interactive architecture reference
│   ├── rapid-reference.md             Text reference (all diagrams as markdown)
│   ├── methodology-deck.md            18-slide methodology walkthrough (source)
│   └── CONSTITUTION.md                Articles I–X governance
│
├── templates/                         CSS/HTML templates used by skills at runtime
│   ├── template-decision-deck.html    For /decision skill output
│   ├── template-docs-deck.html        For /docs skill output
│   └── template-docs-deck-showcase.html  Example of generated output
│
├── tools/                             Operational tooling for running builds
│   ├── observe-server.py              Live observability dashboard server (localhost:4040)
│   ├── dashboard.html                 Dashboard UI (4 themes, 2 modes)
│   └── phase-gate-hook.sh             R1 enforcement hook (blocks phase advancement)
│
├── examples/                          Example output from a real build
│   └── vision/                        What Phase 0 produces
│
├── archive/                           Superseded files kept for reference
├── CHANGELOG.md                       Version history
└── README.md                          You are here
```

### Skills are symlinked to Claude Code

The `skills/` directory is the source of truth for all skill definitions. Each is symlinked into `~/.claude/skills/` so Claude Code finds them:

```bash
ln -sf ~/projects/workflow/skills/rapid-workflow    ~/.claude/skills/rapid-workflow
ln -sf ~/projects/workflow/skills/decision ~/.claude/skills/decision
ln -sf ~/projects/workflow/skills/docs     ~/.claude/skills/docs
ln -sf ~/projects/workflow/skills/workflow  ~/.claude/skills/workflow
```

This means `git diff` shows skill changes, cloning the repo gives you the skills, and Claude Code still finds them at the expected path.

## The Pipeline

```
P0:Vision → P1:Structure → P1b:Decompose → [G0] → P2:Panels → P3:Research → [G1] →
P4:Spec → P5:Tasks → P5b:Deepen → P5c:Mockups → [G2] → P6:Build → P7:Test → P8:Gaps ↻ [G3] →
P9:Deploy → P10:Pulse ↻
```

**12 phases. 4 human gates. Five-lead build team. Tiered per-dimension review. 15 Compound Engineering integrations.**

| Arc | Phases | What happens |
|---|---|---|
| **Understand** | P0–P3 | Vision sets the lens, PRD decomposed, five expert panels challenge requirements, research grounds decisions |
| **Specify** | P4–P5c | Spec derived from PRD with maintained diff, tasks decomposed, eval harness locked, spec deepened, hi-fi mockups approved before build |
| **Execute** | P6–P9 | Five-lead build (planner · coder · tester · reviewer · watchdog), tiered review, gap loop, deploy |
| **Compound** | P10 | Post-ship pulse feeds next build's P0 — each build starts smarter |

## Quick Start

### View the architecture
```bash
open docs/architecture.html
```

### Run the live dashboard during a build
```bash
python3 tools/observe-server.py    # opens localhost:4040
```

### Install the phase gate hook
Add to your project's `.claude/settings.json`:
```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Write|Edit",
      "command": "bash ~/projects/workflow/tools/phase-gate-hook.sh"
    }]
  }
}
```

### Start a build
```
/rapid-workflow "your product idea or PRD path"
```

### Run the test suite (Workflow Test Theater)
Each user workflow is a runnable, recorded test — pick an input, follow the diagram node by node
with two synced panels (what the user sees · the real data-in/processing/data-out), with a Codex
tester and a guardrailed simulated-operator at the gates. Driven by `docs/workflows.json`.
```bash
python3 tools/workflow-runner.py --wf WF-1 --preset math-tutor   # one workflow, Codex tester
python3 tools/workflow-runner.py --all --agents off              # all, deterministic (CI/offline)
# then open docs/testsuite.html (served by observe-server) for the live theater + run log
```

### End-to-end acceptance test (create a new project, prove it ships)
WF-5 / `tools/lifecycle-e2e.sh` creates a fresh project via the skill, then asserts the three
deliverables — **docs populated, local app built, dev deployed** — writing `.rapid/E2E.json`.
```bash
tools/new-project.sh --name myproj --idea "..."                 # scaffold (deterministic P1)
tools/lifecycle-e2e.sh --stage all --name myproj                # create→docs→build→deploy→verify
```

## Key Design Decisions

| Decision | Why |
|---|---|
| **Separate builder from auditor** | Same agent can't serve both honestly under pressure |
| **Hooks over prose** | Phase gate hook blocks advancement; prose gets skipped |
| **task-00 is the eval harness** | Blocking dependency, not a skippable step |
| **Five-lead build team during P6** | planner · coder · tester · reviewer · watchdog — each in its own terminal; roles can't collapse into each other |
| **Tiered per-dimension review** | Reviewer fans out a subagent per dimension (correctness · security · …); confidence gating prevents noise |
| **Compound learning** | LEARNINGS.md carries forward; each build starts where the last left off |

## Lineage

- **Karpathy** autoresearch — eval-first, keep-or-revert ratchet
- **Beck** TDD (2002) — tests before code, owned by separate concern
- **Zaharia et al.** Compound AI Systems (2024) — inter-stage assertions, model routing
- **Every Inc.** [Compound Engineering](https://github.com/everyinc/compound-engineering-plugin) — 15 integrated capabilities
- **SiWarlock** [TDD Agent-Crew Scaffold](https://github.com/SiWarlock/claude-code-tdd-agent-crew-scaffold) — cross-pollination comparison
- **Rapid retro (R1–R6)** — enforcement mechanisms from real build failures

## Version

**v2.5.0** — Full Compound Engineering integration (15 capabilities), 9-reviewer tiered review, spec deepening pass, dogfood QA, simplification pass, compound refresh.

See [CHANGELOG.md](CHANGELOG.md) for full history and [ROADMAP.md](ROADMAP.md) for the running list of future features.

## Author

Johnny Chung — AI Engineering Lead
