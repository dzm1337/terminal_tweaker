# terminal_tweaker 🛠️

Just a collection of scripts to automate the setup of a high-performance terminal and a streamlined Python environment.
## Overview 🚀

The goal of **terminal_tweaker** 🍓​
1. A GPU-accelerated terminal interface.
2. A Python workflow powered exclusively by Ruff for instant fixes and formatting flake8.

---

## 1. Terminal Environment (terminal_setup.sh) 💻

This script sets up a low-latency stack so your terminal actually keeps up with your typing.

### Components
- **Ghostty**: A GPU-accelerated terminal for near-zero input lag. ⚡
- **Starship**: A minimal and fast shell prompt that only shows what you need.
- **eza**: A modern replacement for the `ls` command with better visuals.

### Command Examples 📂
The setup adds these aliases to your `.zshrc`:

#### `ls` (Standard Listing)
Displays files with icons and groups directories first.
> src/  tests/  main.py  README.md  ruff.toml

#### `ll` (Detailed List)
Shows permissions, file sizes, and Git status.
> drwxr-xr-x  - user 18 Apr 12:00 src/  
> -rw-r--r-- 2k user 18 Apr 12:05 main.py  [M]  
> -rw-r--r-- 5k user 18 Apr 11:50 README.md

#### `la` (The Full Picture)
Shows everything, including hidden config files.
> .git/  .config/  src/  main.py  README.md

---

## 2. Flake8 formatter (setup_ruff_fix.sh) 🐍

This module configures Neovim (LazyVim) to use **Ruff** as the only engine for linting and formatting. I removed mypy and other slow tools to keep things snappy.

### Workflow Integration
- **Auto-Fix on Save**: Using `Ctrl + S` triggers an asynchronous fix and format cycle.
- **Ruff Fix**: Automatically kills unused imports and fixes common syntax issues.
- **Ruff Format**: Enforces a consistent 79-character line limit.

### Keymap ⌨️
- **Ctrl + S**: Saves the file and runs the Ruff fix/format for the flake8 pipeline immediately.

### Technical Configuration (ruff.toml)
A global config is created at `~/.config/ruff/ruff.toml`:
- **Line Length**: 79 characters.
- **Target Version**: Python 3.12.
- **Selected Rules**: Pyflakes, Pycodestyle, Isort, and Pyupgrade.

---

## Installation 🔧

1. **Fire up the terminal setup:** `bash ~/terminal_setup.sh`
2. **Run the Ruff engine setup:** `bash ~/setup_ruff_fix.sh`
3. **Restart and go:** Restart your terminal and open Neovim. Check `:Mason` to make sure `ruff` is active.

---

## References & Tools 🔗

- **Ghostty**: [https://ghostty.org/](https://ghostty.org/)
- **Ruff**: [https://astral.sh/ruff](https://astral.sh/ruff)
- **Starship**: [https://starship.rs/](https://starship.rs/)
- **eza**: [https://eza.rocks/](https://eza.rocks/)
- **LazyVim**: [https://www.lazyvim.org/](https://www.lazyvim.org/)
- **Neovim**: [https://neovim.io/](https://neovim.io/)
