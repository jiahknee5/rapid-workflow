#!/usr/bin/env bash
# preflight.sh — probe the declared stack's runtimes EARLY and install the
# missing ones within the declared stack. Hard-fails if a REQUIRED tool is
# absent and can't be installed.  Build-run lesson #3: never write code that
# routes around a missing runtime — that produces code nobody can verify. So
# this gate runs in P1 and BLOCKS the build until the declared stack is green.
#
# It reads the declared stack from .forge/preflight.json:
#   { "tools": [
#       {"name":"node",   "check":"node --version", "install":"brew install node", "required":true},
#       {"name":"python3","check":"python3 -V",      "install":"",                  "required":true},
#       {"name":"pnpm",   "install":"npm i -g pnpm", "required":false}
#   ] }
#   - name      (required) the tool's command name; also the default check.
#   - check     (optional) command that exits 0 iff the tool is present.
#                          default: `command -v <name>`.
#   - install   (optional) command to install it within the declared stack.
#                          empty = no install path (missing => stays missing).
#   - required  (optional, default true) a missing required tool blocks the build.
# If preflight.json is absent, a stub is written and nothing is declared
# (reported, non-blocking) — declare the stack to make this gate meaningful.
#
# Genuine exit codes: every check/install/re-check is run with output REDIRECTED
# to a log file (not piped), so $? is the command's real status — a `cmd | tee`
# cannot launder a failure into success here. pipefail is set for the same reason.
#
# Per-tool report -> .forge/PREFLIGHT.json. Exits nonzero if any REQUIRED tool is
# still missing after install attempts.
set -uo pipefail

[ -f ".forge/STATE.json" ] || { echo "preflight: not a FORGE build (no .forge/STATE.json)" >&2; exit 2; }
mkdir -p .forge
CFG=".forge/preflight.json"

if [ ! -f "$CFG" ]; then
  cat > "$CFG" <<'JSON'
{
  "_note": "Declare EVERY runtime the chosen stack needs (run from project root). 'check' exits 0 iff present (default: command -v <name>); 'install' installs within the declared stack (empty = no install path); 'required' (default true) means a missing one blocks the build. This is probed in P1 BEFORE fan-out — a missing runtime must be installed or hard-fail, never coded around.",
  "tools": []
}
JSON
  echo "preflight: wrote stub $CFG — declare the stack's runtimes." >&2
fi

# All probing/installing/reporting happens in python for safe JSON handling, but
# every external command is executed via bash with redirected (not piped) output
# so exit codes stay genuine.
CFG="$CFG" python3 <<'PY'
import json, os, subprocess, datetime, shlex

def run(cmd, log):
    """Run cmd via bash with pipefail; redirect (not pipe) output to log so $? is genuine. Returns exit code."""
    with open(log, "wb") as fh:
        return subprocess.call(["bash", "-c", "set -o pipefail\n" + cmd],
                               stdout=fh, stderr=subprocess.STDOUT)

cfg_path = os.environ["CFG"]
try:
    cfg = json.load(open(cfg_path))
except (ValueError, OSError) as e:
    print(f"preflight: cannot read {cfg_path}: {e}", flush=True)
    raise SystemExit(2)

tools = cfg.get("tools") or []
if not isinstance(tools, list):
    print(f"preflight: '{cfg_path}' -> \"tools\" must be a list.", flush=True)
    raise SystemExit(2)

results, blocking_missing = [], False

if not tools:
    report = {
        "generated": datetime.datetime.now(datetime.timezone.utc).isoformat().replace("+00:00", "Z"),
        "ok": True, "nothing_declared": True, "tools": [],
    }
    json.dump(report, open(".forge/PREFLIGHT.json", "w"), indent=2)
    print("preflight: nothing declared — no runtimes in .forge/preflight.json. "
          "Declare the chosen stack so this gate can probe it (reported, non-blocking).")
    raise SystemExit(0)

for i, t in enumerate(tools):
    if not isinstance(t, dict) or not (t.get("name") or "").strip():
        print(f"preflight: tools[{i}] has no \"name\" — skipping malformed entry.", flush=True)
        results.append({"name": t.get("name") if isinstance(t, dict) else None,
                        "status": "malformed", "required": True, "installed": False,
                        "check": "", "install": "", "log": ""})
        blocking_missing = True
        continue

    name     = t["name"].strip()
    check    = (t.get("check") or f"command -v {shlex.quote(name)}").strip()
    install  = (t.get("install") or "").strip()
    required = t.get("required", True)
    if not isinstance(required, bool):
        required = str(required).strip().lower() in ("1", "true", "yes")

    safe = "".join(c if c.isalnum() or c in "-_" else "_" for c in name) or f"tool{i}"
    chk_log = f".forge/preflight-{safe}.check.log"
    ins_log = f".forge/preflight-{safe}.install.log"

    installed = False
    code = run(check, chk_log)               # genuine exit code
    if code == 0:
        status = "present"
    elif install:
        print(f"preflight: {name} missing — installing within declared stack: {install}", flush=True)
        icode = run(install, ins_log)        # genuine exit code
        rcode = run(check, chk_log) if icode == 0 else icode
        if icode == 0 and rcode == 0:
            status, installed = "installed", True
        else:
            status = "missing"               # install ran but tool still absent
    else:
        status = "missing"                   # no install path declared

    if status in ("missing", "malformed") and required:
        blocking_missing = True

    results.append({
        "name": name, "status": status, "required": required, "installed": installed,
        "check": check, "install": install, "check_exit": code,
        "log": ins_log if installed or status == "missing" and install else chk_log,
    })

report = {
    "generated": datetime.datetime.now(datetime.timezone.utc).isoformat().replace("+00:00", "Z"),
    "ok": not blocking_missing,
    "tools": results,
}
json.dump(report, open(".forge/PREFLIGHT.json", "w"), indent=2)

mark = {"present": "PRESENT", "installed": "INSTALLED", "missing": "MISSING", "malformed": "MALFORMED"}
print("preflight: declared-stack runtime probe")
for r in results:
    req = "" if r["required"] else " (optional)"
    print(f"  [{mark.get(r['status'], r['status'])}] {r['name']}{req}")

if blocking_missing:
    bad = [r["name"] for r in results
           if r["required"] and r["status"] in ("missing", "malformed")]
    print(f"\nPREFLIGHT FAILED: required runtime(s) absent and not installable: {', '.join(map(str, bad))}. "
          f"The build is BLOCKED. Install the runtime or fix its install command — "
          f"do NOT route around a missing runtime (that yields unverifiable code).")
    raise SystemExit(3)
print("\nPREFLIGHT OK: every required runtime in the declared stack is present (genuine exit codes).")
PY
