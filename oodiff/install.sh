#!/bin/sh
# ==============================================================================
# oodiff Universal Installer & Lifecycle Engine
# "Capability-bounded text & directory diff engine with an agent-native MCP surface."
#
# Usage:
#   curl -fsSL https://openooda-tools.github.io/oodiff/install.sh | bash
#
# Options:
#   --prefix <dir>       Installation directory for standalone binary (default: /usr/local/bin or ~/.local/bin)
#   --apt, --deb         Download and install via Debian/Ubuntu package manager (apt)
#   --dnf, --rpm         Download and install via Fedora/RHEL package manager (dnf)
#   --pkgbuild, --arch   Download and install via Arch Linux package manager (makepkg/pacman)
#   --package            Auto-detect distribution and install using native package manager
#   --dry-run            Simulate installation or uninstallation without touching the filesystem
#   --verify             Perform strict cryptographic SHA-256 integrity verification
#   --uninstall          Remove oodiff binary, companion uninstaller, and packages
#   --purge              When uninstalling, also purge configuration and cache directories (~/.cache/oodiff)
#   -y, --yes            Proceed without interactive confirmation
#   -h, --help           Show this help message
# ==============================================================================

set -eu

REPO="openOODA-tools/oodiff"
GITHUB_URL="https://github.com/${REPO}"
CANONICAL_URL="https://openooda-tools.github.io/oodiff"
VERSION_PIN="v0.3.1"

# --- Styling & Human Interface Standard ---------------------------------------
if [ -t 1 ] && [ "${NO_COLOR:-}" = "" ] && [ "${TERM:-dumb}" != "dumb" ]; then
    AMBER="\033[38;5;214m"
    CYAN="\033[38;5;51m"
    GREEN="\033[38;5;82m"
    YELLOW="\033[38;5;220m"
    MAGENTA="\033[38;5;213m"
    DIM="\033[38;5;242m"
    BOLD="\033[1m"
    RESET="\033[0m"
    IS_TTY=1
else
    AMBER="" CYAN="" GREEN="" YELLOW="" MAGENTA="" DIM="" BOLD="" RESET=""
    IS_TTY=0
fi

say()  { printf '%b\n' "$*"; }
dim()  { say "  ${DIM}$*${RESET}"; }
ok()   { say "  ${GREEN}✔${RESET} $*"; }
warn() { say "  ${YELLOW}!${RESET} $*"; }
err()  { say "  ${YELLOW}ERROR:${RESET} $*" >&2; }
step() { say ""; say " ${CYAN}${BOLD}$*${RESET}"; }

pause() {
    _s="${1:-0.25}"
    if [ "$IS_TTY" -eq 1 ]; then
        sleep "$_s" 2>/dev/null || true
    fi
}

story_line() {
    say "  ${MAGENTA}›${RESET} ${DIM}$*${RESET}"
    pause 0.2
}

spin_while() {
    _pid="$1"
    _label="$2"
    _i=0
    if [ "$IS_TTY" -eq 0 ]; then
        wait "$_pid"
        return $?
    fi
    while kill -0 "$_pid" 2>/dev/null; do
        case $((_i % 4)) in
            0) _ch='⠋' ;;
            1) _ch='⠙' ;;
            2) _ch='⠹' ;;
            3) _ch='⠸' ;;
        esac
        printf "\r  ${CYAN}%s${RESET} %s…  " "$_ch" "$_label"
        _i=$((_i + 1))
        sleep 0.08 2>/dev/null || true
    done
    wait "$_pid"
    _rc=$?
    printf '\r\033[K'
    return $_rc
}

clear_soft() {
    if [ "$IS_TTY" -eq 1 ] && command -v clear >/dev/null 2>&1; then
        clear 2>/dev/null || true
    fi
}

banner() {
    clear_soft
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
        ║       Fast / Capability-Bounded / Agent-Ready            ║
        ║                                                          ║
        ╚══════════════════════════════════════════════════════════╝
BANNER
    say "${RESET}"
    say "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    say ""
}

victory_banner() {
    say ""
    say "${GREEN}${BOLD}"
    cat <<'VICTORY'
        ╔══════════════════════════════════════════════════════════╗
        ║                                                          ║
        ║               ⚡ SOVEREIGNTY AWAKENED ⚡                  ║
        ║                                                          ║
        ╚══════════════════════════════════════════════════════════╝
VICTORY
    say "${RESET}"
    say "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    say ""
}

# --- Argument Parsing ---------------------------------------------------------
DRY_RUN=0
DO_UNINSTALL=0
DO_PURGE=0
AUTO_YES=0
DO_VERIFY=0
USE_APT=0
USE_DNF=0
USE_ARCH=0
AUTO_PKG=0
CUSTOM_PREFIX=""

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) DRY_RUN=1; shift ;;
        --uninstall) DO_UNINSTALL=1; shift ;;
        --purge) DO_PURGE=1; shift ;;
        -y|--yes) AUTO_YES=1; shift ;;
        --verify) DO_VERIFY=1; shift ;;
        --apt|--deb) USE_APT=1; shift ;;
        --dnf|--rpm) USE_DNF=1; shift ;;
        --pkgbuild|--arch|--pacman) USE_ARCH=1; shift ;;
        --package) AUTO_PKG=1; shift ;;
        --prefix) CUSTOM_PREFIX="$2"; shift 2 ;;
        -h|--help)
            banner
            say "  ${BOLD}Usage:${RESET} curl -fsSL .../install.sh | bash [options]"
            say ""
            say "  ${BOLD}Options:${RESET}"
            say "    ${CYAN}--prefix <dir>${RESET}       Target binary directory (default: /usr/local/bin or ~/.local/bin)"
            say "    ${CYAN}--apt, --deb${RESET}         Install using Debian/Ubuntu package manager (apt)"
            say "    ${CYAN}--dnf, --rpm${RESET}         Install using Fedora/RHEL package manager (dnf)"
            say "    ${CYAN}--pkgbuild, --arch${RESET}   Install using Arch Linux package manager (makepkg/pacman)"
            say "    ${CYAN}--package${RESET}            Auto-detect distro and install via native package manager"
            say "    ${CYAN}--dry-run${RESET}            Simulate deployment or removal without modifying host"
            say "    ${CYAN}--verify${RESET}             Verify cryptographic SHA-256 seal and exit"
            say "    ${CYAN}--uninstall${RESET}          Cleanly remove oodiff binary, uninstaller, or package"
            say "    ${CYAN}--purge${RESET}              When uninstalling, also remove configuration & cache (~/.cache/oodiff)"
            say "    ${CYAN}-y, --yes${RESET}            Non-interactive mode (proceed without confirmation)"
            say "    ${CYAN}-h, --help${RESET}           Display this manual"
            say ""
            exit 0
            ;;
        *) err "Unknown flag: $1"; exit 1 ;;
    esac
done

banner

# --- Uninstall Path -----------------------------------------------------------
if [ "$DO_UNINSTALL" -eq 1 ]; then
    if [ "$DRY_RUN" -eq 0 ] && [ "$AUTO_YES" -eq 0 ] && [ -t 0 ]; then
        printf "  Are you sure you want to uninstall oodiff? [y/N]: "
        read -r ans || ans="n"
        case "$ans" in
            [yY]|[yY][eE][sS]) ;;
            *) say "  Uninstallation cancelled."; exit 0 ;;
        esac
        say ""
    fi

    step "Scanning substrate for oodiff installations…"
    REMOVED_ANY=0

    # Package managers
    step "[1/3] Checking system package managers"
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

    # Standalone binaries and companion tools
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
    if [ -n "$CUSTOM_PREFIX" ]; then
        STANDARD_TARGETS="${STANDARD_TARGETS} ${CUSTOM_PREFIX}/oodiff ${CUSTOM_PREFIX}/oodiff-uninstall"
    fi

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

    # Cache and state purge
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
    say ""
    exit 0
fi

# --- Helper: Write Uninstaller Script -----------------------------------------
write_uninstaller_script() {
    _out="$1"
    cat << 'UNINSTALLER_PAYLOAD_EOF' > "$_out"
#!/bin/sh
# ==============================================================================
# oodiff Clean Uninstaller
# "Safely and thoroughly relinquishes oodiff binaries, packages, and companion tools."
#
# Usage:
#   oodiff-uninstall [options]
#   curl -fsSL https://openooda-tools.github.io/oodiff/uninstall.sh | bash
#
# Options:
#   --dry-run        Simulate uninstallation without modifying the filesystem
#   --purge          Also purge configuration and cache directories (~/.cache/oodiff)
#   -y, --yes        Proceed without interactive prompts
#   -h, --help       Show this help message
# ==============================================================================

set -eu

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
    cat <<'BANNER_EOF'
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
BANNER_EOF
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

step "[1/3] Checking system package managers"

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

if [ "$DRY_RUN" -eq 0 ] && command -v oodiff >/dev/null 2>&1; then
    REMAINING="$(command -v oodiff)"
    warn "Note: An oodiff executable is still detected on PATH at ${BOLD}${REMAINING}${RESET}."
fi

say ""
UNINSTALLER_PAYLOAD_EOF
    chmod +x "$_out"
}

# --- Phase 1: Identity & Attunement -------------------------------------------
story_line "Attuning your environment to the openOODA sovereign diff engine…"
pause 0.2

step "[1/4]  Attuning host & kernel substrate"

OS="$(uname -s)"
if [ "$OS" != "Linux" ]; then
    warn "Non-Linux kernel detected: ${BOLD}${OS}${RESET}"
    story_line "oodiff is architected for native Linux. Continuing best-effort…"
fi

ARCH="$(uname -m)"
case "$ARCH" in
    x86_64|amd64) TARGET_ARCH="x86_64"; DEB_ARCH="amd64" ;;
    aarch64|arm64) TARGET_ARCH="aarch64"; DEB_ARCH="arm64" ;;
    *)
        err "Unsupported hardware architecture: $ARCH (oodiff requires x86_64 or aarch64)"
        exit 1
        ;;
esac

OS_ID="linux"
OS_PRETTY="Linux"
if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    OS_ID="${ID:-linux}"
    OS_PRETTY="${PRETTY_NAME:-Linux}"
fi

say "  ${DIM}os${RESET}       ${GREEN}${OS_PRETTY}${RESET}"
say "  ${DIM}arch${RESET}     ${GREEN}${TARGET_ARCH}${RESET} ${DIM}(${ARCH})${RESET}"
say "  ${DIM}kernel${RESET}   ${GREEN}$(uname -r)${RESET}"

if [ "$AUTO_PKG" -eq 1 ]; then
    case "$OS_ID" in
        debian|ubuntu|pop|mint|elementary) USE_APT=1 ;;
        fedora|rhel|centos|rocky|almalinux) USE_DNF=1 ;;
        arch|manjaro|endeavouros|artix) USE_ARCH=1 ;;
        *) warn "Could not determine native package format for ${OS_ID}; defaulting to standalone binary." ;;
    esac
fi

HASH_CMD=""
if command -v sha256sum >/dev/null 2>&1; then
    HASH_CMD="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
    HASH_CMD="shasum -a 256"
fi

if [ -z "$HASH_CMD" ]; then
    warn "No sha256 utility on PATH; cryptographic verification disabled."
else
    say "  ${DIM}crypto${RESET}   ${GREEN}${HASH_CMD}${RESET}"
fi

# Resolve destination directory for binary mode
if [ "$USE_APT" -eq 0 ] && [ "$USE_DNF" -eq 0 ] && [ "$USE_ARCH" -eq 0 ]; then
    if [ -n "$CUSTOM_PREFIX" ]; then
        INSTALL_DIR="$CUSTOM_PREFIX"
    elif [ "$(id -u)" -eq 0 ]; then
        INSTALL_DIR="/usr/local/bin"
    elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
        INSTALL_DIR="/usr/local/bin"
    else
        INSTALL_DIR="${HOME}/.local/bin"
    fi
    say "  ${DIM}target${RESET}   ${CYAN}${INSTALL_DIR}/oodiff${RESET}"
fi
pause 0.2

# --- Phase 2: Resolving Release & Provenance ----------------------------------
step "[2/4]  Scrying release channels & provenance"

story_line "Contacting sovereign registry at ${GITHUB_URL}…"
LATEST_TAG=$(curl -sSL -H "Accept: application/vnd.github+json" "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null | grep '"tag_name":' | head -1 | cut -d '"' -f 4 || echo "")
if [ -z "$LATEST_TAG" ]; then
    LATEST_TAG="$VERSION_PIN"
fi
RAW_VERSION="${LATEST_TAG#v}"

if [ "$USE_APT" -eq 1 ]; then
    ASSET_NAME="oodiff_${RAW_VERSION}-1_${DEB_ARCH}.deb"
    PKG_TYPE="deb"
elif [ "$USE_DNF" -eq 1 ]; then
    RPM_NAME=$(curl -sSL "https://api.github.com/repos/${REPO}/releases/tags/${LATEST_TAG}" 2>/dev/null | grep '"name": "oodiff-.*\.rpm"' | head -1 | cut -d '"' -f 4 || echo "")
    if [ -z "$RPM_NAME" ]; then
        RPM_NAME="oodiff-${RAW_VERSION}-1.fc44.${TARGET_ARCH}.rpm"
    fi
    ASSET_NAME="$RPM_NAME"
    PKG_TYPE="rpm"
elif [ "$USE_ARCH" -eq 1 ]; then
    ASSET_NAME="oodiff-linux-${TARGET_ARCH}"
    PKG_TYPE="pkgbuild"
else
    ASSET_NAME="oodiff-linux-${TARGET_ARCH}"
    PKG_TYPE="binary"
fi

ASSET_URL="${GITHUB_URL}/releases/download/${LATEST_TAG}/${ASSET_NAME}"
SHA_URL="${ASSET_URL}.sha256"

ok "Channel:  ${BOLD}${LATEST_TAG}${RESET} ${DIM}(canonical release)${RESET}"
ok "Artifact: ${BOLD}${ASSET_NAME}${RESET} ${DIM}(${PKG_TYPE})${RESET}"
pause 0.2

if [ "$DRY_RUN" -eq 1 ]; then
    step "[DRY RUN] Verification Plan"
    say "  ${DIM}fetch${RESET}   ${CYAN}${ASSET_URL}${RESET}"
    say "  ${DIM}verify${RESET}  ${CYAN}${SHA_URL}${RESET}"
    if [ "$PKG_TYPE" = "deb" ]; then
        say "  ${DIM}deploy${RESET}  ${CYAN}apt install / sudo dpkg -i${RESET}"
    elif [ "$PKG_TYPE" = "rpm" ]; then
        say "  ${DIM}deploy${RESET}  ${CYAN}dnf install / sudo rpm -Uvh${RESET}"
    elif [ "$PKG_TYPE" = "pkgbuild" ]; then
        say "  ${DIM}deploy${RESET}  ${CYAN}makepkg -si / pacman -U${RESET}"
    else
        say "  ${DIM}deploy${RESET}  ${CYAN}${INSTALL_DIR}/oodiff${RESET}"
        say "  ${DIM}deploy${RESET}  ${CYAN}${INSTALL_DIR}/oodiff-uninstall${RESET}"
    fi
    say ""
    ok "Simulation complete. No host modifications made."
    say ""
    exit 0
fi

# --- Phase 3: Transmission & Cryptographic Seal -------------------------------
step "[3/4]  Transmuting & verifying cryptographic seal"

TMP_DIR="$(mktemp -d /tmp/oodiff-bootstrap.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

# If running from within an oodiff repository checkout with dist/oodiff ready:
if [ -f "./dist/oodiff" ] && [ "$PKG_TYPE" = "binary" ]; then
    story_line "Detected local build at ./dist/oodiff; installing directly…"
    cp "./dist/oodiff" "${TMP_DIR}/${ASSET_NAME}"
    chmod +x "${TMP_DIR}/${ASSET_NAME}"
    ok "Ingested local binary ./dist/oodiff"
else
    if ! command -v curl >/dev/null 2>&1; then
        err "curl is required to retrieve sovereign release assets"
        exit 1
    fi
    story_line "Streaming ${PKG_TYPE} artifact from release channel…"
    curl -fsSL "$ASSET_URL" -o "${TMP_DIR}/${ASSET_NAME}" &
    spin_while $! "Streaming ${ASSET_NAME}"
    ok "Transmitted ${ASSET_NAME}"

    story_line "Acquiring publisher's cryptographic SHA-256 seal…"
    curl -fsSL "$SHA_URL" -o "${TMP_DIR}/${ASSET_NAME}.sha256" 2>/dev/null || true

    EXPECTED_SHA=""
    if [ -f "${TMP_DIR}/${ASSET_NAME}.sha256" ] && [ -n "$HASH_CMD" ]; then
        EXPECTED_SHA=$(awk '{print $1}' "${TMP_DIR}/${ASSET_NAME}.sha256" | head -1)
        ACTUAL_SHA=$($HASH_CMD "${TMP_DIR}/${ASSET_NAME}" | awk '{print $1}')
        if [ "$EXPECTED_SHA" != "$ACTUAL_SHA" ]; then
            err "Cryptographic seal violation! Download corrupted or tampered."
            say "  ${DIM}Expected:${RESET} ${YELLOW}${EXPECTED_SHA}${RESET}"
            say "  ${DIM}Actual:  ${RESET} ${YELLOW}${ACTUAL_SHA}${RESET}"
            exit 1
        fi
        ok "Cryptographic seal verified: ${DIM}${ACTUAL_SHA}${RESET}"
    else
        warn "Checksum manifest unavailable; skipped seal verification."
    fi
fi
pause 0.2

# --- Phase 4: Deploying oodiff & Clean Uninstaller ----------------------------
step "[4/4]  Awakening sovereign diff engine"

if [ "$PKG_TYPE" = "deb" ]; then
    story_line "Installing Debian package via apt/dpkg…"
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get install -y "${TMP_DIR}/${ASSET_NAME}" 2>/dev/null || sudo dpkg -i "${TMP_DIR}/${ASSET_NAME}"
    else
        sudo dpkg -i "${TMP_DIR}/${ASSET_NAME}"
    fi
    ok "Debian package installed to /usr/bin/oodiff"
    INSTALL_DIR="/usr/bin"
elif [ "$PKG_TYPE" = "rpm" ]; then
    story_line "Installing RPM package via dnf/rpm…"
    if command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y "${TMP_DIR}/${ASSET_NAME}" 2>/dev/null || sudo rpm -Uvh --replacepkgs "${TMP_DIR}/${ASSET_NAME}"
    else
        sudo rpm -Uvh --replacepkgs "${TMP_DIR}/${ASSET_NAME}"
    fi
    ok "RPM package installed to /usr/bin/oodiff"
    INSTALL_DIR="/usr/bin"
elif [ "$PKG_TYPE" = "pkgbuild" ]; then
    story_line "Generating PKGBUILD and installing via makepkg/pacman…"
    cat << PKGBUILD_EOF > "${TMP_DIR}/PKGBUILD"
# Maintainer: openOODA-tools <ops@openooda.org>
pkgname=oodiff-bin
_pkgname=oodiff
pkgver=${RAW_VERSION}
pkgrel=1
pkgdesc="Capability-bounded file and directory diff engine with GNU diff parity and MCP surface"
arch=('x86_64')
url="https://github.com/${REPO}"
license=('Apache-2.0')
depends=('glibc')
provides=('oodiff')
conflicts=('oodiff')
source_x86_64=("${ASSET_URL}")
sha256sums_x86_64=('${EXPECTED_SHA:-SKIP}')

package() {
    install -Dm755 "\${srcdir}/${ASSET_NAME}" "\${pkgdir}/usr/bin/oodiff"
}
PKGBUILD_EOF
    if command -v makepkg >/dev/null 2>&1; then
        (cd "$TMP_DIR" && makepkg -si --noconfirm)
        ok "Arch package installed to /usr/bin/oodiff"
        INSTALL_DIR="/usr/bin"
    else
        warn "makepkg not detected on host; installing standalone binary directly."
        if [ ! -d "/usr/local/bin" ]; then mkdir -p "/usr/local/bin" 2>/dev/null || sudo mkdir -p "/usr/local/bin"; fi
        chmod +x "${TMP_DIR}/${ASSET_NAME}"
        if [ -w "/usr/local/bin" ]; then
            mv "${TMP_DIR}/${ASSET_NAME}" "/usr/local/bin/oodiff"
        else
            sudo mv "${TMP_DIR}/${ASSET_NAME}" "/usr/local/bin/oodiff"
        fi
        ok "Binary situated at /usr/local/bin/oodiff"
        INSTALL_DIR="/usr/local/bin"
    fi
else
    if [ ! -d "$INSTALL_DIR" ]; then
        mkdir -p "$INSTALL_DIR" 2>/dev/null || sudo mkdir -p "$INSTALL_DIR"
    fi
    chmod +x "${TMP_DIR}/${ASSET_NAME}"
    story_line "Placing binary into ${INSTALL_DIR}…"
    if [ -w "$INSTALL_DIR" ]; then
        mv "${TMP_DIR}/${ASSET_NAME}" "${INSTALL_DIR}/oodiff"
    else
        sudo mv "${TMP_DIR}/${ASSET_NAME}" "${INSTALL_DIR}/oodiff"
    fi
    ok "Binary situated at ${BOLD}${INSTALL_DIR}/oodiff${RESET}"
fi

# Deploy companion uninstaller to INSTALL_DIR
write_uninstaller_script "${TMP_DIR}/oodiff-uninstall"
story_line "Situating companion uninstaller in ${INSTALL_DIR}…"
if [ -w "$INSTALL_DIR" ]; then
    mv "${TMP_DIR}/oodiff-uninstall" "${INSTALL_DIR}/oodiff-uninstall"
else
    sudo mv "${TMP_DIR}/oodiff-uninstall" "${INSTALL_DIR}/oodiff-uninstall"
fi
ok "Companion uninstaller situated at ${BOLD}${INSTALL_DIR}/oodiff-uninstall${RESET}"

if "${INSTALL_DIR}/oodiff" --version >/dev/null 2>&1; then
    VER_PROVE=$("${INSTALL_DIR}/oodiff" --version)
    ok "Living proof: ${GREEN}${BOLD}${VER_PROVE}${RESET}"
else
    warn "Verification probe non-responsive."
fi

PATH_OK=0
case ":$PATH:" in
    *:"$INSTALL_DIR":*) PATH_OK=1 ;;
esac

victory_banner

if [ "$PATH_OK" -eq 0 ]; then
    warn "The directory ${BOLD}${INSTALL_DIR}${RESET} is not in your current \$PATH."
    say ""
    say "  To enable ${BOLD}oodiff${RESET} across your environment, add to ${BOLD}~/.bashrc${RESET} or ${BOLD}~/.zshrc${RESET}:"
    say "    ${CYAN}export PATH=\"${INSTALL_DIR}:\$PATH\"${RESET}"
    say ""
fi

say "  ${BOLD}Try it right now:${RESET}"
say "    ${AMBER}${BOLD}oodiff --help${RESET}"
say "    ${AMBER}${BOLD}oodiff file_a.txt file_b.txt${RESET}"
say "    ${AMBER}${BOLD}oodiff -u -b file_a.txt file_b.txt${RESET}"
say ""
say "  ${BOLD}Agent surface (Model Context Protocol):${RESET}"
say "    ${DIM}oodiff --mcp${RESET}"
say ""
say "  ${BOLD}Clean uninstallation:${RESET}"
say "    ${CYAN}oodiff-uninstall${RESET} ${DIM}(or: oodiff-uninstall --purge)${RESET}"
say "    ${DIM}Or via web:${RESET} ${CYAN}curl -fsSL ${CANONICAL_URL}/uninstall.sh | bash${RESET}"
say ""
