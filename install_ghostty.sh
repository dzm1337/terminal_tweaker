#!/usr/bin/env bash
# ============================================================
# install_ghostty.sh — Ghostty installer
# terminal_tweaker · https://github.com/dzm1337/terminal_tweaker
# ============================================================
# Supports: macOS (x86_64/arm64), Linux (Debian/Arch/Fedora/
#           RHEL/openSUSE families)
# ============================================================

set -uo pipefail

# ── Colours ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ── Logging ───────────────────────────────────────────────────
log_info()    { printf "${BLUE}→${NC} %s\n"   "$1"; }
log_success() { printf "${GREEN}✓${NC} %s\n"  "$1"; }
log_warn()    { printf "${YELLOW}⚠${NC} %s\n" "$1"; }
log_error()   { printf "${RED}✘${NC} %s\n"    "$1" >&2; }

log_section() {
    printf '\n'
    printf '%s\n' "══════════════════════════════════════════"
    printf '  %s\n' "$1"
    printf '%s\n' "══════════════════════════════════════════"
}

_spin() {
    local pid="$1"
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${CYAN}%s${NC}  " "${frames[$((i % ${#frames[@]}))]}"
        (( i++ )) || true
        sleep 0.1
    done
    printf "\r   \r"
}

run_spin() {
    local label="$1"; shift
    printf "  ${CYAN}…${NC}  %s" "$label"
    "$@" &>/dev/null &
    local pid=$!
    _spin "$pid"
    wait "$pid"
    local rc=$?
    if (( rc == 0 )); then
        printf "\r${GREEN}✓${NC} %s\n" "$label"
    else
        printf "\r${RED}✘${NC} %s (exit %d)\n" "$label" "$rc" >&2
    fi
    return "$rc"
}

# ── Helpers ───────────────────────────────────────────────────
check_command() { command -v "$1" &>/dev/null; }

detect_os() {
    case "$OSTYPE" in
        darwin*)    printf 'macos' ;;
        linux-gnu*) printf 'linux' ;;
        *)          printf 'unknown' ;;
    esac
}

detect_linux_distro() {
    local id="unknown"
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        id=$(. /etc/os-release && printf '%s' "${ID:-unknown}")
    elif [[ -f /etc/redhat-release ]]; then
        id="rhel"
    elif [[ -f /etc/debian_version ]]; then
        id="debian"
    fi
    printf '%s' "$id"
}

ghostty_is_installed() {
    check_command ghostty || [[ -d "/Applications/Ghostty.app" ]]
}

# ============================================================
# INSTALL — macOS
# ============================================================

install_ghostty_macos() {
    log_section "Installing Ghostty — macOS"

    if ghostty_is_installed; then
        log_success "Ghostty already installed"
        return 0
    fi

    if ! check_command brew; then
        log_error "Homebrew not found. Install from https://brew.sh and re-run."
        return 1
    fi

    run_spin "Installing Ghostty" brew install --cask ghostty \
        || { log_error "Failed to install Ghostty"; return 1; }

    log_success "Ghostty installed — launch it from Applications or run: ghostty"
}

# ============================================================
# INSTALL — Linux
# ============================================================

install_ghostty_linux() {
    local distro
    distro=$(detect_linux_distro)

    log_section "Installing Ghostty — Linux ($distro)"

    if ghostty_is_installed; then
        log_success "Ghostty already installed ($(ghostty --version 2>/dev/null | head -n1))"
        return 0
    fi

    case "$distro" in
        ubuntu|debian|linuxmint|pop)
            _install_ghostty_debian
            ;;
        arch|manjaro|endeavouros|garuda)
            _install_ghostty_arch
            ;;
        fedora)
            _install_ghostty_fedora
            ;;
        rhel|centos|rocky|almalinux)
            _install_ghostty_unsupported "$distro"
            ;;
        opensuse*|suse*)
            _install_ghostty_unsupported "$distro"
            ;;
        *)
            log_warn "Unrecognised distro '$distro' — attempting Debian-style install"
            _install_ghostty_debian
            ;;
    esac
}

_install_ghostty_debian() {
    log_info "Adding Ghostty apt repository..."

    if ! check_command curl; then
        run_spin "Installing curl" sudo apt-get install -y curl \
            || { log_error "Failed to install curl"; return 1; }
    fi

    sudo mkdir -p /etc/apt/keyrings

    if ! curl -fsSL https://apt.ghostty.org/gpg.key \
            | sudo gpg --dearmor -o /etc/apt/keyrings/ghostty.gpg 2>/dev/null; then
        log_error "Failed to add Ghostty GPG key"
        return 1
    fi

    printf 'deb [signed-by=/etc/apt/keyrings/ghostty.gpg] https://apt.ghostty.org/apt stable main\n' \
        | sudo tee /etc/apt/sources.list.d/ghostty.list >/dev/null

    run_spin "Updating apt index" sudo apt-get update -qq
    run_spin "Installing Ghostty" sudo apt-get install -y ghostty \
        || { log_error "Failed to install Ghostty"; return 1; }

    log_success "Ghostty installed"
}

_install_ghostty_arch() {
    run_spin "Installing Ghostty" sudo pacman -S --noconfirm ghostty \
        || { log_error "Failed to install Ghostty"; return 1; }

    log_success "Ghostty installed"
}

_install_ghostty_fedora() {
    # Ghostty is available via COPR
    log_info "Adding Ghostty COPR repository..."

    if ! check_command dnf; then
        log_error "dnf not found"
        return 1
    fi

    run_spin "Enabling Ghostty COPR" \
        sudo dnf copr enable -y pgdev/ghostty \
        || { log_warn "COPR enable failed; trying direct dnf install..."; }

    run_spin "Installing Ghostty" sudo dnf install -y ghostty \
        || { log_error "Failed to install Ghostty"; _ghostty_manual_hint; return 1; }

    log_success "Ghostty installed"
}

_install_ghostty_unsupported() {
    local distro="$1"
    log_warn "No automated Ghostty installer available for '$distro'."
    _ghostty_manual_hint
    return 1
}

_ghostty_manual_hint() {
    printf '\n'
    printf '  Install Ghostty manually:\n'
    printf '  → https://ghostty.org/download\n'
    printf '  → Or build from source: https://github.com/ghostty-org/ghostty\n'
    printf '\n'
}

# ============================================================
# MAIN
# ============================================================

main() {
    printf '\n'
    printf '%s\n' "══════════════════════════════════════════"
    printf '  Ghostty Installer\n'
    printf '%s\n\n' "══════════════════════════════════════════"

    local os
    os=$(detect_os)

    case "$os" in
        macos)
            install_ghostty_macos
            ;;
        linux)
            install_ghostty_linux
            ;;
        *)
            log_error "Unsupported operating system: $OSTYPE"
            exit 1
            ;;
    esac

    printf '\n'
    printf 'Next step:\n'
    printf '  Run the terminal setup:  ./terminal_setup.sh\n\n'
}

main "$@"
