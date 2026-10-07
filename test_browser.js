// Automated Browser End-to-End Verification Test for tools.openooda.org
const cp = require("child_process");
const http = require("http");
const fs = require("fs");
const path = require("path");

const PORT = 8899;
const ROOT = __dirname;

// Simple static HTTP server
const mimeTypes = {
  ".html": "text/html",
  ".css": "text/css",
  ".js": "application/javascript",
  ".json": "application/json",
  ".svg": "image/svg+xml",
  ".png": "image/png"
};

const server = http.createServer((req, res) => {
  let reqPath = req.url.split("?")[0];
  if (reqPath === "/") reqPath = "/index.html";
  const filePath = path.join(ROOT, reqPath);

  if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
    const ext = path.extname(filePath);
    res.writeHead(200, { "Content-Type": mimeTypes[ext] || "text/plain" });
    fs.createReadStream(filePath).pipe(res);
  } else {
    res.writeHead(404);
    res.end("Not Found");
  }
});

server.listen(PORT, async () => {
  const chrome = cp.spawn("chromium", [
    "--headless=new", "--disable-gpu", "--remote-debugging-port=9232",
    "--window-size=1200,900", `http://127.0.0.1:${PORT}/`
  ], { stdio: "ignore" });

  try {
    await new Promise(r => setTimeout(r, 2000));
    const tabs = await fetch("http://127.0.0.1:9232/json").then(r => r.json());
    const pageTab = tabs.find(t => t.type === "page");
    if (!pageTab) throw new Error("No page tab found in chromium");

    const ws = new WebSocket(pageTab.webSocketDebuggerUrl);
    await new Promise(r => ws.onopen = r);

    function send(method, params = {}) {
      return new Promise((resolve) => {
        const id = Math.floor(Math.random() * 100000);
        const handler = (msg) => {
          const data = JSON.parse(msg.data);
          if (data.id === id) {
            ws.removeEventListener("message", handler);
            resolve(data.result);
          }
        };
        ws.addEventListener("message", handler);
        ws.send(JSON.stringify({ id, method, params }));
      });
    }

    async function evalJs(expr) {
      const res = await send("Runtime.evaluate", { expression: expr, returnByValue: true, awaitPromise: true });
      return res.result ? res.result.value : null;
    }

    // Test 1: Cards vs Split view toggling and [hidden] style enforcement
    const cardsInitial = await evalJs(`window.getComputedStyle(document.getElementById("plugin-grid")).display`);
    const splitInitial = await evalJs(`window.getComputedStyle(document.getElementById("catalog-split")).display`);
    if (cardsInitial !== "grid" || splitInitial !== "none") {
      throw new Error(`Initial displays unexpected: cards=${cardsInitial}, split=${splitInitial}`);
    }

    await evalJs(`document.querySelector("[data-view=\x27split\x27]").click()`);
    const cardsAfterSplit = await evalJs(`window.getComputedStyle(document.getElementById("plugin-grid")).display`);
    const splitAfterSplit = await evalJs(`window.getComputedStyle(document.getElementById("catalog-split")).display`);
    if (cardsAfterSplit !== "none" || splitAfterSplit !== "grid") {
      throw new Error(`Split mode displays unexpected: cards=${cardsAfterSplit}, split=${splitAfterSplit}`);
    }

    // Test 2: Split view keyboard navigation
    const selectedBefore = await evalJs(`document.querySelector(".split-tile.is-selected").dataset.toolId`);
    await evalJs(`window.dispatchEvent(new KeyboardEvent("keydown", { key: "ArrowDown" }))`);
    const selectedAfterDown = await evalJs(`document.querySelector(".split-tile.is-selected").dataset.toolId`);
    if (selectedAfterDown === selectedBefore) {
      throw new Error("ArrowDown did not update selected tool");
    }

    await evalJs(`window.dispatchEvent(new KeyboardEvent("keydown", { key: "ArrowUp" }))`);
    const selectedAfterUp = await evalJs(`document.querySelector(".split-tile.is-selected").dataset.toolId`);
    if (selectedAfterUp !== selectedBefore) {
      throw new Error("ArrowUp did not navigate back to original tool");
    }

    // Test 3: Search & token filtering
    await evalJs(`document.querySelector("[data-view=\x27cards\x27]").click()`);
    await evalJs(`document.getElementById("search-input").value = "status:released"; document.getElementById("search-input").dispatchEvent(new Event("input"))`);
    const countReleased = await evalJs(`document.getElementById("tool-count").textContent`);
    if (!countReleased.startsWith("19")) {
      throw new Error(`Expected 19 tools for status:released, got ${countReleased}`);
    }

    await evalJs(`document.getElementById("clear-filters").click()`);
    const countAll = await evalJs(`document.getElementById("tool-count").textContent`);
    if (!countAll.startsWith("19")) {
      throw new Error(`Expected 19 tools after clear-filters, got ${countAll}`);
    }

    // Test 4: Viewport responsiveness across widths (no horizontal overflow)
    for (const w of [1200, 768, 600, 375, 320]) {
      await send("Emulation.setDeviceMetricsOverride", { width: w, height: 800, deviceScaleFactor: 1, mobile: w < 768 });
      await new Promise(r => setTimeout(r, 200));
      const diff = await evalJs(`document.documentElement.scrollWidth - window.innerWidth`);
      if (diff > 0) {
        throw new Error(`Horizontal blowout at ${w}px viewport width: overflow ${diff}px`);
      }
    }

    // Test 5: Theme switching and persistence
    await evalJs(`document.querySelector(".theme-toggle").click()`);
    const storedTheme = await evalJs(`localStorage.getItem("openooda-theme")`);
    if (!storedTheme) throw new Error("Theme not saved to localStorage");

    // Test 6: Marquee animation pause toggle
    const pauseBtn = await evalJs(`document.getElementById("recent-feed-toggle") !== null`);
    if (!pauseBtn) throw new Error("Marquee pause button not found");
    await evalJs(`document.getElementById("recent-feed-toggle").click()`);
    const isPaused = await evalJs(`document.getElementById("recent-latest").classList.contains("is-paused")`);
    if (!isPaused) throw new Error("Marquee toggle button did not pause animation");

    // Test 7: Hidden gems random selection and shuffle re-roll
    const gemsInitial = await evalJs(`Array.from(document.querySelectorAll("#gems-grid .gem-card")).map(c => c.dataset.toolId)`);
    if (gemsInitial.length !== 8) {
      throw new Error(`Expected 8 randomized hidden gems, got ${gemsInitial.length}`);
    }
    await evalJs(`document.getElementById("gems-shuffle-btn").click()`);
    const gemsAfterShuffle = await evalJs(`Array.from(document.querySelectorAll("#gems-grid .gem-card")).map(c => c.dataset.toolId)`);
    if (gemsAfterShuffle.length !== 8) {
      throw new Error(`Expected 8 hidden gems after shuffle, got ${gemsAfterShuffle.length}`);
    }

    console.log("[PASS] Browser headless E2E verification passed all 7 test suites");
    ws.close();
    chrome.kill();
    server.close();
    process.exit(0);
  } catch (err) {
    console.error("Browser E2E test failed:", err);
    chrome.kill();
    server.close();
    process.exit(1);
  }
});
