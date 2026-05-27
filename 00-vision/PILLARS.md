# Pillars

The four pillars every SuperBuilders project must clear before it ships. Each pillar is a question that panels ask of the build — not a checkbox to tick.

> Panels in Phase 2 explicitly review the PRD through these four pillars. Spec sections cite the pillar they serve. Walkthroughs flag any decision that weakens a pillar.

---

## 1. Mission Alignment

**Does this build serve the learner's growth, not engagement metrics?**

- Would Joe Liemandt sign off on this feature?
- If we removed all gamification, would the learning still hold?
- Is the success metric a learning outcome — or a vanity number?
- Does the product respect the learner's time?

*Violation example:* a streak counter that pulls children back without measurable learning gain.

---

## 2. Pedagogical Rigor

**Is the instructional design defensible to a Direct Instruction scholar?**

- Engelmann sequencing: mastery before advancement
- Scaffolding made explicit, not implicit
- Worked examples → faded practice → independent practice
- No shortcut paths that bypass the underlying concept
- Cited research backs each instructional choice

*Violation example:* a hint system that gives away the answer when a child stalls, instead of re-teaching.

---

## 3. Build Quality

**Is this production-grade or demo-grade?**

- Tested (golden path + named edge cases, derived from `WORKFLOW.md`)
- Typed end-to-end (no untyped boundaries between layers)
- Observable (per-session trace, per-action event, queryable in <10s)
- Reversible (the user can undo / preview)
- A paying customer would trust this build with their child

*Violation example:* a tutor that crashes mid-lesson and offers no recovery.

---

## 4. Integration Readiness

**Does this fit cleanly into Alpha School's Primer SDK from day one?**

- Data contracts conform to Primer spec
- Telemetry events use Primer naming conventions
- Auth flow uses Primer identity, not a parallel system
- Deployable as a Primer module without rewrite
- API surface is documented in `04-spec/INTERFACES.md`

*Violation example:* a custom identity provider that requires Primer to rebuild auth around us.

---

## How the pillars are used

- **Panels (Phase 2)** cite the pillar(s) each finding affects
- **Spec sections (Phase 4)** declare which pillar they serve in the frontmatter
- **Gaps (Phase 7)** are classified in part by which pillar they weaken
- **Retrospectives** ask: "Which pillar got the least attention this cycle?"
