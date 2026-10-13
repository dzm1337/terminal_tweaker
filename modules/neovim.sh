# shellcheck shell=bash
# ============================================================
# modules/neovim.sh — Neovim + LazyVim starter
# ============================================================
# LazyVim needs a recent Neovim, which Debian/Ubuntu/RHEL repos don't ship
# (Ubuntu 24.04 has 0.9.5). On glibc Linux we therefore use the official
# release tarball, installed into ~/.local so no root is needed and the
# distro's own nvim is left untouched.

NVIM_MIN_VERSION="0.11.2"

nvim_version() {
  check_command nvim || return 1
  nvim --version 2>/dev/null | head -n1 | sed -e 's/^NVIM v//' -e 's/[^0-9.].*//'
}

step_neovim() {
  log_section "Neovim"

  local current
  current=$(nvim_version)
  if [[ -n "$current" ]] && version_ge "$current" "$NVIM_MIN_VERSION"; then
    log_success "Neovim $current already installed"
  else
    [[ -n "$current" ]] &&
      log_warn "Neovim $current is older than $NVIM_MIN_VERSION (required by LazyVim); upgrading"
    _install_neovim || return 1
  fi

  configure_lazyvim
}

_install_neovim() {
  if [[ "$OS" == "macos" ]]; then
    if brew list neovim >/dev/null 2>&1; then
      run_spin "Upgrading Neovim" brew upgrade neovim
    else
      pkg_install neovim
    fi
    return
  fi

  if [[ "$LIBC" == "glibc" && ("$ARCH" == "x86_64" || "$ARCH" == "arm64") ]]; then
    _install_neovim_tarball && return 0
    log_warn "Tarball install failed; falling back to the distro package"
  fi
  pkg_install neovim || return 1

  local installed
  installed=$(nvim_version)
  if [[ -n "$installed" ]] && ! version_ge "$installed" "$NVIM_MIN_VERSION"; then
    log_warn "Distro Neovim is $installed; LazyVim needs >= $NVIM_MIN_VERSION"
  fi
}

_install_neovim_tarball() {
  local name="nvim-linux-$ARCH"
  local url="https://github.com/neovim/neovim/releases/download/stable/$name.tar.gz"
  local opt_dir="$HOME/.local/opt"

  make_tmpdir
  run_spin "Downloading Neovim (stable, $ARCH)" download "$url" "$TMP_DIR/nvim.tar.gz" || return 1
  is_dry_run && return 0

  mkdir -p "$opt_dir" "$LOCAL_BIN"
  rm -rf "${opt_dir:?}/$name"
  tar -xzf "$TMP_DIR/nvim.tar.gz" -C "$opt_dir" || return 1
  ln -sf "$opt_dir/$name/bin/nvim" "$LOCAL_BIN/nvim"
  hash -r
  log_success "Neovim $(nvim_version) installed → $opt_dir/$name"
}

configure_lazyvim() {
  local nvim_dir="$HOME/.config/nvim"

  if [[ -f "$nvim_dir/lua/config/lazy.lua" ]] && grep -q LazyVim "$nvim_dir/lua/config/lazy.lua" 2>/dev/null; then
    log_success "LazyVim already set up in $nvim_dir"
    return 0
  fi

  if [[ -d "$nvim_dir" ]]; then
    log_warn "Existing Neovim config found at $nvim_dir"
    if ! ask_yes_no "Back it up and replace it with LazyVim?" "y"; then
      log_info "Keeping existing Neovim config"
      return 0
    fi
  elif ! ask_yes_no "Install the LazyVim starter config?" "y"; then
    log_info "Skipping LazyVim"
    return 0
  fi

  if ! check_command git && ! is_dry_run; then
    log_error "git is required to install LazyVim"
    return 1
  fi

  backup_config "$nvim_dir" || return 1
  is_dry_run || rm -rf "$nvim_dir"
  run_spin "Cloning LazyVim starter" git clone --depth 1 https://github.com/LazyVim/starter "$nvim_dir" ||
    return 1
  is_dry_run || rm -rf "$nvim_dir/.git"
  log_info "Open nvim — plugins install automatically on first launch"
}
