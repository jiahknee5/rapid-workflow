#!/usr/bin/env bash
# worktree-check.sh — verify that parallel build writers actually ran in isolated
# git worktrees, rather than trusting the skill instruction that says they should.
# Run at P6 exit (alongside ship-gate.sh) from the build root.
#
# The skill spawns coding subagents with `isolation:"worktree"` and binds coder
# terminals to `.rapid/worktrees/coder-N`. This check reads what the build ACTUALLY
# did from the observe log: every build-writer SPAWN event must declare a non-empty
# `worktree`, and two distinct concurrent writers must not share one. It merges a
# `build_writers_isolated` assertion into .rapid/P6_EXIT.json so the existing R1
# phase-gate hook refuses to advance to phase 7 when isolation was skipped.
#
# A "build writer" = a SPAWN event whose role is "implementor" OR whose agent name
# looks like a parallel coder (impl-1, impl_2, coder-3, ...). Leads that only fan
# out (the single `coder`/`planner`/`tester` terminals) are not required to hold a
# worktree themselves — only the parallel writers they dispatch are.
#
# Exit 0 = isolation verified (or no parallel writers ran); exit 3 = a violation.
set -uo pipefail

[ -f ".rapid/STATE.json" ] || { echo "worktree-check: not a RAPID build (no .rapid/STATE.json)" >&2; exit 2; }

# Live git-worktree inventory (best-effort) — lets us confirm declared paths were
# real worktrees while they still exist (isolation:"worktree" auto-removes unchanged
# ones, so absence is not itself a failure).
GIT_WORKTREES="$(git worktree list --porcelain 2>/dev/null | awk '/^worktree /{print $2}' || true)"

GIT_WORKTREES="$GIT_WORKTREES" python3 <<'PY'
import json, os, re, sys, glob

def load(p, d):
    try: return json.load(open(p))
    except Exception: return d

WRITER_NAME = re.compile(r'^(impl|coder|builder|worker)[-_]?\d+$', re.I)
def is_build_writer(ev):
    if str(ev.get("event") or "").upper() != "SPAWN":
        return False
    role  = str(ev.get("role") or "").lower()
    agent = str(ev.get("agent") or "")
    return role == "implementor" or bool(WRITER_NAME.match(agent))

# Load every observe event.
events = []
for fp in sorted(glob.glob(".rapid/observe/*.jsonl")):
    try:
        for line in open(fp):
            line = line.strip()
            if not line: continue
            try: d = json.loads(line)
            except Exception: continue
            if isinstance(d, dict): events.append(d)
    except Exception:
        continue

spawns = [e for e in events if is_build_writer(e)]

live_worktrees = {os.path.realpath(p) for p in os.environ.get("GIT_WORKTREES", "").split() if p.strip()}
proj_root = os.path.realpath(".")

def wt_of(ev):
    # accept either a top-level "worktree" field or detail like "worktree=.rapid/worktrees/impl-1"
    wt = ev.get("worktree")
    if not wt:
        m = re.search(r'worktree[=:]\s*(\S+)', str(ev.get("detail") or ""))
        wt = m.group(1) if m else ""
    return str(wt or "").strip().rstrip(",;")

missing, by_path, writers = [], {}, []
for e in spawns:
    agent = e.get("agent", "?")
    wt = wt_of(e)
    rp = os.path.realpath(wt) if wt else ""
    isolated = bool(wt) and wt not in (".", "./") and rp != proj_root
    rec = {"agent": agent, "task": e.get("task"), "branch": e.get("branch"),
           "worktree": wt, "isolated": isolated,
           "exists_now": rp in live_worktrees if rp else False}
    writers.append(rec)
    if not isolated:
        missing.append(rec)
    elif rp:
        by_path.setdefault(rp, set()).add(agent)

# A collision = one worktree path claimed by two DIFFERENT writer agents.
collisions = [{"worktree": p, "agents": sorted(a)} for p, a in by_path.items() if len(a) > 1]

n = len(spawns)
ok = (len(missing) == 0 and len(collisions) == 0)
if n == 0:
    detail = "no parallel build-writer SPAWNs in observe log — nothing to isolate (single-agent or tiny-change build)"
elif ok:
    detail = f"{n} build-writer spawn(s), all in distinct isolated worktrees"
else:
    bits = []
    if missing:    bits.append(f"{len(missing)} writer(s) with no worktree: " + ", ".join(m["agent"] for m in missing[:8]))
    if collisions: bits.append(f"{len(collisions)} shared-worktree collision(s): "
                               + "; ".join(f'{c["worktree"]} <- {"+".join(c["agents"])}' for c in collisions[:5]))
    detail = " | ".join(bits)

result = {"ok": ok, "build_writers": n, "writers": writers,
          "missing_worktree": missing, "collisions": collisions, "detail": detail}
json.dump(result, open(".rapid/WORKTREE_CHECK.json", "w"), indent=2)

# Merge a single assertion into P6_EXIT.json (same convention as ship-gate.sh).
assertion = {"name": "build_writers_isolated", "pass": ok, "detail": detail}
exit_obj = load(".rapid/P6_EXIT.json", [])
existing = exit_obj if isinstance(exit_obj, list) else exit_obj.get("assertions", [])
by_name = {a.get("name"): a for a in existing if isinstance(a, dict)}
by_name[assertion["name"]] = assertion
merged = list(by_name.values())
if isinstance(exit_obj, dict):
    exit_obj["assertions"] = merged; out = exit_obj
else:
    out = merged
json.dump(out, open(".rapid/P6_EXIT.json", "w"), indent=2)

mark = "PASS" if ok else "FAIL"
print(f"  [{mark}] build_writers_isolated: {detail}")
for w in writers:
    flag = "ok " if w["isolated"] else "!! "
    print(f"    {flag}{w['agent']:<14} worktree={w['worktree'] or '(none)'}"
          + (f"  branch={w['branch']}" if w.get('branch') else ""))
if not ok:
    print("\nWORKTREE CHECK BLOCKED: a parallel build writer did not run in an isolated "
          "git worktree. P6_EXIT.json now has pass:false — STATE.json cannot advance to "
          "phase 7. Re-dispatch the writer(s) with isolation:\"worktree\" (or bind the "
          "coder terminal to .rapid/worktrees/coder-N) so concurrent writes can't collide.")
    sys.exit(3)
print("\nWORKTREE CHECK OK: every parallel build writer ran in its own git worktree.")
PY
