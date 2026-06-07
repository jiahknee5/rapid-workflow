---
name: refine
description: >
  A generic, goal-directed refinement loop for ANY artifact — code, a design/mockup,
  copy, a config, a prompt. Given an artifact, a goal with a measurable eval, and a
  budget, it proposes N variations, measures each against the goal, keeps the best,
  and repeats until it converges or the budget runs out — keep-or-revert so the
  artifact never gets worse. Karpathy's autoresearch loop, generalized past code.
  Use inside Rapid (P5c mockups, P6 build, P8 gaps) or standalone to iterate anything
  toward a defined bar. Triggers: "refine X to Y", "loop on this until …", "iterate
  the design to …", "tune this against a goal".
---

# Refine — goal-directed iteration loop (any artifact)

> **What it is.** One reusable loop that drives *any* artifact toward a measurable
> goal: `propose → measure → keep-or-revert → repeat`. It's the Karpathy autoresearch
> ratchet (eval-first, keep the improvement, revert the regression) lifted out of "code"
> so it works on a **mockup**, a piece of **copy**, a **config**, or a **prompt** just as
> well as on code.
>
> **Why it's a primitive, not a phase.** You don't want a new pipeline phase for every
> thing that needs iterating — you want one loop you can point at anything. Rapid calls
> this loop *inside* phases (design at P5c, code at P6, gaps at P8); you can also call it
> directly.

---

## When to use

- **A goal you can measure.** There must be an eval — a test, a metric, a rubric score,
  a screenshot diff, a human-or-agent judgment with a written bar. No eval → no refine
  (you'd just be flailing). Define the bar first.
- **Room to vary.** The artifact has more than one defensible form (a layout, an
  algorithm, a headline). If there's only one right answer, just write it.
- **Inside Rapid:** iterate **mockups** to a desirability bar (P5c), **code** to the
  immutable eval (P6), **gap fixes / optimizations** to a pillar metric (P8).

---

## The loop

```
   ┌─────────────────────────────────────────────┐
   │                                             │
   ▼                                             │
[ propose N variations ] → [ measure each vs goal ] → [ keep best if it beats current ]
                                                         │  else revert (keep-or-revert)
                                                         ▼
                                              [ converged? or budget spent? ] ──no──┘
                                                         │ yes
                                                         ▼
                                                  [ return best + the trace ]
```

1. **Frame the goal.** Write the goal as a one-line bar + the eval that scores it
   (test pass / metric ≥ X / rubric ≥ N / "judge says it clears the bar"). Record the
   current artifact's score as the baseline.
2. **Propose N variations.** Generate `N` (default 3) genuinely *different* candidates —
   not N tweaks of the same idea. Diversity is what makes the loop find something; near-
   duplicates waste the budget. For non-trivial spaces, give each candidate a distinct
   *strategy* (e.g. for a layout: density-first / hierarchy-first / motion-first).
3. **Measure each** against the eval. Same eval for all — apples to apples.
4. **Keep-or-revert.** If the best candidate **beats the current baseline**, adopt it as
   the new baseline. If none beat it, **revert** — the artifact never regresses. (This is
   the ratchet: only improvements survive.)
5. **Check convergence / budget.** Stop when: the bar is met; `K` consecutive rounds
   produce no improvement (default `K=2`); or the budget (iterations / tokens / wall-clock)
   is spent. Otherwise loop.
6. **Return** the best artifact **and the trace** — every candidate, its score, kept/
   reverted — so the choice is auditable, not magic.

---

## Inputs (the loop's contract)

| Input | What it is | Default |
|---|---|---|
| `artifact` | The thing being refined (a file, a mock, a string) | — (required) |
| `goal` | One-line bar in plain language | — (required) |
| `eval` | The scorer: a command, a metric, a rubric, or a judge prompt | — (required) |
| `N` | Variations per round | 3 |
| `budget` | Max rounds / tokens / time | 5 rounds |
| `K` | No-improvement rounds before stopping | 2 |
| `strategies?` | Distinct angles to seed the variations | inferred |

---

## Modes — same loop, different eval

| Mode | Artifact | Eval (the scorer) |
|---|---|---|
| **code** | a function / module | the immutable test harness + a perf/size metric |
| **design** | a mockup / screen | a desirability rubric + accessibility checks + (optional) a Design-panel judge + screenshot diff vs the target |
| **copy** | a headline / error msg / doc | a readability score + a clarity rubric + a judge |
| **config / prompt** | a config / system prompt | the task's own success metric on a fixed sample set |

The loop is identical; you swap the eval. That's the whole point.

---

## Convergence, honesty, and stopping

- **Never weaken the eval to "win."** If nothing beats the baseline, the honest result is
  "no improvement found" — not a moved goalpost. (Constitution Art. VII: no test theater.)
- **Diminishing returns are a stop signal, not a reason to lower the bar.** `K`
  no-improvement rounds → stop and report the best, with the trace.
- **Log what was dropped.** If the budget caps the search, say so — "explored 9 candidates
  over 3 rounds, best score 0.82, bar 0.85: did not converge." Silent truncation reads as
  success when it isn't.

---

## Anti-patterns

- **No eval** — "make it better" with no bar is flailing, not refining. Define the bar.
- **N near-duplicates** — variations that differ by a word/pixel can't out-search the space.
- **Ratchet off** — adopting a candidate that scored *worse* because it "feels" newer.
- **Goalpost drift** — quietly relaxing the eval until something passes.
- **Looping the un-loopable** — burning budget on an artifact with one correct form.
- **Hidden truncation** — stopping at the budget and reporting it as "converged."

---

## Relationship to Rapid & lineage

- **Lineage:** this is **Karpathy autoresearch** (eval-first, keep-or-revert, surgical
  variations) generalized beyond code, fused with the keep-or-revert ratchet Rapid already
  runs in P6.
- **Inside Rapid:** **P5c** refines mockups to a desirability bar; **P6** refines code to
  the immutable harness; **P8** refines gap fixes / optimization experiments to a pillar
  metric. Same primitive, three evals.
- **Not a phase.** It's a tool phases call. Adding a phase per loop is the anti-pattern;
  one loop, pointed anywhere, is the design.
