'use strict';
(() => {
  const $ = id => document.getElementById(id);
  const stage = $('stage'), rows = $('rows'), template = $('quota-row');
  let state = null, rowViews = [], timer = null, revision = -1;
  let pressStarted = null, releaseTimer = null, pointerHeld = false;
  const format = (pattern, values) => values.reduce((s, v) => s.replace('%@', String(v)), pattern);
  function action(name) {
    const bridge = window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.widget;
    if (bridge) bridge.postMessage({action: name});
    else window.dispatchEvent(new CustomEvent('widget-action', {detail: name}));
  }
  function number(value, fallback = 0) { return typeof value === 'number' && Number.isFinite(value) ? value : fallback; }
  function pressOptions() {
    const speed = Math.max(.5, Math.min(3, number(state && state.pressSpeed, 1)));
    return {speed, immediate: !!(state && state.pressImmediate)};
  }
  function clearPress() {
    if (releaseTimer !== null) clearTimeout(releaseTimer);
    releaseTimer = null; pressStarted = null; pointerHeld = false;
    stage.classList.remove('pressed');
  }
  function press(down) {
    if (releaseTimer !== null) { clearTimeout(releaseTimer); releaseTimer = null; }
    if (down) {
      if (state && state.egg) return;
      pointerHeld = true; pressStarted = Date.now();
      stage.classList.add('pressed');
      return;
    }
    pointerHeld = false;
    if (pressStarted === null) return;
    const options = pressOptions();
    // A trackpad tap can deliver both events before a frame is painted. Keep
    // the pressed target long enough to reach it, then allow a full rebound.
    const attack = options.immediate ? 0 : 140 / options.speed;
    const visibleHold = Math.max(40, 50 / options.speed);
    const remaining = Math.max(0, pressStarted + attack + visibleHold - Date.now());
    if (remaining === 0) { clearPress(); return; }
    releaseTimer = setTimeout(() => {
      releaseTimer = null;
      if (!pointerHeld) clearPress();
    }, remaining);
  }
  function percentage(value) { return Number(value.toFixed(1)).toString() + '%'; }
  function updateClock() {
    if (!state || !state.bubble || state.message !== null) return;
    const now = Date.now(), labels = state.labels || {};
    const stale = state.stale || !Number.isFinite(state.observedAt) || now - state.observedAt > 180000 || now - state.observedAt < -5000;
    $('quota-title').textContent = state.title;
    $('stale').hidden = !stale || rowViews.length === 0;
    $('stale').textContent = labels.stale || '';
    rowViews.forEach(({view, window: w}) => {
      const remaining = Math.max(0, Math.min(100, number(w.remaining)));
      const expires = Number.isFinite(w.resetsAt) && w.resetsAt > 0;
      const elapsed = expires && w.resetsAt <= now;
      view.classList.toggle('expired', elapsed);
      view.classList.toggle('critical', !elapsed && remaining < 5);
      view.classList.toggle('warning', !elapsed && remaining >= 5 && remaining <= 25);
      view.querySelector('.percentage').textContent = elapsed ? '—' : percentage(remaining);
      view.querySelector('.fill').style.width = (elapsed ? 0 : remaining) + '%';
      let text = w.resetText;
      if (elapsed) text = labels.wait;
      else if (expires && w.resetsAt - now < 86400000) {
        const minutes = Math.max(1, Math.ceil((w.resetsAt - now) / 60000));
        text = minutes >= 60 ? format(labels.hours || '%@h %@m', [Math.floor(minutes / 60), minutes % 60])
          : format(labels.minutes || '%@m', [minutes]);
      }
      view.querySelector('.reset').textContent = text || '';
    });
  }
  function startClock() {
    if (timer) { clearInterval(timer); timer = null; }
    if (state && state.bubble && !state.egg && state.message === null && !document.hidden) {
      updateClock(); timer = setInterval(updateClock, 1000);
    }
  }
  function render(next) {
    if (!next || typeof next !== 'object') return;
    state = next;
    state.message = typeof next.message === 'string' ? next.message : null;
    const labels = state.labels || {};
    const pressConfig = pressOptions();
    stage.style.setProperty('--press-in', (pressConfig.immediate ? 0 : 140 / pressConfig.speed) + 'ms');
    stage.style.setProperty('--press-out', (200 / pressConfig.speed) + 'ms');
    stage.classList.toggle('bubble-open', !!state.bubble);
    stage.classList.toggle('is-low', !!state.low);
    const egg = ['squish', 'dance', 'zero'].includes(state.egg) ? state.egg : null;
    if (egg) clearPress();
    stage.classList.toggle('is-easter-egg', egg !== null);
    stage.classList.toggle('egg-squish', egg === 'squish');
    const eggLoops = Math.max(0, Math.min(10, Math.floor(number(state.eggLoops, 1))));
    stage.style.setProperty('--egg-iterations', eggLoops === 0 ? 'infinite' : String(eggLoops));
    const eggSource = (egg === 'zero' ? 'egg-zero.gif' : egg === 'dance' ? 'egg-dance.gif' : 'egg-squish.png') + '?revision=' + Math.max(0, Math.floor(number(state.eggGeneration, 0)));
    if ($('egg-portrait').getAttribute('src') !== eggSource) $('egg-portrait').setAttribute('src', eggSource);
    stage.classList.toggle('hide-menu', !!state.hideMenu);
    stage.classList.toggle('color-full', state.colorScope === 'full' && !state.completion);
    stage.classList.toggle('color-text', state.colorScope === 'text' && !state.completion);
    stage.classList.toggle('paused', !!state.colorPaused || !state.bubble);
    stage.style.setProperty('--mirror', state.mirrored ? '-1' : '1');
    stage.style.setProperty('--baseline', (Math.max(0, Math.min(1, number(state.characterBaseline, 1))) * 100) + '%');
    $('viewport').style.transform = 'scale(' + Math.max(.1, Math.min(2.5, number(state.scale, 1))) + ')';
    const palette = Array.isArray(state.palette) ? state.palette.filter(v => typeof v === 'string' && /^[0-9a-f]{6}$/i.test(v)) : [];
    stage.style.setProperty('--flow', 'linear-gradient(100deg,' + (palette.length > 1 ? palette.map(v => '#' + v).join(',') : '#745a98,#a28bc8') + ')');
    if (revision !== state.revision) {
      revision = Math.max(0, Math.floor(number(state.revision)));
      document.querySelector('.portrait.normal').src = 'normal.png?revision=' + revision;
      document.querySelector('.portrait.low').src = 'low.png?revision=' + revision;
    }
    stage.style.setProperty('--portrait', 'url("' + (state.low ? 'low' : 'normal') + '.png?revision=' + revision + '")');
    const hasMessage = state.message !== null;
    $('content').classList.toggle('has-message', hasMessage);
    $('message').hidden = !hasMessage; $('quota').hidden = hasMessage;
    $('message').textContent = state.message || '';
    $('message').classList.toggle('long', (state.message || '').length > 35);
    $('message').classList.toggle('very-long', (state.message || '').length > 85);
    let quoteSize = (state.message || '').length > 85 ? 13 : (state.message || '').length > 35 ? 17 : 23;
    $('message').style.fontSize = quoteSize + 'px';
    while (hasMessage && $('message').scrollHeight > 124 && quoteSize > 9) {
      $('message').style.fontSize = (--quoteSize) + 'px';
    }
    $('character').setAttribute('aria-label', labels.character || '');
    $('settings').setAttribute('aria-label', labels.settings || '');
    $('refresh').setAttribute('aria-label', labels.refresh || '');
    $('refresh').disabled = !!state.refreshing;
    const windows = Array.isArray(state.windows) ? state.windows.slice(0, 2) : [];
    stage.classList.toggle('single-window', windows.length === 1);
    while (rows.children.length > windows.length) rows.lastElementChild.remove();
    while (rows.children.length < windows.length) rows.append(template.content.cloneNode(true));
    rowViews = windows.map((w, index) => {
      const view = rows.children[index];
      view.querySelector('.window-title').textContent = w.title || '';
      return {view, window: w};
    });
    $('error').textContent = state.error || '';
    $('error').hidden = windows.length > 0;
    $('quota').title = state.plan || '';
    startClock();
  }
  $('character').addEventListener('click', () => action('character'));
  $('character').addEventListener('pointerdown', () => press(true));
  document.addEventListener('pointerup', () => press(false));
  document.addEventListener('pointercancel', clearPress);
  $('character').addEventListener('pointerenter', () => stage.classList.add('hovered'));
  $('stage').addEventListener('pointerleave', () => stage.classList.remove('hovered'));
  $('settings').addEventListener('click', () => action('settings'));
  $('refresh').addEventListener('click', event => { event.stopPropagation(); action('refresh'); });
  $('quota').addEventListener('click', event => { if (!event.target.closest('#refresh')) action('bubble'); });
  $('message').addEventListener('click', () => action('bubble'));
  document.querySelectorAll('.cloud,.thought').forEach(view => view.addEventListener('click', () => action('bubble')));
  document.addEventListener('visibilitychange', () => { if (document.hidden) clearPress(); startClock(); });
  window.GPTNiang = Object.freeze({
    render,
    press,
    hover: value => stage.classList.toggle('hovered', !!value)
  });
  action('ready');
})();
