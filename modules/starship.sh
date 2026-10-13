# shellcheck shell=bash
# ============================================================
# modules/starship.sh — install + configure Starship
# ============================================================

# "Label|preset-slug" — empty slug means the built-in minimal config
STARSHIP_PRESETS=(
  "Nerd Font Symbols|nerd-font-symbols"
  "No Nerd Fonts|no-nerd-font"
  "Bracketed Segments|bracketed-segments"
  "Plain Text|plain-text-symbols"
  "No Runtime Versions|no-runtime-versions"
  "No Empty Icons|no-empty-icons"
  "Pure Prompt|pure-preset"
  "Pastel Powerline|pastel-powerline"
  "Tokyo Night|tokyo-night"
  "Gruvbox Rainbow|gruvbox-rainbow"
  "Jetpack|jetpack"
  "Catppuccin Powerline|catppuccin-powerline"
  "Default (minimal)|"
)

step_starship() {
  log_section "Starship"

  if check_command starship; then
    log_success "Starship already installed ($(starship --version 2>/dev/null | head -n1))"
  elif [[ "$OS" == "macos" ]]; then
    pkg_install starship || return 1
  else
    # Official script ships a static musl binary → works on every distro.
    # Installing into ~/.local/bin avoids needing root.
    make_tmpdir
    mkdir -p "$LOCAL_BIN"
    run_spin "Installing Starship → $LOCAL_BIN" _starship_script_install ||
      pkg_install starship || return 1
  fi

  configure_starship
}

_starship_script_install() {
  download https://starship.rs/install.sh "$TMP_DIR/starship.sh" &&
    sh "$TMP_DIR/starship.sh" --yes --bin-dir "$LOCAL_BIN"
}

configure_starship() {
  local config="$HOME/.config/starship.toml"

  if ! check_command starship && ! is_dry_run; then
    log_warn "Starship not found; skipping its config"
    return 0
  fi
  if [[ -e "$config" ]] && ! ask_yes_no "Existing $config found. Replace it?" "y"; then
    log_info "Keeping existing Starship config"
    return 0
  fi

  local labels=() entry
  for entry in "${STARSHIP_PRESETS[@]}"; do labels+=("${entry%%|*}"); done
  choose "Choose a Starship preset (previews: https://starship.rs/presets/):" 1 "${labels[@]}"
  local slug="${STARSHIP_PRESETS[$((CHOICE - 1))]##*|}"

  backup_config "$config"
  if is_dry_run; then
    log_info "[dry-run] Would write $config (preset: ${slug:-minimal})"
    return 0
  fi
  mkdir -p "$(dirname "$config")"

  if [[ -n "$slug" ]] && starship preset "$slug" -o "$config"; then
    log_success "Starship preset applied: $slug"
    return 0
  fi
  [[ -n "$slug" ]] && log_warn "Failed to apply preset '$slug'; writing minimal config"

  cat >"$config" <<'EOF'
format = "$directory$git_branch$git_status$python$nodejs$rust$go$cmd_duration$line_break$character"

[directory]
truncation_length = 3

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[✘](bold red)"
EOF
  log_success "Minimal Starship config written"
}
