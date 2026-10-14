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
var FOOTER_EMAIL = "cmabijesh.ae@gmail.com";
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

/* View-only image galleries: lightbox + discourage saving */
(function(){
  var lb=null;
  function close(){ if(lb){ lb.classList.remove('open'); } }
  document.addEventListener('click',function(e){
    var a=e.target.closest&&e.target.closest('[data-lightbox]');
    if(a){
      e.preventDefault();
      if(!lb){ lb=document.createElement('div'); lb.className='lightbox'; lb.innerHTML='<img alt="" draggable="false">'; document.body.appendChild(lb); lb.addEventListener('click',close); lb.addEventListener('contextmenu',function(ev){ev.preventDefault();}); }
      lb.querySelector('img').src=a.getAttribute('href'); lb.classList.add('open'); return;
    }
  });
  document.addEventListener('keydown',function(e){ if(e.key==='Escape') close(); });
  document.addEventListener('contextmenu',function(e){ if(e.target.closest&&e.target.closest('.view-gallery,.lightbox')) e.preventDefault(); });
  document.addEventListener('dragstart',function(e){ if(e.target.closest&&e.target.closest('.view-gallery,.lightbox')) e.preventDefault(); });
})();

/* Access-request modal: any element with [data-request-access] (optional data-file) opens it */
(function(){
  var ENDPOINT='https://formsubmit.co/ajax/cmabijesh.ae@gmail.com', OWNER='cmabijesh.ae@gmail.com', modal=null;
  function build(){
    modal=document.createElement('div'); modal.className='ra-overlay';
    modal.innerHTML='<div class="ra-box" role="dialog" aria-modal="true" aria-labelledby="ra-title">'+
      '<button type="button" class="ra-x" aria-label="Close">&times;</button>'+
      '<h3 id="ra-title">Request access</h3>'+
      '<p class="ra-file"></p>'+
      '<p class="ra-sub">Enter your email and I will review your request. If approved, I will send the file to you.</p>'+
      '<form novalidate>'+
        '<label>Your email *<input type="email" name="email" required autocomplete="email" placeholder="you@company.com"></label>'+
        '<label>Name<input type="text" name="name" autocomplete="name" placeholder="Optional"></label>'+
        '<label>Company / role<input type="text" name="company" placeholder="Optional"></label>'+
        '<input type="text" name="_honey" tabindex="-1" autocomplete="off" style="display:none">'+
        '<button type="submit" class="btn btn-primary">Send request</button>'+
        '<p class="ra-msg" role="status"></p>'+
      '</form></div>';
    document.body.appendChild(modal);
    modal.addEventListener('click',function(e){ if(e.target===modal||e.target.classList.contains('ra-x')) close(); });
    modal.querySelector('form').addEventListener('submit',submit);
  }
  function close(){ if(modal) modal.classList.remove('open'); }
  function open(file){
    if(!modal) build();
    modal.querySelector('.ra-file').textContent=file?('File: '+file):'';
    modal.dataset.file=file||'Project files';
    var f=modal.querySelector('form'); f.style.display=''; f.reset(); modal.querySelector('.ra-msg').textContent=''; modal.querySelector('.ra-msg').className='ra-msg';
    modal.classList.add('open'); setTimeout(function(){ f.email.focus(); },50);
  }
  function submit(e){
    e.preventDefault();
    var f=e.target, msg=modal.querySelector('.ra-msg'), btn=f.querySelector('button[type=submit]');
    var email=f.email.value.trim();
    if(!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)){ msg.textContent='Please enter a valid email address.'; msg.className='ra-msg err'; return; }
    if(f._honey.value){ return; }
    var file=modal.dataset.file; btn.disabled=true; btn.textContent='Sending…'; msg.textContent=''; msg.className='ra-msg';
    var body={ _subject:'Access request: '+file, _template:'table', _captcha:'false', _replyto:email,
      email:email, name:f.name.value.trim(), company:f.company.value.trim(), file:file, page:location.href, _honey:'' };
    fetch(ENDPOINT,{method:'POST',headers:{'Content-Type':'application/json','Accept':'application/json'},body:JSON.stringify(body)})
      .then(function(r){ if(!r.ok) throw 0; return r.json(); })
      .then(function(){ f.style.display='none'; msg.textContent='Thank you. Your request has been sent. I will review it and reply to '+email+'.'; msg.className='ra-msg ok'; })
      .catch(function(){
        btn.disabled=false; btn.textContent='Send request';
        msg.innerHTML='Could not send automatically. <a href="mailto:'+OWNER+'?subject='+encodeURIComponent('Access request: '+file)+'&body='+encodeURIComponent('Hi Bijesh, I would like to request access to '+file+'.\n\nMy email: '+email)+'">Click here to send it by email instead.</a>'; msg.className='ra-msg err';
      });
  }
  document.addEventListener('click',function(e){
    var t=e.target.closest&&e.target.closest('[data-request-access]');
    if(t){ e.preventDefault(); open(t.getAttribute('data-file')||''); }
  });
  document.addEventListener('keydown',function(e){ if(e.key==='Escape') close(); });
})();
