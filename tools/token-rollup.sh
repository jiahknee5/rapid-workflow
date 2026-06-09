#!/usr/bin/env bash
# token-rollup.sh — total tokens used so far, PER PROJECT BUILD, across the fleet.
#
# Where cost-summary.sh drills into ONE project (per step / phase / session),
# this rolls UP: it walks every Claude Code transcript dir in
# ~/.claude/projects/<encoded-cwd>/*.jsonl, sums the exact billed tokens per
# project (keyed by the real `cwd` recorded in the transcript), and prints one
# line per project — total tokens, the in/out/cache breakdown, sessions, and $.
#
# Token counts are EXACT (parsed from each assistant turn's `usage`). Dollars are
# computed from a rate table (no cost field exists in transcripts); rates are
# Claude Opus 4.8 standard and overridable via env.
#
# Usage:
#   token-rollup.sh                 every project, most tokens first
#   token-rollup.sh --rapid         only RAPID builds (cwd has a .rapid/ dir)
#   token-rollup.sh --top 15        only the top N projects
#   token-rollup.sh --by cost       sort by $ instead of tokens
#   token-rollup.sh --since 2026-05-01   only count turns on/after a date
#   token-rollup.sh --json          machine JSON only (no table)
#
# Rate overrides (USD per 1M tokens), defaults = Claude Opus 4.8 standard:
#   OPUS_IN=5  OPUS_OUT=25  OPUS_CACHE_READ=0.50  OPUS_CW5=6.25  OPUS_CW1=10
set -uo pipefail

JSON_ONLY=0; ONLY_RAPID=0; TOPN=0; SORT_BY="tokens"; SINCE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --json) JSON_ONLY=1 ;;
    --rapid) ONLY_RAPID=1 ;;
    --top) shift; TOPN="${1:-0}" ;;
    --by) shift; SORT_BY="${1:-tokens}" ;;
    --since) shift; SINCE="${1:-}" ;;
    -h|--help) sed -n '2,28p' "$0"; exit 0 ;;
    *) echo "token-rollup: unknown flag $1" >&2; exit 2 ;;
  esac
  shift
done

PROJ_ROOT="$HOME/.claude/projects"
[ -d "$PROJ_ROOT" ] || { echo "token-rollup: no $PROJ_ROOT" >&2; exit 1; }

PROJ_ROOT="$PROJ_ROOT" JSON_ONLY="$JSON_ONLY" ONLY_RAPID="$ONLY_RAPID" \
TOPN="$TOPN" SORT_BY="$SORT_BY" SINCE="$SINCE" python3 <<'PY'
import os, json, glob, sys

root = os.environ["PROJ_ROOT"]
json_only = os.environ["JSON_ONLY"] == "1"
only_rapid = os.environ["ONLY_RAPID"] == "1"
topn = int(os.environ.get("TOPN") or 0)
sort_by = os.environ.get("SORT_BY", "tokens")
since = os.environ.get("SINCE", "").strip()

def rate(env, d):
    try: return float(os.environ[env])
    except (KeyError, ValueError): return d
R = {"in": rate("OPUS_IN",5.0), "out": rate("OPUS_OUT",25.0), "cr": rate("OPUS_CACHE_READ",0.50),
     "cw5": rate("OPUS_CW5",6.25), "cw1": rate("OPUS_CW1",10.0)}
def usd(t): return (t["in"]*R["in"] + t["out"]*R["out"] + t["cr"]*R["cr"] + t["cw5"]*R["cw5"] + t["cw1"]*R["cw1"]) / 1_000_000

def decode(name):  # fallback if no cwd in the transcript: best-effort un-encode
    return "/" + name.lstrip("-").replace("--", "/.").replace("-", "/")

# project key -> aggregate
projects = {}
for d in sorted(glob.glob(os.path.join(root, "*"))):
    if not os.path.isdir(d): continue
    files = sorted(glob.glob(os.path.join(d, "*.jsonl")))
    if not files: continue
    cwd = None
    agg = {"in":0,"out":0,"cr":0,"cw5":0,"cw1":0,"turns":0,"sessions":0,"first":None,"last":None}
    for f in files:
        had_turn = False
        for line in open(f, errors="ignore"):
            if '"usage"' not in line and '"cwd"' not in line: continue
            try: rec = json.loads(line)
            except Exception: continue
            if cwd is None and rec.get("cwd"): cwd = rec["cwd"]
            ts = rec.get("timestamp") or rec.get("t")
            if since and ts and ts[:len(since)] < since: continue
            msg = rec.get("message") or {}
            u = msg.get("usage") or rec.get("usage") or {}
            if not u: continue
            cc = u.get("cache_creation") or {}
            cw5 = cc.get("ephemeral_5m_input_tokens", 0) or 0
            cw1 = cc.get("ephemeral_1h_input_tokens", 0) or 0
            if not (cw5 or cw1):  # fall back to flat field, treat as 5m
                cw5 = u.get("cache_creation_input_tokens", 0) or 0
            agg["in"]  += u.get("input_tokens",0) or 0
            agg["out"] += u.get("output_tokens",0) or 0
            agg["cr"]  += u.get("cache_read_input_tokens",0) or 0
            agg["cw5"] += cw5; agg["cw1"] += cw1
            agg["turns"] += 1; had_turn = True
            if ts:
                if agg["first"] is None or ts < agg["first"]: agg["first"] = ts
                if agg["last"]  is None or ts > agg["last"]:  agg["last"]  = ts
        if had_turn: agg["sessions"] += 1
    if agg["turns"] == 0: continue
    key = cwd or decode(os.path.basename(d))
    agg["cwd"] = key
    agg["is_rapid"] = bool(cwd and os.path.isdir(os.path.join(cwd, ".rapid")))
    # merge if the same cwd appears under two encoded dirs
    if key in projects:
        p = projects[key]
        for k in ("in","out","cr","cw5","cw1","turns","sessions"): p[k] += agg[k]
        p["is_rapid"] = p["is_rapid"] or agg["is_rapid"]
        if agg["first"] and (not p["first"] or agg["first"] < p["first"]): p["first"] = agg["first"]
        if agg["last"]  and (not p["last"]  or agg["last"]  > p["last"]):  p["last"]  = agg["last"]
    else:
        projects[key] = agg

rows = list(projects.values())
if only_rapid: rows = [r for r in rows if r["is_rapid"]]
for r in rows:
    r["total"] = r["in"] + r["out"] + r["cr"] + r["cw5"] + r["cw1"]
    r["usd"] = usd(r)
rows.sort(key=lambda r: r["usd"] if sort_by == "cost" else r["total"], reverse=True)
shown = rows[:topn] if topn else rows

if json_only:
    out = {"rates": R, "projects": [
        {"project": r["cwd"], "rapid": r["is_rapid"], "total_tokens": r["total"],
         "input": r["in"], "output": r["out"], "cache_read": r["cr"], "cache_write": r["cw5"]+r["cw1"],
         "sessions": r["sessions"], "turns": r["turns"], "usd": round(r["usd"],2),
         "first": r["first"], "last": r["last"]} for r in shown],
        "grand_total_tokens": sum(r["total"] for r in rows),
        "grand_total_usd": round(sum(r["usd"] for r in rows), 2)}
    print(json.dumps(out, indent=2)); sys.exit(0)

def h(n):  # human tokens: 1.2M / 340K
    if n >= 1_000_000: return f"{n/1_000_000:.2f}M"
    if n >= 1_000: return f"{n/1_000:.0f}K"
    return str(n)
def short(p):
    p = p.replace(os.path.expanduser("~"), "~")
    return p if len(p) <= 40 else "…" + p[-39:]

print(f"\n  TOKENS PER PROJECT BUILD — {len(rows)} project(s){' · RAPID builds only' if only_rapid else ''}, exact billed tokens from ~/.claude/projects/\n")
print(f"  {'PROJECT':<42}{'SESS':>5}{'IN':>8}{'OUT':>8}{'CACHE':>9}{'TOTAL':>9}{'$':>9}  R")
print("  " + "─"*92)
for r in shown:
    cache = r["cr"] + r["cw5"] + r["cw1"]
    print(f"  {short(r['cwd']):<42}{r['sessions']:>5}{h(r['in']):>8}{h(r['out']):>8}{h(cache):>9}{h(r['total']):>9}{'$'+format(r['usd'],',.0f'):>9}  {'●' if r['is_rapid'] else ' '}")
print("  " + "─"*92)
gt = sum(r["total"] for r in rows); gusd = sum(r["usd"] for r in rows)
print(f"  {'GRAND TOTAL ('+str(len(rows))+' projects)':<42}{sum(r['sessions'] for r in rows):>5}{'':>8}{'':>8}{'':>9}{h(gt):>9}{'$'+format(gusd,',.0f'):>9}")
print(f"\n  ● = RAPID build (.rapid/ present) · tokens exact · $ at Opus 4.8 rates (override OPUS_IN/OUT/...)")
print(f"  per-build detail: tools/cost-summary.sh <project>   ·   --json for machine output\n")
PY
