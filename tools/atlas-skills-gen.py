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
   reads=["idea / PRD","LEARNINGS.md"], writes=["00-vision/VISION.md","00-vision/PILLARS.md"], exemplar=True,
   deep='''
    <div class="deep-sec">
      <div class="deep-title">How pillars are derived</div>
      <ol class="proto">
        <li><b>Read for the north star</b> — the single outcome that defines success for this build.</li>
        <li><b>Surface the top 3–5 risks &amp; goals</b> that could make or break that outcome.</li>
        <li><b>Name each as a testable pillar</b> — a yardstick you can hold a decision against, not a platitude.</li>
        <li><b>Write the one-pager</b> — north star + success signals + the pillars. One page, no more.</li>
        <li><b>Compound-refresh</b> — pull prior <code>LEARNINGS.md</code>, mark stale entries (referenced files/patterns gone) so old lessons don't mislead.</li>
      </ol>
    </div>
    <div class="deep-sec">
      <div class="deep-title">What makes a pillar load-bearing</div>
      <div class="deep-note">A good pillar is <b>testable, project-specific, and decision-shaping</b>. "High quality" is not a pillar — you can't hold a design against it. "Sub-200ms recognition latency on a mid-range phone" is: every architecture choice either clears that bar or doesn't.</div>
    </div>
    <div class="deep-sec">
      <div class="deep-title">The lens, downstream — where pillars are cited by name</div>
      <table class="idx"><thead><tr><th style="width:24%">Phase</th><th>How the pillars are used</th></tr></thead><tbody>
        <tr><td class="k">P2 · Panels</td><td>Every panel is prompted "review through these pillars" — that's what makes the advice usable, not generic.</td></tr>
        <tr><td class="k">P4 · Spec</td><td>Each spec section maps to the pillar(s) it serves; a section serving no pillar is scope creep.</td></tr>
        <tr><td class="k">Gates G0–G3</td><td>The doc-review agents' criteria are derived from the pillars.</td></tr>
        <tr><td class="k">P8 · Gap loop</td><td>Every gap is classified by the pillar it threatens, so severity ties back to what matters.</td></tr>
      </tbody></table>
    </div>
   '''),

 dict(slug="p1-structure", ph="P1", name="Structure", arc="Arc 1 · Understand", kind="phase",
   what="Scaffolds the numbered folders, <b>locks the PRD</b> as the immutable input contract, drafts <b>CONSTITUTION</b> + <b>BUILD-AUTONOMY</b>, initialises <code>.rapid/</code>, runs the <b>preflight</b> runtime probe, and lays down the Atlas.",
   fixed="The folder skeleton; the PRD-lock; the preflight gate (P1 can't exit unless green).",
   dynamic="Which runtimes preflight probes; the Constitution's tailored Articles VI–X.",
   example="The raw PRD is copied to <code>01-intake/PRD.md</code> and frozen; an empty <code>DIFF.md</code> opens the audit trail. Preflight then probes the declared stack — a missing required runtime <b>blocks</b> P1 rather than letting the build route around it.",
   value="Everything downstream depends on a clean, locked, runnable starting point. Locking the PRD here is what makes the maintained diff (P4) trustworthy.",
   reads=["idea / PRD"], writes=["01-intake/PRD.md (locked)","01-intake/DIFF.md","CONSTITUTION.md","BUILD-AUTONOMY.md",".rapid/STATE.json",".rapid/PREFLIGHT.json"], exemplar=False,
   deep='''
    <div class="deep-sec">
      <div class="deep-title">The numbered folder skeleton</div>
      <div class="deep-sub">P1 lays down the same tree every build uses, so any developer (or agent) lands in a known map.</div>
      <table class="idx"><thead><tr><th style="width:24%">Folder</th><th>Holds</th></tr></thead><tbody>
        <tr><td class="k">00-vision/</td><td>VISION.md + PILLARS.md — the lens.</td></tr>
        <tr><td class="k">01-intake/</td><td>The locked PRD, the maintained DIFF, the enhanced PRD.</td></tr>
        <tr><td class="k">02-grounding/</td><td>Cite-on-demand research notes (P3).</td></tr>
        <tr><td class="k">03-panels/</td><td>Panel synthesis (P2).</td></tr>
        <tr><td class="k">04-spec/</td><td>spec · workflow · architecture · CONTRACTS · agents/.</td></tr>
        <tr><td class="k">05-gaps/</td><td>Gap history + retrospective.</td></tr>
        <tr><td class="k">docs/ · src/</td><td>The Atlas + the product code.</td></tr>
        <tr><td class="k">.rapid/</td><td>Runtime state (gitignored) — STATE, TASKS, EVAL, COST, observe…</td></tr>
      </tbody></table>
    </div>
    <div class="deep-sec">
      <div class="deep-title">Locking the PRD</div>
      <div class="deep-note">The raw stakeholder PRD is copied to <code>01-intake/PRD.md</code> and <b>frozen — never edited again</b>. An empty <code>DIFF.md</code> opens. Why: the diff between PRD and the derived spec (P4) becomes the audit trail of every decision, and a stakeholder can re-read their own doc and trust nothing changed under them.</div>
    </div>
    <div class="deep-sec">
      <div class="deep-title">Preflight — the runtime gate</div>
      <ol class="proto">
        <li><b>Read the declared stack</b> from <code>.rapid/preflight.json</code> (node, python, playwright, …).</li>
        <li><b>Probe each tool</b> (default <code>command -v</code>) with the exit code captured, not piped.</li>
        <li><b>Install what's missing &amp; re-check</b> where an install command is declared.</li>
        <li><b>Block P1 from exiting</b> if any required tool is still missing — never route around an absent runtime.</li>
      </ol>
    </div>
   '''),

 dict(slug="p1b-decompose", ph="P1b", name="PRD Decomposition", arc="Arc 1 · Understand", kind="phase",
   what="Decomposes the raw PRD into a <b>categorized, tagged, traced checklist</b> — BR → FR → TR, each marked MUST / SHOULD / COULD, each traceable.",
   fixed="The BR/FR/TR pyramid; the MUST/SHOULD/COULD tagging; full traceability.",
   dynamic="The actual requirements, their categories, and stakeholder-stated priority.",
   example="A prose PRD becomes <code>### FR-7 [MUST]</code> … <code>### TR-3 [SHOULD]</code> — a checklist a panel can critique line by line and the spec can trace against.",
   value="Turns prose into something reviewable and traceable. The tags here are <i>as the stakeholder stated</i> — strategic re-prioritization waits for G1.",
   reads=["01-intake/PRD.md"], writes=["01-intake/PRD-ENHANCED.md"], exemplar=False,
   deep='''
    <div class="deep-sec">
      <div class="deep-title">The requirement pyramid</div>
      <div class="deep-sub">Prose becomes a three-tier pyramid so priority and traceability are explicit — each lower tier serves the one above it.</div>
      <div class="lens-grid">
        <div class="lens blue"><h5>BR — Business requirements</h5><p>Why the product exists; the outcomes the stakeholder is buying. The top of the pyramid.</p></div>
        <div class="lens teal"><h5>FR — Functional requirements</h5><p>What the product must do for a user to realize each BR. The behaviour.</p></div>
        <div class="lens purple"><h5>TR — Technical requirements</h5><p>What the system must satisfy to deliver each FR — perf, security, platform.</p></div>
        <div class="lens green"><h5>Traceability</h5><p>Every requirement gets a stable ID (<code>BR-1 · FR-7 · TR-3</code>) so the spec, tasks, and tests can all point back to it.</p></div>
      </div>
    </div>
    <div class="deep-sec">
      <div class="deep-title">Tags — priority &amp; status on every requirement</div>
      <table class="idx"><thead><tr><th style="width:22%">Tag</th><th>Meaning</th></tr></thead><tbody>
        <tr><td class="k">[MUST]</td><td>Non-negotiable for this release — as the stakeholder stated it.</td></tr>
        <tr><td class="k">[SHOULD]</td><td>Strongly wanted; cut only with a reason.</td></tr>
        <tr><td class="k">[COULD]</td><td>Nice-to-have; first to drop under pressure.</td></tr>
        <tr><td class="k">[OPEN]</td><td>Unresolved question → routed to P3 grounding or the G1 batch.</td></tr>
        <tr><td class="k">[RISKY]</td><td>Flagged for explicit operator attention at G0.</td></tr>
        <tr><td class="k">[OUT OF SCOPE]</td><td>Explicitly excluded — recorded, not silently dropped.</td></tr>
      </tbody></table>
    </div>
    <div class="deep-sec">
      <div class="deep-title">Example</div>
      <div class="skill-ex"><div class="ex-label">Decomposition</div><div class="ex-body">A line of PRD prose — "kids should get instant feedback" — becomes <code>### FR-7 [MUST] Learner sees correctness feedback &lt;100ms after an answer</code>, tracing to <code>BR-2 (engagement)</code> and pinning <code>TR-4 [MUST] client-side validation, no round-trip</code>. Now a panel can argue FR-7 specifically, and a test can assert the 100ms.</div></div>
    </div>
   '''),

 dict(slug="g0", ph="G0", name="Faithful decomposition", arc="Human gate", kind="gate",
   what="<b>Generalist gate.</b> You review the decomposed PRD: <i>“did we read your PRD right?”</i> Pre-screened by three doc-review agents — <b>Feasibility · Scope Guardian · Coherence</b>. Priority bets are <b>deferred to G1</b> (panels haven't run yet).",
   fixed="The gate position (after P1b); the three pre-screen agents.", dynamic="The review criteria, derived from the pillars.",
   example="You confirm every requirement was captured, tagged, and traced — and confirm what's out of scope. A redirect re-runs P1b.",
   value="A cheap faithfulness check before you spend on expensive expert panels. You never convene specialists on a PRD that failed a coherence read.",
   reads=["01-intake/PRD-ENHANCED.md"], writes=["sign-off"], exemplar=False,
   deep='''
    <div class="deep-sec">
      <div class="deep-title">The three pre-screen agents</div>
      <div class="deep-sub">Before the decomposed PRD reaches you, three <b>generalist</b> doc-review agents read it through the pillars and flag issues — so your attention goes to judgment calls, not proofreading.</div>
      <div class="lens-grid">
        <div class="lens blue"><h5>Feasibility</h5><p>Is each requirement buildable within the implied constraints? Flags the ones that quietly assume the impossible.</p></div>
        <div class="lens teal"><h5>Scope Guardian</h5><p>Did decomposition add or drop anything the PRD didn't say? Catches silent scope drift in both directions.</p></div>
        <div class="lens purple"><h5>Coherence</h5><p>Do the requirements contradict each other or the pillars? Surfaces internal conflicts before they reach the spec.</p></div>
        <div class="lens green"><h5>(not here) Strategy</h5><p>Deliberately absent — strategic priority is a G1 job, with the expert panels in hand. G0 stays a faithfulness check.</p></div>
      </div>
    </div>
    <div class="deep-sec">
      <div class="deep-title">What you approve — and what you defer</div>
      <div class="deep-note"><b>Approve at G0 (faithfulness):</b> every requirement captured, correctly tagged and traced, scope/<code>[RISKY]</code> flags confirmed, <code>[OPEN]</code> questions noted. <b>Deferred to G1:</b> strategic MUST/SHOULD/COULD priority — the panels haven't run yet, so you're not asked to bet on priority here. <b>Redirect:</b> if decomposition misread the PRD, send it back to re-run P1b — cheap, because no panel cost has been spent.</div>
    </div>
   '''),

 dict(slug="p2-panels", ph="P2", name="Expert Panels", arc="Arc 1 · Understand", kind="phase",
   what="Convenes <b>1 (fast) or 3 (full) expert panels</b> — business, technical, SME / users — that review the decomposed PRD <b>through the pillars</b>, each panelist in voice, then synthesizes <b>convergent / divergent / risks / open</b> with sources.",
   fixed="1–3 panels; the synthesis protocol; 2nd-order panels only on escalation.",
   dynamic="Which panels (by domain), which panelists (named), reviewer weights.",
   example="A healthcare build weights the <code>security-expert-panel</code> heaviest; a kids' app convenes a <code>user-panel</code> of kids, parents, and teachers in voice plus <code>asl-expert-panel</code>. The synthesis — not the transcripts — is what you read at G1.",
   value="Tiered, in-voice domain challenge surfaces objections a generalist gate misses — and it runs after the cheap faithfulness gate, so panel cost is never wasted. Its output sets priority at G1.",
   reads=["01-intake/PRD-ENHANCED.md","00-vision/PILLARS.md"], writes=["03-panels/synthesis.md"], exemplar=True,
   deep='''
    <div class="deep-sec">
      <div class="deep-title">The four panel lenses</div>
      <div class="deep-sub">Every panel is one of four lenses. Which lenses run, and who sits on each, is composed per project; <b>the default full track convenes Business + Technical + SME/Users</b>, fast track picks the single most relevant.</div>
      <div class="lens-grid">
        <div class="lens blue"><h5>Business</h5><div class="lens-skill">/business-expert-panel</div><p>Market, GTM, pricing tiers, unit economics, gross margin, moats, regulatory exposure (COPPA/FERPA/AI-in-classroom), 2nd-order societal effects.</p><div class="catches"><b>Catches:</b> is this check-writable? is the funnel real?</div></div>
        <div class="lens teal"><h5>Technical</h5><div class="lens-skill">/technical-expert-panel · /security-expert-panel</div><p>Architecture, testability, performance, security, accessibility, DevEx/CI, mobile/iPad constraints, model/inference design.</p><div class="catches"><b>Catches:</b> will it hold up? is it testable? where does it break?</div></div>
        <div class="lens purple"><h5>SME (domain)</h5><div class="lens-skill">/asl-expert-panel · /superbuilders-patrick-panel</div><p>Domain experts speaking in voice — ASL linguists, Deaf engineers, Direct-Instruction scholars, integration leads. Pedagogy, domain correctness, cultural soundness.</p><div class="catches"><b>Catches:</b> is it right for the domain? is it tone-deaf?</div></div>
        <div class="lens green"><h5>Users</h5><div class="lens-skill">/user-panel</div><p>The people who'll actually touch it, in first person — kids, parents, teachers, operators. Names every hands-on persona (see P5 → tests).</p><div class="catches"><b>Catches:</b> does it feel like exploration, or homework?</div></div>
      </div>
    </div>

    <div class="deep-sec">
      <div class="deep-title">How a panel runs</div>
      <ol class="proto">
        <li><b>Select lenses by domain</b> — 1 (fast) or 3 (full). A healthcare build weights Technical/Security heaviest; a kids' app leads with Users + SME.</li>
        <li><b>Name the panelists</b> — real, opinionated personas with a stake, not "an expert." Named people argue; "an expert" hedges.</li>
        <li><b>Prompt each through the pillars</b> + the enhanced PRD — every panelist reacts to a specific requirement or PRD section, never the doc in general.</li>
        <li><b>Each speaks in voice</b> with one concrete ask — a change they'd make, rooted in their discipline.</li>
        <li><b>Synthesize</b> into convergent / divergent / risks / open, each line carrying its source panelist.</li>
        <li><b>Hand the synthesis to G1</b> (direction &amp; priority) — the operator sets priority with this in hand. The transcripts are not the deliverable; the synthesis is.</li>
      </ol>
    </div>

    <div class="deep-sec">
      <div class="deep-title">Synthesis schema — what lands in 03-panels/synthesis.md</div>
      <table class="idx"><thead><tr><th style="width:20%">Section</th><th>Contents</th></tr></thead><tbody>
        <tr><td class="k">Convergent</td><td>Where the panels agree — the load-bearing consensus the spec can rely on.</td></tr>
        <tr><td class="k">Divergent</td><td>Where they disagree — surfaced for the operator to resolve at G1, never silently averaged.</td></tr>
        <tr><td class="k">Risks</td><td>Named failure modes with the panelist who raised each, ranked by stakes.</td></tr>
        <tr><td class="k">Open</td><td>Questions the panels couldn't settle → routed to P3 grounding research or the G1 undecidable batch.</td></tr>
      </tbody></table>
    </div>

    <div class="deep-sec">
      <div class="deep-title">Escalation — 1st vs 2nd order</div>
      <div class="deep-sub"><b>Default is three 1st-order panels.</b> A 2nd-order panel (experts critiquing the 1st-order panel's output) is escalation, not routine — it roughly doubles cost for marginal gain on most builds.</div>
      <div class="deep-note"><b>Add a 2nd-order panel only when</b> a 1st-order panel disagrees internally on a load-bearing decision · the decision is irreversible (architecture lock-in, public commitment, a contract) · or the stakes cross a defined threshold (compliance, safety, reputation).</div>
    </div>

    <div class="deep-sec">
      <div class="deep-title">The panel library — every panel skill</div>
      <div class="deep-sub">Panels are <b>composed</b> from this library by domain; panelists are named per project. New domains add a new panel skill rather than overloading an existing one.</div>
      <table class="idx"><thead><tr><th style="width:30%">Panel skill</th><th style="width:14%">Lens</th><th>When to convene it</th></tr></thead><tbody>
        <tr><td class="k">/business-expert-panel</td><td>Business</td><td>Market / GTM / pricing / unit economics / regulatory — "is this fundable?"</td></tr>
        <tr><td class="k">/technical-expert-panel</td><td>Technical</td><td>Architecture, testability, perf, a11y, DevEx — general build soundness.</td></tr>
        <tr><td class="k">/security-expert-panel</td><td>Technical</td><td>Threat model, adversarial AI, compliance — weight up for healthcare/finance.</td></tr>
        <tr><td class="k">/asl-technical-panel</td><td>Technical</td><td>On-device / browser inference, datasets, camera UX — vision-model builds.</td></tr>
        <tr><td class="k">/asl-expert-panel</td><td>SME</td><td>ASL linguists, Deaf community, interpreters — domain + cultural correctness.</td></tr>
        <tr><td class="k">/superbuilders-patrick-panel</td><td>SME</td><td>Alpha/Primer/Direct-Instruction lens — mission + integration readiness.</td></tr>
        <tr><td class="k">/user-panel</td><td>Users</td><td>Kids / parents / teachers / operators in first person — felt-sense gut-check.</td></tr>
      </tbody></table>
    </div>
   '''),

 dict(slug="p3-research", ph="P3", name="Grounding Research", arc="Arc 1 · Understand", kind="phase",
   what="Resolves the <code>[OPEN]</code> questions surfaced by decomposition and panels, and <b>verifies external data availability</b> under a VERIFIED / UNVERIFIED protocol.",
   fixed="The VERIFIED/UNVERIFIED protocol; cite-on-demand into the spec, not a separate doc.",
   dynamic="Which questions get researched; which sources are pulled.",
   example="“Is there a free ASL handshape dataset with a usable license?” → a grounding note with options, evidence, a recommendation, a fallback, and a VERIFIED/UNVERIFIED tag.",
   value="Front-loaded knowledge gets read once and ignored; cite-on-demand grounding lands in the spec where it supports a decision, every time it's needed.",
   reads=["[OPEN] questions"], writes=["02-grounding/{question}.md"], exemplar=False,
   deep='''
    <div class="deep-sec">
      <div class="deep-title">The VERIFIED / UNVERIFIED protocol</div>
      <div class="deep-sub">Research is timeboxed and every claim is tagged, so the spec never rests on something nobody actually checked.</div>
      <div class="lens-grid">
        <div class="lens green"><h5>VERIFIED</h5><p>Confirmed against a primary source the agent actually fetched — a doc, a dataset license, a real API response. Safe to build on.</p></div>
        <div class="lens blue"><h5>UNVERIFIED</h5><p>Plausible but unconfirmed — recorded as a risk, never silently treated as fact (Constitution Art. I: no invented facts).</p></div>
      </div>
    </div>
    <div class="deep-sec">
      <div class="deep-title">What a grounding note contains</div>
      <table class="idx"><thead><tr><th style="width:24%">Field</th><th>Contents</th></tr></thead><tbody>
        <tr><td class="k">Options</td><td>The candidate answers considered.</td></tr>
        <tr><td class="k">Evidence</td><td>Sources actually consulted, with what each says.</td></tr>
        <tr><td class="k">Recommendation</td><td>The chosen answer and why.</td></tr>
        <tr><td class="k">Fallback</td><td>What to do if the recommendation proves wrong at build time.</td></tr>
        <tr><td class="k">Verification</td><td>VERIFIED / UNVERIFIED tag per claim.</td></tr>
      </tbody></table>
    </div>
    <div class="deep-sec">
      <div class="deep-title">Cite-on-demand, not a research dump</div>
      <div class="deep-note">Citations land in the <b>spec section they support</b>, at the moment they're needed — not in a front-loaded "research doc" that's read once and ignored. A note in <code>02-grounding/</code> exists only to resolve a specific <code>[OPEN]</code> question and then feeds the spec or the G1 batch.</div>
    </div>
   '''),

 dict(slug="g1", ph="G1", name="Direction & priority", arc="Human gate", kind="gate",
   what="<b>You set direction and priority</b>, informed by the panels: resolve divergences, rank <b>MUST/SHOULD/COULD</b> (moved here from G0), answer the <b>undecidable batch</b>, and <b>sign BUILD-AUTONOMY.md</b>. Pre-screened by <b>Adversarial · Feasibility</b>.",
   fixed="The gate position (after P3); the undecidable batch; the all-or-nothing standing authorization.",
   dynamic="The priority calls and the deploy target / spend ceiling you sign.",
   example="You rank a contested FR as SHOULD (the panel split on it), answer the one undecidable — “SQLite, not Postgres” — written back to the spec with <code>basis=spec</code>, and sign BUILD-AUTONOMY with the deploy target + spend ceiling. The build now runs to completion, bounded by the fixed stop-condition set.",
   value="One place to set strategy with expert input in hand, and to grant the autonomy that lets the rest of the build run unattended.",
   reads=["03-panels/synthesis.md","02-grounding/*.md"], writes=["BUILD-AUTONOMY.md (signed)"], exemplar=False,
   deep='''
    <div class="deep-sec">
      <div class="deep-title">The two pre-screen agents</div>
      <div class="lens-grid">
        <div class="lens purple"><h5>Adversarial</h5><p>Attacks the proposed direction — finds the weakest assumption, the unstated dependency, the "this only works if…" before you commit.</p></div>
        <div class="lens blue"><h5>Feasibility</h5><p>Can the chosen direction actually be built within the implied budget and stack? Flags the strategy that's sound on paper but unbuildable.</p></div>
      </div>
    </div>
    <div class="deep-sec">
      <div class="deep-title">What you decide at G1</div>
      <ol class="proto">
        <li><b>Resolve divergences</b> the panels surfaced — pick a side on each load-bearing disagreement.</li>
        <li><b>Set MUST/SHOULD/COULD priority</b> — moved here from G0, now made with panel input in hand.</li>
        <li><b>Answer the undecidable batch</b> — written back to the spec with <code>basis=spec</code>.</li>
        <li><b>Sign BUILD-AUTONOMY</b> — deploy target, spend ceiling, confirm the stop-condition set.</li>
      </ol>
    </div>
    <div class="deep-sec">
      <div class="deep-title">The undecidable batch</div>
      <div class="deep-note">PRD-silent forks where the spec gives no basis to choose are <b>collected and brought to you once</b> — not one-at-a-time mid-build. This is what lets the build run unattended afterward: the hard human calls are front-loaded into a single batch at G1.</div>
    </div>
    <div class="deep-sec">
      <div class="deep-title">Standing authorization — all-or-nothing</div>
      <div class="deep-note">A signed <code>BUILD-AUTONOMY.md</code> + <code>CONSTITUTION.md</code> + the locked PRD = <b>run-to-completion without per-step gates</b>. The stop-condition set is fixed and <b>not overridable</b>: destructive/irreversible · outward-facing (push/deploy/publish) · spends money · genuinely-undecidable high-stakes fork. Authorization expands what runs without <i>asking</i> — never what runs without <i>stopping</i>.</div>
    </div>
   '''),

 dict(slug="p4-spec", ph="P4", name="Spec Derivation", arc="Arc 2 · Specify", kind="phase",
   what="Derives the spec from the PRD as a <b>maintained diff</b> — never duplicated — traces every requirement, and emits the interface <b>contracts</b> and the <b>workflow state machine</b> the tests will come from.",
   fixed="One document with a diff; every req maps to a section or [OUT OF SCOPE]; every section is [FROM PRD] or [DERIVED].",
   dynamic="The architecture, the contracts, the workflow nodes — all project-specific.",
   example="<code>### S-04 [DERIVED]</code> traces to <code>FR-7</code>; the workflow state machine becomes <code>docs/workflows.json</code>, which the eval harness reads node-by-node.",
   value="Two parallel docs drift within a week. The diff <i>is</i> the value — it's the audit trail and the change log when the gap loop fires.",
   reads=["01-intake/PRD.md"], writes=["04-spec/spec.md","04-spec/workflow.md","04-spec/architecture.md","04-spec/CONTRACTS.md","docs/workflows.json"], exemplar=False,
   deep='''
    <div class="deep-sec">
      <div class="deep-title">Derived, not duplicated — the maintained diff</div>
      <div class="deep-note">One document, diffed against the locked PRD. <b>Every PRD requirement maps to a spec section or an explicit <code>[OUT OF SCOPE]</code>; every section is tagged <code>[FROM PRD §x]</code> or <code>[DERIVED]</code>.</b> Two parallel docs drift within a week — the diff is the value, and it becomes the change log when the gap loop fires.</div>
    </div>
    <div class="deep-sec">
      <div class="deep-title">What P4 emits</div>
      <table class="idx"><thead><tr><th style="width:26%">Artifact</th><th>Role</th></tr></thead><tbody>
        <tr><td class="k">04-spec/spec.md</td><td>The derived spec — sections <code>S-NN</code>, each traced to a requirement.</td></tr>
        <tr><td class="k">04-spec/workflow.md</td><td>The <b>workflow state machine</b> — data-in / processing / data-out per node.</td></tr>
        <tr><td class="k">04-spec/architecture.md</td><td>Components <code>C-NN</code> and how they fit.</td></tr>
        <tr><td class="k">04-spec/CONTRACTS.md</td><td>The interface seams pinned before parallel build (P6a-gate).</td></tr>
        <tr><td class="k">docs/workflows.json</td><td>The runnable workflow defs — same nodes the eval harness reads.</td></tr>
      </tbody></table>
    </div>
    <div class="deep-sec">
      <div class="deep-title">The workflow state machine is the test source</div>
      <div class="deep-note"><code>workflow.md</code> declares <b>data-in / processing / data-out</b> per node, plus branches and failure paths. P5 turns each node into a test, each branch into a negative test. <b>State that isn't drawn here is a test you won't write — and a bug you won't catch.</b></div>
    </div>
   '''),

 dict(slug="p5-tasks-eval", ph="P5", name="Tasks + Eval Harness", arc="Arc 2 · Specify", kind="phase",
   what="Sizes the implementor fan-out, then <b>generates the immutable eval harness from the workflow state machine and locks it</b>. The harness is <b>task-00</b> — the root of the task graph that every other task depends on.",
   fixed="task-00 is the blocking root; the harness is immutable after P5; agents extend tests, never edit them.",
   dynamic="The actual test cases, derived from this project's workflow nodes and branches.",
   example="Each workflow node → a test (arrange from <code>in</code>, act from <code>proc</code>, assert from <code>out</code>); each branch → a negative test; each failure path → a recovery test.",
   value="Tests are the spec, locked before any feature code. A failing test means the code is wrong (or the spec is — re-derive it; never weaken the test).",
   reads=["04-spec/workflow.md"], writes=[".rapid/TASKS.json",".rapid/EVAL/ (locked)","04-spec/agents/*.md","CI config"], exemplar=False,
   deep='''
    <div class="deep-sec">
      <div class="deep-title">task-00 — the eval harness is the root of the graph</div>
      <div class="deep-note">The harness is <code>task-00</code>: <code>depends_on:[]</code>, and <b>every other task depends on it</b>. The supervisor verifies <code>task-00</code> is <code>done</code> before assigning any other task. Tests-before-code isn't a guideline here — it's the shape of the dependency graph.</div>
    </div>
    <div class="deep-sec">
      <div class="deep-title">How tests are generated from the workflow</div>
      <ol class="proto">
        <li><b>Each node → a test</b> — arrange from its <code>in</code>, act from its <code>proc</code>, assert on its <code>out</code>.</li>
        <li><b>Each branch → a negative test</b> — the path not taken still has to behave.</li>
        <li><b>Each failure path → a recovery test</b> — errors are designed for, not hoped against.</li>
      </ol>
    </div>
    <div class="deep-sec">
      <div class="deep-title">Immutable after P5</div>
      <div class="deep-note">Agents <b>EXTEND</b> tests, never <b>EDIT</b> them to make code pass. A failing test means the code is wrong — or the spec is, in which case you re-derive the spec and never weaken the test (Constitution Art. VII: no test theater).</div>
    </div>
    <div class="deep-sec">
      <div class="deep-title">Fan-out sizing</div>
      <table class="idx"><thead><tr><th style="width:30%">Task count</th><th>Implementors</th></tr></thead><tbody>
        <tr><td class="k">≤ 5 tasks</td><td>1 coder (fans out subagents)</td></tr>
        <tr><td class="k">6 – 12 tasks</td><td>2 coder terminals</td></tr>
        <tr><td class="k">13+ tasks</td><td>3 – 4 coder terminals (+ 1 watchdog)</td></tr>
      </tbody></table>
      <div class="deep-sub" style="margin-top:8px;">Beyond 4 implementors, honest review degrades and supervisor arbitration becomes noise — sequence two rounds of 4 rather than fanning out 8.</div>
    </div>
   '''),

 dict(slug="p5b-deepen", ph="P5b", name="Spec Deepening", arc="Arc 2 · Specify", kind="phase",
   what="Three subagents — a <b>flow analyzer</b>, a <b>confidence checker</b>, and a <b>deliverable verifier</b> — hunt for gaps in the spec <i>before</i> the point of no return, surfacing blocking questions for G2.",
   fixed="The three deepening lenses; any LOW-confidence or missing flow becomes a blocking G2 question.",
   dynamic="What they find — specific to the spec's weak spots.",
   example="The flow analyzer notices a workflow branch with no defined recovery path → a blocking question lands in <code>.rapid/DEEPENING.md</code> for you to resolve at G2.",
   value="The last cheap chance to fix ambiguity before the keys change hands and rework gets expensive.",
   reads=["04-spec/spec.md"], writes=[".rapid/DEEPENING.md"], exemplar=False,
   deep='''
    <div class="deep-sec">
      <div class="deep-title">Three deepening subagents</div>
      <div class="deep-sub">A last sweep for ambiguity before the point of no return — three lenses, each hunting a different kind of hole.</div>
      <div class="lens-grid">
        <div class="lens teal"><h5>Flow analyzer</h5><p>Walks the workflow state machine for branches and failure paths with no defined behaviour or recovery.</p></div>
        <div class="lens purple"><h5>Confidence checker</h5><p>Rates each spec section HIGH / MEDIUM / LOW; any LOW becomes a blocking question.</p></div>
        <div class="lens blue"><h5>Deliverable verifier</h5><p>Checks every promised artifact has a home, an owner, and a test that will cover it.</p></div>
      </div>
    </div>
    <div class="deep-sec">
      <div class="deep-title">Findings become blocking G2 questions</div>
      <div class="deep-note">Any LOW-confidence section or missing flow is written to <code>.rapid/DEEPENING.md</code> as a <b>blocking question</b> the operator must resolve at G2. This is the last <i>cheap</i> chance to fix ambiguity — after G2, the same fix means re-entering P4–P5.</div>
    </div>
   '''),

 dict(slug="g2", ph="G2", name="Point of no return", arc="Human gate", kind="gate", por=True,
   what="<b>You hand over the keys.</b> Approve the final spec / architecture / tasks / eval, the cost projection, the deploy target, and the <code>.env</code> values. Pre-screened by <b>Scope · Coherence · Adversarial</b> + deepening findings. After this, the build proceeds; no major redirect without re-entering P4–P5.",
   fixed="The gate position (after P5b); the inputs ledger must be fully resolved.", dynamic="The spec you approve and the credentials you provide.",
   example="A credential row only counts resolved once its <code>.env:KEY</code> actually exists — the gate fails closed otherwise.",
   value="The single most consequential decision — everything after runs autonomously against what you lock here.",
   reads=["04-spec/*",".rapid/EVAL/",".rapid/COST.json"], writes=["spec locked · eval locked · cost budgeted"], exemplar=False,
   deep='''
    <div class="deep-sec">
      <div class="deep-title">The 3 + 3 pre-screen</div>
      <div class="deep-sub">Three doc-review agents — <b>Scope Guardian · Coherence · Adversarial</b> — plus the three deepening findings carried forward from P5b, so nothing flagged as LOW-confidence reaches the operator unexamined.</div>
    </div>
    <div class="deep-sec">
      <div class="deep-title">The inputs ledger — fail-closed</div>
      <div class="deep-note">G2 cannot pass until <b>every required input is resolved or waived</b> in <code>.rapid/INPUTS.json</code>: credentials, deploy target, spend ceiling, resolved undecidables. A credential row counts resolved <b>only once its <code>.env:KEY</code> actually exists</b> — not when someone says it's handled. This turns "gather all input up front" from a hope into a mechanical precondition.</div>
    </div>
    <div class="deep-sec">
      <div class="deep-title">Why it's the point of no return</div>
      <div class="deep-note">After you approve, P6 builds to the <b>locked</b> spec, the eval harness is locked, and cost is budgeted. A major change means <b>re-entering P4–P5</b>, not patching mid-build. Everything downstream runs autonomously against what you lock here — which is why the deepening pass and the fail-closed ledger sit right before it.</div>
    </div>
   '''),

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
              ("watchdog","audits every merge vs spec + Constitution. Never an implementor")],
   deep='''
    <div class="deep-sec">
      <div class="deep-title">The P6 sub-phases</div>
      <ol class="proto">
        <li><b>P6a — Team setup</b>: the planner spins up one terminal per lead and writes each role's brief.</li>
        <li><b>P6a-gate — Pin every shared seam</b>: interfaces in <code>CONTRACTS.md</code> are frozen <i>before</i> fan-out, so parallel coders can't collide on a contract.</li>
        <li><b>P6b — Build loop</b>: coders implement to the locked spec; keep-or-revert after every commit.</li>
        <li><b>P6c — Watchdog loop</b>: a <code>/loop 30m</code> drift audit writes <code>AUDIT.json</code>.</li>
        <li><b>P6d — Monitoring</b>: the orchestrator watches heartbeats, nudges stalls.</li>
        <li><b>P6e — Shutdown handshake</b>: clean teardown, writes <code>P6_EXIT.json</code> — the gate P7 reads.</li>
      </ol>
    </div>
    <div class="deep-sec">
      <div class="deep-title">Five mechanisms — safe by construction</div>
      <table class="idx"><thead><tr><th style="width:30%">Mechanism</th><th>What it guarantees</th></tr></thead><tbody>
        <tr><td class="k">R2 separate auditor</td><td>The watchdog ≠ any implementor — the builder can't skip its own checks.</td></tr>
        <tr><td class="k">R4 immutable evals</td><td><code>.rapid/EVAL/</code> locked after P5 — code follows tests, not the reverse.</td></tr>
        <tr><td class="k">Keep-or-revert</td><td>Any regression after a merge → <code>git reset --hard</code>; only improvements survive.</td></tr>
        <tr><td class="k">Worktree isolation</td><td>Each writer in its own worktree; verified at P6 exit or the gate fails.</td></tr>
        <tr><td class="k">Cost breaker</td><td>Pauses at 80% of the token budget — an explicit human choice, never a silent overrun.</td></tr>
      </tbody></table>
    </div>
    <div class="deep-sec">
      <div class="deep-title">One pipeline, three tracks</div>
      <table class="idx"><thead><tr><th style="width:18%">Track</th><th>P6 team</th></tr></thead><tbody>
        <tr><td class="k">full</td><td>All 5 leads, one terminal each.</td></tr>
        <tr><td class="k">fast</td><td>planner + coder + reviewer + watchdog (tester folds into the coder's keep-or-revert).</td></tr>
        <tr><td class="k">tiny</td><td>the whole loop as subagents under a single planner terminal.</td></tr>
      </tbody></table>
    </div>
    <div class="deep-sec">
      <div class="deep-title">The claude-peers contract</div>
      <div class="deep-note">Leads coordinate over the <b>claude-peers</b> bus (12 message types, JSON envelope); every send/recv is also appended to <code>MESSAGES.json</code> as a durable fallback. Heartbeats every 5m; a lead silent &gt;10m is STALLED and the orchestrator nudges it. Conversation is disposable — the files are the record.</div>
    </div>
   '''),

 dict(slug="p7-test", ph="P7", name="Test + Visual QA", arc="Arc 3 · Execute", kind="phase",
   what="Runs the <b>real per-layer test suite</b>, does <b>visual QA across 3 viewports</b> with screenshot evidence, walks <b>every</b> workflow surface concretely, and records workflow runs — extracting gaps as it goes.",
   fixed="e2e is required to ship; the walkthrough must cover every surface in workflow.md.",
   dynamic="The surfaces, the viewports' content, the recorded runs.",
   example="Playwright flows derived from the workflow map exercise the golden path + named edge cases; <code>.rapid/WALKTHROUGH.md</code> must cover every surface or R1 blocks P8.",
   value="Agents walk the app mechanically first; you become the felt-sense filter, not the regression hunter.",
   reads=["the built app",".rapid/EVAL/"], writes=[".rapid/VERIFY.json","TEST_RESULTS.md","WALKTHROUGH.md",".rapid/RUNS/"], exemplar=False,
   deep='''
    <div class="deep-sec">
      <div class="deep-title">Genuine per-layer verification</div>
      <table class="idx"><thead><tr><th style="width:22%">Layer</th><th>Run with a real exit code (output redirected, never piped)</th></tr></thead><tbody>
        <tr><td class="k">build</td><td>compiles / bundles clean.</td></tr>
        <tr><td class="k">lint</td><td>style + static analysis pass.</td></tr>
        <tr><td class="k">unit</td><td>the locked harness, green.</td></tr>
        <tr><td class="k">e2e</td><td><b>required to ship</b> unless explicitly waived — <code>VERIFY.json.verification_real == true</code>.</td></tr>
      </tbody></table>
    </div>
    <div class="deep-sec">
      <div class="deep-title">Visual QA + walkthrough</div>
      <ol class="proto">
        <li><b>Playwright flows</b> derived from the workflow map exercise the golden path + named edge cases.</li>
        <li><b>Screenshots across 3 viewports</b>, compared to the hi-fi comps approved at G2.</li>
        <li><b>A concrete walkthrough of every surface</b> → <code>WALKTHROUGH.md</code>; R1 blocks P8 unless it covers every surface in <code>workflow.md</code>.</li>
      </ol>
    </div>
    <div class="deep-sec">
      <div class="deep-title">Recorded runs → the Test Theater</div>
      <div class="deep-note">Each workflow is replayed and recorded to <code>.rapid/RUNS/</code> and published to <code>docs/testruns.json</code> — the Test Theater shows the run node-by-node, data-in → data-out. Integration tests hit <b>real sandboxed</b> DBs/APIs, not mocks (Art. VII). Agents walk first; you're the <b>felt-sense filter</b>, not the regression hunter.</div>
    </div>
   '''),

 dict(slug="p8-gaps", ph="P8", name="Gap Loop + Optimization", arc="Arc 3 · Execute", kind="phase",
   what="<b>Classifies every gap</b> by pillar + severity, auto-fixes BLOCKER/HIGH <i>spec-level</i> gaps (capped at <b>3</b> iterations), runs the optimization experiment <b>once</b>, and surfaces the rest to G3.",
   fixed="3-iteration cap on spec-level auto-fix; PRD-level gaps surface to G3 (never guessed); optimization runs once.",
   dynamic="The gaps themselves and which optimization is tried.",
   example="A spec-level gap re-derives the relevant section (≤3×); a PRD-level gap is written up for your G3 decision rather than silently assumed.",
   value="Bounded convergence — the loop terminates instead of chasing a moving target, and PRD-level calls stay with you.",
   reads=["gaps from P7"], writes=[".rapid/GAPS.json",".rapid/OPTIMIZE.json"], exemplar=False,
   deep='''
    <div class="deep-sec">
      <div class="deep-title">Every gap is classified</div>
      <div class="deep-sub">A gap isn't just "a bug" — it carries enough metadata to route and prioritize it.</div>
      <table class="idx"><thead><tr><th style="width:22%">Field</th><th>Values</th></tr></thead><tbody>
        <tr><td class="k">type</td><td>stub · conformance · bug · spec · arch · feature · integration · optimization</td></tr>
        <tr><td class="k">severity</td><td>BLOCKER · CRITICAL · MAJOR · MINOR · (HIGH / MEDIUM / LOW)</td></tr>
        <tr><td class="k">pillar</td><td>which pillar it threatens — ties severity back to what matters</td></tr>
        <tr><td class="k">refs</td><td>spec_ref / prd_ref / file:line — deduped by a stable id</td></tr>
      </tbody></table>
    </div>
    <div class="deep-sec">
      <div class="deep-title">The loop — bounded convergence</div>
      <ol class="proto">
        <li><b>Classify</b> every gap from P7.</li>
        <li><b>Auto-fix BLOCKER/HIGH spec-level gaps</b> — re-derive the affected section, <b>capped at 3 iterations</b> so it terminates.</li>
        <li><b>PRD-level gaps surface to G3</b> as an explicit operator ask — never silently guessed.</li>
      </ol>
    </div>
    <div class="deep-sec">
      <div class="deep-title">Optimization runs once</div>
      <div class="deep-note">For MEDIUM/LOW gaps: up to 3 parallel worktree experiments, measured against the relevant pillar's metric, keep the best. <b>Once — not a loop</b>, so it can't chase diminishing returns past the point of value.</div>
    </div>
   '''),

 dict(slug="g3", ph="G3", name="Ship decision", arc="Human gate", kind="gate",
   what="<b>You decide: ship / loop / redirect / kill.</b> Review the working app, spec-compliance % per domain, tests + visual QA, gaps (resolved &amp; remaining), and cost actual vs projection. The ship gate <b>blocks on unresolved stubs</b>.",
   fixed="The gate position (after P8); the four options; the stub block.", dynamic="The evidence bundle, specific to this build.",
   example="“Ship” → P9; “Loop” → back to P8 with constraints; “Redirect” → re-run from a phase; “Kill” → stop + retro.",
   value="The release call stays human — with a complete, honest evidence bundle and a hard stub block behind it.",
   reads=["the app",".rapid/AUDIT.json",".rapid/GAPS.json",".rapid/COST.json"], writes=["operator decision"], exemplar=False,
   deep='''
    <div class="deep-sec">
      <div class="deep-title">The evidence bundle you review</div>
      <table class="idx"><thead><tr><th style="width:28%">Evidence</th><th>From</th></tr></thead><tbody>
        <tr><td class="k">Working app</td><td>the deployed-local build you actually click through</td></tr>
        <tr><td class="k">Spec-compliance % per domain</td><td><code>.rapid/AUDIT.json</code> (watchdog)</td></tr>
        <tr><td class="k">Tests + visual QA</td><td><code>VERIFY.json</code> · <code>WALKTHROUGH.md</code></td></tr>
        <tr><td class="k">Gaps resolved / remaining</td><td><code>.rapid/GAPS.json</code></td></tr>
        <tr><td class="k">Cost actual vs projection</td><td><code>.rapid/COST.json</code></td></tr>
      </tbody></table>
    </div>
    <div class="deep-sec">
      <div class="deep-title">Four options</div>
      <table class="idx"><thead><tr><th style="width:20%">Decision</th><th>Effect</th></tr></thead><tbody>
        <tr><td class="k">Ship</td><td>→ P9 deploy + document</td></tr>
        <tr><td class="k">Loop</td><td>→ back to P8 with constraints</td></tr>
        <tr><td class="k">Redirect</td><td>→ re-run from an earlier phase</td></tr>
        <tr><td class="k">Kill</td><td>→ stop + retrospective</td></tr>
      </tbody></table>
    </div>
    <div class="deep-sec">
      <div class="deep-title">The stub block (R9)</div>
      <div class="deep-note">The ship gate <b>blocks release while any required module still contains a stub</b>. A "working app" demo can't paper over a placeholder — the scanner reads the tree, not the screenshot.</div>
    </div>
   '''),

 dict(slug="p9-deploy", ph="P9", name="Deploy + Document", arc="Arc 3 · Execute", kind="phase",
   what="Deploys the product, writes the <b>README + RUNBOOK</b>, runs the <b>retro</b>, generates the doc decks, and deploys the <b>Atlas alongside the product</b> at <code>/_atlas</code>.",
   fixed="Deploy is outward-facing — it stops for your authorization; the retro reviews any Article VI–X overrides.",
   dynamic="The deploy target and the product-specific docs.",
   example="The same Atlas you're reading is generated for the built project and shipped next to it, so the next developer lands in a navigable map.",
   value="Ship + document in one move, with no manual cleanup — the docs are already live from the post-write hook.",
   reads=["the shipped app"], writes=["deployed product","README.md","RUNBOOK.md",".rapid/RETRO.md","doc decks","Atlas at /_atlas"], exemplar=False,
   deep='''
    <div class="deep-sec">
      <div class="deep-title">Deploy is outward-facing — it stops for you</div>
      <div class="deep-note">Deploy leaves the machine, so it sits in the <b>fixed stop-condition set</b>: even under signed standing autonomy, the build <b>pauses for explicit authorization</b> before it pushes or publishes.</div>
    </div>
    <div class="deep-sec">
      <div class="deep-title">What ships alongside the product</div>
      <table class="idx"><thead><tr><th style="width:24%">Artifact</th><th>Role</th></tr></thead><tbody>
        <tr><td class="k">README.md</td><td>What it is + how to run it.</td></tr>
        <tr><td class="k">RUNBOOK.md</td><td>How to operate it — deploy, roll back, debug.</td></tr>
        <tr><td class="k">.rapid/RETRO.md</td><td>What worked / drifted; reviews every Article VI–X override.</td></tr>
        <tr><td class="k">Atlas at /_atlas</td><td>This developer view, shipped next to the product.</td></tr>
      </tbody></table>
    </div>
    <div class="deep-sec">
      <div class="deep-title">No post-build cleanup</div>
      <div class="deep-note">The docs are already live from the post-write hook (registry + CHANGES.md kept current on every write). P9 <b>publishes</b> — it doesn't reconstruct a doc site at the end.</div>
    </div>
   '''),

 dict(slug="p10-pulse", ph="P10", name="Product Pulse", arc="Arc 3 · Compound", kind="phase",
   what="Post-ship, produces a <b>time-windowed usage / performance / error / feedback report</b> that feeds the <b>next build's P0</b> — closing the compound loop.",
   fixed="The report format; the pulse → vision loop.",
   dynamic="The data sources (analytics, error tracking, logs) for this product.",
   example="A weekly pulse note in <code>docs/pulse-reports/</code> surfaces the top error and the least-used feature — which become inputs to the next build's pillars.",
   value="<b>The loop is the product.</b> Each build's pulse makes the next build start smarter; a single build is just an artifact.",
   reads=["analytics · errors · logs"], writes=["docs/pulse-reports/YYYY-MM-DD.md"], exemplar=False,
   deep='''
    <div class="deep-sec">
      <div class="deep-title">The pulse report</div>
      <table class="idx"><thead><tr><th style="width:24%">Signal</th><th>What it surfaces</th></tr></thead><tbody>
        <tr><td class="k">Usage</td><td>What's actually used — and the feature nobody touches.</td></tr>
        <tr><td class="k">Performance</td><td>Real-world latency / cost vs the pillar targets.</td></tr>
        <tr><td class="k">Errors</td><td>The top failure in production, with frequency.</td></tr>
        <tr><td class="k">Feedback</td><td>What users say, routed to the next build's intake.</td></tr>
      </tbody></table>
    </div>
    <div class="deep-sec">
      <div class="deep-title">The compound loop closes here</div>
      <div class="deep-note">The pulse feeds the <b>next build's P0</b> — the top error and the least-used feature become inputs to the next set of pillars. <code>LEARNINGS.md</code> carries forward so each build starts where the last one left off, not from scratch.</div>
    </div>
    <div class="deep-sec">
      <div class="deep-title">The loop is the product</div>
      <div class="deep-note">A one-shot build that ships is a success <i>once</i>. A loop that gets faster and safer every pass is a <b>compounding asset</b> — and that, not any single build, is what Rapid optimizes for.</div>
    </div>
   '''),
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
    {p.get("deep","")}
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
