#!/usr/bin/env bash
# install-hooks.sh — idempotently wire FORGE's deterministic hooks into the
# GLOBAL Claude Code config, portably.
#
# New environment? Clone this repo anywhere and run:  bash tools/install-hooks.sh
# It symlinks the tools to a stable $HOME path and registers the hooks against
# that path, so the global settings never hardcode the repo location.
#
# Safe to re-run: it strips any prior FORGE hook entries before re-adding the
# canonical ones (no duplicates), and backs up settings.json first.
set -uo pipefail

TOOLS_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOKS_LINK="$HOME/.claude/hooks/forge"
SETTINGS="$HOME/.claude/settings.json"

mkdir -p "$HOME/.claude/hooks"
ln -sfn "$TOOLS_DIR" "$HOOKS_LINK"
echo "symlink:  $HOOKS_LINK -> $TOOLS_DIR"

[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
BAK="$SETTINGS.bak-$(date -u +%Y%m%d-%H%M%S)"
cp "$SETTINGS" "$BAK"
echo "backup:   $BAK"

python3 - "$SETTINGS" <<'PY'
import json, sys
path = sys.argv[1]
d = json.load(open(path))
hooks = d.setdefault("hooks", {})

OURS = {"stop-hook.sh", "module-conformance-hook.sh",
        "phase-gate-hook.sh", "post-write-hook.sh", "stub-detect-hook.sh"}
B = "bash $HOME/.claude/hooks/forge"

def strip(ev):
    out = []
    for g in hooks.get(ev, []):
        orig = g.get("hooks", [])
        kept = [h for h in orig if not any(b in h.get("command", "") for b in OURS)]
        if kept or not orig:          # keep groups that still have hooks (or were empty)
            g = dict(g); g["hooks"] = kept; out.append(g)
        # groups emptied by stripping were FORGE-only -> dropped
    hooks[ev] = out

def add(ev, matcher, entries):        # entries: list of (command, is_async)
    grp = {"matcher": matcher, "hooks": []}
    for cmd, is_async in entries:
        h = {"type": "command", "command": cmd}
        if is_async: h["async"] = True
        grp["hooks"].append(h)
    hooks.setdefault(ev, []).append(grp)

for ev in ("Stop", "SubagentStop", "PreToolUse", "PostToolUse"):
    strip(ev)

# Stop / SubagentStop: SYNCHRONOUS (must be able to block) — R7
add("Stop",         "",          [(f"{B}/stop-hook.sh", False)])
add("SubagentStop", "",          [(f"{B}/stop-hook.sh", False)])
# PreToolUse phase gate: SYNCHRONOUS (must be able to block via exit 2) — R1
add("PreToolUse",   "Write|Edit", [(f"{B}/phase-gate-hook.sh", False)])
# PostToolUse: non-blocking side effects — async to add no latency
add("PostToolUse",  "Write|Edit", [(f"{B}/post-write-hook.sh", True),
                                    (f"{B}/module-conformance-hook.sh", True),
                                    (f"{B}/stub-detect-hook.sh", True)])

json.dump(d, open(path, "w"), indent=2)
print("settings: registered Stop, SubagentStop, PreToolUse, PostToolUse (FORGE hooks)")
PY

python3 -c "import json; json.load(open('$SETTINGS')); print('validate: JSON OK')"
echo "done."
