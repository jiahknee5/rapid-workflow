# Roadmap — Future Features

A running list of features and improvements not yet built. Append here as ideas land;
move items to [CHANGELOG.md](CHANGELOG.md) when shipped. Newest at the top of each section.

## Workflow Test Theater (`docs/testsuite.html`)

- **Full live `/forge` E2E tier.** Today the lifecycle suite (WF-5) runs the deterministic plumbing (scaffold → populate → build → local deploy). Add an opt-in tier that runs a real multi-agent `/forge` build to completion + a real cloud dev deploy. Gated: spends money, hours, outward-facing.
- **Playwright-backed `codex` exec kind.** The Codex tester currently runs bounded shell commands. Add an exec kind that drives the real app UI (Playwright) so the tester can assert user-visible behavior, not just command exit codes.
- **Perspective-diverse verifiers.** For high-stakes nodes, run N Codex testers with distinct lenses (correctness / security / repro) and require a majority, instead of a single verdict.

## Project lifecycle E2E (`tools/lifecycle-e2e.sh`, WF-5)

- **Real cloud dev-deploy target.** Wire the deploy stage to a real dev target (Vercel/Railway/etc.) behind an explicit flag + operator approval, so the simulated-operator gate hands off to a real human for the outward-facing step.
- **Richer Enhanced-PRD generation.** `prd-enhanced.html` is populated from a hand-written structured fixture. Generate the BR/FR/TR pyramid + traceability matrix from the base PRD programmatically (or via a P1b `claude -p` pass).

## Atlas deck build (`tools/populate-deck.py`, `tools/atlas-init.sh`)

- **`cost.html` section markup.** The cost page is project-branded but still a raw data-table layout. Wrap Overview / Per-step / Per-session in `.section[id]` blocks so the sidebar TOC lists them like the prose pages.
- **`home.html` static sections.** The hub renders its cards at runtime from JSON. Add static `.section[id]` fallbacks so it degrades gracefully with JS off / slow fetches.
- **Auto-fill nav source links.** Populate `env.json` `source.github` (and dev/prod) from the project's `forge.yaml` / git remote during `atlas-init`, instead of leaving placeholders.

---

*Started 2026-06-01 alongside the Workflow Test Theater + lifecycle-E2E work.*
