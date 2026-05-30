#!/usr/bin/env bash
# FORGE Module-Completion Conformance hook (R8).
#
# PostToolUse hook (registered async on Write|Edit globally). When a task in
# .forge/TASKS.json transitions to a done state, it verifies the module traces
# back to the spec, PRD, and (optionally) architecture: each of the task's
# spec_ref / prd_ref / arch_ref must resolve to a real anchor in the
# corresponding doc. Non-blocking by design (operator's choice): it records a
# row in .forge/CONFORMANCE.md and, on an orphan/dangling ref, files a
# .forge/GAPS.json entry so the gap loop / GitHub ticketing picks it up.
#
# Defensive: no `set -e`, every path exits 0, fails SAFE (no-op) if it can't
# read its input. Fires on every Write/Edit on this machine; guards hard on
# .forge/TASKS.json + an active build before doing anything.

INPUT=$(cat 2>/dev/null || true)

# ---- Which file was written? (stdin JSON, current Claude Code contract) ---
FILE_PATH=$(printf '%s' "$INPUT" | python3 -c "import sys,json
try: d=json.load(sys.stdin)
except Exception: d={}
ti=d.get('tool_input') or {}
print(ti.get('file_path','') or '')" 2>/dev/null || true)

# ---- Guards: only on TASKS.json writes inside an active build -------------
case "$FILE_PATH" in *".forge/TASKS.json") : ;; *) exit 0 ;; esac
[ -f ".forge/STATE.json" ] || exit 0
[ -f ".forge/TASKS.json" ] || exit 0

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "")
PHASE=$(python3 -c "import json
try: print('P'+str(json.load(open('.forge/STATE.json')).get('phase','?')))
except Exception: print('P?')" 2>/dev/null || echo "P?")

# ---- All deterministic work happens in python (file resolution + ledgers) -
python3 - "$TS" "$PHASE" <<'PY' 2>/dev/null || exit 0
import json, os, sys, re

ts, phase = (sys.argv[1] if len(sys.argv) > 1 else ""), (sys.argv[2] if len(sys.argv) > 2 else "P?")
DONE = {"done", "complete", "completed", "passed", "merged"}

def load(p, default):
    try:
        with open(p) as f: return json.load(f)
    except Exception:
        return default

def tasks_list(obj):
    if isinstance(obj, list): return obj
    if isinstance(obj, dict): return obj.get("tasks", [])
    return []

tasks = tasks_list(load(".forge/TASKS.json", []))

# seen ledger so each task is conformance-checked exactly once
seen_path = ".forge/.conformance_seen"
seen = set()
if os.path.exists(seen_path):
    seen = set(l.strip() for l in open(seen_path) if l.strip())

def anchor_present(doc, ref):
    """A ref resolves if its token appears anywhere in the doc (heading id,
    section number like S3.1/§3.1, or requirement id like R-12)."""
    if not ref: return False
    if not os.path.exists(doc): return False
    try: text = open(doc, encoding="utf-8", errors="ignore").read()
    except Exception: return False
    norm = ref.replace("§", "").strip()
    return (ref in text) or (norm and norm in text)

SPEC = "04-spec/spec.md"
PRD  = "01-intake/PRD-ENHANCED.md"
ARCH = "04-spec/architecture.md"

new_rows, new_gaps = [], []
newly_seen = []

for t in tasks:
    tid = str(t.get("id", "")).strip()
    if not tid: continue
    status = str(t.get("status", "")).lower()
    if status not in DONE: continue
    if tid in seen: continue
    newly_seen.append(tid)

    spec_ref = str(t.get("spec_ref", "") or "")
    prd_ref  = str(t.get("prd_ref", "") or "")
    arch_ref = str(t.get("arch_ref", "") or "")  # optional

    problems = []
    # spec_ref "ALL" is the eval-harness root task — exempt from section anchoring
    if spec_ref.upper() != "ALL":
        if not spec_ref:
            problems.append("no spec_ref")
        elif not anchor_present(SPEC, spec_ref):
            problems.append(f"spec_ref {spec_ref} not found in {SPEC}")
        if not prd_ref:
            problems.append("no prd_ref")
        elif not anchor_present(PRD, prd_ref):
            problems.append(f"prd_ref {prd_ref} not found in {PRD}")
        if arch_ref and not anchor_present(ARCH, arch_ref):
            problems.append(f"arch_ref {arch_ref} not found in {ARCH}")

    status_word = "TRACEABLE" if not problems else "ORPHAN"
    note = "ok" if not problems else "; ".join(problems)
    new_rows.append(f"| {ts} | {phase} | {tid} | {spec_ref or '—'} | {prd_ref or '—'} | {arch_ref or '—'} | {status_word} | {note} |")

    if problems:
        new_gaps.append({
            "id": f"GAP-CONF-{tid}",
            "type": "conformance",
            "severity": "MAJOR",
            "pillar": "Spec Compliance",
            "spec_ref": spec_ref or None,
            "task": tid,
            "description": f"Module {tid} marked done but fails traceability: {note}",
            "source": "module-conformance-hook (R8)",
            "ts": ts,
            "status": "open",
        })

if not newly_seen:
    sys.exit(0)

# --- write CONFORMANCE.md ledger ---
conf = ".forge/CONFORMANCE.md"
if not os.path.exists(conf):
    with open(conf, "w") as f:
        f.write("# Module Conformance Ledger\n\n"
                "Each completed module traced back to spec / PRD / architecture (R8).\n\n"
                "| Time | Phase | Task | spec_ref | prd_ref | arch_ref | Status | Note |\n"
                "|------|-------|------|----------|---------|----------|--------|------|\n")
with open(conf, "a") as f:
    for r in new_rows: f.write(r + "\n")

# --- append GAPS.json entries (preserve existing shape: list or {gaps:[]}) ---
if new_gaps:
    gaps_obj = load(".forge/GAPS.json", [])
    if isinstance(gaps_obj, dict):
        arr = gaps_obj.setdefault("gaps", [])
        existing = {g.get("id") for g in arr if isinstance(g, dict)}
        arr.extend(g for g in new_gaps if g["id"] not in existing)
        out = gaps_obj
    else:
        arr = gaps_obj if isinstance(gaps_obj, list) else []
        existing = {g.get("id") for g in arr if isinstance(g, dict)}
        arr.extend(g for g in new_gaps if g["id"] not in existing)
        out = arr
    with open(".forge/GAPS.json", "w") as f:
        json.dump(out, f, indent=2)

# --- observe event ---
try:
    os.makedirs(".forge/observe", exist_ok=True)
    seq = 0
    for fn in os.listdir(".forge/observe"):
        if fn.endswith(".jsonl"):
            seq += sum(1 for _ in open(os.path.join(".forge/observe", fn)))
    orphans = len(new_gaps)
    with open(".forge/observe/conformance.jsonl", "a") as f:
        f.write(json.dumps({
            "t": ts, "seq": seq + 1, "agent": "conformance", "role": "conformance",
            "event": "CONFORMANCE",
            "detail": f"checked {len(newly_seen)} module(s); {orphans} orphan(s)",
            "phase": phase.lstrip("P"),
        }) + "\n")
except Exception:
    pass

# --- update seen ledger ---
with open(seen_path, "a") as f:
    for tid in newly_seen: f.write(tid + "\n")

# --- concise stdout summary (visible in transcript; non-blocking) ---
orphans = len(new_gaps)
if orphans:
    print(f"[R8 conformance] {len(newly_seen)} module(s) completed; {orphans} ORPHAN(s) filed to GAPS.json — see .forge/CONFORMANCE.md")
else:
    print(f"[R8 conformance] {len(newly_seen)} module(s) completed; all traceable to spec/PRD")
PY
exit 0
