# shellcheck shell=bash
# ============================================================
# modules/font.sh — JetBrainsMono Nerd Font
# ============================================================

NERD_FONT_VERSION="${NERD_FONT_VERSION:-3.4.0}"

step_font() {
  log_section "JetBrainsMono Nerd Font"

  if [[ "$IS_WSL" == "true" ]]; then
    log_warn "WSL detected — fonts are rendered by Windows. Install the font there:"
    printf '  https://github.com/ryanoasis/nerd-fonts/releases/download/v%s/JetBrainsMono.zip\n' "$NERD_FONT_VERSION"
    return 0
  fi

  if [[ "$OS" == "macos" ]]; then
    if compgen -G "$HOME/Library/Fonts/JetBrainsMonoNerdFont*" >/dev/null ||
      compgen -G "/Library/Fonts/JetBrainsMonoNerdFont*" >/dev/null; then
      log_success "JetBrainsMono Nerd Font already installed"
      return 0
    fi
    run_spin "Installing JetBrainsMono Nerd Font" brew install --cask font-jetbrains-mono-nerd-font
    return
  fi

  _install_font_linux
}

_install_font_linux() {
  local font_dir="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
  local url="https://github.com/ryanoasis/nerd-fonts/releases/download/v${NERD_FONT_VERSION}/JetBrainsMono.zip"

  if [[ -f "$font_dir/JetBrainsMonoNerdFont-Regular.ttf" ]] ||
    fc-list 2>/dev/null | grep -qi 'JetBrainsMono Nerd Font'; then
    log_success "JetBrainsMono Nerd Font already installed"
    return 0
  fi
  if ! check_command unzip; then
    log_warn "unzip not found; skipping font install"
    return 1
  fi

  make_tmpdir
  run_spin "Downloading JetBrainsMono Nerd Font v$NERD_FONT_VERSION" \
    download "$url" "$TMP_DIR/font.zip" || return 1
  is_dry_run && return 0

  mkdir -p "$font_dir"
  unzip -oq "$TMP_DIR/font.zip" '*.ttf' -d "$font_dir" || {
    log_error "Failed to extract font archive"
    return 1
  }
  check_command fc-cache && fc-cache -f "$font_dir" >/dev/null 2>&1
  log_success "JetBrainsMono Nerd Font installed → $font_dir"
}
