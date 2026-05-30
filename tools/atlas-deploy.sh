#!/usr/bin/env bash
# atlas-deploy.sh — ship the static Atlas deck ALONGSIDE the product (P9).
#
# Folds the project's static deck (docs/) into the product's own deploy output
# under a reserved /_atlas path, so one deploy ships the app + its Atlas docs,
# and records the deployed URL in docs/env.json (atlas.url). The LIVE view
# (Observatory / Cost / ↻ Regenerate) stays local via observe-server and
# degrades gracefully on the static deploy.
#
#   atlas-deploy.sh --out <deploy_dir> --url <product_base_url> [--dev URL] [--prod URL]
#     --out   the product's build/deploy output dir (e.g. dist, build, public/.next out)
#     --url   the product's deployed base URL (so atlas.url = <url>/_atlas)
#
# Run from the project root (needs .forge/STATE.json). The static deck = docs/
# (pages fetch env.json/regen.json at runtime — works statically; live /api bits
# no-op gracefully off-server).
set -uo pipefail

[ -f ".forge/STATE.json" ] || { echo "atlas-deploy: not a FORGE build (no .forge/STATE.json)" >&2; exit 2; }
OUT=""; URL=""; DEV=""; PROD=""
while [ $# -gt 0 ]; do
  case "$1" in
    --out)  shift; OUT="${1:-}" ;;
    --url)  shift; URL="${1:-}" ;;
    --dev)  shift; DEV="${1:-}" ;;
    --prod) shift; PROD="${1:-}" ;;
    *) echo "atlas-deploy: unknown arg $1" >&2; exit 2 ;;
  esac; shift
done
[ -n "$OUT" ] || { echo "atlas-deploy: --out <deploy_dir> required" >&2; exit 2; }
[ -d "docs" ] || { echo "atlas-deploy: no docs/ to deploy (run atlas-init first)" >&2; exit 2; }

DEST="$OUT/_atlas"
mkdir -p "$DEST"
# copy the static deck (html + env.json + regen.json + env-links.js + home.html + docs.json)
cp -R docs/. "$DEST/" 2>/dev/null
echo "atlas-deploy: copied static deck → $DEST"

# record the deployed Atlas URL (and any dev/prod the deploy produced) in docs/env.json
URL="$URL" DEV="$DEV" PROD="$PROD" python3 <<'PY'
import os, json
p = "docs/env.json"
try: d = json.load(open(p))
except Exception: d = {}
url, dev, prod = os.environ.get("URL",""), os.environ.get("DEV",""), os.environ.get("PROD","")
if url:  d.setdefault("atlas", {})["url"] = url.rstrip("/") + "/_atlas"
if dev:  d.setdefault("dev", {})["url"] = dev
if prod: d.setdefault("prod", {})["url"] = prod
json.dump(d, open(p, "w"), indent=2)
print("atlas-deploy: env.json →",
      "atlas=" + (d.get("atlas",{}).get("url") or "(unset)"),
      "| dev=" + (d.get("dev",{}).get("url") or "(unset)"),
      "| prod=" + (d.get("prod",{}).get("url") or "(unset)"))
PY

echo "atlas-deploy: done. Commit docs/env.json. Live view (Observatory/Cost/regen) remains local: observe-server."
