#!/usr/bin/env bash
# post-write-hook.sh — PostToolUse hook for Write/Edit operations.
# Triggers docs registry refresh on STATE.json writes and appends to
# CHANGES.md for writes to numbered folders.
set -uo pipefail

# Hook input arrives as JSON on stdin (Claude Code contract). There is no
# TOOL_INPUT_FILE_PATH env var — parse the path from .tool_input.file_path.
INPUT=$(cat 2>/dev/null || true)
FILE_PATH=$(printf '%s' "$INPUT" | python3 -c "import sys,json
try: d=json.load(sys.stdin)
except Exception: d={}
print((d.get('tool_input') or {}).get('file_path','') or '')" 2>/dev/null || true)
[ -z "$FILE_PATH" ] && exit 0

# Two distinct roots: TOOLS_DIR is where these scripts live (the workflow repo);
# PROJECT_ROOT is the build's cwd (where .forge/ and the numbered folders are).
# Build artifacts (CHANGES.md, STATE.json) belong to the project, not the repo.
TOOLS_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$PWD"

# Only act inside an active build
[ -f "$PROJECT_ROOT/.forge/STATE.json" ] || exit 0

# STATE.json write → refresh docs registry
if [[ "$FILE_PATH" == *".forge/STATE.json"* ]]; then
  bash "$TOOLS_DIR/build-docs-registry.sh" 2>/dev/null || true
  exit 0
fi

# Numbered folder, decisions/, panels/, tests/ → append to CHANGES.md
if [[ "$FILE_PATH" =~ [0-9]{2}-[^/]+ ]] || \
   [[ "$FILE_PATH" == *"decisions/"* ]] || \
   [[ "$FILE_PATH" == *"panels/"* ]] || \
   [[ "$FILE_PATH" == *"tests/"* ]]; then

  CHANGES_FILE="$PROJECT_ROOT/CHANGES.md"
  TIMESTAMP=$(date -u +%Y-%m-%dT%H:%MZ)
  REL_PATH=$(python3 -c "import os; print(os.path.relpath('$FILE_PATH', '$PROJECT_ROOT'))" 2>/dev/null || echo "$FILE_PATH")

  # Extract phase from STATE.json if it exists
  PHASE="—"
  if [ -f "$PROJECT_ROOT/.forge/STATE.json" ]; then
    PHASE=$(python3 -c "import json; print('P'+str(json.load(open('$PROJECT_ROOT/.forge/STATE.json')).get('phase','?')))" 2>/dev/null || echo "—")
  fi

  # Create CHANGES.md with header if it doesn't exist
  if [ ! -f "$CHANGES_FILE" ]; then
    printf '| Date | Phase | File | Change |\n|------|-------|------|--------|\n' > "$CHANGES_FILE"
  fi

  printf '| %s | %s | %s | Write/Edit |\n' "$TIMESTAMP" "$PHASE" "$REL_PATH" >> "$CHANGES_FILE"
fi

exit 0
