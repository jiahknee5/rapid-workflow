/* sidebar.js — RAPID Atlas left-menu builder (DEVELOPER VIEW).
 *
 * Turns the per-page left sidebar into a full Atlas map. On every page it
 * PREPENDS two blocks above the page's own hand-authored "On this page" menu
 * (which is preserved, so rich anchors / req-counts are never lost):
 *
 *   1) Deployments — Local / Dev / Production links from docs/env.json, with
 *      greyed "not set" placeholders. (The top-nav cluster from env-links.js
 *      stays too; this is the always-visible home for the same links.)
 *   2) Pages — every page THIS project renders. The list is derived from the
 *      top rapid-nav links (no hardcoded page set), so it works for any
 *      project. The current page is highlighted and its detail lives in the
 *      authored menu below; every OTHER page is eager-fetched once and its
 *      sections nested as deep links (page.html#id), so the menu shows ALL
 *      pages and ALL their sections.
 *
 * Standard across every RAPID project. Ships ALONGSIDE env-links.js — any
 * builder/generator that emits these pages must copy BOTH next to each other.
 * One line per page, after env-links.js:
 *   <script src="sidebar.js" defer></script>
 */
(function () {
  var sidebar = document.querySelector('.sidebar');
  if (!sidebar) return;

  // Page list is DERIVED from the top rapid-nav links that {{NAV}} injects into
  // every generated page — so it reflects whatever pages THIS project renders,
  // not the default kit. The hardcoded list is only a fallback for a page with
  // no rapid-nav (e.g. one rendered outside the template).
  var FALLBACK_PAGES = [
    ['home.html', 'Home'], ['prd.html', 'PRD'], ['prd-enhanced.html', 'Enhanced PRD'],
    ['architecture.html', 'Architecture'], ['workflow.html', 'Workflow'], ['users.html', 'Users'],
    ['spec.html', 'Spec'], ['observatory.html', 'Observatory'], ['eval.html', 'Eval'],
    ['cost.html', 'Cost'], ['documentation.html', 'Documentation']
  ];

  function pagesFromNav() {
    var nav = document.querySelector('.rapid-nav');
    if (!nav) return null;
    var out = [], seen = {};
    var add = function (href, label) {
      var slug = (href || '').split('#')[0].split('/').pop();
      if (!slug || seen[slug]) return;
      seen[slug] = 1;
      out.push([slug, (label || slug).replace(/\s+/g, ' ').trim()]);
    };
    // The Atlas hub lives in the brand area as env-links.js' dev-view-tag
    // (href=home.html). Surface it first so the hub is in the tree.
    var hub = nav.querySelector('a.dev-view-tag[href], a[href$="home.html"]');
    if (hub) add(hub.getAttribute('href'), 'Home');
    // Page links = the {{NAV}} anchors. Skip the dev-view-tag and anything in
    // the injected right-hand harness cluster (Product/Source/Regenerate), and
    // keep only relative .html targets.
    [].forEach.call(nav.querySelectorAll('a'), function (a) {
      if (a.classList.contains('dev-view-tag') || a.closest('.harness-right')) return;
      var href = (a.getAttribute('href') || '').trim();
      if (!/\.html(#|$)/i.test(href) || /^https?:|^javascript:/i.test(href)) return;
      add(href, a.textContent);
    });
    return out.length ? out : null;
  }

  var PAGES = pagesFromNav() || FALLBACK_PAGES;
  var here = location.pathname.split('/').filter(Boolean).pop() || 'home.html';

  var st = document.createElement('style');
  st.textContent =
    '.atlas-deploys{display:flex;flex-direction:column;gap:1px;margin-bottom:4px;}' +
    '.atlas-deploys a{display:flex;align-items:center;}' +
    '.atlas-deploys a.off{opacity:.5;cursor:default;}' +
    '.atlas-deploys .dot{width:6px;height:6px;border-radius:50%;margin-right:8px;flex-shrink:0;display:inline-block;}' +
    '.atlas-deploys .env-state{margin-left:auto;font-size:0.58rem;color:var(--text-dim);font-style:italic;}' +
    '.atlas-page{display:flex;align-items:center;}' +
    '.atlas-page .caret{margin-left:auto;font-size:0.6rem;color:var(--text-dim);transition:transform .12s;padding-left:6px;}' +
    '.atlas-page.collapsed .caret{transform:rotate(-90deg);}' +
    '.atlas-sub{overflow:hidden;}' +
    '.atlas-page.collapsed + .atlas-sub{display:none;}' +
    '.atlas-secs-empty{padding:2px 8px 2px 20px;font-size:0.68rem;color:var(--text-dim);font-style:italic;}';
  document.head.appendChild(st);

  function esc(s) { return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) { return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]; }); }
  function getJSON(u) { return fetch(u).then(function (r) { return r.ok ? r.json() : null; }).catch(function () { return null; }); }

  // Pull top-level sections (id + title) out of a parsed document's .main.
  // Handles both page structures used in the kit: .section[id] blocks with a
  // .section-title, and plain <h1/h2 id> headings inside <main class="main">.
  function parseSections(docOrHtml) {
    var doc = typeof docOrHtml === 'string'
      ? new DOMParser().parseFromString(docOrHtml, 'text/html')
      : docOrHtml;
    var clean = function (s) { return String(s).replace(/\s+/g, ' ').trim(); };
    // Content lives in .main on most pages, .docpage-content on a few.
    var root = doc.querySelector('.main') || doc.querySelector('.docpage-content') || doc.body || doc;
    var secs = root.querySelectorAll('.section[id]');
    if (secs.length) {
      return [].map.call(secs, function (s) {
        var t = s.querySelector('.section-title');
        return { id: s.id, title: clean(t ? t.textContent : s.id) };
      });
    }
    // Fallback: heading-based pages. Strip any trailing .tag chip from the text.
    var heads = root.querySelectorAll('h1[id], h2[id]');
    return [].map.call(heads, function (h) {
      var c = h.cloneNode(true);
      [].forEach.call(c.querySelectorAll('.tag'), function (x) { x.remove(); });
      return { id: h.id, title: clean(c.textContent) };
    });
  }

  // --- Build the injected fragment, inserted right after .sidebar-sub ---
  var frag = document.createElement('div');
  var anchor = sidebar.querySelector('.sidebar-sub') || sidebar.querySelector('.sidebar-brand');

  // 1) DEPLOYMENTS
  var depHdr = document.createElement('div');
  depHdr.className = 'sidebar-section';
  depHdr.textContent = 'Deployments';
  var depBox = document.createElement('div');
  depBox.className = 'atlas-deploys';
  frag.appendChild(depHdr);
  frag.appendChild(depBox);

  // 2) PAGES
  var pgHdr = document.createElement('div');
  pgHdr.className = 'sidebar-section';
  pgHdr.textContent = 'Pages';
  frag.appendChild(pgHdr);

  // Per-page nodes: a link row (+ caret for non-active) and a sub container.
  var subBoxes = {};
  PAGES.forEach(function (p) {
    var href = p[0], label = p[1], active = href === here;

    var row = document.createElement('a');
    row.className = 'atlas-page' + (active ? ' active' : ''); // sections shown by default; caret collapses
    row.href = href;
    row.innerHTML = esc(label);
    if (!active) {
      var caret = document.createElement('span');
      caret.className = 'caret';
      caret.textContent = '▾';
      row.appendChild(caret);
    }
    frag.appendChild(row);

    if (!active) {
      var sub = document.createElement('div');
      sub.className = 'atlas-sub';
      frag.appendChild(sub);
      subBoxes[href] = sub;

      // Caret toggles this page's section list (link still navigates on the label).
      row.addEventListener('click', function (e) {
        if (e.target && e.target.classList.contains('caret')) {
          e.preventDefault();
          row.classList.toggle('collapsed');
        }
      });
    }
  });

  if (anchor) anchor.insertAdjacentElement('afterend', frag);
  else sidebar.insertBefore(frag, sidebar.firstChild);
  // insertAdjacentElement on a wrapper would nest it; instead splice children in.
  // (frag is a <div>; move its children up so they share .sidebar styling.)
  if (frag.parentNode) {
    var parent = frag.parentNode;
    while (frag.firstChild) parent.insertBefore(frag.firstChild, frag);
    parent.removeChild(frag);
  }

  // --- Populate DEPLOYMENTS from env.json ---
  getJSON('env.json').then(function (env) {
    env = env || {};
    var prod = env.product || env; // env-links.js convention: top-level or .product
    [['local', 'Local', '#2BD4A0'], ['dev', 'Dev', '#E0A93B'], ['prod', 'Production', '#E05656']]
      .forEach(function (row) {
        var e = prod[row[0]] || {};
        var live = !!e.url;
        var a = document.createElement('a');
        if (live) { a.href = e.url; a.target = '_blank'; a.rel = 'noopener'; }
        else { a.className = 'off'; a.href = 'javascript:void 0'; }
        a.title = live ? (row[1] + ': ' + e.url) : (row[1] + ' not set');
        a.innerHTML = '<span class="dot" style="background:' + (live ? row[2] : '#9aa5b1') + '"></span>' + esc(row[1]) +
          (live ? '' : '<span class="env-state">not set</span>');
        depBox.appendChild(a);
      });
  });

  // --- Populate each non-active page's sections (active page detail is below) ---
  Object.keys(subBoxes).forEach(function (href) {
    var box = subBoxes[href];
    fetch(href).then(function (r) { return r.ok ? r.text() : ''; }).then(function (html) {
      var secs = html ? parseSections(html) : [];
      if (!secs.length) {
        box.innerHTML = '<div class="atlas-secs-empty">no sections yet</div>';
        return;
      }
      secs.forEach(function (s) {
        var a = document.createElement('a');
        a.className = 'sub';
        a.href = href + '#' + s.id;
        a.textContent = s.title;
        box.appendChild(a);
      });
    }).catch(function () {
      box.innerHTML = '<div class="atlas-secs-empty">unavailable</div>';
    });
  });
})();
