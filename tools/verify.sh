#!/usr/bin/env bash
# verify.sh — real, non-negotiable verification.  "It compiles" / "it builds"
# is NOT "it works."  Runs the actual gates with GENUINE exit codes (no pipe or
# wrapper masking), writes a per-layer report to .forge/VERIFY.json, and exits
# nonzero if any REQUIRED layer failed or could not be run.  e2e is required to
# ship (it catches what every other layer misses) — waive it only explicitly.
#
# Gate commands come from .forge/verify.cmds.json:
#   { "build": "...", "lint": "...", "unit": "...", "e2e": "...",
#     "waive": ["e2e"] }            # waive = not required (reported, non-blocking)
# A layer with no command is "unrun" → blocks unless waived. On first run with no
# config, a stub is written and every layer reports "unrun" (honestly red).
#
# Genuine exit codes: each command is run with output redirected to a log file
# (NOT piped), so $? is the command's real status — a `cmd | tee` cannot mask a
# failure as success here.
set -uo pipefail

[ -f ".forge/STATE.json" ] || { echo "verify: not a FORGE build (no .forge/STATE.json)" >&2; exit 2; }
mkdir -p .forge
CFG=".forge/verify.cmds.json"
LAYERS="build lint unit e2e"

if [ ! -f "$CFG" ]; then
  cat > "$CFG" <<'JSON'
{
  "_note": "Declare the REAL gate command per layer for this project (run from project root). Empty = unrun (blocks). Add a layer to \"waive\" to make it non-required.",
  "build": "",
  "lint": "",
  "unit": "",
  "e2e": "",
  "waive": []
}
JSON
  echo "verify: wrote stub $CFG — fill in the real gate commands." >&2
fi

CFG="$CFG" LAYERS="$LAYERS" python3 <<'PY'
import json, os, subprocess, datetime

cfg = json.load(open(os.environ["CFG"]))
waive = set(cfg.get("waive", []) or [])
layers = os.environ["LAYERS"].split()
results, blocking_fail = [], False

for name in layers:
    cmd = (cfg.get(name) or "").strip()
    required = name not in waive
    log = f".forge/verify-{name}.log"
    if not cmd:
        status = "waived" if not required else "unrun"
        if required:
            blocking_fail = True
        results.append({"name": name, "status": status, "exit": None, "required": required, "cmd": "", "log": ""})
        continue
    # Run the REAL command with pipefail so an internal pipe (cmd | tee) cannot
    # mask a failure as success, and redirect (not pipe) so $? is genuine.
    with open(log, "wb") as fh:
        code = subprocess.call(["bash", "-c", "set -o pipefail\n" + cmd], stdout=fh, stderr=subprocess.STDOUT)
    status = "pass" if code == 0 else "fail"
    if status == "fail" and required:
        blocking_fail = True
    results.append({"name": name, "status": status, "exit": code, "required": required, "cmd": cmd, "log": log})

report = {
    "generated": datetime.datetime.now(datetime.timezone.utc).isoformat().replace("+00:00", "Z"),
    "ok": not blocking_fail,
    "layers": results,
}
json.dump(report, open(".forge/VERIFY.json", "w"), indent=2)

# per-layer report — what actually RAN vs only inspected, and what couldn't be verified
mark = {"pass": "PASS", "fail": "FAIL", "unrun": "UNRUN", "waived": "waived"}
for r in results:
    req = "" if r["required"] else " (waived)"
    ec = "" if r["exit"] is None else f" exit={r['exit']}"
    print(f"  [{mark.get(r['status'], r['status'])}] {r['name']}{req}{ec}"
          + (f"  → {r['log']}" if r["log"] else "  (no command set)"))
if blocking_fail:
    failed = [r["name"] for r in results if r["required"] and r["status"] in ("fail", "unrun")]
    print(f"\nVERIFY FAILED: required layer(s) not green: {', '.join(failed)}. "
          f"This is NOT shippable — fix or set a real command (e2e is the point of the loop).")
    raise SystemExit(3)
print("\nVERIFY OK: all required layers ran green (genuine exit codes).")
PY
