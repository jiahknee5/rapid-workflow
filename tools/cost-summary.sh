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
# Rate overrides (USD per 1M tokens), defaults = standard Opus schedule:
#   OPUS_IN=15  OPUS_OUT=75  OPUS_CACHE_READ=1.50  OPUS_CW5=18.75  OPUS_CW1=30
set -uo pipefail

JSON_ONLY=0
PROJECT="$PWD"
for a in "$@"; do
  case "$a" in
    --json) JSON_ONLY=1 ;;
    -*) echo "cost-summary: unknown flag $a" >&2; exit 2 ;;
    *) PROJECT="$a" ;;
  esac
done
PROJECT="$(cd "$PROJECT" 2>/dev/null && pwd || echo "$PROJECT")"

# Claude Code encodes the cwd into the session dir name by replacing / with -.
ENCODED=$(printf '%s' "$PROJECT" | sed 's#/#-#g')
SDIR="$HOME/.claude/projects/$ENCODED"

JSON_ONLY="$JSON_ONLY" PROJECT="$PROJECT" SDIR="$SDIR" python3 <<'PY'
import os, sys, json, glob

PROJECT = os.environ["PROJECT"]
SDIR    = os.environ["SDIR"]
JSON_ONLY = os.environ.get("JSON_ONLY") == "1"

def rate(name, default):
    try: return float(os.environ.get(name, default))
    except Exception: return default

# USD per 1M tokens. Token counts below are exact; these rates drive the $ only.
R = {
    "in":   rate("OPUS_IN", 15.0),
    "out":  rate("OPUS_OUT", 75.0),
    "cr":   rate("OPUS_CACHE_READ", 1.50),
    "cw5":  rate("OPUS_CW5", 18.75),
    "cw1":  rate("OPUS_CW1", 30.0),
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
PY
