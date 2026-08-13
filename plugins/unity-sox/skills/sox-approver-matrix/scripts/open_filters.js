// Opens the "Filters" tab in the Lightning report builder's left panel.
//
// The builder opens on "Outline" (Groups/Columns); the control needs the Filters
// panel. A synthetic mouse click cannot be used -- macOS blocks those here -- so this
// runs through Chrome's AppleScript JavaScript bridge.
//
// The builder lives inside a same-origin iframe (/reports/lightningReportApp...) and
// uses shadow DOM, so a plain document.querySelectorAll on the top document finds
// nothing. This walks the top document, every reachable iframe, and every shadow root.
(function () {
  function visible(el) {
    if (!el || !el.getClientRects || !el.getClientRects().length) return false;
    var s = (el.ownerDocument.defaultView || window).getComputedStyle(el);
    return s.visibility !== 'hidden' && s.display !== 'none';
  }

  function roots() {
    var found = [document];
    var frames = document.querySelectorAll('iframe');
    for (var i = 0; i < frames.length; i++) {
      try {
        var d = frames[i].contentDocument;
        if (d && d.body) found.push(d);
      } catch (e) { /* cross-origin: skip */ }
    }
    return found;
  }

  function collect(root, acc, depth) {
    if (depth > 12) return;
    var els;
    try { els = root.querySelectorAll('*'); } catch (e) { return; }
    for (var i = 0; i < els.length; i++) {
      acc.push(els[i]);
      if (els[i].shadowRoot) collect(els[i].shadowRoot, acc, depth + 1);
    }
  }

  var docs = roots();

  // Already open? The Filters panel always shows a "Show Me" row.
  for (var d = 0; d < docs.length; d++) {
    var body = docs[d].body ? docs[d].body.innerText : '';
    if (/Show\s*Me/i.test(body)) return 'already-open';
  }

  for (var j = 0; j < docs.length; j++) {
    var all = [];
    collect(docs[j], all, 0);
    // Real tabs first, then any short element labelled Filters.
    for (var pass = 0; pass < 2; pass++) {
      for (var k = 0; k < all.length; k++) {
        var el = all[k];
        if (pass === 0 && el.getAttribute && el.getAttribute('role') !== 'tab') continue;
        var t = (el.innerText || el.textContent || '').trim();
        if (!/^Filters(\s|\d|$)/.test(t) || t.length > 20) continue;
        if (!visible(el)) continue;
        el.click();
        return 'clicked:' + t.replace(/\s+/g, ' ') + ' pass=' + pass;
      }
    }
  }
  return 'not-found';
})();
