#!/usr/bin/env bash
# cost-summary.sh — token + cost monitor/summarizer for a project's work.
#
# Layered, per the design decision:
#   REAL      — actual token usage parsed from Claude Code session transcripts
#               (~/.claude/projects/<encoded-cwd>/*.jsonl), broken down per STEP
#               (each real user prompt), per SESSION, and for the WHOLE PROJECT.
#   ESTIMATE  — FORGE per-phase / per-agent breakdown from .forge/observe/*.jsonl
#               (ctx_est — a context-size estimate, not billed tokens).
#
# Token counts are exact. Dollar figures are computed from a rate table (no cost
# field exists in the transcripts) — rates are labeled and overridable via env.
#
# Usage:
#   cost-summary.sh                 summarize the current project (cwd)
#   cost-summary.sh /path/to/proj   summarize a specific project dir
#   cost-summary.sh --json          emit machine JSON only (no table)
# Side effect: writes .forge/COST.json when a .forge/ dir exists.
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

# --- ESTIMATE layer: FORGE observe ctx_est per phase / per agent --------------
forge = {"by_phase": {}, "by_agent": {}, "total_ctx_est": 0, "available": False}
obs = sorted(glob.glob(os.path.join(PROJECT, ".forge", "observe", "*.jsonl")))
for fp in obs:
    try:
        for line in open(fp):
            line = line.strip()
            if not line: continue
            try: d = json.loads(line)
            except Exception: continue
            ce = d.get("ctx_est")
            if ce is None: continue
            forge["available"] = True
            ph = "P" + str(d.get("phase", "?")).lstrip("P")
            ag = d.get("agent", "?")
            forge["by_phase"][ph] = forge["by_phase"].get(ph, 0) + ce
            forge["by_agent"][ag] = forge["by_agent"].get(ag, 0) + ce
            forge["total_ctx_est"] += ce
    except Exception:
        continue

out_obj = {
    "project": PROJECT,
    "rates_usd_per_mtok": R,
    "real": {"sessions": len(files), "steps": steps,
             "by_session": sessions, "total": tot},
    "forge_estimate": forge,
}

# --- write .forge/COST.json when a build dir exists ---------------------------
wrote = None
fdir = os.path.join(PROJECT, ".forge")
if os.path.isdir(fdir):
    try:
        with open(os.path.join(fdir, "COST.json"), "w") as f:
            json.dump(out_obj, f, indent=2)
        wrote = os.path.join(".forge", "COST.json")
    except Exception:
        pass

# --- optional: render the docs deck cost page (regenerable artifact) ----------
def k(n): return f"{n/1000:.1f}k" if n < 1_000_000 else f"{n/1_000_000:.2f}M"
def short_ts(ts): return ts[5:16].replace("T", " ") if ts else ""

html_path = None
if HTML_OUT:
    import html as _h
    def esc(s): return _h.escape(s or "")
    NAV = [("prd.html","PRD"),("prd-enhanced.html","Enhanced PRD"),("architecture.html","Architecture"),
           ("workflow.html","Workflow"),("users.html","Users"),("spec.html","Spec"),
           ("observatory.html","Observatory"),("eval.html","Eval"),("cost.html","Cost"),
           ("documentation.html","Documentation")]
    HEAD = """<!doctype html><html lang="en"><head><meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/><title>RAPID — cost</title><style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{--bg:#FFF;--surface:#F7F8FA;--surface-alt:#F0F2F5;--border:#D4D8DE;--border-light:#E2E5EA;
--text:#1A2744;--text-muted:#4A5568;--text-dim:#8896A6;--navy:#1A2744;--blue:#2B6CB0;--green:#276749;--red:#C53030;--amber:#B7791F;--radius:4px}
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
.forge-nav{display:flex;align-items:center;background:#1A2744;padding:0 20px;overflow-x:auto;position:sticky;top:0;z-index:1000}
.forge-nav-brand{display:flex;flex-direction:column;font-size:12px;font-weight:800;color:#fff;letter-spacing:-0.02em;padding:6px 16px 6px 0;margin-right:8px;border-right:1px solid rgba(255,255,255,.15);line-height:1.2}
.forge-nav-brand .forge-nav-sub{font-size:7px;font-weight:500;color:rgba(255,255,255,.45);letter-spacing:.06em;text-transform:uppercase}
.forge-nav a{font-size:9.5px;font-weight:600;color:rgba(255,255,255,.55);text-decoration:none;padding:10px 12px;letter-spacing:.3px;white-space:nowrap;border-bottom:2px solid transparent}
.forge-nav a:hover{color:rgba(255,255,255,.85)}.forge-nav a.active{color:#fff;border-bottom-color:#fff}
</style></head><body>"""
    nav = '<nav class="forge-nav"><span class="forge-nav-brand">RAPID <span style="font-weight:400;opacity:0.5;font-size:10px;">/ AI Build Workflow</span><span class="forge-nav-sub">Rapid Autonomous Pipeline for Iterative Development</span></span>'
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
    forge_html = ""
    if forge["available"]:
        ph = "".join(f'<tr><td class="mono">{p}</td><td class="r">{k(forge["by_phase"][p])}</td></tr>'
                     for p in sorted(forge["by_phase"]))
        forge_html = ('<h2>FORGE phase estimate<span class="tag">ctx_est · approximate · not billed</span></h2>'
                      '<table class="t"><thead><tr><th>phase</th><th class="r">ctx_est</th></tr></thead><tbody>'
                      + ph + f'<tr class="total"><td>total</td><td class="r">{k(forge["total_ctx_est"])}</td></tr></tbody></table>')
    nsteps = len([s for s in steps if s["n"] > 0])
    data_through = short_ts(max((st["ts"] for st in steps), default=""))
    body = (f'<main class="main"><h1>Cost &amp; Token Burn</h1>'
            f'<p class="sub">Real token usage parsed from Claude Code session logs — tokens are exact; '
            f'$ uses the Opus rate table (in ${R["in"]:g} / out ${R["out"]:g} / cache-read ${R["cr"]:g} / '
            f'cache-write ${R["cw5"]:g}–${R["cw1"]:g} per Mtok), adjust if 4.8 pricing differs. Data through {data_through}.</p>'
            f'<div class="cards">'
            f'<div class="card"><div class="big">${tot["cost"]:.2f}</div><div class="lbl">total est. cost</div></div>'
            f'<div class="card"><div class="big">{k(tot["out"])}</div><div class="lbl">output tokens</div></div>'
            f'<div class="card"><div class="big">{nsteps}</div><div class="lbl">steps</div></div>'
            f'<div class="card"><div class="big">{len(files)}</div><div class="lbl">sessions</div></div></div>'
            f'<h2>Per step<span class="tag">each user prompt</span></h2>'
            f'<table class="t"><thead><tr><th>#</th><th>when</th><th>prompt</th><th class="r">in</th><th class="r">out</th>'
            f'<th class="r">cache-rd</th><th class="r">cache-wr</th><th class="r">$</th></tr></thead><tbody>{step_rows}'
            f'<tr class="total"><td colspan="3">whole project</td><td class="r">{k(tot["in"])}</td><td class="r">{k(tot["out"])}</td>'
            f'<td class="r">{k(tot["cr"])}</td><td class="r">{k(tcw)}</td><td class="r cost">${tot["cost"]:.2f}</td></tr></tbody></table>'
            f'<h2>Per session</h2><table class="t"><thead><tr><th>session</th><th class="r">turns</th><th class="r">in</th>'
            f'<th class="r">out</th><th class="r">cache-rd</th><th class="r">cache-wr</th><th class="r">$</th></tr></thead><tbody>{sess_rows}</tbody></table>'
            f'{forge_html}'
            f'<p class="foot">Generated by <code>tools/cost-summary.sh --html</code> — regenerate to refresh.</p></main></body></html>')
    op = HTML_OUT if os.path.isabs(HTML_OUT) else os.path.join(PROJECT, HTML_OUT)
    try:
        os.makedirs(os.path.dirname(op), exist_ok=True)
        with open(op, "w") as f: f.write(HEAD + nav + body)
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

if forge["available"]:
    print("\nFORGE PHASE ESTIMATE — ctx_est from .forge/observe (approximate, context-size not billed tokens)")
    for ph in sorted(forge["by_phase"]):
        print(f"  {ph:<5} ctx_est {k(forge['by_phase'][ph])}")
    print(f"  agents: " + "  ".join(f"{a}={k(v)}" for a, v in sorted(forge["by_agent"].items())))
    print(f"  total ctx_est {k(forge['total_ctx_est'])}  (estimate only)")
else:
    print("\nFORGE PHASE ESTIMATE — no ctx_est observe data found (.forge/observe/*.jsonl)")

if wrote: print(f"\nwrote {wrote}")
if html_path: print(f"wrote {html_path}")
PY
