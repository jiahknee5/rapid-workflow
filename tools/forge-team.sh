#!/usr/bin/env bash
# forge-team.sh — launch the FORGE build TEAM as terminal agents.
#
# The persistent lead agents — planner, coder, tester, reviewer, watchdog —
# each run in their OWN terminal, connected as one team over the claude-peers
# bus. Each lead fans out SUBAGENTS for parallel work (the coder dispatches
# coding subagents, the tester per-surface test subagents, the reviewer
# per-dimension review subagents). Run from a project root (needs .forge/STATE.json).
#
#   forge-team.sh                 launch the team via tmux (session: forge-team)
#   forge-team.sh --dry-run       print what would launch; do nothing
#   forge-team.sh --cursor        write .vscode/tasks.json so each role opens in
#                                 its own Cursor / VS Code integrated terminal
#   forge-team.sh --track fast    smaller team (planner, coder, reviewer, watchdog)
#   forge-team.sh /path/to/proj   target a specific project root
#
# Context + hooks: each window exports FORGE_ROLE=<role> and reads its contract
# at 04-spec/agents/<role>.md (seeded from templates/agent-roles/). The globally
# installed FORGE hooks (phase-gate R1, continuation R7, conformance R8, stub R9,
# status/heartbeat) attribute themselves per FORGE_ROLE automatically — no
# per-terminal hook install needed.
set -uo pipefail

PROJECT="$PWD"; MODE="tmux"; TRACK="full"; DEMO=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) MODE="dry" ;;
    --cursor)  MODE="cursor" ;;
    --demo)    DEMO=1 ;;   # create the named role terminals but run a placeholder, not claude
    --track)   shift; TRACK="${1:-full}" ;;
    -*)        echo "forge-team: unknown flag $1" >&2; exit 2 ;;
    *)         PROJECT="$1" ;;
  esac; shift
done
PROJECT="$(cd "$PROJECT" 2>/dev/null && pwd)" || { echo "forge-team: bad project path" >&2; exit 2; }
TOOLS_DIR="$(cd "$(dirname "$0")" && pwd)"
TPL_DIR="$(cd "$TOOLS_DIR/../templates/agent-roles" 2>/dev/null && pwd || true)"

[ -f "$PROJECT/.forge/STATE.json" ] || { echo "forge-team: not a FORGE build (no .forge/STATE.json in $PROJECT)" >&2; exit 2; }

case "$TRACK" in
  fast) ROLES="planner coder reviewer watchdog" ;;   # tester folds into coder's keep-or-revert on a fast track
  *)    ROLES="planner coder tester reviewer watchdog" ;;
esac

mission() { case "$1" in
  planner)  echo "team lead — own the plan, decomposition, human gates, and operator relationship; assign work to the coder; route tester/reviewer/watchdog verdicts; re-plan on gaps" ;;
  coder)    echo "build lead — implement tasks from .forge/TASKS.json, fanning out coding subagents for independent tasks; keep-or-revert on the tester's results; never self-approve" ;;
  tester)   echo "test lead — own the immutable eval harness (task-00); run and extend behavior tests, fanning out per-surface test subagents; report pass/fail to the planner" ;;
  reviewer) echo "review lead — tiered code review of every diff via per-dimension subagents (correctness / security / performance); APPROVE or REJECT; the writer is never the auditor" ;;
  watchdog) echo "R2 auditor — independently audit completed work against spec/architecture for drift; write .forge/AUDIT.json; never implements" ;;
esac; }

ensure_brief() {  # seed 04-spec/agents/<role>.md from the template if missing
  local role="$1"
  local dst="$PROJECT/04-spec/agents/$role.md"
  mkdir -p "$PROJECT/04-spec/agents"
  [ -f "$dst" ] || { [ -n "$TPL_DIR" ] && [ -f "$TPL_DIR/$role.md" ] && cp "$TPL_DIR/$role.md" "$dst"; }
}

kickoff() {  # the initial prompt handed to `claude` in the role's terminal
  local role="$1"
  printf 'You are the FORGE %s. Read 04-spec/agents/%s.md (your role contract), .forge/STATE.json and .forge/TASKS.json. Call claude-peers set_summary with your role + current focus, list_peers to find the team, then begin: %s. Coordinate over claude-peers and answer teammates immediately.' \
    "$role" "$role" "$(mission "$role")"
}

case "$MODE" in
  dry)
    echo "FORGE team (track=$TRACK) — would launch in $PROJECT:"
    for r in $ROLES; do ensure_brief "$r"; printf '  [%s] cd %q && export FORGE_ROLE=%s && claude "<kickoff>"\n' "$r" "$PROJECT" "$r"; done
    ;;
  cursor)
    for r in $ROLES; do ensure_brief "$r"; done
    ROLES_CSV="$ROLES" PROJECT="$PROJECT" python3 - <<'PY'
import json, os
project=os.environ["PROJECT"]; roles=os.environ["ROLES_CSV"].split()
def cmd(r):
    kick=(f"You are the FORGE {r}. Read 04-spec/agents/{r}.md, .forge/STATE.json and .forge/TASKS.json; "
          f"set your claude-peers summary; list_peers; then begin your role. Coordinate over claude-peers.")
    return f'export FORGE_ROLE={r} && claude "{kick}"'
tasks=[{"label":f"FORGE: {r}","type":"shell","command":cmd(r),
        "presentation":{"panel":"dedicated","group":"forge-team","reveal":"always","focus":False},
        "problemMatcher":[]} for r in roles]
tasks.append({"label":"FORGE: launch team","dependsOrder":"parallel",
              "dependsOn":[f"FORGE: {r}" for r in roles],"problemMatcher":[]})
os.makedirs(os.path.join(project,".vscode"),exist_ok=True)
json.dump({"version":"2.0.0","tasks":tasks}, open(os.path.join(project,".vscode","tasks.json"),"w"), indent=2)
print("wrote .vscode/tasks.json")
PY
    echo "In Cursor: Cmd/Ctrl+Shift+P → 'Run Task' → 'FORGE: launch team' — each role opens in its own integrated terminal."
    ;;
  tmux)
    command -v tmux >/dev/null 2>&1 || { echo "forge-team: tmux not found (brew install tmux) — or use: forge-team.sh --cursor" >&2; exit 2; }
    S=forge-team
    if tmux has-session -t "$S" 2>/dev/null; then echo "forge-team: session '$S' already running — attach: tmux attach -t $S"; exit 0; fi
    first=1
    for r in $ROLES; do
      ensure_brief "$r"
      if [ $first -eq 1 ]; then tmux new-session -d -s "$S" -n "$r" -c "$PROJECT"; first=0
      else tmux new-window -t "$S" -n "$r" -c "$PROJECT"; fi
      if [ "$DEMO" -eq 1 ]; then
        tmux send-keys -t "$S:$r" "export FORGE_ROLE=$r && clear && printf 'FORGE role: %s\n  FORGE_ROLE=%s  cwd=%s\n  contract: 04-spec/agents/%s.md\n  (demo — no claude launched; drop --demo to start the real agent here)\n' \"$r\" \"\$FORGE_ROLE\" \"\$(pwd)\" \"$r\"" Enter
      else
        tmux send-keys -t "$S:$r" "export FORGE_ROLE=$r && claude $(printf '%q' "$(kickoff "$r")")" Enter
      fi
    done
    echo "FORGE team launched in tmux session '$S' (roles: $ROLES). Attach: tmux attach -t $S  (or run 'tmux attach -t $S' inside a Cursor terminal)."
    ;;
esac
