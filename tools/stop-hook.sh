#!/usr/bin/env bash
# FORGE Stop / SubagentStop hook — deterministic halt logging + continuation.
#
# Registered SYNCHRONOUSLY (no "async") on Stop and SubagentStop in
# ~/.claude/settings.json. Async hooks cannot block; this one must, so it is
# the one synchronous entry alongside the existing async clorch/speak hooks.
#
# Fires on EVERY session-end on this machine. It MUST no-op instantly unless
# the cwd is an active FORGE build (.forge/STATE.json present). Defensive by
# design: no `set -e`, every path ends in `exit 0`, all reads guarded — a bug
# here must never trap an unrelated Claude session.
#
# Behavior inside an active build:
#   1. Always append a STOP event to .forge/observe/<role>.jsonl  (fixes silent halts)
#   2. Loop guard: if stop_hook_active, allow the stop (never block twice)
#   3. SubagentStop: log only (parent's Stop hook owns phase continuation)
#   4. Stop: if the current phase's completion artifact is MISSING, block with
#      the concrete next step; if present, allow the stop (gate / advance)
#   5. Runaway cap: after N consecutive blocks in one phase, escalate + allow stop

INPUT=$(cat 2>/dev/null || true)

# ---- Guard: only act inside an active FORGE build -------------------------
[ -f ".forge/STATE.json" ] || exit 0

# ---- Parse stdin (python3; matches repo style, jq also present) -----------
field() {
  printf '%s' "$INPUT" | python3 -c "import sys,json
try: d=json.load(sys.stdin)
except Exception: d={}
v=d.get('$1','')
print('' if v is None else v)" 2>/dev/null || true
}

EVENT=$(field hook_event_name)
STOP_ACTIVE=$(field stop_hook_active)
AGENT_TYPE=$(field agent_type)
ROLE="${FORGE_ROLE:-${AGENT_TYPE:-orchestrator}}"
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "")

PHASE_NUM=$(python3 -c "import json
try: print(json.load(open('.forge/STATE.json')).get('phase',''))
except Exception: print('')" 2>/dev/null || echo "")

# ---- Always log the halt (this is the half that fixes "completed but unlogged") ----
log_event() {  # $1=event $2=detail
  mkdir -p .forge/observe 2>/dev/null || return 0
  local seq
  seq=$(cat .forge/observe/*.jsonl 2>/dev/null | wc -l | tr -d ' ')
  seq=$(( ${seq:-0} + 1 ))
  printf '{"t":"%s","seq":%s,"agent":"%s","role":"%s","event":"%s","detail":"%s","phase":"P%s"}\n' \
    "$TS" "$seq" "$ROLE" "$ROLE" "$1" "$2" "${PHASE_NUM:-?}" \
    >> ".forge/observe/${ROLE}.jsonl" 2>/dev/null || true
}

log_event "STOP" "${EVENT:-Stop} turn ended"

# ---- Loop guard: never block on a stop we already forced ------------------
case "$STOP_ACTIVE" in True|true|1) exit 0 ;; esac

# ---- SubagentStop: log only. The hook cannot reliably map a subagent to its
#      task, and the parent's Stop hook already enforces phase completion.
#      Blocking a fan-out worker on an orchestrator-level artifact misfires. --
[ "$EVENT" = "SubagentStop" ] && exit 0

# ---- Need a valid phase to reason about -----------------------------------
[ -z "$PHASE_NUM" ] && exit 0

# ---- Determine the CURRENT phase's completion artifact --------------------
missing=""
nextstep=""
case "$PHASE_NUM" in
  1)
    [ -f "01-intake/PRD-ENHANCED.md" ] || {
      missing="01-intake/PRD-ENHANCED.md"
      nextstep="finish P1b PRD decomposition (MUST/SHOULD/COULD) and write 01-intake/PRD-ENHANCED.md"; }
    ;;
  2|3)
    [ -f "03-panels/synthesis.md" ] || {
      missing="03-panels/synthesis.md"
      nextstep="complete the expert panels + research and write 03-panels/synthesis.md"; }
    ;;
  4)
    [ -f "04-spec/spec.md" ] || {
      missing="04-spec/spec.md"
      nextstep="derive the spec from the PRD (maintained diff) and write 04-spec/spec.md"; }
    ;;
  5)
    testcount=$(find .forge/EVAL \( -name '*.test.*' -o -name '*.spec.*' -o -name 'tests.ts' -o -name 'tests' \) 2>/dev/null | wc -l | tr -d ' ')
    if [ ! -d ".forge/EVAL" ] || [ "${testcount:-0}" -lt 1 ] 2>/dev/null; then
      missing=".forge/EVAL/ tests"
      nextstep="generate the immutable eval harness (task-00) before the build can start"
    elif [ ! -f ".forge/TASKS.json" ]; then
      missing=".forge/TASKS.json"
      nextstep="decompose the spec into tasks and write .forge/TASKS.json"
    fi
    ;;
  6)
    if [ ! -f ".forge/P6_EXIT.json" ]; then
      inc=$(python3 -c "import json
try:
 t=json.load(open('.forge/TASKS.json'))
 ts=t if isinstance(t,list) else t.get('tasks',[])
 done={'done','complete','completed','passed','merged'}
 print(','.join(str(x.get('id','?')) for x in ts if str(x.get('status','')).lower() not in done))
except Exception: print('')" 2>/dev/null || echo "")
      missing=".forge/P6_EXIT.json"
      if [ -n "$inc" ]; then
        nextstep="continue the build — incomplete tasks: ${inc}. When all tasks pass, run the P6 exit assertions and write .forge/P6_EXIT.json"
      else
        nextstep="all tasks look done — run the P6 exit assertions (incl. watchdog AUDIT.json check) and write .forge/P6_EXIT.json"
      fi
    fi
    ;;
  7)
    [ -f ".forge/WALKTHROUGH.md" ] || {
      missing=".forge/WALKTHROUGH.md"
      nextstep="run the P7 walkthrough across every surface and write .forge/WALKTHROUGH.md"; }
    ;;
  *)
    : # P0, P8 (human-driven gap loop), P9, P10 — no single hard artifact; allow stop
    ;;
esac

# ---- Artifact present → phase work complete → allow stop (gate / advance) -
[ -z "$missing" ] && exit 0

# ---- Runaway cap (per phase) ----------------------------------------------
cnt_file=".forge/.stop_count"
phase_file=".forge/.stop_phase"
last_phase=$(cat "$phase_file" 2>/dev/null || echo "")
if [ "$last_phase" != "$PHASE_NUM" ]; then
  echo "0" > "$cnt_file" 2>/dev/null || true
  echo "$PHASE_NUM" > "$phase_file" 2>/dev/null || true
fi
cnt=$(cat "$cnt_file" 2>/dev/null || echo 0)
[ -z "$cnt" ] && cnt=0
MAX=5
if [ "$cnt" -ge "$MAX" ] 2>/dev/null; then
  log_event "ESCALATE" "stop-hook nudged ${cnt}x in P${PHASE_NUM} without producing ${missing} — allowing stop for operator"
  exit 0
fi
echo $(( cnt + 1 )) > "$cnt_file" 2>/dev/null || true

# ---- Block the stop and inject the concrete next step ---------------------
log_event "LOOP_ITER" "blocked premature stop: ${missing} missing"
python3 -c "import json
reason=('FORGE phase P${PHASE_NUM} is not complete: required artifact \"${missing}\" does not exist yet. '
        'Do not stop. Next step: ${nextstep}. '
        'If you are genuinely blocked on a human decision or an external dependency, append the blocker to .forge/MEMORY.md, note it in .forge/STATE.json, then stopping is allowed.')
print(json.dumps({'decision':'block','reason':reason}))" 2>/dev/null || exit 0
exit 0
