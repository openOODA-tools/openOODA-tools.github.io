# openOODA-tools.github.io: House Laws & Agent Engineering Standards (v1)

This document is the **single canonical source of truth** for all code, architecture, and system integration standards across `openOODA-tools.github.io` (the official web portal and asset gateway for openOODA Tools). Every human contributor and AI agent must strictly follow these rules without exception.

---

## 1. Web Architecture & Privacy Standards

- **Zero External Runtime Dependencies**: Never import third-party CDNs, Google Fonts, external analytics, trackers, or cookies. All styling, SVG assets, and scripts must be 100% self-hosted and sovereign.
- **Pure Semantic HTML5 & CSS**: Fast, responsive layout optimized for mobile and desktop screens. Instant render performance ($\le 50\text{ms}$ FCP).
- **Single-Source Distribution**: Web install scripts (`https://openooda-tools.github.io/<tool>/install.sh`) and uninstall scripts (`https://openooda-tools.github.io/<tool>/uninstall.sh`) must match repository counterparts byte-for-byte.

---

## 2. Tool Coverage & Alignment Invariant

All 7 sovereign openOODA tools must be fully documented and represented:
1. **`oosh`** — Sovereign interactive command shell
2. **`oogrep`** — Capability-bounded recursive regex search
3. **`oodiff`** — Capability-bounded file & directory comparison
4. **`oofind`** — Capability-bounded file finding utility
5. **`oojq`** — Capability-bounded JSON transformation engine
6. **`ootail`** — Capability-bounded streaming file & event follower
7. **`oote`** — Sovereign unified theming and color engine

Every tool card on `index.html` and dedicated subpage (`<tool>/index.html`) must provide:
- Verified latest release version badge
- One-liner standalone curl install snippet
- DNF, DEB, and Arch PKGBUILD instructions
- Clean uninstallation instructions (CLI helper, standalone web uninstaller, `--purge`)
- Direct links to GitHub repository and release assets

---

## 3. System Architecture: systemd & Tri-Distribution Compliance (Arch, Fedora, Debian)

All openOODA utilities cataloged on this portal adhere to a sovereign Linux architecture:

1. **Pure systemd-Native Citizenship**:
   - Services managed natively in `/etc/systemd/system/` (or `~/.config/systemd/user/` for user services). Drop-in overrides in `<unit>.service.d/*.conf`.
   - Declarative system accounts via `systemd-sysusers` in `/etc/sysusers.d/*.conf`; directory lifecycle via `systemd-tmpfiles` in `/etc/tmpfiles.d/*.conf`.
   - Native sandboxing directives (`ProtectSystem=strict`, `ProtectHome=read-only`, `PrivateTmp=true`, `NoNewPrivileges=true`).
   - Logging exclusively via `systemd-journald`; scheduled tasks via `systemd.timer`.
   - Standard system directories: `$RUNTIME_DIRECTORY` (`/run/openooda`), `$STATE_DIRECTORY` (`/var/lib/openooda`), `$CONFIGURATION_DIRECTORY` (`/etc/openooda`).

2. **Tri-Distribution Standards (Arch, Fedora, Debian)**:
   - **Arch Linux**: Standard `PKGBUILD` and `packaging/arch/PKGBUILD`, producing `.pkg.tar.zst` packages via `makepkg` or GNU `tar --zstd`.
   - **Fedora / RHEL**: Standard `.spec` files under `packaging/`, producing native RPM packages (`.rpm`).
   - **Debian / Ubuntu**: Standard Debian source packaging under `packaging/debian/`, producing native `.deb` packages.
   - **Universal Installers & Dedicated Uninstallers**: Every utility provides both universal `install.sh` and dedicated `uninstall.sh`, plus an installed companion `<tool>-uninstall` CLI. Clean uninstallation guarantees zero host residue.

---

## 4. Verification & QA Gate

Before any commit is pushed to `main`:
1. **URL Validity**: All internal links (`<tool>/`, `favicon.svg`) and outbound links must be valid.
2. **Script Parity**: Every `<tool>/install.sh` and `<tool>/uninstall.sh` must be verified executable and pass `bash -n` syntax check.
3. **HTML Validation**: Valid markup across `index.html` and all subpages.
