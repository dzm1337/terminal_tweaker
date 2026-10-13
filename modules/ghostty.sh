# shellcheck shell=bash
# ============================================================
# modules/ghostty.sh — install + configure Ghostty
# ============================================================
# Linux strategy, in order:
#   1. native package (Arch, openSUSE Tumbleweed, Alpine, Void, …)
#   2. distro-specific community repo (Fedora COPR, Ubuntu/Debian .debs)
#   3. snap, if available
#   4. print manual instructions

GHOSTTY_THEMES=(
  "TokyoNight" "Catppuccin Mocha" "Catppuccin Frappe" "Dracula"
  "Gruvbox Dark" "Nord" "One Dark Two" "Rose Pine"
  "Kanagawa Dragon" "Everforest Dark Hard"
)

ghostty_is_installed() {
  check_command ghostty || [[ -d "/Applications/Ghostty.app" ]]
}

step_ghostty() {
  log_section "Ghostty"

  if [[ "$IS_WSL" == "true" ]]; then
    log_warn "WSL detected — Ghostty has no Windows build yet; skipping."
    return 0
  fi

  if ghostty_is_installed; then
    log_success "Ghostty already installed"
  elif [[ "$OS" == "macos" ]]; then
    run_spin "Installing Ghostty" brew install --cask ghostty || return 1
  else
    _install_ghostty_linux || return 0 # not fatal: everything else still works
  fi

  configure_ghostty
}

_install_ghostty_linux() {
  case "$PKG_MGR" in
  pacman | zypper | apk | xbps)
    SOFT_FAIL=true pkg_install ghostty && return 0
    ;;
  dnf)
    if distro_is fedora; then
      SOFT_FAIL=true run_spin "Enabling COPR scottames/ghostty" _ghostty_enable_copr &&
        pkg_install ghostty && return 0
    fi
    ;;
  apt)
    # Community .deb builds: Ubuntu 24.04+, Debian 13+, Mint, Pop, elementary…
    make_tmpdir
    SOFT_FAIL=true run_spin "Installing Ghostty (ghostty-ubuntu .deb)" _ghostty_deb_install && return 0
    ;;
  esac

  if check_command snap; then
    run_spin "Installing Ghostty (snap)" as_root snap install ghostty --classic && return 0
  fi

  log_warn "No automated Ghostty install for '$DISTRO_ID $DISTRO_VERSION'."
  printf '  Install manually: https://ghostty.org/docs/install/binary\n'
  printf '  Then re-run:      ./install.sh --only ghostty\n'
  return 1
}

_ghostty_enable_copr() {
  # 'dnf-command(copr)' resolves to the right plugin on both dnf4 and dnf5
  as_root dnf install -y 'dnf-command(copr)' &&
    as_root dnf copr enable -y scottames/ghostty
}

_ghostty_deb_install() {
  # Run from the tmpdir: the script downloads the .deb into $PWD.
  download "https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh" "$TMP_DIR/install.sh" &&
    (cd "$TMP_DIR" && bash ./install.sh)
}

configure_ghostty() {
  if ! ghostty_is_installed && ! is_dry_run; then
    log_warn "Ghostty not installed — skipping its config"
    return 0
  fi

  choose "Choose a Ghostty theme:" 1 "${GHOSTTY_THEMES[@]}"
  local theme="${GHOSTTY_THEMES[$((CHOICE - 1))]}"
  local config="$HOME/.config/ghostty/config"

  backup_config "$config"
  if is_dry_run; then
    log_info "[dry-run] Would write $config (theme: $theme)"
    return 0
  fi

  mkdir -p "$(dirname "$config")"
  cat >"$config" <<EOF
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
