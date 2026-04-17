# terminal_tweaker

This project provides a collection of scripts to automate the setup of a high-performance terminal and a streamlined Python development environment using Neovim.

## Overview

The goal of terminal_tweaker is to replace heavy legacy tools with fast, modern alternatives written in Rust and Zig. It focuses on:
1. A GPU-accelerated terminal interface.
2. A Python workflow powered exclusively by Ruff for instant fixes and formatting.

---

## 1. Terminal Environment (terminal_setup.sh)

This script configures a low-latency stack to replace the standard shell experience.

### Components
- Ghostty: A GPU-accelerated terminal emulator for near-zero input lag.
- Starship: A minimal and fast shell prompt that displays context like Git branches.
- eza: A modern replacement for the ls command with better visualization.

### Command Examples
The setup adds specific aliases to your .zshrc to make navigation more intuitive:

#### ls (Standard Listing)
Displays files with icons and groups directories first.
Example output:
src/  tests/  main.py  README.md  ruff.toml

#### ll (Detailed List)
Shows permissions, file sizes, and Git status for each file.
Example output:
drwxr-xr-x  - user 18 Apr 12:00 src/
-rw-r--r-- 2k user 18 Apr 12:05 main.py  [M]
-rw-r--r-- 5k user 18 Apr 11:50 README.md

#### la (Hidden Files)
Shows all files, including dotfiles and configuration directories.
Example output:
.git/  .config/  src/  main.py  README.md

---

## 2. Python Development (setup_ruff_fix.sh)

This module configures Neovim (LazyVim) to use Ruff as the sole engine for linting and formatting. Mypy and other slower tools are excluded to maintain maximum speed.

### Workflow Integration
- Auto-Fix on Save: Using the Ctrl + S shortcut triggers an asynchronous fix and format cycle.
- Ruff Fix: Automatically removes unused imports and fixes common syntax issues.
- Ruff Format: Enforces a consistent coding style based on a 79-character line limit.

### Keymap
- Ctrl + S: Saves the current buffer and runs the Ruff fix/format pipeline immediately.

### Technical Configuration (ruff.toml)
A global configuration is created at ~/.config/ruff/ruff.toml with the following defaults:
- Line Length: 79 characters.
- Target Version: Python 3.12.
- Selected Rules: Pyflakes, Pycodestyle, Isort, and Pyupgrade.

---

## Installation

1. Execute the terminal setup:
   bash ~/terminal_setup.sh

2. Execute the Ruff engine setup:
   bash ~/setup_ruff_fix.sh

3. Restart your terminal and open Neovim. Ensure ruff is installed via the :Mason interface.
