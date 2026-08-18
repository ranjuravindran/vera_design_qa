/* ============================================================
   VERA — Official Interactive Logic & Dynamic 3D Physics
   ============================================================ */

(function () {
  'use strict';

  var reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var root = document.documentElement;
  var themeMeta = document.getElementById('themeColorMeta');

  /* ================= 1. THEME TOGGLE ENGINE ================= */
  var themeToggleBtn = document.getElementById('themeToggle');

  function getPreferredTheme() {
    var stored = localStorage.getItem('vera-theme');
    if (stored) return stored;
    return 'dark'; // Always default to dark mode
  }

  function applyTheme(theme) {
    root.setAttribute('data-theme', theme);
    localStorage.setItem('vera-theme', theme);
    if (themeMeta) {
      themeMeta.setAttribute('content', theme === 'dark' ? '#080d1a' : '#f8fafc');
    }
  }

  // Initialize theme immediately
  var currentTheme = getPreferredTheme();
  applyTheme(currentTheme);

  if (themeToggleBtn) {
    themeToggleBtn.addEventListener('click', function () {
      var nextTheme = root.getAttribute('data-theme') === 'dark' ? 'light' : 'dark';
      applyTheme(nextTheme);
    });
  }

  /* ================= 2. AMBIENT SHADER CANVAS ================= */
  var canvas = document.getElementById('ambientCanvas');
  if (canvas && !reducedMotion) {
    var ctx = canvas.getContext('2d');
    var width, height, dpr;
    var particles = [];
    var particleCount = 36;
    var mouse = { x: -1000, y: -1000, targetX: -1000, targetY: -1000 };
    var isVisible = true;

    function resizeCanvas() {
      dpr = Math.min(window.devicePixelRatio || 1, 2);
      width = window.innerWidth;
      height = window.innerHeight;
      canvas.width = width * dpr;
      canvas.height = height * dpr;
      ctx.scale(dpr, dpr);
    }

    function initParticles() {
      particles = [];
      for (var i = 0; i < particleCount; i++) {
        particles.push({
          x: Math.random() * width,
          y: Math.random() * height,
          vx: (Math.random() - 0.5) * 0.4,
          vy: (Math.random() - 0.5) * 0.4,
          radius: Math.random() * 2 + 1.2,
          baseAlpha: Math.random() * 0.35 + 0.15,
          colorType: Math.random() > 0.4 ? 'sky' : 'gold'
        });
      }
    }

    resizeCanvas();
    initParticles();

    window.addEventListener('resize', function () {
      resizeCanvas();
      initParticles();
    }, { passive: true });

    window.addEventListener('mousemove', function (e) {
      mouse.targetX = e.clientX;
      mouse.targetY = e.clientY;
    }, { passive: true });

    document.addEventListener('visibilitychange', function () {
      isVisible = !document.hidden;
      if (isVisible) requestAnimationFrame(render);
    });

    function render() {
      if (!isVisible) return;

      mouse.x += (mouse.targetX - mouse.x) * 0.08;
      mouse.y += (mouse.targetY - mouse.y) * 0.08;

      ctx.clearRect(0, 0, width, height);

      var isDark = root.getAttribute('data-theme') !== 'light';
      var skyColor = isDark ? 'rgba(56, 189, 248,' : 'rgba(2, 132, 199,';
      var goldColor = 'rgba(245, 136, 5,';

      // Mouse interactive ambient field
      if (mouse.x > 0 && mouse.y > 0) {
        var grad = ctx.createRadialGradient(mouse.x, mouse.y, 10, mouse.x, mouse.y, 320);
        grad.addColorStop(0, isDark ? 'rgba(56, 189, 248, 0.08)' : 'rgba(2, 132, 199, 0.05)');
        grad.addColorStop(1, 'rgba(0, 0, 0, 0)');
        ctx.fillStyle = grad;
        ctx.fillRect(0, 0, width, height);
      }

      // Draw particle constellation
      for (var i = 0; i < particles.length; i++) {
        var p = particles[i];
        p.x += p.vx;
        p.y += p.vy;

        if (p.x < -10) p.x = width + 10;
        if (p.x > width + 10) p.x = -10;
        if (p.y < -10) p.y = height + 10;
        if (p.y > height + 10) p.y = -10;

        var colorPrefix = p.colorType === 'sky' ? skyColor : goldColor;
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
        ctx.fillStyle = colorPrefix + p.baseAlpha + ')';
        ctx.fill();

        for (var j = i + 1; j < particles.length; j++) {
          var p2 = particles[j];
          var dx = p.x - p2.x;
          var dy = p.y - p2.y;
          var dist = Math.sqrt(dx * dx + dy * dy);

          if (dist < 120) {
            var alpha = (1 - dist / 120) * 0.14;
            ctx.beginPath();
            ctx.moveTo(p.x, p.y);
            ctx.lineTo(p2.x, p2.y);
            ctx.strokeStyle = skyColor + alpha + ')';
            ctx.lineWidth = 0.75;
            ctx.stroke();
          }
        }
      }

      requestAnimationFrame(render);
    }

    requestAnimationFrame(render);
  }

  /* ================= 3. DYNAMIC 3D PERSPECTIVE TILT & REALISTIC SHADOW ================= */
  if (!reducedMotion) {
    var tiltCards = document.querySelectorAll('.tilt-card');
    tiltCards.forEach(function (card) {
      var maxTilt = parseFloat(card.getAttribute('data-tilt')) || 3.5;

      card.addEventListener('mousemove', function (e) {
        var rect = card.getBoundingClientRect();
        var x = e.clientX - rect.left;
        var y = e.clientY - rect.top;
        var centerX = rect.width / 2;
        var centerY = rect.height / 2;

        var rotateX = ((y - centerY) / centerY) * -maxTilt;
        var rotateY = ((x - centerX) / centerX) * maxTilt;

        // Dynamic solid 3D shadow strictly matching the element's exact computed stroke/border color
        var shadowOffsetX = (-rotateY * 1.5).toFixed(0);
        var shadowOffsetY = (rotateX * 1.5 + 4).toFixed(0);
        var computedStyle = window.getComputedStyle(card);
        var strokeColor = computedStyle.borderTopColor || computedStyle.borderColor;

        card.style.transform = 'perspective(1000px) rotateX(' + rotateX.toFixed(2) + 'deg) rotateY(' + rotateY.toFixed(2) + 'deg) translateY(-2px)';
        card.style.boxShadow = shadowOffsetX + 'px ' + shadowOffsetY + 'px 0 ' + strokeColor;
      });

      card.addEventListener('mouseleave', function () {
        card.style.transform = 'perspective(1000px) rotateX(0deg) rotateY(0deg) translateY(0)';
        card.style.boxShadow = '';
      });
    });
  }

  /* ================= 4. MAGNETIC BUTTONS ================= */
  if (!reducedMotion) {
    var magneticBtns = document.querySelectorAll('.magnetic-btn');
    magneticBtns.forEach(function (btn) {
      btn.addEventListener('mousemove', function (e) {
        var rect = btn.getBoundingClientRect();
        var x = e.clientX - rect.left - rect.width / 2;
        var y = e.clientY - rect.top - rect.height / 2;
        btn.style.transform = 'translate(' + (x * 0.16).toFixed(1) + 'px, ' + (y * 0.16).toFixed(1) + 'px)';
      });

      btn.addEventListener('mouseleave', function () {
        btn.style.transform = 'translate(0, 0)';
      });
    });
  }

  /* ================= 5. HERO SHOWCASE TABS ================= */
  var tabButtons = document.querySelectorAll('.showcase-tabs .tab-btn');
  var tabPanels = document.querySelectorAll('.window-body .tab-panel');

  tabButtons.forEach(function (btn) {
    btn.addEventListener('click', function () {
      var targetId = btn.getAttribute('data-target');
      if (!targetId) return;

      tabButtons.forEach(function (b) {
        b.classList.remove('is-active');
        b.setAttribute('aria-selected', 'false');
      });
      tabPanels.forEach(function (p) {
        p.classList.remove('is-active');
      });

      btn.classList.add('is-active');
      btn.setAttribute('aria-selected', 'true');

      var targetPanel = document.getElementById(targetId);
      if (targetPanel) {
        targetPanel.classList.add('is-active');
      }
    });
  });

  /* ================= 6. INTERACTIVE FEATURE SPOTLIGHT TABS ================= */
  var featureBtns = document.querySelectorAll('.feature-item-btn');
  var featurePanels = document.querySelectorAll('.feature-panel');

  featureBtns.forEach(function (btn) {
    btn.addEventListener('click', function () {
      var targetFeature = btn.getAttribute('data-feature');
      if (!targetFeature) return;

      featureBtns.forEach(function (b) {
        b.classList.remove('is-active');
        b.setAttribute('aria-selected', 'false');
      });
      featurePanels.forEach(function (p) {
        p.classList.remove('is-active');
      });

      btn.classList.add('is-active');
      btn.setAttribute('aria-selected', 'true');

      var targetPanel = document.getElementById(targetFeature);
      if (targetPanel) {
        targetPanel.classList.add('is-active');
      }
    });
  });

  /* ================= 7. FIGMA DIFFERENCE SLIDER ================= */
  var diffSlider = document.getElementById('diffSlider');
  var diffPercent = document.getElementById('diffPercent');
  var diffStage = document.getElementById('diffStage');

  if (diffSlider && diffStage) {
    function updateDiff() {
      var val = diffSlider.value;
      diffStage.style.setProperty('--diff', (val / 100).toFixed(2));
      diffSlider.style.setProperty('--pct', val + '%');
      if (diffPercent) diffPercent.textContent = val + '%';
    }

    diffSlider.addEventListener('input', updateDiff);
    updateDiff();

    if ('IntersectionObserver' in window && !reducedMotion) {
      var diffAnimated = false;
      var observer = new IntersectionObserver(function (entries) {
        entries.forEach(function (entry) {
          if (!entry.isIntersecting || diffAnimated) return;
          diffAnimated = true;
          observer.disconnect();

          var start = 15;
          var end = 65;
          var duration = 1200;
          var startTime = null;

          function animateSweep(ts) {
            if (!startTime) startTime = ts;
            var progress = Math.min((ts - startTime) / duration, 1);
            var current = start + (end - start) * Math.sin(progress * Math.PI);
            diffSlider.value = Math.round(current);
            updateDiff();

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

  /* ================= 8. TERMINAL SNIPPET COPY ================= */
  var copyBtn = document.getElementById('copySnippetBtn');
  var copyText = document.getElementById('copyText');
  var snippetElem = document.getElementById('codeSnippet');

  if (copyBtn && snippetElem && navigator.clipboard) {
    copyBtn.addEventListener('click', function () {
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
        var rawText = snippetElem.innerText;
        navigator.clipboard.writeText(rawText);
      });
    });
  }

  /* ================= 9. ACTIVE NAV SCROLLSPY (Solid Fill Squircle) ================= */
  var header = document.getElementById('header');
  var navLinks = document.querySelectorAll('.site-nav .nav-link');
  var sections = document.querySelectorAll('section[id]');

  function updateNavSpy() {
    var scrollPos = window.scrollY + 140;
    var currentId = '';

    sections.forEach(function (section) {
      var top = section.offsetTop;
      var height = section.offsetHeight;
      if (scrollPos >= top && scrollPos < top + height) {
        currentId = section.getAttribute('id');
      }
    });

    if (currentId) {
      navLinks.forEach(function (link) {
        var href = link.getAttribute('href');
        if (href === '#' + currentId) {
          link.classList.add('is-active');
          link.setAttribute('aria-current', 'page');
        } else {
          link.classList.remove('is-active');
          link.removeAttribute('aria-current');
        }
      });
    }
  }

  window.addEventListener('scroll', updateNavSpy, { passive: true });
  updateNavSpy();

})();
