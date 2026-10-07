#!/bin/sh
# ==============================================================================
# oodiff Clean Uninstaller
# "Safely and thoroughly relinquishes oodiff binaries, packages, and companion tools."
#
# Usage:
#   curl -fsSL https://openooda-tools.github.io/oodiff/uninstall.sh | bash
#   or locally: oodiff-uninstall [options]
#
# Options:
#   --dry-run        Simulate uninstallation without modifying the filesystem
#   --purge          Also purge configuration and cache directories (~/.cache/oodiff)
#   -y, --yes        Proceed without interactive prompts
#   -h, --help       Show this help message
# ==============================================================================

set -eu

# --- Styling & Terminal Discipline -------------------------------------------
if [ -t 1 ] && [ "${NO_COLOR:-}" = "" ] && [ "${TERM:-dumb}" != "dumb" ]; then
    AMBER="\033[38;5;214m"
    CYAN="\033[38;5;51m"
    GREEN="\033[38;5;82m"
    YELLOW="\033[38;5;220m"
    DIM="\033[38;5;242m"
    BOLD="\033[1m"
    RESET="\033[0m"
else
    AMBER="" CYAN="" GREEN="" YELLOW="" DIM="" BOLD="" RESET=""
fi

say()  { printf '%b\n' "$*"; }
dim()  { say "  ${DIM}$*${RESET}"; }
ok()   { say "  ${GREEN}✔${RESET} $*"; }
warn() { say "  ${YELLOW}!${RESET} $*"; }
err()  { say "  ${YELLOW}ERROR:${RESET} $*" >&2; }
step() { say ""; say " ${CYAN}${BOLD}$*${RESET}"; }

banner() {
    say ""
    say "${AMBER}${BOLD}"
    cat <<'BANNER'
        ╔══════════════════════════════════════════════════════════╗
        ║                                                          ║
        ║      ██████╗  ██████╗ ██████╗ ██╗███████╗███████╗        ║
        ║     ██╔═══██╗██╔═══██╗██╔══██╗██║██╔════╝██╔════╝        ║
        ║     ██║   ██║██║   ██║██║  ██║██║█████╗  █████╗          ║
        ║     ██║   ██║██║   ██║██║  ██║██║██╔══╝  ██╔══╝          ║
        ║     ╚██████╔╝╚██████╔╝██████╔╝██║██║     ██║             ║
        ║      ╚═════╝  ╚═════╝ ╚═════╝ ╚═╝╚═╝     ╚═╝             ║
        ║                                                          ║
        ║           openOODA Sovereign Diff Engine                 ║
        ║                   Clean Uninstaller                      ║
        ║                                                          ║
        ╚══════════════════════════════════════════════════════════╝
BANNER
    say "${RESET}"
    say "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    say ""
}

DRY_RUN=0
DO_PURGE=0
AUTO_YES=0

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) DRY_RUN=1; shift ;;
        --purge) DO_PURGE=1; shift ;;
        -y|--yes) AUTO_YES=1; shift ;;
        -h|--help)
            banner
            say "  ${BOLD}Usage:${RESET} oodiff-uninstall [options]"
            say "         curl -fsSL https://openooda-tools.github.io/oodiff/uninstall.sh | bash -s -- [options]"
            say ""
            say "  ${BOLD}Options:${RESET}"
            say "    ${CYAN}--dry-run${RESET}    Simulate removal without modifying host"
            say "    ${CYAN}--purge${RESET}      Also remove configuration and user cache directories"
            say "    ${CYAN}-y, --yes${RESET}    Non-interactive mode"
            say "    ${CYAN}-h, --help${RESET}   Display this manual"
            say ""
            exit 0
            ;;
        *) err "Unknown flag: $1"; exit 1 ;;
    esac
done

banner

if [ "$DRY_RUN" -eq 0 ] && [ "$AUTO_YES" -eq 0 ] && [ -t 0 ]; then
    printf "  Are you sure you want to uninstall oodiff? [y/N]: "
    read -r ans || ans="n"
    case "$ans" in
        [yY]|[yY][eE][sS]) ;;
        *) say "  Uninstallation cancelled."; exit 0 ;;
    esac
    say ""
fi

say "  Scanning substrate for oodiff installations…"
say ""

REMOVED_ANY=0

# --- Phase 1: Package Managers ------------------------------------------------
step "[1/3] Checking system package managers"

# Debian / Ubuntu (dpkg / apt)
if command -v dpkg >/dev/null 2>&1 && dpkg -s oodiff >/dev/null 2>&1; then
    if [ "$DRY_RUN" -eq 1 ]; then
        dim "[dry-run] Would remove Debian package oodiff via apt/dpkg"
    else
        dim "Purging Debian package oodiff…"
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get remove -y oodiff 2>/dev/null || sudo dpkg -r oodiff
        else
            sudo dpkg -r oodiff
        fi
        ok "Removed Debian package ${BOLD}oodiff${RESET}"
    fi
    REMOVED_ANY=1
fi

# Fedora / RHEL (rpm / dnf)
if command -v rpm >/dev/null 2>&1 && rpm -q oodiff >/dev/null 2>&1; then
    if [ "$DRY_RUN" -eq 1 ]; then
        dim "[dry-run] Would remove RPM package oodiff via dnf/rpm"
    else
        dim "Purging RPM package oodiff…"
        if command -v dnf >/dev/null 2>&1; then
            sudo dnf remove -y oodiff 2>/dev/null || sudo rpm -e oodiff
        else
            sudo rpm -e oodiff
        fi
        ok "Removed RPM package ${BOLD}oodiff${RESET}"
    fi
    REMOVED_ANY=1
fi

# Arch Linux (pacman)
if command -v pacman >/dev/null 2>&1; then
    for pkg in oodiff-bin oodiff; do
        if pacman -Qi "$pkg" >/dev/null 2>&1; then
            if [ "$DRY_RUN" -eq 1 ]; then
                dim "[dry-run] Would remove Arch package $pkg via pacman"
            else
                dim "Purging Arch package $pkg…"
                sudo pacman -R --noconfirm "$pkg"
                ok "Removed Arch package ${BOLD}$pkg${RESET}"
            fi
            REMOVED_ANY=1
        fi
    done
fi

if [ "$REMOVED_ANY" -eq 0 ]; then
    dim "No package manager installations detected."
fi

# --- Phase 2: Standalone Binaries & Companion Tools --------------------------
step "[2/3] Checking standalone paths and companion scripts"

STANDARD_TARGETS="
/usr/local/bin/oodiff
/usr/local/bin/oodiff-uninstall
/usr/bin/oodiff
/usr/bin/oodiff-uninstall
${HOME}/.local/bin/oodiff
${HOME}/.local/bin/oodiff-uninstall
${HOME}/.openooda/bin/oodiff
${HOME}/.openooda/bin/oodiff-uninstall
"

for p in $STANDARD_TARGETS; do
    if [ -f "$p" ]; then
        if [ "$DRY_RUN" -eq 1 ]; then
            dim "[dry-run] Would delete file: $p"
        else
            if [ -w "$p" ] || [ -w "$(dirname "$p")" ]; then
                rm -f "$p"
            else
                sudo rm -f "$p"
            fi
            ok "Removed file ${BOLD}$p${RESET}"
        fi
        REMOVED_ANY=1
    fi
done

# --- Phase 3: Purge Cache & Config --------------------------------------------
step "[3/3] User cache and state cleanup"

USER_STATE_PATHS="
${HOME}/.cache/oodiff
${HOME}/.config/oodiff
"

for d in $USER_STATE_PATHS; do
    if [ -d "$d" ]; then
        if [ "$DO_PURGE" -eq 1 ]; then
            if [ "$DRY_RUN" -eq 1 ]; then
                dim "[dry-run] Would purge directory: $d"
            else
                rm -rf "$d"
                ok "Purged directory ${BOLD}$d${RESET}"
            fi
            REMOVED_ANY=1
        else
            dim "Preserved state directory: $d (use --purge to delete)"
        fi
    fi
done

say ""
say "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

if [ "$DRY_RUN" -eq 1 ]; then
    ok "Dry run simulation finished. No filesystem changes were made."
elif [ "$REMOVED_ANY" -eq 1 ]; then
    ok "oodiff has been cleanly and completely uninstalled."
else
    warn "No oodiff binaries, packages, or scripts were found on this system."
fi

# Verification
if [ "$DRY_RUN" -eq 0 ] && command -v oodiff >/dev/null 2>&1; then
    REMAINING="$(command -v oodiff)"
    warn "Note: An oodiff executable is still detected on PATH at ${BOLD}${REMAINING}${RESET}."
fi

say ""
