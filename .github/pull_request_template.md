<!-- Rapid PR — passes the alignment & quality gate (templates/PR-CHECKLIST.md). -->

**What & why:** <one line — the task and the requirement it serves>

**Traces to:** PRD `<FR-/TR-…>` · Spec `<S-NN>` · Areas `<Business/Technical/Design/SME/Users>`

### Alignment — PRD & spec
- [ ] Traces to ≥1 enhanced-PRD requirement and ≥1 spec section; in scope (no scope creep)
- [ ] `04-spec/TRACE.md` row complete (requirement → spec → node → mock → task → eval)
- [ ] Any new requirement is a **versioned amendment** (not a silent PRD edit) + `DIFF.md`/`DECISIONS.json` updated

### Alignment — expert panels
- [ ] The touched area's panel asks are honored/addressed; no panel risk reintroduced (`03-panels/synthesis.md`)
- [ ] Divergence from a panel rec is logged as a decision; Design PRs match the G2 comp

### Constitution & pillars
- [ ] No Article I–V violation; serves ≥1 pillar; any VI–X override logged

### Quality
- [ ] Tests extended (harness never edited to pass); **function-level coverage** for touched surfaces (`untouched_functions==0`)
- [ ] No stubs in MUST modules; watchdog drift = CLEAN; harness green (keep-or-revert); reviewers APPROVE

> Reviewer asserts; the **watchdog independently verifies** the PRD/spec/panel claims. Full checklist: `templates/PR-CHECKLIST.md`.
