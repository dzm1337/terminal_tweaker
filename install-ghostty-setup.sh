#!/bin/bash
# ================================================
# Ghostty + Neovim + Starship + eza - Interactive Setup
# ================================================
# Detect OS
# ====================== 1. Install Dependencies ======================#
#
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
else
  OS="linux"
fi

if [[ "$OS" == "macos" ]]; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    BREW_PREFIX="/opt/homebrew"
  elif [[ -x /usr/local/bin/brew ]]; then
    BREW_PREFIX="/usr/local"
  else
    echo "Homebrew não encontrado. Instale manualmente em https://brew.sh"
    exit 1
  fi

  if ! grep -q "brew shellenv" ~/.zprofile 2>/dev/null; then
    echo 'eval "$('"$BREW_PREFIX"'/bin/brew shellenv)"' >>~/.zprofile
  fi

  eval "$("$BREW_PREFIX"/bin/brew shellenv)"

  brew update
  brew install neovim eza starship
  brew install --cask font-jetbrains-mono-nerd-font

  echo "Instalação no macOS concluída!"
else
  # Linux (mantido como estava)
  sudo apt update
  sudo apt install -y neovim curl git zsh

  curl -sS https://starship.rs/install.sh | sh -s -- --yes

  echo "Installing eza..."
  sudo mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/eza.gpg
  echo "deb [signed-by=/etc/apt/keyrings/eza.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/eza.list
  sudo apt update
  sudo apt install -y eza
fi

echo "Installing required programs..."

if [[ "$OS" == "macos" ]]; then
  brew install neovim starship eza font-jetbrains-mono-nerd-font
else
  sudo apt update
  sudo apt install -y neovim curl git zsh
  curl -sS https://starship.rs/install.sh | sh -s -- --yes
  sudo apt install -y eza
fi

# ====================== 2. Install Nerd Font ======================
if [[ "$OS" == "linux" ]]; then
  echo "Installing JetBrainsMono Nerd Font..."
  mkdir -p ~/.local/share/fonts
  cd /tmp
  wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip
  unzip -q JetBrainsMono.zip -d ~/.local/share/fonts/
  fc-cache -fv
  rm JetBrainsMono.zip
fi

# ====================== 3. Choose Ghostty Theme ======================
echo ""
echo "=========================================="
echo "      AVAILABLE GHOSTTY THEMES"
echo "=========================================="
echo ""
echo "1. TokyoNight"
echo "2. Catppuccin Mocha"
echo "3. Catppuccin Frappe"
echo "4. Dracula"
echo "5. Gruvbox Dark"
echo "6. Nord"
echo "7. OneDark"
echo "8. RosePine"
echo "9. KanagawaDragon"
echo "10. EverforestDark"
echo ""

read -p "Enter the number of the theme you want (1-10): " theme_choice

case $theme_choice in
1) theme="TokyoNight" ;;
2) theme="CatppuccinMocha" ;;
3) theme="CatppuccinFrappe" ;;
4) theme="Dracula" ;;
5) theme="GruvboxDark" ;;
6) theme="Nord" ;;
7) theme="OneDark" ;;
8) theme="RosePine" ;;
9) theme="KanagawaDragon" ;;
10) theme="EverforestDark" ;;
*) theme="TokyoNight" && echo "Invalid option. Using TokyoNight as default." ;;
esac

echo "Selected Ghostty theme: $theme"

# ====================== 4. Starship Setup ======================
echo ""
read -p "Do you want to install Starship prompt? (y/n): " install_starship

if [[ "$install_starship" =~ ^[Yy]$ ]]; then
  echo "Starship will be installed."
  starship_preset="default"
  starship_preset_name="Default (no custom preset)"

  echo ""
  read -p "Do you want to apply an official Starship preset? (y/n): " apply_preset

  if [[ "$apply_preset" =~ ^[Yy]$ ]]; then
    echo ""
    echo "=========================================="
    echo "      OFFICIAL STARSHIP PRESETS"
    echo "=========================================="
    echo ""
    echo "1. Nerd Font Symbols"
    echo "2. No Nerd Fonts"
    echo "3. Bracketed Segments"
    echo "4. Plain Text Symbols"
    echo "5. No Runtime Versions"
    echo "6. No Empty Icons"
    echo "7. Pure Prompt"
    echo "8. Pastel Powerline"
    echo "9. Tokyo Night"
    echo "10. Gruvbox Rainbow"
    echo "11. Jetpack"
    echo "12. Catppuccin Powerline"
    echo "13. None - use Starship default"
    echo ""

    read -p "Choose preset (1-13): " preset_choice

    case $preset_choice in
    1)
      starship_preset_name="Nerd Font Symbols"
      preset_slug="nerd-font-symbols"
      ;;
    2)
      starship_preset_name="No Nerd Fonts"
      preset_slug="no-nerd-font"
      ;;
    3)
      starship_preset_name="Bracketed Segments"
      preset_slug="bracketed-segments"
      ;;
    4)
      starship_preset_name="Plain Text Symbols"
      preset_slug="plain-text-symbols"
      ;;
    5)
      starship_preset_name="No Runtime Versions"
      preset_slug="no-runtime-versions"
      ;;
    6)
      starship_preset_name="No Empty Icons"
      preset_slug="no-empty-icons"
      ;;
    7)
      starship_preset_name="Pure Prompt"
      preset_slug="pure"
      ;;
    8)
      starship_preset_name="Pastel Powerline"
      preset_slug="pastel-powerline"
      ;;
    9)
      starship_preset_name="Tokyo Night"
      preset_slug="tokyo-night"
      ;;
    10)
      starship_preset_name="Gruvbox Rainbow"
      preset_slug="gruvbox-rainbow"
      ;;
    11)
      starship_preset_name="Jetpack"
      preset_slug="jetpack"
      ;;
    12)
      starship_preset_name="Catppuccin Powerline"
      preset_slug="catppuccin-powerline"
      ;;
    13 | *)
      starship_preset_name="Default (no custom preset)"
      preset_slug=""
      ;;
    esac

    echo "Selected preset: $starship_preset_name"
  else
    echo "No preset will be applied. Starship will use its built-in default."
  fi
else
  echo "Starship will not be installed."
  starship_preset="none"
fi
# ====================== 5. Configure Ghostty ======================#
echo "Configuring Ghostty..."
mkdir -p ~/.config/ghostty

cat >~/.config/ghostty/config <<GHOSTTY
theme=$theme
background-opacity = 1.0

font-family = "JetBrainsMono Nerd Font"
font-size = 15
font-thicken = true

cursor-style = block
cursor-style-blink = false

confirm-close-surface = false
mouse-hide-while-typing = true
GHOSTTY

# ====================== 6. Configure Starship (if chosen) ======================
if [[ "$install_starship" =~ ^[Yy]$ ]]; then
  mkdir -p ~/.config

  if [[ -n "${preset_slug:-}" && "$preset_slug" != "" ]]; then
    echo "Applying official Starship preset: $starship_preset_name"
    starship preset "$preset_slug" -o ~/.config/starship.toml
    starship_preset="preset-$preset_slug"
  else
    echo "Starship configured with default settings (no custom preset applied)."
    rm -f ~/.config/starship.toml 2>/dev/null || true
    starship_preset="default"
  fi
fi

# ====================== 7. Configure zsh ======================
echo "Configuring zsh..."

cat >>~/.zshrc <<'ZSHRC'

# Starship (if installed)
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi

# eza - Full configuration
alias ls='eza --icons --group-directories-first'
alias ll='eza -lh --icons --group-directories-first --git'
alias lt='eza --tree --level=2 --icons --git'
alias la='eza -lah --icons --group-directories-first --git'
ZSHRC

# ====================== 8. Install LazyVim ======================
echo "Installing Neovim + LazyVim..."
rm -rf ~/.config/nvim
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

echo ""
echo "=================================================="
echo "Installation completed successfully!"
echo "Ghostty Theme : $theme"
if [[ "$starship_preset" != "none" ]]; then
  echo "Starship      : Installed ($starship_preset)"
else
  echo "Starship      : Skipped"
fi
echo "=================================================="
echo ""
echo "Next steps:"
echo "1. Restart Ghostty"
echo "2. Run: source ~/.zshrc"
echo "3. Open Neovim: nvim"
echo "4. Inside Neovim run: :Lazy sync"
echo ""
echo "Enjoy your new setup!"
