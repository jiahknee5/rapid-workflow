/* Atlas top-nav wiring — data-driven from docs/env.json (one level up).
   Local ▶ / Deployed / Source resolve to real URLs; unset ones grey out
   honestly. The Local launch command is exposed as a copy button. */
(function () {
  function flash(msg) {
    var f = document.createElement('div');
    f.textContent = msg;
    f.style.cssText = 'position:fixed;bottom:18px;right:18px;background:#1C2330;color:#E6EDF3;border:1px solid #2A313B;padding:8px 14px;border-radius:20px;font-size:12px;z-index:9999;box-shadow:0 6px 24px rgba(0,0,0,.4);';
    document.body.appendChild(f);
    setTimeout(function () { f.remove(); }, 1500);
  }
  function setLink(dest, url) {
    var a = document.querySelector('.dest[data-dest="' + dest + '"]');
    if (!a) return null;
    if (url) { a.href = url; a.target = '_blank'; a.rel = 'noopener'; a.classList.remove('off'); }
    else { a.classList.add('off'); a.removeAttribute('href'); a.title = 'not set'; }
    return a;
  }
  fetch('../env.json').then(function (r) { return r.ok ? r.json() : null; }).then(function (env) {
    if (!env) return;
    var prod = env.product || env, src = env.source || {};
    var local = prod.local || {}, deployed = (prod.prod && prod.prod.url) ? prod.prod : (prod.dev || {});
    var la = setLink('local', local.url);
    setLink('deployed', deployed.url);
    setLink('source', src.github || src.gitlab || src.bitbucket);
    var btn = document.querySelector('.copy-launch');
    if (btn && local.launch) {
      btn.hidden = false;
      btn.title = 'Copy launch command';
      if (la) la.title = 'Open ' + (local.url || 'local') + '  ·  launch: ' + local.launch;
      btn.addEventListener('click', function (e) {
        e.preventDefault();
        if (navigator.clipboard && navigator.clipboard.writeText) {
          navigator.clipboard.writeText(local.launch).then(
            function () { flash('▶ launch command copied'); },
            function () { flash('copy failed'); }
          );
        } else { flash('clipboard unavailable'); }
      });
    }
  }).catch(function () {});
})();
