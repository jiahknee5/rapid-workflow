#!/usr/bin/env bash
# atlas-init.sh — scaffold a project's own ATLAS (the developer-view harness).
#
# Run once at P1 (Structure) from the target project root. Stamps the shared kit
# into docs/ and generates the per-project config, so the project gets its OWN
# Atlas — live and prepopulated from the start; deck pages fill in as phases
# complete. Idempotent: never overwrites a page that already has real content.
#
#   atlas-init.sh                 scaffold Atlas into the current project
#   atlas-init.sh /path/to/proj   target a specific project root
#
# Generates (into the project):
#   docs/env-links.js, docs/home.html          (copied from the kit)
#   docs/env.json, docs/regen.json             (per-project config, placeholders)
#   docs/<page>.html  x10                       (deck shell: nav + sidebar + stub)
#   .vscode/tasks.json                          (Atlas serve + forge-team)
# The live view is served by tools/observe-server.py from the project root.
set -uo pipefail

PROJECT="${1:-$PWD}"
PROJECT="$(cd "$PROJECT" 2>/dev/null && pwd)" || { echo "atlas-init: bad project path" >&2; exit 2; }
KIT="$(cd "$(dirname "$0")/.." && pwd)"           # rapid-workflow root (the kit)
TPL="$KIT/templates/template-docs-page.html"
[ -f "$TPL" ] || { echo "atlas-init: kit template not found ($TPL)" >&2; exit 2; }

mkdir -p "$PROJECT/docs" "$PROJECT/.vscode"

# Copy the runtime kit files (don't clobber project edits).
for f in env-links.js home.html; do
  [ -f "$KIT/docs/$f" ] && [ ! -f "$PROJECT/docs/$f" ] && cp "$KIT/docs/$f" "$PROJECT/docs/$f"
done

KIT="$KIT" PROJECT="$PROJECT" TPL="$TPL" python3 <<'PY'
import os, json, re

kit, project, tpl = os.environ["KIT"], os.environ["PROJECT"], os.environ["TPL"]
docs = os.path.join(project, "docs")

# Pull the canonical <style> block from the kit page template.
tpl_html = open(tpl).read()
m = re.search(r"<style>.*?</style>", tpl_html, re.S)
STYLE = m.group(0) if m else "<style></style>"

NAV = [("prd.html","PRD"),("prd-enhanced.html","Enhanced PRD"),("architecture.html","Architecture"),
       ("workflow.html","Workflow"),("users.html","Users"),("spec.html","Spec"),
       ("observatory.html","Observatory"),("eval.html","Eval"),("cost.html","Cost"),
       ("documentation.html","Documentation")]

def nav_html(active):
    out = ['<nav class="forge-nav"><span class="forge-nav-brand">RAPID <span style="font-weight:400;opacity:0.5;font-size:10px;">/ AI Build Workflow</span><span class="forge-nav-sub">Rapid Autonomous Pipeline for Iterative Development</span></span>']
    for href, label in NAV:
        cls = ' class="active"' if href == active else ''
        out.append(f'<a href="{href}"{cls}>{label}</a>')
    out.append('</nav>')
    return ''.join(out)

# page -> (title, eyebrow, "generated when ... completes")
PAGES = {
  "prd.html":("PRD","P1 · Intake","the PRD is locked (Gate 1)"),
  "prd-enhanced.html":("Enhanced PRD","P1b · Decompose","requirements are decomposed into the BR/FR/TR pyramid"),
  "architecture.html":("Architecture","P4 · Spec","the architecture is derived"),
  "workflow.html":("Workflow","P4 · Spec","the workflow map is derived"),
  "users.html":("Users","P5 · Decompose","users + golden-test workflows are mapped"),
  "spec.html":("Spec","P4 · Spec","the spec is derived (Gate 2)"),
  "observatory.html":("Observatory","Live","the build starts — it streams live"),
  "eval.html":("Eval","P5–P6","the eval harness runs"),
  "cost.html":("Cost","Live","each phase — token/cost burn updates"),
  "documentation.html":("Documentation","P9 · Document","the product is documented"),
}

def is_stub_or_absent(path):
    if not os.path.exists(path): return True
    s = open(path).read()
    return ("dynamically generated" in s) or ("atlas-stub" in s) or len(s) < 1500

made = []
for href,(title, eyebrow, when) in PAGES.items():
    path = os.path.join(docs, href)
    if not is_stub_or_absent(path):
        continue  # real content already there — never clobber
    active = href
    body = (f'<!doctype html><html lang="en"><head><meta charset="utf-8"/>'
            f'<meta name="viewport" content="width=device-width, initial-scale=1"/>'
            f'<title>{title} — RAPID</title>{STYLE}</head><body>'
            f'{nav_html(active)}'
            f'<div class="spec-layout"><nav class="sidebar"><div class="sidebar-brand">RAPID</div>'
            f'<div class="sidebar-sub">{title}</div><div class="sidebar-section">Status</div>'
            f'<a href="#pending">Pending</a></nav>'
            f'<div class="docpage-content"><div class="main">'
            f'<!-- atlas-stub -->'
            f'<div class="section" id="pending"><div class="section-id">{eyebrow}</div>'
            f'<div class="section-title">{title}</div>'
            f'<div class="section-desc">Generated when {when}. Atlas is live and prepopulated from the '
            f'start; each page fills in as its phase completes — use the ↻ Regenerate button or rerun the build.</div>'
            f'<div class="key-insight">This is a scaffold stub created by <code>atlas-init</code>. '
            f'The nav, sidebar, and Product/Source links are already wired.</div></div>'
            f'</div></div></div>'
            f'<script src="env-links.js" defer></script></body></html>')
    open(path,"w").write(body)
    made.append(href)

# env.json — per-project link config (placeholders; filled from forge.yaml at deploy)
env_path = os.path.join(docs, "env.json")
if not os.path.exists(env_path):
    json.dump({
      "_note":"Atlas per-project links. Fill product/source/atlas from forge.yaml deploy targets (atlas-init/atlas-deploy).",
      "local":{"url":"http://localhost:3000","launch":"<your dev server, e.g. npm run dev>"},
      "dev":{"url":""},"prod":{"url":""},
      "source":{"github":"","gitlab":""},
      "atlas":{"url":""}
    }, open(env_path,"w"), indent=2)

# regen.json — per-page generators (cost is deterministic; rest manual/agent until wired)
regen_path = os.path.join(docs, "regen.json")
if not os.path.exists(regen_path):
    json.dump({
      "_note":"Per-page regenerate commands (POST /api/regen). cost is instant; wire others to the project's generators or claude -p.",
      "cost.html":{"kind":"instant","cmd":"bash tools/cost-summary.sh --html"},
      "observatory.html":{"kind":"live","note":"live dashboard — no regen"}
    }, open(regen_path,"w"), indent=2)

# .vscode/tasks.json — serve Atlas (observe-server) + launch the forge-team
vs = os.path.join(project, ".vscode", "tasks.json")
if not os.path.exists(vs):
    json.dump({"version":"2.0.0","tasks":[
      {"label":"Atlas: serve","type":"shell",
       "command":f"python3 {kit}/tools/observe-server.py --port 4040",
       "presentation":{"panel":"dedicated","reveal":"always"},"problemMatcher":[],"isBackground":True},
      {"label":"FORGE: launch team","type":"shell",
       "command":f"bash {kit}/tools/forge-team.sh","problemMatcher":[]}
    ]}, open(vs,"w"), indent=2)

print(f"atlas-init: scaffolded {len(made)} deck stub(s): {', '.join(made) or '(all pages already had content)'}")
print(f"  config: docs/env.json, docs/regen.json | kit: env-links.js, home.html | .vscode/tasks.json")
PY

echo "atlas-init: done. Serve Atlas: python3 $KIT/tools/observe-server.py --port 4040  (open http://localhost:4040/home.html)"
