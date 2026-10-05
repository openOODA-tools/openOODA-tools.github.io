#!/bin/sh
# ==============================================================================
# oofind Universal Installer
# "Capability-bounded file finding utility for the openOODA era."
#
# Usage:
#   curl -fsSL https://openooda-tools.github.io/oofind/install.sh | bash
#
# Options:
#   --prefix <dir>   Installation directory (default: /usr/local/bin or ~/.local/bin)
#   --dry-run        Simulate installation without touching the filesystem
#   --uninstall      Remove oofind binary from standard system paths
#   -h, --help       Show this help message
# ==============================================================================

set -eu

REPO="openOODA-tools/oofind"
GITHUB_URL="https://github.com/${REPO}"
VERSION_PIN="v0.1.0"

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

say()  { printf '%b\n' "$*"; }
ok()   { say "  ${GREEN}✔${RESET} $*"; }
warn() { say "  ${YELLOW}!${RESET} $*"; }
err()  { say "  ${YELLOW}ERROR:${RESET} $*" >&2; }
step() { say ""; say " ${CYAN}${BOLD}$*${RESET}"; }

PREFIX=""
DRY_RUN=0
UNINSTALL=0

while [ $# -gt 0 ]; do
    case "$1" in
        --prefix)
            PREFIX="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --uninstall)
            UNINSTALL=1
            shift
            ;;
        -h|--help)
            say "Usage: install.sh [options]"
            say "Options:"
            say "  --prefix <dir>   Target installation directory"
            say "  --dry-run        Simulate installation without disk writes"
            say "  --uninstall      Remove oofind from installation path"
            exit 0
            ;;
        *)
            err "Unknown option: $1"
            exit 2
            ;;
    esac
done

resolve_prefix() {
    if [ -n "$PREFIX" ]; then
        return
    fi
    if [ "$(id -u)" -eq 0 ]; then
        PREFIX="/usr/local/bin"
    elif [ -d "$HOME/.local/bin" ] && printf '%s' "$PATH" | grep -q "$HOME/.local/bin"; then
        PREFIX="$HOME/.local/bin"
    elif [ -w "/usr/local/bin" ]; then
        PREFIX="/usr/local/bin"
    else
        PREFIX="$HOME/.local/bin"
    fi
}

resolve_prefix

if [ "$UNINSTALL" -eq 1 ]; then
    step "Uninstalling oofind"
    TARGET="$PREFIX/oofind"
    if [ -f "$TARGET" ]; then
        if [ "$DRY_RUN" -eq 1 ]; then
            say "  [dry-run] Would remove $TARGET"
        else
            rm -f "$TARGET"
            ok "Removed $TARGET"
        fi
    else
        warn "$TARGET does not exist."
    fi
    exit 0
fi

step "Installing oofind ($VERSION_PIN)"
say "  Target location: ${BOLD}$PREFIX/oofind${RESET}"

if [ "$DRY_RUN" -eq 1 ]; then
    say "  [dry-run] Would download and install to $PREFIX/oofind"
    ok "Dry run complete."
    exit 0
fi

mkdir -p "$PREFIX"

# If local binary exists in dist/oofind, install it directly
if [ -f "./dist/oofind" ]; then
    cp "./dist/oofind" "$PREFIX/oofind"
    chmod +x "$PREFIX/oofind"
    ok "Installed local binary to $PREFIX/oofind"
else
    DOWNLOAD_URL="${GITHUB_URL}/releases/download/${VERSION_PIN}/oofind-linux-x86_64"
    TMP_BIN="$(mktemp)"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$DOWNLOAD_URL" -o "$TMP_BIN"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$TMP_BIN" "$DOWNLOAD_URL"
    else
        err "Neither curl nor wget is available."
        exit 1
    fi
    chmod +x "$TMP_BIN"
    mv "$TMP_BIN" "$PREFIX/oofind"
    ok "Downloaded and installed $VERSION_PIN to $PREFIX/oofind"
fi

if "$PREFIX/oofind" --version >/dev/null 2>&1; then
    ok "Verified: $("$PREFIX/oofind" --version)"
else
    warn "Installed binary failed execution check."
fi
