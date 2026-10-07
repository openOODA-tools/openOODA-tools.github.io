import { TOOLS_DATA, CATEGORIES, STATUS_FILTERS } from "./tools-data.js";

// Application State
const state = {
  tools: TOOLS_DATA,
  searchQuery: "",
  category: "All Categories",
  status: "all",
  sortBy: "status",
  viewMode: "cards", // "cards" or "split"
  currentPage: 1,
  pageSize: 9,
  showAll: false,
  selectedToolId: "oosh",
  isMarqueePaused: false
};

// DOM Elements
const searchInput = document.getElementById("search-input");
const searchClear = document.getElementById("search-clear");
const sortSelect = document.getElementById("sort-select");
const sourceFiltersContainer = document.getElementById("source-filters");
const categoryFiltersContainer = document.getElementById("category-filters");
const clearFiltersBtn = document.getElementById("clear-filters");
const pluginGrid = document.getElementById("plugin-grid");
const catalogSplit = document.getElementById("catalog-split");
const splitGrid = document.getElementById("split-grid");
const splitCard = document.getElementById("split-card");
const emptyState = document.getElementById("empty-state");
const emptyReset = document.getElementById("empty-reset");
const toolCountEl = document.getElementById("tool-count");
const pagination = document.getElementById("catalog-pagination");
const pagePrevious = document.getElementById("page-previous");
const pageNext = document.getElementById("page-next");
const pageSummary = document.getElementById("page-summary");
const viewDock = document.getElementById("catalog-view-dock");
const viewDockBtn = document.getElementById("catalog-view-dock-button");
const viewDockStatus = document.getElementById("catalog-view-dock-status");
const viewDockAction = document.getElementById("catalog-view-dock-action");
const toast = document.getElementById("toast");
const themeToggle = document.querySelector(".theme-toggle");

// Initialize theme from storage
function initTheme() {
  const themes = ["dark", "tokyo-night", "gruvbox", "catppuccin", "ethereal", "light"];
  let savedTheme = localStorage.getItem("openooda-theme");
  if (!themes.includes(savedTheme)) {
    savedTheme = "dark";
  }
  document.documentElement.dataset.theme = savedTheme;

  if (themeToggle) {
    themeToggle.addEventListener("click", () => {
      const current = document.documentElement.dataset.theme || "dark";
      const nextIndex = (themes.indexOf(current) + 1) % themes.length;
      const nextTheme = themes[nextIndex];
      document.documentElement.dataset.theme = nextTheme;
      localStorage.setItem("openooda-theme", nextTheme);
      showToast(`Theme switched: ${nextTheme}`);
    });
  }
}

// Copy to clipboard with toast notification
export function copySnippet(text, btn = null) {
  navigator.clipboard.writeText(text).then(() => {
    if (btn) {
      const orig = btn.textContent;
      btn.textContent = "COPIED";
      btn.style.color = "var(--accent)";
      btn.style.borderColor = "var(--accent)";
      setTimeout(() => {
        btn.textContent = orig;
        btn.style.color = "";
        btn.style.borderColor = "";
      }, 1500);
    }
    showToast("Command copied to clipboard");
  }).catch(err => {
    console.error("Clipboard copy failed:", err);
  });
}
window.copySnippet = copySnippet;

let toastTimer = null;
export function showToast(message) {
  if (!toast) return;
  toast.textContent = message;
  toast.classList.add("show");
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => {
    toast.classList.remove("show");
  }, 2200);
}

// Render Hidden Gems Carousel
function renderHiddenGems() {
  const track = document.getElementById("gems-grid");
  const prevBtn = document.querySelector("[data-gems-step='-1']");
  const nextBtn = document.querySelector("[data-gems-step='1']");
  if (!track) return;

  const gems = state.tools.filter(t => t.gem);
  track.innerHTML = gems.map(tool => `
    <article class="gem-card" style="--card-accent: ${tool.accent}">
      <div>
        <div class="gem-header">
          <div class="gem-icon">${tool.monogram}</div>
          <div class="gem-title-group">
            <h3>${tool.name} <span class="badge badge-green">${tool.version}</span></h3>
            <span class="gem-role">${tool.role}</span>
          </div>
        </div>
        <div class="gem-fact"><strong>GEM:</strong> ${tool.gemFact}</div>
        <p class="gem-desc">${tool.description}</p>
      </div>
      <div>
        <div class="install-box">
          <code>${escapeHtml(tool.installCommand)}</code>
          <button class="copy-btn" onclick="copySnippet('${escapeHtml(tool.installCommand)}', this)">COPY</button>
        </div>
        <div class="card-links">
          <a href="${tool.overviewUrl}">[ Overview ]</a>
          <a href="${tool.repoUrl}" target="_blank" rel="noopener noreferrer">[ Source &#8599; ]</a>
        </div>
      </div>
    </article>
  `).join("");

  // Navigation handlers
  const updateButtons = () => {
    const maxScroll = track.scrollWidth - track.clientWidth;
    if (prevBtn) prevBtn.disabled = track.scrollLeft <= 4;
    if (nextBtn) nextBtn.disabled = track.scrollLeft >= maxScroll - 4;
  };

  if (prevBtn && nextBtn && !track.dataset.carouselInit) {
    track.dataset.carouselInit = "true";
    prevBtn.addEventListener("click", () => {
      track.scrollBy({ left: -(track.clientWidth * 0.8), behavior: "smooth" });
    });
    nextBtn.addEventListener("click", () => {
      track.scrollBy({ left: track.clientWidth * 0.8, behavior: "smooth" });
    });
    track.addEventListener("scroll", updateButtons, { passive: true });
    window.addEventListener("resize", updateButtons);
  }
  updateButtons();
}

// Render Dual Scrolling Marquee
function renderMarquee() {
  const container = document.getElementById("recent-latest");
  const toggleBtn = document.getElementById("recent-feed-toggle");
  if (!container) return;

  // Split all 256 tools into two rows
  const row0Tools = state.tools.filter((_, i) => i % 2 === 0);
  const row1Tools = state.tools.filter((_, i) => i % 2 === 1);

  const makeCard = (tool, duplicate = false) => `
    <li${duplicate ? ' aria-hidden="true"' : ""}>
      <a class="landed-card" href="#catalog" onclick="selectAndScroll('${tool.id}')" style="--card-accent: ${tool.accent}">
        <span class="landed-media">
          <span class="landed-mark">${tool.monogram}</span>
          <span class="landed-tag-badge">${tool.category.split(" ")[0]}</span>
        </span>
        <span class="landed-body">
          <span class="landed-name">${tool.name}</span>
          <span class="landed-role">${tool.role}</span>
          <span class="landed-foot">
            <span class="landed-status ${tool.status === 'released' ? 'status-released' : 'status-blueprint'}">
              ${tool.status === 'released' ? tool.version : 'Blueprint'}
            </span>
            <span>&rarr;</span>
          </span>
        </span>
      </a>
    </li>
  `;

  const track0 = container.querySelector('[data-landed-row="0"]');
  const track1 = container.querySelector('[data-landed-row="1"]');

  if (track0) {
    track0.innerHTML = row0Tools.map(t => makeCard(t)).join("") + row0Tools.map(t => makeCard(t, true)).join("");
  }
  if (track1) {
    track1.innerHTML = row1Tools.map(t => makeCard(t)).join("") + row1Tools.map(t => makeCard(t, true)).join("");
  }

  container.classList.add("is-animated");

  if (toggleBtn && !toggleBtn.dataset.init) {
    toggleBtn.dataset.init = "true";
    toggleBtn.addEventListener("click", () => {
      state.isMarqueePaused = !state.isMarqueePaused;
      container.classList.toggle("is-paused", state.isMarqueePaused);
      toggleBtn.textContent = state.isMarqueePaused ? "Play" : "Pause";
      toggleBtn.setAttribute("aria-label", `${state.isMarqueePaused ? "Play" : "Pause"} marquee animation`);
    });
  }
}

// Select tool and jump to catalog
window.selectAndScroll = function(toolId) {
  state.searchQuery = toolId;
  if (searchInput) searchInput.value = toolId;
  if (searchClear) searchClear.style.display = "block";
  state.selectedToolId = toolId;
  applyFiltersAndRender();
  const catalog = document.getElementById("catalog");
  if (catalog) {
    catalog.scrollIntoView({ behavior: "smooth" });
  }
};

// Filter & Sort Logic
function getFilteredTools() {
  const query = state.searchQuery.trim().toLowerCase();
  
  return state.tools.filter(tool => {
    // Status filter
    if (state.status === "released" && tool.status !== "released") return false;
    if (state.status === "blueprint" && tool.status !== "blueprint") return false;

    // Category filter
    if (state.category !== "All Categories" && tool.category !== state.category) return false;

    // Query filter
    if (query) {
      if (query.startsWith("tag:")) {
        const tagQuery = query.slice(4).trim();
        return tool.tags.some(t => t.toLowerCase().includes(tagQuery));
      }
      const matchName = tool.name.toLowerCase().includes(query);
      const matchRole = tool.role.toLowerCase().includes(query);
      const matchDesc = tool.description.toLowerCase().includes(query);
      const matchTags = tool.tags.some(t => t.toLowerCase().includes(query));
      const matchCategory = tool.category.toLowerCase().includes(query);
      return matchName || matchRole || matchDesc || matchTags || matchCategory;
    }

    return true;
  }).sort((a, b) => {
    if (state.sortBy === "status") {
      if (a.status === "released" && b.status !== "released") return -1;
      if (b.status === "released" && a.status !== "released") return 1;
      return a.name.localeCompare(b.name);
    }
    if (state.sortBy === "name") {
      return a.name.localeCompare(b.name);
    }
    if (state.sortBy === "category") {
      const catCompare = a.category.localeCompare(b.category);
      return catCompare !== 0 ? catCompare : a.name.localeCompare(b.name);
    }
    if (state.sortBy === "added") {
      return (b.addedAt || "").localeCompare(a.addedAt || "");
    }
    return 0;
  });
}

// Render Filter Bars
function renderFilterBars() {
  if (sourceFiltersContainer) {
    sourceFiltersContainer.innerHTML = STATUS_FILTERS.map(f => `
      <button type="button" class="filter-btn ${state.status === f.id ? 'active' : ''}" data-status="${f.id}">
        ${f.label} <span class="filter-count">(${f.count})</span>
      </button>
    `).join("");

    sourceFiltersContainer.querySelectorAll("[data-status]").forEach(btn => {
      btn.addEventListener("click", () => {
        state.status = btn.dataset.status;
        state.currentPage = 1;
        applyFiltersAndRender();
      });
    });
  }

  if (categoryFiltersContainer) {
    categoryFiltersContainer.innerHTML = CATEGORIES.map(cat => {
      const count = cat === "All Categories" 
        ? state.tools.length 
        : state.tools.filter(t => t.category === cat).length;
      return `
        <button type="button" class="filter-btn ${state.category === cat ? 'active' : ''}" data-cat="${cat}">
          ${cat} <span class="filter-count">(${count})</span>
        </button>
      `;
    }).join("");

    categoryFiltersContainer.querySelectorAll("[data-cat]").forEach(btn => {
      btn.addEventListener("click", () => {
        state.category = btn.dataset.cat;
        state.currentPage = 1;
        applyFiltersAndRender();
      });
    });
  }
}

// Render Cards View
function renderCardsView(filteredTools) {
  pluginGrid.hidden = false;
  catalogSplit.hidden = true;

  const total = filteredTools.length;
  const totalPages = Math.ceil(total / state.pageSize) || 1;
  state.currentPage = Math.min(Math.max(1, state.currentPage), totalPages);

  const start = state.showAll ? 0 : (state.currentPage - 1) * state.pageSize;
  const end = state.showAll ? total : start + state.pageSize;
  const currentTools = filteredTools.slice(start, end);

  pluginGrid.innerHTML = currentTools.map(tool => {
    const isReleased = tool.status === "released";
    const statusBadgeClass = isReleased ? "badge-green" : "badge";
    const statusLabel = isReleased ? tool.version : "Blueprint";

    return `
      <article class="tool-card" style="--card-accent: ${tool.accent}">
        <div>
          <div class="tool-card-head">
            <div class="tool-card-icon">${tool.monogram}</div>
            <div class="tool-card-title-group">
              <div class="tool-card-title-line">
                <h3 class="tool-card-name">${tool.name}</h3>
                <span class="tool-card-role">${tool.role}</span>
              </div>
              <div class="tool-card-badges">
                <span class="badge ${statusBadgeClass}">${statusLabel}</span>
                <span class="badge badge-cyan">${tool.category}</span>
                ${tool.tags.slice(0, 2).map(tag => `<span class="badge">${tag}</span>`).join("")}
              </div>
            </div>
          </div>
          <p class="tool-card-desc">${tool.description}</p>
        </div>
        <div>
          <div class="install-box">
            <code>${escapeHtml(tool.installCommand)}</code>
            ${isReleased ? `<button class="copy-btn" onclick="copySnippet('${escapeHtml(tool.installCommand)}', this)">COPY</button>` : ''}
          </div>
          <div class="card-links">
            ${isReleased ? `<a href="${tool.overviewUrl}">[ Overview ]</a>` : '<span style="color:var(--faint)">[ In Spec Review ]</span>'}
            <a href="${tool.repoUrl}" target="_blank" rel="noopener noreferrer">[ GitHub &#8599; ]</a>
          </div>
        </div>
      </article>
    `;
  }).join("");

  renderPagination(total, totalPages);
}

// Render Split View
function renderSplitView(filteredTools) {
  pluginGrid.hidden = true;
  catalogSplit.hidden = false;

  const total = filteredTools.length;
  const totalPages = Math.ceil(total / 18) || 1;
  state.currentPage = Math.min(Math.max(1, state.currentPage), totalPages);

  const start = (state.currentPage - 1) * 18;
  const currentTools = filteredTools.slice(start, start + 18);

  // If current selected tool not in list, pick first
  let selected = filteredTools.find(t => t.id === state.selectedToolId);
  if (!selected && filteredTools.length > 0) {
    selected = filteredTools[0];
    state.selectedToolId = selected.id;
  }

  // Render left tiles
  splitGrid.innerHTML = currentTools.map(tool => `
    <button type="button" class="split-tile ${tool.id === state.selectedToolId ? 'is-selected' : ''}" data-tool-id="${tool.id}" style="--card-accent: ${tool.accent}">
      <span class="split-tile-icon">${tool.monogram}</span>
      <span class="split-tile-name">${tool.name}</span>
      <span class="split-tile-role">${tool.role}</span>
    </button>
  `).join("");

  // Tile click events
  splitGrid.querySelectorAll("[data-tool-id]").forEach(btn => {
    btn.addEventListener("click", () => {
      state.selectedToolId = btn.dataset.toolId;
      renderSplitView(filteredTools);
    });
  });

  // Render right inspector card
  if (selected) {
    const isReleased = selected.status === "released";
    splitCard.innerHTML = `
      <section class="split-inspector" style="--card-accent: ${selected.accent}">
        <div class="inspector-title">
          <div class="inspector-icon">${selected.monogram}</div>
          <div>
            <h2 class="inspector-name">${selected.name}</h2>
            <span class="badge ${isReleased ? 'badge-green' : 'badge'}">${isReleased ? selected.version : 'Blueprint Specification'}</span>
          </div>
        </div>
        <p class="inspector-desc">${selected.description}</p>
        
        <div class="inspector-meta-block">
          <div class="inspector-row"><span>Category</span><span>${selected.category}</span></div>
          <div class="inspector-row"><span>Role</span><span>${selected.role}</span></div>
          <div class="inspector-row"><span>Security Bounds</span><span>Negative-trust sandbox</span></div>
          <div class="inspector-row"><span>Ambient Auth</span><span>Zero Ambient Auth (NAA)</span></div>
          <div class="inspector-row"><span>systemd Integration</span><span>Native service / scope</span></div>
          <div class="inspector-row"><span>Model Context Protocol</span><span>stdio MCP server (--mcp)</span></div>
          <div class="inspector-row"><span>Packaging</span><span>Arch, Fedora RPM, Debian DEB</span></div>
        </div>

        <div class="install-box">
          <code>${escapeHtml(selected.installCommand)}</code>
          ${isReleased ? `<button class="copy-btn" onclick="copySnippet('${escapeHtml(selected.installCommand)}', this)">COPY</button>` : ''}
        </div>

        <div class="card-links" style="margin-top: 8px;">
          ${isReleased ? `<a href="${selected.overviewUrl}" class="button market-primary" style="height:32px; padding:0 12px; font-size:11px;">View Man Page &rarr;</a>` : ''}
          <a href="${selected.repoUrl}" target="_blank" rel="noopener noreferrer" class="button" style="height:32px; padding:0 12px; font-size:11px;">GitHub Repository &#8599;</a>
        </div>
      </section>
    `;
  }

  // Split view pager
  const splitPrev = document.getElementById("split-page-previous");
  const splitNext = document.getElementById("split-page-next");
  const splitSummary = document.getElementById("split-page-summary");

  if (splitPrev) splitPrev.disabled = state.currentPage <= 1;
  if (splitNext) splitNext.disabled = state.currentPage >= totalPages;
  if (splitSummary) splitSummary.textContent = `Page ${state.currentPage} of ${totalPages}`;

  if (splitPrev && !splitPrev.dataset.init) {
    splitPrev.dataset.init = "true";
    splitPrev.addEventListener("click", () => {
      if (state.currentPage > 1) {
        state.currentPage--;
        renderSplitView(getFilteredTools());
      }
    });
  }
  if (splitNext && !splitNext.dataset.init) {
    splitNext.dataset.init = "true";
    splitNext.addEventListener("click", () => {
      if (state.currentPage < totalPages) {
        state.currentPage++;
        renderSplitView(getFilteredTools());
      }
    });
  }
}

// Render Pagination Controls
function renderPagination(total, totalPages) {
  if (pagination) {
    pagination.hidden = state.showAll || totalPages <= 1;
    if (pagePrevious) pagePrevious.disabled = state.currentPage <= 1;
    if (pageNext) pageNext.disabled = state.currentPage >= totalPages;
    if (pageSummary) pageSummary.textContent = `${state.currentPage} / ${totalPages}`;
  }

  // Update Bottom Dock
  if (viewDock) {
    viewDock.hidden = total <= state.pageSize;
    if (viewDockStatus) {
      viewDockStatus.textContent = state.showAll 
        ? `Showing all ${total} tools` 
        : `Showing page ${state.currentPage} of ${totalPages} (${total} total)`;
    }
    if (viewDockAction) {
      viewDockAction.innerHTML = state.showAll
        ? `Show 9 per page &uarr;`
        : `Browse all ${total} tools &darr;`;
    }
  }
}

// Main Filter & Render Dispatcher
function applyFiltersAndRender() {
  const filtered = getFilteredTools();

  // Update counts
  if (toolCountEl) {
    toolCountEl.textContent = `${filtered.length} tool${filtered.length === 1 ? '' : 's'}`;
  }

  // Check empty state
  if (filtered.length === 0) {
    if (pluginGrid) pluginGrid.hidden = true;
    if (catalogSplit) catalogSplit.hidden = true;
    if (pagination) pagination.hidden = true;
    if (viewDock) viewDock.hidden = true;
    if (emptyState) emptyState.hidden = false;
    return;
  }

  if (emptyState) emptyState.hidden = true;

  if (state.viewMode === "split") {
    renderSplitView(filtered);
  } else {
    renderCardsView(filtered);
  }

  renderFilterBars();
}

// Hero Parametric Capability-Vector Ray Animation
function initHeroRay() {
  const frame = document.querySelector(".market-hero-ray");
  const canvas = frame?.querySelector("canvas");
  const label = frame?.querySelector(".market-hero-ray-label");
  if (!frame || !canvas || !label) return;

  const ctx = canvas.getContext("2d");
  if (!ctx) return;

  const presets = [
    { title: "CAPABILITY: AMBIENT BOUNDS", waves: 4, speed: 0.0015, color: "#00e676" },
    { title: "LCS MYERS STREAM", waves: 6, speed: 0.0022, color: "#00e5ff" },
    { title: "CIRCADIAN HARMONIC", waves: 5, speed: 0.0018, color: "#7c4dff" },
    { title: "RING BUFFER SCAN", waves: 7, speed: 0.0026, color: "#ff4081" }
  ];

  let currentPreset = 0;
  let animId = null;

  function resize() {
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    const rect = frame.getBoundingClientRect();
    canvas.width = rect.width * dpr;
    canvas.height = rect.height * dpr;
    ctx.scale(dpr, dpr);
  }

  function draw(time) {
    const preset = presets[currentPreset];
    const w = frame.clientWidth;
    const h = frame.clientHeight;

    ctx.clearRect(0, 0, w, h);

    // Subtle background grid
    ctx.strokeStyle = "rgba(30, 41, 59, 0.4)";
    ctx.lineWidth = 1;
    const step = 24;
    for (let x = 0; x < w; x += step) {
      ctx.beginPath();
      ctx.moveTo(x, 0);
      ctx.lineTo(x, h);
      ctx.stroke();
    }
    for (let y = 0; y < h; y += step) {
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(w, y);
      ctx.stroke();
    }

    // Dynamic parametric capability waves
    const cy = h / 2;
    for (let i = 0; i < preset.waves; i++) {
      ctx.beginPath();
      ctx.strokeStyle = preset.color;
      ctx.lineWidth = i === 0 ? 2 : 1;
      ctx.globalAlpha = i === 0 ? 0.9 : 0.35 - (i * 0.04);

      const freq = 0.015 + (i * 0.005);
      const amp = 30 + (i * 8);
      const phase = time * preset.speed * (i + 1);

      for (let x = 0; x < w; x += 3) {
        const y = cy + Math.sin(x * freq + phase) * amp * Math.cos((x / w - 0.5) * Math.PI);
        if (x === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      ctx.stroke();
    }

    ctx.globalAlpha = 1.0;
    animId = requestAnimationFrame(draw);
  }

  frame.addEventListener("click", () => {
    currentPreset = (currentPreset + 1) % presets.length;
    label.textContent = `${presets[currentPreset].title} 0${currentPreset + 1}/04`;
  });

  window.addEventListener("resize", resize);
  resize();
  animId = requestAnimationFrame(draw);
}

// Utility: escape HTML entities
function escapeHtml(str) {
  if (!str) return "";
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

// Bind Global UI Listeners
function setupEventListeners() {
  // Search input
  if (searchInput) {
    searchInput.addEventListener("input", (e) => {
      state.searchQuery = e.target.value;
      state.currentPage = 1;
      if (searchClear) searchClear.style.display = state.searchQuery ? "block" : "none";
      applyFiltersAndRender();
    });

    if (searchClear) {
      searchClear.addEventListener("click", () => {
        searchInput.value = "";
        state.searchQuery = "";
        searchClear.style.display = "none";
        state.currentPage = 1;
        applyFiltersAndRender();
        searchInput.focus();
      });
    }
  }

  // Keyboard shortcut Ctrl+K or / to focus search
  window.addEventListener("keydown", (e) => {
    if ((e.ctrlKey && e.key.toLowerCase() === "k") || (e.key === "/" && document.activeElement !== searchInput)) {
      e.preventDefault();
      searchInput?.focus();
      searchInput?.select();
    }
    if (e.key === "Escape" && document.activeElement === searchInput) {
      searchInput.value = "";
      state.searchQuery = "";
      if (searchClear) searchClear.style.display = "none";
      searchInput.blur();
      applyFiltersAndRender();
    }
  });

  // Sort dropdown
  if (sortSelect) {
    sortSelect.addEventListener("change", (e) => {
      state.sortBy = e.target.value;
      applyFiltersAndRender();
    });
  }

  // Clear filters button
  if (clearFiltersBtn) {
    clearFiltersBtn.addEventListener("click", () => {
      state.category = "All Categories";
      state.status = "all";
      state.searchQuery = "";
      if (searchInput) searchInput.value = "";
      if (searchClear) searchClear.style.display = "none";
      state.currentPage = 1;
      applyFiltersAndRender();
    });
  }

  // Empty reset button
  if (emptyReset) {
    emptyReset.addEventListener("click", () => {
      state.category = "All Categories";
      state.status = "all";
      state.searchQuery = "";
      if (searchInput) searchInput.value = "";
      if (searchClear) searchClear.style.display = "none";
      state.currentPage = 1;
      applyFiltersAndRender();
    });
  }

  // View Mode Buttons (Cards vs Split)
  const viewModeButtons = document.querySelectorAll("#catalog-view-mode button");
  viewModeButtons.forEach(btn => {
    btn.addEventListener("click", () => {
      const mode = btn.dataset.view;
      state.viewMode = mode;
      viewModeButtons.forEach(b => b.setAttribute("aria-pressed", String(b.dataset.view === mode)));
      applyFiltersAndRender();
    });
  });

  // Pagination Previous / Next
  if (pagePrevious) {
    pagePrevious.addEventListener("click", () => {
      if (state.currentPage > 1) {
        state.currentPage--;
        applyFiltersAndRender();
        document.getElementById("catalog")?.scrollIntoView({ behavior: "smooth" });
      }
    });
  }
  if (pageNext) {
    pageNext.addEventListener("click", () => {
      state.currentPage++;
      applyFiltersAndRender();
      document.getElementById("catalog")?.scrollIntoView({ behavior: "smooth" });
    });
  }

  // View Dock (Toggle between 9 per page and show all)
  if (viewDockBtn) {
    viewDockBtn.addEventListener("click", () => {
      state.showAll = !state.showAll;
      applyFiltersAndRender();
    });
  }
}

// Bootstrap Application
document.addEventListener("DOMContentLoaded", () => {
  initTheme();
  renderHiddenGems();
  renderMarquee();
  setupEventListeners();
  applyFiltersAndRender();
  initHeroRay();
});
