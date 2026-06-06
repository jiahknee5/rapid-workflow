# Prompt — Extract design elements from a screenshot

Reusable prompt. Give a model a UI screenshot; it returns a structured **design spec**
(below) that a builder can turn into CSS tokens + components. Designed to capture a
*look*, not to pixel-clone. Pair with a target's existing class/DOM contract so the
output is a re-skin, not a rewrite.

---

## Prompt

> You are a senior product designer doing a **design teardown** of the attached UI
> screenshot. Identify the design language precisely enough that an engineer could
> rebuild the look on a *different* page without seeing the image. Do **not** describe
> the page's words/content — describe its **design system**. Where you can't read an
> exact value, give your best estimate and say "(approx)". Output the spec below, in order.
>
> **1. Mood & brand** — 3–5 adjectives (e.g. calm, premium, dense, playful). The overall
> impression, theme/metaphor, and whether it's light/dark/auto.
>
> **2. Color palette** — as hex (approx ok), grouped:
> - background layers: base, raised surface, hover/elevated
> - text: primary, muted/secondary, dim/tertiary
> - borders/dividers: default, subtle
> - accent(s): primary + any secondary; where each is used (links, active nav, focus)
> - semantic: success / warning / danger if present
> - special effects: gradients, glows, shadows, background textures (e.g. starfield, noise)
>
> **3. Typography** — font family/families (and likely fallbacks), and a type scale:
> page title, section heading, subheading, body, small/eyebrow — give size, weight,
> line-height, letter-spacing, and casing (e.g. UPPERCASE eyebrows) for each.
>
> **4. Spacing & rhythm** — base unit, content max-width, section vertical gap, density
> (tight/comfortable/airy), and corner radius scale.
>
> **5. Layout & grid** — overall structure (e.g. top bar + left nav + content + right TOC),
> column widths, sticky elements, what's fixed vs scrolls.
>
> **6. Components** — for each present, note shape/fill/border/state: top nav, left sidebar
> (group labels, item style, active state), right TOC, cards, callouts/admonitions, buttons
> (primary/ghost), badges/pills, tables, code blocks, inputs/search, icons (style: line/solid,
> size), dividers.
>
> **7. Motion & detail** — hover/active transitions, focus rings, elevation changes,
> any signature flourish.
>
> **8. CSS tokens** — emit a `:root { --token: value; }` block capturing the palette +
> radius + a few key sizes, named so they map onto the target's existing tokens.
>
> **9. Three "do" rules and two "don't" rules** — the essence of nailing this look (and the
> traps that would make a rebuild feel off-brand).
>
> Keep it concrete and buildable. No prose preamble — start at section 1.

---

## How to apply (in this repo)

1. Read the screenshot with the Read tool (shell tools can't read `~/Desktop` due to macOS TCC).
2. Run the prompt above against it → get the design spec.
3. Re-skin the **existing** template contract — keep every class name in
   `templates/template-docs-page.html` (so `sidebar.js` / `env-links.js` and all generated
   pages keep working); change only the `<style>` tokens + component rules. Save as a new
   `templates/template-docs-page-v2.html`. `atlas-init.sh` extracts the `<style>` block, so a
   re-skin propagates to every project's deck.
