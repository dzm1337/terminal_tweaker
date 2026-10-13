#!/usr/bin/env bash
# ============================================================
# install.sh — terminal_tweaker entrypoint
# https://github.com/dzm1337/terminal_tweaker
# ============================================================
# Layout:
#   install.sh        flags, step selection, orchestration (this file)
#   lib/core.sh       logging, spinner, prompts, backups, downloads
#   lib/platform.sh   OS / arch / distro / package-manager detection
#   lib/pkg.sh        package-manager abstraction
#   modules/*.sh      one file per tool, each exposing step_<name>
# ============================================================

set -uo pipefail

REPO_URL="https://github.com/dzm1337/terminal_tweaker"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"

# ── Bootstrap: support `curl -fsSL …/install.sh | bash` ───────
# Piped in, there are no lib/ or modules/ next to us, so fetch the repo.
if [[ ! -f "$ROOT_DIR/lib/core.sh" ]]; then
  tmp=$(mktemp -d "${TMPDIR:-/tmp}/terminal_tweaker.XXXXXX")
  echo "→ Downloading terminal_tweaker into $tmp ..."
  curl -fsSL "$REPO_URL/archive/refs/heads/main.tar.gz" | tar -xz -C "$tmp" --strip-components=1 || {
    echo "✘ Download failed" >&2
    exit 1
  }
  exec bash "$tmp/install.sh" "$@"
fi

# shellcheck source=lib/core.sh
. "$ROOT_DIR/lib/core.sh"
# shellcheck source=lib/platform.sh
. "$ROOT_DIR/lib/platform.sh"
# shellcheck source=lib/pkg.sh
. "$ROOT_DIR/lib/pkg.sh"
for module in "$ROOT_DIR"/modules/*.sh; do
  # shellcheck source=/dev/null
  . "$module"
done

# Order matters: packages provides curl/git/unzip for everything after it.
ALL_STEPS="packages font ghostty starship eza neovim shell"
ONLY_STEPS=""
SKIP_STEPS=""

show_help() {
  cat <<EOF
Usage: ./install.sh [OPTIONS]

Options:
  -n, --dry-run        Preview every change without applying it
  -y, --yes, --force   Non-interactive; accept all defaults
  -v, --verbose        Stream command output instead of a spinner
      --only a,b       Run only these steps
      --skip a,b       Skip these steps
  -h, --help           Show this help

Steps (in order): ${ALL_STEPS}

Environment: DRY_RUN=true  ASSUME_YES=true  VERBOSE=true  LOG_FILE=path

Examples:
  ./install.sh
  ./install.sh --dry-run
  ./install.sh --yes --skip ghostty,font      # headless server / container
  ./install.sh --only neovim
  curl -fsSL https://raw.githubusercontent.com/dzm1337/terminal_tweaker/main/install.sh | bash
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      show_help
      exit 0
      ;;
    -n | --dry-run) DRY_RUN=true ;;
    -y | --yes | -f | --force) ASSUME_YES=true ;;
    -v | --verbose) VERBOSE=true ;;
    --only | --skip)
      [[ $# -ge 2 ]] || {
        log_error "$1 needs a comma-separated list of steps"
        exit 1
      }
      _validate_steps "$2"
      if [[ "$1" == "--only" ]]; then ONLY_STEPS="${2//,/ }"; else SKIP_STEPS="${2//,/ }"; fi
      shift
      ;;
    *)
      log_error "Unknown option: $1"
      show_help
      exit 1
      ;;
    esac
    shift
  done
}

_validate_steps() {
  local step
  for step in ${1//,/ }; do
    case " $ALL_STEPS " in
    *" $step "*) ;;
    *)
      log_error "Unknown step '$step' (valid: $ALL_STEPS)"
      exit 1
      ;;
    esac
  done
}

_in_list() { case " $2 " in *" $1 "*) return 0 ;; esac; return 1; }

step_enabled() {
  [[ -n "$ONLY_STEPS" ]] && ! _in_list "$1" "$ONLY_STEPS" && return 1
  _in_list "$1" "$SKIP_STEPS" && return 1
  return 0
}

main() {
  parse_args "$@"
  detect_platform

  printf '══════════════════════════════════════════\n'
  printf '  terminal_tweaker\n'
  printf '  Ghostty · Starship · eza · Neovim\n'
  is_dry_run && printf '  *** DRY-RUN — no changes will be made ***\n'
  printf '══════════════════════════════════════════\n'

  if [[ "$OS" == "unknown" ]]; then
    log_error "Unsupported OS: $(uname -s)"
    exit 1
  fi
  log_info "Platform: $(platform_summary)"
  log_info "Log file: $LOG_FILE"
  : >"$LOG_FILE" 2>/dev/null || LOG_FILE=/dev/null

  # Binaries we drop in ~/.local/bin must be found by later steps.
  export PATH="$LOCAL_BIN:$PATH"

  if [[ "$OS" == "linux" ]] && { step_enabled packages || step_enabled ghostty; }; then
    prime_sudo || {
      log_error "Could not obtain administrator rights"
      exit 1
    }
  fi

  local step ok="" failed=""
  for step in $ALL_STEPS; do
    step_enabled "$step" || continue
    if "step_$step"; then
      ok="$ok $step"
    else
      failed="$failed $step"
      # Without base packages nothing else can work.
      if [[ "$step" == "packages" ]]; then
        log_error "Base package install failed; stopping."
        break
      fi
    fi
  done

  log_section "Summary"
  [[ -n "$ok" ]] && log_success "Done:${ok}"
  [[ -n "$failed" ]] && log_error "Failed:${failed} (details in $LOG_FILE)"
  [[ -d "$BACKUP_DIR" ]] && log_info "Backups: $BACKUP_DIR"

  printf '\nNext steps:\n'
  printf '  1. Restart your terminal (or run: exec %s)\n' "${SHELL:-zsh}"
  printf '  2. Open nvim — LazyVim installs its plugins on first launch\n'
  printf '  3. Tweak: ~/.config/ghostty/config, ~/.config/starship.toml\n\n'

  [[ -z "$failed" ]]
}

main "$@"
