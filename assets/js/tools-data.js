// openOODA Tools Catalog Data (Actual Repositories)
// Generated automatically with 100% parity for all 19 active repositories

export const TOOLS_DATA = [
  {
    "id": "oosh",
    "name": "oosh",
    "category": "Shell & Terminal",
    "role": "SOVEREIGN SHELL",
    "version": "v1.0.1",
    "status": "released",
    "monogram": "SH",
    "accent": "#00e676",
    "description": "Sovereign interactive command plane engineered for direct systems control, ambient environment integration, and POSIX muscle memory.",
    "gem": true,
    "gemFact": "Ambient Intent \u00b7 Zero Ambient Auth",
    "installCommand": "curl -fsSL https://openooda-tools.github.io/oosh/install.sh | bash",
    "overviewUrl": "oosh/",
    "repoUrl": "https://github.com/openOODA-tools/oosh",
    "tags": [
      "mcp-native",
      "zero-ambient-auth",
      "posix-muscle",
      "pure-openooda"
    ],
    "capabilities": [
      "&TermCap",
      "&ProcCap",
      "&EnvCap",
      "&McpCap"
    ],
    "addedAt": "2026-08-15"
  },
  {
    "id": "oogrep",
    "name": "oogrep",
    "category": "Search & Inspection",
    "role": "REGEX SEARCH",
    "version": "v0.3.2",
    "status": "released",
    "monogram": "GP",
    "accent": "#00e5ff",
    "description": "Capability-bounded recursive regex search. Fast directory traversal with column tracking, colored hunks, and an stdio MCP surface.",
    "gem": true,
    "gemFact": "Myers Regex Engine \u00b7 stdio MCP Surface",
    "installCommand": "curl -fsSL https://openooda-tools.github.io/oogrep/install.sh | bash",
    "overviewUrl": "oogrep/",
    "repoUrl": "https://github.com/openOODA-tools/oogrep",
    "tags": [
      "mcp-native",
      "gitignore-aware",
      "posix-parity",
      "pure-openooda"
    ],
    "capabilities": [
      "&FsReadCap",
      "&McpCap"
    ],
    "addedAt": "2026-08-20"
  },
  {
    "id": "oodiff",
    "name": "oodiff",
    "category": "Diff & Comparison",
    "role": "AST & TEXT DIFF",
    "version": "v0.3.1",
    "status": "released",
    "monogram": "DF",
    "accent": "#ffb300",
    "description": "Capability-bounded file and directory comparison. Byte-for-byte GNU normal and unified diff parity with negative-trust sandbox.",
    "gem": true,
    "gemFact": "GNU Byte-for-Byte Parity \u00b7 LCS Myers Algorithm",
    "installCommand": "curl -fsSL https://openooda-tools.github.io/oodiff/install.sh | bash",
    "overviewUrl": "oodiff/",
    "repoUrl": "https://github.com/openOODA-tools/oodiff",
    "tags": [
      "gnu-parity",
      "lcs-myers",
      "apt-dnf",
      "pure-openooda"
    ],
    "capabilities": [
      "&FsReadCap",
      "&McpCap"
    ],
    "addedAt": "2026-08-28"
  },
  {
    "id": "oofind",
    "name": "oofind",
    "category": "Files & Navigation",
    "role": "DIR TRAVERSAL",
    "version": "v0.2.1",
    "status": "released",
    "monogram": "FD",
    "accent": "#64ffda",
    "description": "Fast directory traversal with glob matching, type filtering, -print0 for xargs piping, and structured JSON output.",
    "gem": false,
    "gemFact": "Structured JSON Lines \u00b7 Fast Glob Traversal",
    "installCommand": "curl -fsSL https://openooda-tools.github.io/oofind/install.sh | bash",
    "overviewUrl": "oofind/",
    "repoUrl": "https://github.com/openOODA-tools/oofind",
    "tags": [
      "mcp-native",
      "json-lines",
      "posix-parity",
      "pure-openooda"
    ],
    "capabilities": [
      "&FsReadCap",
      "&McpCap"
    ],
    "addedAt": "2026-09-02"
  },
  {
    "id": "oojq",
    "name": "oojq",
    "category": "Data & Streaming",
    "role": "STREAMING JSON",
    "version": "v0.1.1",
    "status": "released",
    "monogram": "JQ",
    "accent": "#ff4081",
    "description": "High-fidelity jq replacement. Exact arithmetic boundaries, full filter parser, and capability-isolated JSON transformation.",
    "gem": true,
    "gemFact": "Exact Arithmetic Boundaries \u00b7 Zero JSON Leakage",
    "installCommand": "curl -fsSL https://openooda-tools.github.io/oojq/install.sh | bash",
    "overviewUrl": "oojq/",
    "repoUrl": "https://github.com/openOODA-tools/oojq",
    "tags": [
      "exact-math",
      "zero-leakage",
      "pure-openooda",
      "mcp-native"
    ],
    "capabilities": [
      "&FsReadCap",
      "&McpCap"
    ],
    "addedAt": "2026-09-05"
  },
  {
    "id": "ootail",
    "name": "ootail",
    "category": "Data & Streaming",
    "role": "STREAM FOLLOWER",
    "version": "v0.2.0",
    "status": "released",
    "monogram": "TL",
    "accent": "#e040fb",
    "description": "Capability-bounded streaming file and event follower. Inotify change events, line and byte windowing, and native MCP stdio server.",
    "gem": true,
    "gemFact": "Inotify Event Follower \u00b7 Stdio MCP Server",
    "installCommand": "curl -fsSL https://openooda-tools.github.io/ootail/install.sh | bash",
    "overviewUrl": "ootail/",
    "repoUrl": "https://github.com/openOODA-tools/ootail",
    "tags": [
      "inotify-watch",
      "truncate-safe",
      "pure-openooda",
      "mcp-native"
    ],
    "capabilities": [
      "&FsReadCap",
      "&InotifyCap",
      "&McpCap"
    ],
    "addedAt": "2026-09-10"
  },
  {
    "id": "oote",
    "name": "oote",
    "category": "Theme & Styling",
    "role": "THEME ENGINE",
    "version": "v0.1.0",
    "status": "released",
    "monogram": "TE",
    "accent": "#7c4dff",
    "description": "Sovereign, unified theming and color styling engine. 25 circadian calendar themes, dynamic terminal palette synchronization, and MCP.",
    "gem": true,
    "gemFact": "25 Circadian Themes \u00b7 Global Ecosystem Sync",
    "installCommand": "curl -fsSL https://openooda-tools.github.io/oote/install.sh | bash",
    "overviewUrl": "oote/",
    "repoUrl": "https://github.com/openOODA-tools/oote",
    "tags": [
      "theme-engine",
      "ansi-styling",
      "circadian-palettes",
      "pure-openooda"
    ],
    "capabilities": [
      "&TermCap",
      "&EnvCap",
      "&McpCap"
    ],
    "addedAt": "2026-09-15"
  },
  {
    "id": "oofetch",
    "name": "oofetch",
    "category": "System & Monitor",
    "role": "SYSTEM FETCH",
    "version": "v0.2.0",
    "status": "released",
    "monogram": "FT",
    "accent": "#ffab40",
    "description": "Sovereign system fetch and environment showcase. Dynamic ASCII mascots, hardware & OS telemetry, zero ambient leakage, and stdio MCP.",
    "gem": true,
    "gemFact": "Dynamic ASCII Mascots \u00b7 Hardware & OS Telemetry",
    "installCommand": "curl -fsSL https://openooda-tools.github.io/oofetch/install.sh | bash",
    "overviewUrl": "oofetch/",
    "repoUrl": "https://github.com/openOODA-tools/oofetch",
    "tags": [
      "ascii-art",
      "system-info",
      "zero-ambient-leak",
      "pure-openooda"
    ],
    "capabilities": [
      "&SysInfoCap",
      "&EnvCap",
      "&McpCap"
    ],
    "addedAt": "2026-09-18"
  },
  {
    "id": "oocat",
    "name": "oocat",
    "category": "Search & Inspection",
    "role": "VIEWER & PAGER",
    "version": "v0.2.0",
    "status": "released",
    "monogram": "CT",
    "accent": "#ffd740",
    "description": "Capability-bounded syntax-highlighting file viewer and pager. Multi-language lexing, range bounded paging, and stdio MCP inspection.",
    "gem": false,
    "gemFact": "Multi-Language Lexing \u00b7 Range Bounded Paging",
    "installCommand": "curl -fsSL https://openooda-tools.github.io/oocat/install.sh | bash",
    "overviewUrl": "oocat/",
    "repoUrl": "https://github.com/openOODA-tools/oocat",
    "tags": [
      "syntax-highlighting",
      "pager-integration",
      "pure-openooda"
    ],
    "capabilities": [
      "&FsReadCap",
      "&TermCap",
      "&McpCap"
    ],
    "addedAt": "2026-09-20"
  },
  {
    "id": "ootop",
    "name": "ootop",
    "category": "System & Monitor",
    "role": "PROCESS MONITOR",
    "version": "v0.2.0",
    "status": "released",
    "monogram": "TP",
    "accent": "#69f0ae",
    "description": "Sovereign real-time system monitor and dashboard. Systemd slice telemetry, dynamic mascot moods, and streaming MCP telemetry.",
    "gem": false,
    "gemFact": "Systemd Slice Telemetry \u00b7 Mascot Mood Dynamics",
    "installCommand": "curl -fsSL https://openooda-tools.github.io/ootop/install.sh | bash",
    "overviewUrl": "ootop/",
    "repoUrl": "https://github.com/openOODA-tools/ootop",
    "tags": [
      "systemd-slices",
      "emotional-mascot",
      "mcp-telemetry",
      "pure-openooda"
    ],
    "capabilities": [
      "&ProcCap",
      "&SysInfoCap",
      "&TermCap",
      "&McpCap"
    ],
    "addedAt": "2026-09-22"
  },
  {
    "id": "oofzf",
    "name": "oofzf",
    "category": "Search & Inspection",
    "role": "FUZZY FINDER",
    "version": "v0.2.0",
    "status": "released",
    "monogram": "FZ",
    "accent": "#18ffff",
    "description": "Sovereign interactive fuzzy finder and candidate ranker. Subsequence scoring with consecutive run bonuses, oote palettes, and stdio MCP.",
    "gem": true,
    "gemFact": "Subsequence Scoring \u00b7 Consecutive Run Bonus",
    "installCommand": "curl -fsSL https://openooda-tools.github.io/oofzf/install.sh | bash",
    "overviewUrl": "oofzf/",
    "repoUrl": "https://github.com/openOODA-tools/oofzf",
    "tags": [
      "fuzzy-matching",
      "mcp-surface",
      "oote-palettes",
      "pure-openooda"
    ],
    "capabilities": [
      "&TermCap",
      "&FsReadCap",
      "&McpCap"
    ],
    "addedAt": "2026-09-25"
  },
  {
    "id": "ools",
    "name": "ools",
    "category": "Files & Navigation",
    "role": "DIR LISTER",
    "version": "v0.2.0",
    "status": "released",
    "monogram": "LS",
    "accent": "#b388ff",
    "description": "Sovereign directory lister and metadata classifier. Multi-column grid rendering, detailed long-format tables, oote palettes, and native MCP stdio server.",
    "gem": true,
    "gemFact": "Metadata Classification \u00b7 Multi-Column Grid",
    "installCommand": "curl -fsSL https://openooda-tools.github.io/ools/install.sh | bash",
    "overviewUrl": "ools/",
    "repoUrl": "https://github.com/openOODA-tools/ools",
    "tags": [
      "metadata-class",
      "zero-ambient-auth",
      "mcp-surface",
      "pure-openooda"
    ],
    "capabilities": [
      "&FsReadCap",
      "&EnvCap",
      "&McpCap"
    ],
    "addedAt": "2026-09-28"
  },
  {
    "id": "ootree",
    "name": "ootree",
    "category": "Files & Navigation",
    "role": "TREE VISUALIZER",
    "version": "v0.2.0",
    "status": "released",
    "monogram": "TR",
    "accent": "#64ffda",
    "description": "Sovereign directory hierarchy visualizer. Depth limiting, size sorting, oote color formatting, and MCP tree exploration.",
    "gem": false,
    "gemFact": "Depth-Bounded Traversal \u00b7 Indent Matrix",
    "installCommand": "curl -fsSL https://openooda-tools.github.io/ootree/install.sh | bash",
    "overviewUrl": "ootree/",
    "repoUrl": "https://github.com/openOODA-tools/ootree",
    "tags": [
      "tree-traversal",
      "depth-limiting",
      "mcp-native",
      "pure-openooda"
    ],
    "capabilities": [
      "&FsReadCap",
      "&ProcessCap",
      "&EnvCap",
      "&McpCap"
    ],
    "addedAt": "2026-10-02"
  },
  {
    "id": "ooclock",
    "name": "ooclock",
    "category": "System & Monitor",
    "role": "MATRIX CLOCK",
    "version": "v0.1.0",
    "status": "released",
    "monogram": "CK",
    "accent": "#00e5ff",
    "description": "Sovereign TUI digital matrix clock. Military time, custom seconds refresh cadences, color themes, and terminal resize responsiveness.",
    "gem": false,
    "gemFact": "Matrix Clock \u00b7 Monotonic Time Sync",
    "installCommand": "curl -fsSL https://openooda-tools.github.io/ooclock/install.sh | bash",
    "overviewUrl": "ooclock/",
    "repoUrl": "https://github.com/openOODA-tools/ooclock",
    "tags": [
      "tui-clock",
      "time-sync",
      "oote-themes",
      "pure-openooda"
    ],
    "capabilities": [
      "&TimeCap",
      "&TermCap",
      "&McpCap"
    ],
    "addedAt": "2026-10-03"
  },
  {
    "id": "oosed",
    "name": "oosed",
    "category": "Data & Streaming",
    "role": "STREAM EDITOR",
    "version": "v0.1.0",
    "status": "released",
    "monogram": "SD",
    "accent": "#ff4081",
    "description": "Capability-bounded stream editor. Pattern matching, text substitution, in-place editing safety, and streaming transform pipeline.",
    "gem": false,
    "gemFact": "Stream Transformations \u00b7 Substitution Engine",
    "installCommand": "curl -fsSL https://openooda-tools.github.io/oosed/install.sh | bash",
    "overviewUrl": "oosed/",
    "repoUrl": "https://github.com/openOODA-tools/oosed",
    "tags": [
      "stream-editor",
      "regex-substitution",
      "pure-openooda"
    ],
    "capabilities": [
      "&FsReadCap",
      "&FsWriteCap",
      "&McpCap"
    ],
    "addedAt": "2026-10-04"
  },
  {
    "id": "ootar",
    "name": "ootar",
    "category": "Files & Navigation",
    "role": "ARCHIVE MANAGER",
    "version": "v0.1.0",
    "status": "released",
    "monogram": "AR",
    "accent": "#ff4081",
    "description": "Traversal-resistant archive utility. Prevents zip-slip and path traversal attacks by construction with capability-bounded extraction.",
    "gem": true,
    "gemFact": "Traversal-Resistant \u00b7 Zero Zip-Slip",
    "installCommand": "curl -fsSL https://openooda-tools.github.io/ootar/install.sh | bash",
    "overviewUrl": "ootar/",
    "repoUrl": "https://github.com/openOODA-tools/ootar",
    "tags": [
      "tar-archive",
      "path-sanitization",
      "mcp-native",
      "pure-openooda"
    ],
    "capabilities": [
      "&FsReadCap",
      "&FsWriteCap",
      "&McpCap"
    ],
    "addedAt": "2026-10-05"
  },
  {
    "id": "oops",
    "name": "oops",
    "category": "System & Monitor",
    "role": "PROCESS TABLE",
    "version": "v0.2.0",
    "status": "released",
    "monogram": "PS",
    "accent": "#00b0ff",
    "description": "Sovereign process table and tree inspector. Visualizes user sessions, cgroups, systemd units, and capability privileges.",
    "gem": false,
    "gemFact": "Process Tree Hierarchy \u00b7 Capability Audit",
    "installCommand": "curl -fsSL https://openooda-tools.github.io/oops/install.sh | bash",
    "overviewUrl": "oops/",
    "repoUrl": "https://github.com/openOODA-tools/oops",
    "tags": [
      "process-table",
      "process-tree",
      "systemd-cgroups",
      "pure-openooda"
    ],
    "capabilities": [
      "&ProcCap",
      "&McpCap"
    ],
    "addedAt": "2026-10-06"
  },
  {
    "id": "oocurl",
    "name": "oocurl",
    "category": "Network & Egress",
    "role": "HTTP CLIENT",
    "version": "v0.2.0",
    "status": "released",
    "monogram": "CL",
    "accent": "#ffd740",
    "description": "Capability-bounded HTTP/HTTPS client. Zero ambient network egress, strict TLS validation, and streaming response output.",
    "gem": true,
    "gemFact": "Explicit NetCap \u00b7 Zero Ambient Egress",
    "installCommand": "curl -fsSL https://openooda-tools.github.io/oocurl/install.sh | bash",
    "overviewUrl": "oocurl/",
    "repoUrl": "https://github.com/openOODA-tools/oocurl",
    "tags": [
      "http-client",
      "tls-validation",
      "zero-ambient-egress",
      "pure-openooda"
    ],
    "capabilities": [
      "&NetCap",
      "&TlsCap",
      "&McpCap"
    ],
    "addedAt": "2026-10-06"
  },
  {
    "id": "oowatch",
    "name": "oowatch",
    "category": "System & Monitor",
    "role": "INTERVAL WATCHER",
    "version": "v0.1.0",
    "status": "released",
    "monogram": "WT",
    "accent": "#00b0ff",
    "description": "Continuous command runner and watcher. Highlight deltas between consecutive executions with jitter-free timer scheduling.",
    "gem": false,
    "gemFact": "Periodic Execution \u00b7 Delta Highlight",
    "installCommand": "curl -fsSL https://openooda-tools.github.io/oowatch/install.sh | bash",
    "overviewUrl": "oowatch/",
    "repoUrl": "https://github.com/openOODA-tools/oowatch",
    "tags": [
      "watch-runner",
      "delta-highlighting",
      "mcp-native",
      "pure-openooda"
    ],
    "capabilities": [
      "&TimeCap",
      "&ProcCap",
      "&McpCap"
    ],
    "addedAt": "2026-10-07"
  },
  {
    "id": "oomcp",
    "name": "oomcp",
    "category": "System & Monitor",
    "role": "COMPOSITE MCP GATEWAY",
    "version": "v0.1.0",
    "status": "released",
    "monogram": "CP",
    "accent": "#bd93f9",
    "description": "Sovereign Model Context Protocol (MCP) composite gateway & tool router. Single unified stdio endpoint for all openOODA userland tools.",
    "gem": true,
    "gemFact": "Composite Gateway \u00b7 Dynamic Discovery",
    "installCommand": "curl -fsSL https://openooda-tools.github.io/oomcp/install.sh | bash",
    "overviewUrl": "oomcp/",
    "repoUrl": "https://github.com/openOODA-tools/oomcp",
    "tags": [
      "mcp-gateway",
      "composite-router",
      "systemd-native",
      "pure-openooda"
    ],
    "capabilities": [
      "&ProcessCap",
      "&FsReadCap",
      "&EnvCap",
      "&McpCap"
    ],
    "addedAt": "2026-10-07"
  }
];

export const CATEGORIES = [
  "All Categories",
  "Data & Streaming",
  "Diff & Comparison",
  "Files & Navigation",
  "Network & Egress",
  "Search & Inspection",
  "Shell & Terminal",
  "System & Monitor",
  "Theme & Styling"
];

export const STATUS_FILTERS = [
  { id: "all", label: "All Repos", count: 20 },
  { id: "released", label: "Released", count: 20 }
];
