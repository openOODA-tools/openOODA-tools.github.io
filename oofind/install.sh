#!/bin/sh
# ==============================================================================
# oofind Universal Installer & Uninstaller
# "Capability-bounded file finding utility for the openOODA era."
#
# Install:
#   curl -fsSL https://openooda-tools.github.io/oofind/install.sh | bash
#   curl -fsSL https://openooda-tools.github.io/oofind/install.sh | bash -s -- --dnf
#   curl -fsSL https://openooda-tools.github.io/oofind/install.sh | bash -s -- --deb
#   curl -fsSL https://openooda-tools.github.io/oofind/install.sh | bash -s -- --pkgbuild
#
# Uninstall:
#   curl -fsSL https://openooda-tools.github.io/oofind/install.sh | bash -s -- --uninstall
#   curl -fsSL https://openooda-tools.github.io/oofind/uninstall.sh | bash
#   oofind-uninstall
#
# Options:
#   --prefix <dir>       Target installation directory for standalone binary
#   --deb, --apt         Download and install Debian package (.deb) via apt/dpkg
#   --dnf, --rpm         Download and install RPM package (.rpm) via dnf
#   --pkgbuild, --arch   Download and install Arch Linux package via makepkg/PKGBUILD
#   --uninstall          Cleanly remove oofind binary, packages, and system artifacts
#   --purge              Purge configuration (~/.config/oofind) and cache (~/.cache/oofind)
#   -y, --yes            Assume yes to prompts; non-interactive mode
#   --dry-run            Simulate actions without modifying filesystem
#   -h, --help           Show this help message
# ==============================================================================

set -eu

REPO="openOODA-tools/oofind"
GITHUB_URL="https://github.com/${REPO}"
CANONICAL_URL="https://openooda-tools.github.io/oofind"
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

PREFIX=""
DRY_RUN=0
UNINSTALL=0
PURGE=0
YES=0
INSTALL_DEB=0
INSTALL_DNF=0
INSTALL_ARCH=0

case "$(basename "$0")" in
    *uninstall*)
        UNINSTALL=1
        ;;
esac

while [ $# -gt 0 ]; do
    case "$1" in
        --prefix)
            PREFIX="$2"
            shift 2
            ;;
        --deb|--apt)
            INSTALL_DEB=1
            shift
            ;;
        --dnf|--rpm)
            INSTALL_DNF=1
            shift
            ;;
        --pkgbuild|--arch)
            INSTALL_ARCH=1
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --uninstall)
            UNINSTALL=1
            shift
            ;;
        --purge)
            PURGE=1
            shift
            ;;
        -y|--yes)
            YES=1
            shift
            ;;
        -h|--help)
            say "oofind Universal Installer & Uninstaller (${VERSION_PIN})"
            say ""
            say "Usage: install.sh [options]"
            say ""
            say "Install Options:"
            say "  --prefix <dir>       Target installation directory for standalone binary"
            say "  --deb, --apt         Install Debian package (.deb) via apt/dpkg"
            say "  --dnf, --rpm         Install RPM package (.rpm) via dnf"
            say "  --pkgbuild, --arch   Build and install Arch Linux package via PKGBUILD"
            say ""
            say "Uninstall Options:"
            say "  --uninstall          Cleanly remove oofind binary, packages, and system integration"
            say "  --purge              Purge configuration and cache directories"
            say ""
            say "General Options:"
            say "  -y, --yes            Assume yes; non-interactive mode"
            say "  --dry-run            Simulate actions without filesystem writes"
            say "  -h, --help           Show this help message"
            exit 0
            ;;
        *)
            err "Unknown option: $1"
            exit 2
            ;;
    esac
done

write_uninstaller_script() {
    _out="$1"
    cat << 'UNINSTALLER_PAYLOAD_EOF' > "$_out"
#!/bin/sh
# oofind Companion Uninstaller
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

say()  { printf '%b\n' "$*"; }
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
            say "oofind Companion Uninstaller"
            say "Usage: oofind-uninstall [options]"
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
UNINSTALLER_PAYLOAD_EOF
    chmod +x "$_out"
}

# --- CLEAN UNINSTALLATION ---
if [ "$UNINSTALL" -eq 1 ]; then
    TMP_UNINSTALL="$(mktemp)"
    write_uninstaller_script "$TMP_UNINSTALL"
    ARGS=""
    if [ "$DRY_RUN" -eq 1 ]; then ARGS="$ARGS --dry-run"; fi
    if [ "$PURGE" -eq 1 ]; then ARGS="$ARGS --purge"; fi
    if [ "$YES" -eq 1 ]; then ARGS="$ARGS --yes"; fi
    if [ -n "$PREFIX" ]; then ARGS="$ARGS --prefix $PREFIX"; fi
    sh "$TMP_UNINSTALL" $ARGS
    rm -f "$TMP_UNINSTALL"
    exit 0
fi

# --- DEB / APT Installation ---
if [ "$INSTALL_DEB" -eq 1 ]; then
    step "Installing oofind via DEB/apt ($VERSION_PIN)"
    DEB_NAME="oofind_${RAW_VERSION}-1_amd64.deb"
    DEB_URL="${GITHUB_URL}/releases/download/${VERSION_PIN}/${DEB_NAME}"
    if [ "$DRY_RUN" -eq 1 ]; then
        say "  [dry-run] Would download $DEB_URL and run dpkg -i"
        ok "Dry run complete."
        exit 0
    fi
    TMP_DEB="$(mktemp --suffix=.deb)"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$DEB_URL" -o "$TMP_DEB"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$TMP_DEB" "$DEB_URL"
    else
        err "Neither curl nor wget available."
        exit 1
    fi
    elevate dpkg -i "$TMP_DEB" || elevate apt-get install -f -y
    rm -f "$TMP_DEB"
    ok "Installed oofind deb package."
    oofind --version
    exit 0
fi

# --- DNF / RPM Installation ---
if [ "$INSTALL_DNF" -eq 1 ]; then
    step "Installing oofind via DNF/rpm ($VERSION_PIN)"
    RPM_NAME="oofind-${RAW_VERSION}-1.x86_64.rpm"
    RPM_URL="${GITHUB_URL}/releases/download/${VERSION_PIN}/${RPM_NAME}"
    if [ "$DRY_RUN" -eq 1 ]; then
        say "  [dry-run] Would install $RPM_URL via dnf"
        ok "Dry run complete."
        exit 0
    fi
    elevate dnf install -y "$RPM_URL"
    ok "Installed oofind RPM package."
    oofind --version
    exit 0
fi

# --- Arch Linux / PKGBUILD Installation ---
if [ "$INSTALL_ARCH" -eq 1 ]; then
    step "Installing oofind via PKGBUILD ($VERSION_PIN)"
    if [ "$DRY_RUN" -eq 1 ]; then
        say "  [dry-run] Would fetch PKGBUILD and execute makepkg -si"
        ok "Dry run complete."
        exit 0
    fi
    if ! command -v makepkg >/dev/null 2>&1; then
        err "makepkg not found. Install base-devel on Arch Linux or install the standalone binary."
        exit 1
    fi
    BUILD_DIR="$(mktemp -d)"
    if [ -f "./packaging/arch/PKGBUILD" ]; then
        cp "./packaging/arch/PKGBUILD" "$BUILD_DIR/PKGBUILD"
    elif command -v curl >/dev/null 2>&1; then
        curl -fsSL "${CANONICAL_URL}/PKGBUILD" -o "$BUILD_DIR/PKGBUILD" || \
        curl -fsSL "${GITHUB_URL}/raw/main/packaging/arch/PKGBUILD" -o "$BUILD_DIR/PKGBUILD"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$BUILD_DIR/PKGBUILD" "${CANONICAL_URL}/PKGBUILD" || \
        wget -qO "$BUILD_DIR/PKGBUILD" "${GITHUB_URL}/raw/main/packaging/arch/PKGBUILD"
    else
        err "Neither curl nor wget available."
        rm -rf "$BUILD_DIR"
        exit 1
    fi
    (cd "$BUILD_DIR" && makepkg -si --noconfirm)
    rm -rf "$BUILD_DIR"
    ok "Installed oofind via PKGBUILD."
    oofind --version
    exit 0
fi

# --- Standalone Binary Installation (Default) ---
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

step "Installing oofind standalone binary ($VERSION_PIN)"
say "  Target location: ${BOLD}$PREFIX/oofind${RESET}"

if [ "$DRY_RUN" -eq 1 ]; then
    say "  [dry-run] Would download and install to $PREFIX/oofind"
    say "  [dry-run] Would situate uninstaller at $PREFIX/oofind-uninstall"
    ok "Dry run complete."
    exit 0
fi

mkdir -p "$PREFIX"

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
        err "Neither curl nor wget available."
        exit 1
    fi
    chmod +x "$TMP_BIN"
    mv "$TMP_BIN" "$PREFIX/oofind"
    ok "Downloaded and installed $VERSION_PIN to $PREFIX/oofind"
fi

# Situate companion uninstaller
TMP_UNINSTALL="$(mktemp)"
write_uninstaller_script "$TMP_UNINSTALL"
if [ -w "$PREFIX" ]; then
    mv "$TMP_UNINSTALL" "$PREFIX/oofind-uninstall"
else
    elevate mv "$TMP_UNINSTALL" "$PREFIX/oofind-uninstall"
fi
chmod +x "$PREFIX/oofind-uninstall" 2>/dev/null || elevate chmod +x "$PREFIX/oofind-uninstall"
ok "Situating companion uninstaller at $PREFIX/oofind-uninstall"

if "$PREFIX/oofind" --version >/dev/null 2>&1; then
    ok "Verified: $("$PREFIX/oofind" --version)"
else
    warn "Installed binary failed execution check."
fi
