/* env-links.js — RAPID project harness (DEVELOPER VIEW).
 *
 * The deck this runs on is the *developer view*: the surface for navigating and
 * developing the product (PRD, spec, architecture, observatory, cost, docs).
 * It is NOT the product. This script makes that separation explicit:
 *   - tags the harness brand as "Developer View"
 *   - renders a separate PRODUCT cluster linking to the *finished product* in
 *     each environment: Local / Dev / Production (from docs/env.json).
 * Local also exposes a copyable launch command (a browser can't start a server,
 * so "launch" = copy the command to run the local product).
 *
 * Standard across every project FORGE builds. One line per page:
 *   <script src="env-links.js" defer></script>
 */
(function () {
  var nav = document.querySelector('.forge-nav');
  if (!nav) return;

  var st = document.createElement('style');
  st.textContent =
    '.dev-view-tag{font-size:7px;font-weight:700;text-transform:uppercase;letter-spacing:.12em;color:rgba(255,255,255,.5);border:1px solid rgba(255,255,255,.22);border-radius:3px;padding:2px 6px;margin-right:10px;white-space:nowrap;align-self:center}' +
    '.env-links{margin-left:auto;display:flex;align-items:center;gap:4px;padding-left:14px;border-left:1px solid rgba(255,255,255,.15);flex-shrink:0}' +
    '.env-links .env-lbl{font-size:7px;font-weight:700;text-transform:uppercase;letter-spacing:.12em;color:rgba(255,255,255,.4);margin-right:3px}' +
    '.env-links a{display:inline-flex;align-items:center;font-size:9.5px;font-weight:600;color:rgba(255,255,255,.6);text-decoration:none;padding:4px 8px;border:1px solid rgba(255,255,255,.18);border-radius:3px;white-space:nowrap;transition:all .1s}' +
    '.env-links a:hover{color:#fff;border-color:rgba(255,255,255,.45)}' +
    '.env-links a.off{opacity:.4;cursor:not-allowed}' +
    '.env-links .dot{width:5px;height:5px;border-radius:50%;margin-right:5px;display:inline-block}' +
    '.env-links .launch{margin-left:3px;padding:4px 6px;border:1px solid rgba(255,255,255,.18);border-radius:3px;color:rgba(255,255,255,.55);cursor:pointer;font-size:9px}' +
    '.env-links .launch:hover{color:#fff;border-color:rgba(255,255,255,.45)}';
  document.head.appendChild(st);

  // 1) Mark the harness as the developer view (only if not already tagged).
  var brand = nav.querySelector('.forge-nav-brand');
  if (brand && !nav.querySelector('.dev-view-tag')) {
    var tag = document.createElement('span');
    tag.className = 'dev-view-tag';
    tag.textContent = 'Developer View';
    tag.title = 'This deck is the developer view — navigate & develop the product. The product itself is under "Product →".';
    brand.insertAdjacentElement('afterend', tag);
  }

  // 2) Render the PRODUCT cluster (the finished app per environment).
  fetch('env.json')
    .then(function (r) { return r.ok ? r.json() : null; })
    .then(function (env) {
      if (!env) return;
      var wrap = document.createElement('div');
      wrap.className = 'env-links';
      wrap.appendChild(Object.assign(document.createElement('span'), { className: 'env-lbl', textContent: 'Product' }));

      [['local', 'Local', '#2BD4A0'], ['dev', 'Dev', '#E0A93B'], ['prod', 'Production', '#E05656']]
        .forEach(function (row) {
          var key = row[0], label = row[1], color = row[2];
          var e = env[key] || {};
          var live = !!e.url;
          var a = document.createElement('a');
          if (live) { a.href = e.url; a.target = '_blank'; a.rel = 'noopener'; }
          else { a.className = 'off'; a.href = 'javascript:void 0'; }
          a.title = live ? (label + ' product: ' + e.url) : (label + ' environment not set');
          a.innerHTML = '<span class="dot" style="background:' + (live ? color : '#666') + '"></span>' + label;
          wrap.appendChild(a);

          if (key === 'local' && e.launch) {
            var b = document.createElement('span');
            b.className = 'launch';
            b.textContent = '▶ launch';
            b.title = 'Copy: ' + e.launch;
            b.addEventListener('click', function () {
              navigator.clipboard && navigator.clipboard.writeText(e.launch);
              var old = b.textContent;
              b.textContent = '✓ copied';
              setTimeout(function () { b.textContent = old; }, 1400);
            });
            wrap.appendChild(b);
          }
        });

      nav.appendChild(wrap);
    })
    .catch(function () { /* offline / no env.json — product cluster omitted */ });
})();
