# shellcheck shell=bash
# ============================================================
# modules/packages.sh — base packages every other step relies on
# ============================================================
# Only packages whose command is missing are requested. Asking for ones
# that are already there can fail (RHEL 9 ships curl-minimal, which
# conflicts with the curl package) and forces needless index refreshes.

# "command:generic-package" pairs
BASE_PACKAGES="curl:curl git:git unzip:unzip tar:tar zsh:zsh fc-cache:fontconfig"

_missing_base_packages() {
  local pair
  for pair in $BASE_PACKAGES; do
    check_command "${pair%%:*}" || printf '%s ' "${pair##*:}"
  done
  # Fresh minimal images without curl usually lack CA certs too.
  check_command curl || printf 'ca-certificates '
  if ! { check_command cc || check_command gcc; } || ! check_command make; then
    printf 'build-tools '
  fi
}

step_packages() {
  log_section "Base packages"

  if [[ "$OS" == "macos" && "$PKG_MGR" != "brew" ]]; then
    log_error "Homebrew not found. Install it from https://brew.sh and re-run."
    return 1
  fi

  local missing
  missing=$(_missing_base_packages)
  # Only real packages count; e.g. fontconfig maps to nothing on macOS.
  local pkg needed=""
  for pkg in $missing; do
    [[ -n "$(pkg_name "$pkg")" ]] && needed="$needed $pkg"
  done

  if [[ -z "$needed" ]]; then
    log_success "Base packages already present"
    return 0
  fi
  if [[ "$PKG_MGR" == "none" ]]; then
    log_warn "No supported package manager found for '$DISTRO_ID'."
    log_warn "Please install:$needed"
    return 0
  fi

  pkg_update || log_warn "Package index update failed (continuing)"
  # shellcheck disable=SC2086 # intentional word splitting
  pkg_install $needed
}
