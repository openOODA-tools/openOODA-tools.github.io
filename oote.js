// oote.js — Sovereign openOODA Ecosystem Theme Switcher & Runtime
(function() {
  const THEME_KEY = "oote_theme";
  const defaultTheme = "classic";

  function applyTheme(theme) {
    document.documentElement.setAttribute("data-theme", theme);
    localStorage.setItem(THEME_KEY, theme);
    const selects = document.querySelectorAll(".theme-select");
    selects.forEach(sel => { sel.value = theme; });
  }

  const savedTheme = localStorage.getItem(THEME_KEY) || defaultTheme;
  applyTheme(savedTheme);

  window.setOoteTheme = function(theme) {
    applyTheme(theme);
  };

  window.copySnippet = function(text, btn) {
    navigator.clipboard.writeText(text).then(() => {
      const orig = btn.textContent;
      btn.textContent = 'COPIED';
      btn.style.color = 'var(--status-success)';
      btn.style.borderColor = 'var(--status-success)';
      setTimeout(() => {
        btn.textContent = orig;
        btn.style.color = '';
        btn.style.borderColor = '';
      }, 1500);
    });
  };

  document.addEventListener("DOMContentLoaded", () => {
    applyTheme(localStorage.getItem(THEME_KEY) || defaultTheme);
  });
})();
