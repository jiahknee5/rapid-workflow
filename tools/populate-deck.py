#!/usr/bin/env python3
"""populate-deck.py — fill a project's Atlas deck pages from its OWN artifacts.

Deterministic (no LLM): renders each project markdown/JSON artifact into the matching
deck page — replacing the `atlas-stub` main content AND rebuilding the in-page sidebar
"On this page" TOC from the rendered sections (so no dead `#pending` anchor survives).
Used by the lifecycle E2E test's `docs` stage to prove a fresh project's documentation
actually populates. Reads PROJECT from $PROJECT (default cwd).

The kit supplies the form (template, nav, CSS); the project supplies the content — so a
build of `rapid_workflow_test_1` shows that project's PRD/spec/architecture, never the kit's.
"""
import html
import json
import os
import re
import sys

PROJ = os.environ.get("PROJECT") or (sys.argv[1] if len(sys.argv) > 1 else os.getcwd())
DOCS = os.path.join(PROJ, "docs")


def esc(s):
    return html.escape(str(s if s is not None else ""))


def slug(s):
    return re.sub(r"[^a-z0-9]+", "-", str(s).lower()).strip("-") or "section"


def _body_html(body):
    """Render a list of markdown body lines: `- ` → list items, else paragraphs."""
    out, ul = [], []
    for ln in body:
        s = ln.strip()
        if s.startswith("- "):
            ul.append("<li>" + esc(s[2:]) + "</li>")
            continue
        if ul:
            out.append("<ul>" + "".join(ul) + "</ul>"); ul = []
        if s:
            out.append('<div class="section-desc">' + esc(s) + "</div>")
    if ul:
        out.append("<ul>" + "".join(ul) + "</ul>")
    return "".join(out)


def md_to_sections(md, section_id):
    """Render markdown into `.section[id]` blocks. The title section ALSO carries any
    body that appears before the first `##` heading (so a doc with only a title + a list
    — e.g. workflow.md's `- in:/proc:/out:` — is never dropped). Returns ('', '') -> None."""
    title, lead = "", []
    blocks, cur_head, cur_body = [], None, []
    for ln in md.splitlines():
        if ln.startswith("# ") and not ln.startswith("## "):
            title = ln[2:].strip()
        elif ln.startswith("## "):
            if cur_head is not None:
                blocks.append((cur_head, cur_body))
            cur_head, cur_body = ln[3:].strip(), []
        elif cur_head is not None:
            cur_body.append(ln)
        else:
            lead.append(ln)                       # body before the first heading — keep it
    if cur_head is not None:
        blocks.append((cur_head, cur_body))

    secs = []
    if title or lead:
        secs.append('<div class="section" id="%s"><div class="section-id">%s</div>'
                    '<div class="section-title">%s</div>%s</div>'
                    % (slug(title or section_id), esc(section_id), esc(title), _body_html(lead)))
    for head, body in blocks:
        secs.append('<div class="section" id="%s"><div class="section-title">%s</div>%s</div>'
                    % (slug(head), esc(head), _body_html(body)))
    return "".join(secs) or None


def eval_sections():
    try:
        d = json.load(open(os.path.join(DOCS, "eval.json")))
    except Exception:
        return None
    s = d.get("summary", {})
    rows = "".join(
        '<li><strong>%s</strong> — %s — %s</li>' % (
            "PASS" if a.get("pass") else "FAIL", esc(a.get("name")), esc(a.get("detail", "")))
        for a in d.get("assertions", []))
    return ('<div class="section" id="test-results"><div class="section-id">Evaluation</div>'
            '<div class="section-title">Test results</div>'
            '<div class="section-desc">%s of %s assertions passing (generated %s).</div>'
            '<ul>%s</ul></div>' % (esc(s.get("pass", 0)), esc(s.get("total", 0)),
                                   esc(d.get("generated", "")), rows))


def documentation_sections():
    try:
        d = json.load(open(os.path.join(PROJ, "docs.json")))
    except Exception:
        return None
    rows = "".join('<li><strong>%s</strong> — %s</li>' % (esc(x.get("title")), esc(x.get("file")))
                   for x in d.get("docs", []))
    return ('<div class="section" id="registered-documents"><div class="section-id">Documentation</div>'
            '<div class="section-title">Registered documents (%s)</div><ul>%s</ul></div>'
            % (esc(len(d.get("docs", []))), rows))


def observatory_sections():
    """The observatory is a live dashboard; for a static deck render the build state from
    .rapid/STATE.json so the page is never a stub (live events stream when observe-server runs)."""
    try:
        st = json.load(open(os.path.join(PROJ, ".rapid", "STATE.json")))
    except Exception:
        st = {}
    rows = "".join('<li><strong>%s</strong>: %s</li>' % (esc(k), esc(v)) for k, v in st.items())
    return ('<div class="section" id="build-state"><div class="section-id">Observatory</div>'
            '<div class="section-title">Build state</div>'
            '<div class="section-desc">Current build state from <code>.rapid/STATE.json</code>. '
            'Live agent events stream here when <code>observe-server</code> is running.</div>'
            '<ul>%s</ul></div>' % (rows or "<li>no state recorded yet</li>"))


def _toc(inner_html):
    """Build the in-page sidebar 'On this page' list from the rendered sections."""
    items = re.findall(r'<div class="section" id="([^"]+)">(?:<div class="section-id">[^<]*</div>)?'
                       r'<div class="section-title">([^<]*)</div>', inner_html)
    if not items:
        return '<div class="sidebar-section">On this page</div>'
    links = "".join('<a href="#%s">%s</a>' % (sid, esc(title)) for sid, title in items)
    return '<div class="sidebar-section">On this page</div>' + links


def _write_page(page_path, inner_html):
    """Replace the deck page's `<div class="main">` inner with inner_html, and rebuild the
    in-page sidebar TOC from the rendered sections (removing the `#pending` stub). Re-runnable."""
    if not os.path.isfile(page_path):
        return False
    h = open(page_path, encoding="utf-8").read()
    m = re.search(r'<div class="main">', h)
    if not m:
        return False
    i, open_at = m.end(), m.start()
    depth, j = 1, i
    for tok in re.finditer(r'<div\b|</div>', h[i:]):
        if tok.group() == "</div>":
            depth -= 1
            if depth == 0:
                j = i + tok.start()
                break
        else:
            depth += 1
    h = h[:open_at] + '<div class="main">' + inner_html + h[j:]
    # rebuild the in-page sidebar TOC (kill the stale Status/#pending stub)
    h = re.sub(r'<div class="sidebar-section">Status</div>\s*<a href="#pending">Pending</a>',
               _toc(inner_html), h)
    open(page_path, "w", encoding="utf-8").write(h)
    return "atlas-stub" not in h


def _md(path, section_id):
    return lambda: md_to_sections(open(os.path.join(PROJ, path)).read(), section_id)


def main():
    # Hard guard: never run against the kit itself (its docs are hand-curated, not stubs).
    if os.path.isfile(os.path.join(PROJ, "skills", "rapid", "SKILL.md")):
        print("populate-deck: refusing to run against the kit root (%s)" % PROJ, file=sys.stderr)
        sys.exit(2)
    jobs = [
        ("prd.html",           _md("01-intake/PRD.md", "PRD")),
        ("prd-enhanced.html",  _md("01-intake/PRD-ENHANCED.md", "Enhanced PRD")),
        ("spec.html",          _md("04-spec/spec.md", "Spec")),
        ("architecture.html",  _md("04-spec/architecture.md", "Architecture")),
        ("workflow.html",      _md("04-spec/workflow.md", "Workflow")),
        ("users.html",         _md("04-spec/users.md", "Users")),
        ("eval.html",          eval_sections),
        ("documentation.html", documentation_sections),
        ("observatory.html",   observatory_sections),
    ]
    failed = []
    for page, render in jobs:
        try:
            inner = render()
        except FileNotFoundError:
            inner = None
        if not inner:
            continue
        if not _write_page(os.path.join(DOCS, page), inner):
            failed.append(page)
    if failed:
        print("populate-deck: still stubbed:", ", ".join(failed), file=sys.stderr)
        sys.exit(1)
    print("populate-deck: populated", DOCS)


if __name__ == "__main__":
    main()
