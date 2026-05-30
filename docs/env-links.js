/* env-links.js — RAPID project harness (DEVELOPER VIEW).
 *
 * The deck this runs on is the *developer view*: the surface for navigating and
 * developing the product. It is NOT the product. This script:
 *   - tags the harness brand "Developer View"
 *   - adds a per-page "↻ Regenerate" button that regenerates THIS page from its
 *     source (POST /api/regen?page=<file>; the command is registered per page in
 *     docs/regen.json and run by observe-server — instant scripts or a page-
 *     specific `claude -p`)
 *   - renders a PRODUCT cluster linking to the finished product per environment
 *     (Local / Dev / Production from docs/env.json; Local has a launch command).
 * Standard across every FORGE project. One line per page:
 *   <script src="env-links.js" defer></script>
 */
(function () {
  var nav = document.querySelector('.forge-nav');
  if (!nav) return;

  var st = document.createElement('style');
  st.textContent =
    '.dev-view-tag{font-size:7px;font-weight:700;text-transform:uppercase;letter-spacing:.12em;color:rgba(255,255,255,.5);border:1px solid rgba(255,255,255,.22);border-radius:3px;padding:2px 6px;margin-right:10px;white-space:nowrap;align-self:center}' +
    '.harness-right{margin-left:auto;display:flex;align-items:center;gap:8px;padding-left:14px;flex-shrink:0}' +
    '.regen-btn{font:inherit;font-size:9.5px;font-weight:600;color:rgba(255,255,255,.7);background:transparent;border:1px solid rgba(255,255,255,.25);border-radius:3px;padding:4px 9px;white-space:nowrap;cursor:pointer;transition:all .1s}' +
    '.regen-btn:hover{color:#fff;border-color:rgba(255,255,255,.5)}' +
    '.regen-btn:disabled{cursor:default}' +
    '.regen-btn.off{opacity:.4;cursor:not-allowed}' +
    '.env-links{display:flex;align-items:center;gap:4px;padding-left:12px;border-left:1px solid rgba(255,255,255,.15)}' +
    '.env-links .env-lbl{font-size:7px;font-weight:700;text-transform:uppercase;letter-spacing:.12em;color:rgba(255,255,255,.4);margin-right:3px}' +
    '.env-links a{display:inline-flex;align-items:center;font-size:9.5px;font-weight:600;color:rgba(255,255,255,.6);text-decoration:none;padding:4px 8px;border:1px solid rgba(255,255,255,.18);border-radius:3px;white-space:nowrap;transition:all .1s}' +
    '.env-links a:hover{color:#fff;border-color:rgba(255,255,255,.45)}' +
    '.env-links a.off{opacity:.4;cursor:not-allowed}' +
    '.env-links .dot{width:5px;height:5px;border-radius:50%;margin-right:5px;display:inline-block}' +
    '.env-links .launch{margin-left:3px;padding:4px 6px;border:1px solid rgba(255,255,255,.18);border-radius:3px;color:rgba(255,255,255,.55);cursor:pointer;font-size:9px}' +
    '.env-links .launch:hover{color:#fff;border-color:rgba(255,255,255,.45)}';
  document.head.appendChild(st);

  // 1) Tag the harness as the developer view (once).
  var brand = nav.querySelector('.forge-nav-brand');
  if (brand && !nav.querySelector('.dev-view-tag')) {
    var tag = document.createElement('span');
    tag.className = 'dev-view-tag';
    tag.textContent = 'Developer View';
    tag.title = 'This deck is the developer view — navigate & develop the product. The product itself is under "Product →".';
    brand.insertAdjacentElement('afterend', tag);
  }

  var thisPage = location.pathname.split('/').filter(Boolean).pop() || 'observatory.html';

  function buildRegenButton(regen) {
    var entry = regen && regen[thisPage];
    var hasCmd = entry && entry.cmd;
    var btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'regen-btn' + (hasCmd ? '' : ' off');
    btn.textContent = '↻ Regenerate';
    btn.title = hasCmd
      ? ('Regenerate this page from its source (' + (entry.kind || 'generator') + ')')
      : ((entry && entry.note) || 'No generator registered for this page');
    btn.addEventListener('click', function () {
      if (btn.classList.contains('off') || btn.disabled) return;
      var orig = btn.textContent;
      btn.disabled = true;
      btn.textContent = '⏳ regenerating…';
      fetch('/api/regen?page=' + encodeURIComponent(thisPage), { method: 'POST' })
        .then(function (r) { return r.json(); })
        .then(function (res) {
          if (res.started && res.kind === 'instant') {
            btn.textContent = '✓ updating…';
            setTimeout(function () { location.reload(); }, 1500);
          } else if (res.started) {
            btn.textContent = '⏳ started — reload when ready';
            setTimeout(function () { btn.textContent = orig; btn.disabled = false; }, 5000);
          } else {
            btn.textContent = '— ' + (res.reason || 'no generator');
            setTimeout(function () { btn.textContent = orig; btn.disabled = false; }, 3000);
          }
        })
        .catch(function () {
          btn.textContent = '⚠ needs observatory server (:4040)';
          setTimeout(function () { btn.textContent = orig; btn.disabled = false; }, 3000);
        });
    });
    return btn;
  }

  function buildEnvCluster(env) {
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
            var old = b.textContent; b.textContent = '✓ copied';
            setTimeout(function () { b.textContent = old; }, 1400);
          });
          wrap.appendChild(b);
        }
      });
    return wrap;
  }

  // 2) Assemble the right-hand cluster: [↻ Regenerate] [Product links]
  var getJSON = function (u) { return fetch(u).then(function (r) { return r.ok ? r.json() : null; }).catch(function () { return null; }); };
  Promise.all([getJSON('regen.json'), getJSON('env.json')]).then(function (res) {
    var regen = res[0], env = res[1];
    var right = document.createElement('div');
    right.className = 'harness-right';
    right.appendChild(buildRegenButton(regen));
    if (env) right.appendChild(buildEnvCluster(env));
    nav.appendChild(right);
  });
})();
