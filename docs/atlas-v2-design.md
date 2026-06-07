# Atlas UI v2 — design spec (extracted from the "Constellation" docs screenshot)

> Produced by running `tools/design-extract-prompt.md` against the reference screenshot.
> Drives `templates/template-docs-page-v2.html` (a re-skin of the v1 template — same class
> contract, dark cosmic theme).

**1. Mood & brand.** Calm, premium, spacious, technical. A "constellation / cosmic" metaphor —
deep night-sky surfaces with a cool starlight accent. **Dark theme.**

**2. Color palette** (approx):
- bg base `#0D1117` · raised surface `#161B22` · hover/elevated `#1C2330`
- text primary `#E6EDF3` · muted `#9BA6B2` · dim `#6B7480`
- borders `#2A313B` · subtle `#20262F`
- accent (links/active nav/eyebrows) periwinkle `#7AA2F7`; secondary cyan `#56D4DD` (sparing)
- semantic: success `#3FB950` · warning `#D29922` · danger `#F85149`
- effects: faint accent radial glow top-left (~6%), barely-there starfield dots, soft card shadows, 1px low-contrast dividers

**3. Typography.** System sans (`-apple-system`, Inter-like fallback).
- page title 1.9rem / 700 / 1.2 / near-white
- section heading 1.25rem / 700 / near-white
- subheading 1rem / 700
- body 0.9rem / 1.7 / muted
- eyebrow 0.58rem / 700 / UPPERCASE / +0.14em tracking / **accent**

**4. Spacing & rhythm.** 4px base · content max-width ~760px · ~48px section gap · airy density · radius 8px (cards) / 6px (small).

**5. Layout.** Sticky top bar + left nav (~280px) + content column (+ optional right TOC). Sidebar sticky-scrolls; top bar fixed.

**6. Components.**
- top nav: dark bar, brand (✦ glyph + wordmark), muted links, accent underline on active, a rounded ghost CTA at right
- left sidebar: UPPERCASE dim group labels; muted items; **active = accent-tint bg + accent text + 2px left accent bar**
- cards: raised surface, subtle border, soft shadow, 8px radius
- callouts (strategy/key-insight): surface with a left accent bar
- pills/badges: rounded, tinted semantic backgrounds
- tables: surface header row with accent text, subtle row dividers, even-row tint
- code: near-black `#0A0D12` bg, subtle border, mono, light text
- icons: thin line style

**7. Motion & detail.** 120ms ease on hover/active; accent focus ring; cards lift ~1px on hover; nav links brighten on hover.

**8. CSS tokens.**
```css
:root{
  --bg:#0D1117; --surface:#161B22; --surface-alt:#1C2330;
  --border:#2A313B; --border-light:#20262F;
  --text:#E6EDF3; --text-muted:#9BA6B2; --text-dim:#6B7480;
  --navy:#7AA2F7; /* repurposed: primary accent (fills/active/eyebrow) */
  --blue:#58A6FF; --green:#3FB950; --red:#F85149; --amber:#D29922;
  --purple:#BC8CFF; --teal:#56D4DD;
  --radius:8px; --radius-sm:6px;
}
```

**9. Rules.**
- DO keep surfaces near-black and let a single cool accent carry interactivity (links, active, eyebrows).
- DO keep generous vertical rhythm and a narrow reading column.
- DO use very low-contrast borders + faint glow for depth instead of heavy lines.
- DON'T color body headings with the accent — headings stay near-white; accent is for eyebrows/links/active only.
- DON'T add saturated fills or hard shadows — it reads cheap; keep it subtle and cosmic.
