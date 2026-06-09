#!/usr/bin/env bash
# cost-summary.sh — token + cost monitor/summarizer for a project's work.
#
# Layered, per the design decision:
#   REAL      — actual token usage parsed from Claude Code session transcripts
#               (~/.claude/projects/<encoded-cwd>/*.jsonl), broken down per STEP
#               (each real user prompt), per SESSION, for the WHOLE PROJECT, and
#               per PHASE (each step's billed tokens attributed to the RAPID phase
#               that was active in the observe timeline at the step's timestamp).
#   TOUCHPTS  — human touchpoints per phase: GATE (a human gate was reached) and
#               ESCALATE (a decision was escalated to the human) observe events,
#               plus needs_real_human flags from .rapid/RUNS/*. The two metrics
#               you optimize a build on: $ per phase, and how often it stopped you.
#   ESTIMATE  — RAPID per-phase / per-agent breakdown from .rapid/observe/*.jsonl
#               (ctx_est — a context-size estimate, not billed tokens).
#
# Token counts are exact. Dollar figures are computed from a rate table (no cost
# field exists in the transcripts) — rates are labeled and overridable via env.
#
# Usage:
#   cost-summary.sh                 summarize the current project (cwd)
#   cost-summary.sh /path/to/proj   summarize a specific project dir
#   cost-summary.sh --json          emit machine JSON only (no table)
# Side effect: writes .rapid/COST.json when a .rapid/ dir exists.
#
# Rate overrides (USD per 1M tokens), defaults = Claude Opus 4.8 standard rates:
#   OPUS_IN=5  OPUS_OUT=25  OPUS_CACHE_READ=0.50  OPUS_CW5=6.25  OPUS_CW1=10
set -uo pipefail

JSON_ONLY=0
HTML_OUT=""
PROJECT="$PWD"
for a in "$@"; do
  case "$a" in
    --json) JSON_ONLY=1 ;;
    --html) HTML_OUT="docs/cost.html" ;;
    --html=*) HTML_OUT="${a#--html=}" ;;
    -*) echo "cost-summary: unknown flag $a" >&2; exit 2 ;;
    *) PROJECT="$a" ;;
  esac
done
PROJECT="$(cd "$PROJECT" 2>/dev/null && pwd || echo "$PROJECT")"

# Claude Code encodes the cwd into the session dir name by replacing / with -.
ENCODED=$(printf '%s' "$PROJECT" | sed 's#/#-#g')
SDIR="$HOME/.claude/projects/$ENCODED"

JSON_ONLY="$JSON_ONLY" HTML_OUT="$HTML_OUT" PROJECT="$PROJECT" SDIR="$SDIR" python3 <<'PY'
import os, sys, json, glob

PROJECT = os.environ["PROJECT"]
SDIR    = os.environ["SDIR"]
JSON_ONLY = os.environ.get("JSON_ONLY") == "1"
HTML_OUT  = os.environ.get("HTML_OUT", "")

def rate(name, default):
    try: return float(os.environ.get(name, default))
    except Exception: return default

# USD per 1M tokens — Claude Opus 4.8 standard rates (platform.claude.com/docs pricing,
# verified 2026-05). Token counts are exact; these rates drive the $ only. Override via
# env for other models or fast mode (Opus 4.8 fast = $10 in / $50 out).
R = {
    "in":   rate("OPUS_IN", 5.0),
    "out":  rate("OPUS_OUT", 25.0),
    "cr":   rate("OPUS_CACHE_READ", 0.50),
    "cw5":  rate("OPUS_CW5", 6.25),
    "cw1":  rate("OPUS_CW1", 10.0),
}

def cost(in_, out_, cr, cw5, cw1):
    return (in_*R["in"] + out_*R["out"] + cr*R["cr"] + cw5*R["cw5"] + cw1*R["cw1"]) / 1_000_000

def is_real_prompt(rec):
    """A genuine user turn (not a tool_result echoed back as a user message)."""
    if rec.get("type") != "user": return False
    if rec.get("isSidechain"): return False
    m = rec.get("message") or {}
    c = m.get("content")
    if isinstance(c, str):
        return bool(c.strip())
    if isinstance(c, list):
        has_text = any(isinstance(x, dict) and x.get("type") == "text" and x.get("text", "").strip() for x in c)
        is_tool  = any(isinstance(x, dict) and x.get("type") == "tool_result" for x in c)
        return has_text and not is_tool
    return False

def prompt_text(rec):
    m = rec.get("message") or {}
    c = m.get("content")
    if isinstance(c, str): return c.strip()
    if isinstance(c, list):
        for x in c:
            if isinstance(x, dict) and x.get("type") == "text":
                return x.get("text", "").strip()
    return ""

# --- load + globally order every timestamped record across all sessions ------
records = []
files = sorted(glob.glob(os.path.join(SDIR, "*.jsonl")))
for fi, fp in enumerate(files):
    try:
        with open(fp) as fh:
            for li, line in enumerate(fh):
                line = line.strip()
                if not line: continue
                try: d = json.loads(line)
                except Exception: continue
                ts = d.get("timestamp")
                if not ts: continue
                records.append(((ts, fi, li), d))
    except Exception:
        continue
records.sort(key=lambda r: r[0])

# --- walk in order: accrue each assistant turn's usage to the current step ----
def new_step(idx, rec):
    return {
        "n": idx, "ts": rec.get("timestamp", ""),
        "session": (rec.get("sessionId") or "")[:8],
        "prompt": prompt_text(rec)[:70].replace("\n", " "),
        "in": 0, "out": 0, "cr": 0, "cw5": 0, "cw1": 0, "turns": 0,
    }

steps, cur = [], None
sessions = {}
for _, rec in records:
    if is_real_prompt(rec):
        cur = new_step(len(steps) + 1, rec)
        steps.append(cur)
    if rec.get("type") == "assistant":
        m = rec.get("message") or {}
        u = m.get("usage") or {}
        if not u: continue
        cc = u.get("cache_creation") or {}
        vals = dict(
            in_=u.get("input_tokens", 0) or 0,
            out=u.get("output_tokens", 0) or 0,
            cr=u.get("cache_read_input_tokens", 0) or 0,
            cw5=cc.get("ephemeral_5m_input_tokens", 0) or 0,
            cw1=cc.get("ephemeral_1h_input_tokens", 0) or 0,
        )
        # fall back to flat cache_creation_input_tokens if the split is absent
        if not (vals["cw5"] or vals["cw1"]):
            vals["cw5"] = u.get("cache_creation_input_tokens", 0) or 0
        target = cur if cur is not None else None
        if target is None:  # assistant output before any captured prompt
            cur = {"n": 0, "ts": rec.get("timestamp", ""), "session": (rec.get("sessionId") or "")[:8],
                   "prompt": "(pre-prompt / session start)", "in": 0, "out": 0, "cr": 0, "cw5": 0, "cw1": 0, "turns": 0}
            steps.append(cur); target = cur
        target["in"]  += vals["in_"]; target["out"] += vals["out"]
        target["cr"]  += vals["cr"];  target["cw5"] += vals["cw5"]; target["cw1"] += vals["cw1"]
        target["turns"] += 1

# session sums are derived from the per-step totals (each step has one session)
sessions = {}
for st in steps:
    sid = st["session"]
    s = sessions.setdefault(sid, {"in":0,"out":0,"cr":0,"cw5":0,"cw1":0,"turns":0})
    for k in ("in","out","cr","cw5","cw1","turns"): s[k] += st[k]

for st in steps: st["cost"] = round(cost(st["in"], st["out"], st["cr"], st["cw5"], st["cw1"]), 4)
for sid, s in sessions.items(): s["cost"] = round(cost(s["in"], s["out"], s["cr"], s["cw5"], s["cw1"]), 4)

tot = {k: sum(st[k] for st in steps) for k in ("in","out","cr","cw5","cw1","turns")}
tot["cost"] = round(cost(tot["in"], tot["out"], tot["cr"], tot["cw5"], tot["cw1"]), 4)

# --- observe layer: load every event once (timeline + ctx_est + touchpoints) --
import bisect

def norm_phase(p):
    if p is None: return None
    s = str(p).strip()
    if not s or s == "?": return None
    return s if s[0] in ("P", "p") else "P" + s

obs_events = []
for fp in sorted(glob.glob(os.path.join(PROJECT, ".rapid", "observe", "*.jsonl"))):
    try:
        for line in open(fp):
            line = line.strip()
            if not line: continue
            try: d = json.loads(line)
            except Exception: continue
            if isinstance(d, dict): obs_events.append(d)
    except Exception:
        continue
obs_events.sort(key=lambda d: (str(d.get("t") or ""), d.get("seq") or 0))

# ESTIMATE: ctx_est per phase / per agent (context-size, not billed) — unchanged semantics
rapid = {"by_phase": {}, "by_agent": {}, "total_ctx_est": 0, "available": False}
for d in obs_events:
    ce = d.get("ctx_est")
    if ce is None: continue
    rapid["available"] = True
    ph = norm_phase(d.get("phase")) or "P?"
    ag = d.get("agent", "?")
    rapid["by_phase"][ph] = rapid["by_phase"].get(ph, 0) + ce
    rapid["by_agent"][ag] = rapid["by_agent"].get(ag, 0) + ce
    rapid["total_ctx_est"] += ce

# Phase timeline: phase active as a step-function of wall-clock time. Every observe
# event carries `phase`, so the phase at any timestamp is the phase of the most
# recent event at/before it. PHASE-transition events are the canonical markers but
# any event refines the timeline.
timeline = [(str(d.get("t")), norm_phase(d.get("phase"))) for d in obs_events
            if d.get("t") and norm_phase(d.get("phase"))]
tl_ts = [t for t, _ in timeline]
def phase_at(ts):
    if not timeline or not ts: return None
    i = bisect.bisect_right(tl_ts, str(ts)) - 1
    if i < 0: return timeline[0][1]   # step ran before the first observe event
    return timeline[i][1]

# REAL billed tokens attributed to the phase active at each step's START timestamp.
# A step that straddles a phase boundary is booked whole to its starting phase — an
# honest approximation, noted in the output. No timeline → no attribution (degrades
# to the ctx_est estimate only).
real_by_phase = {}
phase_timeline_available = bool(timeline)
if phase_timeline_available:
    for st in steps:
        if st["n"] == 0: continue
        ph = phase_at(st["ts"]) or "P?"
        b = real_by_phase.setdefault(ph, {"in":0,"out":0,"cr":0,"cw5":0,"cw1":0,"turns":0,"steps":0,"cost":0.0})
        for kk in ("in","out","cr","cw5","cw1","turns"): b[kk] += st[kk]
        b["steps"] += 1
    for ph, b in real_by_phase.items():
        b["cost"] = round(cost(b["in"], b["out"], b["cr"], b["cw5"], b["cw1"]), 4)

# Human touchpoints per phase: GATE (a human gate was reached) + ESCALATE (a
# decision was kicked to the human). Both observe events carry `phase`.
touch = {"by_phase": {}, "total": {"gate": 0, "escalate": 0, "needs_real_human": 0}}
def touch_bucket(ph): return touch["by_phase"].setdefault(ph, {"gate": 0, "escalate": 0})
for d in obs_events:
    ev = str(d.get("event") or "").upper()
    if ev not in ("GATE", "ESCALATE"): continue
    ph = norm_phase(d.get("phase")) or "P?"
    key = "gate" if ev == "GATE" else "escalate"
    touch_bucket(ph)[key] += 1
    touch["total"][key] += 1
# Escalations flagged as needing a REAL human (from workflow-test runs, project-wide).
for fp in glob.glob(os.path.join(PROJECT, ".rapid", "RUNS", "*", "*.jsonl")):
    try:
        for line in open(fp):
            line = line.strip()
            if not line: continue
            try: d = json.loads(line)
            except Exception: continue
            if not isinstance(d, dict): continue
            v = (d.get("data_out") or {}).get("verdict") or {}
            if isinstance(v, dict) and v.get("needs_real_human") is True:
                touch["total"]["needs_real_human"] += 1
    except Exception:
        continue

# Canonical RAPID phase order for any phase-keyed display (HTML + console).
PHASE_ORDER = ["P0","P1","P1b","P2","P3","P4","P4b","P5","P5b","P6","P7","P8","P9","P10"]
def phase_sort_key(p):
    return (PHASE_ORDER.index(p) if p in PHASE_ORDER else len(PHASE_ORDER), p)

out_obj = {
    "project": PROJECT,
    "rates_usd_per_mtok": R,
    "real": {"sessions": len(files), "steps": steps,
             "by_session": sessions, "total": tot,
             "by_phase": real_by_phase, "phase_timeline_available": phase_timeline_available},
    "touchpoints": touch,
    "rapid_estimate": rapid,
}

# --- write .rapid/COST.json when a build dir exists ---------------------------
wrote = None
fdir = os.path.join(PROJECT, ".rapid")
if os.path.isdir(fdir):
    try:
        with open(os.path.join(fdir, "COST.json"), "w") as f:
            json.dump(out_obj, f, indent=2)
        wrote = os.path.join(".rapid", "COST.json")
    except Exception:
        pass

# --- optional: render the docs deck cost page (regenerable artifact) ----------
def k(n): return f"{n/1000:.1f}k" if n < 1_000_000 else f"{n/1_000_000:.2f}M"
def short_ts(ts): return ts[5:16].replace("T", " ") if ts else ""

html_path = None
if HTML_OUT:
    import html as _h
    def esc(s): return _h.escape(s or "")
    _root = PROJECT or os.getcwd()          # the project's own name, not the kit's
    BRAND = "RAPID" if os.path.isfile(os.path.join(_root, "skills", "rapid", "SKILL.md")) \
            else os.path.basename(os.path.normpath(_root))
    NAV = [("prd.html","PRD"),("prd-enhanced.html","Enhanced PRD"),("architecture.html","Architecture"),
           ("workflow.html","Workflow"),("users.html","Users"),("spec.html","Spec"),
           ("observatory.html","Observatory"),("eval.html","Eval"),("cost.html","Cost"),
           ("documentation.html","Documentation")]
    HEAD = """<!doctype html><html lang="en"><head><meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/><title>__BRAND__ — cost</title><style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{--bg:#0D1117;--surface:#161B22;--surface-alt:#1C2330;--border:#2A313B;--border-light:#20262F;
--text:#E6EDF3;--text-muted:#9BA6B2;--text-dim:#6B7480;--navy:#7AA2F7;--blue:#58A6FF;--green:#3FB950;--red:#F85149;--amber:#D29922;--radius:4px}
html{background:var(--bg);color:var(--text);font-family:-apple-system,BlinkMacSystemFont,"Helvetica Neue",sans-serif;font-size:15px;line-height:1.6;-webkit-font-smoothing:antialiased}
.main{max-width:1040px;margin:0 auto;padding:40px 40px 96px}
h1{font-size:1.5rem;font-weight:800;color:var(--navy);margin-bottom:6px}
h2{font-size:1.05rem;font-weight:800;color:var(--navy);margin:32px 0 12px}
.sub{font-size:.82rem;color:var(--text-muted);max-width:760px;margin-bottom:24px}
.tag{font-size:.62rem;font-weight:600;color:var(--text-dim);text-transform:uppercase;letter-spacing:.06em;border:1px solid var(--border-light);border-radius:3px;padding:1px 6px;margin-left:6px;vertical-align:middle}
.cards{display:flex;gap:14px;flex-wrap:wrap;margin-bottom:8px}
.card{flex:1;min-width:150px;background:var(--surface);border:1px solid var(--border-light);border-radius:var(--radius);padding:16px 18px}
.card .big{font-size:1.6rem;font-weight:800;color:var(--navy);line-height:1.1}
.card .lbl{font-size:.7rem;color:var(--text-dim);text-transform:uppercase;letter-spacing:.05em;margin-top:4px}
table.t{width:100%;border-collapse:collapse;font-size:.78rem;margin-bottom:8px}
table.t th{text-align:left;font-size:.65rem;text-transform:uppercase;letter-spacing:.05em;color:var(--text-dim);border-bottom:1px solid var(--border);padding:7px 8px}
table.t td{padding:6px 8px;border-bottom:1px solid var(--border-light);vertical-align:top}
td.r,th.r{text-align:right;font-variant-numeric:tabular-nums}
td.mono,.num{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;color:var(--text-muted)}
td.prompt{color:var(--text);max-width:420px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
td.cost{font-weight:700;color:var(--green)}
tr.total td{border-top:2px solid var(--border);border-bottom:none;font-weight:800;color:var(--navy);padding-top:9px}
.foot{font-size:.72rem;color:var(--text-dim);margin-top:28px}
.rapid-nav{display:flex;align-items:center;background:#1A2744;padding:0 20px;overflow-x:auto;position:sticky;top:0;z-index:1000}
.rapid-nav-brand{display:flex;flex-direction:column;font-size:12px;font-weight:800;color:#fff;letter-spacing:-0.02em;padding:6px 16px 6px 0;margin-right:8px;border-right:1px solid rgba(255,255,255,.15);line-height:1.2}
.rapid-nav-brand .rapid-nav-sub{font-size:7px;font-weight:500;color:rgba(255,255,255,.45);letter-spacing:.06em;text-transform:uppercase}
.rapid-nav a{font-size:9.5px;font-weight:600;color:rgba(255,255,255,.55);text-decoration:none;padding:10px 12px;letter-spacing:.3px;white-space:nowrap;border-bottom:2px solid transparent}
.rapid-nav a:hover{color:rgba(255,255,255,.85)}.rapid-nav a.active{color:#fff;border-bottom-color:#fff}
body{min-height:100vh;display:flex;flex-direction:column}
.spec-layout{display:flex;flex:1}
.docpage-content{flex:1;min-width:0}
.sidebar{width:280px;flex-shrink:0;background:var(--surface);border-right:1px solid var(--border);padding:32px 20px;position:sticky;top:38px;height:calc(100vh - 38px);overflow-y:auto}
.sidebar-brand{font-size:1.1rem;font-weight:800;color:var(--navy);letter-spacing:-0.02em;margin-bottom:4px}
.sidebar-sub{font-size:.7rem;color:var(--text-dim);margin-bottom:24px;font-weight:500}
.sidebar-section{font-size:.55rem;font-weight:700;letter-spacing:.14em;text-transform:uppercase;color:var(--text-dim);margin:20px 0 8px}
.sidebar a{display:block;font-size:.78rem;color:var(--text-muted);text-decoration:none;padding:3px 8px;border-radius:3px;margin:1px 0}
.sidebar a:hover{background:var(--surface-alt);color:var(--text)}
h1,h2{scroll-margin-top:48px}
</style></head><body>"""
    nav = '<nav class="rapid-nav"><span class="rapid-nav-brand">' + esc(BRAND) + ' <span style="font-weight:400;opacity:0.5;font-size:10px;">/ Atlas</span><span class="rapid-nav-sub">developer view</span></span>'
    for href, label in NAV:
        cls = ' class="active"' if href == "cost.html" else ""
        nav += f'<a href="{href}"{cls}>{label}</a>'
    nav += '</nav>'

    step_rows = ""
    for st in steps:
        cw = st["cw5"] + st["cw1"]
        step_rows += (f'<tr><td class="num">{st["n"]}</td><td class="mono">{short_ts(st["ts"])}</td>'
                      f'<td class="prompt" title="{esc(st["prompt"])}">{esc(st["prompt"])}</td>'
                      f'<td class="r">{k(st["in"])}</td><td class="r">{k(st["out"])}</td>'
                      f'<td class="r">{k(st["cr"])}</td><td class="r">{k(cw)}</td>'
                      f'<td class="r cost">${st["cost"]:.2f}</td></tr>')
    sess_rows = ""
    for sid, s in sessions.items():
        cw = s["cw5"] + s["cw1"]
        sess_rows += (f'<tr><td class="mono">{sid}</td><td class="r">{s["turns"]}</td>'
                      f'<td class="r">{k(s["in"])}</td><td class="r">{k(s["out"])}</td>'
                      f'<td class="r">{k(s["cr"])}</td><td class="r">{k(cw)}</td>'
                      f'<td class="r cost">${s["cost"]:.2f}</td></tr>')
    tcw = tot["cw5"] + tot["cw1"]

    # Per-phase REAL billed tokens + human touchpoints (the build-optimization view)
    phase_html = ""
    phases_seen = sorted(set(list(real_by_phase) + list(touch["by_phase"])), key=phase_sort_key)
    if phases_seen:
        rows = ""
        pt = {"in":0,"out":0,"cr":0,"cw5":0,"cw1":0,"cost":0.0,"gate":0,"escalate":0}
        for p in phases_seen:
            b  = real_by_phase.get(p, {})
            tb = touch["by_phase"].get(p, {})
            cw = b.get("cw5",0) + b.get("cw1",0)
            tp = tb.get("gate",0) + tb.get("escalate",0)
            rows += (f'<tr><td class="mono">{p}</td>'
                     f'<td class="r">{k(b.get("in",0))}</td><td class="r">{k(b.get("out",0))}</td>'
                     f'<td class="r">{k(b.get("cr",0))}</td><td class="r">{k(cw)}</td>'
                     f'<td class="r cost">${b.get("cost",0):.2f}</td>'
                     f'<td class="r">{tp or ""}</td></tr>')
            for kk in ("in","out","cr","cw5","cw1","cost"): pt[kk] += b.get(kk,0)
            pt["gate"] += tb.get("gate",0); pt["escalate"] += tb.get("escalate",0)
        tcw2 = pt["cw5"] + pt["cw1"]; ttp = pt["gate"] + pt["escalate"]
        nrh = touch["total"].get("needs_real_human", 0)
        attr_tag = ('attributed by observe phase timeline' if phase_timeline_available
                    else 'no phase timeline — touchpoints only, tokens unattributed')
        nrh_note = (f' · {nrh} flagged needs-real-human' if nrh else '')
        phase_html = ('<h2 id="per-phase">Per phase<span class="tag">real billed · ' + attr_tag + '</span></h2>'
                      '<p class="sub" style="margin:-6px 0 14px">Billed tokens booked to the phase active at each step, '
                      'and the human touchpoints (gates + escalations) that phase cost you' + nrh_note + '.</p>'
                      '<table class="t"><thead><tr><th>phase</th><th class="r">in</th><th class="r">out</th>'
                      '<th class="r">cache-rd</th><th class="r">cache-wr</th><th class="r">$</th>'
                      '<th class="r">touchpts</th></tr></thead><tbody>' + rows
                      + f'<tr class="total"><td>total</td><td class="r">{k(pt["in"])}</td><td class="r">{k(pt["out"])}</td>'
                      f'<td class="r">{k(pt["cr"])}</td><td class="r">{k(tcw2)}</td><td class="r cost">${pt["cost"]:.2f}</td>'
                      f'<td class="r">{ttp or ""}</td></tr></tbody></table>')

    rapid_html = ""
    if rapid["available"]:
        ph = "".join(f'<tr><td class="mono">{p}</td><td class="r">{k(rapid["by_phase"][p])}</td></tr>'
                     for p in sorted(rapid["by_phase"]))
        rapid_html = ('<h2 id="rapid-estimate">RAPID phase estimate<span class="tag">ctx_est · approximate · not billed</span></h2>'
                      '<table class="t"><thead><tr><th>phase</th><th class="r">ctx_est</th></tr></thead><tbody>'
                      + ph + f'<tr class="total"><td>total</td><td class="r">{k(rapid["total_ctx_est"])}</td></tr></tbody></table>')
    nsteps = len([s for s in steps if s["n"] > 0])
    data_through = short_ts(max((st["ts"] for st in steps), default=""))
    sidebar = ('<nav class="sidebar"><div class="sidebar-brand">' + esc(BRAND) + '</div><div class="sidebar-sub">Cost</div>'
               '<div class="sidebar-section">On this page</div>'
               '<a href="#overview">Overview</a><a href="#per-step">Per step</a><a href="#per-session">Per session</a>'
               + ('<a href="#per-phase">Per phase</a>' if phases_seen else '')
               + ('<a href="#rapid-estimate">RAPID phase estimate</a>' if rapid["available"] else '')
               + '</nav>')
    body = (f'<div class="spec-layout">{sidebar}<div class="docpage-content"><main class="main">'
            f'<h1 id="overview">Cost &amp; Token Burn</h1>'
            f'<p class="sub">Real token usage parsed from Claude Code session logs — tokens are exact; '
            f'$ uses the Opus rate table (in ${R["in"]:g} / out ${R["out"]:g} / cache-read ${R["cr"]:g} / '
            f'cache-write ${R["cw5"]:g}–${R["cw1"]:g} per Mtok), adjust if 4.8 pricing differs. Data through {data_through}.</p>'
            f'<div class="cards">'
            f'<div class="card"><div class="big">${tot["cost"]:.2f}</div><div class="lbl">total est. cost</div></div>'
            f'<div class="card"><div class="big">{k(tot["out"])}</div><div class="lbl">output tokens</div></div>'
            f'<div class="card"><div class="big">{nsteps}</div><div class="lbl">steps</div></div>'
            f'<div class="card"><div class="big">{len(files)}</div><div class="lbl">sessions</div></div></div>'
            f'<h2 id="per-step">Per step<span class="tag">each user prompt</span></h2>'
            f'<table class="t"><thead><tr><th>#</th><th>when</th><th>prompt</th><th class="r">in</th><th class="r">out</th>'
            f'<th class="r">cache-rd</th><th class="r">cache-wr</th><th class="r">$</th></tr></thead><tbody>{step_rows}'
            f'<tr class="total"><td colspan="3">whole project</td><td class="r">{k(tot["in"])}</td><td class="r">{k(tot["out"])}</td>'
            f'<td class="r">{k(tot["cr"])}</td><td class="r">{k(tcw)}</td><td class="r cost">${tot["cost"]:.2f}</td></tr></tbody></table>'
            f'<h2 id="per-session">Per session</h2><table class="t"><thead><tr><th>session</th><th class="r">turns</th><th class="r">in</th>'
            f'<th class="r">out</th><th class="r">cache-rd</th><th class="r">cache-wr</th><th class="r">$</th></tr></thead><tbody>{sess_rows}</tbody></table>'
            f'{phase_html}'
            f'{rapid_html}'
            f'<p class="foot">Generated by <code>tools/cost-summary.sh --html</code> — regenerate to refresh.</p>'
            f'</main></div></div>'
            f'<script src="env-links.js" defer></script>'
            f'<script src="sidebar.js" defer></script>'
            f'<script src="rapid-nav.js" defer></script></body></html>')
    op = HTML_OUT if os.path.isabs(HTML_OUT) else os.path.join(PROJECT, HTML_OUT)
    try:
        os.makedirs(os.path.dirname(op), exist_ok=True)
        with open(op, "w") as f: f.write((HEAD + nav + body).replace("__BRAND__", esc(BRAND)))
        html_path = os.path.relpath(op, PROJECT)
    except Exception as e:
        sys.stderr.write(f"cost-summary: could not write {op}: {e}\n")

if JSON_ONLY:
    print(json.dumps(out_obj, indent=2)); sys.exit(0)

# --- human-readable table -----------------------------------------------------
def k(n): return f"{n/1000:.1f}k" if n < 1_000_000 else f"{n/1_000_000:.2f}M"
def short_ts(ts): return ts[5:16].replace("T", " ") if ts else ""

print(f"\nToken & cost summary — {os.path.basename(PROJECT) or PROJECT}")
print(f"rates (USD/Mtok): in ${R['in']:g}  out ${R['out']:g}  cache-read ${R['cr']:g}  "
      f"cache-write ${R['cw5']:g}(5m)/${R['cw1']:g}(1h)   [override via OPUS_IN/OPUS_OUT/...]")
print(f"sessions: {len(files)}   assistant turns: {tot['turns']}   steps (user prompts): {len([s for s in steps if s['n']>0])}")

print("\nREAL BURN — per step (each user prompt), from Claude Code session logs")
print(f"  {'#':>2}  {'when':<12} {'in':>7} {'out':>7} {'cache-rd':>9} {'cache-wr':>9} {'$':>8}  prompt")
for st in steps:
    cw = st["cw5"] + st["cw1"]
    print(f"  {st['n']:>2}  {short_ts(st['ts']):<12} {k(st['in']):>7} {k(st['out']):>7} "
          f"{k(st['cr']):>9} {k(cw):>9} {('$'+format(st['cost'],'.2f')):>8}  {st['prompt']}")

print("\nREAL BURN — per session")
for sid, s in sessions.items():
    cw = s["cw5"] + s["cw1"]
    print(f"  {sid:<10} turns {s['turns']:>3}  in {k(s['in']):>7}  out {k(s['out']):>7}  "
          f"cache-rd {k(s['cr']):>9}  cache-wr {k(cw):>8}  ${s['cost']:.2f}")

cw = tot["cw5"] + tot["cw1"]
print("\nWHOLE PROJECT")
print(f"  input(fresh) {k(tot['in'])}   output {k(tot['out'])}   cache-read {k(tot['cr'])}   cache-write {k(cw)}")
print(f"  >> output is the dominant $ driver.   TOTAL ESTIMATED COST: ${tot['cost']:.2f}")

phases_seen = sorted(set(list(real_by_phase) + list(touch["by_phase"])), key=phase_sort_key)
if phases_seen:
    src = "billed tokens attributed via observe phase timeline" if phase_timeline_available \
          else "no phase timeline — touchpoints only (tokens unattributed)"
    print(f"\nREAL BURN — per phase ({src})")
    print(f"  {'phase':<6} {'in':>7} {'out':>7} {'cache-rd':>9} {'cache-wr':>9} {'$':>8}  touchpoints")
    for p in phases_seen:
        b  = real_by_phase.get(p, {})
        tb = touch["by_phase"].get(p, {})
        cw = b.get("cw5",0) + b.get("cw1",0)
        tp = tb.get("gate",0) + tb.get("escalate",0)
        tpd = (f"{tp} ({tb.get('gate',0)} gate/{tb.get('escalate',0)} esc)" if tp else "")
        print(f"  {p:<6} {k(b.get('in',0)):>7} {k(b.get('out',0)):>7} {k(b.get('cr',0)):>9} "
              f"{k(cw):>9} {('$'+format(b.get('cost',0),'.2f')):>8}  {tpd}")
    tt = touch["total"]
    print(f"  TOUCHPOINTS total: {tt['gate']} gate, {tt['escalate']} escalate"
          + (f", {tt['needs_real_human']} flagged needs-real-human" if tt['needs_real_human'] else ""))

if rapid["available"]:
    print("\nFORGE PHASE ESTIMATE — ctx_est from .rapid/observe (approximate, context-size not billed tokens)")
    for ph in sorted(rapid["by_phase"]):
        print(f"  {ph:<5} ctx_est {k(rapid['by_phase'][ph])}")
    print(f"  agents: " + "  ".join(f"{a}={k(v)}" for a, v in sorted(rapid["by_agent"].items())))
    print(f"  total ctx_est {k(rapid['total_ctx_est'])}  (estimate only)")
else:
    print("\nFORGE PHASE ESTIMATE — no ctx_est observe data found (.rapid/observe/*.jsonl)")

if wrote: print(f"\nwrote {wrote}")
if html_path: print(f"wrote {html_path}")
PY
