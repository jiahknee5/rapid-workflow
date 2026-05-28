#!/usr/bin/env bash
# build-docs-registry.sh — Scan filesystem and regenerate docs.json
# Preserves manual metadata (descriptions, categories, archive entries).
# Idempotent: running twice produces the same result.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOCS_JSON="$REPO_ROOT/docs.json"
TMP_JSON="$REPO_ROOT/docs.json.tmp"

# Read existing docs.json for metadata preservation
if [ -f "$DOCS_JSON" ]; then
  EXISTING=$(cat "$DOCS_JSON")
  OLD_VERSION=$(echo "$EXISTING" | python3 -c "import sys,json; print(json.load(sys.stdin).get('version',2))")
else
  EXISTING='{}'
  OLD_VERSION=2
fi

NEW_VERSION=$((OLD_VERSION + 1))
TODAY=$(date +%Y-%m-%d)

# Build lookup of existing doc metadata keyed by file path
python3 - "$DOCS_JSON" "$REPO_ROOT" "$NEW_VERSION" "$TODAY" <<'PYSCRIPT'
import json, os, sys, glob
from pathlib import Path

docs_json_path = sys.argv[1]
repo_root = sys.argv[2]
new_version = int(sys.argv[3])
today = sys.argv[4]

# Load existing registry
existing = {}
if os.path.exists(docs_json_path):
    with open(docs_json_path) as f:
        existing = json.load(f)

old_docs = {d["file"]: d for d in existing.get("docs", [])}
old_archive = {d["file"]: d for d in existing.get("archive", [])}
default_categories = {
    "forge": {"label": "FORGE System", "description": "How the FORGE autonomous build system works"},
    "workflow": {"label": "AI Build Workflow", "description": "Johnny's methodology for AI-assisted software builds"},
    "template": {"label": "Templates", "description": "Reusable templates for projects built with the workflow"},
    "skill": {"label": "Skills", "description": "Claude Code skill definitions"},
}
categories = existing.get("categories", {})
for k, v in default_categories.items():
    if k not in categories:
        categories[k] = v

# Infer category from file path
def infer_category(relpath):
    if "template" in relpath:
        return "template"
    if "skill" in relpath:
        return "skill"
    if "forge" in relpath or "observe" in relpath or "phase-gate" in relpath or "dashboard" in relpath:
        return "forge"
    if "observatory" in relpath:
        return "forge"
    return "workflow"

# Infer title from filename
def infer_title(relpath):
    p = Path(relpath)
    if p.name == "SKILL.md":
        skill_dir = p.parent.name
        return f"{skill_dir.title()} Skill"
    name = p.stem
    return name.replace("-", " ").replace("_", " ").title()

# Scan directories for documentation files
scan_patterns = [
    "docs/*.html",
    "docs/*.md",
    "tools/*.html",
    "tools/*.py",
    "tools/*.sh",
    "templates/*.html",
    "skills/*/SKILL.md",
]

found_files = set()
for pattern in scan_patterns:
    for filepath in glob.glob(os.path.join(repo_root, pattern)):
        relpath = os.path.relpath(filepath, repo_root)
        found_files.add(relpath)

# Build new docs list
new_docs = []
for relpath in sorted(found_files):
    if relpath in old_docs:
        entry = dict(old_docs[relpath])
        entry["status"] = "current"
        if entry.get("generated") and not entry.get("description"):
            entry["title"] = infer_title(relpath)
            entry["category"] = infer_category(relpath)
        new_docs.append(entry)
    elif relpath in old_archive:
        # Was archived but file is back — restore
        entry = dict(old_archive[relpath])
        entry.pop("superseded_by", None)
        entry["status"] = "current"
        entry["generated"] = True
        new_docs.append(entry)
    else:
        new_docs.append({
            "file": relpath,
            "title": infer_title(relpath),
            "category": infer_category(relpath),
            "description": "",
            "status": "new",
            "generated": True,
        })

# Check for files in old registry that no longer exist on disk
new_archive = list(existing.get("archive", []))
for relpath, entry in old_docs.items():
    if relpath not in found_files:
        archive_entry = {"file": relpath, "title": entry.get("title", ""), "category": entry.get("category", ""), "status": "missing"}
        if archive_entry not in new_archive:
            new_archive.append(archive_entry)

registry = {
    "version": new_version,
    "updated": today,
    "generated_by": "tools/build-docs-registry.sh",
    "categories": categories,
    "docs": new_docs,
    "archive": new_archive,
}

with open(docs_json_path, "w") as f:
    json.dump(registry, f, indent=2)
    f.write("\n")

print(f"docs.json v{new_version}: {len(new_docs)} docs, {len(new_archive)} archived")
PYSCRIPT
