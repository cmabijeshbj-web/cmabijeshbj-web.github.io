/* =========================================================================
   site.js — Bijesh BJ Portfolio
   Single source of truth for the header/nav and footer. Edit the NAV_ITEMS
   list below to add, remove, or rename a page in the menu — every page on
   the site will pick up the change automatically (no need to edit each
   HTML file individually).
   ========================================================================= */

// ---- 1. EDIT THIS LIST to add/remove/rename nav links ----
var NAV_ITEMS = [
  { href: "index.html",            label: "Home" },
  { href: "about.html",            label: "About" },
  { href: "experience.html",       label: "Experience" },
  { href: "projects.html",         label: "Projects" },
  { href: "certifications.html",   label: "Education & Certs" },
  { href: "resume.html",           label: "Resume" },
  { href: "contact.html",          label: "Contact" }
];

var SITE_NAME = "Bijesh BJ, CMA (USA)";
var SITE_LEDGER_TAG = "FP&A · SAP FICO · UAE VAT &amp; CT";
var FOOTER_TAGLINE = "Every number tells a story. I turn financial data into insight.";
var FOOTER_EMAIL = "cmabijeshbj@gmail.com";
var FOOTER_SITE_URL = "https://cmabijeshbj-web.github.io/";

// ---- 2. Everything below this line is plumbing — no need to edit it ----
(function () {
  // Dark theme is default; only set the attribute when the visitor chose "light".
  var root = document.documentElement;
  var stored = localStorage.getItem('bijesh-portfolio-theme');
  if (stored === 'light') root.setAttribute('data-theme', 'light');

  function currentDepth() {
    return window.location.pathname.indexOf('/projects/') !== -1 ? '../' : '';
  }

  function currentActiveHref() {
    var path = window.location.pathname;
    if (path.indexOf('/projects/') !== -1) return 'projects.html';
    var last = path.split('/').pop();
    if (!last || last === '') return 'index.html';
    return last;
  }

  function buildHeader() {
    var prefix = currentDepth();
    var active = currentActiveHref();
    var links = NAV_ITEMS.map(function (item) {
      var cls = item.href === active ? ' class="active"' : '';
      return '<a href="' + prefix + item.href + '"' + cls + '>' + item.label + '</a>';
    }).join('\n      ');

    return (
      '<header class="site-header">\n' +
      '  <div class="nav-inner">\n' +
      '    <a class="brand" href="' + prefix + 'index.html">' + SITE_NAME + '\n' +
      '      <span class="ledger-no">' + SITE_LEDGER_TAG + '</span>\n' +
      '    </a>\n' +
      '    <div style="display:flex; align-items:center; gap:8px;">\n' +
      '      <button class="theme-toggle" id="themeToggle" aria-label="Toggle dark mode">\u263E</button>\n' +
      '      <button class="nav-toggle-btn" id="navToggle" aria-label="Toggle menu">\u2630</button>\n' +
      '    </div>\n' +
      '    <nav class="main-nav" id="mainNav">\n' +
      '      ' + links + '\n' +
      '    </nav>\n' +
      '  </div>\n' +
      '</header>'
    );
  }

  function buildFooter() {
    var prefix = currentDepth();
    return (
      '<footer class="site-footer">\n' +
      '  <div class="wrap">\n' +
      '    <p>' + FOOTER_TAGLINE + '</p>\n' +
      '    <p>&copy; 2026 ' + SITE_NAME + ' &middot; <a href="mailto:' + FOOTER_EMAIL + '">' + FOOTER_EMAIL + '</a> &middot; <a href="' + FOOTER_SITE_URL + '">' + FOOTER_SITE_URL.replace('https://', '') + '</a></p>\n' +
      '  </div>\n' +
      '</footer>'
    );
  }

  document.addEventListener('DOMContentLoaded', function () {
    var headerSlot = document.getElementById('site-header-placeholder');
    var footerSlot = document.getElementById('site-footer-placeholder');
    if (headerSlot) headerSlot.outerHTML = buildHeader();
    if (footerSlot) footerSlot.outerHTML = buildFooter();

    var btn = document.getElementById('themeToggle');
    if (btn) {
      btn.textContent = root.getAttribute('data-theme') === 'light' ? '\u263E' : '\u2600';
      btn.addEventListener('click', function () {
        var isLight = root.getAttribute('data-theme') === 'light';
        if (isLight) {
          root.removeAttribute('data-theme');
          localStorage.setItem('bijesh-portfolio-theme', 'dark');
          btn.textContent = '\u2600';
        } else {
          root.setAttribute('data-theme', 'light');
          localStorage.setItem('bijesh-portfolio-theme', 'light');
          btn.textContent = '\u263E';
        }
      });
    }

    var navToggle = document.getElementById('navToggle');
    var mainNav = document.getElementById('mainNav');
    if (navToggle && mainNav) {
      navToggle.addEventListener('click', function () {
        mainNav.classList.toggle('open');
      });
    }
  });
})();
