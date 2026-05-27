# Changelog

All notable changes to Johnny's AI Build Workflow are documented here.

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
