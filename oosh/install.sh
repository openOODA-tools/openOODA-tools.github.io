#!/bin/sh
# ==============================================================================
# oosh Universal Installer
# "The intent-driven, ambient, capability-bounded interactive shell for the AI era."
#
# Usage:
#   curl -fsSL https://openooda-tools.github.io/oosh/install.sh | bash
#
# Channels:
#   --web (default)  Direct standalone binary deployment
#   --dnf, --rpm     Native RPM package installation via DNF
#   --apt, --deb     Native DEB package installation via APT
#   --pacman, --arch Native Arch package installation via Pacman (.pkg.tar.zst)
#   --pkgbuild       Build and install via Arch PKGBUILD and makepkg
#   --auto           Auto-detect host package manager or fallback to web
#
# Options:
#   --prefix <dir>   Installation directory for web binary (default: /usr/local/bin or ~/.local/bin)
#   --dry-run        Simulate installation without touching the filesystem
#   --verify         Perform strict cryptographic SHA-256 integrity verification
#   --uninstall      Remove oosh binary or package from system
#   -h, --help       Show this help message
# ==============================================================================

set -eu

REPO="openOODA-tools/oosh"
GITHUB_URL="https://github.com/${REPO}"
CANONICAL_URL="https://openooda-tools.github.io/oosh"
VERSION_PIN="v1.0.0"

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

countdown() {
    _n="${1:-3}"
    _msg="${2:-Launching}"
    if [ "$IS_TTY" -eq 0 ]; then
        return 0
    fi
    while [ "$_n" -gt 0 ]; do
        printf "\r  ${AMBER}${BOLD}%s${RESET} in ${BOLD}%s${RESET}…   " "$_msg" "$_n"
        sleep 0.8
        _n=$((_n - 1))
    done
    printf '\r\033[K'
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
        ║      ██████╗  ██████╗ ███████╗██╗  ██╗                   ║
        ║     ██╔═══██╗██╔═══██╗██╔════╝██║  ██║                   ║
        ║     ██║   ██║██║   ██║███████╗███████║                   ║
        ║     ██║   ██║██║   ██║╚════██║██╔══██║                   ║
        ║     ╚██████╔╝╚██████╔╝███████║██║  ██║                   ║
        ║      ╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝                   ║
        ║                                                          ║
        ║               openOODA Sovereign Shell                   ║
        ║       Intent-Driven • Ambient • Capability-Bounded       ║
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
DO_VERIFY=0
CUSTOM_PREFIX=""
INSTALL_METHOD="web"

while [ $# -gt 0 ]; do
    case "$1" in
        --web) INSTALL_METHOD="web"; shift ;;
        --dnf|--rpm) INSTALL_METHOD="dnf"; shift ;;
        --apt|--deb) INSTALL_METHOD="apt"; shift ;;
        --pacman|--arch) INSTALL_METHOD="pacman"; shift ;;
        --pkgbuild) INSTALL_METHOD="pkgbuild"; shift ;;
        --auto) INSTALL_METHOD="auto"; shift ;;
        --dry-run) DRY_RUN=1; shift ;;
        --uninstall) DO_UNINSTALL=1; shift ;;
        --verify) DO_VERIFY=1; shift ;;
        --prefix) CUSTOM_PREFIX="$2"; shift 2 ;;
        -h|--help)
            banner
            say "  ${BOLD}Usage:${RESET} curl -fsSL .../install.sh | bash [options]"
            say ""
            say "  ${BOLD}Distribution Channels:${RESET}"
            say "    ${CYAN}--web${RESET}            Direct glibc-linked standalone binary deployment (default)"
            say "    ${CYAN}--dnf, --rpm${RESET}     Native RPM package installation via DNF"
            say "    ${CYAN}--apt, --deb${RESET}     Native DEB package installation via APT"
            say "    ${CYAN}--pacman, --arch${RESET} Native Arch package installation via Pacman (.pkg.tar.zst)"
            say "    ${CYAN}--pkgbuild${RESET}       Build and install via Arch PKGBUILD and makepkg"
            say "    ${CYAN}--auto${RESET}           Auto-detect host package manager (dnf/apt/pacman) or fallback to web"
            say ""
            say "  ${BOLD}Options:${RESET}"
            say "    ${CYAN}--prefix <dir>${RESET}   Target binary directory for web install (default: /usr/local/bin)"
            say "    ${CYAN}--dry-run${RESET}        Simulate deployment without modifying host"
            say "    ${CYAN}--verify${RESET}         Verify cryptographic SHA-256 seal and exit"
            say "    ${CYAN}--uninstall${RESET}      Cleanly remove oosh package or binary from system"
            say "    ${CYAN}-h, --help${RESET}       Display this manual"
            say ""
            exit 0
            ;;
        *) err "Unknown flag: $1"; exit 1 ;;
    esac
done

banner
story_line "Attuning your environment to the openOODA sovereign shell…"
pause 0.3

# --- Uninstall Path -----------------------------------------------------------
if [ "$DO_UNINSTALL" -eq 1 ]; then
    step "Relinquishing Sovereign Shell"
    FOUND=0
    if command -v dnf >/dev/null 2>&1 && rpm -q oosh >/dev/null 2>&1; then
        if [ "$DRY_RUN" -eq 1 ]; then
            dim "Would remove oosh via dnf remove -y oosh"
        else
            if [ "$(id -u)" -eq 0 ]; then dnf remove -y oosh; else sudo dnf remove -y oosh; fi
            ok "Banished oosh RPM package"
        fi
        FOUND=1
    elif command -v dpkg >/dev/null 2>&1 && dpkg -s oosh >/dev/null 2>&1; then
        if [ "$DRY_RUN" -eq 1 ]; then
            dim "Would remove oosh via apt remove -y oosh"
        else
            if [ "$(id -u)" -eq 0 ]; then apt remove -y oosh; else sudo apt remove -y oosh; fi
            ok "Banished oosh DEB package"
        fi
        FOUND=1
    elif command -v pacman >/dev/null 2>&1 && pacman -Q oosh >/dev/null 2>&1; then
        if [ "$DRY_RUN" -eq 1 ]; then
            dim "Would remove oosh via pacman -R --noconfirm oosh"
        else
            if [ "$(id -u)" -eq 0 ]; then pacman -R --noconfirm oosh; else sudo pacman -R --noconfirm oosh; fi
            ok "Banished oosh Pacman package"
        fi
        FOUND=1
    fi
    for p in /usr/local/bin/oosh /usr/bin/oosh "${HOME}/.local/bin/oosh" "${HOME}/.openooda/bin/oosh"; do
        if [ -f "$p" ]; then
            if [ "$DRY_RUN" -eq 1 ]; then
                dim "Would remove $p"
            else
                rm -f "$p" 2>/dev/null || sudo rm -f "$p"
                ok "Banished ${BOLD}$p${RESET}"
            fi
            FOUND=1
        fi
    done
    if [ "$FOUND" -eq 0 ]; then
        warn "No existing oosh binary or package detected in standard search paths."
    fi
    say ""
    exit 0
fi

# --- Phase 1: Identity & Attunement -------------------------------------------
step "[1/4]  Attuning host & kernel substrate"

OS="$(uname -s)"
if [ "$OS" != "Linux" ]; then
    warn "Non-Linux kernel detected: ${BOLD}${OS}${RESET}"
    story_line "oosh is architected for native Linux. Continuing best-effort…"
fi

ARCH="$(uname -m)"
case "$ARCH" in
    x86_64|amd64) TARGET_ARCH="x86_64" ;;
    aarch64|arm64) TARGET_ARCH="aarch64" ;;
    *)
        err "Unsupported hardware architecture: $ARCH (oosh requires x86_64 or aarch64)"
        exit 1
        ;;
esac

OS_PRETTY="Linux"
if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    OS_PRETTY="${PRETTY_NAME:-Linux}"
fi

say "  ${DIM}os${RESET}       ${GREEN}${OS_PRETTY}${RESET}"
say "  ${DIM}arch${RESET}     ${GREEN}${TARGET_ARCH}${RESET} ${DIM}(${ARCH})${RESET}"
say "  ${DIM}kernel${RESET}   ${GREEN}$(uname -r)${RESET}"

if [ "$INSTALL_METHOD" = "auto" ]; then
    if command -v dnf >/dev/null 2>&1; then
        INSTALL_METHOD="dnf"
    elif command -v apt >/dev/null 2>&1; then
        INSTALL_METHOD="apt"
    elif command -v pacman >/dev/null 2>&1; then
        INSTALL_METHOD="pacman"
    else
        INSTALL_METHOD="web"
    fi
    say "  ${DIM}channel${RESET}  ${CYAN}${INSTALL_METHOD}${RESET} ${DIM}(auto-detected)${RESET}"
else
    say "  ${DIM}channel${RESET}  ${CYAN}${INSTALL_METHOD}${RESET}"
fi

if ! command -v curl >/dev/null 2>&1; then
    err "curl is required to retrieve sovereign release assets"
    exit 1
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

# Resolve destination directory
if [ -n "$CUSTOM_PREFIX" ]; then
    INSTALL_DIR="$CUSTOM_PREFIX"
elif [ "$INSTALL_METHOD" = "dnf" ] || [ "$INSTALL_METHOD" = "apt" ] || [ "$INSTALL_METHOD" = "pacman" ] || [ "$INSTALL_METHOD" = "pkgbuild" ]; then
    INSTALL_DIR="/usr/bin"
elif [ "$(id -u)" -eq 0 ]; then
    INSTALL_DIR="/usr/local/bin"
elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    INSTALL_DIR="/usr/local/bin"
else
    INSTALL_DIR="${HOME}/.local/bin"
fi
say "  ${DIM}target${RESET}   ${CYAN}${INSTALL_DIR}/oosh${RESET}"
pause 0.3

# --- Phase 2: Resolving Release & Provenance ----------------------------------
step "[2/4]  Scrying release channels & provenance"

story_line "Contacting sovereign registry at ${GITHUB_URL}…"
LATEST_TAG=$(curl -sSL -H "Accept: application/vnd.github+json" "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null | grep '"tag_name":' | head -1 | cut -d '"' -f 4 || echo "")
if [ -z "$LATEST_TAG" ]; then
    LATEST_TAG="$VERSION_PIN"
fi
VERSION_NUM="${LATEST_TAG#v}"

case "$INSTALL_METHOD" in
    dnf)
        if [ "$TARGET_ARCH" != "x86_64" ]; then
            err "RPM package currently available for x86_64. Use --web for direct binary installation."
            exit 1
        fi
        ASSET_NAME="oosh-${VERSION_NUM}-1.x86_64.rpm"
        ASSET_URL="${GITHUB_URL}/releases/download/${LATEST_TAG}/${ASSET_NAME}"
        SHA_URL=""
        ;;
    apt)
        if [ "$TARGET_ARCH" != "x86_64" ]; then
            err "DEB package currently available for x86_64 (amd64). Use --web for direct binary installation."
            exit 1
        fi
        ASSET_NAME="oosh_${VERSION_NUM}-1_amd64.deb"
        ASSET_URL="${GITHUB_URL}/releases/download/${LATEST_TAG}/${ASSET_NAME}"
        SHA_URL=""
        ;;
    pacman)
        if [ "$TARGET_ARCH" != "x86_64" ]; then
            err "Pacman package currently available for x86_64. Use --web for direct binary installation."
            exit 1
        fi
        ASSET_NAME="oosh-${VERSION_NUM}-1-x86_64.pkg.tar.zst"
        ASSET_URL="${GITHUB_URL}/releases/download/${LATEST_TAG}/${ASSET_NAME}"
        SHA_URL="${ASSET_URL}.sha256"
        ;;
    pkgbuild)
        ASSET_NAME="PKGBUILD"
        ASSET_URL="https://raw.githubusercontent.com/${REPO}/${LATEST_TAG}/packaging/pacman/PKGBUILD"
        SHA_URL=""
        ;;
    web|*)
        ASSET_NAME="oosh-linux-${TARGET_ARCH}"
        ASSET_URL="${GITHUB_URL}/releases/download/${LATEST_TAG}/${ASSET_NAME}"
        SHA_URL="${GITHUB_URL}/releases/download/${LATEST_TAG}/${ASSET_NAME}.sha256"
        ;;
esac

ok "Channel:  ${BOLD}${LATEST_TAG}${RESET} ${DIM}(canonical release)${RESET}"
ok "Artifact: ${BOLD}${ASSET_NAME}${RESET}"
pause 0.2

if [ "$DRY_RUN" -eq 1 ]; then
    step "[DRY RUN] Verification Plan"
    say "  ${DIM}channel${RESET} ${CYAN}${INSTALL_METHOD}${RESET}"
    say "  ${DIM}fetch${RESET}   ${CYAN}${ASSET_URL}${RESET}"
    if [ "$INSTALL_METHOD" = "dnf" ]; then
        say "  ${DIM}deploy${RESET}  ${CYAN}sudo dnf install -y ${ASSET_NAME}${RESET}"
    elif [ "$INSTALL_METHOD" = "apt" ]; then
        say "  ${DIM}deploy${RESET}  ${CYAN}sudo apt install -y ./${ASSET_NAME}${RESET}"
    elif [ "$INSTALL_METHOD" = "pacman" ]; then
        say "  ${DIM}deploy${RESET}  ${CYAN}sudo pacman -U --noconfirm ${ASSET_NAME}${RESET}"
    elif [ "$INSTALL_METHOD" = "pkgbuild" ]; then
        say "  ${DIM}deploy${RESET}  ${CYAN}makepkg -si --noconfirm (via PKGBUILD)${RESET}"
    else
        if [ -n "$SHA_URL" ]; then
            say "  ${DIM}verify${RESET}  ${CYAN}${SHA_URL}${RESET}"
        fi
        say "  ${DIM}deploy${RESET}  ${CYAN}${INSTALL_DIR}/oosh${RESET}"
    fi
    say ""
    ok "Simulation complete. No host modifications made."
    say ""
    exit 0
fi

# --- Phase 3: Transmission & Cryptographic Seal -------------------------------
step "[3/4]  Transmuting & verifying cryptographic seal"

TMP_DIR="$(mktemp -d /tmp/oosh-bootstrap.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

story_line "Streaming artifact ${ASSET_NAME} from release channel…"
curl -fsSL "$ASSET_URL" -o "${TMP_DIR}/${ASSET_NAME}" &
spin_while $! "Streaming ${ASSET_NAME}"
ok "Transmitted ${ASSET_NAME}"

if [ -n "$SHA_URL" ]; then
    story_line "Acquiring publisher's cryptographic SHA-256 seal…"
    curl -fsSL "$SHA_URL" -o "${TMP_DIR}/${ASSET_NAME}.sha256" 2>/dev/null || true

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
else
    ok "Package distribution artifact ready for installation."
fi
pause 0.3

# --- Phase 4: Awakening the Sovereign Shell -----------------------------------
step "[4/4]  Awakening sovereign shell"

if [ "$INSTALL_METHOD" = "dnf" ]; then
    story_line "Installing RPM package via system package manager…"
    if command -v dnf >/dev/null 2>&1; then
        if [ "$(id -u)" -eq 0 ]; then
            dnf install -y "${TMP_DIR}/${ASSET_NAME}"
        else
            sudo dnf install -y "${TMP_DIR}/${ASSET_NAME}"
        fi
    else
        if [ "$(id -u)" -eq 0 ]; then
            rpm -Uvh --replacepkgs "${TMP_DIR}/${ASSET_NAME}"
        else
            sudo rpm -Uvh --replacepkgs "${TMP_DIR}/${ASSET_NAME}"
        fi
    fi
    INSTALL_DIR="/usr/bin"
    ok "Package installed to ${BOLD}${INSTALL_DIR}/oosh${RESET}"
elif [ "$INSTALL_METHOD" = "apt" ]; then
    story_line "Installing DEB package via system package manager…"
    if command -v apt >/dev/null 2>&1; then
        if [ "$(id -u)" -eq 0 ]; then
            apt install -y "${TMP_DIR}/${ASSET_NAME}"
        else
            sudo apt install -y "${TMP_DIR}/${ASSET_NAME}"
        fi
    else
        if [ "$(id -u)" -eq 0 ]; then
            dpkg -i "${TMP_DIR}/${ASSET_NAME}"
        else
            sudo dpkg -i "${TMP_DIR}/${ASSET_NAME}"
        fi
    fi
    INSTALL_DIR="/usr/bin"
    ok "Package installed to ${BOLD}${INSTALL_DIR}/oosh${RESET}"
elif [ "$INSTALL_METHOD" = "pacman" ]; then
    story_line "Installing Arch package via pacman…"
    if command -v pacman >/dev/null 2>&1; then
        if [ "$(id -u)" -eq 0 ]; then
            pacman -U --noconfirm "${TMP_DIR}/${ASSET_NAME}"
        else
            sudo pacman -U --noconfirm "${TMP_DIR}/${ASSET_NAME}"
        fi
    else
        err "pacman not found on this system. Cannot install pacman package."
        exit 1
    fi
    INSTALL_DIR="/usr/bin"
    ok "Package installed to ${BOLD}${INSTALL_DIR}/oosh${RESET}"
elif [ "$INSTALL_METHOD" = "pkgbuild" ]; then
    story_line "Building package via makepkg…"
    if ! command -v makepkg >/dev/null 2>&1; then
        err "makepkg not found on this system. Install base-devel or use --pacman / --web."
        exit 1
    fi
    (
        cd "$TMP_DIR"
        curl -fsSL "https://raw.githubusercontent.com/${REPO}/${LATEST_TAG}/packaging/pacman/oosh.install" -o oosh.install 2>/dev/null || true
        makepkg -si --noconfirm
    )
    INSTALL_DIR="/usr/bin"
    ok "Package built and installed to ${BOLD}${INSTALL_DIR}/oosh${RESET}"
else
    if [ ! -d "$INSTALL_DIR" ]; then
        mkdir -p "$INSTALL_DIR" 2>/dev/null || sudo mkdir -p "$INSTALL_DIR"
    fi

    chmod +x "${TMP_DIR}/${ASSET_NAME}"

    story_line "Placing binary into ${INSTALL_DIR}…"
    if [ -w "$INSTALL_DIR" ]; then
        mv "${TMP_DIR}/${ASSET_NAME}" "${INSTALL_DIR}/oosh"
    else
        sudo mv "${TMP_DIR}/${ASSET_NAME}" "${INSTALL_DIR}/oosh"
    fi
    ok "Binary situated at ${BOLD}${INSTALL_DIR}/oosh${RESET}"
fi

if "${INSTALL_DIR}/oosh" --version >/dev/null 2>&1; then
    VER_PROVE=$("${INSTALL_DIR}/oosh" --version)
    ok "Living proof: ${GREEN}${BOLD}${VER_PROVE}${RESET}"
else
    warn "Verification probe non-responsive."
fi

INSTALL_DIR="${INSTALL_DIR%/}"

# Detect system-wide installation
IS_SYSTEM_WIDE=0
case "$INSTALL_DIR" in
    /usr/bin|/usr/local/bin|/bin|/sbin|/usr/sbin|/opt/*) IS_SYSTEM_WIDE=1 ;;
esac

# Automatically register in /etc/shells if system-wide and root or passwordless sudo is available
if [ "$IS_SYSTEM_WIDE" -eq 1 ] && [ -f /etc/shells ]; then
    if ! grep -q "^${INSTALL_DIR}/oosh$" /etc/shells 2>/dev/null; then
        story_line "Registering ${INSTALL_DIR}/oosh in /etc/shells…"
        if [ "$(id -u)" -eq 0 ]; then
            echo "${INSTALL_DIR}/oosh" >> /etc/shells 2>/dev/null || true
            if grep -q "^${INSTALL_DIR}/oosh$" /etc/shells 2>/dev/null; then
                ok "Registered ${BOLD}${INSTALL_DIR}/oosh${RESET} in /etc/shells"
            fi
        elif command -v sudo >/dev/null 2>&1; then
            if sudo -n true 2>/dev/null; then
                echo "${INSTALL_DIR}/oosh" | sudo tee -a /etc/shells >/dev/null 2>&1 || true
                if grep -q "^${INSTALL_DIR}/oosh$" /etc/shells 2>/dev/null; then
                    ok "Registered ${BOLD}${INSTALL_DIR}/oosh${RESET} in /etc/shells (via sudo)"
                fi
            elif [ "$IS_TTY" -eq 1 ]; then
                story_line "Requesting sudo authority to register shell in /etc/shells…"
                echo "${INSTALL_DIR}/oosh" | sudo tee -a /etc/shells >/dev/null 2>&1 || true
                if grep -q "^${INSTALL_DIR}/oosh$" /etc/shells 2>/dev/null; then
                    ok "Registered ${BOLD}${INSTALL_DIR}/oosh${RESET} in /etc/shells (via sudo)"
                fi
            fi
        fi
    else
        ok "Shell ${BOLD}${INSTALL_DIR}/oosh${RESET} registered in /etc/shells"
    fi
fi

# Detect systemd-homed managed user or active daemon
IS_HOMED=0
CURRENT_USER="${USER:-$(id -un 2>/dev/null || echo '')}"
if command -v homectl >/dev/null 2>&1; then
    if systemctl is-active systemd-homed >/dev/null 2>&1; then
        IS_HOMED=1
    elif [ -n "$CURRENT_USER" ] && homectl inspect "$CURRENT_USER" >/dev/null 2>&1; then
        IS_HOMED=1
    fi
fi

# PATH Inspection
PATH_OK=0
case ":$PATH:" in
    *:"$INSTALL_DIR":*) PATH_OK=1 ;;
esac

victory_banner

if [ "$PATH_OK" -eq 0 ]; then
    warn "The directory ${BOLD}${INSTALL_DIR}${RESET} is not in your current \$PATH."
    say ""
    say "  To enable ${BOLD}oosh${RESET} across your environment, add to ${BOLD}~/.bashrc${RESET} or ${BOLD}~/.zshrc${RESET}:"
    say "    ${CYAN}export PATH=\"${INSTALL_DIR}:\$PATH\"${RESET}"
    say ""
fi

say "  ${BOLD}Enter your sovereign shell right now:${RESET}"
say "    ${AMBER}${BOLD}${INSTALL_DIR}/oosh${RESET}"
say ""

if [ "$IS_SYSTEM_WIDE" -eq 0 ]; then
    warn "${BOLD}User-space installation detected (${INSTALL_DIR}/oosh).${RESET}"
    say "  ${YELLOW}! WARNING:${RESET} Binaries inside ${BOLD}${HOME}${RESET} ${BOLD}CANNOT${RESET} be safely configured as a login shell"
    say "    (via chsh or homectl) on systems with encrypted or unmounted home directories"
    say "    (${CYAN}systemd-homed${RESET}, LUKS per-user encryption, ecryptfs)."
    say "    Upon logout, your home directory is unmounted. On subsequent login or SSH connection,"
    say "    ${BOLD}${INSTALL_DIR}/oosh${RESET} does not exist on disk before authentication,"
    say "    triggering immediate login failure and session lockout!"
    say ""
    say "  ${BOLD}Recommended Safe Activation (Interactive Chaining):${RESET}"
    say "    Keep your standard login shell (e.g. /bin/bash) and chain into ${BOLD}oosh${RESET} by adding"
    say "    the following hook to the end of your ${BOLD}~/.bashrc${RESET} or ${BOLD}~/.zshrc${RESET}:"
    say ""
    say "      ${CYAN}if [[ \$- == *i* ]] && [ -x \"${INSTALL_DIR}/oosh\" ] && [ \"\$OOSH_ACTIVE\" != \"1\" ]; then${RESET}"
    say "      ${CYAN}    export OOSH_ACTIVE=1${RESET}"
    say "      ${CYAN}    exec \"${INSTALL_DIR}/oosh\"${RESET}"
    say "      ${CYAN}fi${RESET}"
    say ""
elif [ "$IS_HOMED" -eq 1 ]; then
    say "  ${CYAN}${BOLD}systemd-homed environment detected.${RESET}"
    say "  To configure oosh as your default login shell via systemd-homed:"
    say "    ${AMBER}${BOLD}homectl update \"\$USER\" --shell=\"${INSTALL_DIR}/oosh\"${RESET}"
    say ""
    warn "Notice for encrypted home directories & SSH public-key authentication:"
    say "  If your home directory uses per-user encryption, SSH public-key authentication"
    say "  requires systemd-homed to unlock storage on login. Always verify the binary is"
    say "  situated in a system path (${INSTALL_DIR}/oosh). Never use a user-local path inside /home."
    say "  Alternatively, use the safe ${BOLD}~/.bashrc${RESET} interactive chaining hook:"
    say ""
    say "      ${CYAN}if [[ \$- == *i* ]] && [ -x \"${INSTALL_DIR}/oosh\" ] && [ \"\$OOSH_ACTIVE\" != \"1\" ]; then${RESET}"
    say "      ${CYAN}    export OOSH_ACTIVE=1${RESET}"
    say "      ${CYAN}    exec \"${INSTALL_DIR}/oosh\"${RESET}"
    say "      ${CYAN}fi${RESET}"
    say ""
else
    say "  ${BOLD}Make oosh your default login shell:${RESET}"
    if ! grep -q "^${INSTALL_DIR}/oosh$" /etc/shells 2>/dev/null; then
        say "    ${DIM}echo \"${INSTALL_DIR}/oosh\" | sudo tee -a /etc/shells${RESET}"
    fi
    say "    ${BOLD}chsh -s \"${INSTALL_DIR}/oosh\"${RESET}"
    say ""
    say "  ${BOLD}Alternative: Safe ~/.bashrc Interactive Exec Chaining:${RESET}"
    say "  To use oosh interactively without altering system login accounts:"
    say ""
    say "      ${CYAN}if [[ \$- == *i* ]] && [ -x \"${INSTALL_DIR}/oosh\" ] && [ \"\$OOSH_ACTIVE\" != \"1\" ]; then${RESET}"
    say "      ${CYAN}    export OOSH_ACTIVE=1${RESET}"
    say "      ${CYAN}    exec \"${INSTALL_DIR}/oosh\"${RESET}"
    say "      ${CYAN}fi${RESET}"
    say ""
fi
