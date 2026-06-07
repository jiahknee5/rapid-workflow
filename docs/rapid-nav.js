/* Rapid — unified top navigation. One source of truth for the header/menu across
   every surface (Atlas, Build & Observatory, Test Suite, Documentation, the hub).
   Self-injecting: include `<script src="rapid-nav.js" defer></script>` on any docs/
   page. It styles + injects a consistent dark nav, hides any legacy per-page nav,
   marks the active destination, and data-drives Local/Deployed/Source from env.json. */
(function () {
  var file = (location.pathname.split('/').pop() || '');
  // Are we inside docs/atlas-v2/? then links to sibling surfaces need "../".
  var inAtlas = /\/atlas-v2\//.test(location.pathname);
  var P = inAtlas ? '../' : '';          // prefix to reach docs/ root
  var A = inAtlas ? '' : 'atlas-v2/';    // prefix to reach the Atlas

  function dest(label, href, active, attrs) {
    return '<a class="rn-dest' + (active ? ' rn-active' : '') + '"' + (attrs || '') +
           ' href="' + href + '">' + label + '</a>';
  }
  var inner =
    '<a class="rn-brand" href="' + A + 'index.html">✦ RAPID<span>Skills Atlas</span></a>' +
    // Logical lifecycle order: method → design references → run → verify → docs
    dest('Skills Atlas',        A + 'index.html',        inAtlas) +
    dest('Workflow',            P + 'workflow.html',     file === 'workflow.html') +
    dest('Architecture',        P + 'architecture.html', file === 'architecture.html') +
    dest('Build &amp; Observatory', P + 'observatory.html', file === 'observatory.html') +
    dest('Test Suite',          P + 'testsuite.html',    file === 'testsuite.html') +
    dest('Documentation',       P + 'documentation.html', file === 'documentation.html') +
    '<span class="rn-spacer"></span>' +
    dest('Local&nbsp;▶', P + 'home.html#product', false, ' data-rn="local"') +
    dest('Deployed',     P + 'home.html#product', false, ' data-rn="deployed"') +
    dest('Source',       P + 'home.html#source',  false, ' data-rn="source"');

  var css =
    '.rn-topnav{position:sticky;top:0;z-index:9999;display:flex;align-items:center;gap:0;' +
    'background:rgba(8,11,16,0.95);backdrop-filter:saturate(140%) blur(8px);' +
    'border-bottom:1px solid #2A313B;padding:0 16px;overflow-x:auto;flex-shrink:0;' +
    "font-family:-apple-system,BlinkMacSystemFont,'Helvetica Neue',sans-serif;}" +
    '.rn-brand{display:flex;flex-direction:column;font-size:12px;font-weight:800;color:#E6EDF3;' +
    'text-decoration:none;padding:8px 14px 8px 0;margin-right:8px;border-right:1px solid #2A313B;' +
    'line-height:1.12;white-space:nowrap;}' +
    '.rn-brand::before{content:"";}' +
    '.rn-brand span{font-size:7px;font-weight:500;color:#6B7480;letter-spacing:0.06em;text-transform:uppercase;}' +
    '.rn-dest{font-size:11px;font-weight:600;color:#9BA6B2;text-decoration:none;padding:12px 12px;' +
    'white-space:nowrap;border-bottom:2px solid transparent;transition:color .12s;}' +
    '.rn-dest:hover{color:#E6EDF3;}' +
    '.rn-active{color:#7AA2F7 !important;border-bottom-color:#7AA2F7;}' +
    '.rn-off{opacity:.4;cursor:default;}' +
    '.rn-spacer{flex:1;min-width:8px;}';

  function init() {
    var st = document.createElement('style'); st.textContent = css; document.head.appendChild(st);
    // Hide legacy per-page navs (the old .rapid-nav link bar) and any inline Atlas .top-nav,
    // so there's exactly one header everywhere.
    document.querySelectorAll('.rapid-nav, nav.top-nav').forEach(function (n) { n.style.display = 'none'; });
    var nav = document.createElement('nav');
    nav.className = 'rn-topnav';
    nav.innerHTML = inner;
    document.body.insertBefore(nav, document.body.firstChild);

    // Data-drive Local / Deployed / Source from env.json (same dir as docs/).
    fetch(P + 'env.json').then(function (r) { return r.ok ? r.json() : null; }).then(function (env) {
      if (!env) return;
      var prod = env.product || env, src = env.source || {};
      function wire(key, url) {
        var a = nav.querySelector('[data-rn="' + key + '"]'); if (!a) return;
        if (url) { a.href = url; a.target = '_blank'; a.rel = 'noopener'; a.classList.remove('rn-off'); }
        else { a.classList.add('rn-off'); a.removeAttribute('href'); a.title = 'not set'; }
      }
      wire('local', (prod.local || {}).url);
      wire('deployed', (prod.prod && prod.prod.url) || (prod.dev || {}).url);
      wire('source', src.github || src.gitlab || src.bitbucket);
    }).catch(function () {});
  }

  if (document.body) init();
  else document.addEventListener('DOMContentLoaded', init);
})();
