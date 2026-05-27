#!/usr/bin/env bash
# FORGE Phase Gate Hook — blocks STATE.json advancement unless artifacts exist.
# Install: add as a PreToolUse hook on Write/Edit of .forge/STATE.json
# This is the enforcement mechanism. Prose won't do it. A hook will.

set -euo pipefail

STATE_FILE=".forge/STATE.json"

# Only trigger on STATE.json writes
[[ "${TOOL_INPUT_FILE_PATH:-}" == *"STATE.json"* ]] || exit 0

# Parse the next phase from the new content
NEXT_PHASE=$(echo "${TOOL_INPUT_CONTENT:-}" | grep -o '"phase"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*' || echo "")
[[ -z "$NEXT_PHASE" ]] && exit 0

# Phase 2: PRD-ENHANCED.md must exist (P1b complete)
if [ "$NEXT_PHASE" -ge 2 ] 2>/dev/null; then
  if [ ! -f "01-intake/PRD-ENHANCED.md" ]; then
    echo "PHASE GATE BLOCKED: P1b artifact missing — 01-intake/PRD-ENHANCED.md does not exist"
    exit 1
  fi
fi

# Phase 4: Panel synthesis must exist (P2-P3 complete)
if [ "$NEXT_PHASE" -ge 4 ] 2>/dev/null; then
  if [ ! -f "03-panels/synthesis.md" ]; then
    echo "PHASE GATE BLOCKED: P2 artifact missing — 03-panels/synthesis.md does not exist"
    exit 1
  fi
fi

# Phase 5: Spec must exist (P4 complete)
if [ "$NEXT_PHASE" -ge 5 ] 2>/dev/null; then
  if [ ! -f "04-spec/spec.md" ]; then
    echo "PHASE GATE BLOCKED: P4 artifact missing — 04-spec/spec.md does not exist"
    exit 1
  fi
fi

# Phase 6: Eval harness must exist and have tests (P5 complete) — R1 + R4
if [ "$NEXT_PHASE" -ge 6 ] 2>/dev/null; then
  if [ ! -d ".forge/EVAL" ]; then
    echo "PHASE GATE BLOCKED: eval harness directory .forge/EVAL/ does not exist"
    exit 1
  fi
  TEST_COUNT=$(find .forge/EVAL -name "*.test.*" -o -name "*.spec.*" 2>/dev/null | wc -l)
  if [ "$TEST_COUNT" -lt 1 ]; then
    echo "PHASE GATE BLOCKED: eval harness has 0 test files — task-00 (eval-harness) must complete first"
    exit 1
  fi
  if [ ! -f ".forge/TASKS.json" ]; then
    echo "PHASE GATE BLOCKED: .forge/TASKS.json does not exist"
    exit 1
  fi
fi

# Phase 7: P6_EXIT.json must exist and all assertions must pass (P6 complete) — R1
if [ "$NEXT_PHASE" -ge 7 ] 2>/dev/null; then
  if [ ! -f ".forge/P6_EXIT.json" ]; then
    echo "PHASE GATE BLOCKED: .forge/P6_EXIT.json does not exist — P6 exit assertions not run"
    exit 1
  fi
  FAIL_COUNT=$(grep -c '"pass":false\|"pass": false\|"result":"fail"\|"result": "fail"' .forge/P6_EXIT.json 2>/dev/null || echo "0")
  if [ "$FAIL_COUNT" -gt 0 ]; then
    echo "PHASE GATE BLOCKED: P6_EXIT.json has $FAIL_COUNT failing assertions"
    exit 1
  fi
fi

# Phase 8: WALKTHROUGH.md must exist with surface coverage (P7 complete) — R6
if [ "$NEXT_PHASE" -ge 8 ] 2>/dev/null; then
  if [ ! -f ".forge/WALKTHROUGH.md" ]; then
    echo "PHASE GATE BLOCKED: .forge/WALKTHROUGH.md does not exist — walkthrough not run"
    exit 1
  fi
fi

exit 0
