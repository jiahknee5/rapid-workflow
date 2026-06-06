#!/usr/bin/env bash
# new-project.sh — create a new project using this skill (the deterministic P1 scaffold).
#
# This is the non-LLM "Structure" phase extracted as a one-shot command: it lays down
# everything a RAPID build needs to START — the numbered folder structure, CONSTITUTION,
# BUILD-AUTONOMY, a locked PRD, .rapid/STATE, the self-contained toolset, and the live
# Atlas deck (via atlas-init.sh). After this, the LLM phases (P1b…P9) fill the docs and
# build the app; the lifecycle E2E test (tools/lifecycle-e2e.sh) drives those stages.
#
#   new-project.sh --name <name> [--dir <parent>] [--prd <file>] [--idea "<one-liner>"]
#     --name   project name (dir = <parent>/<name>)
#     --dir    parent directory (default: ~/projects)
#     --prd    seed 01-intake/PRD.md from this file
#     --idea   one-line idea, used to write a minimal PRD if --prd is absent
#     --force  reuse an existing dir (default: refuse to clobber a non-empty dir)
#
# Prints the created project path on the last line. Idempotent-ish: refuses a non-empty
# target unless --force.
set -uo pipefail

KIT="$(cd "$(dirname "$0")/.." && pwd)"
NAME=""; PARENT="$HOME/projects"; PRD=""; IDEA=""; FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --name)  shift; NAME="${1:-}" ;;
    --dir)   shift; PARENT="${1:-}" ;;
    --prd)   shift; PRD="${1:-}" ;;
    --idea)  shift; IDEA="${1:-}" ;;
    --force) FORCE=1 ;;
    *) echo "new-project: unknown arg $1" >&2; exit 2 ;;
  esac; shift
done
[ -n "$NAME" ] || { echo "new-project: --name <name> required" >&2; exit 2; }

PROJ="$PARENT/$NAME"
if [ -d "$PROJ" ] && [ -n "$(ls -A "$PROJ" 2>/dev/null)" ] && [ "$FORCE" -ne 1 ]; then
  echo "new-project: $PROJ exists and is non-empty (use --force to reuse)" >&2; exit 3
fi

echo "new-project: creating $PROJ"
mkdir -p "$PROJ" || { echo "new-project: cannot create $PROJ" >&2; exit 2; }

# 1) Numbered folder structure (P1.1)
for d in 00-vision 01-intake 02-grounding 03-panels 04-spec 04-spec/agents 04-spec/contracts \
         05-gaps audits decisions panels tests docs src .rapid; do
  mkdir -p "$PROJ/$d"
done

# 2) Locked PRD (P1.2). From --prd file, else a minimal one from --idea.
if [ -n "$PRD" ] && [ -f "$PRD" ]; then
  cp "$PRD" "$PROJ/01-intake/PRD.md"
else
  IDEA="${IDEA:-A small app built to exercise the RAPID pipeline end to end.}"
  cat > "$PROJ/01-intake/PRD.md" <<EOF
# $NAME — PRD

## What is this?
$IDEA

## Who is this for?
The operator validating that a RAPID build produces populated docs, a built local app, and a dev deploy.

## What should it do?
- Build a small but real local application.
- Populate the documentation deck (PRD, spec, architecture, eval, …) from its own artifacts.
- Deploy to a dev target.

## What does "done" look like?
1. The documentation deck is populated (no stub pages).
2. The local app builds (build command exits 0, produces a dist/ output).
3. Dev is deployed (the deploy output exists and env.json records the dev URL).

## Constraints
- Small, self-contained, no paid services.
EOF
fi
: > "$PROJ/01-intake/DIFF.md"

# 3) CONSTITUTION.md (P1.4) — seed from the kit's reference constitution.
if [ -f "$KIT/docs/CONSTITUTION.md" ]; then
  cp "$KIT/docs/CONSTITUTION.md" "$PROJ/CONSTITUTION.md"
else
  printf '# %s — Constitution\n\nArticles I–X. Inviolable guardrails checked before merge.\n' "$NAME" > "$PROJ/CONSTITUTION.md"
fi

# 4) BUILD-AUTONOMY.md (P1.5) — from template, with the project name stamped in.
if [ -f "$KIT/templates/BUILD-AUTONOMY.md" ]; then
  sed "s/&lt;project&gt;/$NAME/g; s/<project>/$NAME/g" "$KIT/templates/BUILD-AUTONOMY.md" > "$PROJ/BUILD-AUTONOMY.md"
fi

# 4b) .rapid/INPUTS.json (P1.5) — the human-input ledger, enforced before P6 (B).
if [ -f "$KIT/templates/INPUTS.json" ]; then
  sed "s/<project>/$NAME/g" "$KIT/templates/INPUTS.json" > "$PROJ/.rapid/INPUTS.json"
fi

# 5) .rapid/STATE.json (P1.7)
cat > "$PROJ/.rapid/STATE.json" <<EOF
{ "project": "$NAME", "phase": 1, "phase_name": "structure", "status": "complete", "track": "fast" }
EOF

# 6) Self-contained toolset — copy the kit tools + templates so the project can build,
#    document, verify, and deploy on its own (the kit supplies the form).
cp -R "$KIT/tools" "$PROJ/tools" 2>/dev/null
cp -R "$KIT/templates" "$PROJ/templates" 2>/dev/null

# 7) Scaffold the project's own Atlas deck (P1.8): nav + sidebar + env.json + regen.json + stubs.
bash "$KIT/tools/atlas-init.sh" "$PROJ" >/dev/null 2>&1 || echo "new-project: atlas-init had warnings" >&2

# 8) docs registry
( cd "$PROJ" && bash tools/build-docs-registry.sh >/dev/null 2>&1 ) || true

echo "new-project: scaffold complete"
echo "$PROJ"
