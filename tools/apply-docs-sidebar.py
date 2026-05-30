#!/usr/bin/env python3
"""apply-docs-sidebar.py — convert a RAPID docs web page to the standard
spec-style layout: top forge-nav (kept) + left .sidebar menu + content.

The canonical layout/CSS lives in templates/template-docs-page.html; this
applies it to existing pages in place. Idempotent (skips pages already
converted). Two sidebar modes:

  default   build an in-page TOC from .section blocks (id + .section-title),
            falling back to <h2> headings (ids auto-assigned).
  --nav     populate the sidebar with explicit cross-page links instead
            (use for hub/dynamic pages with no static sections).

Usage:
  apply-docs-sidebar.py docs/cost.html --title Cost
  apply-docs-sidebar.py docs/documentation.html --title Documentation \\
       --nav "PRD:prd.html,Architecture:architecture.html,Spec:spec.html"
"""
import re, sys, argparse, html

CSS = """
/* --- standard sidebar layout (templates/template-docs-page.html) --- */
body{min-height:100vh;display:flex;flex-direction:column}
.spec-layout{display:flex;flex:1}
.docpage-content{flex:1;min-width:0}
.sidebar{width:280px;flex-shrink:0;background:var(--surface,#F7F8FA);border-right:1px solid var(--border,#D4D8DE);padding:32px 20px;position:sticky;top:38px;height:calc(100vh - 38px);overflow-y:auto}
.sidebar-brand{font-size:1.1rem;font-weight:800;color:var(--navy,#1A2744);letter-spacing:-0.02em;margin-bottom:4px}
.sidebar-sub{font-size:0.7rem;color:var(--text-dim,#8896A6);margin-bottom:24px;font-weight:500}
.sidebar-section{font-size:0.55rem;font-weight:700;letter-spacing:0.14em;text-transform:uppercase;color:var(--text-dim,#8896A6);margin:20px 0 8px}
.sidebar a{display:block;font-size:0.78rem;color:var(--text-muted,#4A5568);text-decoration:none;padding:3px 8px;border-radius:3px;margin:1px 0;line-height:1.4}
.sidebar a:hover{background:var(--surface-alt,#F0F2F5);color:var(--text,#1A2744)}
.section{scroll-margin-top:48px}
"""

def slug(text):
    return re.sub(r'[^a-z0-9]+', '-', text.lower()).strip('-')[:40]

def build_toc(s):
    """Return (modified_html, toc_html). Prefer .section blocks, else <h2>."""
    secs = re.findall(r'<div class="section"[^>]*id="([^"]+)"[^>]*>.*?<div class="section-title">(.*?)</div>', s, re.S)
    if secs:
        clean = lambda t: re.sub(r'<[^>]+>', '', t).strip()
        toc = '\n'.join(f'  <a href="#{i}">{clean(t)}</a>' for i, t in secs)
        return s, toc
    # fallback: <h2> headings; assign ids where missing
    links = []
    def repl(m):
        attrs, text = m.group(1), m.group(2)
        idm = re.search(r'id="([^"]+)"', attrs)
        hid = idm.group(1) if idm else slug(re.sub(r'<[^>]+>', '', text))
        links.append((hid, re.sub(r'<[^>]+>', '', text).strip()))
        if idm:
            return m.group(0)
        return f'<h2{attrs} id="{hid}">{text}</h2>'
    s = re.sub(r'<h2([^>]*)>(.*?)</h2>', repl, s, flags=re.S)
    toc = '\n'.join(f'  <a href="#{i}">{html.escape(t)}</a>' for i, t in links)
    return s, toc

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('file')
    ap.add_argument('--title', required=True)
    ap.add_argument('--label', default='Contents')
    ap.add_argument('--nav', default='', help='comma list "Label:href" for an explicit nav sidebar')
    a = ap.parse_args()

    s = open(a.file).read()
    if 'spec-layout' in s:
        print(f'{a.file}: already converted'); return
    s = s.replace('</style>', CSS + '</style>', 1)

    if a.nav:
        items = [p.split(':', 1) for p in a.nav.split(',') if ':' in p]
        body = '\n'.join(f'  <a href="{href}">{html.escape(lbl)}</a>' for lbl, href in items)
        sidebar_inner = f'<div class="sidebar-section">{html.escape(a.label)}</div>\n{body}'
    else:
        s, toc = build_toc(s)
        sidebar_inner = (f'<div class="sidebar-section">{html.escape(a.label)}</div>\n{toc}'
                         if toc else '')

    sidebar = ('<nav class="sidebar">\n'
               f'  <div class="sidebar-brand">RAPID</div>\n'
               f'  <div class="sidebar-sub">{html.escape(a.title)}</div>\n'
               f'  {sidebar_inner}\n</nav>')

    s = s.replace('</nav>', '</nav>\n<div class="spec-layout">\n' + sidebar + '\n<div class="docpage-content">\n', 1)
    s = s.replace('</body>', '</div><!-- /docpage-content -->\n</div><!-- /spec-layout -->\n</body>', 1)
    open(a.file, 'w').write(s)
    print(f'{a.file}: converted ({len(s)} bytes)')

if __name__ == '__main__':
    main()
