# Changelog

All notable changes to Johnny's AI Build Workflow are documented here.

## [0.4.0] — 2026-05-27

### Added
- `/forge status` command — structured terminal dashboard showing phase, agents, tasks, safety, alerts, cost
- Agent heartbeat protocol — `HEARTBEAT.json` updated every 5m during P6 with per-agent status, task, progress metrics, test counts, blocker info
- Enforced `claude-peers set_summary` — mandatory on spawn + on status change, with specific format: `[FORGE {role}] {status}: {description}`
- Stall detection tightened from 15m silence to 10m stale heartbeat
- `TEST_RESULTS.md` and `P6_EXIT.json` added to state files table

### Fixed
- 6 gap fixes from autonomous build test (applied externally):
  - Gap 1: Reference project protocol — spec is authority, reference is pattern guide
  - Gap 2: Smoke test mandatory — orchestrator runs build/test directly via Bash
  - Gap 3: Code review mandatory — P7 blocked until all tasks have APPROVE verdict
  - Gap 4: Secret scanning — grep for credentials after every agent return
  - Gap 5: Phase 7 unambiguous — "Execute via Bash, not a file audit"
  - Gap 6: P6_EXIT.json enforcement — STATE.json blocked until all assertions pass

## [0.3.0] — 2026-05-27

### Added
- `/docs` skill (`~/.claude/skills/docs/SKILL.md`) — universal project documentation deck system
  - `build` — generate per-folder Reveal.js decks + master hub from project artifacts
  - `hub` — regenerate master navigation deck only
  - `status` — folder inventory with completeness indicators
  - `changelog` — show master CHANGES.md
- `docs-deck-template.html` — universal CSS template extending decision-deck-template with slide types for every forge phase: hub navigation cards, metric callouts, SVG diagram frames, state machine nodes, requirement traceability, changelog entries, split layouts
- D17 section in forge-autonomous-build.html — panel documentation corpus (per-expert + per-topic views + asks tracker)
- D18 section in forge-autonomous-build.html — documentation deck system architecture, slide types per folder, change tracking flow
- `/decision panel` subcommand — log expert panel findings with per-expert verdicts, auto-generate panels/deck.html with by-topic, by-expert, and asks tracker views
- Documentation protocol added to forge skill — every phase updates folder CHANGELOG.md, appends to CHANGES.md, regenerates decks
- `panels/`, `tests/`, `docs/` directories added to forge Phase 1 scaffold

### Changed
- `/decision` skill expanded from decision-only to decisions + panel corpus
- Forge Decision Router (D5) now auto-invokes `/decision log` for architectural/strategic decisions
- Cross-reference index updated for D17, D18

## [0.2.0] — 2026-05-26

### Added
- `/decision` skill (`~/.claude/skills/decision/SKILL.md`) — log architectural and strategic decisions as McKinsey-style Reveal.js slides with auto-regenerating index
  - `log` — add a new decision (structured YAML frontmatter + options grid + pro/con + rationale + cascade)
  - `rebuild` — regenerate `decisions/deck.html` from all `D-*.md` files, sorted by phase then date
  - `status` — print summary table of all decisions
- Decision file format: individual `decisions/D-{NN}.md` files with YAML frontmatter (id, question, phase, pillars, status, options with pros/cons, rationale, panel input, cascade impacts)
- Forge integration: Decision Router (D5) now invokes `/decision log` after resolving architectural or strategic decisions
- `decisions/` directory added to forge Phase 1 scaffold

## [0.1.0] — 2026-05-26

### Added
- Initial project scaffold: `00-vision/`, `CONSTITUTION.md`
- `deck.md` — original workflow methodology (Reveal.js source)
- `deck-v1.html` — 13-slide Reveal.js deck: 7-phase pipeline, expert lenses, spec pipeline, phase deep-dives (intake through gap loop), skills-to-decisions map, ASL case study
- `deck.html` — latest iteration of the slide deck
- `deck.pptx` — PowerPoint export
- `forge-autonomous-build.html` — FORGE system reference (D0–D16): 10-phase pipeline, 10 agents, 4 safety mechanisms, trust model, methodology provenance
- `decision-deck-template.html` — reusable decision deck template
- `/forge` skill (`~/.claude/skills/forge/SKILL.md`) — autonomous build skill implementing the full pipeline
- `/workflow` skill (`~/.claude/skills/workflow/SKILL.md`) — alias for `/forge`
