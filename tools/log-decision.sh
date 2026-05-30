#!/usr/bin/env bash
# log-decision.sh — log a PRD-silent build decision instead of interrupting the
# build for it.  Under standing authorization (CONSTITUTION.md + locked PRD +
# BUILD-AUTONOMY.md), a FORGE build runs to completion without per-step
# check-ins; the only things that stop it are destructive/irreversible,
# outward-facing, spends-money, or genuinely-undecidable high-stakes blockers.
# Everything the PRD is silent about is RESOLVED IN-PLACE and recorded here so
# the choice is auditable after the fact — not surfaced as a mid-build prompt.
#
# Each entry is flagged by basis:
#   spec           — the decision is a direct fact of the locked PRD/spec.
#   interpretation — the PRD is silent; this is the builder's reasoned call.
# (Genuinely-undecidable high-stakes items are NOT logged here — they go to the
# human as a Gate-1 decision batch BEFORE the build starts.)
#
# Usage:  tools/log-decision.sh "<decision text>" spec|interpretation
# Appends {id, ts, phase, decision, basis, by} to .forge/DECISIONS.json (a JSON
# list, created if absent), prints the logged id, and emits the structured
# {file, wrote, summary} result.  Runs only inside a FORGE build.
set -uo pipefail

err() { echo "log-decision: $*" >&2; }

# --- must be inside a FORGE build -------------------------------------------
if [ ! -f ".forge/STATE.json" ]; then
  err "not a FORGE build (no .forge/STATE.json in $(pwd)) — run from the build root"
  exit 2
fi

# --- args --------------------------------------------------------------------
DECISION="${1:-}"
BASIS="${2:-}"

if [ -z "$DECISION" ]; then
  err 'missing decision text'
  err 'usage: tools/log-decision.sh "<decision text>" spec|interpretation'
  exit 2
fi
if [ "$BASIS" != "spec" ] && [ "$BASIS" != "interpretation" ]; then
  err "basis must be 'spec' (PRD-fact) or 'interpretation' (PRD-silent call), got: '${BASIS:-<empty>}'"
  err 'usage: tools/log-decision.sh "<decision text>" spec|interpretation'
  exit 2
fi

command -v python3 >/dev/null 2>&1 || { err "python3 not found on PATH"; exit 2; }

mkdir -p .forge

# --- append (python3 owns the JSON: parse, validate shape, next id, write) ---
DECISION="$DECISION" BASIS="$BASIS" BY="${FORGE_ROLE:-build}" python3 <<'PY'
import json, os, sys, datetime

PATH = ".forge/DECISIONS.json"
STATE = ".forge/STATE.json"

def fail(msg, code=1):
    sys.stderr.write("log-decision: %s\n" % msg)
    sys.exit(code)

# phase from STATE.json (best-effort; "unknown" if unreadable/missing)
phase = "unknown"
try:
    with open(STATE) as f:
        st = json.load(f)
    if isinstance(st, dict) and st.get("phase") is not None:
        phase = st["phase"]
except Exception:
    pass

# load existing ledger; tolerate absent/empty, refuse corrupt-non-list
decisions = []
if os.path.exists(PATH) and os.path.getsize(PATH) > 0:
    try:
        with open(PATH) as f:
            loaded = json.load(f)
    except Exception as e:
        fail("%s is not valid JSON (%s); refusing to overwrite — fix or remove it" % (PATH, e), 2)
    if not isinstance(loaded, list):
        fail("%s must be a JSON list, found %s; refusing to overwrite" % (PATH, type(loaded).__name__), 2)
    decisions = loaded

# next id: D<max existing numeric suffix + 1>, robust to gaps/garbage ids
maxn = 0
for d in decisions:
    if isinstance(d, dict):
        i = str(d.get("id", ""))
        if i.startswith("D") and i[1:].isdigit():
            maxn = max(maxn, int(i[1:]))
new_id = "D%d" % (maxn + 1)

entry = {
    "id": new_id,
    "ts": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "phase": phase,
    "decision": os.environ["DECISION"],
    "basis": os.environ["BASIS"],
    "by": os.environ.get("BY") or "build",
}
decisions.append(entry)

# atomic write: tmp then replace, so a crash can't truncate the ledger
tmp = PATH + ".tmp"
with open(tmp, "w") as f:
    json.dump(decisions, f, indent=2)
    f.write("\n")
os.replace(tmp, PATH)

print(new_id)
sys.stderr.write("log-decision: logged %s (basis=%s, phase=%s, by=%s)\n"
                 % (new_id, entry["basis"], entry["phase"], entry["by"]))
PY
rc=$?
[ "$rc" -eq 0 ] || exit "$rc"
