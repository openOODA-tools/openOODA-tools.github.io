#!/bin/sh
# ==============================================================================
# oosh Clean Uninstaller
# Safely deprovisions oosh, prevents login lockouts, cleans packages & binaries.
#
# Usage:
#   curl -fsSL https://openooda-tools.github.io/oosh/uninstall.sh | bash
#   or locally:
#   oosh-uninstall [--purge] [--dry-run]
# ==============================================================================

set -eu

if [ -t 1 ] && [ "${NO_COLOR:-}" = "" ] && [ "${TERM:-dumb}" != "dumb" ]; then
    CYAN="\033[38;5;51m"
    GREEN="\033[38;5;82m"
    YELLOW="\033[38;5;220m"
    MAGENTA="\033[38;5;213m"
    DIM="\033[38;5;242m"
    BOLD="\033[1m"
    RESET="\033[0m"
    IS_TTY=1
else
    CYAN="" GREEN="" YELLOW="" MAGENTA="" DIM="" BOLD="" RESET=""
    IS_TTY=0
fi

say()  { printf '%b\n' "$*"; }
dim()  { say "  ${DIM}$*${RESET}"; }
ok()   { say "  ${GREEN}✔${RESET} $*"; }
warn() { say "  ${YELLOW}!${RESET} $*"; }
err()  { say "  ${YELLOW}ERROR:${RESET} $*" >&2; }
step() { say ""; say " ${CYAN}${BOLD}$*${RESET}"; }

story_line() {
    say "  ${MAGENTA}›${RESET} ${DIM}$*${RESET}"
}

DRY_RUN=0
DO_PURGE=0

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) DRY_RUN=1; shift ;;
        --purge) DO_PURGE=1; shift ;;
        -h|--help)
            say "${BOLD}oosh Clean Uninstaller${RESET}"
            say "Usage: $0 [options]"
            say ""
            say "Options:"
            say "  ${CYAN}--dry-run${RESET}   Simulate uninstallation without modifying host"
            say "  ${CYAN}--purge${RESET}     Also remove user configuration and command history (~/.ooshrc, ~/.oosh_history)"
            say "  ${CYAN}-h, --help${RESET}  Display this manual"
            say ""
            exit 0
            ;;
        *) err "Unknown option: $1"; exit 1 ;;
    esac
done

say ""
say "  ${BOLD}Relinquishing Sovereign Shell (oosh)${RESET}"
say "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

FOUND_SOMETHING=0

# --- Phase 1: Login Shell Safety Check ----------------------------------------
step "[1/6]  Inspecting login shell accounts (lockout prevention)"

INVOKING_USER="${SUDO_USER:-${USER:-$(id -un 2>/dev/null || echo '')}}"
USERS_TO_CHECK=""
if [ -n "$INVOKING_USER" ]; then
    USERS_TO_CHECK="$INVOKING_USER"
fi
CURRENT_RUN_USER="$(id -un 2>/dev/null || echo '')"
if [ -n "$CURRENT_RUN_USER" ] && [ "$CURRENT_RUN_USER" != "$INVOKING_USER" ]; then
    USERS_TO_CHECK="${USERS_TO_CHECK} ${CURRENT_RUN_USER}"
fi

for target_user in $USERS_TO_CHECK; do
    [ -z "$target_user" ] && continue
    target_shell=""

    # Check systemd-homed
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
        # Standard /etc/passwd or getent
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

# --- Phase 2: Deregister from /etc/shells --------------------------------------
step "[2/6]  Deregistering shell entries from /etc/shells"

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
else
    ok "No oosh registrations found in /etc/shells"
fi

# --- Phase 3: Package Manager Deinstallation -----------------------------------
step "[3/6]  Scanning and removing package manager workloads"

if command -v dnf >/dev/null 2>&1 && rpm -q oosh >/dev/null 2>&1; then
    if [ "$DRY_RUN" -eq 1 ]; then
        dim "Would remove RPM package via dnf remove -y oosh"
    else
        story_line "Removing RPM package via dnf…"
        if [ "$(id -u)" -eq 0 ]; then dnf remove -y oosh; else sudo dnf remove -y oosh; fi
        ok "Removed oosh RPM package"
    fi
    FOUND_SOMETHING=1
elif command -v dpkg >/dev/null 2>&1 && dpkg -s oosh >/dev/null 2>&1; then
    if [ "$DRY_RUN" -eq 1 ]; then
        dim "Would remove DEB package via apt remove -y oosh"
    else
        story_line "Removing DEB package via apt…"
        if [ "$(id -u)" -eq 0 ]; then apt remove -y oosh; else sudo apt remove -y oosh; fi
        ok "Removed oosh DEB package"
    fi
    FOUND_SOMETHING=1
elif command -v pacman >/dev/null 2>&1 && pacman -Q oosh >/dev/null 2>&1; then
    if [ "$DRY_RUN" -eq 1 ]; then
        dim "Would remove Pacman package via pacman -R --noconfirm oosh"
    else
        story_line "Removing Pacman package…"
        if [ "$(id -u)" -eq 0 ]; then pacman -R --noconfirm oosh; else sudo pacman -R --noconfirm oosh; fi
        ok "Removed oosh Pacman package"
    fi
    FOUND_SOMETHING=1
else
    ok "No native package manager installation found"
fi

# --- Phase 4: Standalone Binaries & Helpers Removal ---------------------------
step "[4/6]  Removing standalone binaries & helpers"

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

# --- Phase 5: Shell Interactive Chaining Hooks --------------------------------
step "[5/6]  Cleaning shell startup configurations"

HOOK_COUNT=0
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
                HOOK_COUNT=$((HOOK_COUNT + 1))
                FOUND_SOMETHING=1
            fi
        done
    fi
done
if [ "$HOOK_COUNT" -eq 0 ]; then
    ok "No interactive shell chaining hooks found in user profiles"
fi

# --- Phase 6: Runtime Sockets & Configuration Purge ---------------------------
step "[6/6]  Clearing runtime sockets and caches"

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

if [ "$DO_PURGE" -eq 1 ]; then
    story_line "Purging configuration files, command history, and telemetry…"
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
else
    dim "User configuration (~/.ooshrc, ~/.oosh_history) preserved. Use --purge to remove."
fi

say ""
if [ "$FOUND_SOMETHING" -eq 0 ]; then
    ok "System is already completely clean of oosh."
else
    if [ "$DRY_RUN" -eq 1 ]; then
        ok "Simulation complete. No modifications were made to the system."
    else
        ok "oosh has been cleanly relinquished from your system."
    fi
fi
say ""
