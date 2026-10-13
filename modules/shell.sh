# shellcheck shell=bash
# ============================================================
# modules/shell.sh — wire Starship, eza aliases and PATH into the shell
# ============================================================
# Everything lives in one marked block that is rewritten on each run,
# so re-running never duplicates lines and edits are easy to undo.

TT_BLOCK_BEGIN="# >>> terminal_tweaker >>>"
TT_BLOCK_END="# <<< terminal_tweaker <<<"

step_shell() {
  log_section "Shell"

  local default=1
  [[ "$(basename "${SHELL:-}")" == "bash" ]] && default=2
  choose "Which shell should be configured?" "$default" "Zsh" "Bash"

  local shell_type rc_file
  if [[ "$CHOICE" == "2" ]]; then
    shell_type=bash rc_file="$HOME/.bashrc"
  else
    shell_type=zsh rc_file="$HOME/.zshrc"
  fi

  if is_dry_run; then
    log_info "[dry-run] Would write the terminal_tweaker block into $rc_file"
  else
    _write_shell_block "$shell_type" "$rc_file" || return 1
    log_success "Updated $rc_file"
  fi

  _offer_default_shell "$shell_type"
  printf '%s→%s Reload with: %sexec %s%s\n' "$BLUE" "$NC" "$GREEN" "$shell_type" "$NC"
}

_shell_block() {
  cat <<EOF
$TT_BLOCK_BEGIN
# Managed by terminal_tweaker — re-running the installer rewrites this block.
case ":\$PATH:" in
  *":\$HOME/.local/bin:"*) ;;
  *) export PATH="\$HOME/.local/bin:\$PATH" ;;
esac

if command -v starship >/dev/null 2>&1; then
  eval "\$(starship init $1)"
fi

if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -lh --icons --group-directories-first --git'
  alias lt='eza --tree --level=2 --icons --git'
  alias la='eza -lah --icons --group-directories-first --git'
fi
$TT_BLOCK_END
EOF
}

_write_shell_block() {
  local shell_type="$1" rc_file="$2"
  [[ -f "$rc_file" ]] || touch "$rc_file"
  backup_config "$rc_file" || return 1

  make_tmpdir
  # Drop the current block plus the legacy blocks older versions appended
  # ("# ── … (added by terminal_tweaker) ──" followed by an if…fi).
  awk -v begin="$TT_BLOCK_BEGIN" -v end="$TT_BLOCK_END" '
    $0 == begin { skip = 1; next }
    $0 == end   { skip = 0; next }
    /\(added by terminal_tweaker\) ──$/ { legacy = 1; next }
    legacy && /^fi$/ { legacy = 0; next }
    skip || legacy { next }
    # Hold blank lines back so trailing ones are dropped.
    /^[[:space:]]*$/ { blanks = blanks $0 "\n"; next }
    { printf "%s", blanks; blanks = ""; print }
  ' "$rc_file" >"$TMP_DIR/rc"

  {
    cat "$TMP_DIR/rc"
    [[ -s "$TMP_DIR/rc" ]] && printf '\n'
    _shell_block "$shell_type"
  } >"$TMP_DIR/rc.new"

  # cat > keeps symlinks (e.g. dotfile managers) and permissions intact.
  cat "$TMP_DIR/rc.new" >"$rc_file"
}

_offer_default_shell() {
  local shell_type="$1" shell_path
  [[ "$(basename "${SHELL:-}")" == "$shell_type" ]] && return 0
  shell_path=$(command -v "$shell_type") || return 0

  if ! check_command chsh; then
    log_warn "$shell_type is not your login shell and chsh is unavailable; change it manually"
    return 0
  fi
  if ask_yes_no "Make $shell_type your default shell?" "y"; then
    run_cmd chsh -s "$shell_path" ||
      log_warn "chsh failed — is $shell_path listed in /etc/shells?"
  fi
}
