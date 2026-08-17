/* ============================================================
   VERA — Official Interactive Logic, Theme Engine & Shader
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
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }

  function applyTheme(theme) {
    root.setAttribute('data-theme', theme);
    localStorage.setItem('vera-theme', theme);
    if (themeMeta) {
      themeMeta.setAttribute('content', theme === 'dark' ? '#060a14' : '#f4f6fa');
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

  // Listen for OS system theme changes
  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', function (e) {
    if (!localStorage.getItem('vera-theme')) {
      applyTheme(e.matches ? 'dark' : 'light');
    }
  });

  /* ================= 2. AMBIENT SHADER CANVAS ================= */
  var canvas = document.getElementById('ambientCanvas');
  if (canvas && !reducedMotion) {
    var ctx = canvas.getContext('2d');
    var width, height, dpr;
    var particles = [];
    var particleCount = 38;
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
          radius: Math.random() * 2 + 1,
          isCyan: Math.random() > 0.35,
          alpha: Math.random() * 0.35 + 0.15,
          pulseSpeed: Math.random() * 0.02 + 0.005,
          pulseAngle: Math.random() * Math.PI * 2
        });
      }
    }

    function renderShader() {
      if (!isVisible) return;

      ctx.clearRect(0, 0, width, height);

      var isDark = root.getAttribute('data-theme') === 'dark';
      var cyanPrefix = isDark ? 'rgba(0, 157, 255,' : 'rgba(0, 136, 223,';
      var amberPrefix = isDark ? 'rgba(245, 158, 11,' : 'rgba(217, 119, 6,';

      // Mouse glow
      if (mouse.x > 0 && mouse.y > 0) {
        var glowAlpha = isDark ? '0.06' : '0.04';
        var gradient = ctx.createRadialGradient(mouse.x, mouse.y, 0, mouse.x, mouse.y, 300);
        gradient.addColorStop(0, cyanPrefix + glowAlpha + ')');
        gradient.addColorStop(1, cyanPrefix + '0)');
        ctx.fillStyle = gradient;
        ctx.fillRect(0, 0, width, height);
      }

      // Smooth mouse tracking
      mouse.x += (mouse.targetX - mouse.x) * 0.08;
      mouse.y += (mouse.targetY - mouse.y) * 0.08;

      // Update & Draw particles
      for (var i = 0; i < particles.length; i++) {
        var p = particles[i];

        p.x += p.vx;
        p.y += p.vy;

        if (p.x < 0) p.x = width;
        if (p.x > width) p.x = 0;
        if (p.y < 0) p.y = height;
        if (p.y > height) p.y = 0;

        p.pulseAngle += p.pulseSpeed;
        var currentAlpha = p.alpha + Math.sin(p.pulseAngle) * 0.12;
        currentAlpha = Math.max(0.05, Math.min(0.6, currentAlpha));

        ctx.beginPath();
        ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
        ctx.fillStyle = (p.isCyan ? cyanPrefix : amberPrefix) + currentAlpha + ')';
        ctx.fill();

        for (var j = i + 1; j < particles.length; j++) {
          var p2 = particles[j];
          var dx = p.x - p2.x;
          var dy = p.y - p2.y;
          var dist = Math.sqrt(dx * dx + dy * dy);

          if (dist < 120) {
            ctx.beginPath();
            ctx.moveTo(p.x, p.y);
            ctx.lineTo(p2.x, p2.y);
            var lineAlpha = (1 - dist / 120) * (isDark ? 0.1 : 0.06);
            ctx.strokeStyle = cyanPrefix + lineAlpha + ')';
            ctx.lineWidth = 0.75;
            ctx.stroke();
          }
        }
      }

      requestAnimationFrame(renderShader);
    }

    resizeCanvas();
    initParticles();
    renderShader();

    window.addEventListener('resize', function () {
      resizeCanvas();
      initParticles();
    }, { passive: true });

    window.addEventListener('pointermove', function (e) {
      mouse.targetX = e.clientX;
      mouse.targetY = e.clientY;
    }, { passive: true });

    document.addEventListener('visibilitychange', function () {
      isVisible = !document.hidden;
      if (isVisible) renderShader();
    });
  }

  /* ================= 3. 3D CARD TILT ================= */
  var tiltCards = document.querySelectorAll('.tilt-card');
  if (tiltCards.length && !reducedMotion && window.matchMedia('(pointer: fine)').matches) {
    tiltCards.forEach(function (card) {
      var maxTilt = parseFloat(card.getAttribute('data-tilt')) || 3;

      card.addEventListener('mousemove', function (e) {
        var rect = card.getBoundingClientRect();
        var x = e.clientX - rect.left;
        var y = e.clientY - rect.top;
        var centerX = rect.width / 2;
        var centerY = rect.height / 2;

        var rotateX = ((y - centerY) / centerY) * -maxTilt;
        var rotateY = ((x - centerX) / centerX) * maxTilt;

        card.style.transform = 'perspective(1000px) rotateX(' + rotateX.toFixed(2) + 'deg) rotateY(' + rotateY.toFixed(2) + 'deg) translateY(-2px)';
      });

      card.addEventListener('mouseleave', function () {
        card.style.transform = '';
      });
    });
  }

  /* ================= 4. MAGNETIC BUTTONS ================= */
  var magneticBtns = document.querySelectorAll('.magnetic-btn');
  if (magneticBtns.length && !reducedMotion && window.matchMedia('(pointer: fine)').matches) {
    magneticBtns.forEach(function (btn) {
      btn.addEventListener('mousemove', function (e) {
        var rect = btn.getBoundingClientRect();
        var x = e.clientX - rect.left - rect.width / 2;
        var y = e.clientY - rect.top - rect.height / 2;
        btn.style.transform = 'translate(' + (x * 0.15).toFixed(1) + 'px, ' + (y * 0.15).toFixed(1) + 'px)';
      });

      btn.addEventListener('mouseleave', function () {
        btn.style.transform = '';
      });
    });
  }

  /* ================= 5. SHOWCASE TABS ================= */
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

        tabButtons.forEach(function (btn) {
          btn.classList.remove('is-active');
          btn.setAttribute('aria-selected', 'false');
        });
        tabPanels.forEach(function (panel) {
          panel.classList.remove('is-active');
        });

        this.classList.add('is-active');
        this.setAttribute('aria-selected', 'true');

        var activePanel = document.getElementById(targetId);
        if (activePanel) {
          activePanel.classList.add('is-active');
        }

        if (windowTitle && titles[targetId]) {
          windowTitle.textContent = titles[targetId];
        }
      });
    });
  }

  /* ================= 6. DIFFERENCE SLIDER ================= */
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

    if (!reducedMotion && 'IntersectionObserver' in window) {
      var hasSwept = false;
      var observer = new IntersectionObserver(function (entries) {
        entries.forEach(function (entry) {
          if (!entry.isIntersecting || hasSwept) return;
          hasSwept = true;
          observer.disconnect();

          var start = null;
          var fromVal = 40, peakVal = 100, endVal = 50, duration = 1500;

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

  /* ================= 7. TERMINAL SNIPPET COPY ================= */
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

  /* ================= 8. HEADER SHADOW & ACTIVE NAV SPY ================= */
  var header = document.getElementById('header');
  var navLinks = document.querySelectorAll('.site-nav .nav-link');
  var sections = document.querySelectorAll('section[id]');

  if (header) {
    window.addEventListener('scroll', function () {
      if (window.scrollY > 20) {
        header.style.boxShadow = 'var(--shadow-subtle)';
      } else {
        header.style.boxShadow = 'none';
      }

      var scrollPos = window.scrollY + 100;
      sections.forEach(function (section) {
        var top = section.offsetTop;
        var height = section.offsetHeight;
        var id = section.getAttribute('id');
        if (scrollPos >= top && scrollPos < top + height) {
          navLinks.forEach(function (link) {
            if (link.getAttribute('href') === '#' + id) {
              link.classList.add('is-active');
            } else {
              link.classList.remove('is-active');
            }
          });
        }
      });
    }, { passive: true });
  }

})();
