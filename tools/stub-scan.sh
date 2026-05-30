#!/usr/bin/env bash
# stub-scan.sh — detect placeholder/incomplete code ("stubs").
#
# Shared by the write-time detector hook (R9) and the ship gate. It is a NET,
# not a proof: the real anti-stub mechanism is behavior-asserting tests +
# keep-or-revert. This catches the known patterns those miss.
#
# Usage:
#   stub-scan.sh <file>          scan one file  → JSONL findings on stdout
#   stub-scan.sh --tree [dir]    scan a tree    → JSONL findings on stdout
#                                                  exit 3 if any stub found
#
# A line containing `forge:allow-stub` is exempt (intentional, documented).
set -uo pipefail

# Source extensions only — docs/markdown legitimately contain markers like TODO.  (forge:allow-stub)
SRC_RE='\.(ts|tsx|js|jsx|mjs|cjs|py|go|rs|java|rb|php|c|cc|cpp|h|hpp|cs|swift|kt|kts|scala|sh)$'

# High-signal stub markers (extended regex). Conservative on purpose.
# Note: the bare word "placeholder" was dropped (it false-matched HTML/React
# props); use the explicit at-placeholder annotation for a deliberate stub.
MARKER_RE='TODO|FIXME|XXX|HACK|NotImplementedError|NotImplemented|raise[[:space:]]+NotImplemented|not[[:space:]]+implemented|unimplemented|@stub|@placeholder|lorem[[:space:]]+ipsum|throw[[:space:]]+new[[:space:]]+Error\([[:space:]]*["'"'"']?(not[[:space:]]+implemented|todo|unimplemented|stub)'  # forge:allow-stub: marker definitions, not stubs

scan_file() {
  local f="$1"
  [ -f "$f" ] || return 0
  # grep -nE: line numbers; -I skips binary. Filter allowlist. Emit JSONL.
  grep -nEI "$MARKER_RE" "$f" 2>/dev/null | grep -v 'forge:allow-stub' | \
  while IFS=: read -r lineno text; do
    marker=$(printf '%s' "$text" | grep -oEi "$MARKER_RE" | head -1)
    python3 -c "import json,sys
print(json.dumps({
  'file': sys.argv[1], 'line': int(sys.argv[2]),
  'marker': sys.argv[3].strip(),
  'text': sys.argv[4].strip()[:160],
}))" "$f" "$lineno" "$marker" "$text" 2>/dev/null || true
  done
}

found=0

if [ "${1:-}" = "--tree" ]; then
  dir="${2:-.}"
  while IFS= read -r f; do
    out=$(scan_file "$f")
    if [ -n "$out" ]; then printf '%s\n' "$out"; found=1; fi
  done < <(grep -rEIl "$MARKER_RE" "$dir" 2>/dev/null \
             --exclude-dir=node_modules --exclude-dir=.git \
             --exclude-dir=.forge --exclude-dir=dist --exclude-dir=build \
           | grep -E "$SRC_RE" || true)
  [ "$found" -eq 1 ] && exit 3 || exit 0
else
  f="${1:-}"
  [ -z "$f" ] && { echo "usage: stub-scan.sh <file> | --tree [dir]" >&2; exit 2; }
  printf '%s' "$f" | grep -qE "$SRC_RE" || exit 0   # non-source → nothing to do
  out=$(scan_file "$f")
  [ -n "$out" ] && { printf '%s\n' "$out"; exit 3; }
  exit 0
fi
