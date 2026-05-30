#!/usr/bin/env bash
# FORGE Phase Gate Hook — blocks STATE.json advancement unless artifacts exist.
# Install: add as a PreToolUse hook on Write/Edit of .forge/STATE.json
# This is the enforcement mechanism. Prose won't do it. A hook will.

set -uo pipefail

STATE_FILE=".forge/STATE.json"

# Hook input arrives as JSON on stdin (Claude Code contract) — NOT via
# TOOL_INPUT_* env vars. Parse the file path and the new content from stdin.
INPUT=$(cat 2>/dev/null || true)
FILE_PATH=$(printf '%s' "$INPUT" | python3 -c "import sys,json
try: d=json.load(sys.stdin)
except Exception: d={}
print((d.get('tool_input') or {}).get('file_path','') or '')" 2>/dev/null || true)

# Only trigger on STATE.json writes
[[ "$FILE_PATH" == *"STATE.json"* ]] || exit 0

# New phase comes from the written content (Write: .content; Edit: .new_string)
CONTENT=$(printf '%s' "$INPUT" | python3 -c "import sys,json
try: d=json.load(sys.stdin)
except Exception: d={}
ti=d.get('tool_input') or {}
print(ti.get('content') or ti.get('new_string') or '')" 2>/dev/null || true)
NEXT_PHASE=$(echo "$CONTENT" | grep -o '"phase"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*' || echo "")
[[ -z "$NEXT_PHASE" ]] && exit 0

# PreToolUse blocks on exit 2 with the reason on stderr — route all output there.
exec 1>&2

# Phase 2: PRD-ENHANCED.md must exist (P1b complete)
if [ "$NEXT_PHASE" -ge 2 ] 2>/dev/null; then
  if [ ! -f "01-intake/PRD-ENHANCED.md" ]; then
    echo "PHASE GATE BLOCKED: P1b artifact missing — 01-intake/PRD-ENHANCED.md does not exist"
    exit 2
  fi
fi

# Phase 4: Panel synthesis must exist (P2-P3 complete)
if [ "$NEXT_PHASE" -ge 4 ] 2>/dev/null; then
  if [ ! -f "03-panels/synthesis.md" ]; then
    echo "PHASE GATE BLOCKED: P2 artifact missing — 03-panels/synthesis.md does not exist"
    exit 2
  fi
fi

# Phase 5: Spec must exist (P4 complete)
if [ "$NEXT_PHASE" -ge 5 ] 2>/dev/null; then
  if [ ! -f "04-spec/spec.md" ]; then
    echo "PHASE GATE BLOCKED: P4 artifact missing — 04-spec/spec.md does not exist"
    exit 2
  fi
fi

# Phase 6: Eval harness must exist and have tests (P5 complete) — R1 + R4
if [ "$NEXT_PHASE" -ge 6 ] 2>/dev/null; then
  if [ ! -d ".forge/EVAL" ]; then
    echo "PHASE GATE BLOCKED: eval harness directory .forge/EVAL/ does not exist"
    exit 2
  fi
  TEST_COUNT=$(find .forge/EVAL \( -name "*.test.*" -o -name "*.spec.*" -o -name "tests.ts" -o -name "tests" \) 2>/dev/null | wc -l)
  if [ "$TEST_COUNT" -lt 1 ]; then
    echo "PHASE GATE BLOCKED: eval harness has 0 test files — task-00 (eval-harness) must complete first"
    exit 2
  fi
  if [ ! -f ".forge/TASKS.json" ]; then
    echo "PHASE GATE BLOCKED: .forge/TASKS.json does not exist"
    exit 2
  fi
fi

# Phase 7: P6_EXIT.json must exist and all assertions must pass (P6 complete) — R1
if [ "$NEXT_PHASE" -ge 7 ] 2>/dev/null; then
  if [ ! -f ".forge/P6_EXIT.json" ]; then
    echo "PHASE GATE BLOCKED: .forge/P6_EXIT.json does not exist — P6 exit assertions not run"
    exit 2
  fi
  FAIL_COUNT=$(python3 -c "import json,sys
try: d=json.load(open('.forge/P6_EXIT.json'))
except Exception: print(0); sys.exit()
a=d if isinstance(d,list) else (d.get('assertions') or [])
print(sum(1 for x in a if isinstance(x,dict) and (x.get('pass') is False or str(x.get('result','')).lower()=='fail')))" 2>/dev/null || echo 0)
  if [ "${FAIL_COUNT:-0}" -gt 0 ] 2>/dev/null; then
    echo "PHASE GATE BLOCKED: P6_EXIT.json has $FAIL_COUNT failing assertions"
    exit 2
  fi
fi

# Phase 8: WALKTHROUGH.md must exist with surface coverage (P7 complete) — R6
if [ "$NEXT_PHASE" -ge 8 ] 2>/dev/null; then
  if [ ! -f ".forge/WALKTHROUGH.md" ]; then
    echo "PHASE GATE BLOCKED: .forge/WALKTHROUGH.md does not exist — walkthrough not run"
    exit 2
  fi
fi

exit 0
