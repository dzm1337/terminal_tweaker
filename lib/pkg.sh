# shellcheck shell=bash
# ============================================================
# lib/pkg.sh — package-manager abstraction
# ============================================================
# Modules ask for *generic* package names; pkg_name maps them to the
# native name for $PKG_MGR. Adding a new distro family means adding a
# case to pkg_update / _pkg_install_native and, if names differ, pkg_name.

# pkg_name <generic> — prints native package name(s), or nothing to skip
pkg_name() {
  case "$PKG_MGR:$1" in
  # Build tools (needed by nvim-treesitter to compile parsers)
  apt:build-tools) printf 'build-essential' ;;
  dnf:build-tools | yum:build-tools | zypper:build-tools) printf 'gcc gcc-c++ make' ;;
  pacman:build-tools | xbps:build-tools) printf 'base-devel' ;;
  apk:build-tools) printf 'build-base' ;;
  brew:build-tools) ;; # Xcode Command Line Tools

  # Things macOS already ships
  brew:curl | brew:unzip | brew:tar | brew:zsh | brew:fontconfig | brew:ca-certificates) ;;

  *) printf '%s' "$1" ;;
  esac
}

pkg_update() {
  case "$PKG_MGR" in
  brew) run_spin "Updating Homebrew" brew update --quiet ;;
  apt) run_spin "Updating apt index" as_root apt-get update -qq ;;
  dnf | yum) run_spin "Refreshing $PKG_MGR metadata" as_root "$PKG_MGR" makecache -q ;;
  # Arch does not support partial upgrades: -Sy without -u can break the system.
  pacman) run_spin "Upgrading system (pacman -Syu)" as_root pacman -Syu --noconfirm ;;
  zypper) run_spin "Refreshing zypper" as_root zypper --non-interactive refresh ;;
  apk) run_spin "Updating apk index" as_root apk update ;;
  xbps) run_spin "Syncing xbps" as_root xbps-install -Sy xbps ;;
  *) return 0 ;;
  esac
}

_pkg_install_native() {
  case "$PKG_MGR" in
  brew) brew install "$@" ;;
  apt) as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" ;;
  dnf | yum) as_root "$PKG_MGR" install -y "$@" ;;
  pacman) as_root pacman -S --needed --noconfirm "$@" ;;
  zypper) as_root zypper --non-interactive install "$@" ;;
  apk) as_root apk add "$@" ;;
  xbps) as_root xbps-install -y "$@" ;;
  *) return 1 ;;
  esac
}

# pkg_install <generic-name>... — install via the native package manager
pkg_install() {
  local pkg native pkgs=()
  for pkg in "$@"; do
    native=$(pkg_name "$pkg")
    # shellcheck disable=SC2206 # intentional split: one generic → many native
    [[ -n "$native" ]] && pkgs+=($native)
  done
  ((${#pkgs[@]} == 0)) && return 0

  if [[ "$PKG_MGR" == "none" ]]; then
    log_warn "No supported package manager; please install manually: ${pkgs[*]}"
    return 1
  fi
  run_spin "Installing ${pkgs[*]}" _pkg_install_native "${pkgs[@]}"
}
