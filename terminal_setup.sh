#!/usr/bin/env bash
# ============================================================
# terminal_setup.sh — Terminal Setup (single-file edition)
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
BOLD='\033[1m'
NC='\033[0m'

# ── Runtime config ────────────────────────────────────────────
DRY_RUN="${DRY_RUN:-false}"
FORCE_INSTALL="${FORCE_INSTALL:-false}"
VERBOSE="${VERBOSE:-false}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/.config_backups/$(date +%Y%m%d_%H%M%S)}"

NERD_FONT_VERSION="3.2.1"

# ── Tmpdir registry ───────────────────────────────────────────
_TMPDIRS=()

_cleanup() {
    local dir
    for dir in "${_TMPDIRS[@]+"${_TMPDIRS[@]}"}"; do
        [[ -d "$dir" ]] && rm -rf "$dir"
    done
}
trap _cleanup EXIT

make_tmpdir() {
    local dir
    dir=$(mktemp -d)
    _TMPDIRS+=("$dir")
    printf '%s' "$dir"
}

# ============================================================
# LOGGING
# ============================================================

log_info()    { printf "${BLUE}→${NC} %s\n"   "$1"; }
log_success() { printf "${GREEN}✓${NC} %s\n"  "$1"; }
log_warn()    { printf "${YELLOW}⚠${NC} %s\n" "$1"; }
log_error()   { printf "${RED}✘${NC} %s\n"    "$1" >&2; }
log_verbose() { [[ "$VERBOSE" == "true" ]] && printf "${CYAN}·${NC} %s\n" "$1" || true; }

log_section() {
    printf '\n'
    printf '%s\n' "══════════════════════════════════════════"
    printf '  %s\n' "$1"
    printf '%s\n' "══════════════════════════════════════════"
}

# Spinner: used internally by run_spin
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

# run_spin <label> <cmd> [args...]
run_spin() {
    local label="$1"; shift
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] $label: $*"
        return 0
    fi
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

# ============================================================
# UTILITIES
# ============================================================

check_command() { command -v "$1" &>/dev/null; }

run_cmd() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] $*"
        return 0
    fi
    log_verbose "Running: $*"
    "$@"
}

# Portable uppercase — bash 3.2 safe
str_upper_first() {
    local first rest
    first=$(printf '%s' "$1" | cut -c1 | tr '[:lower:]' '[:upper:]')
    rest=$(printf '%s' "$1" | cut -c2-)
    printf '%s%s' "$first" "$rest"
}

backup_config() {
    local config_path="$1"
    [[ ! -e "$config_path" ]] && return 0

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would backup: $config_path → $BACKUP_DIR/"
        return 0
    fi

    mkdir -p "$BACKUP_DIR"
    local backup_name
    backup_name=$(basename "$config_path")
    local backup_path="$BACKUP_DIR/$backup_name"

    if [[ -d "$config_path" ]]; then
        cp -r "$config_path" "$backup_path"
    else
        cp "$config_path" "$backup_path"
    fi

    log_success "Backup: $backup_path"
    printf '%s' "$backup_path"
}

ask_yes_no() {
    local prompt="$1"
    local default="${2:-y}"
    local response

    if [[ "$FORCE_INSTALL" == "true" ]]; then
        return 0
    fi

    printf "${BLUE}→${NC} %s (y/n) [default: %s]: " "$prompt" "$default"
    read -r response
    response="${response:-$default}"
    [[ "$response" =~ ^[Yy]$ ]]
}

# ============================================================
# DETECTION
# ============================================================

detect_os() {
    case "$OSTYPE" in
        darwin*)    printf 'macos' ;;
        linux-gnu*) printf 'linux' ;;
        *)          printf 'unknown' ;;
    esac
}

detect_arch() {
    local machine
    machine=$(uname -m)
    case "$machine" in
        x86_64)        printf 'x86_64' ;;
        aarch64|arm64) printf 'arm64'  ;;
        armv7l|armv6l) printf 'armv7'  ;;
        i686)          printf 'i386'   ;;
        *)             printf '%s' "$machine" ;;
    esac
}

detect_mac_version() {
    sw_vers -productVersion 2>/dev/null | cut -d. -f1
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

get_brew_prefix() {
    if check_command brew; then
        brew --prefix
        return
    fi
    if [[ "$(detect_arch)" == "arm64" ]]; then
        printf '/opt/homebrew'
    else
        printf '/usr/local'
    fi
}

# ============================================================
# INSTALLATION — macOS
# ============================================================

install_macos_deps() {
    local arch
    arch=$(detect_arch)

    log_section "macOS Dependencies (arch: $arch)"

    if ! check_command brew; then
        log_error "Homebrew not found. Install from https://brew.sh and re-run."
        return 1
    fi

    local brew_prefix
    brew_prefix=$(get_brew_prefix)
    eval "$("$brew_prefix/bin/brew" shellenv)" 2>/dev/null || true

    run_spin "Updating Homebrew" brew update --quiet \
        || log_warn "brew update had warnings (continuing)"

    _install_starship_macos
    _install_font_macos
    _install_eza_macos
    _install_neovim_macos "$arch"
    _install_git_macos
}

_install_starship_macos() {
    if check_command starship; then
        log_success "Starship already installed ($(starship --version 2>/dev/null | head -n1))"
        return 0
    fi
    log_info "Installing Starship..."
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would install Starship via official script"
        return 0
    fi
    if ! curl -fsSL https://starship.rs/install.sh | sh -s -- --yes --quiet; then
        log_warn "Official install failed, falling back to brew..."
        run_cmd brew install starship || { log_error "Failed to install Starship"; return 1; }
    fi
    log_success "Starship installed"
}

_install_font_macos() {
    if fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd Font"; then
        log_success "JetBrainsMono Nerd Font already installed"
        return 0
    fi
    run_spin "Installing JetBrainsMono Nerd Font" \
        brew install --cask font-jetbrains-mono-nerd-font \
        || log_warn "Font install had warnings (may already exist)"
}

_install_eza_macos() {
    if check_command eza; then
        log_success "eza already installed ($(eza --version 2>/dev/null | head -n1))"
        return 0
    fi
    run_spin "Installing eza" brew install eza \
        || { log_error "Failed to install eza"; return 1; }
}

_install_git_macos() {
    if check_command git; then
        log_success "git already installed ($(git --version))"
        return 0
    fi
    run_spin "Installing git" brew install git \
        || { log_error "Failed to install git"; return 1; }
}

_install_neovim_macos() {
    local arch="$1"

    if check_command nvim; then
        log_success "Neovim already installed ($(nvim --version 2>/dev/null | head -n1))"
        return 0
    fi

    # Prefer brew for simpler upgrades later
    if check_command brew; then
        run_spin "Installing Neovim" brew install neovim \
            && { log_success "Neovim installed via brew"; return 0; }
        log_warn "brew install neovim failed, trying binary tarball..."
    fi

    local nvim_url
    case "$arch" in
        arm64)  nvim_url="https://github.com/neovim/neovim/releases/download/stable/nvim-macos-arm64.tar.gz" ;;
        x86_64) nvim_url="https://github.com/neovim/neovim/releases/download/stable/nvim-macos-x86_64.tar.gz" ;;
        *)
            log_error "Unsupported architecture for Neovim binary: $arch"
            return 1
            ;;
    esac

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would download Neovim from $nvim_url"
        return 0
    fi

    local tmpdir
    tmpdir=$(make_tmpdir)

    log_info "Downloading Neovim for $arch..."
    if ! curl -L --fail --progress-bar -o "$tmpdir/nvim.tar.gz" "$nvim_url"; then
        log_error "Failed to download Neovim"
        return 1
    fi

    tar xzf "$tmpdir/nvim.tar.gz" -C "$tmpdir"

    local extracted_dir
    extracted_dir=$(find "$tmpdir" -maxdepth 1 -name 'nvim-macos-*' -type d | head -n1)

    if [[ -z "$extracted_dir" ]]; then
        log_error "Could not find extracted Neovim directory"
        return 1
    fi

    log_info "Installing Neovim to /usr/local/bin (requires sudo)..."
    sudo rm -rf /usr/local/bin/nvim /usr/local/share/nvim 2>/dev/null || true
    sudo mv "$extracted_dir/bin/nvim" /usr/local/bin/nvim
    [[ -d "$extracted_dir/share/nvim" ]] && \
        sudo mv "$extracted_dir/share/nvim" /usr/local/share/nvim

    log_success "Neovim installed ($(nvim --version 2>/dev/null | head -n1))"
}

# ============================================================
# INSTALLATION — Linux
# ============================================================

install_linux_deps() {
    local distro
    distro=$(detect_linux_distro)

    log_section "Linux Dependencies (distro: $distro)"

    case "$distro" in
        ubuntu|debian|linuxmint|pop)
            _install_debian_deps
            ;;
        arch|manjaro|endeavouros|garuda)
            _install_arch_deps
            ;;
        fedora)
            _install_fedora_deps
            ;;
        rhel|centos|rocky|almalinux)
            _install_rhel_deps
            ;;
        opensuse*|suse*)
            _install_opensuse_deps
            ;;
        *)
            log_warn "Unrecognised distro '$distro' — attempting Debian-style install"
            _install_debian_deps
            ;;
    esac
}

_install_starship_linux() {
    if check_command starship; then
        log_success "Starship already installed ($(starship --version 2>/dev/null | head -n1))"
        return 0
    fi
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would install Starship via official script"
        return 0
    fi
    log_info "Installing Starship..."
    curl -fsSL https://starship.rs/install.sh | sh -s -- --yes --quiet \
        || { log_error "Failed to install Starship"; return 1; }
    log_success "Starship installed"
}

_install_debian_deps() {
    run_spin "Updating apt index" sudo apt-get update -qq

    local pkgs="neovim curl wget git zsh build-essential unzip"
    run_spin "Installing packages" sudo apt-get install -y $pkgs \
        || { log_error "apt-get install failed"; return 1; }

    _install_starship_linux
    _install_eza_debian
    _install_nerd_font_linux
}

_install_eza_debian() {
    if check_command eza; then
        log_success "eza already installed ($(eza --version 2>/dev/null | head -n1))"
        return 0
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would add eza apt repo and install"
        return 0
    fi

    log_info "Adding eza apt repository..."
    sudo mkdir -p /etc/apt/keyrings

    if ! wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
            | sudo gpg --dearmor -o /etc/apt/keyrings/eza.gpg 2>/dev/null; then
        log_warn "Failed to add eza GPG key; skipping eza"
        return 1
    fi

    printf 'deb [signed-by=/etc/apt/keyrings/eza.gpg] http://deb.gierens.de stable main\n' \
        | sudo tee /etc/apt/sources.list.d/eza.list >/dev/null

    run_spin "Installing eza" sudo apt-get update -qq \
        && sudo apt-get install -y eza \
        || log_warn "Failed to install eza"
}

_install_arch_deps() {
    run_spin "Syncing pacman" sudo pacman -Syu --noconfirm

    local pkgs="neovim curl wget git zsh base-devel eza unzip"
    run_spin "Installing packages" sudo pacman -S --needed --noconfirm $pkgs \
        || { log_error "pacman install failed"; return 1; }

    _install_starship_linux
    _install_nerd_font_linux
}

_install_fedora_deps() {
    run_cmd sudo dnf check-update || true  # exit 100 = updates available, not an error

    local pkgs="neovim curl wget git zsh gcc gcc-c++ make unzip"
    run_spin "Installing packages" sudo dnf install -y $pkgs \
        || { log_error "dnf install failed"; return 1; }

    _install_starship_linux

    if check_command eza; then
        log_success "eza already installed"
    else
        run_cmd sudo dnf install -y eza 2>/dev/null \
            || _install_eza_cargo
    fi

    _install_nerd_font_linux
}

_install_rhel_deps() {
    run_cmd sudo dnf install -y epel-release || log_warn "EPEL install failed (continuing)"

    local pkgs="neovim curl wget git zsh gcc gcc-c++ make unzip"
    run_spin "Installing packages" sudo dnf install -y $pkgs \
        || { log_error "dnf install failed"; return 1; }

    _install_starship_linux
    check_command eza || _install_eza_cargo
    _install_nerd_font_linux
}

_install_opensuse_deps() {
    run_spin "Refreshing zypper" sudo zypper refresh

    local pkgs="neovim curl wget git zsh gcc gcc-c++ make unzip"
    run_spin "Installing packages" sudo zypper install -y $pkgs \
        || { log_error "zypper install failed"; return 1; }

    _install_starship_linux
    check_command eza || _install_eza_cargo
    _install_nerd_font_linux
}

_install_eza_cargo() {
    if check_command cargo; then
        run_spin "Installing eza via cargo" cargo install eza \
            || log_warn "cargo install eza failed"
    else
        log_warn "eza not available and cargo not found; install eza manually"
    fi
}

_install_nerd_font_linux() {
    local font_dir="$HOME/.local/share/fonts"
    local marker="$font_dir/JetBrainsMonoNerdFont-Regular.ttf"

    if [[ -f "$marker" ]]; then
        log_success "JetBrainsMono Nerd Font already installed"
        return 0
    fi

    local font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v${NERD_FONT_VERSION}/JetBrainsMono.zip"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would download font from $font_url"
        return 0
    fi

    if ! check_command wget && ! check_command curl; then
        log_warn "Neither wget nor curl found; skipping font install"
        return 1
    fi

    mkdir -p "$font_dir"
    local tmpdir
    tmpdir=$(make_tmpdir)
    local archive="$tmpdir/JetBrainsMono.zip"

    if check_command wget; then
        run_spin "Downloading JetBrainsMono Nerd Font" wget -q -O "$archive" "$font_url"
    else
        run_spin "Downloading JetBrainsMono Nerd Font" curl -fsSL -o "$archive" "$font_url"
    fi

    if [[ ! -f "$archive" ]]; then
        log_warn "Font download failed; skipping"
        return 1
    fi

    if ! check_command unzip; then
        log_warn "unzip not found; skipping font install"
        return 1
    fi

    unzip -q "$archive" -d "$font_dir/" 2>/dev/null || true
    fc-cache -fv >/dev/null 2>&1 || true
    log_success "JetBrainsMono Nerd Font installed"
}

# ============================================================
# CONFIGURATION
# ============================================================

configure_ghostty() {
    log_section "Configure Ghostty"

    if ! check_command ghostty && [[ ! -d "/Applications/Ghostty.app" ]]; then
        log_warn "Ghostty not found — skipping config. Install it first: https://ghostty.org/download"
        return 0
    fi

    printf "${BLUE}→${NC} Choose a theme (1-10) [default: 1]:\n"
    printf '   1.  Tokyo Night\n'
    printf '   2.  Catppuccin Mocha\n'
    printf '   3.  Catppuccin Frappe\n'
    printf '   4.  Dracula\n'
    printf '   5.  Gruvbox Dark\n'
    printf '   6.  Nord\n'
    printf '   7.  One Dark Two\n'
    printf '   8.  Rose Pine\n'
    printf '   9.  Kanagawa Dragon\n'
    printf '  10.  Everforest Dark Hard\n'
    printf 'Choice: '
    read -r theme_choice

    local theme
    case "${theme_choice:-1}" in
        1)  theme="TokyoNight" ;;
        2)  theme="Catppuccin Mocha" ;;
        3)  theme="Catppuccin Frappe" ;;
        4)  theme="Dracula" ;;
        5)  theme="Gruvbox Dark" ;;
        6)  theme="Nord" ;;
        7)  theme="One Dark Two" ;;
        8)  theme="Rose Pine" ;;
        9)  theme="Kanagawa Dragon" ;;
        10) theme="Everforest Dark Hard" ;;
        *)  theme="TokyoNight" ;;
    esac

    log_info "Selected theme: $theme"

    local ghostty_config="$HOME/.config/ghostty/config"
    [[ -e "$ghostty_config" ]] && backup_config "$ghostty_config"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would write Ghostty config (theme=$theme)"
        return 0
    fi

    mkdir -p "$HOME/.config/ghostty"

    cat >"$ghostty_config" <<EOF
theme = $theme
background-opacity = 1.0
font-family = "JetBrainsMono Nerd Font"
font-size = 15
font-thicken = true
cursor-style = block
cursor-style-blink = false
confirm-close-surface = false
mouse-hide-while-typing = true
EOF

    log_success "Ghostty configured (theme: $theme)"
}

configure_starship() {
    log_section "Configure Starship"

    if ! check_command starship; then
        log_warn "Starship not found; skipping configuration"
        return 0
    fi

    if ! ask_yes_no "Configure Starship prompt?" "y"; then
        log_info "Skipping Starship configuration"
        return 0
    fi

    local starship_config="$HOME/.config/starship.toml"

    if [[ -e "$starship_config" ]]; then
        backup_config "$starship_config"
        if ! ask_yes_no "Existing Starship config found. Overwrite?" "y"; then
            log_info "Keeping existing Starship config"
            return 0
        fi
    fi

    if ask_yes_no "Use a Starship preset?" "y"; then
        printf "${BLUE}→${NC} Choose a preset (1-13) [default: 1]:\n"
        printf '   1.  Nerd Font Symbols\n'
        printf '   2.  No Nerd Fonts\n'
        printf '   3.  Bracketed Segments\n'
        printf '   4.  Plain Text\n'
        printf '   5.  No Runtime Versions\n'
        printf '   6.  No Empty Icons\n'
        printf '   7.  Pure Prompt\n'
        printf '   8.  Pastel Powerline\n'
        printf '   9.  Tokyo Night\n'
        printf '  10.  Gruvbox Rainbow\n'
        printf '  11.  Jetpack\n'
        printf '  12.  Catppuccin Powerline\n'
        printf '  13.  Default (minimal custom)\n'
        printf 'Choice: '
        read -r preset_choice

        local preset_slug
        case "${preset_choice:-1}" in
            1)  preset_slug="nerd-font-symbols" ;;
            2)  preset_slug="no-nerd-font" ;;
            3)  preset_slug="bracketed-segments" ;;
            4)  preset_slug="plain-text-symbols" ;;
            5)  preset_slug="no-runtime-versions" ;;
            6)  preset_slug="no-empty-icons" ;;
            7)  preset_slug="pure-preset" ;;
            8)  preset_slug="pastel-powerline" ;;
            9)  preset_slug="tokyo-night" ;;
            10) preset_slug="gruvbox-rainbow" ;;
            11) preset_slug="jetpack" ;;
            12) preset_slug="catppuccin-powerline" ;;
            *)  preset_slug="" ;;
        esac

        if [[ -n "$preset_slug" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                log_info "[DRY-RUN] Would run: starship preset $preset_slug -o $starship_config"
            else
                mkdir -p "$HOME/.config"
                starship preset "$preset_slug" -o "$starship_config" \
                    && log_success "Starship preset applied: $preset_slug" \
                    || log_warn "Failed to apply preset; falling back to minimal config"
            fi
            return 0
        fi
    fi

    # Minimal default
    if [[ "$DRY_RUN" != "true" ]]; then
        mkdir -p "$HOME/.config"
        cat >"$starship_config" <<'EOF'
format = "$directory$git_branch$git_status$python$nodejs$rust$go$cmd_duration$line_break$character"

[directory]
truncation_length = 3

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[✘](bold red)"
EOF
    fi
    log_success "Minimal Starship config written"
}

configure_shell() {
    log_section "Configure Shell"

    printf "${BLUE}→${NC} Choose your shell (1-2) [default: 1]:\n"
    printf '  1. Zsh\n'
    printf '  2. Bash\n'
    printf 'Choice: '
    read -r shell_choice

    local shell_type rc_file
    if [[ "${shell_choice:-1}" == "2" ]]; then
        shell_type="bash"
        rc_file="$HOME/.bashrc"
    else
        shell_type="zsh"
        rc_file="$HOME/.zshrc"
    fi

    log_info "Shell: $shell_type → $rc_file"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would update $rc_file with Starship init and eza aliases"
        return 0
    fi

    [[ ! -f "$rc_file" ]] && touch "$rc_file"

    # ── Starship init ─────────────────────────────────────────
    if grep -q "starship init" "$rc_file" 2>/dev/null; then
        log_success "Starship init already in $rc_file"
    else
        cat >>"$rc_file" <<EOF

# ── Starship prompt (added by terminal_tweaker) ──
if command -v starship &>/dev/null; then
    eval "\$(starship init $shell_type)"
fi
EOF
        log_success "Starship init added to $rc_file"
    fi

    # ── eza aliases ───────────────────────────────────────────
    # Guard uses the terminal_tweaker marker so it doesn't match
    # aliases the user wrote themselves.
    if grep -q "terminal_tweaker" "$rc_file" 2>/dev/null; then
        log_success "eza aliases already in $rc_file"
    else
        cat >>"$rc_file" <<'EOF'

# ── eza aliases (added by terminal_tweaker) ──
if command -v eza &>/dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -lh --icons --group-directories-first --git'
    alias lt='eza --tree --level=2 --icons --git'
    alias la='eza -lah --icons --group-directories-first --git'
fi
EOF
        log_success "eza aliases added to $rc_file"
    fi

    printf "${BLUE}→${NC} Reload with: ${GREEN}source %s${NC}\n" "$rc_file"
}

configure_neovim() {
    log_section "Configure Neovim"

    local nvim_dir="$HOME/.config/nvim"

    if [[ -d "$nvim_dir" ]]; then
        log_warn "Existing Neovim config found at $nvim_dir"
        if ask_yes_no "Back it up and install LazyVim?" "y"; then
            backup_config "$nvim_dir"
            [[ "$DRY_RUN" != "true" ]] && rm -rf "$nvim_dir"
        else
            log_info "Keeping existing Neovim config"
            return 0
        fi
    fi

    if ! ask_yes_no "Install LazyVim starter?" "y"; then
        log_info "Skipping Neovim configuration"
        return 0
    fi

    if ! check_command git; then
        log_error "git is required to install LazyVim but was not found"
        return 1
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would clone LazyVim/starter into $nvim_dir"
        return 0
    fi

    log_info "Cloning LazyVim starter..."
    if git clone --quiet https://github.com/LazyVim/starter "$nvim_dir"; then
        rm -rf "$nvim_dir/.git"
        log_success "LazyVim installed — open nvim and run :Lazy sync"
    else
        log_error "Failed to clone LazyVim starter"
        return 1
    fi
}

# ============================================================
# ARGUMENT PARSING
# ============================================================

show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -h, --help       Show this help
  -n, --dry-run    Preview changes without applying them
  -f, --force      Non-interactive; accept all defaults
  -v, --verbose    Show extra output

Environment variables:
  DRY_RUN=true        Same as --dry-run
  FORCE_INSTALL=true  Same as --force
  VERBOSE=true        Same as --verbose

Examples:
  ./terminal_setup.sh
  ./terminal_setup.sh --dry-run
  ./terminal_setup.sh --force
  FORCE_INSTALL=true ./terminal_setup.sh
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)    show_help; exit 0 ;;
            -n|--dry-run) DRY_RUN=true; shift ;;
            -f|--force)   FORCE_INSTALL=true; shift ;;
            -v|--verbose) VERBOSE=true; shift ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# ============================================================
# MAIN
# ============================================================

main() {
    parse_args "$@"

    clear

    printf '%s\n' "══════════════════════════════════════════"
    printf '  Ghostty · Neovim · Starship · eza\n'
    printf '  Terminal Setup\n'
    [[ "$DRY_RUN" == "true" ]] && \
        printf '  *** DRY-RUN MODE — no changes will be made ***\n'
    printf '%s\n\n' "══════════════════════════════════════════"

    local os arch
    os=$(detect_os)
    arch=$(detect_arch)

    if [[ "$os" == "unknown" ]]; then
        log_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi

    log_info "OS: $(str_upper_first "$os") | Arch: $arch"

    if [[ "$os" == "macos" ]]; then
        log_info "macOS version: $(detect_mac_version)"
        install_macos_deps || { log_error "macOS dependency install failed"; exit 1; }
    else
        log_info "Distro: $(detect_linux_distro)"
        install_linux_deps || { log_error "Linux dependency install failed"; exit 1; }
    fi

    configure_ghostty
    configure_starship
    configure_shell
    configure_neovim

    log_section "Setup Complete"

    [[ -d "$BACKUP_DIR" ]] && \
        printf "${GREEN}✓${NC} Backups at: %s\n\n" "$BACKUP_DIR"

    printf 'Next steps:\n'
    printf '  1. Reload shell:    source ~/.zshrc  (or ~/.bashrc)\n'
    printf '  2. Test listing:    ls\n'
    printf '  3. Open Neovim:     nvim  →  :Lazy sync\n'
    printf '  4. Health check:    ./health_check.sh\n\n'

    printf 'Tips:\n'
    printf '  • Change theme:     edit ~/.config/ghostty/config\n'
    printf '  • Tweak prompt:     edit ~/.config/starship.toml\n\n'

    printf 'Enjoy your setup! ✨\n\n'
}

main "$@"
