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
const splitStats = document.getElementById("split-stats");
const splitPanelCount = document.getElementById("split-panel-count");
const splitPagePrevious = document.getElementById("split-page-previous");
const splitPageNext = document.getElementById("split-page-next");
const splitPageSummary = document.getElementById("split-page-summary");
const splitPageInput = document.getElementById("split-page-input");
const splitPageTotal = document.getElementById("split-page-total");
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

// Initialize theme from localStorage and synchronize with oote
function initTheme() {
  const ooteThemes = ["classic", "1982", "dracula", "nord", "cyberpunk"];
  let savedTheme = null;
  try {
    savedTheme = localStorage.getItem("oote_theme") || localStorage.getItem("openooda-theme");
  } catch (e) {}

  if (!ooteThemes.includes(savedTheme)) {
    savedTheme = "classic";
  }

  function applyTheme(theme, notify = false) {
    document.documentElement.dataset.theme = theme;
    document.documentElement.setAttribute("data-theme", theme);
    try {
      localStorage.setItem("oote_theme", theme);
      localStorage.setItem("openooda-theme", theme);
    } catch (e) {}

    const selects = document.querySelectorAll(".theme-select");
    selects.forEach(sel => { sel.value = theme; });

    if (notify) {
      showToast(`Theme switched: ${theme}`);
    }
  }

  applyTheme(savedTheme, false);

  window.setOoteTheme = function(theme) {
    applyTheme(theme, true);
  };

  if (themeToggle) {
    themeToggle.addEventListener("click", () => {
      const current = document.documentElement.dataset.theme || "classic";
      const currentIndex = ooteThemes.indexOf(current);
      const nextIndex = (currentIndex === -1) ? 0 : (currentIndex + 1) % ooteThemes.length;
      const nextTheme = ooteThemes[nextIndex];
      window.setOoteTheme(nextTheme);
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
      <div class="tool-card-preview">
        <span class="tool-preview-mark">${tool.monogram}</span>
        <span class="badge badge-green tool-preview-badge">${tool.version}</span>
      </div>
      <div class="gem-body">
        <div class="gem-title-group">
          <div class="gem-title-line">
            <h3 class="gem-name">${tool.name}</h3>
            <span class="gem-role">${tool.role}</span>
          </div>
          <div class="gem-fact"><strong>GEM:</strong> ${escapeHtml(tool.gemFact)}</div>
        </div>
        <p class="gem-desc">${escapeHtml(tool.description)}</p>
        <div>
          <div class="install-box">
            <code>${escapeHtml(tool.installCommand)}</code>
            <button class="copy-btn" onclick="copySnippet('${escapeHtml(tool.installCommand)}', this)">COPY</button>
          </div>
          <div class="card-links" style="margin-top: 10px;">
            <a href="${tool.overviewUrl}">[ Overview ]</a>
            <a href="${tool.repoUrl}" target="_blank" rel="noopener noreferrer">[ GitHub &#8599; ]</a>
          </div>
        </div>
      </div>
    </article>
  `).join("");

  const updateButtons = () => {
    const maxScroll = track.scrollWidth - track.clientWidth;
    if (prevBtn) prevBtn.disabled = track.scrollLeft <= 4;
    if (nextBtn) nextBtn.disabled = track.scrollLeft >= maxScroll - 4;
  };

  if (prevBtn && nextBtn && !track.dataset.carouselInit) {
    track.dataset.carouselInit = "true";
    prevBtn.addEventListener("click", () => {
      track.scrollBy({ left: -(track.clientWidth * 0.75), behavior: "smooth" });
    });
    nextBtn.addEventListener("click", () => {
      track.scrollBy({ left: track.clientWidth * 0.75, behavior: "smooth" });
    });
    track.addEventListener("scroll", updateButtons, { passive: true });
    window.addEventListener("resize", updateButtons);
  }
  updateButtons();
}

// Select tool and jump to catalog without hiding all other tools
window.selectAndScroll = function(toolId) {
  state.selectedToolId = toolId;
  const tool = state.tools.find(t => t.id === toolId);
  if (!tool) return;

  // If in Split view, re-render split view on page containing tool
  if (state.viewMode === "split") {
    const filtered = getFilteredTools();
    const idx = filtered.findIndex(t => t.id === toolId);
    if (idx !== -1) {
      state.currentPage = Math.floor(idx / 18) + 1;
    }
    applyFiltersAndRender();
  } else {
    // In Cards view, locate page containing tool
    const filtered = getFilteredTools();
    const idx = filtered.findIndex(t => t.id === toolId);
    if (idx !== -1 && !state.showAll) {
      state.currentPage = Math.floor(idx / state.pageSize) + 1;
    }
    applyFiltersAndRender();
    
    // Highlight the card briefly
    setTimeout(() => {
      const card = document.querySelector(`[data-tool-id="${toolId}"]`);
      if (card) {
        card.classList.add("is-highlighted");
        setTimeout(() => card.classList.remove("is-highlighted"), 2500);
      }
    }, 150);
  }

  const catalog = document.getElementById("catalog");
  if (catalog) {
    catalog.scrollIntoView({ behavior: "smooth" });
  }
};

// Render Dual Scrolling Marquee (Curated 48 showcase items)
function renderMarquee() {
  const container = document.getElementById("recent-latest");
  const toggleBtn = document.getElementById("recent-feed-toggle");
  if (!container) return;

  // Build a curated 48-item showcase:
  // All 12 released tools + 36 representative blueprint tools from various categories
  const released = state.tools.filter(t => t.status === "released");
  const blueprintSample = state.tools.filter(t => t.status !== "released").slice(0, 36);
  const showcaseTools = [...released, ...blueprintSample];

  const row0Tools = showcaseTools.filter((_, i) => i % 2 === 0);
  const row1Tools = showcaseTools.filter((_, i) => i % 2 === 1);

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

// Tokenized Search & Multi-filter Logic
function getFilteredTools() {
  const rawQuery = state.searchQuery.trim().toLowerCase();
  const tokens = rawQuery ? rawQuery.split(/\s+/).filter(Boolean) : [];

  return state.tools.filter(tool => {
    // Status filter chip
    if (state.status === "released" && tool.status !== "released") return false;
    if (state.status === "blueprint" && tool.status !== "blueprint") return false;

    // Category filter chip
    if (state.category !== "All Categories" && tool.category !== state.category) return false;

    // Query tokens
    if (tokens.length > 0) {
      for (const token of tokens) {
        if (token.startsWith("tag:")) {
          const val = token.slice(4);
          if (!tool.tags.some(t => t.toLowerCase().includes(val))) return false;
          continue;
        }
        if (token.startsWith("status:")) {
          const val = token.slice(7);
          if (!tool.status.toLowerCase().includes(val)) return false;
          continue;
        }
        if (token.startsWith("cat:")) {
          const val = token.slice(4);
          if (!tool.category.toLowerCase().includes(val)) return false;
          continue;
        }

        const matchName = tool.name.toLowerCase().includes(token);
        const matchRole = tool.role.toLowerCase().includes(token);
        const matchDesc = tool.description.toLowerCase().includes(token);
        const matchTags = tool.tags.some(t => t.toLowerCase().includes(token));
        const matchCategory = tool.category.toLowerCase().includes(token);

        if (!matchName && !matchRole && !matchDesc && !matchTags && !matchCategory) {
          return false;
        }
      }
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

// Render Filter Bars with accurate dynamic counts
function renderFilterBars() {
  if (sourceFiltersContainer) {
    sourceFiltersContainer.innerHTML = STATUS_FILTERS.map(f => {
      let count = 0;
      if (f.id === "all") count = state.tools.length;
      else if (f.id === "released") count = state.tools.filter(t => t.status === "released").length;
      else if (f.id === "blueprint") count = state.tools.filter(t => t.status === "blueprint").length;

      return `
        <button type="button" class="filter-btn ${state.status === f.id ? 'active' : ''}" data-status="${f.id}">
          ${f.label} <span class="filter-count">(${count})</span>
        </button>
      `;
    }).join("");

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
      const subset = state.status === "all"
        ? state.tools
        : state.tools.filter(t => t.status === state.status);
      const count = cat === "All Categories"
        ? subset.length
        : subset.filter(t => t.category === cat).length;

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
      <article class="tool-card" data-tool-id="${tool.id}" style="--card-accent: ${tool.accent}">
        <div class="tool-card-preview">
          <span class="tool-preview-mark">${tool.monogram}</span>
          <span class="badge ${statusBadgeClass} tool-preview-badge">${statusLabel}</span>
        </div>
        <div class="tool-card-body">
          <div class="tool-card-title-group">
            <div class="tool-card-title-line">
              <h3 class="tool-card-name">${tool.name}</h3>
              <span class="tool-card-role">${tool.role}</span>
            </div>
            <div class="tool-card-badges">
              <span class="badge badge-cyan">${tool.category}</span>
              ${tool.tags.slice(0, 2).map(tag => `<span class="badge">${tag}</span>`).join("")}
            </div>
          </div>
          <p class="tool-card-desc">${escapeHtml(tool.description)}</p>
          <div>
            <div class="install-box">
              <code>${escapeHtml(tool.installCommand)}</code>
              ${isReleased ? `<button class="copy-btn" onclick="copySnippet('${escapeHtml(tool.installCommand)}', this)">COPY</button>` : ''}
            </div>
            <div class="card-links" style="margin-top: 10px;">
              ${isReleased ? `<a href="${tool.overviewUrl}">[ Overview ]</a>` : '<span style="color:var(--faint)">[ In Spec Review ]</span>'}
              <a href="${tool.repoUrl}" target="_blank" rel="noopener noreferrer">[ GitHub &#8599; ]</a>
            </div>
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

  // If currently selected tool not in filtered list, select first available
  let selected = filteredTools.find(t => t.id === state.selectedToolId);
  if (!selected && filteredTools.length > 0) {
    selected = filteredTools[0];
    state.selectedToolId = selected.id;
  }

  // Render left tiles list
  splitGrid.innerHTML = currentTools.map((tool, index) => `
    <button type="button" class="split-tile ${tool.id === state.selectedToolId ? 'is-selected' : ''}" 
      data-tool-id="${tool.id}" 
      data-index="${index}"
      role="option" 
      aria-selected="${tool.id === state.selectedToolId ? 'true' : 'false'}"
      style="--card-accent: ${tool.accent}">
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

  // Render right inspector panel
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
        <p class="inspector-desc">${escapeHtml(selected.description)}</p>
        
        <div class="inspector-meta-block">
          <div class="inspector-row"><span>Category</span><span>${selected.category}</span></div>
          <div class="inspector-row"><span>Role</span><span>${selected.role}</span></div>
          <div class="inspector-row"><span>Security Bounds</span><span>Negative-trust sandbox</span></div>
          <div class="inspector-row"><span>Ambient Auth</span><span>Zero Ambient Auth (NAA)</span></div>
          <div class="inspector-row"><span>Model Context Protocol</span><span>stdio MCP server (--mcp)</span></div>
          <div class="inspector-row"><span>Packaging</span><span>Arch PKGBUILD, RPM, DEB</span></div>
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

    if (splitStats) {
      splitStats.innerHTML = `
        <div class="inspector-row"><span>Execution Plane</span><span>Dual (Terminal + Agent)</span></div>
        <div class="inspector-row"><span>Boundary Enforcement</span><span>Kernel-level namespaces</span></div>
        <div class="inspector-row"><span>Audit Logging</span><span>Structured JSON Lines</span></div>
        <div class="inspector-row"><span>Language Runtime</span><span>Pure compiled openOODA</span></div>
      `;
    }
  }

  // Update Split Pager elements
  if (splitPanelCount) {
    splitPanelCount.textContent = `${total} available`;
  }
  if (splitPageSummary) {
    splitPageSummary.innerHTML = `
      <label class="split-page-jump">Page <input id="split-page-input" type="number" inputmode="numeric" min="1" max="${totalPages}" value="${state.currentPage}" aria-label="Go to page" /></label>
      <span id="split-page-total">of ${totalPages}</span>
    `;
    const newPageInput = document.getElementById("split-page-input");
    if (newPageInput) {
      newPageInput.addEventListener("change", (e) => {
        let p = parseInt(e.target.value, 10);
        if (isNaN(p)) p = 1;
        state.currentPage = Math.min(Math.max(1, p), totalPages);
        renderSplitView(filteredTools);
      });
    }
  }

  if (splitPagePrevious) splitPagePrevious.disabled = state.currentPage <= 1;
  if (splitPageNext) splitPageNext.disabled = state.currentPage >= totalPages;

  if (pagination) pagination.hidden = true;
  if (viewDock) viewDock.hidden = true;
}

// Split View Keyboard Navigation (Arrow Keys, PageUp, PageDown)
function setupSplitKeyboardNav() {
  window.addEventListener("keydown", (e) => {
    if (state.viewMode !== "split" || catalogSplit.hidden) return;
    if (document.activeElement === searchInput) return;

    const filtered = getFilteredTools();
    if (filtered.length === 0) return;

    const start = (state.currentPage - 1) * 18;
    const currentTools = filtered.slice(start, start + 18);
    const currentIndex = currentTools.findIndex(t => t.id === state.selectedToolId);
    const totalPages = Math.ceil(filtered.length / 18) || 1;

    if (e.key === "ArrowDown" || e.key === "ArrowRight") {
      e.preventDefault();
      const nextIdx = (currentIndex + 1) % currentTools.length;
      state.selectedToolId = currentTools[nextIdx].id;
      renderSplitView(filtered);
    } else if (e.key === "ArrowUp" || e.key === "ArrowLeft") {
      e.preventDefault();
      const prevIdx = (currentIndex - 1 + currentTools.length) % currentTools.length;
      state.selectedToolId = currentTools[prevIdx].id;
      renderSplitView(filtered);
    } else if (e.key === "PageDown") {
      e.preventDefault();
      if (state.currentPage < totalPages) {
        state.currentPage++;
        renderSplitView(filtered);
      }
    } else if (e.key === "PageUp") {
      e.preventDefault();
      if (state.currentPage > 1) {
        state.currentPage--;
        renderSplitView(filtered);
      }
    } else if (e.key === "Home") {
      e.preventDefault();
      if (currentTools.length > 0) {
        state.selectedToolId = currentTools[0].id;
        renderSplitView(filtered);
      }
    } else if (e.key === "End") {
      e.preventDefault();
      if (currentTools.length > 0) {
        state.selectedToolId = currentTools[currentTools.length - 1].id;
        renderSplitView(filtered);
      }
    }
  });
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
    renderFilterBars();
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

  // Split View Pager Buttons
  if (splitPagePrevious) {
    splitPagePrevious.addEventListener("click", () => {
      if (state.currentPage > 1) {
        state.currentPage--;
        applyFiltersAndRender();
      }
    });
  }
  if (splitPageNext) {
    splitPageNext.addEventListener("click", () => {
      state.currentPage++;
      applyFiltersAndRender();
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
  setupSplitKeyboardNav();
  applyFiltersAndRender();
  initHeroRay();
});
