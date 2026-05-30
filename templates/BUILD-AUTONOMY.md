# Build Autonomy — &lt;project&gt;

> **What this is.** The per-project standing-authorization contract. The operator signs it **once at Gate 1**. With this file + `CONSTITUTION.md` + a **locked PRD** all present, the build carries **standing approval to run to completion** — no per-step check-ins for file, config, or dependency changes. It stops only for the four conditions below.
>
> **Why it exists.** A build that pauses on every `npm install`, file write, or config edit isn't autonomous — it's a chat session. This contract front-loads the trust (and the few hard limits) so the loop runs uninterrupted while the gap loop + requirements/issue tracking keep its green honest. Mirrors the operator's `~/.claude/CLAUDE.md` carve-out: act freely, stop only for the irreversible/outward/costly/undecidable.
>
> Signed at: **Gate 1 (D3 — Direction)**. Without this file present, FORGE falls back to per-step confirmation.

---

## Signature

| Field | Value |
| --- | --- |
| Project | `<project>` |
| PRD locked at | `<commit / path — e.g. 01-intake/PRD-locked.md @ <sha>>` |
| CONSTITUTION present | `<docs/CONSTITUTION.md @ <sha>>` |
| Operator | `<name>` |
| Signed (Gate 1) | `<YYYY-MM-DD>` |
| Autonomy level | **FULL — run to completion** |

A build may proceed under standing authorization **only** when all three are true: this signed file exists, `CONSTITUTION.md` exists, and a **locked** PRD exists. Missing any one → revert to per-step confirmation.

---

## Standing authorization

With this file + `CONSTITUTION.md` + a locked PRD present, the build runs to completion **WITHOUT per-file / per-config / per-dependency check-ins**. Specifically, the build is **pre-authorized** to, without asking:

- Create, edit, move, and delete files **inside the project tree**.
- Edit project config (build config, lint/test config, CI config, framework config).
- Add / remove / pin **dependencies within the pre-approved toolchain** (below).
- Install missing runtimes/toolchain via `tools/preflight.sh` (within the declared stack).
- Run build / lint / unit / e2e gates, scaffold tests, refactor, and re-run `tools/verify.sh`.
- Make every PRD-silent call as a **logged decision** (`.forge/DECISIONS.json`), not a pause.

Everything in scope is decided and logged. The build surfaces to the human **only** for a Stop Condition.

---

## Pre-approved toolchain / stack

The languages, frameworks, package managers, and runtimes the build may install and use freely. `tools/preflight.sh` probes these in **P1** and installs any missing one **within this declared stack**; it hard-fails (blocks the build) if it cannot. The build must **never** write code that routes around a missing runtime — that produces unverifiable code.

| Concern | Pre-approved | Notes / pinned version |
| --- | --- | --- |
| Language(s) | `<e.g. TypeScript, Python 3.12>` | |
| Runtime(s) | `<e.g. Node 20, CPython 3.12>` | probed + installed by preflight |
| Framework(s) | `<e.g. Next.js 16, React 19>` | |
| Package manager(s) | `<e.g. pnpm, uv>` | |
| Test / e2e | `<e.g. vitest + Playwright>` | e2e runtime + browsers installed by preflight |
| Datastore / infra | `<e.g. SQLite, local only>` | |
| Anything OUT of stack | `<adding X requires a Gate-1 amendment / operator OK>` | not auto-approved |

> Adding a dependency **outside** this stack is not covered by standing authorization — it is an interpretation the build logs, or (if high-stakes) a Stop Condition. Keep the stack tight; widen it by amending this file, not mid-build.

---

## Up-front resolved decisions

High-stakes choices settled **before** the build so they are not mid-build interrupts. Genuinely-undecidable high-stakes items are batched to the human **at Gate 1** (a *Gate-1 decision batch*) and recorded here. Anything not listed here is decided by the build and logged (see Decision protocol).

| # | Decision | Resolution | Decided by |
| --- | --- | --- | --- |
| 1 | `<e.g. auth approach>` | `<resolved value>` | operator @ Gate 1 |
| 2 | `<e.g. data persistence model>` | `<resolved value>` | operator @ Gate 1 |
| 3 | `<e.g. deployment target>` | `<resolved / deferred>` | operator @ Gate 1 |

---

## Stop conditions — the ONLY reasons to surface to the human

The build pauses and asks **only** when an action is:

1. **Destructive / irreversible** — deleting data outside the project tree, rewriting git history, `rm -rf` beyond the workspace, dropping a real database, force-pushing.
2. **Outward-facing** — `git push`, deploy, publish (npm/PyPI/registry), opening a PR to a shared branch, sending mail/messages, anything that leaves the machine or is seen by others.
3. **Spends money** — provisioning paid infra, paid API keys/usage, purchases, anything with a bill.
4. **Genuinely-undecidable high-stakes blocker** — a fork in the road the PRD does not resolve, where guessing wrong is expensive and the choice can't be cheaply reversed. (Low-stakes ambiguity is **not** a stop — it is a logged interpretation.)

Anything **not** on this list is in scope under standing authorization. When in doubt between "log it" and "stop": if it's reversible, in-tree, free, and the PRD or an obvious interpretation covers it → **log and continue.**

---

## Decision protocol

Everything outside a Stop Condition is **decided and logged**, never a mid-build pause.

- Every PRD-silent call becomes an entry in `.forge/DECISIONS.json` via
  `tools/log-decision.sh "<decision>" spec|interpretation`.
- **`basis="spec"`** — the decision follows directly from a PRD fact (no judgment added).
- **`basis="interpretation"`** — the PRD is silent and the build chose a reasonable default; flagged so a reviewer / the gap loop can revisit it.
- Logged decisions feed the **gap loop (P8)** and requirements/issue tracking, so the build's own green is audited rather than trusted naively — an `interpretation` that turns out wrong becomes a gap, not a silent assumption.
- The **only** decisions escalated to the human are the genuinely-undecidable high-stakes ones, and those are batched **before** the build starts (Gate-1 decision batch above) — not surfaced mid-run.

---

## Shared-seam contracts (gate before fan-out)

Standing authorization to fan out implementors is conditional on **every shared seam being pinned first**. (The largest observed failure: two layers agreed the API but never the DOM/test contract → 100% of e2e failed.) Before any parallel fan-out in P6, enumerate **every** seam two or more agents will share and pin each in `04-spec/contracts/` as the single source of truth both sides build against:

- [ ] **API contract** — endpoints, request/response shapes, status codes
- [ ] **DOM contract** — selectors / `data-testid` / element structure the UI and e2e both target
- [ ] **Event contract** — message types, event names, payload schemas
- [ ] **Data schema** — tables / types / serialization shared across layers
- [ ] **e2e / test contract** — the user-visible flows e2e asserts, derived from the seams above

A **GATE blocks P6 fan-out** until every shared seam has a pinned contract. e2e tests **derive from** these contracts; the conformance hook (R8) traces each module back to its seam contract. No pinned seam → no fan-out.

---

## Verification waivers

`tools/verify.sh` runs **build / lint / unit / e2e** with genuine exit codes (`set -o pipefail`, output **redirected not piped**, so a `cmd | tee` cannot mask a failure), writes `.forge/VERIFY.json`, and the **ship gate (`verification_real`)** blocks release unless every required layer is green. The build reports, per layer, what actually **ran** vs what was only **inspected**, and surfaces anything that could not be verified.

**Default: NO waivers. e2e is required to ship** — it is the point of the loop and catches what every other layer misses.

| Layer | Required? | If waived, reason |
| --- | --- | --- |
| build | **required** | — |
| lint | **required** | — |
| unit | **required** | — |
| e2e | **required** | `<none — waiving e2e requires explicit operator sign-off here, with reason>` |

> A waiver here is the **only** way a layer becomes non-blocking; it is recorded in `.forge/verify.cmds.json` `"waive"` and is visible in every ship-gate report. Waiving e2e defeats run-to-completion verification — do it only with a stated, accepted reason.

---

## Amendment

This contract is amended by re-signing at a gate (Gate 1 for a fresh build, or an explicit operator amendment mid-build for a Stop-Condition-class change such as widening the stack or waiving e2e). Mid-build, the build **proposes** an amendment as a Stop Condition; it does not self-amend.
