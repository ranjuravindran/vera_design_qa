/* ============================================================
   VERA — Official Landing Page Interactive Motion & Shader Engine
   ============================================================ */

(function () {
  'use strict';

  var reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* ================= 1. AMBIENT SHADER CANVAS ================= */
  var canvas = document.getElementById('ambientCanvas');
  if (canvas && !reducedMotion) {
    var ctx = canvas.getContext('2d');
    var width, height, dpr;
    var particles = [];
    var particleCount = 42;
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
          vx: (Math.random() - 0.5) * 0.45,
          vy: (Math.random() - 0.5) * 0.45,
          radius: Math.random() * 2 + 1,
          color: Math.random() > 0.3 ? 'rgba(0, 157, 255,' : 'rgba(245, 158, 11,',
          alpha: Math.random() * 0.4 + 0.15,
          pulseSpeed: Math.random() * 0.02 + 0.005,
          pulseAngle: Math.random() * Math.PI * 2
        });
      }
    }

    function renderShader() {
      if (!isVisible) return;

      ctx.clearRect(0, 0, width, height);

      // Smooth mouse interpolation
      mouse.x += (mouse.targetX - mouse.x) * 0.08;
      mouse.y += (mouse.targetY - mouse.y) * 0.08;

      // Draw subtle ambient glow near mouse
      if (mouse.x > 0 && mouse.y > 0) {
        var gradient = ctx.createRadialGradient(mouse.x, mouse.y, 0, mouse.x, mouse.y, 350);
        gradient.addColorStop(0, 'rgba(0, 157, 255, 0.06)');
        gradient.addColorStop(1, 'rgba(0, 157, 255, 0)');
        ctx.fillStyle = gradient;
        ctx.fillRect(0, 0, width, height);
      }

      // Update and draw particles
      for (var i = 0; i < particles.length; i++) {
        var p = particles[i];

        p.x += p.vx;
        p.y += p.vy;

        if (p.x < 0) p.x = width;
        if (p.x > width) p.x = 0;
        if (p.y < 0) p.y = height;
        if (p.y > height) p.y = 0;

        p.pulseAngle += p.pulseSpeed;
        var currentAlpha = p.alpha + Math.sin(p.pulseAngle) * 0.15;
        currentAlpha = Math.max(0.05, Math.min(0.65, currentAlpha));

        ctx.beginPath();
        ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
        ctx.fillStyle = p.color + currentAlpha + ')';
        ctx.fill();

        // Connect nearby nodes
        for (var j = i + 1; j < particles.length; j++) {
          var p2 = particles[j];
          var dx = p.x - p2.x;
          var dy = p.y - p2.y;
          var dist = Math.sqrt(dx * dx + dy * dy);

          if (dist < 130) {
            ctx.beginPath();
            ctx.moveTo(p.x, p.y);
            ctx.lineTo(p2.x, p2.y);
            var lineAlpha = (1 - dist / 130) * 0.12;
            ctx.strokeStyle = 'rgba(0, 157, 255, ' + lineAlpha + ')';
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

  /* ================= 2. 3D CARD TILT & SPOTLIGHT ================= */
  var tiltCards = document.querySelectorAll('.tilt-card');
  if (tiltCards.length && !reducedMotion && window.matchMedia('(pointer: fine)').matches) {
    tiltCards.forEach(function (card) {
      var maxTilt = parseFloat(card.getAttribute('data-tilt')) || 4;

      card.addEventListener('mousemove', function (e) {
        var rect = card.getBoundingClientRect();
        var x = e.clientX - rect.left;
        var y = e.clientY - rect.top;
        var centerX = rect.width / 2;
        var centerY = rect.height / 2;

        var rotateX = ((y - centerY) / centerY) * -maxTilt;
        var rotateY = ((x - centerX) / centerX) * maxTilt;

        card.style.transform = 'perspective(1000px) rotateX(' + rotateX.toFixed(2) + 'deg) rotateY(' + rotateY.toFixed(2) + 'deg) translateY(-3px)';
      });

      card.addEventListener('mouseleave', function () {
        card.style.transform = '';
      });
    });
  }

  /* ================= 3. MAGNETIC BUTTONS ================= */
  var magneticBtns = document.querySelectorAll('.magnetic-btn');
  if (magneticBtns.length && !reducedMotion && window.matchMedia('(pointer: fine)').matches) {
    magneticBtns.forEach(function (btn) {
      btn.addEventListener('mousemove', function (e) {
        var rect = btn.getBoundingClientRect();
        var x = e.clientX - rect.left - rect.width / 2;
        var y = e.clientY - rect.top - rect.height / 2;
        btn.style.transform = 'translate(' + (x * 0.18).toFixed(1) + 'px, ' + (y * 0.18).toFixed(1) + 'px)';
      });

      btn.addEventListener('mouseleave', function () {
        btn.style.transform = '';
      });
    });
  }

  /* ================= 4. SHOWCASE TABS ================= */
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

  /* ================= 5. DIFFERENCE SLIDER ================= */
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

  /* ================= 6. TERMINAL SNIPPET COPY ================= */
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

  /* ================= 7. HEADER SHADOW ON SCROLL & ACTIVE SPY ================= */
  var header = document.getElementById('header');
  var navLinks = document.querySelectorAll('.site-nav .nav-link');
  var sections = document.querySelectorAll('section[id], div[id="showcase"]');

  if (header) {
    window.addEventListener('scroll', function () {
      if (window.scrollY > 20) {
        header.style.borderBottomColor = 'rgba(255, 255, 255, 0.12)';
        header.style.boxShadow = '0 10px 30px rgba(0, 0, 0, 0.5)';
      } else {
        header.style.borderBottomColor = 'var(--border-subtle)';
        header.style.boxShadow = 'none';
      }

      // Scroll Spy for Nav links
      var scrollPos = window.scrollY + 120;
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
