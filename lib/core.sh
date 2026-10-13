# shellcheck shell=bash
# ============================================================
# lib/core.sh — logging, spinner, prompts, backups, downloads
# ============================================================
# Must stay bash 3.2 compatible (macOS /bin/bash): no associative
# arrays, no ${var,,}, no mapfile.

# ── Runtime config (overridable via env) ─────────────────────
DRY_RUN="${DRY_RUN:-false}"
ASSUME_YES="${ASSUME_YES:-${FORCE_INSTALL:-false}}"
VERBOSE="${VERBOSE:-false}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/.config_backups/$(date +%Y%m%d_%H%M%S)}"
LOG_FILE="${LOG_FILE:-${TMPDIR:-/tmp}/terminal_tweaker.log}"
# shellcheck disable=SC2034 # used by modules
LOCAL_BIN="$HOME/.local/bin"

# ── Colours (disabled when not writing to a terminal) ────────
if [[ -t 1 ]]; then
  RED=$'\033[0;31m' GREEN=$'\033[0;32m' YELLOW=$'\033[1;33m'
  BLUE=$'\033[0;34m' CYAN=$'\033[0;36m' NC=$'\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' CYAN='' NC=''
fi

# ── Tmpdir registry ──────────────────────────────────────────
_TMPDIRS=()

_cleanup() {
  local dir
  for dir in "${_TMPDIRS[@]+"${_TMPDIRS[@]}"}"; do
    [[ -d "$dir" ]] && rm -rf "$dir"
  done
  [[ -n "${_SUDO_KEEPALIVE_PID:-}" ]] && kill "$_SUDO_KEEPALIVE_PID" 2>/dev/null
  return 0
}
trap _cleanup EXIT

# make_tmpdir — sets TMP_DIR (a subshell would lose the registry entry)
make_tmpdir() {
  TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/terminal_tweaker.XXXXXX")
  _TMPDIRS+=("$TMP_DIR")
}

# ============================================================
# LOGGING
# ============================================================

log_info() { printf '%s→%s %s\n' "$BLUE" "$NC" "$1"; }
log_success() { printf '%s✓%s %s\n' "$GREEN" "$NC" "$1"; }
log_warn() { printf '%s⚠%s %s\n' "$YELLOW" "$NC" "$1"; }
log_error() { printf '%s✘%s %s\n' "$RED" "$NC" "$1" >&2; }
log_verbose() {
  if [[ "$VERBOSE" == "true" ]]; then printf '%s·%s %s\n' "$CYAN" "$NC" "$1"; fi
}

log_section() {
  printf '\n══════════════════════════════════════════\n'
  printf '  %s\n' "$1"
  printf '══════════════════════════════════════════\n'
}

is_dry_run() { [[ "$DRY_RUN" == "true" ]]; }

# ============================================================
# COMMAND EXECUTION
# ============================================================

check_command() { command -v "$1" >/dev/null 2>&1; }

# run_cmd <cmd> [args...] — run in the foreground (output visible)
run_cmd() {
  if is_dry_run; then
    log_info "[dry-run] $*"
    return 0
  fi
  log_verbose "Running: $*"
  "$@"
}

_spin() {
  local pid="$1" i=0
  local frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  while kill -0 "$pid" 2>/dev/null; do
    printf '\r  %s%s%s ' "$CYAN" "${frames:$((i % 10)):1}" "$NC"
    i=$((i + 1))
    sleep 0.1
  done
  printf '\r   \r'
}

# run_spin <label> <cmd> [args...]
# Runs quietly with a spinner; output goes to $LOG_FILE and the tail is
# shown on failure, so errors are never swallowed. Set SOFT_FAIL=true for
# attempts that have a fallback: failure is then a one-line note.
run_spin() {
  local label="$1" rc
  shift
  if is_dry_run; then
    log_info "[dry-run] $label: $*"
    return 0
  fi
  printf '\n### %s\n$ %s\n' "$label" "$*" >>"$LOG_FILE"

  if [[ -t 1 && "$VERBOSE" != "true" ]]; then
    printf '  %s…%s  %s' "$CYAN" "$NC" "$label"
    "$@" </dev/null >>"$LOG_FILE" 2>&1 &
    local pid=$!
    _spin "$pid"
    wait "$pid"
    rc=$?
    printf '\r\033[K'
  else
    log_verbose "Running: $*"
    "$@" </dev/null >>"$LOG_FILE" 2>&1
    rc=$?
  fi

  if ((rc == 0)); then
    log_success "$label"
  elif [[ "${SOFT_FAIL:-false}" == "true" ]]; then
    printf '%s·%s %s — not available, trying next option\n' "$CYAN" "$NC" "$label"
  else
    log_error "$label (exit $rc) — last lines of $LOG_FILE:"
    tail -n 15 "$LOG_FILE" | sed 's/^/    /' >&2
  fi
  return "$rc"
}

# as_root <cmd> [args...] — run with root privileges via sudo/doas
as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  elif check_command sudo; then
    sudo "$@"
  elif check_command doas; then
    doas "$@"
  else
    log_error "Need root for '$1' but neither sudo nor doas is available"
    return 1
  fi
}

# Ask for the sudo password once up front, then keep the ticket fresh so
# spinner-wrapped commands never block on a hidden password prompt.
prime_sudo() {
  is_dry_run && return 0
  [[ "$(id -u)" -eq 0 ]] && return 0
  check_command sudo || return 0
  log_info "Some steps need administrator rights."
  sudo -v || return 1
  (while kill -0 "$$" 2>/dev/null; do
    sudo -n true 2>/dev/null
    sleep 50
  done) &
  _SUDO_KEEPALIVE_PID=$!
}

# ============================================================
# PROMPTS
# ============================================================

# Prompts read from /dev/tty so they still work under `curl | bash`.
_read_answer() {
  ANSWER=""
  if [[ "$ASSUME_YES" == "true" ]] || ! { : </dev/tty; } 2>/dev/null; then
    return 1
  fi
  read -r ANSWER </dev/tty
}

# ask_yes_no <prompt> [default y|n]
ask_yes_no() {
  local prompt="$1" default="${2:-y}"
  printf '%s→%s %s (y/n) [%s]: ' "$BLUE" "$NC" "$prompt" "$default"
  if ! _read_answer; then
    printf '%s\n' "$default"
    ANSWER="$default"
  fi
  [[ "${ANSWER:-$default}" =~ ^[Yy] ]]
}

# choose <prompt> <default-index> <option>... — sets CHOICE (1-based)
choose() {
  local prompt="$1" default="$2" i=1 opt
  shift 2
  printf '%s→%s %s\n' "$BLUE" "$NC" "$prompt"
  for opt in "$@"; do
    printf '  %2d. %s\n' "$i" "$opt"
    i=$((i + 1))
  done
  printf 'Choice [%s]: ' "$default"
  if ! _read_answer; then
    printf '%s\n' "$default"
  fi
  # shellcheck disable=SC2034 # CHOICE is the return value
  if [[ "$ANSWER" =~ ^[0-9]+$ ]] && ((ANSWER >= 1 && ANSWER <= $#)); then
    CHOICE="$ANSWER"
  else
    CHOICE="$default"
  fi
}

# ============================================================
# FILES & DOWNLOADS
# ============================================================

backup_config() {
  local path="$1"
  [[ -e "$path" ]] || return 0
  if is_dry_run; then
    log_info "[dry-run] Would back up $path → $BACKUP_DIR/"
    return 0
  fi
  if ! { mkdir -p "$BACKUP_DIR" && cp -R "$path" "$BACKUP_DIR/$(basename "$path")"; }; then
    log_error "Backup of $path failed — not touching it"
    return 1
  fi
  log_success "Backup: $BACKUP_DIR/$(basename "$path")"
}

# download <url> <dest>
download() {
  if check_command curl; then
    curl -fsSL --retry 3 -o "$2" "$1"
  elif check_command wget; then
    wget -q -O "$2" "$1"
  else
    log_error "Neither curl nor wget is available"
    return 1
  fi
}

# version_ge <a> <b> — true if dotted version a >= b
version_ge() {
  local IFS=.
  # shellcheck disable=SC2206
  local a=($1) b=($2) i
  for i in 0 1 2; do
    if ((${a[i]:-0} > ${b[i]:-0})); then return 0; fi
    if ((${a[i]:-0} < ${b[i]:-0})); then return 1; fi
  done
  return 0
}
