#!/usr/bin/env bash
# ship-gate.sh — turn R8 (conformance) + R9 (stub) findings into a BLOCKING
# gate. Run at P6 exit / G3 from the build root.
#
# It re-scans the tree for stubs and counts open MAJOR+ stub/conformance gaps,
# then merges the results as assertions into .forge/P6_EXIT.json. The existing
# phase-gate hook (R1) refuses to advance STATE.json to phase 7 while
# P6_EXIT.json contains any "pass": false — so a failed ship-gate mechanically
# blocks release through the gate you already have.
#
# Exit 0 = all gate assertions pass; exit 3 = at least one failed (CI-friendly).
set -uo pipefail

[ -f ".forge/STATE.json" ] || { echo "ship-gate: not a FORGE build (no .forge/STATE.json)" >&2; exit 2; }
TOOLS_DIR="$(cd "$(dirname "$0")" && pwd)"

# Live stub scan of the tree (source files only).
STUB_FINDINGS=$(bash "$TOOLS_DIR/stub-scan.sh" --tree . 2>/dev/null || true)

STUB_FINDINGS="$STUB_FINDINGS" python3 <<'PY'
import json, os, sys

def load(p, d):
    try: return json.load(open(p))
    except Exception: return d

gaps_obj = load(".forge/GAPS.json", [])
gaps = gaps_obj["gaps"] if isinstance(gaps_obj, dict) else (gaps_obj if isinstance(gaps_obj, list) else [])

BLOCKING = {"BLOCKER", "CRITICAL", "MAJOR"}
def is_open(g):  return str(g.get("status", "open")).lower() == "open"
def blocking(g): return str(g.get("severity", "MAJOR")).upper() in BLOCKING

open_stub = [g for g in gaps if g.get("type") == "stub" and is_open(g) and blocking(g)]
open_conf = [g for g in gaps if g.get("type") == "conformance" and is_open(g) and blocking(g)]

# live tree scan (independent of the gap ledger — catches stubs never hooked)
tree_stubs = [l for l in os.environ.get("STUB_FINDINGS", "").splitlines() if l.strip()]

assertions = [
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
exit_obj = load(".forge/P6_EXIT.json", [])
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
json.dump(out, open(".forge/P6_EXIT.json", "w"), indent=2)

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
