# Rapid PR Checklist — alignment & quality gate

> Every PR in a Rapid build passes this checklist before merge. It is not a courtesy —
> it is the **per-PR enforcement** of the same alignment the planning phase locks at G2:
> a PR must trace to the locked PRD/spec, honor the expert panels' findings for the area
> it touches, and clear the quality bar. The **reviewer** lead fills it; the **watchdog**
> verifies the alignment claims against `04-spec/` and `03-panels/`. An unchecked box is a
> blocked merge.

**PR:** `<task-id> — <title>`  ·  **Touches surfaces:** `<S-IDs>`  ·  **Areas:** `<Business/Technical/Design/SME/Users>`

---

## 1 · Alignment with the PRD & spec  *(does this build the agreed thing?)*
- [ ] Traces to **≥1 requirement** in `01-intake/PRD-ENHANCED.md` — IDs: `<FR-/TR-…>`
- [ ] Implements **≥1 spec section** in `04-spec/spec.md` — refs: `<S-NN>` *(commit msgs use `[SPEC §X.Y]`)*
- [ ] **In scope** — every changed file maps to a requirement/spec; no work that serves no pillar (scope creep)
- [ ] `04-spec/TRACE.md` updated so the requirement → spec → node → mock → task → eval row is complete
- [ ] If a **new requirement** emerged: it's a **versioned amendment** to the enhanced PRD (not a silent edit), `01-intake/DIFF.md` + `DECISIONS.json` updated, and (if PRD-level) flagged for the operator at G3

## 2 · Alignment with the expert panels  *(does it honor what the experts asked for?)*
- [ ] For each **area this PR touches**, the relevant panel's **asks are honored or explicitly addressed** — `03-panels/synthesis.md` + `roster.json`
- [ ] No panel **risk** (especially a BLOCKER/divergent one) is reintroduced or left unmitigated
- [ ] If the PR **diverges** from a panel recommendation, the reason is logged as a decision (`basis:"panel"`)
- [ ] **Design** PRs match the G2-approved comp (`04-spec/mocks/`); **Users** PRs preserve the persona scenarios that became tests

## 3 · Constitution & pillars  *(is it allowed, and does it matter?)*
- [ ] No **Article I–V** violation (truthfulness, user safety, data handling, reversibility, scope)
- [ ] Any **Article VI–X override** carries an explicit `# OVERRIDE` + a log entry
- [ ] Serves **≥1 pillar** (`00-vision/PILLARS.md`)

## 4 · Quality  *(the writer-is-never-the-auditor bar)*
- [ ] Tests **added/updated**; the immutable harness is **extended, never edited to pass**
- [ ] **Function-level coverage** for every touched surface — `untouched_functions == 0` (P7 acceptance)
- [ ] **No stubs** in MUST modules (R9 / `stub-scan.sh` clean)
- [ ] Watchdog drift verdict = **CLEAN** (`.rapid/AUDIT.json`) — checked against spec/architecture, not just the diff
- [ ] Keep-or-revert: the harness is **green** after this change (no regression)
- [ ] Tiered review: all reviewer dimensions **APPROVE** (or only LOW-confidence objections) — `.rapid/REVIEW.json`

## 5 · Docs & observability
- [ ] Docs stay live (post-write hook / `CHANGES.md`); `docs.json` registry current
- [ ] The PR's work is visible in the **Observatory** (PR_SUBMITTED/PR_MERGED messages, worktree/branch on SPAWN)

---

**Merge rule:** sections 1–4 must be fully checked. The reviewer asserts; the **watchdog independently verifies** the PRD/spec/panel alignment claims (it reads `04-spec/` and `03-panels/`, not the PR author's word). A claim the watchdog can't verify blocks the merge.
