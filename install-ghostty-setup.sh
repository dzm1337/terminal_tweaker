#!/bin/bash
# ================================================
# Ghostty + Neovim + Starship + eza - Interactive Setup
# ================================================

echo "Starting full interactive setup..."

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
else
    OS="linux"
fi

# ====================== 1. Install Dependencies ======================
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
echo "7. One Dark"
echo "8. Rose Pine"
echo "9. Kanagawa Dragon"
echo "10. Everforest Dark"
echo ""

read -p "Enter the number of the theme you want (1-10): " theme_choice

case $theme_choice in
    1) theme="TokyoNight" ;;
    2) theme="Catppuccin Mocha" ;;
    3) theme="Catppuccin Frappe" ;;
    4) theme="Dracula" ;;
    5) theme="Gruvbox Dark" ;;
    6) theme="Nord" ;;
    7) theme="One Dark" ;;
    8) theme="Rose Pine" ;;
    9) theme="Kanagawa Dragon" ;;
    10) theme="Everforest Dark" ;;
    *) theme="TokyoNight" && echo "Invalid option. Using TokyoNight as default." ;;
esac

echo "Selected Ghostty theme: $theme"

# ====================== 4. Ask about Starship ======================
echo ""
read -p "Do you want to install Starship prompt? (y/n): " install_starship

if [[ "$install_starship" =~ ^[Yy]$ ]]; then
    echo ""
    echo "=========================================="
    echo "      STARSHIP THEMES / PRESETS"
    echo "=========================================="
    echo ""
    echo "1. Default (recommended)"
    echo "2. Minimal"
    echo "3. Nerd Font (with icons)"
    echo "4. Classic"
    echo ""

    read -p "Choose Starship style (1-4): " starship_choice

    case $starship_choice in
        1) starship_preset="default" ;;
        2) starship_preset="minimal" ;;
        3) starship_preset="nerd" ;;
        4) starship_preset="classic" ;;
        *) starship_preset="default" ;;
    esac

    echo "Selected Starship style: $starship_preset"
else
    echo "Starship will not be installed."
    starship_preset="none"
fi

# ====================== 5. Configure Ghostty ======================
echo "Configuring Ghostty..."
mkdir -p ~/.config/ghostty

cat > ~/.config/ghostty/config << GHOSTTY
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
if [[ "$starship_preset" != "none" ]]; then
    echo "Configuring Starship ($starship_preset)..."
    mkdir -p ~/.config

    if [[ "$starship_preset" == "nerd" || "$starship_preset" == "default" ]]; then
        cat > ~/.config/starship.toml << 'STARSHIP'
format = """$directory$git_branch$git_status$python$cmd_duration$line_break$character"""
[character]
success_symbol = "[➜](bold green)"
error_symbol = "[✘](bold red)"
STARSHIP
    else
        # Minimal or Classic - use simpler config
        cat > ~/.config/starship.toml << 'STARSHIP'
format = "$directory$character"
[character]
success_symbol = "❯"
STARSHIP
    fi
fi

# ====================== 7. Configure zsh ======================
echo "Configuring zsh..."

cat >> ~/.zshrc << 'ZSHRC'

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
