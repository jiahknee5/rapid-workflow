#!/usr/bin/env bash
# mock-init.sh — scaffold a project's PLAN-PHASE design mocks (E: design-in-plan).
#
# Runs at P4 (Spec Derivation), BEFORE architecture, for any project with a
# user-facing surface. It lays down a real design-token system + a hi-fi screen
# template so the design subagent can produce high-fidelity visual comps of every
# screen, plus `04-spec/screens.md` — the screen inventory (states + the data each
# screen needs + actions->endpoints). The screens are what the DOM/API/data seam
# contracts are then DERIVED from, so architecture is built to serve real screens
# instead of guessed ones. The same comps become the visual target P7 QA compares
# the built UI against.
#
#   mock-init.sh                 scaffold into ./04-spec/mocks (cwd = project root)
#   mock-init.sh /path/to/proj   target a specific project root
#
# Idempotent: never clobbers an existing screen mock or a populated screens.md.
# One token source (04-spec/mocks/_tokens.css) keeps every hi-fi comp in sync — no
# drift, and re-skinnable from a reference screenshot via tools/design-extract-prompt.md.
set -uo pipefail

PROJECT="${1:-$PWD}"
PROJECT="$(cd "$PROJECT" 2>/dev/null && pwd)" || { echo "mock-init: bad project path" >&2; exit 2; }
MOCKS="$PROJECT/04-spec/mocks"
mkdir -p "$MOCKS"

PROJECT="$PROJECT" MOCKS="$MOCKS" python3 <<'PY'
import os

mocks = os.environ["MOCKS"]
proj  = os.path.basename(os.environ["PROJECT"].rstrip("/")) or "app"

def write(name, content, clobber=False):
    p = os.path.join(mocks, name)
    if os.path.exists(p) and not clobber:
        print(f"  keep   04-spec/mocks/{name} (exists)")
        return
    with open(p, "w") as f:
        f.write(content)
    print(f"  wrote  04-spec/mocks/{name}")

# --- _tokens.css : the design system (the single source every comp builds from) ---
TOKENS = """/* Design tokens — the single source of truth for every hi-fi mock in this folder.
   Re-skin from a reference screenshot via tools/design-extract-prompt.md, or hand-tune.
   Every screen mock links ONLY this file, so the whole comp set stays in sync. */
:root{
  /* color — light (default) */
  --bg:#FBFCFE; --surface:#FFFFFF; --surface-2:#F6F8FA; --surface-3:#EEF1F5;
  --border:#E3E8EE; --border-strong:#CBD5E1;
  --text:#0F172A; --text-muted:#475569; --text-dim:#94A3B8;
  --primary:#2563EB; --primary-fg:#FFFFFF; --primary-soft:#EFF4FF;
  --accent:#7C3AED; --success:#16A34A; --warn:#D97706; --danger:#DC2626;
  --ring:rgba(37,99,235,.35);
  /* type */
  --font:-apple-system,BlinkMacSystemFont,"Segoe UI",Inter,Roboto,Helvetica,Arial,sans-serif;
  --mono:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;
  /* radius / shadow / space */
  --r-sm:6px; --r:10px; --r-lg:16px; --r-pill:999px;
  --sh-1:0 1px 2px rgba(15,23,42,.06),0 1px 3px rgba(15,23,42,.10);
  --sh-2:0 4px 12px rgba(15,23,42,.08),0 2px 4px rgba(15,23,42,.06);
  --sh-3:0 12px 32px rgba(15,23,42,.14);
  --s1:4px; --s2:8px; --s3:12px; --s4:16px; --s5:24px; --s6:32px; --s7:48px;
}
:root[data-theme="dark"]{
  --bg:#0B1220; --surface:#111A2B; --surface-2:#0E1626; --surface-3:#162236;
  --border:#1F2C44; --border-strong:#2B3B57;
  --text:#E6EDF6; --text-muted:#9FB0C7; --text-dim:#5F7596;
  --primary:#5B8DEF; --primary-fg:#0B1220; --primary-soft:#16233B;
  --accent:#A78BFA; --ring:rgba(91,141,239,.4);
  --sh-1:0 1px 2px rgba(0,0,0,.4); --sh-2:0 6px 18px rgba(0,0,0,.45); --sh-3:0 14px 40px rgba(0,0,0,.55);
}
*,*::before,*::after{box-sizing:border-box}
html,body{margin:0}
body{background:var(--bg);color:var(--text);font-family:var(--font);font-size:15px;line-height:1.55;-webkit-font-smoothing:antialiased}
h1,h2,h3{margin:0 0 var(--s3);line-height:1.2;font-weight:700;letter-spacing:-.01em}
h1{font-size:1.6rem} h2{font-size:1.2rem} h3{font-size:1rem}
p{margin:0 0 var(--s3);color:var(--text-muted)}
a{color:var(--primary);text-decoration:none}

/* layout primitives */
.app{display:grid;grid-template-columns:248px 1fr;min-height:100vh}
.topbar{display:flex;align-items:center;gap:var(--s4);height:56px;padding:0 var(--s5);
  background:var(--surface);border-bottom:1px solid var(--border);position:sticky;top:0;z-index:5}
.brand{font-weight:800;letter-spacing:-.02em}
.sidebar{background:var(--surface-2);border-right:1px solid var(--border);padding:var(--s5) var(--s3)}
.sidebar a{display:block;padding:8px 12px;border-radius:var(--r-sm);color:var(--text-muted);font-size:.9rem;font-weight:500}
.sidebar a.active{background:var(--primary-soft);color:var(--primary)}
.main{padding:var(--s6) var(--s7);max-width:1100px}
.row{display:flex;gap:var(--s4);flex-wrap:wrap}
.grid{display:grid;gap:var(--s4)}

/* components */
.btn{display:inline-flex;align-items:center;gap:8px;height:38px;padding:0 16px;border-radius:var(--r-sm);
  border:1px solid var(--primary);background:var(--primary);color:var(--primary-fg);font:inherit;font-weight:600;
  font-size:.9rem;cursor:pointer;box-shadow:var(--sh-1)}
.btn.ghost{background:transparent;color:var(--text);border-color:var(--border-strong);box-shadow:none}
.btn.subtle{background:var(--surface-3);color:var(--text);border-color:transparent;box-shadow:none}
.card{background:var(--surface);border:1px solid var(--border);border-radius:var(--r);padding:var(--s5);box-shadow:var(--sh-1)}
.card.flush{padding:0;overflow:hidden}
.stat .big{font-size:1.9rem;font-weight:800;letter-spacing:-.02em}
.stat .lbl{color:var(--text-dim);font-size:.72rem;text-transform:uppercase;letter-spacing:.06em}
.field{display:block;margin-bottom:var(--s4)}
.field > span{display:block;font-size:.78rem;font-weight:600;color:var(--text-muted);margin-bottom:6px}
.input,select.input,textarea.input{width:100%;height:38px;padding:0 12px;border:1px solid var(--border-strong);
  border-radius:var(--r-sm);background:var(--surface);color:var(--text);font:inherit;font-size:.92rem;outline:none}
.input:focus{border-color:var(--primary);box-shadow:0 0 0 3px var(--ring)}
textarea.input{height:auto;padding:10px 12px;min-height:90px;resize:vertical}
.badge{display:inline-flex;align-items:center;height:22px;padding:0 10px;border-radius:var(--r-pill);
  font-size:.72rem;font-weight:600;background:var(--surface-3);color:var(--text-muted)}
.badge.ok{background:color-mix(in srgb,var(--success) 16%,transparent);color:var(--success)}
.badge.warn{background:color-mix(in srgb,var(--warn) 18%,transparent);color:var(--warn)}
.badge.err{background:color-mix(in srgb,var(--danger) 16%,transparent);color:var(--danger)}
table.tbl{width:100%;border-collapse:collapse;font-size:.9rem}
table.tbl th{text-align:left;font-size:.72rem;text-transform:uppercase;letter-spacing:.05em;color:var(--text-dim);
  padding:10px 14px;border-bottom:1px solid var(--border)}
table.tbl td{padding:12px 14px;border-bottom:1px solid var(--border)}
.empty{display:grid;place-items:center;gap:var(--s3);padding:var(--s7);text-align:center;color:var(--text-dim)}
.skeleton{background:linear-gradient(90deg,var(--surface-2),var(--surface-3),var(--surface-2));
  border-radius:var(--r-sm);height:14px;animation:sk 1.2s infinite}
@keyframes sk{0%{opacity:.6}50%{opacity:1}100%{opacity:.6}}

/* a small banner the screen template uses to label which state it depicts */
.state-tag{position:fixed;right:12px;bottom:12px;z-index:50;font:600 11px var(--mono);
  background:var(--text);color:var(--bg);padding:4px 10px;border-radius:var(--r-pill);opacity:.85}
"""
write("_tokens.css", TOKENS)

# --- screen.template.html : a hi-fi starting screen the design agent copies per screen ---
SCREEN = """<!doctype html>
<!-- SCREEN MOCK — copy this per screen as <screen-id>.html and build the real hi-fi comp.
     Keep the metadata block below in sync with the matching entry in 04-spec/screens.md.
     screen: <screen-id>
     route: /<path>
     states: loading | empty | populated | error          (depict the one named in data-state)
     needs:  <entities/fields this screen reads>
     actions: <button/flow> -> <METHOD /endpoint>          (these derive the API contract)
-->
<html lang="en" data-theme="light">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>__PROJ__ — <Screen></title>
<link rel="stylesheet" href="_tokens.css"/>
</head>
<body data-state="populated">
<div class="app">
  <aside class="sidebar">
    <div class="brand" style="padding:6px 12px 18px">__PROJ__</div>
    <a class="active" href="#">Overview</a>
    <a href="#">Section two</a>
    <a href="#">Section three</a>
    <a href="#">Settings</a>
  </aside>
  <div>
    <header class="topbar">
      <strong>Screen title</strong>
      <span style="flex:1"></span>
      <button class="btn ghost">Secondary</button>
      <button class="btn">Primary action</button>
    </header>
    <main class="main">
      <h1>Screen title</h1>
      <p>One line on what the user does here. Replace everything below with the real
         hi-fi composition for this screen, using only the components in _tokens.css.</p>

      <div class="row" style="margin:var(--s5) 0">
        <div class="card stat" style="flex:1"><div class="big">128</div><div class="lbl">Metric A</div></div>
        <div class="card stat" style="flex:1"><div class="big">$4.2k</div><div class="lbl">Metric B</div></div>
        <div class="card stat" style="flex:1"><div class="big">99.9%</div><div class="lbl">Metric C</div></div>
      </div>

      <div class="card flush">
        <table class="tbl">
          <thead><tr><th>Name</th><th>Status</th><th>Updated</th><th></th></tr></thead>
          <tbody>
            <tr><td>Example row</td><td><span class="badge ok">active</span></td><td>2m ago</td>
                <td style="text-align:right"><button class="btn subtle">Open</button></td></tr>
            <tr><td>Another row</td><td><span class="badge warn">pending</span></td><td>1h ago</td>
                <td style="text-align:right"><button class="btn subtle">Open</button></td></tr>
          </tbody>
        </table>
      </div>
    </main>
  </div>
</div>
<div class="state-tag">state: populated</div>
</body>
</html>
"""
write("screen.template.html", SCREEN.replace("__PROJ__", proj))

# --- index.html : the gallery GATE 2 presents and P7 compares against ---
INDEX = """<!doctype html><html lang="en" data-theme="light"><head>
<meta charset="utf-8"/><meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>__PROJ__ — design mocks</title><link rel="stylesheet" href="_tokens.css"/>
<style>.gal{display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:var(--s4)}
.gal a{display:block} .gal .card{padding:0;overflow:hidden}
.gal iframe{width:100%;height:200px;border:0;background:var(--surface-2);pointer-events:none}
.gal .cap{padding:12px 14px;font-weight:600;border-top:1px solid var(--border)}</style></head>
<body><main class="main" style="max-width:1180px">
<h1>__PROJ__ — design mocks</h1>
<p>Hi-fi comps of every screen, built from <code>_tokens.css</code>. These are approved at GATE 2
and are the visual target P7 QA compares the built UI against. Inventory: <a href="../screens.md">screens.md</a>.
Add one tile per screen below as you create <code>&lt;screen-id&gt;.html</code>.</p>
<div class="gal">
  <!-- one tile per screen — example:
  <a href="dashboard.html"><div class="card"><iframe src="dashboard.html"></iframe>
     <div class="cap">Dashboard</div></div></a> -->
</div>
</main></body></html>
"""
write("index.html", INDEX.replace("__PROJ__", proj))

print("mock-init: design-token kit ready in 04-spec/mocks/")
PY

# --- 04-spec/screens.md : the screen inventory (drives the seam contracts) ---
SCREENS="$PROJECT/04-spec/screens.md"
if [ -f "$SCREENS" ] && grep -q '^## ' "$SCREENS" 2>/dev/null; then
  echo "  keep   04-spec/screens.md (already has content)"
else
  cat > "$SCREENS" <<'MD'
# Screens — design-in-plan inventory

> The bridge from look to contract. For every screen the app has, list its states, the
> data it reads, and the actions it fires. The DOM / API / data-schema seam contracts in
> `04-spec/contracts/` are DERIVED from this table, so the backend is built to serve real
> screens. Each screen has a hi-fi comp in `04-spec/mocks/<screen-id>.html`. Approved at
> GATE 2; the comps are P7's visual target.

| Screen | Route | States | Reads (data) | Actions → endpoint | Mock |
|---|---|---|---|---|---|
| _example: Dashboard_ | `/` | loading · empty · populated · error | `user{name,avatar}`, `metrics[{label,value,delta}]` | refresh → `GET /api/metrics` | `mocks/dashboard.html` |

---

## <Screen name>

- **Route:** `/<path>`
- **States:** loading · empty · populated · error  *(build a comp, or at least note, each state)*
- **Reads:** `<entity{fields}>` — the exact fields this screen renders (these become the API response shape)
- **Writes / actions:**
  - `<button or flow>` → `<METHOD> /api/<endpoint>` with `<request shape>`
- **Derived contracts:**
  - DOM: `data-testid`s / roles this screen exposes (→ `04-spec/contracts/dom.md`)
  - API: endpoints + shapes above (→ `04-spec/contracts/api.md`)
  - Data: entities/fields (→ `04-spec/contracts/schema.md`)
- **Mock:** `04-spec/mocks/<screen-id>.html`
MD
  echo "  wrote  04-spec/screens.md"
fi

# --- README ---
README="$MOCKS/README.md"
if [ ! -f "$README" ]; then
  cat > "$README" <<'MD'
# Design mocks (plan-phase, E)

Hi-fi visual comps of every screen, produced at **P4 — before architecture**.

**Flow:** `screens.md` (inventory) → hi-fi comp per screen (`<screen-id>.html`, copied from
`screen.template.html`) → **derive** DOM/API/data seam contracts in `04-spec/contracts/` from
the screens → architecture is built to serve them. Approved at **GATE 2**; the comps are the
**visual target P7 QA** compares the built UI against.

- `_tokens.css` — the design system. Every comp links ONLY this, so they never drift. Re-skin
  from a reference screenshot with `tools/design-extract-prompt.md`.
- `screen.template.html` — copy per screen; keep its metadata header in sync with `screens.md`.
- `index.html` — gallery (one tile per screen) — what GATE 2 presents.

Build each comp with the components in `_tokens.css` (`.btn`, `.card`, `.input`, `.badge`,
`.tbl`, `.stat`, `.empty`, `.skeleton`). Depict each meaningful state (loading/empty/populated/
error) — that's what makes the data needs, and therefore the contracts, fall out cleanly.
MD
  echo "  wrote  04-spec/mocks/README.md"
fi

echo "mock-init: done — fill 04-spec/screens.md, build a comp per screen, then derive 04-spec/contracts/"
