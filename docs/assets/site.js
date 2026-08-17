/* ============================================================
   VERA — Official Landing Page Interactive Logic
   ============================================================ */

(function () {
  'use strict';

  var reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* ================= 1. SHOWCASE TABS ================= */
  var tabButtons = document.querySelectorAll('.tab-btn');
  var tabPanels = document.querySelectorAll('.tab-panel');
  var windowTitle = document.getElementById('windowTitle');

  var titles = {
    'tab-inspect': 'Vera Canvas — Inspect & Property Tuning',
    'tab-diff': 'Vera Canvas — Figma Difference Blend Mode',
    'tab-tokens': 'Vera Canvas — Design System Token Linting',
    'tab-route': 'Vera Canvas — Route Jumper & Deep-Linking',
    'tab-export': 'Vera Companion — Live AST Patch Exporter'
  };

  if (tabButtons.length && tabPanels.length) {
    tabButtons.forEach(function (button) {
      button.addEventListener('click', function () {
        var targetId = this.getAttribute('data-target');

        // Deactivate all
        tabButtons.forEach(function (btn) {
          btn.classList.remove('is-active');
          btn.setAttribute('aria-selected', 'false');
        });
        tabPanels.forEach(function (panel) {
          panel.classList.remove('is-active');
        });

        // Activate selected
        this.classList.add('is-active');
        this.setAttribute('aria-selected', 'true');

        var activePanel = document.getElementById(targetId);
        if (activePanel) {
          activePanel.classList.add('is-active');
        }

        // Update window title
        if (windowTitle && titles[targetId]) {
          windowTitle.textContent = titles[targetId];
        }
      });
    });
  }

  /* ================= 2. DIFFERENCE SLIDER ================= */
  var diffSlider = document.getElementById('diffSlider');
  var diffPercent = document.getElementById('diffPercent');
  var diffStage = document.getElementById('diffStage');

  function updateDiff(value) {
    if (!diffStage || !diffSlider) return;
    diffStage.style.setProperty('--diff', value / 100);
    diffSlider.style.setProperty('--pct', value + '%');
    if (diffPercent) {
      diffPercent.textContent = Math.round(value) + '%';
    }
  }

  if (diffSlider && diffStage) {
    updateDiff(diffSlider.value);

    diffSlider.addEventListener('input', function () {
      updateDiff(this.value);
    });

    // Gentle auto-sweep animation on first view
    if (!reducedMotion && 'IntersectionObserver' in window) {
      var hasSwept = false;
      var observer = new IntersectionObserver(function (entries) {
        entries.forEach(function (entry) {
          if (!entry.isIntersecting || hasSwept) return;
          hasSwept = true;
          observer.disconnect();

          var start = null;
          var fromVal = 40, peakVal = 100, endVal = 50, duration = 1600;

          function animateSweep(timestamp) {
            if (start === null) start = timestamp;
            var progress = Math.min((timestamp - start) / duration, 1);
            var current;

            if (progress < 0.5) {
              var a = progress / 0.5;
              current = fromVal + (peakVal - fromVal) * (1 - Math.pow(1 - a, 3));
            } else {
              var b = (progress - 0.5) / 0.5;
              current = peakVal + (endVal - peakVal) * (1 - Math.pow(1 - b, 3));
            }

            updateDiff(current);
            diffSlider.value = current;

            if (progress < 1) {
              requestAnimationFrame(animateSweep);
            }
          }

          requestAnimationFrame(animateSweep);
        });
      }, { threshold: 0.4 });

      observer.observe(diffStage);
    }
  }

  /* ================= 3. TERMINAL SNIPPET COPY ================= */
  var copyBtn = document.getElementById('copySnippetBtn');
  var copyText = document.getElementById('copyText');
  var snippetElem = document.getElementById('codeSnippet');

  if (copyBtn && snippetElem && navigator.clipboard) {
    copyBtn.addEventListener('click', function () {
      // Extract clean commands without comments
      var lines = snippetElem.innerText.split('\n');
      var cleanCommands = lines
        .filter(function (line) {
          var trimmed = line.trim();
          return trimmed.length > 0 && !trimmed.startsWith('#');
        })
        .join('\n');

      navigator.clipboard.writeText(cleanCommands).then(function () {
        if (copyText) copyText.textContent = '✓ Copied!';
        copyBtn.style.borderColor = 'var(--emerald)';
        copyBtn.style.color = 'var(--emerald)';

        setTimeout(function () {
          if (copyText) copyText.textContent = 'Copy Commands';
          copyBtn.style.borderColor = '';
          copyBtn.style.color = '';
        }, 2200);
      }).catch(function () {
        // Fallback for clipboard permissions failure
        var rawText = snippetElem.innerText;
        navigator.clipboard.writeText(rawText);
      });
    });
  }

  /* ================= 4. HEADER SHADOW ON SCROLL ================= */
  var header = document.getElementById('header');
  if (header) {
    window.addEventListener('scroll', function () {
      if (window.scrollY > 20) {
        header.style.borderBottomColor = 'rgba(255, 255, 255, 0.12)';
        header.style.boxShadow = '0 10px 30px rgba(0, 0, 0, 0.5)';
      } else {
        header.style.borderBottomColor = 'var(--border-subtle)';
        header.style.boxShadow = 'none';
      }
    }, { passive: true });
  }

})();
