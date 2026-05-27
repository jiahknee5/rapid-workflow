# Decision Deck — McKinsey-Style Decision & Panel Documentation

Two corpora in one skill: **decisions** (resolved choices) and **panel findings** (expert reviews). Both produce McKinsey-style Reveal.js decks with auto-regenerating navigation.

> Reference template: `~/projects/workflow/templates/template-decision-deck.html`
> System reference: `~/projects/workflow/docs/forge-architecture.html` (D5 decisions, D17 panel corpus)
> Integrated with `/forge` Decision Router (D5) and all expert panel skills.
> Documentation style: McKinsey aesthetic (action titles, exhibit labels, source lines) + plain-English-first pattern. Every decision summary leads with an accessible explanation, then "**Technically:**" for the precise detail.

## Invocation

```
/decision log [context]       — add a new decision, regenerate decisions/deck.html
/decision rebuild             — regenerate decisions/deck.html from all D-*.md files
/decision status              — print summary table of all decisions

/decision panel [context]     — log expert panel findings, regenerate panels/deck.html
/decision panel rebuild       — regenerate panels/deck.html from all P-*.md files
/decision panel status        — print summary of all panel runs + open asks
```

## First Actions on Invocation

1. **Find the project root.** Walk up from cwd looking for `.forge/`, `decisions/`, or `CONSTITUTION.md`. Fall back to cwd.
2. **Ensure `decisions/` directory exists.** Create it if missing.
3. **Read existing decisions.** Parse all `decisions/D-*.md` files to determine next ID and current state.

---

## The `log` Flow

### Step 1 — Collect Decision Data

If invoked with context (e.g., from a forge build where a decision was just resolved), extract the details from conversation context. Otherwise, use AskUserQuestion to collect:

- **Question**: The decision being made (phrased as a question)
- **Phase**: Which forge phase (0–9) this decision belongs to
- **Pillars**: Which project pillars this affects (from `00-vision/PILLARS.md`)
- **Options**: 2–3 options, each with name, description, pros, cons
- **Chosen option**: Which option was selected (or mark as `open`/`blocked`)
- **Rationale**: Why this option was chosen (1–2 sentences, reference panel findings)
- **Sources**: Which panels or panelists informed this decision
- **Cascade impacts**: (optional) How this decision affects spec, build, tests, timeline

### Step 2 — Write the Decision File

**Path:** `decisions/D-{NN}.md` where NN is zero-padded, incrementing from the highest existing ID.

**Format:**

```yaml
---
id: D-01
title: "Short action title for the decision"
question: "The decision question phrased as a question?"
phase: 2
phase_name: "Expert Panels"
pillars:
  - "Pillar Name"
status: decided          # decided | open | blocked
date: 2026-05-26
options:
  - name: "Option A"
    description: "Brief description"
    chosen: true
    pros:
      - "Advantage"
    cons:
      - "Disadvantage"
  - name: "Option B"
    description: "Brief description"
    chosen: false
    pros:
      - "Advantage"
    cons:
      - "Disadvantage"
rationale:
  text: "Why this option was chosen. Reference panel findings."
  sources:
    - "Technical Panel: Sarah flagged re-render cost"
panel_input:
  - panel: "Technical"
    name: "Sarah"
cascade:
  - label: "Spec Impact"
    text: "What changes in the spec"
  - label: "Build Impact"
    text: "What changes in the implementation"
---

## Additional Context

Optional freeform markdown. Not rendered in the deck — preserved as a record.
```

**YAML rules:** Always quote string values that contain colons, brackets, or special characters.

### Step 3 — Regenerate the Deck

After writing the decision file, immediately run the rebuild flow.

---

## The `rebuild` Flow

This is the core generation logic. Run after every `log` or when invoked directly.

### Step 1 — Read and Sort

1. Read all `decisions/D-*.md` files. Parse YAML frontmatter from each.
2. Sort: primary = `phase` (ascending), secondary = `date` (ascending), tertiary = `id` (ascending).
3. Read project name from `00-vision/VISION.md` (first heading or first non-empty line). Fall back to directory name.

### Step 2 — Generate `decisions/deck.html`

Write the complete HTML file from scratch. The file has this structure:

```
[DOCTYPE + head with title, fonts, Reveal.js CSS, inline styles]
[<div class="reveal"><div class="slides">]
  [COVER SLIDE — index table]
  [For each decision, sorted:]
    [DECISION SLIDE]
    [CASCADE SLIDE — only if cascade field exists with items]
[</div></div>]
[Reveal.js script + init]
```

### HTML Generation Rules

Follow these rules exactly. Use the CSS classes from the template — do not invent new ones.

**Phase label map** (for the breadcrumb nav):

| Phase | Label |
|-------|-------|
| 0 | P0 Vision |
| 1 | P1 Structure |
| 2 | P2 Panels |
| 3 | P3 Research |
| 4 | P4 Spec |
| 5 | P5 Tasks |
| 6 | P6 Build |
| 7 | P7 Test |
| 8 | P8 Gaps |
| 9 | P9 Deploy |

**Cover slide:**
- Eyebrow: `Decision Log`
- Title: `{PROJECT NAME} — Decisions Register`
- Table with class `decision-index`, columns: #, Decision, Phase, Pillar(s), Status, Date
- Each row: ID, title, phase_name, first pillar, status with dot (`green` for decided, `amber` for open, `red` for blocked), date
- Footer: `{PROJECT NAME} · Decision Log` | today's date

**Decision slide:**
- Phase breadcrumb: `<div class="phase-nav">` with one `<span class="ph">` per phase (0–9), the decision's phase gets class `active`, separated by `<span class="sep">›</span>`
- Eyebrow: `D-{NN} · {phase_name}`
- Title: the `question` field + `<span class="badge {status}">{Status capitalized}</span>`
- Pillars: `<div class="pillars">` with `<span class="pillar-tag">` per pillar
- Options grid: `<div class="options cols-{N}">` where N = number of options (2 or 3, cap at 3)
  - Each option: `<div class="option {class}">` where class is:
    - `chosen` if `chosen: true` AND status is `decided`
    - `rejected` if `chosen: false` AND status is `decided`
    - *(no extra class)* if status is `open` or `blocked`
  - Contains: `opt-name`, `opt-desc`, `pro-con` div with `.item.pro` / `.item.con` / `.item.neutral`
- Rationale box: `<div class="rationale">` with `r-label`, `r-text`, `r-source` (sources joined with " · "). Only render if rationale exists.
- Panel input: `<div class="panel-input">` with `<span class="panel-chip">{panel}: {name}</span>` per entry. Only render if panel_input exists.
- Footer: `{PROJECT NAME} · D-{NN}` | date

**Cascade slide** (only if `cascade` has items):
- Eyebrow: `D-{NN} · Downstream Impact`
- Title: `How "{title}" cascades through the build`
- `<div class="cascade">` with `<div class="cascade-item">` per entry, each having `c-label` and `c-text`
- Footer: `{PROJECT NAME} · D-{NN} cascade` | date

**Content constraints** (enforce when collecting input):
- Option descriptions: 1–2 sentences max
- Pro/con lists: 3–4 items max per option
- Rationale: 2–3 sentences max
- These limits keep slides within the 720px height budget

### Step 3 — Inline CSS

The generated `decisions/deck.html` must include the **complete CSS block** from the decision-deck-template inline in a `<style>` tag. Copy it verbatim from `~/projects/workflow/templates/template-decision-deck.html` (lines 8–107). This includes all `:root` variables, `.slide`, `.eyebrow`, `.title`, `.footer`, `.phase-nav`, `.badge`, `.options`, `.option`, `.pro-con`, `.rationale`, `.panel-input`, `.pillars`, `.cascade`, and `.decision-index` classes.

### Step 4 — Reveal.js Config

```html
<script src="https://cdn.jsdelivr.net/npm/reveal.js@5.0.4/dist/reveal.min.js"></script>
<script>Reveal.initialize({hash:true,width:1280,height:720,margin:0,minScale:0.2,maxScale:2,center:false,transition:'none',controls:true,controlsTutorial:false,progress:true});</script>
```

---

## The `status` Flow

Read all `decisions/D-*.md`, parse frontmatter, print a markdown table sorted by phase then date:

```
| #    | Decision                        | Phase      | Status  | Date       |
|------|---------------------------------|------------|---------|------------|
| D-01 | Which state management...       | P2 Panels  | Decided | 2026-05-26 |
| D-02 | API auth strategy?              | P3 Research| Open    | —          |
```

---

## Integration with Forge

This skill is invoked automatically by the forge Decision Router (D5) when an **Architectural** or **Strategic** decision is resolved. The forge orchestrator or supervisor calls `/decision log` with the decision context after resolution.

**Tactical** and **Technical** decisions are logged to `.forge/MEMORY.md` only — they are too frequent and too small for deck slides.

## When to Log a Decision (outside of Forge)

Even outside a forge build, invoke `/decision log` whenever:
- A technology choice is made (framework, library, service, model)
- An architecture direction is set (monolith vs micro, client vs server, sync vs async)
- A scope decision is made (feature cut, MVP boundary, out-of-scope declaration)
- A security or compliance trade-off is accepted
- A build-vs-buy decision is made
- A panel finding changes the direction of the project

---

# Panel Documentation Corpus (D17)

Every expert panel invocation produces a persistent, navigable record organized by expert and by topic. Two views: **by-topic** (all experts on the camera pipeline) and **by-expert** (what did Marcus say across all reviews?).

## The `panel` Flow

### Step 1 — Collect Panel Data

After any expert panel skill finishes (technical-expert-panel, business-expert-panel, user-panel, or any project-specific panel), extract the findings. If invoked with context from a panel that just ran, parse it directly. Otherwise, ask for:

- **Panel type**: which panel skill (technical, business, SME, user, etc.)
- **Topic**: what was reviewed (1-line description)
- **Phase**: which forge phase (typically 2 for panels)
- **Pillars**: which project pillars this review touched
- **Each expert's findings**: name, lens, verdict, finding (1–3 bullets), asks (concrete action items)
- **Synthesis**: convergent findings, divergent findings, recommended action

### Step 2 — Write the Panel Record

**Path:** `panels/P-{NN}.md` where NN is zero-padded, incrementing from the highest existing ID.

**Format:**

```yaml
---
id: P-01
panel_type: "technical-expert-panel"
topic: "Camera pipeline architecture"
phase: 2
phase_name: "Expert Panels"
date: 2026-05-26
pillars:
  - "Build Quality"
  - "Correctness"
experts:
  - name: "Sarah"
    lens: "Senior Frontend"
    verdict: approve       # approve | caution | block | pass
    finding: "React 19 concurrent features handle this well."
    asks: []
  - name: "Marcus"
    lens: "iPad/Mobile"
    verdict: caution
    finding: "Canvas touch events on iPad Safari drop frames above 4 objects. Use CSS transforms with will-change instead."
    asks:
      - "Prototype CSS transforms approach"
      - "FPS test on real iPad Air, not simulator"
  - name: "Lin"
    lens: "Performance"
    verdict: caution
    finding: "Canvas repaints on every drag. 60fps of full-canvas clears."
    asks:
      - "Measure actual FPS on real device"
  - name: "Alex"
    lens: "SWE Skeptic"
    verdict: pass
    finding: ""
    asks: []
convergent:
  - "Touch targets must be >=44px (Apple HIG)"
  - "Test on real iPad hardware, not just simulator"
divergent:
  - "Canvas vs CSS transforms for the manipulative"
recommended_action: "Prototype both approaches. FPS test on a real iPad Air before committing."
decisions_spawned:
  - "D-03"            # back-reference to decision deck if this panel triggered a decision
---

## Notes

Optional freeform context. Not rendered in the deck.
```

**Expert verdict classification:**
- **approve** (green) — No objection on this topic
- **caution** (amber) — Flag raised, has concrete asks
- **block** (red) — Stops the build, requires resolution before proceeding
- **pass** (gray) — Nothing useful to add (honest signal, not filler)

### Step 3 — Regenerate the Panel Deck

After writing the panel record, regenerate `panels/deck.html`. Read all `panels/P-*.md` files, parse frontmatter, and generate the complete Reveal.js deck.

**Deck structure — four slide groups:**

#### Group 1: Cover Slide
- Eyebrow: `Expert Panel Corpus`
- Title: `{PROJECT NAME} — Panel Findings`
- Table with class `decision-index`, columns: #, Topic, Panel Type, Experts, Open Asks, Date
- "Experts" column shows count (e.g., "6/8 spoke" — those who didn't pass)
- "Open Asks" column shows count of all unresolved asks across experts, colored amber if >0
- Footer: `{PROJECT NAME} · Panel Corpus` | today's date

#### Group 2: By-Topic Slides (one per panel invocation, sorted by date)
- Phase breadcrumb: same as decision slides, current phase gets `active`
- Eyebrow: `P-{NN} · {panel_type}`
- Title: `{topic}`
- Pillars row
- Expert grid: render each expert as a card in a 2-column or 3-column layout (use `cols-2` for ≤4 experts, `cols-3` for 5+, wrapping is fine)
  - Each expert card uses the `.option` class with verdict-based styling:
    - `approve` → `.option.chosen` (green border)
    - `caution` → `.option` with `border-color: var(--amber-rule)` and `background: var(--amber-tint)`
    - `block` → `.option` with `border-color: var(--red)` and `background: var(--red-tint)`
    - `pass` → `.option.rejected` (dimmed)
  - Card content: `.opt-name` = "{name} — {lens}", finding as `.opt-desc`, asks as `.pro-con` items (use `.item.neutral` class with `~` prefix for asks)
- Synthesis box: use `.rationale` class. `r-label` = "Synthesis". `r-text` = convergent + divergent + recommended action formatted as a short paragraph.
- If `decisions_spawned` has entries: `<div class="panel-input">` with chips like `Spawned: D-03`
- Footer: `{PROJECT NAME} · P-{NN}` | date

#### Group 3: By-Expert Slides (one per unique expert name across all panels)
- Collect all findings for a given expert name across all `P-*.md` files
- Eyebrow: `Expert View`
- Title: `{name} — {lens}` (use the lens from their most recent appearance)
- Content: a vertical list of findings, one per panel invocation, using `.cascade` layout:
  - Each entry: `.cascade-item` where `.c-label` = "P-{NN}: {topic}" and `.c-text` = the finding + asks
  - Color the left border by verdict: green for approve, amber for caution, red for block, gray for pass
- Summary line at bottom: "{X} reviews, {Y} cautions, {Z} blocks, {W} open asks"
- Footer: `{PROJECT NAME} · {name}` | "across {N} panels"

**Why by-expert views matter:** In a multi-panel build, the same expert speaks on 5–10 topics. This view surfaces systemic concerns: "Marcus flagged touch targets in 4 of 6 reviews — this is a systemic issue, not a one-off."

#### Group 4: Asks Tracker Slide (final slide)
- Eyebrow: `Open Asks`
- Title: `{N} asks across {M} panel runs`
- Table with class `decision-index`, columns: Ask, Expert, Panel, Verdict, Status
- Aggregate all asks from all experts across all panels
- Sort: blocks first, then cautions, then approves
- Status column: `Open` (amber dot) by default. If the ask maps to a resolved decision (via `decisions_spawned`), mark as `Resolved` (green dot) with the decision ID.
- Footer: `{PROJECT NAME} · Asks Tracker` | today's date

### Inline CSS

Use the same CSS from the decision-deck-template (`~/projects/workflow/templates/template-decision-deck.html` lines 8–107). All the necessary classes are already defined (`.option`, `.badge`, `.rationale`, `.cascade`, `.decision-index`, `.pillar-tag`, `.panel-chip`). No new CSS needed — the existing class vocabulary covers all panel slide patterns.

### Reveal.js Config

Same as decision deck:
```html
<script src="https://cdn.jsdelivr.net/npm/reveal.js@5.0.4/dist/reveal.min.js"></script>
<script>Reveal.initialize({hash:true,width:1280,height:720,margin:0,minScale:0.2,maxScale:2,center:false,transition:'none',controls:true,controlsTutorial:false,progress:true});</script>
```

---

## The `panel status` Flow

Read all `panels/P-*.md`, parse frontmatter, print two tables:

**Panel runs:**
```
| #    | Topic                     | Panel Type | Experts | Date       |
|------|---------------------------|------------|---------|------------|
| P-01 | Camera pipeline           | Technical  | 6/8     | 2026-05-26 |
| P-02 | Unit economics            | Business   | 7/8     | 2026-05-26 |
```

**Open asks** (aggregated across all panels):
```
| Ask                              | Expert  | Panel | Verdict |
|----------------------------------|---------|-------|---------|
| FPS test on real iPad Air        | Marcus  | P-01  | Caution |
| Define "latest Safari" as version| Marcus  | P-03  | Caution |
| Remove sharp dependency          | Watchdog| P-04  | Block   |
```

---

## Auto-Invocation Protocol

**Every expert panel skill** should invoke `/decision panel` after producing its findings. This is the integration contract:

1. Panel skill runs, produces structured output (experts speak, synthesis)
2. Panel skill invokes `/decision panel` with the full output as context
3. The decision skill writes `panels/P-{NN}.md` and regenerates `panels/deck.html`

For panels invoked during a `/forge` build (Phase 2), the forge orchestrator handles this automatically. For ad-hoc panel invocations outside a build, the panel skill itself should invoke the logging.

## Cross-References

- Panel records reference decisions they spawned: `decisions_spawned: ["D-03"]`
- Decision records reference panels that informed them: `sources: ["Technical Panel: Marcus flagged re-render cost"]`
- The panel deck and decision deck are separate HTML files but form a linked corpus. The asks tracker in the panel deck shows which asks became resolved decisions.
