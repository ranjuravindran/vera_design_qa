/* Vera — site behaviour.
   Three things only: the difference layer, the video, the copy button. */

(function () {
  'use strict';

  var reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* ---------- the difference layer ---------- */
  var range = document.getElementById('diffRange');
  var out = document.getElementById('diffOut');
  var stage = document.querySelector('.diff-stage');

  function setDiff(v) {
    stage.style.setProperty('--diff', v / 100);
    range.style.setProperty('--pct', v + '%');
    out.textContent = Math.round(v) + '%';
  }

  if (range && stage && out) {
    setDiff(range.value);
    range.addEventListener('input', function () { setDiff(this.value); });

    /* One deliberate motion moment: on first view, sweep the blend up and
       settle, so it's obvious the control does something. Runs once. */
    if (!reduced && 'IntersectionObserver' in window) {
      var played = false;
      var demo = new IntersectionObserver(function (entries) {
        entries.forEach(function (e) {
          if (!e.isIntersecting || played) return;
          played = true;
          demo.disconnect();

          var start = null;
          var from = 35, peak = 100, end = 45, dur = 1900;

          function frame(t) {
            if (start === null) start = t;
            var p = Math.min((t - start) / dur, 1);
            // ease out to peak across the first 55%, then settle back
            var v;
            if (p < 0.55) {
              var a = p / 0.55;
              v = from + (peak - from) * (1 - Math.pow(1 - a, 3));
            } else {
              var b = (p - 0.55) / 0.45;
              v = peak + (end - peak) * (1 - Math.pow(1 - b, 3));
            }
            setDiff(v);
            range.value = v;
            if (p < 1) requestAnimationFrame(frame);
          }
          requestAnimationFrame(frame);
        });
      }, { threshold: 0.45 });
      demo.observe(stage);
    }
  }

  /* ---------- video ---------- */
  var player = document.getElementById('player');
  var video = document.getElementById('demoVideo');
  var playBtn = document.getElementById('playBtn');
  var note = document.getElementById('demoNote');

  if (player && video && playBtn) {
    /* Controls are added only once playback starts, so the resting state is a
       clean poster + one affordance rather than a poster wearing a dead
       scrubber. preload stays "none" until the user actually asks for it. */
    playBtn.addEventListener('click', function () {
      player.classList.add('is-playing');
      video.preload = 'auto';
      video.controls = true;
      video.play().catch(function () {
        /* playback refused — leave the native controls for the user */
      });
    });

    video.addEventListener('error', showPosterOnly);

    /* preload="none" means a missing file is never discovered on its own.
       One HEAD request (no body) keeps the page honest at rest. */
    if (window.fetch) {
      fetch(video.getAttribute('src'), { method: 'HEAD' })
        .then(function (r) { if (!r.ok) showPosterOnly(); })
        .catch(showPosterOnly);
    }

    function showPosterOnly() {
      playBtn.style.display = 'none';
      video.controls = false;
      if (note) note.textContent = 'Demo video landing shortly';
    }
  }

  /* ---------- copy the install command ---------- */
  var copyBtn = document.getElementById('copyBtn');
  if (copyBtn && navigator.clipboard) {
    copyBtn.addEventListener('click', function () {
      var code = copyBtn.previousElementSibling.innerText
        .split('\n')
        .filter(function (l) { return l.trim() && l.trim()[0] !== '#'; })
        .join('\n');
      navigator.clipboard.writeText(code).then(function () {
        copyBtn.textContent = 'Copied';
        setTimeout(function () { copyBtn.textContent = 'Copy'; }, 1600);
      });
    });
  } else if (copyBtn) {
    copyBtn.hidden = true;
  }

})();
