#!/usr/bin/env bash
# trace-check.sh — the G2 planning-alignment gate. Verifies the planning chain is
# coherent and complete BEFORE the build locks: every enhanced-PRD requirement maps to
# a spec section (or is explicitly OUT OF SCOPE), and every spec section traces back to
# a requirement. Reports orphans both ways and writes a `planning_aligned` assertion to
# .rapid/TRACE.json so the gate can fail closed. This is the planning-time twin of the
# R8 conformance hook (which does the same trace at build time, per module).
#
# Exit 0 = aligned (or nothing to check yet); exit 3 = orphans found (block G2).
set -uo pipefail

[ -f ".rapid/STATE.json" ] || { echo "trace-check: not a Rapid build (no .rapid/STATE.json)" >&2; exit 2; }

PRD="01-intake/PRD-ENHANCED.md"
SPEC="04-spec/spec.md"
[ -f "$PRD" ]  || { echo "trace-check: no $PRD yet — nothing to align"; exit 0; }
[ -f "$SPEC" ] || { echo "trace-check: no $SPEC yet — nothing to align"; exit 0; }

python3 - "$PRD" "$SPEC" <<'PY'
import re, sys, json, os
prd_path, spec_path = sys.argv[1], sys.argv[2]
prd  = open(prd_path).read()
spec = open(spec_path).read()

# Requirement IDs declared in the enhanced PRD (BR/FR/TR/NFR-N).
reqs = sorted(set(re.findall(r'\b((?:BR|FR|TR|NFR)-\d+)\b', prd)))
# Spec section IDs (S-NN) and the requirement IDs the spec references.
spec_sections = sorted(set(re.findall(r'\b(S-\d+)\b', spec)))
spec_refs     = set(re.findall(r'\b((?:BR|FR|TR|NFR)-\d+)\b', spec))
# Requirements explicitly parked out of scope (a line tagging the id [OUT OF SCOPE]).
out_of_scope  = set(m for m in reqs
                    if re.search(re.escape(m) + r'.{0,80}\[OUT OF SCOPE\]', prd, re.I)
                    or re.search(r'\[OUT OF SCOPE\].{0,80}' + re.escape(m), prd, re.I))

# Orphan requirement = declared, not referenced by the spec, not parked out of scope.
orphan_reqs = [r for r in reqs if r not in spec_refs and r not in out_of_scope]
# Orphan spec section = an S-NN whose surrounding block carries no [FROM PRD]/[DERIVED] tag
# and references no requirement id (best-effort: scan the section's own line + a window).
orphan_secs = []
for sid in spec_sections:
    # the line(s) introducing this section
    m = re.search(r'^.*\b' + re.escape(sid) + r'\b.*$', spec, re.M)
    blk = spec[m.start(): m.start()+400] if m else ""
    tagged = ('[FROM PRD' in blk) or ('[DERIVED]' in blk) or re.search(r'\b(?:BR|FR|TR|NFR)-\d+\b', blk)
    if not tagged:
        orphan_secs.append(sid)

aligned = not orphan_reqs and not orphan_secs
result = {
    "requirements": len(reqs), "spec_sections": len(spec_sections),
    "out_of_scope": sorted(out_of_scope),
    "orphan_requirements": orphan_reqs,           # in PRD, not built/spec'd, not parked
    "orphan_spec_sections": orphan_secs,          # in spec, traces to no requirement
    "planning_aligned": aligned,
}
os.makedirs(".rapid", exist_ok=True)
json.dump(result, open(".rapid/TRACE.json", "w"), indent=2)

print(f"trace-check: {len(reqs)} requirements, {len(spec_sections)} spec sections")
if orphan_reqs:
    print("  ORPHAN REQUIREMENTS (declared, not in spec, not [OUT OF SCOPE]):")
    for r in orphan_reqs: print(f"    - {r}")
if orphan_secs:
    print("  ORPHAN SPEC SECTIONS (no requirement trace):")
    for s in orphan_secs: print(f"    - {s}")
if aligned:
    print("  planning_aligned: true — the chain is complete. G2 may lock.")
else:
    print("  planning_aligned: FALSE — resolve orphans (map, derive, or mark [OUT OF SCOPE]) before G2.")
sys.exit(0 if aligned else 3)
PY
