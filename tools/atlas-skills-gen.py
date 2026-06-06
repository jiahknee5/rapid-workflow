#!/usr/bin/env python3
# Generate the multi-page Rapid Skills Atlas (one page per phase + a hub).
# Real phase NAMES in the header. Shared v2 "Constellation" dark theme.
import os, html

OUT = "/Users/johnny/projects/rapid-workflow/docs/atlas-v2"
os.makedirs(OUT, exist_ok=True)

# ---- pipeline: phases and gates in build order. gate=True for gates. ----
# fields: slug, ph, name, arc, kind, what, fixed, dynamic, example, value, reads[], writes[], exemplar
PH = [
 dict(slug="p0-vision", ph="P0", name="Vision Extraction", arc="Arc 1 · Understand", kind="phase",
   what="Reads the idea or PRD and extracts the <b>north star, success signals, and objective</b>, then derives <b>3–5 project pillars</b> — the lens every later prompt and spec section cites by name. Also <b>compound-refreshes</b> prior <code>LEARNINGS.md</code> so each build starts smarter.",
   fixed="3–5 pillars; the pillar-derivation protocol; the compound-refresh step.",
   dynamic="Pillar <i>content</i> — derived from this project's specific risks and goals.",
   example="For a kids' ASL tutor the pillars resolve to <b>[Deaf-community trust · recognition accuracy · sub-200ms latency · COPPA-safe]</b>. From here on every panel is prompted “review through these pillars,” and a requirement that violates one is sent back before panels run.",
   value="Panels prompted without a lens give <b>generic best-practice advice</b>; prompted through pillars, they give advice you can use. Vision-first is the cheapest move that prevents drift downstream.",
   reads=["idea / PRD","LEARNINGS.md"], writes=["00-vision/VISION.md","00-vision/PILLARS.md"], exemplar=True),

 dict(slug="p1-structure", ph="P1", name="Structure", arc="Arc 1 · Understand", kind="phase",
   what="Scaffolds the numbered folders, <b>locks the PRD</b> as the immutable input contract, drafts <b>CONSTITUTION</b> + <b>BUILD-AUTONOMY</b>, initialises <code>.rapid/</code>, runs the <b>preflight</b> runtime probe, and lays down the Atlas.",
   fixed="The folder skeleton; the PRD-lock; the preflight gate (P1 can't exit unless green).",
   dynamic="Which runtimes preflight probes; the Constitution's tailored Articles VI–X.",
   example="The raw PRD is copied to <code>01-intake/PRD.md</code> and frozen; an empty <code>DIFF.md</code> opens the audit trail. Preflight then probes the declared stack — a missing required runtime <b>blocks</b> P1 rather than letting the build route around it.",
   value="Everything downstream depends on a clean, locked, runnable starting point. Locking the PRD here is what makes the maintained diff (P4) trustworthy.",
   reads=["idea / PRD"], writes=["01-intake/PRD.md (locked)","01-intake/DIFF.md","CONSTITUTION.md","BUILD-AUTONOMY.md",".rapid/STATE.json",".rapid/PREFLIGHT.json"], exemplar=False),

 dict(slug="p1b-decompose", ph="P1b", name="PRD Decomposition", arc="Arc 1 · Understand", kind="phase",
   what="Decomposes the raw PRD into a <b>categorized, tagged, traced checklist</b> — BR → FR → TR, each marked MUST / SHOULD / COULD, each traceable.",
   fixed="The BR/FR/TR pyramid; the MUST/SHOULD/COULD tagging; full traceability.",
   dynamic="The actual requirements, their categories, and stakeholder-stated priority.",
   example="A prose PRD becomes <code>### FR-7 [MUST]</code> … <code>### TR-3 [SHOULD]</code> — a checklist a panel can critique line by line and the spec can trace against.",
   value="Turns prose into something reviewable and traceable. The tags here are <i>as the stakeholder stated</i> — strategic re-prioritization waits for G1.",
   reads=["01-intake/PRD.md"], writes=["01-intake/PRD-ENHANCED.md"], exemplar=False),

 dict(slug="g0", ph="G0", name="Faithful decomposition", arc="Human gate", kind="gate",
   what="<b>Generalist gate.</b> You review the decomposed PRD: <i>“did we read your PRD right?”</i> Pre-screened by three doc-review agents — <b>Feasibility · Scope Guardian · Coherence</b>. Priority bets are <b>deferred to G1</b> (panels haven't run yet).",
   fixed="The gate position (after P1b); the three pre-screen agents.", dynamic="The review criteria, derived from the pillars.",
   example="You confirm every requirement was captured, tagged, and traced — and confirm what's out of scope. A redirect re-runs P1b.",
   value="A cheap faithfulness check before you spend on expensive expert panels. You never convene specialists on a PRD that failed a coherence read.",
   reads=["01-intake/PRD-ENHANCED.md"], writes=["sign-off"], exemplar=False),

 dict(slug="p2-panels", ph="P2", name="Expert Panels", arc="Arc 1 · Understand", kind="phase",
   what="Convenes <b>1 (fast) or 3 (full) expert panels</b> — business, technical, SME / users — that review the decomposed PRD <b>through the pillars</b>, each panelist in voice, then synthesizes <b>convergent / divergent / risks / open</b> with sources.",
   fixed="1–3 panels; the synthesis protocol; 2nd-order panels only on escalation.",
   dynamic="Which panels (by domain), which panelists (named), reviewer weights.",
   example="A healthcare build weights the <code>security-expert-panel</code> heaviest; a kids' app convenes a <code>user-panel</code> of kids, parents, and teachers in voice plus <code>asl-expert-panel</code>. The synthesis — not the transcripts — is what you read at G1.",
   value="Tiered, in-voice domain challenge surfaces objections a generalist gate misses — and it runs after the cheap faithfulness gate, so panel cost is never wasted. Its output sets priority at G1.",
   reads=["01-intake/PRD-ENHANCED.md","00-vision/PILLARS.md"], writes=["03-panels/synthesis.md"], exemplar=True),

 dict(slug="p3-research", ph="P3", name="Grounding Research", arc="Arc 1 · Understand", kind="phase",
   what="Resolves the <code>[OPEN]</code> questions surfaced by decomposition and panels, and <b>verifies external data availability</b> under a VERIFIED / UNVERIFIED protocol.",
   fixed="The VERIFIED/UNVERIFIED protocol; cite-on-demand into the spec, not a separate doc.",
   dynamic="Which questions get researched; which sources are pulled.",
   example="“Is there a free ASL handshape dataset with a usable license?” → a grounding note with options, evidence, a recommendation, a fallback, and a VERIFIED/UNVERIFIED tag.",
   value="Front-loaded knowledge gets read once and ignored; cite-on-demand grounding lands in the spec where it supports a decision, every time it's needed.",
   reads=["[OPEN] questions"], writes=["02-grounding/{question}.md"], exemplar=False),

 dict(slug="g1", ph="G1", name="Direction & priority", arc="Human gate", kind="gate",
   what="<b>You set direction and priority</b>, informed by the panels: resolve divergences, rank <b>MUST/SHOULD/COULD</b> (moved here from G0), answer the <b>undecidable batch</b>, and <b>sign BUILD-AUTONOMY.md</b>. Pre-screened by <b>Adversarial · Feasibility</b>.",
   fixed="The gate position (after P3); the undecidable batch; the all-or-nothing standing authorization.",
   dynamic="The priority calls and the deploy target / spend ceiling you sign.",
   example="You rank a contested FR as SHOULD (the panel split on it), answer the one undecidable — “SQLite, not Postgres” — written back to the spec with <code>basis=spec</code>, and sign BUILD-AUTONOMY with the deploy target + spend ceiling. The build now runs to completion, bounded by the fixed stop-condition set.",
   value="One place to set strategy with expert input in hand, and to grant the autonomy that lets the rest of the build run unattended.",
   reads=["03-panels/synthesis.md","02-grounding/*.md"], writes=["BUILD-AUTONOMY.md (signed)"], exemplar=False),

 dict(slug="p4-spec", ph="P4", name="Spec Derivation", arc="Arc 2 · Specify", kind="phase",
   what="Derives the spec from the PRD as a <b>maintained diff</b> — never duplicated — traces every requirement, and emits the interface <b>contracts</b> and the <b>workflow state machine</b> the tests will come from.",
   fixed="One document with a diff; every req maps to a section or [OUT OF SCOPE]; every section is [FROM PRD] or [DERIVED].",
   dynamic="The architecture, the contracts, the workflow nodes — all project-specific.",
   example="<code>### S-04 [DERIVED]</code> traces to <code>FR-7</code>; the workflow state machine becomes <code>docs/workflows.json</code>, which the eval harness reads node-by-node.",
   value="Two parallel docs drift within a week. The diff <i>is</i> the value — it's the audit trail and the change log when the gap loop fires.",
   reads=["01-intake/PRD.md"], writes=["04-spec/spec.md","04-spec/workflow.md","04-spec/architecture.md","04-spec/CONTRACTS.md","docs/workflows.json"], exemplar=False),

 dict(slug="p5-tasks-eval", ph="P5", name="Tasks + Eval Harness", arc="Arc 2 · Specify", kind="phase",
   what="Sizes the implementor fan-out, then <b>generates the immutable eval harness from the workflow state machine and locks it</b>. The harness is <b>task-00</b> — the root of the task graph that every other task depends on.",
   fixed="task-00 is the blocking root; the harness is immutable after P5; agents extend tests, never edit them.",
   dynamic="The actual test cases, derived from this project's workflow nodes and branches.",
   example="Each workflow node → a test (arrange from <code>in</code>, act from <code>proc</code>, assert from <code>out</code>); each branch → a negative test; each failure path → a recovery test.",
   value="Tests are the spec, locked before any feature code. A failing test means the code is wrong (or the spec is — re-derive it; never weaken the test).",
   reads=["04-spec/workflow.md"], writes=[".rapid/TASKS.json",".rapid/EVAL/ (locked)","04-spec/agents/*.md","CI config"], exemplar=False),

 dict(slug="p5b-deepen", ph="P5b", name="Spec Deepening", arc="Arc 2 · Specify", kind="phase",
   what="Three subagents — a <b>flow analyzer</b>, a <b>confidence checker</b>, and a <b>deliverable verifier</b> — hunt for gaps in the spec <i>before</i> the point of no return, surfacing blocking questions for G2.",
   fixed="The three deepening lenses; any LOW-confidence or missing flow becomes a blocking G2 question.",
   dynamic="What they find — specific to the spec's weak spots.",
   example="The flow analyzer notices a workflow branch with no defined recovery path → a blocking question lands in <code>.rapid/DEEPENING.md</code> for you to resolve at G2.",
   value="The last cheap chance to fix ambiguity before the keys change hands and rework gets expensive.",
   reads=["04-spec/spec.md"], writes=[".rapid/DEEPENING.md"], exemplar=False),

 dict(slug="g2", ph="G2", name="Point of no return", arc="Human gate", kind="gate", por=True,
   what="<b>You hand over the keys.</b> Approve the final spec / architecture / tasks / eval, the cost projection, the deploy target, and the <code>.env</code> values. Pre-screened by <b>Scope · Coherence · Adversarial</b> + deepening findings. After this, the build proceeds; no major redirect without re-entering P4–P5.",
   fixed="The gate position (after P5b); the inputs ledger must be fully resolved.", dynamic="The spec you approve and the credentials you provide.",
   example="A credential row only counts resolved once its <code>.env:KEY</code> actually exists — the gate fails closed otherwise.",
   value="The single most consequential decision — everything after runs autonomously against what you lock here.",
   reads=["04-spec/*",".rapid/EVAL/",".rapid/COST.json"], writes=["spec locked · eval locked · cost budgeted"], exemplar=False),

 dict(slug="p6-build", ph="P6", name="Parallel Build", arc="Arc 3 · Execute", kind="phase",
   what="Stands up the <b>five-lead build team</b> — one long-lived terminal each, over claude-peers — and builds to the <b>locked</b> spec with a keep-or-revert ratchet. The <b>writer is never the auditor</b>: the coder fans out 1–4 isolated worktree writers while a separate watchdog audits every merge.",
   fixed="5 leads; coder ≠ tester/reviewer/watchdog; message contract; keep-or-revert; immutable evals.",
   dynamic="Track size (full 5 / fast 4 / tiny subagents); coder fan-out 1–4; reviewer weights.",
   example="13+ tasks → 3–4 coder terminals in isolated git worktrees; ≤5 tasks → one coder fanning out subagents. The watchdog runs a <code>/loop 30m</code> drift-check and writes <code>AUDIT.json</code> — and P6 can't exit without it.",
   value="The riskiest phase, safe <b>by construction</b>: separate auditor + immutable evals + keep-or-revert + verified worktree isolation + an 80% cost breaker.",
   reads=["04-spec/",".rapid/TASKS.json",".rapid/EVAL/ (locked)"], writes=["merged PRs",".rapid/AUDIT.json",".rapid/P6_EXIT.json",".rapid/LEARNINGS.md"], exemplar=True,
   subskills=[("planner","owns the spec-of-record; pins shared seams before fan-out; arbitrates"),
              ("coder","writes code; fans out 1–4 isolated worktree writers. Never audits"),
              ("tester","runs the locked harness, Playwright, screenshots. Never writes features"),
              ("reviewer","5 tiered, confidence-gated lenses; one verdict per PR"),
              ("watchdog","audits every merge vs spec + Constitution. Never an implementor")]),

 dict(slug="p7-test", ph="P7", name="Test + Visual QA", arc="Arc 3 · Execute", kind="phase",
   what="Runs the <b>real per-layer test suite</b>, does <b>visual QA across 3 viewports</b> with screenshot evidence, walks <b>every</b> workflow surface concretely, and records workflow runs — extracting gaps as it goes.",
   fixed="e2e is required to ship; the walkthrough must cover every surface in workflow.md.",
   dynamic="The surfaces, the viewports' content, the recorded runs.",
   example="Playwright flows derived from the workflow map exercise the golden path + named edge cases; <code>.rapid/WALKTHROUGH.md</code> must cover every surface or R1 blocks P8.",
   value="Agents walk the app mechanically first; you become the felt-sense filter, not the regression hunter.",
   reads=["the built app",".rapid/EVAL/"], writes=[".rapid/VERIFY.json","TEST_RESULTS.md","WALKTHROUGH.md",".rapid/RUNS/"], exemplar=False),

 dict(slug="p8-gaps", ph="P8", name="Gap Loop + Optimization", arc="Arc 3 · Execute", kind="phase",
   what="<b>Classifies every gap</b> by pillar + severity, auto-fixes BLOCKER/HIGH <i>spec-level</i> gaps (capped at <b>3</b> iterations), runs the optimization experiment <b>once</b>, and surfaces the rest to G3.",
   fixed="3-iteration cap on spec-level auto-fix; PRD-level gaps surface to G3 (never guessed); optimization runs once.",
   dynamic="The gaps themselves and which optimization is tried.",
   example="A spec-level gap re-derives the relevant section (≤3×); a PRD-level gap is written up for your G3 decision rather than silently assumed.",
   value="Bounded convergence — the loop terminates instead of chasing a moving target, and PRD-level calls stay with you.",
   reads=["gaps from P7"], writes=[".rapid/GAPS.json",".rapid/OPTIMIZE.json"], exemplar=False),

 dict(slug="g3", ph="G3", name="Ship decision", arc="Human gate", kind="gate",
   what="<b>You decide: ship / loop / redirect / kill.</b> Review the working app, spec-compliance % per domain, tests + visual QA, gaps (resolved &amp; remaining), and cost actual vs projection. The ship gate <b>blocks on unresolved stubs</b>.",
   fixed="The gate position (after P8); the four options; the stub block.", dynamic="The evidence bundle, specific to this build.",
   example="“Ship” → P9; “Loop” → back to P8 with constraints; “Redirect” → re-run from a phase; “Kill” → stop + retro.",
   value="The release call stays human — with a complete, honest evidence bundle and a hard stub block behind it.",
   reads=["the app",".rapid/AUDIT.json",".rapid/GAPS.json",".rapid/COST.json"], writes=["operator decision"], exemplar=False),

 dict(slug="p9-deploy", ph="P9", name="Deploy + Document", arc="Arc 3 · Execute", kind="phase",
   what="Deploys the product, writes the <b>README + RUNBOOK</b>, runs the <b>retro</b>, generates the doc decks, and deploys the <b>Atlas alongside the product</b> at <code>/_atlas</code>.",
   fixed="Deploy is outward-facing — it stops for your authorization; the retro reviews any Article VI–X overrides.",
   dynamic="The deploy target and the product-specific docs.",
   example="The same Atlas you're reading is generated for the built project and shipped next to it, so the next developer lands in a navigable map.",
   value="Ship + document in one move, with no manual cleanup — the docs are already live from the post-write hook.",
   reads=["the shipped app"], writes=["deployed product","README.md","RUNBOOK.md",".rapid/RETRO.md","doc decks","Atlas at /_atlas"], exemplar=False),

 dict(slug="p10-pulse", ph="P10", name="Product Pulse", arc="Arc 3 · Compound", kind="phase",
   what="Post-ship, produces a <b>time-windowed usage / performance / error / feedback report</b> that feeds the <b>next build's P0</b> — closing the compound loop.",
   fixed="The report format; the pulse → vision loop.",
   dynamic="The data sources (analytics, error tracking, logs) for this product.",
   example="A weekly pulse note in <code>docs/pulse-reports/</code> surfaces the top error and the least-used feature — which become inputs to the next build's pillars.",
   value="<b>The loop is the product.</b> Each build's pulse makes the next build start smarter; a single build is just an artifact.",
   reads=["analytics · errors · logs"], writes=["docs/pulse-reports/YYYY-MM-DD.md"], exemplar=False),
]

STYLE = open("/Users/johnny/projects/rapid-workflow/docs/atlas-v2/_style.css").read()

def topnav(active):
    # Slim, high-level developer destinations — phases live in the left nav + hub stepper.
    # active="index" highlights Plan (every Skills-Atlas page is part of the plan).
    DEST = [
        ("Plan", "index.html", True, None),
        ("Build &amp; Observatory", "../observatory.html", False, None),
        ("Test Suite", "../testsuite.html", False, None),
        ("Local&nbsp;▶", "../home.html#product", False, "local"),
        ("Deployed", "../home.html#product", False, "deployed"),
        ("Source", "../home.html#source", False, "source"),
    ]
    out = []
    for t,h,a,d in DEST:
        da = f' data-dest="{d}"' if d else ''
        out.append(f'<a class="dest{" active" if a else ""}"{da} href="{h}">{t}</a>')
        if d=="local":
            out.append('<button class="copy-launch" type="button" hidden>⧉</button>')
    links = "".join(out)
    return ('<nav class="top-nav"><a class="top-brand" href="index.html">RAPID<span class="sub">Skills Atlas</span></a>'
            '<span class="dest-sep"></span>' + links +
            '<span class="top-spacer"></span>'
            '<a class="top-link" href="../how-it-works.html">How it works ↗</a></nav>')

def sidebar(active):
    rows = ['<div class="sidebar-section">The package</div>',
            '<a href="index.html"%s>Overview &amp; hierarchy</a>' % (' class="active"' if active=="index" else ""),
            '<div class="sidebar-section">Phase skills (build order)</div>']
    for p in PH:
        if p["kind"]=="gate":
            rows.append(f'<a class="sub" href="{p["slug"]}.html"%s>⟨{p["ph"]}⟩ {html.escape(p["name"])} <span class="gate-dot">gate</span></a>' % (' class="active sub"' if p["slug"]==active else ""))
        else:
            cls = ' class="active"' if p["slug"]==active else ''
            rows.append(f'<a href="{p["slug"]}.html"{cls}><span class="ph">{p["ph"]}</span> {html.escape(p["name"])}</a>')
    rows.append('<div class="sidebar-section">Cross-cutting</div>')
    rows.append('<a href="index.html#crosscut">/decision · /docs · hooks R1–R9</a>')
    return '<nav class="sidebar"><div class="sidebar-brand">✦ Skills Atlas</div><div class="sidebar-sub">Rapid — the build workflow, by skill</div>' + "".join(rows) + '</nav>'

def chips(items, cls=""):
    return "".join(f'<span class="fchip {cls}">{html.escape(x)}</span>' for x in items)

def skill_card(p):
    badges = f'<span class="sb arc">{html.escape(p["arc"])}</span>'
    if p["kind"]=="gate": badges += '<span class="sb gatefeed">human gate</span>'
    else: badges += '<span class="sb comp">composed</span>'
    sub = ""
    if p.get("subskills"):
        cells = "".join(f'<div class="subskill"><span class="ss-name">{n}</span> <span class="ss-id">rapid:role-{n}</span><div class="ss-desc">{d}</div></div>' for n,d in p["subskills"])
        sub = f'<div class="field-label" style="margin-top:18px;">Role sub-skills (gstack personas — each a bounded contract)</div><div class="subskills">{cells}</div>'
    if p["kind"]=="gate":
        src = f'Defined in the orchestrator\'s gate protocol (Gate {p["ph"]} — {html.escape(p["name"])}); the pre-screen doc-review agents are composed from the project\'s pillars. Verbatim in <code>skills/rapid-workflow/SKILL.md</code>.'
    else:
        src = f'Composed inside the <code>/rapid-workflow</code> orchestrator (Phase {p["ph"]} — {html.escape(p["name"])}). The verbatim instruction block lives in <code>skills/rapid-workflow/SKILL.md</code>'
        src += ' plus the role briefs in <code>templates/agent-roles/*.md</code>.' if p.get("subskills") else '.'
    src += ' Regenerate the Atlas (<code>tools/atlas-skills-gen.py</code>) to embed it inline.'
    sub += f'<details class="srctext"><summary>▸ Skill text · where it lives</summary><div class="src-body">{src}</div></details>'
    return f'''<div class="skill">
      <div class="skill-head"><span class="skill-name">{html.escape(p["name"])}</span><span class="skill-id">rapid:{p["slug"]}</span><span class="skill-badges">{badges}</span></div>
      <div class="skill-body">
        <div class="skill-what">{p["what"]}</div>
        <div class="fielddual">
          <div class="field"><div class="field-label">Fixed vs. Dynamic</div><div class="fixed-dyn">
            <div class="fd-row"><span class="lab fixed">Fixed</span><span>{p["fixed"]}</span></div>
            <div class="fd-row"><span class="lab dyn">Dynamic</span><span>{p["dynamic"]}</span></div></div></div>
          <div class="field"><div class="field-label">Files touched</div><div class="files">
            <div class="fileflow"><span class="io">reads</span>{chips(p["reads"])}</div>
            <div class="fileflow"><span class="io">writes</span>{chips(p["writes"],"out")}</div></div></div>
        </div>
        <div class="skill-ex"><div class="ex-label">Example</div><div class="ex-body">{p["example"]}</div></div>
        <div class="skill-val"><div class="val-label">Why it's valuable</div><div class="val-body">{p["value"]}</div></div>
        {sub}
      </div>
    </div>'''

def page(p, idx):
    prevn = PH[idx-1] if idx>0 else None
    nextn = PH[idx+1] if idx<len(PH)-1 else None
    nav = ""
    if prevn: nav += f'<a class="pager" href="{prevn["slug"]}.html">← {prevn["ph"]} {html.escape(prevn["name"])}</a>'
    nav += '<span style="flex:1"></span>'
    if nextn: nav += f'<a class="pager" href="{nextn["slug"]}.html">{nextn["ph"]} {html.escape(nextn["name"])} →</a>'
    sid = "Human gate" if p["kind"]=="gate" else "Phase skill"
    return f'''<!doctype html><html lang="en"><head><meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>{html.escape(p["ph"])} {html.escape(p["name"])} — Rapid Skills Atlas</title>
<style>{STYLE}</style></head><body>
{topnav(p["slug"])}
<div class="spec-layout">{sidebar(p["slug"])}
<div class="main">
  <section class="section">
    <div class="section-id">{sid} · {html.escape(p["arc"])}</div>
    <h2 class="section-title">{html.escape(p["ph"])} — {html.escape(p["name"])}</h2>
    {skill_card(p)}
    <div class="pagernav">{nav}</div>
  </section>
</div></div><script src="atlas-env.js" defer></script></body></html>'''

# ---- hub (index.html) ----
def index_page():
    # build-order stepper with real names
    nodes = []
    for p in PH:
        c = "pnode " + ("gate" if p["kind"]=="gate" else ("primary" if p["slug"]=="p6-build" else "auto"))
        if p.get("por"): c = "pnode por"
        sub = p["ph"] if p["kind"]!="gate" else "gate"
        nodes.append(f'<a class="{c}" href="{p["slug"]}.html">{html.escape(p["name"])}<small>{sub}</small></a>')
    stepper = '<span class="parr">→</span>'.join(nodes)
    # skill index rows
    rows = []
    for p in PH:
        rc = ' class="gate"' if p["kind"]=="gate" else ''
        reads = " · ".join(p["reads"]); writes = " · ".join(p["writes"])
        rows.append(f'<tr{rc}><td class="k">{p["ph"]}</td><td class="sk"><a href="{p["slug"]}.html">{html.escape(p["name"])}</a></td><td><span class="fc">{html.escape(reads)} → {html.escape(writes)}</span></td></tr>')
    idxtbl = "".join(rows)
    return f'''<!doctype html><html lang="en"><head><meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>Skills Atlas — Rapid</title><style>{STYLE}</style></head><body>
{topnav("index")}
<div class="spec-layout">{sidebar("index")}
<div class="main">
  <section class="section" id="package">
    <div class="section-id">The package</div>
    <h1 class="section-title">Rapid is a hierarchy of dynamic skills, run in a fixed order.</h1>
    <p class="section-desc">One orchestrator composes a project-specific build system from a library of skills. The <b>scaffold</b> — 12 phases, 4 gates, the message contract, keep-or-revert, the immutable eval harness — never changes; every skill <b>inside</b> it is composed per project. Each page documents one skill: <b>name · what · fixed-vs-dynamic · example · why-valuable · files touched</b>.</p>
    <div class="tree">
      <div class="t0"><span class="k">/rapid-workflow</span> — the orchestrator <span class="tag reg">registered skill</span></div>
      <div class="t1"><div><span class="k">P0–P10 phase skills</span> <span class="tag comp">composed in orchestrator</span></div>
      <div class="t2">↳ build-team role skills (P6): planner · coder · tester · reviewer · watchdog</div></div>
      <div class="t1" style="margin-top:8px;"><div><span class="k">/decision</span>, <span class="k">/docs</span> <span class="tag reg">registered</span> · <span class="k">R1–R9</span> enforcement hooks <span class="tag hook">hook</span></div></div>
    </div>
    <div class="section-id" style="margin-top:24px;">Build order</div>
    <div class="pipeline">{stepper}</div>
  </section>
  <section class="section" id="index">
    <div class="section-id">Index</div>
    <h2 class="section-title">Every phase, its skill, and its files</h2>
    <p class="section-desc">Each name links to its own page; <b>every page carries the same depth</b> — what it does, fixed-vs-dynamic, a worked example, why it's valuable, the files it touches, and where the skill text lives.</p>
    <table class="idx"><thead><tr><th style="width:8%">Phase</th><th style="width:24%">Skill</th><th>Reads → Writes</th></tr></thead><tbody>{idxtbl}</tbody></table>
  </section>
  <section class="section" id="crosscut">
    <div class="section-id">Cross-cutting</div>
    <h2 class="section-title">Documentation skills &amp; enforcement hooks</h2>
    <p class="section-desc">Run <b>across</b> phases. <code>/decision</code> + <code>/docs</code> are registered skills; <b>R1 phase-gate · R7 stop · R8 conformance · R9 stub-scan · post-write</b> are mechanical hooks the harness runs so load-bearing steps can't be skipped.</p>
    <div class="footnote">Generated by tools/atlas-skills-gen.py · fully Rapid-named · theme docs/atlas-v2-design.md. One page per phase; high-level destinations in the header (data-driven from env.json).</div>
  </section>
</div></div><script src="atlas-env.js" defer></script></body></html>'''

# ---- write ----
n=0
open(os.path.join(OUT,"index.html"),"w").write(index_page()); n+=1
for i,p in enumerate(PH):
    open(os.path.join(OUT,p["slug"]+".html"),"w").write(page(p,i)); n+=1
print(f"wrote {n} pages to {OUT}")
print("pages:", ", ".join([p["slug"] for p in PH]))
