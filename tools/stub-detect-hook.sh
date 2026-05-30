#!/usr/bin/env bash
# stub-detect-hook.sh — write-time stub detector (R9), PostToolUse on Write|Edit.
#
# Non-blocking by design: a written source file is scanned; new stubs are
# logged to .forge/STUBS.md and filed to .forge/GAPS.json (type:"stub") so they
# flow into the P8 gap loop / GitHub ticketing. The SHIP GATE (not this hook)
# is what blocks release on open stub gaps in MUST modules.
#
# Defensive: fails safe (no-op) if it can't read input; never blocks.
set -uo pipefail

INPUT=$(cat 2>/dev/null || true)
FILE_PATH=$(printf '%s' "$INPUT" | python3 -c "import sys,json
try: d=json.load(sys.stdin)
except Exception: d={}
print((d.get('tool_input') or {}).get('file_path','') or '')" 2>/dev/null || true)

[ -z "$FILE_PATH" ] && exit 0
[ -f ".forge/STATE.json" ] || exit 0          # only inside an active build
[ -f "$FILE_PATH" ] || exit 0

TOOLS_DIR="$(cd "$(dirname "$0")" && pwd)"
FINDINGS=$(bash "$TOOLS_DIR/stub-scan.sh" "$FILE_PATH" 2>/dev/null || true)
[ -z "$FINDINGS" ] && exit 0

FINDINGS_JSON="$FINDINGS" PROJECT_ROOT="$PWD" python3 <<'PY' 2>/dev/null || exit 0
import json, os, sys

project = os.environ.get("PROJECT_ROOT", ".")
findings = []
for line in os.environ.get("FINDINGS_JSON", "").splitlines():
    line = line.strip()
    if not line: continue
    try: findings.append(json.loads(line))
    except Exception: pass
if not findings: sys.exit(0)

def relpath(p):
    # Resolve symlinks on both sides first (e.g. /tmp -> /private/tmp on macOS)
    # so the gap id is a stable repo-relative path, not "../../private/tmp/...".
    try: return os.path.relpath(os.path.realpath(p), os.path.realpath(project))
    except Exception: return p

# phase + spec_ref-from-task (best effort: map file to a task by name match)
phase = "P?"
try:
    phase = "P" + str(json.load(open(".forge/STATE.json")).get("phase", "?"))
except Exception:
    pass

def load(p, default):
    try: return json.load(open(p))
    except Exception: return default

# --- GAPS.json (preserve list or {gaps:[]} shape), dedup by id ---
gaps_obj = load(".forge/GAPS.json", [])
arr = gaps_obj["gaps"] if isinstance(gaps_obj, dict) else (gaps_obj if isinstance(gaps_obj, list) else [])
existing = {g.get("id") for g in arr if isinstance(g, dict)}

new_rows, added = [], 0
for f in findings:
    rp = relpath(f["file"])
    gid = f"GAP-STUB-{rp}-L{f['line']}"
    if gid in existing:
        continue
    existing.add(gid); added += 1
    arr.append({
        "id": gid, "type": "stub", "severity": "MAJOR",
        "pillar": "Build Quality", "spec_ref": None,
        "file": rp, "line": f["line"], "marker": f["marker"],
        "description": f"Stub at {rp}:{f['line']} ({f['marker']}): {f['text']}",
        "source": "stub-detect-hook (R9)", "status": "open",
    })
    new_rows.append(f"| {rp}:{f['line']} | {f['marker']} | {f['text']} | open |")

if not added:
    sys.exit(0)

out = gaps_obj if isinstance(gaps_obj, dict) else arr
json.dump(out, open(".forge/GAPS.json", "w"), indent=2)

# --- STUBS.md ledger ---
ledger = ".forge/STUBS.md"
if not os.path.exists(ledger):
    open(ledger, "w").write("# Stub Ledger (R9)\n\n"
        "Detected placeholder/incomplete code. Resolved by the gap loop; the "
        "ship gate blocks on open stubs in MUST modules.\n\n"
        "| Location | Marker | Text | Status |\n|------|------|------|------|\n")
with open(ledger, "a") as fh:
    for r in new_rows: fh.write(r + "\n")

# --- observe event ---
try:
    os.makedirs(".forge/observe", exist_ok=True)
    seq = sum(sum(1 for _ in open(os.path.join(".forge/observe", fn)))
              for fn in os.listdir(".forge/observe") if fn.endswith(".jsonl"))
    open(".forge/observe/stub.jsonl", "a").write(json.dumps({
        "t": "", "seq": seq + 1, "agent": "stub-detect", "role": "stub-detect",
        "event": "STUB", "detail": f"{added} new stub(s) in {relpath(findings[0]['file'])}",
        "phase": phase.lstrip("P"),
    }) + "\n")
except Exception:
    pass

print(f"[R9 stub-detect] {added} new stub(s) filed to GAPS.json — see .forge/STUBS.md")
PY
exit 0
