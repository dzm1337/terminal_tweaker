# terminal_tweaker 🛠️

> Automate the setup of a high-performance terminal and a streamlined Python environment.

---

## Overview 🚀

**terminal_tweaker** gets your machine running two things exceptionally well:

1. **A curated terminal setup** — installs and configures Starship, eza, Neovim,
LazyVim, and JetBrainsMono Nerd Font, then applies your chosen Ghostty theme automatically.
2. **A Ruff-only Python workflow** — fast linting and formatting, no bloat.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Terminal Environment](#1-terminal-environment)
- [Python Linting & Formatting](#2-python-linting--formatting)
- [Installation](#installation)
- [References](#references)

---

## Prerequisites ⚠️

> **Ghostty must be installed before running any script.**
> `terminal_setup.sh` will configure Ghostty, but it will not install it.

### Ghostty — GPU-Accelerated Terminal

Ghostty is a fast, feature-rich terminal emulator that uses the GPU to render
every frame. It is the foundation of this entire stack.

#### Why Ghostty?

| Feature | Detail |
|---|---|
| ⚡ Rendering | GPU-accelerated via Metal (macOS) and OpenGL (Linux) |
| ⌨️ Input latency | Near-zero — renders independently of the shell |
| 🔤 Font rendering | Native, per-platform font rendering |
| 🪟 Multiplexing | Built-in tabs and splits, no tmux required |
| 📦 Size | Single binary, no runtime dependencies |
| 🧩 Compatibility | Full `xterm-256color` and Kitty keyboard protocol |

#### System Requirements

| Platform | Requirement |
|---|---|
| macOS | macOS 13 (Ventura) or later, Apple Silicon or Intel |
| Linux | X11 or Wayland, GPU with OpenGL 3.3+ support |

---

#### Install Ghostty on macOS 🍎

```bash
brew install --cask ghostty
```

---

#### Install Ghostty on Linux 🐧

**Debian / Ubuntu:**

```bash
sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://apt.ghostty.org/gpg.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/ghostty.gpg

echo "deb [signed-by=/etc/apt/keyrings/ghostty.gpg] \
  https://apt.ghostty.org/apt stable main" \
  | sudo tee /etc/apt/sources.list.d/ghostty.list

sudo apt update && sudo apt install ghostty
```

> Once Ghostty is running, you are ready to proceed. ✅

---

## 1. Terminal Environment

> Script: `terminal_setup.sh` 💻

Installs and configures the full terminal stack. Detects your OS automatically
and handles everything from packages to shell config.

### What the Script Does

| Step | Action |
|---|---|
| 📦 Installs | Starship, eza, Neovim, LazyVim, JetBrainsMono Nerd Font |
| 🎨 Configures | Ghostty theme of your choice |
| 🐚 Configures | Aliases in `.zshrc` or `.bashrc` |
| 🔍 Detects | OS and architecture automatically (macOS arm64/x86_64, Linux) |

---

### Interactive Prompts During Setup

**1. Shell preference**
```
1. Zsh
2. Bash
```

**2. Ghostty theme**
- [ghostty +list-themes] to see all the themes.
```
1. Tokyo Night        2. Catppuccin Mocha
3. Catppuccin Frappe  4. Dracula
5. Gruvbox Dark       6. Nord
7. One Dark           8. Rose Pine
9. Kanagawa Dragon    10. Everforest
```

**3. Starship prompt preset**
- [Starship](https://starship.rs/presets/) — Presets Overview 🎨
```
1. Nerd Font Symbols    2. No Nerd Fonts
3. Bracketed Segments   4. Plain Text
5. No Runtime Versions  6. No Empty Icons
7. Pure Prompt          8. Pastel Powerline
9. Tokyo Night          10. Gruvbox Rainbow
11. Jetpack             12. Catppuccin Powerline
13. Default
```

---

### Aliases Added to Your Shell

#### `ls` — Standard listing
Displays files with icons, directories grouped first.

```
src/  tests/  main.py  README.md  ruff.toml
```

#### `ll` — Detailed list
Shows permissions, file sizes, and Git status inline.

```
drwxr-xr-x  -   user  18 Apr 12:00  src/
-rw-r--r--  2k  user  18 Apr 12:05  main.py    [M]
-rw-r--r--  5k  user  18 Apr 11:50  README.md
```

#### `lt` — Tree view
Shows the directory structure up to 2 levels deep.

```
./
├── src/
│   ├── main.py
│   └── utils.py
├── tests/
└── README.md
```

#### `la` — Full picture
Includes hidden files and config directories.

```
.git/  .config/  src/  main.py  README.md
```

---

## 2. Python Linting & Formatting

> Script: `setup_ruff_fix.sh` 🐍

Configures **Neovim (LazyVim)** to use **Ruff** as the sole engine for linting
and formatting. Slow tools like `mypy` and `black` are intentionally excluded.

> **Why Ruff only?**
> Ruff replaces Flake8, isort, pyupgrade, and Black in a single binary —
> written in Rust, orders of magnitude faster.

### Workflow

| Trigger | Action |
|---|---|
| `Ctrl + S` | Save → Ruff fix → Ruff format (async, non-blocking) |
| Ruff Fix | Removes unused imports, corrects common syntax issues |
| Ruff Format | Enforces 79-character line width consistently |

### Configuration

A global config is written to `~/.config/ruff/ruff.toml`:

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

## Installation 🔧

> **Prerequisites:** Ghostty (see above), `zsh` or `bash`,
> `brew` (macOS) or `apt` (Linux), `nvim >= 0.9`

```bash
# 1. Install Ghostty first (see Prerequisites above)

# 2. Set up the terminal stack
bash ~/terminal_setup.sh

# 3. Restart your terminal and reload your shell config
source ~/.zshrc  # or source ~/.bashrc

# 4. Set up the Ruff engine
bash ~/setup_ruff_fix.sh

# 5. Open Neovim and sync plugins
nvim  # then run :Lazy sync

# 6. Verify Ruff is active inside Neovim
:Mason
```

---

## References 🔗

- [Ghostty](https://ghostty.org/) — GPU-accelerated terminal
- [Ghostty Docs](https://ghostty.org/docs) — Full documentation
- [Starship](https://starship.rs/) — Cross-shell prompt
- [eza](https://eza.rocks/) — Modern `ls`
- [Ruff](https://astral.sh/ruff) — Fast Python linter & formatter
- [LazyVim](https://www.lazyvim.org/) — Neovim config framework
- [Neovim](https://neovim.io/) — Hyperextensible text editor
