#!/bin/bash
# ================================================
# Ghostty + Neovim + Starship + eza Setup
# ================================================

set -euo pipefail

clear

echo "=================================================="
echo "   Ghostty + Neovim + Starship + eza Setup"
echo "=================================================="
echo

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
  if [[ "$(uname -m)" == "arm64" ]]; then
    ARCH="arm64"
    BREW_PREFIX="/opt/homebrew"
  else
    ARCH="x86_64"
    BREW_PREFIX="/usr/local"
  fi
else
  OS="linux"
fi

echo "→ System detected: $OS ($ARCH)"
echo

# Install Dependencies
echo "→ Installing packages..."

if [[ "$OS" == "macos" ]]; then
  if ! command -v brew &>/dev/null; then
    echo "❌ Homebrew not found. Install from https://brew.sh"
    exit 1
  fi

  eval "$("$BREW_PREFIX"/bin/brew shellenv)"
  brew update --quiet

  echo "→ Installing Starship (official binary)..."
  curl -sS https://starship.rs/install.sh | sh -s -- --yes

  echo "→ Installing Nerd Font..."
  brew install --cask font-jetbrains-mono-nerd-font

  echo "→ Installing eza..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --quiet 2>/dev/null || true
  source "$HOME/.cargo/env" 2>/dev/null || true
  if command -v cargo &>/dev/null; then
    cargo install eza --quiet || brew install eza
  else
    brew install eza
  fi

  echo "→ Installing Neovim..."
  cd /tmp
  if [[ "$ARCH" == "arm64" ]]; then
    curl -L -o nvim.tar.gz https://github.com/neovim/neovim/releases/download/stable/nvim-macos-arm64.tar.gz
  else
    curl -L -o nvim.tar.gz https://github.com/neovim/neovim/releases/download/stable/nvim-macos-x86_64.tar.gz
  fi
  tar xzf nvim.tar.gz
  sudo rm -rf /usr/local/bin/nvim /usr/local/share/nvim 2>/dev/null || true
  sudo mv nvim-macos-*/bin/nvim /usr/local/bin/nvim 2>/dev/null || true
  sudo mv nvim-macos-*/share/nvim /usr/local/share/nvim 2>/dev/null || true
  rm -rf nvim-macos-* nvim.tar.gz

else
  # Ubuntu/Debian
  sudo apt update
  sudo apt install -y neovim curl git zsh fonts-powerline

  curl -sS https://starship.rs/install.sh | sh -s -- --yes

  echo "→ Installing eza..."
  sudo mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/eza.gpg 2>/dev/null || true
  echo "deb [signed-by=/etc/apt/keyrings/eza.gpg] http://deb.gierens.de stable main" |
    sudo tee /etc/apt/sources.list.d/eza.list >/dev/null
  sudo apt update
  sudo apt install -y eza
fi

# Nerd Font
echo "→ Installing JetBrainsMono Nerd Font..."
if [[ "$OS" == "macos" ]]; then
  echo "   → Already installed via Homebrew"
else
  mkdir -p ~/.local/share/fonts
  cd /tmp
  wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip
  unzip -q JetBrainsMono.zip -d ~/.local/share/fonts/
  fc-cache -fv
  rm -f JetBrainsMono.zip
fi

# Choose Shell
echo
echo "=========================================="
echo "      CHOOSE YOUR SHELL"
echo "=========================================="
echo "1. Zsh"
echo "2. Bash"
echo
read -p "Choose (1-2) [default: 1]: " shell_choice

if [[ "${shell_choice:-1}" == "2" ]]; then
  SHELL_TYPE="bash"
  RC_FILE="$HOME/.bashrc"
else
  SHELL_TYPE="zsh"
  RC_FILE="$HOME/.zshrc"
fi

echo "→ Using: $SHELL_TYPE"

# Ghostty Theme
echo
echo "=========================================="
echo "      GHOSTTY THEMES"
echo "=========================================="
echo "1. Tokyo Night     2. Catppuccin Mocha"
echo "3. Catppuccin Frappe 4. Dracula"
echo "5. Gruvbox Dark    6. Nord"
echo "7. One Dark        8. Rose Pine"
echo "9. Kanagawa Dragon 10. Everforest"
echo
read -p "Choose theme (1-10) [default: 1]: " theme_choice

case "${theme_choice:-1}" in
1) theme="TokyoNight" ;;
2) theme="Catppuccin Mocha" ;;
3) theme="Catppuccin Frappe" ;;
4) theme="Dracula" ;;
5) theme="Gruvbox Dark" ;;
6) theme="Nord" ;;
7) theme="One Dark Two" ;;
8) theme="Rose Pine" ;;
9) theme="Kanagawa Dragon" ;;
10) theme="Everforest Dark Hard" ;;
*) theme="TokyoNight" ;;
esac

echo "→ Selected theme: $theme"

# Starship Setup
echo
read -p "Install Starship? (y/n) [default: y]: " install_starship
install_starship=${install_starship:-y}

if [[ "$install_starship" =~ ^[Yy]$ ]]; then
  echo
  read -p "Do you want to install a custom preset for starship? (y/n) [default: y]: " apply_preset
  apply_preset=${apply_preset:-y}

  if [[ "$apply_preset" =~ ^[Yy]$ ]]; then
    echo
    echo "1. Nerd Font Symbols   2. No Nerd Fonts"
    echo "3. Bracketed Segments  4. Plain Text"
    echo "5. No Runtime Versions 6. No Empty Icons"
    echo "7. Pure Prompt         8. Pastel Powerline"
    echo "9. Tokyo Night         10. Gruvbox Rainbow"
    echo "11. Jetpack            12. Catppuccin Powerline"
    echo "13. Default"
    echo
    read -p "Choose preset (1-13) [default: 1]: " preset_choice

    case "${preset_choice:-1}" in
    1) preset_slug="nerd-font-symbols" ;;
    2) preset_slug="no-nerd-font" ;;
    3) preset_slug="bracketed-segments" ;;
    4) preset_slug="plain-text-symbols" ;;
    5) preset_slug="no-runtime-versions" ;;
    6) preset_slug="no-empty-icons" ;;
    7) preset_slug="pure-preset" ;;
    8) preset_slug="pastel-powerline" ;;
    9) preset_slug="tokyo-night" ;;
    10) preset_slug="gruvbox-rainbow" ;;
    11) preset_slug="jetpack" ;;
    12) preset_slug="catppuccin-powerline" ;;
    *) preset_slug="" ;;
    esac
  else
    preset_slug=""
  fi
else
  install_starship="n"
fi

# Configure Ghostty
echo "→ Configuring Ghostty..."
mkdir -p ~/.config/ghostty

cat >~/.config/ghostty/config <<GHOSTTY
theme = $theme
background-opacity = 1.0
font-family = "JetBrainsMono Nerd Font"
font-size = 15
font-thicken = true
cursor-style = block
cursor-style-blink = false
confirm-close-surface = false
mouse-hide-while-typing = true
GHOSTTY

# Configure Starship
if [[ "$install_starship" =~ ^[Yy]$ ]]; then
  echo "→ Configuring Starship..."
  mkdir -p ~/.config

  if [[ -n "${preset_slug:-}" ]]; then
    starship preset "$preset_slug" -o ~/.config/starship.toml
    echo "   → Preset applied successfully!"
  else
    cat >~/.config/starship.toml <<'STARSHIP'
format = """$directory$git_branch$git_status$python$nodejs$cmd_duration$line_break$character"""
[directory]
truncation_length = 3
[character]
success_symbol = "[➜](bold green)"
error_symbol = "[✘](bold red)"
STARSHIP
    echo "   → Using recommended default configuration."
  fi
fi

# Configure Shell
echo "→ Configuring $SHELL_TYPE..."
cat >>"$RC_FILE" <<EOF
# Starship
if command -v starship &> /dev/null; then
    eval "\$(starship init $SHELL_TYPE)"
fi

# eza aliases
alias ls='eza --icons --group-directories-first'
alias ll='eza -lh --icons --group-directories-first --git'
alias lt='eza --tree --level=2 --icons --git'
alias la='eza -lah --icons --group-directories-first --git'
EOF

# LazyVim
echo "→ Installing LazyVim for Neovim..."
rm -rf ~/.config/nvim 2>/dev/null || true
git clone --quiet https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

echo
echo "=================================================="
echo "          INSTALLATION COMPLETED SUCCESSFULLY!"
echo "=================================================="
echo "Ghostty Theme : $theme"
if [[ "$install_starship" =~ ^[Yy]$ ]]; then
  echo "Starship      : Installed"
else
  echo "Starship      : Skipped"
fi
echo "Shell         : $SHELL_TYPE"
echo "Neovim + LazyVim : Installed"
echo "=================================================="
echo
echo "Next steps:"
echo "1. Close Ghostty completely (Command + Q) and reopen it"
echo "2. Run: source $RC_FILE"
echo "3. Test: ls"
echo "4. Open Neovim: nvim → then run :Lazy sync"
echo
echo "Enjoy your setup! ✨"
