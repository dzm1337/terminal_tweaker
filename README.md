# terminal_tweaker 🛠️

> One command to transform a fresh machine into a productive development environment.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey)](README.md#supported-platforms)

---

## Table of Contents

- [Why terminal_tweaker?](#why-terminal_tweaker)
- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Supported Platforms](#supported-platforms)
- [What the Script Does](#what-the-script-does)
- [Aliases](#aliases)
- [Python Workflow](#python-linting--formatting)
- [Troubleshooting](#troubleshooting)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [Acknowledgements](#acknowledgements)

---

## Why terminal_tweaker?

Setting up a new machine involves the same sequence of steps every time: install a font,
configure a prompt, wire up aliases, get Neovim ready, connect a linter.
terminal_tweaker automates that sequence into a single script with sane defaults and
interactive overrides.

It does two things well:

1. **Terminal stack** — installs and configures Ghostty, Starship, eza, Neovim, LazyVim,
   and JetBrainsMono Nerd Font.
2. **Python workflow** — configures Ruff as the sole linting and formatting engine inside
   Neovim, replacing Flake8, Black, and isort with one Rust binary.

Everything is idempotent and safe to re-run.

---

## Features

| Feature | Detail |
|---|---|
| **Single file** | Everything in one `terminal_setup.sh` — no dependencies, no installer |
| **Automatic OS detection** | macOS (arm64/x86_64) and twelve Linux distro families |
| **Interactive setup** | Choose your theme, prompt preset, and shell |
| **Dry-run mode** | Preview every change before it happens: `--dry-run` |
| **Idempotent** | Re-running never duplicates aliases or config blocks |
| **Safe backups** | Existing configs are copied to `~/.config_backups/` before being replaced |
| **Spinner feedback** | Progress indicator on every long-running install step |
| **Non-interactive mode** | `--force` accepts all defaults for scripted use |

---

## Architecture

```
Ghostty
  ↓
Shell (zsh / bash)
  ↓
Starship prompt
  ↓
eza  (ls / ll / lt / la aliases)
  ↓
Neovim + LazyVim
  ↓
Ruff  (lint + format on save)
```

### Component overview

| Component | Role |
|---|---|
| **[Ghostty](https://ghostty.org/)** | GPU-accelerated terminal. Metal on macOS, OpenGL on Linux. Single binary, built-in tabs and splits. |
| **[Starship](https://starship.rs/)** | Cross-shell prompt. Reads git state, language runtimes, and exit codes. Written in Rust. |
| **[eza](https://eza.rocks/)** | Modern `ls` replacement with icons, git status, and tree view. |
| **[Neovim](https://neovim.io/)** | Hyperextensible editor configured via LazyVim for zero-friction startup. |
| **[LazyVim](https://www.lazyvim.org/)** | Neovim distribution with lazy-loading, LSP, and a curated plugin set. |
| **[Ruff](https://astral.sh/ruff)** | Python linter and formatter written in Rust. Replaces Flake8, Black, isort, and pyupgrade. |

---

## Prerequisites

> **Ghostty must be installed before running `terminal_setup.sh`.** The script
> configures Ghostty but does not install it.

### Install Ghostty on macOS

```bash
brew install --cask ghostty
```

### Install Ghostty on Linux (Debian / Ubuntu)

```bash
sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://apt.ghostty.org/gpg.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/ghostty.gpg

echo "deb [signed-by=/etc/apt/keyrings/ghostty.gpg] \
  https://apt.ghostty.org/apt stable main" \
  | sudo tee /etc/apt/sources.list.d/ghostty.list

sudo apt update && sudo apt install ghostty
```

### Install Ghostty on Arch Linux

```bash
sudo pacman -S ghostty
```

Other distributions: [ghostty.org/download](https://ghostty.org/download).

---

## Installation

```bash
git clone https://github.com/dzm1337/terminal_tweaker.git
cd terminal_tweaker

# 1. Terminal stack
./terminal_setup.sh

# 2. Reload your shell
source ~/.zshrc   # or source ~/.bashrc

# 3. Python workflow (optional)
./setup_ruff_fix.sh

# 4. Sync Neovim plugins
nvim   # then :Lazy sync
```

### Options

| Flag | Effect |
|---|---|
| `--dry-run` | Print every action without making changes |
| `--force` | Skip all prompts, use defaults |
| `--verbose` | Print each command before it runs |
| `--help` | Show usage |

```bash
./terminal_setup.sh --dry-run
./terminal_setup.sh --force
./terminal_setup.sh --verbose
DRY_RUN=true ./terminal_setup.sh
```

---

## Supported Platforms

| Platform | Package manager | eza source |
|---|---|---|
| macOS 13+ (Apple Silicon) | Homebrew | brew |
| macOS 13+ (Intel) | Homebrew | brew |
| Ubuntu 20.04+ | apt | eza apt repo |
| Debian 11+ | apt | eza apt repo |
| Linux Mint | apt | eza apt repo |
| Pop!\_OS | apt | eza apt repo |
| **Arch Linux** | **pacman** | **pacman (official repos)** |
| Manjaro | pacman | pacman |
| EndeavourOS | pacman | pacman |
| Fedora 38+ | dnf | dnf / cargo fallback |
| RHEL 9 / Rocky / AlmaLinux | dnf + EPEL | cargo fallback |
| openSUSE Leap / Tumbleweed | zypper | cargo fallback |

---

## What the Script Does

| Step | Action |
|---|---|
| Detect OS and arch | Selects the correct install path automatically |
| Install packages | Starship, eza, Neovim, git, build tools via native package manager |
| Install font | JetBrainsMono Nerd Font v3.2.1 |
| Configure Ghostty | Writes `~/.config/ghostty/config` with chosen theme |
| Configure Starship | Applies chosen preset to `~/.config/starship.toml` |
| Configure shell | Injects Starship init and eza aliases into `.zshrc` or `.bashrc` |
| Install LazyVim | Clones the LazyVim starter into `~/.config/nvim` |

### Interactive prompts

**Shell preference**
```
1. Zsh
2. Bash
```

**Ghostty theme**
```
 1. Tokyo Night        2. Catppuccin Mocha
 3. Catppuccin Frappe  4. Dracula
 5. Gruvbox Dark       6. Nord
 7. One Dark Two       8. Rose Pine
 9. Kanagawa Dragon   10. Everforest Dark Hard
```

**Starship preset** — full list at [starship.rs/presets](https://starship.rs/presets/)
```
 1. Nerd Font Symbols    2. No Nerd Fonts
 3. Bracketed Segments   4. Plain Text
 5. No Runtime Versions  6. No Empty Icons
 7. Pure Prompt          8. Pastel Powerline
 9. Tokyo Night         10. Gruvbox Rainbow
11. Jetpack             12. Catppuccin Powerline
13. Default (minimal)
```

---

## Aliases

Added to your shell rc file automatically.

| Alias | Command | Description |
|---|---|---|
| `ls` | `eza --icons --group-directories-first` | Standard listing with icons |
| `ll` | `eza -lh --icons --group-directories-first --git` | Detailed list with git status |
| `lt` | `eza --tree --level=2 --icons --git` | Tree view, 2 levels deep |
| `la` | `eza -lah --icons --group-directories-first --git` | All files including hidden |

---

## Python Linting & Formatting

> Script: `setup_ruff_fix.sh`

Configures Neovim (LazyVim) to use Ruff as the sole Python engine.

**Why Ruff only?** Ruff replaces Flake8, isort, pyupgrade, and Black in a single binary
written in Rust — typically 10–100× faster than the tools it replaces.

| Trigger | Action |
|---|---|
| `Ctrl + S` | Save → Ruff fix → Ruff format (async, non-blocking) |
| Ruff fix | Removes unused imports, corrects common syntax issues |
| Ruff format | Enforces 79-character line width |

Global config written to `~/.config/ruff/ruff.toml`:

```toml
line-length = 79
target-version = "py312"

[lint]
select = [
  "F",   # Pyflakes
  "E",   # Pycodestyle errors
  "W",   # Pycodestyle warnings
  "I",   # isort
  "UP",  # pyupgrade
]
```

---

## Troubleshooting

### Ghostty not found

`terminal_setup.sh` configures Ghostty but does not install it. Install it first:
- macOS: `brew install --cask ghostty`
- Arch: `sudo pacman -S ghostty`
- Others: [ghostty.org/download](https://ghostty.org/download)

### Starship not appearing after install

```bash
source ~/.zshrc   # or ~/.bashrc
grep "starship init" ~/.zshrc
```

### Neovim plugins not loading

Open Neovim and run `:Lazy sync`. If Mason shows errors, run `:MasonUpdate`.

### Ruff not running on save

```bash
ruff --version
ls ~/.config/nvim/lua/plugins/ruff.lua
```

If the plugin file is missing, re-run `./setup_ruff_fix.sh`.

### Font glyphs not rendering

```bash
grep font-family ~/.config/ghostty/config
fc-cache -fv   # Linux only — rebuild font cache
```

### eza aliases not active

```bash
source ~/.zshrc
eza --version
```

---

## Roadmap

- Fish shell support
- tmux configuration module
- WezTerm as an alternative to Ghostty
- Docker development environment
- Python project template generator (Ruff + pyproject.toml)

---

## Contributing

One concern per PR. ShellCheck must pass. Update `CHANGELOG.md` under `[Unreleased]`.

```bash
shellcheck terminal_setup.sh
./terminal_setup.sh --dry-run
```

---

## References

- [Ghostty](https://ghostty.org/)
- [Starship](https://starship.rs/)
- [eza](https://eza.rocks/)
- [Ruff](https://astral.sh/ruff)
- [LazyVim](https://www.lazyvim.org/)
- [Neovim](https://neovim.io/)
- [Nerd Fonts](https://www.nerdfonts.com/)

---

## Acknowledgements

- [Starship](https://starship.rs/) for the preset system
- [LazyVim](https://www.lazyvim.org/) for the Neovim starter template
- [Astral](https://astral.sh/) for Ruff
- [eza community](https://github.com/eza-community/eza) for maintaining the fork
