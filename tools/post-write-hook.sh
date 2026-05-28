#!/usr/bin/env bash
# post-write-hook.sh — PostToolUse hook for Write/Edit operations.
# Triggers docs registry refresh on STATE.json writes and appends to
# CHANGES.md for writes to numbered folders.
set -euo pipefail

FILE_PATH="${TOOL_INPUT_FILE_PATH:-}"
[ -z "$FILE_PATH" ] && exit 0

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# STATE.json write → refresh docs registry
if [[ "$FILE_PATH" == *".forge/STATE.json"* ]]; then
  bash "$REPO_ROOT/tools/build-docs-registry.sh" 2>/dev/null || true
  exit 0
fi

# Numbered folder, decisions/, panels/, tests/ → append to CHANGES.md
if [[ "$FILE_PATH" =~ [0-9]{2}-[^/]+ ]] || \
   [[ "$FILE_PATH" == *"decisions/"* ]] || \
   [[ "$FILE_PATH" == *"panels/"* ]] || \
   [[ "$FILE_PATH" == *"tests/"* ]]; then

  CHANGES_FILE="$REPO_ROOT/CHANGES.md"
  TIMESTAMP=$(date -u +%Y-%m-%dT%H:%MZ)
  REL_PATH=$(python3 -c "import os; print(os.path.relpath('$FILE_PATH', '$REPO_ROOT'))" 2>/dev/null || echo "$FILE_PATH")

  # Extract phase from STATE.json if it exists
  PHASE="—"
  if [ -f "$REPO_ROOT/.forge/STATE.json" ]; then
    PHASE=$(python3 -c "import json; print('P'+str(json.load(open('$REPO_ROOT/.forge/STATE.json')).get('phase','?')))" 2>/dev/null || echo "—")
  fi

  # Create CHANGES.md with header if it doesn't exist
  if [ ! -f "$CHANGES_FILE" ]; then
    printf '| Date | Phase | File | Change |\n|------|-------|------|--------|\n' > "$CHANGES_FILE"
  fi

  printf '| %s | %s | %s | Write/Edit |\n' "$TIMESTAMP" "$PHASE" "$REL_PATH" >> "$CHANGES_FILE"
fi

exit 0
