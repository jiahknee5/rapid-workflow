#!/usr/bin/env bash
# inputs-check.sh — fail-closed gate on the human-input ledger (.rapid/INPUTS.json).
#
# The build promise is "gather everything from the human up front, then run to
# completion." This is the check that makes that real: before the build may enter
# P6, EVERY required input — credentials, deploy target, spend ceiling, resolved
# undecidable decisions — must be resolved (or explicitly waived). Run it at GATE 2,
# and the phase-gate hook runs the same check when STATE.json advances to phase 6.
#
# "Resolved" is verified, not just asserted: a required env/secret/credential whose
# value_ref points at `.env:NAME` is only counted resolved if `.env` actually
# contains NAME=. Marking a row resolved without backing it fails the gate.
#
#   inputs-check.sh            check ./.rapid/INPUTS.json (cwd is the build root)
#   inputs-check.sh --quiet    print nothing on success (for hooks)
# Exit 0 = every required input resolved/waived; exit 3 = one or more unresolved;
# exit 2 = ledger missing (also a block — inputs were never gathered).
set -uo pipefail

QUIET=0
[ "${1:-}" = "--quiet" ] && QUIET=1

LEDGER=".rapid/INPUTS.json"
if [ ! -f "$LEDGER" ]; then
  echo "INPUTS GATE BLOCKED: $LEDGER does not exist — the human-input ledger was never" >&2
  echo "  created/populated. Seed it from templates/INPUTS.json at P1 and fill it at" >&2
  echo "  GATE 1 / GATE 2 before the build can enter P6." >&2
  exit 2
fi

QUIET="$QUIET" python3 <<'PY'
import json, os, sys, re

quiet = os.environ.get("QUIET") == "1"
try:
    doc = json.load(open(".rapid/INPUTS.json"))
except Exception as e:
    print(f"INPUTS GATE BLOCKED: cannot parse .rapid/INPUTS.json ({e})", file=sys.stderr); sys.exit(2)

inputs = doc.get("inputs", []) if isinstance(doc, dict) else (doc if isinstance(doc, list) else [])

# Parse .env once so a "resolved" credential claim can be verified against reality.
env_keys = set()
if os.path.isfile(".env"):
    for line in open(".env"):
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line: continue
        env_keys.add(line.split("=", 1)[0].strip())

RESOLVED_OK = {"resolved", "waived", "n/a"}
BACKED_KINDS = {"env", "secret", "credential"}

unresolved, unbacked, waived = [], [], []
for i in inputs:
    if not isinstance(i, dict): continue
    if not i.get("required", False): continue
    status = str(i.get("status", "unresolved")).lower()
    iid = i.get("id", "?")
    if status not in RESOLVED_OK:
        unresolved.append(i); continue
    if status == "waived":
        waived.append(i)
    # Verify env/secret/credential resolutions are actually backed by .env.
    if status == "resolved" and str(i.get("kind","")).lower() in BACKED_KINDS:
        ref = str(i.get("value_ref", ""))
        m = re.match(r"\.env:(\w+)", ref)
        if m and m.group(1) not in env_keys:
            unbacked.append((iid, m.group(1)))

blocked = unresolved or unbacked
req = [i for i in inputs if isinstance(i, dict) and i.get("required")]
if not quiet or blocked:
    print(f"INPUTS LEDGER: {len(req)} required, "
          f"{len(req)-len(unresolved)-len(unbacked)} resolved, "
          f"{len(unresolved)} unresolved, {len(unbacked)} unbacked, {len(waived)} waived")
    for i in unresolved:
        print(f"  [UNRESOLVED] {i.get('id','?')} ({i.get('kind','?')}) — {i.get('label','')}  [gate {i.get('gate','?')}]")
    for iid, key in unbacked:
        print(f"  [UNBACKED]   {iid} — marked resolved but .env has no {key}=")

if blocked:
    print(f"\nINPUTS GATE BLOCKED: {len(unresolved)+len(unbacked)} required input(s) not satisfied. "
          "The build cannot enter P6 until each is resolved in .rapid/INPUTS.json "
          "(or marked waived with a reason). This is the front-loaded-human-input "
          "guarantee — resolve them now so the build runs to completion without stopping.", file=sys.stderr)
    sys.exit(3)
if not quiet:
    print("\nINPUTS GATE OPEN: every required human input is resolved — the build can run to completion.")
PY
