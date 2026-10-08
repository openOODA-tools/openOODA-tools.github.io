#!/bin/sh
# ==============================================================================
# oobase58 Universal Installer & Lifecycle Manager
# "Cryptographic Base58 encoder and decoder omitting ambiguous alphanumeric glyphs."
#
# Usage:
#   curl -fsSL https://openooda-tools.github.io/oobase58/install.sh | bash
#
# Options:
#   --prefix <dir>       Installation directory (default: /usr/local/bin or ~/.local/bin)
#   --apt, --deb         Install Debian package (.deb) via apt/dpkg
#   --dnf, --rpm         Install RPM package (.rpm) via dnf
#   --pkgbuild, --arch   Install Arch Linux package via PKGBUILD / makepkg
#   --dry-run            Simulate installation or uninstallation without filesystem writes
#   --uninstall          Cleanly remove oobase58 binary, packages, and symlinks
#   -h, --help           Show this help message
# ==============================================================================

set -eu

REPO="openOODA-tools/oobase58"
GITHUB_URL="https://github.com/${REPO}"
VERSION_PIN="v0.2.0"
RAW_VERSION="0.2.0"

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
MODE="binary"

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
        --apt|--deb)
            MODE="deb"
            shift
            ;;
        --dnf|--rpm)
            MODE="rpm"
            shift
            ;;
        --pkgbuild|--arch)
            MODE="arch"
            shift
            ;;
        -h|--help)
            say "Usage: install.sh [options]"
            say "Options:"
            say "  --prefix <dir>       Target installation directory"
            say "  --apt, --deb         Install Debian package via apt/dpkg"
            say "  --dnf, --rpm         Install RPM package via dnf"
            say "  --pkgbuild, --arch   Install Arch Linux package via PKGBUILD / makepkg"
            say "  --dry-run            Simulate installation or uninstallation without disk writes"
            say "  --uninstall          Remove oobase58 from system paths and package managers"
            say "  -h, --help           Show this help message"
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

# --- Clean Uninstaller Implementation -----------------------------------------
if [ "$UNINSTALL" -eq 1 ]; then
    step "Cleanly uninstalling oobase58"
    REMOVED_ANY=0

    # 1. Check Debian package manager
    if command -v dpkg >/dev/null 2>&1 && dpkg -s oobase58 >/dev/null 2>&1; then
        if [ "$DRY_RUN" -eq 1 ]; then
            say "  [dry-run] Would remove Debian package: oobase58"
        else
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get remove -y -qq oobase58 2>/dev/null || sudo dpkg -r oobase58
            else
                sudo dpkg -r oobase58
            fi
            ok "Removed Debian package: oobase58"
        fi
        REMOVED_ANY=1
    fi

    # 2. Check RPM package manager
    if command -v rpm >/dev/null 2>&1 && rpm -q oobase58 >/dev/null 2>&1; then
        if [ "$DRY_RUN" -eq 1 ]; then
            say "  [dry-run] Would remove RPM package: oobase58"
        else
            if command -v dnf >/dev/null 2>&1; then
                sudo dnf remove -y -q oobase58 2>/dev/null || sudo rpm -e oobase58
            else
                sudo rpm -e oobase58
            fi
            ok "Removed RPM package: oobase58"
        fi
        REMOVED_ANY=1
    fi

    # 3. Check Arch pacman
    if command -v pacman >/dev/null 2>&1 && pacman -Q oobase58-bin >/dev/null 2>&1; then
        if [ "$DRY_RUN" -eq 1 ]; then
            say "  [dry-run] Would remove Pacman package: oobase58-bin"
        else
            sudo pacman -R --noconfirm oobase58-bin
            ok "Removed Pacman package: oobase58-bin"
        fi
        REMOVED_ANY=1
    fi

    # 4. Check standalone binaries in standard paths
    CANDIDATE_PATHS="$PREFIX/oobase58 $PREFIX/oobase58-uninstall /usr/local/bin/oobase58 /usr/local/bin/oobase58-uninstall /usr/bin/oobase58 /usr/bin/oobase58-uninstall $HOME/.local/bin/oobase58 $HOME/.local/bin/oobase58-uninstall"
    for p in $CANDIDATE_PATHS; do
        if [ -f "$p" ]; then
            if [ "$DRY_RUN" -eq 1 ]; then
                say "  [dry-run] Would remove binary: $p"
            else
                if [ -w "$p" ] || [ -w "$(dirname "$p")" ]; then
                    rm -f "$p"
                else
                    sudo rm -f "$p"
                fi
                ok "Removed binary: $p"
            fi
            REMOVED_ANY=1
        fi
    done

    if [ "$REMOVED_ANY" -eq 0 ]; then
        warn "No existing oobase58 installation found in system paths or package managers."
    else
        ok "oobase58 clean uninstallation complete."
    fi
    exit 0
fi

# --- Package Manager Installs (APT / DNF / PKGBUILD) ---------------------------
if [ "$MODE" = "deb" ]; then
    step "Installing oobase58 via Debian package (.deb)"
    DEB_URL="${GITHUB_URL}/releases/download/${VERSION_PIN}/oobase58_${RAW_VERSION}-1_amd64.deb"
    if [ "$DRY_RUN" -eq 1 ]; then
        say "  [dry-run] Would download and install $DEB_URL"
        ok "Dry run complete."
        exit 0
    fi
    TMP_DEB="$(mktemp --suffix=.deb)"
    if [ -f "./dist/oobase58_${RAW_VERSION}-1_amd64.deb" ]; then
        TMP_DEB="./dist/oobase58_${RAW_VERSION}-1_amd64.deb"
    else
        curl -fsSL "$DEB_URL" -o "$TMP_DEB"
    fi
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get install -y -qq "$TMP_DEB"
    else
        sudo dpkg -i "$TMP_DEB"
    fi
    ok "Installed oobase58 Debian package successfully."
    exit 0
fi

if [ "$MODE" = "rpm" ]; then
    step "Installing oobase58 via RPM package (.rpm)"
    RPM_URL="${GITHUB_URL}/releases/download/${VERSION_PIN}/oobase58-${RAW_VERSION}-1.x86_64.rpm"
    if [ "$DRY_RUN" -eq 1 ]; then
        say "  [dry-run] Would download and install $RPM_URL"
        ok "Dry run complete."
        exit 0
    fi
    if command -v dnf >/dev/null 2>&1; then
        if [ -f "./dist/oobase58-${RAW_VERSION}-1.x86_64.rpm" ]; then
            sudo dnf install -y -q "./dist/oobase58-${RAW_VERSION}-1.x86_64.rpm"
        else
            sudo dnf install -y -q "$RPM_URL"
        fi
    else
        TMP_RPM="$(mktemp --suffix=.rpm)"
        curl -fsSL "$RPM_URL" -o "$TMP_RPM"
        sudo rpm -Uvh "$TMP_RPM"
    fi
    ok "Installed oobase58 RPM package successfully."
    exit 0
fi

if [ "$MODE" = "arch" ]; then
    step "Installing oobase58 via Arch PKGBUILD"
    if [ "$DRY_RUN" -eq 1 ]; then
        say "  [dry-run] Would build and install package using packaging/PKGBUILD"
        ok "Dry run complete."
        exit 0
    fi
    TMP_DIR="$(mktemp -d)"
    if [ -f "./packaging/PKGBUILD" ]; then
        cp ./packaging/PKGBUILD "$TMP_DIR/"
    else
        curl -fsSL "https://raw.githubusercontent.com/${REPO}/${VERSION_PIN}/packaging/PKGBUILD" -o "$TMP_DIR/PKGBUILD"
    fi
    (cd "$TMP_DIR" && makepkg -si --noconfirm)
    rm -rf "$TMP_DIR"
    ok "Installed oobase58 Arch package successfully."
    exit 0
fi

# --- Standalone Binary Universal Install --------------------------------------
step "Installing oobase58 ($VERSION_PIN)"
say "  Target location: ${BOLD}$PREFIX/oobase58${RESET}"

if [ "$DRY_RUN" -eq 1 ]; then
    say "  [dry-run] Would download and install to $PREFIX/oobase58"
    ok "Dry run complete."
    exit 0
fi

mkdir -p "$PREFIX"

if [ -f "./dist/oobase58" ]; then
    cp "./dist/oobase58" "$PREFIX/oobase58"
    chmod +x "$PREFIX/oobase58"
    ok "Installed local binary to $PREFIX/oobase58"
else
    DOWNLOAD_URL="${GITHUB_URL}/releases/download/${VERSION_PIN}/oobase58-linux-x86_64"
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
    mv "$TMP_BIN" "$PREFIX/oobase58"
    ok "Downloaded and installed $VERSION_PIN to $PREFIX/oobase58"
fi

if [ -f "./uninstall.sh" ]; then
    cp "./uninstall.sh" "$PREFIX/oobase58-uninstall"
    chmod +x "$PREFIX/oobase58-uninstall"
    ok "Installed companion uninstaller to $PREFIX/oobase58-uninstall"
else
    UNINSTALL_URL="https://raw.githubusercontent.com/${REPO}/${VERSION_PIN}/uninstall.sh"
    TMP_UNINSTALL="$(mktemp)"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$UNINSTALL_URL" -o "$TMP_UNINSTALL" 2>/dev/null || true
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$TMP_UNINSTALL" "$UNINSTALL_URL" 2>/dev/null || true
    fi
    if [ -s "$TMP_UNINSTALL" ]; then
        chmod +x "$TMP_UNINSTALL"
        mv "$TMP_UNINSTALL" "$PREFIX/oobase58-uninstall"
        ok "Installed companion uninstaller to $PREFIX/oobase58-uninstall"
    else
        rm -f "$TMP_UNINSTALL"
    fi
fi

if "$PREFIX/oobase58" --version >/dev/null 2>&1; then
    ok "Verified: $("$PREFIX/oobase58" --version)"
else
    warn "Installed binary failed execution check."
fi
