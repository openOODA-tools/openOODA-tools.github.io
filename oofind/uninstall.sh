#!/bin/sh
# ==============================================================================
# oofind Clean Uninstaller
# "Capability-bounded file finding utility for the openOODA era."
#
# Usage:
#   curl -fsSL https://openooda-tools.github.io/oofind/uninstall.sh | bash
#   ./uninstall.sh [options]
#
# Options:
#   --prefix <dir>   Installation directory of standalone binary
#   --purge          Purge configuration and cache directories
#   -y, --yes        Assume yes; non-interactive mode
#   --dry-run        Simulate actions without filesystem writes
#   -h, --help       Show this help message
# ==============================================================================

set -eu

if [ -t 1 ] && [ "${NO_COLOR:-}" = "" ] && [ "${TERM:-dumb}" != "dumb" ]; then
    CYAN="\033[38;5;51m"
    GREEN="\033[38;5;82m"
    YELLOW="\033[38;5;220m"
    DIM="\033[38;5;242m"
    BOLD="\033[1m"
    RESET="\033[0m"
else
    CYAN="" GREEN="" YELLOW="" DIM="" BOLD="" RESET=""
fi

say()  { printf "%b\n" "$*"; }
ok()   { say "  ${GREEN}✔${RESET} $*"; }
warn() { say "  ${YELLOW}!${RESET} $*"; }
err()  { say "  ${YELLOW}ERROR:${RESET} $*" >&2; }
step() { say ""; say " ${CYAN}${BOLD}$*${RESET}"; }

elevate() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        warn "Root privileges may be required for: $*"
        "$@"
    fi
}

DRY_RUN=0
PURGE=0
YES=0
PREFIX=""

while [ $# -gt 0 ]; do
    case "$1" in
        --prefix) PREFIX="$2"; shift 2 ;;
        --dry-run) DRY_RUN=1; shift ;;
        --purge) PURGE=1; shift ;;
        -y|--yes) YES=1; shift ;;
        -h|--help)
            say "oofind Clean Uninstaller"
            say ""
            say "Usage: uninstall.sh [options]"
            say ""
            say "Options:"
            say "  --prefix <dir>   Installation directory of standalone binary"
            say "  --purge          Purge configuration and cache directories"
            say "  -y, --yes        Assume yes; non-interactive mode"
            say "  --dry-run        Simulate actions without filesystem writes"
            say "  -h, --help       Show this help message"
            exit 0
            ;;
        *) err "Unknown option: $1"; exit 2 ;;
    esac
done

if [ "$DRY_RUN" -eq 0 ] && [ "$YES" -eq 0 ] && [ -t 0 ]; then
    printf "  Are you sure you want to uninstall oofind? [y/N]: "
    read -r ans || ans="n"
    case "$ans" in
        [yY]|[yY][eE][sS]) ;;
        *) say "  Uninstallation cancelled."; exit 0 ;;
    esac
    say ""
fi

step "Uninstalling oofind"
REMOVED_COUNT=0

remove_file() {
    target="$1"
    if [ -f "$target" ] || [ -L "$target" ]; then
        if [ "$DRY_RUN" -eq 1 ]; then
            say "  ${DIM}[dry-run]${RESET} Would remove file: $target"
        else
            if [ -w "$target" ] && [ -w "$(dirname "$target")" ]; then
                rm -f "$target"
            else
                elevate rm -f "$target"
            fi
            ok "Removed $target"
        fi
        REMOVED_COUNT=$((REMOVED_COUNT + 1))
    fi
}

remove_dir() {
    target="$1"
    if [ -d "$target" ]; then
        if [ "$DRY_RUN" -eq 1 ]; then
            say "  ${DIM}[dry-run]${RESET} Would remove directory: $target"
        else
            if [ -w "$target" ] && [ -w "$(dirname "$target")" ]; then
                rm -rf "$target"
            else
                elevate rm -rf "$target"
            fi
            ok "Removed directory $target"
        fi
        REMOVED_COUNT=$((REMOVED_COUNT + 1))
    fi
}

# 1. Package managers
if command -v dpkg >/dev/null 2>&1 && dpkg -s oofind >/dev/null 2>&1; then
    if [ "$DRY_RUN" -eq 1 ]; then
        say "  ${DIM}[dry-run]${RESET} Would remove Debian package: oofind"
    else
        say "  Removing Debian package: oofind..."
        if [ "$PURGE" -eq 1 ] && command -v apt-get >/dev/null 2>&1; then
            elevate apt-get purge -y oofind 2>/dev/null || elevate dpkg -P oofind
        elif command -v apt-get >/dev/null 2>&1; then
            elevate apt-get remove -y oofind 2>/dev/null || elevate dpkg -r oofind
        else
            elevate dpkg -r oofind
        fi
        ok "Removed oofind Debian package"
    fi
    REMOVED_COUNT=$((REMOVED_COUNT + 1))
fi

if command -v rpm >/dev/null 2>&1 && rpm -q oofind >/dev/null 2>&1; then
    if [ "$DRY_RUN" -eq 1 ]; then
        say "  ${DIM}[dry-run]${RESET} Would remove RPM package: oofind"
    else
        say "  Removing RPM package: oofind..."
        if command -v dnf >/dev/null 2>&1; then
            elevate dnf remove -y oofind 2>/dev/null || elevate rpm -e oofind
        else
            elevate rpm -e oofind
        fi
        ok "Removed oofind RPM package"
    fi
    REMOVED_COUNT=$((REMOVED_COUNT + 1))
fi

if command -v pacman >/dev/null 2>&1; then
    for arch_pkg in oofind-bin oofind; do
        if pacman -Q "$arch_pkg" >/dev/null 2>&1; then
            if [ "$DRY_RUN" -eq 1 ]; then
                say "  ${DIM}[dry-run]${RESET} Would remove Arch package: $arch_pkg"
            else
                say "  Removing Arch package: $arch_pkg..."
                elevate pacman -R --noconfirm "$arch_pkg"
                ok "Removed $arch_pkg Arch package"
            fi
            REMOVED_COUNT=$((REMOVED_COUNT + 1))
        fi
    done
fi

# 2. Standalone Binaries and uninstallers
BIN_TARGETS="
/usr/local/bin/oofind
/usr/local/bin/oofind-uninstall
${HOME}/.local/bin/oofind
${HOME}/.local/bin/oofind-uninstall
/usr/bin/oofind
/usr/bin/oofind-uninstall
${HOME}/bin/oofind
${HOME}/bin/oofind-uninstall
${HOME}/.openooda/bin/oofind
${HOME}/.openooda/bin/oofind-uninstall
/opt/oofind/bin/oofind
/opt/oofind/oofind
/opt/oofind/oofind-uninstall
"
if [ -n "$PREFIX" ]; then
    BIN_TARGETS="$PREFIX/oofind $PREFIX/oofind-uninstall $BIN_TARGETS"
fi
SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd || echo "")"
if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/oofind-uninstall" ]; then
    BIN_TARGETS="$SCRIPT_DIR/oofind $SCRIPT_DIR/oofind-uninstall $BIN_TARGETS"
fi

for bp in $BIN_TARGETS; do
    remove_file "$bp"
done

# 3. Shell completions, man pages, and service units
SYSTEMD_RELOAD=0
EXTRA_TARGETS="
/usr/local/share/man/man1/oofind.1
/usr/share/man/man1/oofind.1
${HOME}/.local/share/man/man1/oofind.1
/usr/share/bash-completion/completions/oofind
/etc/bash_completion.d/oofind
${HOME}/.local/share/bash-completion/completions/oofind
/usr/share/zsh/site-functions/_oofind
${HOME}/.zsh/completion/_oofind
/usr/share/fish/vendor_completions.d/oofind.fish
${HOME}/.config/fish/completions/oofind.fish
/etc/systemd/system/oofind.service
${HOME}/.config/systemd/user/oofind.service
"

for ep in $EXTRA_TARGETS; do
    if [ -f "$ep" ] || [ -L "$ep" ]; then
        case "$ep" in
            *.service) SYSTEMD_RELOAD=1 ;;
        esac
        remove_file "$ep"
    fi
done

if [ "$SYSTEMD_RELOAD" -eq 1 ] && [ "$DRY_RUN" -eq 0 ]; then
    elevate systemctl daemon-reload 2>/dev/null || true
    systemctl --user daemon-reload 2>/dev/null || true
fi

# 4. Configuration and cache directories
USER_DIRS="${HOME}/.config/oofind ${HOME}/.cache/oofind /etc/oofind"
if [ "$PURGE" -eq 1 ]; then
    for pd in $USER_DIRS; do
        remove_dir "$pd"
    done
else
    found_data_dir=0
    for pd in $USER_DIRS; do
        if [ -d "$pd" ]; then
            found_data_dir=1
            break
        fi
    done
    if [ "$found_data_dir" -eq 1 ]; then
        say "  ${DIM}Note: Configuration/cache directories preserved. Use --purge to remove.${RESET}"
    fi
fi

# Clean empty /opt/oofind directory if empty
if [ -d "/opt/oofind" ] && [ -z "$(ls -A /opt/oofind 2>/dev/null)" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
        say "  ${DIM}[dry-run]${RESET} Would remove empty directory: /opt/oofind"
    else
        elevate rmdir /opt/oofind 2>/dev/null || true
        ok "Removed empty directory /opt/oofind"
    fi
    REMOVED_COUNT=$((REMOVED_COUNT + 1))
fi

if [ "$REMOVED_COUNT" -eq 0 ]; then
    ok "No oofind installations or artifacts found on this system."
else
    if [ "$DRY_RUN" -eq 1 ]; then
        ok "Dry run complete: $REMOVED_COUNT item(s) detected for removal."
    else
        ok "oofind clean uninstallation complete ($REMOVED_COUNT item(s) cleaned)."
    fi
fi
