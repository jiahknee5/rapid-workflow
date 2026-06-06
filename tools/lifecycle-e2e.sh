#!/usr/bin/env bash
# lifecycle-e2e.sh — END-TO-END acceptance test of the skill: create a new project,
# populate its docs, build the local app, and deploy dev — asserting each outcome.
#
# This is the runnable "create a new project and prove it works" test. It drives the
# REAL tooling (new-project.sh → atlas-init → real generators → real build → atlas-deploy)
# against a real (small) app, so a green result means the pipeline actually produced the
# three deliverables — not a remembered claim. Bounded: a local/staging deploy, no cloud,
# no paid services. (The full multi-agent /rapid-workflow build with human gates is the separate
# opt-in "live" tier; this exercises the deterministic plumbing the skill guarantees.)
#
#   lifecycle-e2e.sh --stage <create|build|docs|deploy|verify|all> --name <name> \
#                    [--dir <parent>] [--deploy-out <dir>]
#
# Each stage exits non-zero on a failed assertion (so a workflow node fails honestly).
# `verify` writes <kit>/.rapid/E2E.json summarizing the three outcomes.
set -uo pipefail

KIT="$(cd "$(dirname "$0")/.." && pwd)"
STAGE="all"; NAME=""; PARENT="$HOME/projects"; DEPLOY_OUT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --stage) shift; STAGE="${1:-all}" ;;
    --name)  shift; NAME="${1:-}" ;;
    --dir)   shift; PARENT="${1:-}" ;;
    --deploy-out) shift; DEPLOY_OUT="${1:-}" ;;
    *) echo "lifecycle-e2e: unknown arg $1" >&2; exit 2 ;;
  esac; shift
done
[ -n "$NAME" ] || { echo "lifecycle-e2e: --name <name> required" >&2; exit 2; }
PROJ="$PARENT/$NAME"
DEPLOY_OUT="${DEPLOY_OUT:-/tmp/$NAME-dev}"
LOCAL_URL="http://localhost:4173"

ok(){ echo "  [PASS] $1"; }
die(){ echo "  [FAIL] $1" >&2; exit 1; }

# ---------------------------------------------------------------- create
stage_create(){
  echo "STAGE create — scaffold the project via the skill"
  bash "$KIT/tools/new-project.sh" --name "$NAME" --dir "$PARENT" --force \
    --idea "A tiny unit-converter web app (length + temperature) that builds to static files." \
    >/dev/null || die "new-project.sh failed"
  [ -f "$PROJ/CONSTITUTION.md" ] || die "CONSTITUTION.md missing"
  [ -f "$PROJ/BUILD-AUTONOMY.md" ] || die "BUILD-AUTONOMY.md missing"
  [ -f "$PROJ/.rapid/STATE.json" ] || die ".rapid/STATE.json missing"
  [ -d "$PROJ/docs" ] || die "docs/ missing"
  ok "project scaffolded at $PROJ (structure + CONSTITUTION + BUILD-AUTONOMY + Atlas deck)"
}

# ---------------------------------------------------------------- build
stage_build(){
  echo "STAGE build — seed the real app + build it locally"
  mkdir -p "$PROJ/src"
  # a real (tiny) static app: unit converter
  cat > "$PROJ/src/index.html" <<'HTML'
<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Unit Converter</title><link rel="stylesheet" href="style.css"></head>
<body><main><h1>Unit Converter</h1>
<section><label>Meters <input id="m" type="number" value="1"></label>
<output id="ft"></output> ft</section>
<section><label>Celsius <input id="c" type="number" value="100"></label>
<output id="f"></output> °F</section>
<script src="app.js"></script></main></body></html>
HTML
  cat > "$PROJ/src/style.css" <<'CSS'
body{font-family:-apple-system,sans-serif;max-width:32rem;margin:3rem auto;padding:0 1rem}
section{margin:1rem 0}output{font-weight:700}
CSS
  cat > "$PROJ/src/app.js" <<'JS'
const $=id=>document.getElementById(id);
function sync(){ $('ft').textContent=(+$('m').value*3.28084).toFixed(2);
  $('f').textContent=(+$('c').value*9/5+32).toFixed(1); }
['m','c'].forEach(id=>$(id).addEventListener('input',sync)); sync();
JS
  # a real build: produce dist/ with a stamped build (no external deps)
  cat > "$PROJ/Makefile" <<'MK'
build:
	@rm -rf dist && mkdir -p dist
	@cp src/index.html src/style.css src/app.js dist/
	@printf '/* built %s */\n' "$$(date -u +%FT%TZ)" >> dist/app.js
	@echo "built dist/ ($$(ls dist | wc -l | tr -d ' ') files)"
test:
	@node --check src/app.js && echo "app.js syntax OK"
MK
  ( cd "$PROJ" && make build ) >/dev/null 2>&1 || die "make build failed"
  [ -f "$PROJ/dist/index.html" ] && [ -f "$PROJ/dist/app.js" ] || die "dist/ output missing after build"
  ( cd "$PROJ" && make test ) >/dev/null 2>&1 || die "make test (app.js syntax) failed"
  # seed an eval test so the eval doc has real content to surface
  mkdir -p "$PROJ/.rapid/EVAL"
  cat > "$PROJ/.rapid/EVAL/build.smoke.test.sh" <<'EVAL'
#!/usr/bin/env bash
# smoke: the app builds to dist/ and app.js is valid JS
set -uo pipefail
cd "$(dirname "$0")/../.."
make build >/dev/null 2>&1 || { echo "build smoke: FAIL (build)"; exit 1; }
node --check src/app.js  || { echo "build smoke: FAIL (syntax)"; exit 1; }
[ -f dist/index.html ]   || { echo "build smoke: FAIL (no dist)"; exit 1; }
echo "build smoke: PASS"
EVAL
  chmod +x "$PROJ/.rapid/EVAL/build.smoke.test.sh"
  ok "local app built → dist/ ($(ls "$PROJ/dist" | wc -l | tr -d ' ') files), app.js valid, eval seeded"
}

# ---------------------------------------------------------------- docs
stage_docs(){
  echo "STAGE docs — write real artifacts + populate the deck (no stub pages)"
  # real spec + architecture + workflow artifacts (the project's own content)
  cat > "$PROJ/04-spec/spec.md" <<'MD'
# Unit Converter — Spec
## S-01 — Length conversion
Meters → feet, factor 3.28084, rendered to 2 decimals on input.
## S-02 — Temperature conversion
Celsius → Fahrenheit (×9/5 + 32), rendered to 1 decimal on input.
## S-03 — Static build
`make build` copies src→dist and stamps the build; no runtime dependencies.
MD
  cat > "$PROJ/04-spec/architecture.md" <<'MD'
# Unit Converter — Architecture
## C-01 — Static front-end
`src/index.html` + `app.js` + `style.css`; vanilla JS, two `<output>` bindings.
## C-02 — Build
`Makefile` build target → `dist/`. Deployed alongside Atlas under `/_atlas`.
MD
  cat > "$PROJ/04-spec/workflow.md" <<'MD'
# Unit Converter — Workflow
- in: a number in meters / celsius
- proc: multiply by the conversion factor on the `input` event
- out: the converted value rendered in the matching `<output>`
MD
  # Enhanced PRD — a DISTINCT, categorized requirements view (not a copy of the PRD)
  cat > "$PROJ/01-intake/PRD-ENHANCED.md" <<'MD'
# Unit Converter — Enhanced PRD
## BR-1 — Instant conversion (MUST)
A learner converts length/temperature and sees the result immediately, no submit step. *(why: friction kills casual use)*
## FR-1 — Length: meters → feet (MUST)
On input, render meters × 3.28084 to 2 decimals. Acceptance: typing 1 shows 3.28.
## FR-2 — Temperature: celsius → fahrenheit (MUST)
On input, render °C × 9/5 + 32 to 1 decimal. Acceptance: typing 100 shows 212.0.
## TR-1 — Zero-dependency static build (SHOULD)
`make build` emits `dist/` with no runtime deps; deployable as static files. Acceptance: `dist/index.html` + `dist/app.js` present.
## Traceability
FR-1 ↓ S-01, FR-2 ↓ S-02, TR-1 ↓ S-03.
MD
  # Users — DISTINCT user personas + journeys (not a copy of the workflow)
  cat > "$PROJ/04-spec/users.md" <<'MD'
# Unit Converter — Users
## Persona: the quick converter
Someone mid-task who needs one number converted now. Journey: open → type a value → read the result → leave. Success: under 3 seconds, no instructions needed.
## Persona: the learner
A student checking homework. Journey: tries several values, compares °C/°F to build intuition. Success: results update live as they type.
## Golden journey
Type 100 in Celsius → see 212.0 °F immediately. This is the acceptance journey the eval asserts.
MD
  # deterministic generators that populate data-driven pages
  ( cd "$PROJ" && bash tools/ship-gate.sh >/dev/null 2>&1 ) || true       # → docs/eval.json
  ( cd "$PROJ" && bash tools/build-docs-registry.sh >/dev/null 2>&1 ) || true  # → docs.json
  ( cd "$PROJ" && bash tools/cost-summary.sh --html >/dev/null 2>&1 ) || true  # → docs/cost.html

  # populate the prose deck pages from the project's markdown (deterministic markdown→section)
  PROJECT="$PROJ" python3 "$KIT/tools/populate-deck.py" || die "deck population failed"

  # assert every core page is populated (no stub) and free of dead #pending anchors
  miss=""
  for pg in prd prd-enhanced spec architecture workflow users eval documentation observatory; do
    f="$PROJ/docs/$pg.html"
    [ -f "$f" ] || { miss="$miss $pg(missing)"; continue; }
    grep -q 'atlas-stub' "$f" && miss="$miss $pg(stub)"
    grep -q 'href="#pending"' "$f" && miss="$miss $pg(deadlink)"
  done
  [ -z "$miss" ] || die "docs not properly built:$miss"
  # distinctness: enhanced PRD must differ from PRD; users must differ from workflow
  titles(){ grep -oE '<div class="section-title">[^<]*</div>' "$1" | sort; }
  [ "$(titles "$PROJ/docs/prd.html")" != "$(titles "$PROJ/docs/prd-enhanced.html")" ] || die "prd-enhanced duplicates prd"
  [ "$(titles "$PROJ/docs/workflow.html")" != "$(titles "$PROJ/docs/users.html")" ] || die "users duplicates workflow"
  # branding: pages carry the PROJECT name, not the kit's
  grep -q "<title>.* — $NAME</title>" "$PROJ/docs/prd.html" || die "deck not branded as $NAME (still kit-branded)"
  ok "documentation populated + distinct (9 pages: no stub, no dead links, prd≠prd-enhanced, workflow≠users, branded $NAME)"
}

# ---------------------------------------------------------------- deploy
stage_deploy(){
  echo "STAGE deploy — local/staging dev deploy (app + /_atlas)"
  ( cd "$PROJ" && make build ) >/dev/null 2>&1 || die "build before deploy failed"
  rm -rf "$DEPLOY_OUT"; mkdir -p "$DEPLOY_OUT"
  cp -R "$PROJ/dist/." "$DEPLOY_OUT/" 2>/dev/null || die "copy app dist → deploy out failed"
  ( cd "$PROJ" && bash tools/atlas-deploy.sh --out "$DEPLOY_OUT" --url "$LOCAL_URL" --dev "$LOCAL_URL" ) \
    >/dev/null 2>&1 || die "atlas-deploy failed"
  [ -f "$DEPLOY_OUT/index.html" ] || die "deployed app (index.html) missing in $DEPLOY_OUT"
  [ -d "$DEPLOY_OUT/_atlas" ] || die "deployed /_atlas docs missing in $DEPLOY_OUT"
  dev=$(python3 -c "import json;print((json.load(open('$PROJ/docs/env.json')).get('dev') or {}).get('url',''))")
  [ -n "$dev" ] || die "env.json dev.url not set after deploy"
  ok "dev deployed → $DEPLOY_OUT (app + /_atlas), env.json dev.url=$dev"
}

# ---------------------------------------------------------------- verify
stage_verify(){
  echo "STAGE verify — assert the three deliverables + write E2E.json"
  local docs_ok=1 build_ok=1 deploy_ok=1
  for pg in prd prd-enhanced spec architecture workflow users eval documentation observatory; do
    { [ -f "$PROJ/docs/$pg.html" ] && ! grep -q 'atlas-stub' "$PROJ/docs/$pg.html" \
      && ! grep -q 'href="#pending"' "$PROJ/docs/$pg.html"; } || docs_ok=0
  done
  tt(){ grep -oE '<div class="section-title">[^<]*</div>' "$1" | sort; }
  [ "$(tt "$PROJ/docs/prd.html")" != "$(tt "$PROJ/docs/prd-enhanced.html")" ] || docs_ok=0
  [ "$(tt "$PROJ/docs/workflow.html")" != "$(tt "$PROJ/docs/users.html")" ] || docs_ok=0
  { [ -f "$PROJ/dist/index.html" ] && [ -f "$PROJ/dist/app.js" ]; } || build_ok=0
  dev=$(python3 -c "import json;print((json.load(open('$PROJ/docs/env.json')).get('dev') or {}).get('url',''))" 2>/dev/null)
  { [ -d "$DEPLOY_OUT/_atlas" ] && [ -f "$DEPLOY_OUT/index.html" ] && [ -n "$dev" ]; } || deploy_ok=0
  npages=$(ls "$PROJ"/docs/*.html 2>/dev/null | wc -l | tr -d ' ')
  nstub=$(grep -l 'atlas-stub' "$PROJ"/docs/*.html 2>/dev/null | wc -l | tr -d ' ')
  gen="$(date -u +%FT%TZ)"
  mkdir -p "$KIT/.rapid"
  cat > "$KIT/.rapid/E2E.json" <<JSON
{ "generated": "$gen", "project": "$NAME", "project_dir": "$PROJ", "deploy_out": "$DEPLOY_OUT",
  "summary": { "pass": $((docs_ok+build_ok+deploy_ok)), "fail": $((3-docs_ok-build_ok-deploy_ok)), "total": 3 },
  "assertions": [
    { "name": "documentation_populated", "pass": $([ $docs_ok -eq 1 ] && echo true || echo false), "detail": "$((npages-nstub))/$npages deck pages populated (no atlas-stub)" },
    { "name": "local_app_built", "pass": $([ $build_ok -eq 1 ] && echo true || echo false), "detail": "dist/index.html + dist/app.js present" },
    { "name": "dev_deployed", "pass": $([ $deploy_ok -eq 1 ] && echo true || echo false), "detail": "app + /_atlas in $DEPLOY_OUT, env.json dev.url=$dev" }
  ] }
JSON
  echo "  wrote $KIT/.rapid/E2E.json"
  [ $docs_ok -eq 1 ]   && ok "documentation populated" || die "documentation NOT populated"
  [ $build_ok -eq 1 ]  && ok "local app built"        || die "local app NOT built"
  [ $deploy_ok -eq 1 ] && ok "dev deployed"           || die "dev NOT deployed"
  echo "LIFECYCLE E2E GREEN: $NAME created, documented, built, and dev-deployed."
}

case "$STAGE" in
  create) stage_create ;;
  build)  stage_build ;;
  docs)   stage_docs ;;
  deploy) stage_deploy ;;
  verify) stage_verify ;;
  all)    stage_create; stage_build; stage_docs; stage_deploy; stage_verify ;;
  *) echo "lifecycle-e2e: unknown stage $STAGE" >&2; exit 2 ;;
esac
