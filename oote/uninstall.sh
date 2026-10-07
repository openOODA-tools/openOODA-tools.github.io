#!/bin/sh
# ==============================================================================
# oote Sovereign Clean Uninstaller
# "Removes oote binary, package installations, helpers, and optional config."
#
# Usage:
#   curl -fsSL https://openooda-tools.github.io/oote/uninstall.sh | bash
#   or: ./uninstall.sh [options]
#
# Options:
#   --prefix <dir>       Target directory where standalone binary was installed
#   --purge              Remove theme configuration (~/.openooda/theme.oot) and cache
#   --dry-run            Simulate uninstallation without modifying the system
#   -y, --yes            Assume yes to all prompts (non-interactive)
#   -h, --help           Show this help message
# ==============================================================================

set -eu

if [ -t 1 ] && [ "${NO_COLOR:-}" = "" ] && [ "${TERM:-dumb}" != "dumb" ]; then
    CYAN="\033[38;5;51m"
    GREEN="\033[38;5;82m"
    YELLOW="\033[38;5;220m"
    RED="\033[38;5;196m"
    DIM="\033[38;5;242m"
    BOLD="\033[1m"
    RESET="\033[0m"
else
    CYAN="" GREEN="" YELLOW="" RED="" DIM="" BOLD="" RESET=""
fi

say()  { printf '%b\n' "$*"; }
ok()   { say "  ${GREEN}✔${RESET} $*"; }
warn() { say "  ${YELLOW}!${RESET} $*"; }
err()  { say "  ${RED}ERROR:${RESET} $*" >&2; }
step() { say ""; say " ${CYAN}${BOLD}$*${RESET}"; }

PREFIX=""
PURGE=0
DRY_RUN=0
ASSUME_YES=0

while [ $# -gt 0 ]; do
    case "$1" in
        --prefix)
            PREFIX="$2"
            shift 2
            ;;
        --purge)
            PURGE=1
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        -y|--yes)
            ASSUME_YES=1
            shift
            ;;
        -h|--help)
            say "Usage: uninstall.sh [options]"
            say "Options:"
            say "  --prefix <dir>       Target directory where standalone binary was installed"
            say "  --purge              Remove theme configuration (~/.openooda/theme.oot) and cache"
            say "  --dry-run            Simulate uninstallation without disk writes"
            say "  -y, --yes            Assume yes to all prompts"
            say "  -h, --help           Show this help message"
            exit 0
            ;;
        *)
            err "Unknown option: $1"
            exit 2
            ;;
    esac
done

step "oote Sovereign Clean Uninstaller"

REMOVED_COUNT=0

# --- 1. Detect Package Manager Installations ---
if command -v dpkg >/dev/null 2>&1 && dpkg -s oote >/dev/null 2>&1; then
    if [ "$DRY_RUN" -eq 1 ]; then
        say "  [dry-run] Would remove Debian package 'oote' (dpkg/apt)"
    else
        say "  Removing Debian package 'oote'..."
        if [ "$PURGE" -eq 1 ]; then
            sudo apt-get purge -y oote 2>/dev/null || sudo dpkg -P oote 2>/dev/null || true
        else
            sudo apt-get remove -y oote 2>/dev/null || sudo dpkg -r oote 2>/dev/null || true
        fi
        ok "Removed Debian package 'oote'"
    fi
    REMOVED_COUNT=$((REMOVED_COUNT + 1))
fi

if command -v rpm >/dev/null 2>&1 && rpm -q oote >/dev/null 2>&1; then
    if [ "$DRY_RUN" -eq 1 ]; then
        say "  [dry-run] Would remove RPM package 'oote' (rpm/dnf)"
    else
        say "  Removing RPM package 'oote'..."
        sudo dnf remove -y oote 2>/dev/null || sudo rpm -e oote 2>/dev/null || true
        ok "Removed RPM package 'oote'"
    fi
    REMOVED_COUNT=$((REMOVED_COUNT + 1))
fi

if command -v pacman >/dev/null 2>&1; then
    if pacman -Q oote >/dev/null 2>&1; then
        if [ "$DRY_RUN" -eq 1 ]; then
            say "  [dry-run] Would remove Arch package 'oote' (pacman)"
        else
            say "  Removing Arch package 'oote'..."
            sudo pacman -R --noconfirm oote 2>/dev/null || true
            ok "Removed Arch package 'oote'"
        fi
        REMOVED_COUNT=$((REMOVED_COUNT + 1))
    elif pacman -Q oote-bin >/dev/null 2>&1; then
        if [ "$DRY_RUN" -eq 1 ]; then
            say "  [dry-run] Would remove Arch package 'oote-bin' (pacman)"
        else
            say "  Removing Arch package 'oote-bin'..."
            sudo pacman -R --noconfirm oote-bin 2>/dev/null || true
            ok "Removed Arch package 'oote-bin'"
        fi
        REMOVED_COUNT=$((REMOVED_COUNT + 1))
    fi
fi

# --- 2. Remove Standalone Binaries and Helpers ---
PATHS_TO_CHECK=""
if [ -n "$PREFIX" ]; then
    PATHS_TO_CHECK="$PREFIX/oote $PREFIX/oote-uninstall"
fi

PATHS_TO_CHECK="$PATHS_TO_CHECK
/usr/local/bin/oote
/usr/local/bin/oote-uninstall
${HOME}/.local/bin/oote
${HOME}/.local/bin/oote-uninstall
/usr/bin/oote
/usr/bin/oote-uninstall
${HOME}/.openooda/bin/oote
${HOME}/.openooda/bin/oote-uninstall"

# Check if which/command finds any other binary in PATH
if command -v oote >/dev/null 2>&1; then
    ACTIVE_BIN="$(command -v oote)"
    PATHS_TO_CHECK="$PATHS_TO_CHECK
$ACTIVE_BIN"
fi

# Deduplicate candidate paths
DEDUPED_PATHS=""
for bin_candidate in $PATHS_TO_CHECK; do
    case " $DEDUPED_PATHS " in
        *" $bin_candidate "*) ;;
        *) DEDUPED_PATHS="$DEDUPED_PATHS $bin_candidate" ;;
    esac
done

for bin_path in $DEDUPED_PATHS; do
    if [ -f "$bin_path" ] || [ -L "$bin_path" ]; then
        if [ "$DRY_RUN" -eq 1 ]; then
            say "  [dry-run] Would delete $bin_path"
        else
            rm -f "$bin_path" 2>/dev/null || sudo rm -f "$bin_path" 2>/dev/null || true
            ok "Removed $bin_path"
        fi
        REMOVED_COUNT=$((REMOVED_COUNT + 1))
    fi
done

# --- 3. Configuration & Cache Cleanup ---
CONFIG_FILE="${HOME}/.openooda/theme.oot"
CACHE_DIR="${HOME}/.cache/oote"

if [ "$PURGE" -eq 1 ]; then
    if [ -f "$CONFIG_FILE" ]; then
        if [ "$DRY_RUN" -eq 1 ]; then
            say "  [dry-run] Would remove configuration $CONFIG_FILE (--purge)"
        else
            rm -f "$CONFIG_FILE"
            ok "Purged configuration $CONFIG_FILE"
        fi
        REMOVED_COUNT=$((REMOVED_COUNT + 1))
    fi

    if [ -d "$CACHE_DIR" ]; then
        if [ "$DRY_RUN" -eq 1 ]; then
            say "  [dry-run] Would remove cache directory $CACHE_DIR (--purge)"
        else
            rm -rf "$CACHE_DIR"
            ok "Purged cache directory $CACHE_DIR"
        fi
        REMOVED_COUNT=$((REMOVED_COUNT + 1))
    fi
else
    if [ -f "$CONFIG_FILE" ]; then
        say ""
        say "  ${DIM}Note: Preserved configuration file ${CONFIG_FILE}${RESET}"
        say "  ${DIM}To completely wipe theme configurations, re-run with: ${BOLD}--purge${RESET}"
    fi
fi

# --- 4. Final Verification ---
say ""
if [ "$DRY_RUN" -eq 1 ]; then
    ok "${GREEN}Dry run complete.${RESET} (No system modifications were made)"
else
    if command -v oote >/dev/null 2>&1; then
        REMAINING="$(command -v oote)"
        warn "oote is still reachable at: $REMAINING (check your PATH or shell aliases)"
    else
        ok "${GREEN}${BOLD}oote has been cleanly uninstalled.${RESET}"
    fi
fi
