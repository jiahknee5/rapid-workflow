#!/usr/bin/env bash
# gaps-to-issues.sh — externalize .forge/GAPS.json to GitHub issues and sync
# resolutions back. GAPS.json stays the in-build source of truth; GitHub is the
# externalization for gaps that outlive the inner loop.
#
#   gaps-to-issues.sh            DRY RUN — print intended actions, touch nothing
#   gaps-to-issues.sh --push     actually create/close issues via `gh`
#
# This is operator/`/loop`-triggered, NOT an automatic write-hook — externalizing
# every GAPS.json write would spam the tracker and fire network calls from any
# session. Idempotent: a gap with an "issue" number is never re-created; a gap
# flipped to resolved closes its issue once.
set -uo pipefail

PUSH=0; [ "${1:-}" = "--push" ] && PUSH=1
[ -f ".forge/GAPS.json" ] || { echo "gaps-to-issues: no .forge/GAPS.json"; exit 0; }
if [ "$PUSH" -eq 1 ]; then
  command -v gh >/dev/null 2>&1 || { echo "gaps-to-issues: gh not installed" >&2; exit 2; }
  gh auth status >/dev/null 2>&1 || { echo "gaps-to-issues: gh not authenticated (run: gh auth login)" >&2; exit 2; }
fi

PLAN=$(python3 <<'PY'
import json
def load(p,d):
    try: return json.load(open(p))
    except Exception: return d
g = load(".forge/GAPS.json", [])
gaps = g["gaps"] if isinstance(g, dict) else (g if isinstance(g, list) else [])
def is_open(x):  return str(x.get("status","open")).lower() == "open"
def is_done(x):  return str(x.get("status","")).lower() in ("resolved","closed","done")
out=[]
for gp in gaps:
    if not isinstance(gp, dict): continue
    gid = gp.get("id","")
    issue = gp.get("issue")
    if is_open(gp) and not issue:
        labels = ",".join(["forge:gap",
                           f"sev:{str(gp.get('severity','MAJOR')).lower()}",
                           f"type:{gp.get('type','gap')}"])
        title = f"[{gp.get('type','gap')}] {gp.get('id')}: {str(gp.get('description',''))[:80]}"
        body  = (f"Filed by FORGE {gp.get('source','gap loop')}.\\n\\n"
                 f"- id: {gid}\\n- type: {gp.get('type')}\\n- severity: {gp.get('severity')}\\n"
                 f"- pillar: {gp.get('pillar')}\\n- spec_ref: {gp.get('spec_ref')}\\n"
                 f"- file: {gp.get('file','')}:{gp.get('line','')}\\n\\n{gp.get('description','')}")
        # tab-separated; newlines escaped as \n above
        print("\t".join(["CREATE", gid, title, labels, body]))
    elif is_done(gp) and issue:
        print("\t".join(["CLOSE", gid, str(issue)]))
PY
)

[ -z "$PLAN" ] && { echo "gaps-to-issues: nothing to sync."; exit 0; }

# action -> gap-id -> issue-number, accumulated for the GAPS.json write-back
MAP=""
while IFS=$'\t' read -r action gid a b c; do
  case "$action" in
    CREATE)
      title="$a"; labels="$b"; body="$c"
      if [ "$PUSH" -eq 1 ]; then
        url=$(gh issue create --title "$title" --label "$labels" --body "$(printf '%b' "$body")" 2>/dev/null || true)
        num=$(printf '%s' "$url" | grep -oE '[0-9]+$' || true)
        [ -n "$num" ] && { echo "created #$num  $gid"; MAP="$MAP$gid=$num
"; } || echo "FAILED to create issue for $gid"
      else
        echo "[dry-run] CREATE issue for $gid  labels=$labels  title=\"$title\""
      fi
      ;;
    CLOSE)
      num="$a"
      if [ "$PUSH" -eq 1 ]; then
        gh issue close "$num" -c "Resolved by FORGE (gap $gid)." >/dev/null 2>&1 && echo "closed #$num  $gid" || echo "FAILED to close #$num"
      else
        echo "[dry-run] CLOSE issue #$num for resolved gap $gid"
      fi
      ;;
  esac
done <<< "$PLAN"

# Write created issue numbers back into GAPS.json (only on --push)
if [ "$PUSH" -eq 1 ] && [ -n "$MAP" ]; then
  MAP="$MAP" python3 <<'PY'
import json, os
m = {}
for line in os.environ.get("MAP","").splitlines():
    if "=" in line:
        k,v = line.split("=",1); m[k]=int(v)
def load(p,d):
    try: return json.load(open(p))
    except Exception: return d
g = load(".forge/GAPS.json", [])
gaps = g["gaps"] if isinstance(g, dict) else g
for gp in gaps:
    if isinstance(gp, dict) and gp.get("id") in m and not gp.get("issue"):
        gp["issue"] = m[gp["id"]]
json.dump(g, open(".forge/GAPS.json","w"), indent=2)
print(f"gaps-to-issues: recorded {len(m)} issue number(s) into GAPS.json")
PY
fi
