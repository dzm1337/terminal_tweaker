# shellcheck shell=bash
# ============================================================
# modules/eza.sh — eza (modern ls)
# ============================================================
# Native package first (Homebrew, Arch, Fedora, Ubuntu 24.04+, Debian 13+,
# Alpine, Void, Tumbleweed…); otherwise the upstream prebuilt binary into
# ~/.local/bin, which covers older/LTS distros with no extra apt repos.

step_eza() {
  log_section "eza"

  if check_command eza; then
    log_success "eza already installed ($(eza --version 2>/dev/null | sed -n 2p))"
    return 0
  fi

  SOFT_FAIL=true pkg_install eza && check_command eza && return 0
  is_dry_run && return 0
  [[ "$OS" == "linux" ]] && _install_eza_binary && return 0

  log_warn "Could not install eza — the ls aliases will stay inactive until it is."
  log_warn "See https://github.com/eza-community/eza/blob/main/INSTALL.md"
  return 0
}

_install_eza_binary() {
  local asset
  case "$ARCH:$LIBC" in
  x86_64:*) asset="eza_x86_64-unknown-linux-musl.tar.gz" ;; # static, any libc
  arm64:glibc) asset="eza_aarch64-unknown-linux-gnu.tar.gz" ;;
  armv7:glibc) asset="eza_arm-unknown-linux-gnueabihf.tar.gz" ;;
  *)
    log_warn "No prebuilt eza binary for $ARCH/$LIBC"
    return 1
    ;;
  esac

  make_tmpdir
  run_spin "Downloading eza binary → $LOCAL_BIN" \
    download "https://github.com/eza-community/eza/releases/latest/download/$asset" "$TMP_DIR/eza.tar.gz" ||
    return 1

  mkdir -p "$LOCAL_BIN"
  tar -xzf "$TMP_DIR/eza.tar.gz" -C "$TMP_DIR" &&
    install -m 755 "$TMP_DIR/eza" "$LOCAL_BIN/eza" &&
    log_success "eza installed ($("$LOCAL_BIN/eza" --version | sed -n 2p))"
}
