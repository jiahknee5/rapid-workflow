# Vision

> One page. Read first by every panel and every spec section. The lens through which the PRD is reviewed.

## Company / Program

**SuperBuilders Partner Project** — build production-grade AI applications under Liemandt-orbit pedagogy standards, ready for integration with Alpha School's Primer SDK.

## Project Objective

Teach **fraction equivalence** (1/2 = 2/4) to a **9-year-old** on **iPad in the browser**. Hold attention through exploration, not homework. Sessions ≤ 15 minutes.

## North Star

A child finishes the lesson and says, *"I want to do another one."*

## Audience

| Who | What they care about |
|---|---|
| Child (9, grade 3) | "Is this fun, do I understand?" |
| Parent | "Is my child learning, is it safe?" |
| Teacher | "Does this fit my classroom flow?" |
| Liemandt-orbit reviewer | "Is the pedagogy rigorous?" |
| Primer SDK integrator | "Does this drop in cleanly?" |

## Constraints

- Browser-based (no native app); Safari iPad as primary target
- Zero backend dependencies during a lesson (no live API calls in the learner session)
- Open-source friendly stack — no vendor lock-in on inference
- COPPA / FERPA compliance is binding

## Success Signals

- ≥ 80% of children complete the manipulation without adult assistance
- ≥ 70% return for a second session within 48 hours
- 0 incidents of unmoderated content reaching the learner
- 100% spec coverage of the user workflow map at test time

## Out of Scope

- Multi-grade content (this build is grade 3 only)
- Teacher dashboards (Primer SDK will provide)
- Offline mode (requires native)
- Adaptive difficulty across lessons (this lesson only)

## See Also

- [`PILLARS.md`](PILLARS.md) — the four pillars this project must clear
- [`/CONSTITUTION.md`](../CONSTITUTION.md) — guardrails every agent operates under
