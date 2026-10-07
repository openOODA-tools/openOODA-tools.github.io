// oote.js — Sovereign openOODA Ecosystem Theme Switcher & Circadian Runtime
(function() {
  const THEME_KEY = "oote_theme";
  const MODE_KEY = "oote_mode";

  // Canonical Holiday and Calendar Resolver (exact parity with oote/presets/calendar.oo)
  function getHolidayForDate(m, d) {
    if ((m === 12 && d === 31) || (m === 1 && (d === 1 || d === 2))) return "nova";
    if (m === 2 && d >= 1 && d <= 10) return "lantern";
    if (m === 3 && d >= 18 && d <= 24) return "sakura";
    if (m === 6 && d >= 18 && d <= 24) return "sol";
    if (m === 10 && d >= 25 && d <= 31) return "spooky";
    if (m === 11 && d >= 22 && d <= 28) return "harvest";
    if (m === 12 && d >= 20 && d <= 26) return "yule";
    return "";
  }

  function getMonthTheme(m) {
    const months = [
      "frost", "amethyst", "thaw", "bloom", "meadow", "solstice",
      "mirage", "amber", "equinox", "ember", "hearth", "solitude"
    ];
    return months[m - 1] || "ember";
  }

  function resolveCalendarAutoTheme() {
    const now = new Date();
    const m = now.getMonth() + 1; // 1 - 12
    const d = now.getDate();
    const holiday = getHolidayForDate(m, d);
    return holiday || getMonthTheme(m);
  }

  function resolveCircadianAutoMode() {
    const hour = new Date().getHours();
    // 06:00 - 17:59 light; 18:00 - 05:59 dark (exact parity with oote clock_is_dark)
    return (hour < 6 || hour >= 18) ? "dark" : "light";
  }

  function applyTheme(themeSetting, modeSetting) {
    let tSetting = themeSetting;
    let mSetting = modeSetting;

    if (!tSetting) {
      try { tSetting = localStorage.getItem(THEME_KEY); } catch (e) {}
    }
    if (!mSetting) {
      try { mSetting = localStorage.getItem(MODE_KEY); } catch (e) {}
    }

    if (!tSetting) tSetting = "auto";
    if (!mSetting) mSetting = "auto";

    const resolvedTheme = (tSetting === "auto") ? resolveCalendarAutoTheme() : tSetting;
    const resolvedMode = (mSetting === "auto") ? resolveCircadianAutoMode() : mSetting;

    document.documentElement.setAttribute("data-theme", resolvedTheme);
    document.documentElement.setAttribute("data-mode", resolvedMode);
    document.documentElement.setAttribute("data-oote-theme", tSetting);
    document.documentElement.setAttribute("data-oote-mode", mSetting);
    document.documentElement.dataset.theme = resolvedTheme;
    document.documentElement.dataset.mode = resolvedMode;

    try {
      localStorage.setItem(THEME_KEY, tSetting);
      localStorage.setItem(MODE_KEY, mSetting);
      localStorage.setItem("openooda-theme", resolvedTheme);
    } catch (e) {}

    const selects = document.querySelectorAll(".theme-select");
    selects.forEach(sel => { sel.value = tSetting; });
  }

  // Initial immediate application
  applyTheme();

  window.setOoteTheme = function(theme, mode) {
    applyTheme(theme, mode);
  };

  window.getOoteState = function() {
    return {
      themeSetting: localStorage.getItem(THEME_KEY) || "auto",
      modeSetting: localStorage.getItem(MODE_KEY) || "auto",
      resolvedTheme: document.documentElement.getAttribute("data-theme"),
      resolvedMode: document.documentElement.getAttribute("data-mode")
    };
  };

  window.toggleOoteMode = function() {
    const current = document.documentElement.getAttribute("data-mode") || "dark";
    const next = current === "dark" ? "light" : "dark";
    applyTheme(localStorage.getItem(THEME_KEY) || "auto", next);
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
    applyTheme();
  });
})();
