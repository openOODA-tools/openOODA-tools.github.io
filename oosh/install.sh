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
DO_PURGE=0
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
        --purge) DO_PURGE=1; shift ;;
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
            say "    ${CYAN}--dry-run${RESET}        Simulate deployment or uninstallation without modifying host"
            say "    ${CYAN}--verify${RESET}         Verify cryptographic SHA-256 seal and exit"
            say "    ${CYAN}--uninstall${RESET}      Cleanly remove oosh package or binary, preventing login lockouts"
            say "    ${CYAN}--purge${RESET}          When combined with --uninstall, also purges configuration & history"
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

# --- Comprehensive Clean Uninstall Path ---------------------------------------
if [ "$DO_UNINSTALL" -eq 1 ]; then
    step "Relinquishing Sovereign Shell (oosh)"
    FOUND_SOMETHING=0

    # 1. Login Shell Safety Check (Lockout Prevention)
    story_line "Inspecting login shell accounts to prevent session lockout…"
    INVOKING_USER="${SUDO_USER:-${USER:-$(id -un 2>/dev/null || echo '')}}"
    USERS_TO_CHECK=""
    if [ -n "$INVOKING_USER" ]; then USERS_TO_CHECK="$INVOKING_USER"; fi
    CURRENT_RUN_USER="$(id -un 2>/dev/null || echo '')"
    if [ -n "$CURRENT_RUN_USER" ] && [ "$CURRENT_RUN_USER" != "$INVOKING_USER" ]; then
        USERS_TO_CHECK="${USERS_TO_CHECK} ${CURRENT_RUN_USER}"
    fi

    for target_user in $USERS_TO_CHECK; do
        [ -z "$target_user" ] && continue
        target_shell=""
        if command -v homectl >/dev/null 2>&1 && homectl inspect "$target_user" >/dev/null 2>&1; then
            target_shell=$(homectl inspect "$target_user" 2>/dev/null | grep -i 'Shell:' | awk '{print $2}')
            if echo "$target_shell" | grep -q "oosh"; then
                if [ "$DRY_RUN" -eq 1 ]; then
                    dim "Would revert login shell for ${target_user} from ${target_shell} to /bin/bash (via homectl)"
                else
                    story_line "Reverting ${target_user}'s login shell to /bin/bash via homectl…"
                    if [ "$(id -u)" -eq 0 ]; then
                        homectl update "$target_user" --shell=/bin/bash 2>/dev/null || true
                    elif command -v sudo >/dev/null 2>&1; then
                        sudo homectl update "$target_user" --shell=/bin/bash 2>/dev/null || true
                    fi
                    ok "Reverted ${BOLD}${target_user}${RESET}'s login shell to ${BOLD}/bin/bash${RESET} (prevented lockout)"
                fi
                FOUND_SOMETHING=1
            fi
        else
            target_shell=$(getent passwd "$target_user" 2>/dev/null | cut -d: -f7 || echo "")
            if echo "$target_shell" | grep -q "oosh"; then
                fallback_sh="/bin/bash"
                if [ ! -x "$fallback_sh" ]; then fallback_sh="/bin/sh"; fi
                if [ "$DRY_RUN" -eq 1 ]; then
                    dim "Would revert login shell for ${target_user} from ${target_shell} to ${fallback_sh}"
                else
                    story_line "Reverting ${target_user}'s login shell to ${fallback_sh}…"
                    if [ "$(id -u)" -eq 0 ]; then
                        if command -v usermod >/dev/null 2>&1; then
                            usermod -s "$fallback_sh" "$target_user" 2>/dev/null || true
                        elif command -v chsh >/dev/null 2>&1; then
                            chsh -s "$fallback_sh" "$target_user" 2>/dev/null || true
                        fi
                    elif command -v sudo >/dev/null 2>&1; then
                        if command -v usermod >/dev/null 2>&1; then
                            sudo usermod -s "$fallback_sh" "$target_user" 2>/dev/null || true
                        elif command -v chsh >/dev/null 2>&1; then
                            sudo chsh -s "$fallback_sh" "$target_user" 2>/dev/null || true
                        fi
                    fi
                    ok "Reverted ${BOLD}${target_user}${RESET}'s login shell to ${BOLD}${fallback_sh}${RESET} (prevented lockout)"
                fi
                FOUND_SOMETHING=1
            fi
        fi
    done

    # 2. Deregister from /etc/shells
    if [ -f /etc/shells ] && grep -q '/oosh$' /etc/shells 2>/dev/null; then
        if [ "$DRY_RUN" -eq 1 ]; then
            dim "Would deregister oosh entries from /etc/shells"
        else
            story_line "Removing oosh entries from /etc/shells…"
            if [ "$(id -u)" -eq 0 ]; then
                sed -i -e '\|/oosh$|d' /etc/shells 2>/dev/null || true
            elif command -v sudo >/dev/null 2>&1; then
                sudo sed -i -e '\|/oosh$|d' /etc/shells 2>/dev/null || true
            fi
            if ! grep -q '/oosh$' /etc/shells 2>/dev/null; then
                ok "Deregistered oosh from /etc/shells"
            fi
        fi
        FOUND_SOMETHING=1
    fi

    # 3. Remove Package Manager Workloads
    if command -v dnf >/dev/null 2>&1 && rpm -q oosh >/dev/null 2>&1; then
        if [ "$DRY_RUN" -eq 1 ]; then
            dim "Would remove oosh via dnf remove -y oosh"
        else
            story_line "Removing oosh RPM package via dnf…"
            if [ "$(id -u)" -eq 0 ]; then dnf remove -y oosh; else sudo dnf remove -y oosh; fi
            ok "Removed oosh RPM package"
        fi
        FOUND_SOMETHING=1
    elif command -v dpkg >/dev/null 2>&1 && dpkg -s oosh >/dev/null 2>&1; then
        if [ "$DRY_RUN" -eq 1 ]; then
            dim "Would remove oosh via apt remove -y oosh"
        else
            story_line "Removing oosh DEB package via apt…"
            if [ "$(id -u)" -eq 0 ]; then apt remove -y oosh; else sudo apt remove -y oosh; fi
            ok "Removed oosh DEB package"
        fi
        FOUND_SOMETHING=1
    elif command -v pacman >/dev/null 2>&1 && pacman -Q oosh >/dev/null 2>&1; then
        if [ "$DRY_RUN" -eq 1 ]; then
            dim "Would remove oosh via pacman -R --noconfirm oosh"
        else
            story_line "Removing oosh Pacman package…"
            if [ "$(id -u)" -eq 0 ]; then pacman -R --noconfirm oosh; else sudo pacman -R --noconfirm oosh; fi
            ok "Removed oosh Pacman package"
        fi
        FOUND_SOMETHING=1
    fi

    # 4. Remove Standalone Binaries & Uninstaller Helpers
    SEARCH_BINS="/usr/local/bin/oosh /usr/bin/oosh /opt/oosh/bin/oosh /usr/local/bin/oosh-uninstall /usr/bin/oosh-uninstall"
    for u_home in "${HOME:-}" "${SUDO_USER:+$(getent passwd "$SUDO_USER" 2>/dev/null | cut -d: -f6)}"; do
        if [ -n "$u_home" ] && [ -d "$u_home" ]; then
            SEARCH_BINS="${SEARCH_BINS} ${u_home}/.local/bin/oosh ${u_home}/.local/bin/oosh-uninstall ${u_home}/.openooda/bin/oosh"
        fi
    done
    for bin_path in $SEARCH_BINS; do
        if [ -f "$bin_path" ]; then
            if [ "$DRY_RUN" -eq 1 ]; then
                dim "Would remove binary: $bin_path"
            else
                rm -f "$bin_path" 2>/dev/null || sudo rm -f "$bin_path" 2>/dev/null || true
                ok "Removed binary: ${BOLD}${bin_path}${RESET}"
            fi
            FOUND_SOMETHING=1
        fi
    done

    # 5. Clean Shell Startup Chaining Hooks
    for u_home in "${HOME:-}" "${SUDO_USER:+$(getent passwd "$SUDO_USER" 2>/dev/null | cut -d: -f6)}"; do
        if [ -n "$u_home" ] && [ -d "$u_home" ]; then
            for rc_file in "${u_home}/.bashrc" "${u_home}/.zshrc" "${u_home}/.bash_profile" "${u_home}/.profile"; do
                if [ -f "$rc_file" ] && grep -q "OOSH_ACTIVE" "$rc_file" 2>/dev/null; then
                    if [ "$DRY_RUN" -eq 1 ]; then
                        dim "Would remove oosh chaining hook from ${rc_file}"
                    else
                        sed -i -e '/if \[\[ \$- == \*i\* \]\] && \[ -x .*\/oosh \] && \[ "\$OOSH_ACTIVE" != "1" \]; then/,/fi/d' "$rc_file" 2>/dev/null || true
                        sed -i -e '/OOSH_ACTIVE/d' "$rc_file" 2>/dev/null || true
                        ok "Cleaned oosh chaining hook from ${BOLD}${rc_file}${RESET}"
                    fi
                    FOUND_SOMETHING=1
                fi
            done
        fi
    done

    # 6. Clear Runtime Sockets & Sinks
    for sock_path in /run/oosh "/tmp/oosh-$(id -u 2>/dev/null || echo '')" "${SUDO_USER:+/tmp/oosh-$(id -u "$SUDO_USER" 2>/dev/null || echo '')}"; do
        if [ -e "$sock_path" ]; then
            if [ "$DRY_RUN" -eq 1 ]; then
                dim "Would remove runtime socket path: $sock_path"
            else
                rm -rf "$sock_path" 2>/dev/null || sudo rm -rf "$sock_path" 2>/dev/null || true
                ok "Removed runtime socket ${sock_path}"
            fi
            FOUND_SOMETHING=1
        fi
    done

    # 7. Purge Configuration & History if --purge requested
    if [ "$DO_PURGE" -eq 1 ]; then
        story_line "Purging configuration files and command history…"
        for u_home in "${HOME:-}" "${SUDO_USER:+$(getent passwd "$SUDO_USER" 2>/dev/null | cut -d: -f6)}"; do
            if [ -n "$u_home" ] && [ -d "$u_home" ]; then
                for cfg in "${u_home}/.ooshrc" "${u_home}/.oosh_history" "${u_home}/.oosh_profile"; do
                    if [ -f "$cfg" ]; then
                        if [ "$DRY_RUN" -eq 1 ]; then
                            dim "Would purge: $cfg"
                        else
                            rm -f "$cfg" 2>/dev/null || true
                            ok "Purged configuration ${BOLD}${cfg}${RESET}"
                        fi
                        FOUND_SOMETHING=1
                    fi
                done
            fi
        done
        if [ -d "/etc/oosh" ]; then
            if [ "$DRY_RUN" -eq 1 ]; then
                dim "Would purge /etc/oosh"
            else
                rm -rf /etc/oosh 2>/dev/null || sudo rm -rf /etc/oosh 2>/dev/null || true
                ok "Purged /etc/oosh"
            fi
            FOUND_SOMETHING=1
        fi
    fi

    say ""
    if [ "$FOUND_SOMETHING" -eq 0 ]; then
        ok "System is already completely clean of oosh."
    else
        if [ "$DRY_RUN" -eq 1 ]; then
            ok "Simulation complete. No host modifications made."
        else
            ok "oosh has been cleanly relinquished from your system."
        fi
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
elif command -v sudo >/dev/null 2>&1 && [ -t 0 ] && [ "${IS_TTY:-0}" -eq 1 ]; then
    INSTALL_DIR="/usr/local/bin"
else
    INSTALL_DIR="${HOME}/.local/bin"
fi
INSTALL_DIR="${INSTALL_DIR%/}"

IS_SYSTEM_WIDE=0
case "$INSTALL_DIR" in
    /usr/bin|/usr/local/bin|/bin|/sbin|/usr/sbin|/opt/*) IS_SYSTEM_WIDE=1 ;;
esac

if [ "$IS_SYSTEM_WIDE" -eq 1 ]; then
    say "  ${DIM}target${RESET}   ${CYAN}${INSTALL_DIR}/oosh${RESET} ${DIM}(system-wide, root:root)${RESET}"
else
    say "  ${DIM}target${RESET}   ${CYAN}${INSTALL_DIR}/oosh${RESET} ${DIM}(user-space)${RESET}"
fi
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
        if [ "$IS_SYSTEM_WIDE" -eq 1 ]; then
            say "  ${DIM}deploy${RESET}  ${CYAN}sudo cp ${ASSET_NAME} ${INSTALL_DIR}/oosh && sudo chown root:root && sudo chmod 755${RESET}"
        else
            say "  ${DIM}deploy${RESET}  ${CYAN}cp ${ASSET_NAME} ${INSTALL_DIR}/oosh && chmod 755${RESET}"
        fi
    fi
    if [ "$IS_SYSTEM_WIDE" -eq 1 ]; then
        for u_home in "${HOME:-}" "${SUDO_USER:+$(getent passwd "$SUDO_USER" 2>/dev/null | cut -d: -f6)}"; do
            if [ -n "$u_home" ] && [ -d "$u_home" ]; then
                for shadow_bin in "${u_home}/.local/bin/oosh" "${u_home}/.openooda/bin/oosh"; do
                    if [ -f "$shadow_bin" ] && [ "$shadow_bin" != "${INSTALL_DIR}/oosh" ]; then
                        say "  ${DIM}prune${RESET}   ${YELLOW}Would prune redundant shadow binary at ${shadow_bin}${RESET}"
                    fi
                done
            fi
        done
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
        if [ "$(id -u)" -eq 0 ]; then
            mkdir -p "$INSTALL_DIR" 2>/dev/null
        else
            mkdir -p "$INSTALL_DIR" 2>/dev/null || sudo mkdir -p "$INSTALL_DIR"
        fi
    fi

    chmod 755 "${TMP_DIR}/${ASSET_NAME}"

    story_line "Placing binary into ${INSTALL_DIR}…"
    if [ "$IS_SYSTEM_WIDE" -eq 1 ]; then
        if [ "$(id -u)" -eq 0 ]; then
            cp -f "${TMP_DIR}/${ASSET_NAME}" "${INSTALL_DIR}/oosh"
            chown root:root "${INSTALL_DIR}/oosh" 2>/dev/null || true
            chmod 755 "${INSTALL_DIR}/oosh"
        else
            sudo cp -f "${TMP_DIR}/${ASSET_NAME}" "${INSTALL_DIR}/oosh"
            sudo chown root:root "${INSTALL_DIR}/oosh" 2>/dev/null || true
            sudo chmod 755 "${INSTALL_DIR}/oosh"
        fi
    else
        if [ -w "$INSTALL_DIR" ]; then
            cp -f "${TMP_DIR}/${ASSET_NAME}" "${INSTALL_DIR}/oosh"
        else
            sudo cp -f "${TMP_DIR}/${ASSET_NAME}" "${INSTALL_DIR}/oosh"
        fi
        chmod 755 "${INSTALL_DIR}/oosh"
    fi
    ok "Binary situated at ${BOLD}${INSTALL_DIR}/oosh${RESET}"
fi

if "${INSTALL_DIR}/oosh" --version >/dev/null 2>&1; then
    VER_PROVE=$("${INSTALL_DIR}/oosh" --version)
    ok "Living proof: ${GREEN}${BOLD}${VER_PROVE}${RESET}"
else
    warn "Verification probe non-responsive."
fi

# Privilege boundary audit & enforcement for system-wide installations
if [ "$IS_SYSTEM_WIDE" -eq 1 ] && [ -f "${INSTALL_DIR}/oosh" ]; then
    CURR_OWNER=$(stat -c '%U:%G' "${INSTALL_DIR}/oosh" 2>/dev/null || stat -f '%Su:%Sg' "${INSTALL_DIR}/oosh" 2>/dev/null || echo "")
    if [ "$CURR_OWNER" != "root:root" ]; then
        story_line "Remediating privilege boundary hazard on ${INSTALL_DIR}/oosh (${CURR_OWNER} -> root:root)…"
        if [ "$(id -u)" -eq 0 ]; then
            chown root:root "${INSTALL_DIR}/oosh" 2>/dev/null || true
            chmod 755 "${INSTALL_DIR}/oosh" 2>/dev/null || true
        elif command -v sudo >/dev/null 2>&1; then
            sudo chown root:root "${INSTALL_DIR}/oosh" 2>/dev/null || true
            sudo chmod 755 "${INSTALL_DIR}/oosh" 2>/dev/null || true
        fi
        CURR_OWNER=$(stat -c '%U:%G' "${INSTALL_DIR}/oosh" 2>/dev/null || stat -f '%Su:%Sg' "${INSTALL_DIR}/oosh" 2>/dev/null || echo "")
    fi
    if [ "$CURR_OWNER" = "root:root" ]; then
        ok "Privilege boundary enforced: ${BOLD}${INSTALL_DIR}/oosh${RESET} is owned by ${GREEN}root:root${RESET} (0755)"
    else
        warn "Privilege boundary hazard: ${INSTALL_DIR}/oosh is owned by ${CURR_OWNER}. Expected root:root."
    fi
fi

# Prune redundant user-local shadow binaries when running system-wide
if [ "$IS_SYSTEM_WIDE" -eq 1 ] && [ -x "${INSTALL_DIR}/oosh" ]; then
    TARGET_REAL=$(readlink -f "${INSTALL_DIR}/oosh" 2>/dev/null || echo "${INSTALL_DIR}/oosh")
    for u_home in "${HOME:-}" "${SUDO_USER:+$(getent passwd "$SUDO_USER" 2>/dev/null | cut -d: -f6)}"; do
        if [ -n "$u_home" ] && [ -d "$u_home" ]; then
            for shadow_bin in "${u_home}/.local/bin/oosh" "${u_home}/.openooda/bin/oosh"; do
                if [ -f "$shadow_bin" ]; then
                    SHADOW_REAL=$(readlink -f "$shadow_bin" 2>/dev/null || echo "$shadow_bin")
                    if [ "$SHADOW_REAL" != "$TARGET_REAL" ]; then
                        story_line "Pruning redundant user-local shadow binary at ${shadow_bin}…"
                        rm -f "$shadow_bin" 2>/dev/null || sudo rm -f "$shadow_bin" 2>/dev/null || true
                        if [ ! -f "$shadow_bin" ]; then
                            ok "Pruned redundant shadow binary: ${DIM}${shadow_bin}${RESET}"
                        else
                            warn "Could not remove shadow binary at ${shadow_bin}; please remove manually to avoid PATH shadowing."
                        fi
                    fi
                fi
            done
        fi
    done
fi

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

# Deploy standalone uninstaller helper into INSTALL_DIR
story_line "Situating standalone uninstaller at ${INSTALL_DIR}/oosh-uninstall…"
cat << 'EOF_UNINSTALLER' > "${TMP_DIR}/oosh-uninstall"
#!/bin/sh
# oosh Clean Uninstaller
set -eu

if [ -t 1 ] && [ "${NO_COLOR:-}" = "" ] && [ "${TERM:-dumb}" != "dumb" ]; then
    CYAN="\033[38;5;51m" GREEN="\033[38;5;82m" YELLOW="\033[38;5;220m" MAGENTA="\033[38;5;213m" DIM="\033[38;5;242m" BOLD="\033[1m" RESET="\033[0m"
else
    CYAN="" GREEN="" YELLOW="" MAGENTA="" DIM="" BOLD="" RESET=""
fi
say() { printf '%b\n' "$*"; }
dim() { say "  ${DIM}$*${RESET}"; }
ok()  { say "  ${GREEN}✔${RESET} $*"; }
warn(){ say "  ${YELLOW}!${RESET} $*"; }
err() { say "  ${YELLOW}ERROR:${RESET} $*" >&2; }
step(){ say ""; say " ${CYAN}${BOLD}$*${RESET}"; }
story_line(){ say "  ${MAGENTA}›${RESET} ${DIM}$*${RESET}"; }

DRY_RUN=0
DO_PURGE=0

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) DRY_RUN=1; shift ;;
        --purge) DO_PURGE=1; shift ;;
        -h|--help)
            say "${BOLD}oosh Clean Uninstaller${RESET}"
            say "Usage: $0 [--purge] [--dry-run]"
            exit 0 ;;
        *) err "Unknown option: $1"; exit 1 ;;
    esac
done

say ""
say "  ${BOLD}Relinquishing Sovereign Shell (oosh)${RESET}"
say "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
FOUND_SOMETHING=0

step "[1/6]  Inspecting login shell accounts (lockout prevention)"
INVOKING_USER="${SUDO_USER:-${USER:-$(id -un 2>/dev/null || echo '')}}"
USERS_TO_CHECK=""
if [ -n "$INVOKING_USER" ]; then USERS_TO_CHECK="$INVOKING_USER"; fi
CURRENT_RUN_USER="$(id -un 2>/dev/null || echo '')"
if [ -n "$CURRENT_RUN_USER" ] && [ "$CURRENT_RUN_USER" != "$INVOKING_USER" ]; then USERS_TO_CHECK="${USERS_TO_CHECK} ${CURRENT_RUN_USER}"; fi

for target_user in $USERS_TO_CHECK; do
    [ -z "$target_user" ] && continue
    if command -v homectl >/dev/null 2>&1 && homectl inspect "$target_user" >/dev/null 2>&1; then
        target_shell=$(homectl inspect "$target_user" 2>/dev/null | grep -i 'Shell:' | awk '{print $2}')
        if echo "$target_shell" | grep -q "oosh"; then
            if [ "$DRY_RUN" -eq 1 ]; then
                dim "Would revert login shell for ${target_user} from ${target_shell} to /bin/bash (via homectl)"
            else
                story_line "Reverting ${target_user}'s login shell to /bin/bash via homectl…"
                if [ "$(id -u)" -eq 0 ]; then homectl update "$target_user" --shell=/bin/bash 2>/dev/null || true
                elif command -v sudo >/dev/null 2>&1; then sudo homectl update "$target_user" --shell=/bin/bash 2>/dev/null || true; fi
                ok "Reverted ${BOLD}${target_user}${RESET}'s login shell to ${BOLD}/bin/bash${RESET} (prevented lockout)"
            fi
            FOUND_SOMETHING=1
        fi
    else
        target_shell=$(getent passwd "$target_user" 2>/dev/null | cut -d: -f7 || echo "")
        if echo "$target_shell" | grep -q "oosh"; then
            fallback_sh="/bin/bash"; [ ! -x "$fallback_sh" ] && fallback_sh="/bin/sh"
            if [ "$DRY_RUN" -eq 1 ]; then
                dim "Would revert login shell for ${target_user} from ${target_shell} to ${fallback_sh}"
            else
                story_line "Reverting ${target_user}'s login shell to ${fallback_sh}…"
                if [ "$(id -u)" -eq 0 ]; then
                    if command -v usermod >/dev/null 2>&1; then usermod -s "$fallback_sh" "$target_user" 2>/dev/null || true
                    elif command -v chsh >/dev/null 2>&1; then chsh -s "$fallback_sh" "$target_user" 2>/dev/null || true; fi
                elif command -v sudo >/dev/null 2>&1; then
                    if command -v usermod >/dev/null 2>&1; then sudo usermod -s "$fallback_sh" "$target_user" 2>/dev/null || true
                    elif command -v chsh >/dev/null 2>&1; then sudo chsh -s "$fallback_sh" "$target_user" 2>/dev/null || true; fi
                fi
                ok "Reverted ${BOLD}${target_user}${RESET}'s login shell to ${BOLD}${fallback_sh}${RESET} (prevented lockout)"
            fi
            FOUND_SOMETHING=1
        fi
    fi
done

step "[2/6]  Deregistering shell entries from /etc/shells"
if [ -f /etc/shells ] && grep -q '/oosh$' /etc/shells 2>/dev/null; then
    if [ "$DRY_RUN" -eq 1 ]; then
        dim "Would deregister oosh entries from /etc/shells"
    else
        story_line "Removing oosh entries from /etc/shells…"
        if [ "$(id -u)" -eq 0 ]; then sed -i -e '\|/oosh$|d' /etc/shells 2>/dev/null || true
        elif command -v sudo >/dev/null 2>&1; then sudo sed -i -e '\|/oosh$|d' /etc/shells 2>/dev/null || true; fi
        if ! grep -q '/oosh$' /etc/shells 2>/dev/null; then ok "Deregistered oosh from /etc/shells"; fi
    fi
    FOUND_SOMETHING=1
else
    ok "No oosh registrations found in /etc/shells"
fi

step "[3/6]  Scanning and removing package manager workloads"
if command -v dnf >/dev/null 2>&1 && rpm -q oosh >/dev/null 2>&1; then
    if [ "$DRY_RUN" -eq 1 ]; then dim "Would remove RPM package via dnf remove -y oosh"
    else
        if [ "$(id -u)" -eq 0 ]; then dnf remove -y oosh; else sudo dnf remove -y oosh; fi
        ok "Removed oosh RPM package"
    fi
    FOUND_SOMETHING=1
elif command -v dpkg >/dev/null 2>&1 && dpkg -s oosh >/dev/null 2>&1; then
    if [ "$DRY_RUN" -eq 1 ]; then dim "Would remove DEB package via apt remove -y oosh"
    else
        if [ "$(id -u)" -eq 0 ]; then apt remove -y oosh; else sudo apt remove -y oosh; fi
        ok "Removed oosh DEB package"
    fi
    FOUND_SOMETHING=1
elif command -v pacman >/dev/null 2>&1 && pacman -Q oosh >/dev/null 2>&1; then
    if [ "$DRY_RUN" -eq 1 ]; then dim "Would remove Pacman package via pacman -R --noconfirm oosh"
    else
        if [ "$(id -u)" -eq 0 ]; then pacman -R --noconfirm oosh; else sudo pacman -R --noconfirm oosh; fi
        ok "Removed oosh Pacman package"
    fi
    FOUND_SOMETHING=1
else
    ok "No native package manager installation found"
fi

step "[4/6]  Removing standalone binaries & helpers"
SEARCH_BINS="/usr/local/bin/oosh /usr/bin/oosh /opt/oosh/bin/oosh /usr/local/bin/oosh-uninstall /usr/bin/oosh-uninstall"
for u_home in "${HOME:-}" "${SUDO_USER:+$(getent passwd "$SUDO_USER" 2>/dev/null | cut -d: -f6)}"; do
    if [ -n "$u_home" ] && [ -d "$u_home" ]; then
        SEARCH_BINS="${SEARCH_BINS} ${u_home}/.local/bin/oosh ${u_home}/.local/bin/oosh-uninstall ${u_home}/.openooda/bin/oosh"
    fi
done
for bin_path in $SEARCH_BINS; do
    if [ -f "$bin_path" ]; then
        if [ "$DRY_RUN" -eq 1 ]; then dim "Would remove binary: $bin_path"
        else
            rm -f "$bin_path" 2>/dev/null || sudo rm -f "$bin_path" 2>/dev/null || true
            ok "Removed binary: ${BOLD}${bin_path}${RESET}"
        fi
        FOUND_SOMETHING=1
    fi
done

step "[5/6]  Cleaning shell startup configurations"
for u_home in "${HOME:-}" "${SUDO_USER:+$(getent passwd "$SUDO_USER" 2>/dev/null | cut -d: -f6)}"; do
    if [ -n "$u_home" ] && [ -d "$u_home" ]; then
        for rc_file in "${u_home}/.bashrc" "${u_home}/.zshrc" "${u_home}/.bash_profile" "${u_home}/.profile"; do
            if [ -f "$rc_file" ] && grep -q "OOSH_ACTIVE" "$rc_file" 2>/dev/null; then
                if [ "$DRY_RUN" -eq 1 ]; then dim "Would remove oosh chaining hook from ${rc_file}"
                else
                    sed -i -e '/if \[\[ \$- == \*i\* \]\] && \[ -x .*\/oosh \] && \[ "\$OOSH_ACTIVE" != "1" \]; then/,/fi/d' "$rc_file" 2>/dev/null || true
                    sed -i -e '/OOSH_ACTIVE/d' "$rc_file" 2>/dev/null || true
                    ok "Cleaned oosh chaining hook from ${BOLD}${rc_file}${RESET}"
                fi
                FOUND_SOMETHING=1
            fi
        done
    fi
done

step "[6/6]  Clearing runtime sockets and caches"
for sock_path in /run/oosh "/tmp/oosh-$(id -u 2>/dev/null || echo '')" "${SUDO_USER:+/tmp/oosh-$(id -u "$SUDO_USER" 2>/dev/null || echo '')}"; do
    if [ -e "$sock_path" ]; then
        if [ "$DRY_RUN" -eq 1 ]; then dim "Would remove runtime socket path: $sock_path"
        else
            rm -rf "$sock_path" 2>/dev/null || sudo rm -rf "$sock_path" 2>/dev/null || true
            ok "Removed runtime socket ${sock_path}"
        fi
        FOUND_SOMETHING=1
    fi
done

if [ "$DO_PURGE" -eq 1 ]; then
    story_line "Purging configuration files and command history…"
    for u_home in "${HOME:-}" "${SUDO_USER:+$(getent passwd "$SUDO_USER" 2>/dev/null | cut -d: -f6)}"; do
        if [ -n "$u_home" ] && [ -d "$u_home" ]; then
            for cfg in "${u_home}/.ooshrc" "${u_home}/.oosh_history" "${u_home}/.oosh_profile"; do
                if [ -f "$cfg" ]; then
                    if [ "$DRY_RUN" -eq 1 ]; then dim "Would purge: $cfg"
                    else rm -f "$cfg" 2>/dev/null || true; ok "Purged configuration ${BOLD}${cfg}${RESET}"; fi
                    FOUND_SOMETHING=1
                fi
            done
        fi
    done
    if [ -d "/etc/oosh" ]; then
        if [ "$DRY_RUN" -eq 1 ]; then dim "Would purge /etc/oosh"
        else rm -rf /etc/oosh 2>/dev/null || sudo rm -rf /etc/oosh 2>/dev/null || true; ok "Purged /etc/oosh"; fi
        FOUND_SOMETHING=1
    fi
fi

say ""
if [ "$FOUND_SOMETHING" -eq 0 ]; then
    ok "System is already completely clean of oosh."
else
    if [ "$DRY_RUN" -eq 1 ]; then ok "Simulation complete. No modifications were made to the system."
    else ok "oosh has been cleanly relinquished from your system."; fi
fi
say ""
EOF_UNINSTALLER

chmod 755 "${TMP_DIR}/oosh-uninstall"
if [ "$IS_SYSTEM_WIDE" -eq 1 ]; then
    if [ "$(id -u)" -eq 0 ]; then
        cp -f "${TMP_DIR}/oosh-uninstall" "${INSTALL_DIR}/oosh-uninstall" 2>/dev/null || true
        chown root:root "${INSTALL_DIR}/oosh-uninstall" 2>/dev/null || true
        chmod 755 "${INSTALL_DIR}/oosh-uninstall" 2>/dev/null || true
    else
        sudo cp -f "${TMP_DIR}/oosh-uninstall" "${INSTALL_DIR}/oosh-uninstall" 2>/dev/null || true
        sudo chown root:root "${INSTALL_DIR}/oosh-uninstall" 2>/dev/null || true
        sudo chmod 755 "${INSTALL_DIR}/oosh-uninstall" 2>/dev/null || true
    fi
else
    cp -f "${TMP_DIR}/oosh-uninstall" "${INSTALL_DIR}/oosh-uninstall" 2>/dev/null || true
    chmod 755 "${INSTALL_DIR}/oosh-uninstall" 2>/dev/null || true
fi
if [ -x "${INSTALL_DIR}/oosh-uninstall" ]; then
    ok "Standalone uninstaller ready: ${BOLD}${INSTALL_DIR}/oosh-uninstall${RESET}"
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
