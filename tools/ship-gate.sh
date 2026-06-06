#!/usr/bin/env bash
# ship-gate.sh — turn R8 (conformance) + R9 (stub) findings into a BLOCKING
# gate. Run at P6 exit / G3 from the build root.
#
# It re-scans the tree for stubs and counts open MAJOR+ stub/conformance gaps,
# then merges the results as assertions into .rapid/P6_EXIT.json. The existing
# phase-gate hook (R1) refuses to advance STATE.json to phase 7 while
# P6_EXIT.json contains any "pass": false — so a failed ship-gate mechanically
# blocks release through the gate you already have.
#
# Exit 0 = all gate assertions pass; exit 3 = at least one failed (CI-friendly).
set -uo pipefail

[ -f ".rapid/STATE.json" ] || { echo "ship-gate: not a RAPID build (no .rapid/STATE.json)" >&2; exit 2; }
TOOLS_DIR="$(cd "$(dirname "$0")" && pwd)"

# Live stub scan of the tree (source files only).
STUB_FINDINGS=$(bash "$TOOLS_DIR/stub-scan.sh" --tree . 2>/dev/null || true)

STUB_FINDINGS="$STUB_FINDINGS" python3 <<'PY'
import json, os, sys, glob, subprocess, datetime

def load(p, d):
    try: return json.load(open(p))
    except Exception: return d

gaps_obj = load(".rapid/GAPS.json", [])
gaps = gaps_obj["gaps"] if isinstance(gaps_obj, dict) else (gaps_obj if isinstance(gaps_obj, list) else [])

BLOCKING = {"BLOCKER", "CRITICAL", "MAJOR"}
def is_open(g):  return str(g.get("status", "open")).lower() == "open"
def blocking(g): return str(g.get("severity", "MAJOR")).upper() in BLOCKING

open_stub = [g for g in gaps if g.get("type") == "stub" and is_open(g) and blocking(g)]
open_conf = [g for g in gaps if g.get("type") == "conformance" and is_open(g) and blocking(g)]

# live tree scan (independent of the gap ledger — catches stubs never hooked)
tree_stubs = [l for l in os.environ.get("STUB_FINDINGS", "").splitlines() if l.strip()]

# real verification (.rapid/VERIFY.json from tools/verify.sh): required layers must
# be green with genuine exit codes. Absent VERIFY.json = verification not run = block.
verify = load(".rapid/VERIFY.json", None)
if verify is None:
    verify_pass = False
    verify_detail = "no .rapid/VERIFY.json — run tools/verify.sh (build/lint/unit/e2e)"
else:
    bad = [l.get("name") for l in verify.get("layers", []) if l.get("required") and l.get("status") != "pass"]
    verify_pass = bool(verify.get("ok")) and not bad
    verify_detail = ("all required layers green with genuine exit codes"
                     if verify_pass else f"required layer(s) not green: {', '.join(bad) or 'unknown'}")

assertions = [
    {"name": "verification_real", "pass": verify_pass, "detail": verify_detail},
    {"name": "no_open_stub_gaps",
     "pass": len(open_stub) == 0,
     "detail": f"{len(open_stub)} open MAJOR+ stub gap(s)"
               + ("" if not open_stub else ": " + ", ".join(g.get("id","?") for g in open_stub[:8]))},
    {"name": "no_stubs_in_tree",
     "pass": len(tree_stubs) == 0,
     "detail": f"{len(tree_stubs)} stub marker(s) found in source tree"},
    {"name": "no_open_conformance_gaps",
     "pass": len(open_conf) == 0,
     "detail": f"{len(open_conf)} open MAJOR+ conformance gap(s)"
               + ("" if not open_conf else ": " + ", ".join(g.get("id","?") for g in open_conf[:8]))},
]

# Merge into P6_EXIT.json (list of assertions), replacing any same-named ones.
exit_obj = load(".rapid/P6_EXIT.json", [])
existing = exit_obj if isinstance(exit_obj, list) else exit_obj.get("assertions", [])
by_name = {a.get("name"): a for a in existing if isinstance(a, dict)}
for a in assertions:
    by_name[a["name"]] = a
merged = list(by_name.values())

if isinstance(exit_obj, dict):
    exit_obj["assertions"] = merged
    out = exit_obj
else:
    out = merged
json.dump(out, open(".rapid/P6_EXIT.json", "w"), indent=2)

# Run the eval harness (.rapid/EVAL/*.test.sh) for REAL and record its results,
# then publish docs/eval.json — the single data file the eval page renders from.
# It works both under observe-server (live view) and in a static /_atlas deploy,
# so the eval page reflects actual state instead of a remembered claim.
harness = []
for tf in sorted(glob.glob(".rapid/EVAL/*.test.sh")):
    try:
        r = subprocess.run(["bash", tf], capture_output=True, text=True, timeout=180)
        tail = [l for l in (r.stdout or "").splitlines() if l.strip()]
        err = [l for l in (r.stderr or "").splitlines() if l.strip()]
        harness.append({"name": os.path.basename(tf),
                        "pass": r.returncode == 0,
                        "output": (tail[-1] if tail else (err[-1] if err else f"exit {r.returncode}"))})
    except Exception as e:
        harness.append({"name": os.path.basename(tf), "pass": False, "output": f"error: {e}"})

summary = {"pass": sum(1 for a in merged if a.get("pass") is True),
           "fail": sum(1 for a in merged if a.get("pass") is False),
           "total": len(merged)}
eval_doc = {
    "generated": datetime.datetime.now().astimezone().strftime("%Y-%m-%d %H:%M %Z").strip(),
    "summary": summary,
    "assertions": merged,
    "harness": harness,
}
if os.path.isdir("docs"):
    json.dump(eval_doc, open("docs/eval.json", "w"), indent=2)
    print(f"  wrote docs/eval.json ({summary['pass']}/{summary['total']} assertions, "
          f"{sum(1 for h in harness if h['pass'])}/{len(harness)} harness test(s) passing)")

failed = [a for a in assertions if not a["pass"]]
for a in assertions:
    mark = "PASS" if a["pass"] else "FAIL"
    print(f"  [{mark}] {a['name']}: {a['detail']}")
if failed:
    print(f"\nSHIP GATE BLOCKED: {len(failed)} assertion(s) failed. "
          f"P6_EXIT.json now has pass:false — STATE.json cannot advance to phase 7 "
          f"until the underlying stub/conformance gaps are resolved.")
    sys.exit(3)
print("\nSHIP GATE OPEN: stub + conformance assertions pass.")
PY
