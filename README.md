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

It installs and configures Ghostty, Starship, eza, Neovim + LazyVim and the
JetBrainsMono Nerd Font — on macOS and on almost any Linux distribution.
Everything is idempotent and safe to re-run.

---

## Features

| Feature | Detail |
|---|---|
| **One command** | `./install.sh`, or `curl … \| bash` without cloning |
| **Runs almost anywhere** | Detects the package manager, not the distro name — derivatives work automatically |
| **No stale Neovim** | Installs a Neovim recent enough for LazyVim even on Debian/Ubuntu LTS |
| **Interactive or unattended** | Pick theme, prompt and shell — or `--yes` for defaults |
| **Pick your steps** | `--only neovim`, `--skip ghostty,font` |
| **Dry-run mode** | Preview every change: `--dry-run` |
| **Idempotent** | Shell config lives in one managed block that is rewritten, never duplicated |
| **Safe backups** | Existing configs are copied to `~/.config_backups/` before being replaced |
| **Debuggable** | Command output goes to a log file; failures show its last lines |

---

## Architecture

### Stack

```
Ghostty → zsh / bash → Starship → eza → Neovim + LazyVim
```

| Component | Role |
|---|---|
| **[Ghostty](https://ghostty.org/)** | GPU-accelerated terminal with built-in tabs and splits. |
| **[Starship](https://starship.rs/)** | Cross-shell prompt showing git state, runtimes and exit codes. |
| **[eza](https://eza.rocks/)** | Modern `ls` replacement with icons, git status and tree view. |
| **[Neovim](https://neovim.io/)** + **[LazyVim](https://www.lazyvim.org/)** | Editor with a curated, lazy-loaded plugin set and LSP. |

### Code layout

```
install.sh           entrypoint: flags, step selection, summary
lib/
  core.sh            logging, spinner, prompts, backups, downloads
  platform.sh        OS / arch / distro / libc / package-manager detection
  pkg.sh             one pkg_install for apt, dnf, yum, pacman, zypper, apk, xbps, brew
modules/             one file per tool, each exposing step_<name>
  packages.sh        base packages (curl, git, unzip, zsh, compiler, …)
  font.sh  ghostty.sh  starship.sh  eza.sh  neovim.sh  shell.sh
tests/
  docker-test.sh     runs the installer inside any distro container
```

Modules never call `apt`/`dnf`/… directly — they ask `pkg_install` for a generic
name and `lib/pkg.sh` maps it (e.g. `build-tools` → `build-essential` / `base-devel` /
`build-base`). Supporting a new distro family means adding a few lines there.

Steps run in order: `packages font ghostty starship eza neovim shell`.

### Install strategy per tool

| Tool | macOS | Linux |
|---|---|---|
| Starship | Homebrew | Official installer → `~/.local/bin` (static binary, no root) |
| eza | Homebrew | Native package, else upstream binary → `~/.local/bin` |
| Neovim | Homebrew | Official release → `~/.local/opt` on glibc; native package on musl |
| Font | Homebrew cask | Nerd Fonts release → `~/.local/share/fonts` |
| Ghostty | Homebrew cask | Native package → Fedora COPR / Ubuntu-Debian `.deb` → snap → manual hint |

---

## Prerequisites

- `bash` (3.2+ — the macOS default is fine; Alpine: `apk add bash`)
- `curl` or `wget`
- macOS: [Homebrew](https://brew.sh)
- Linux: a user with `sudo` or `doas` (or run as root, e.g. in a container)

Ghostty is installed for you where possible — see [Supported Platforms](#supported-platforms).

---

## Installation

```bash
git clone https://github.com/dzm1337/terminal_tweaker.git
cd terminal_tweaker
./install.sh
```

Or without cloning:

```bash
curl -fsSL https://raw.githubusercontent.com/dzm1337/terminal_tweaker/main/install.sh | bash
```

Then restart your terminal and open `nvim` — LazyVim installs its plugins on first launch.

### Options

| Flag | Effect |
|---|---|
| `-n`, `--dry-run` | Print every action without making changes |
| `-y`, `--yes`, `--force` | Skip all prompts, use defaults |
| `-v`, `--verbose` | Stream command output instead of a spinner |
| `--only a,b` | Run only these steps |
| `--skip a,b` | Skip these steps |
| `-h`, `--help` | Show usage |

```bash
./install.sh --dry-run
./install.sh --yes --skip ghostty,font   # headless server, container, WSL
./install.sh --only neovim               # just upgrade Neovim + LazyVim
```

---

## Supported Platforms

Detection is based on the package manager that is present, so derivatives of these
families (Mint, Pop!\_OS, Zorin, elementary, Kali, Manjaro, EndeavourOS, CachyOS,
Artix, Nobara, AlmaLinux, …) are covered too.

| Family | Package manager | Tested in CI | Ghostty |
|---|---|---|---|
| macOS 13+ (Apple Silicon / Intel) | brew | ✓ | Homebrew cask |
| Ubuntu 22.04, 24.04+ | apt | ✓ | `.deb` (24.04+) or snap |
| Debian 12, 13+ | apt | ✓ | `.deb` (13+) or snap |
| Fedora | dnf | ✓ | COPR `scottames/ghostty` |
| RHEL / Rocky / Alma 9 | dnf | ✓ | snap or manual |
| Arch | pacman | ✓ | official repo |
| openSUSE Tumbleweed / Leap | zypper | ✓ | official repo (Tumbleweed) |
| Alpine | apk | ✓ | community repo |
| Void | xbps | ✓ | official repo |
| WSL | any of the above | — | skipped (font goes on Windows) |

Unknown package manager? The script still installs the user-space tools (Starship,
eza, Neovim) and tells you which packages to install yourself.

---

## What the Script Does

| Step | Action |
|---|---|
| `packages` | curl, git, unzip, tar, zsh, fontconfig, C compiler via the native package manager |
| `font` | JetBrainsMono Nerd Font |
| `ghostty` | Installs Ghostty, writes `~/.config/ghostty/config` with your theme |
| `starship` | Installs Starship, applies your preset to `~/.config/starship.toml` |
| `eza` | Installs eza |
| `neovim` | Installs Neovim ≥ 0.11.2, clones the LazyVim starter into `~/.config/nvim` |
| `shell` | Writes the managed block (PATH, Starship init, eza aliases) into `.zshrc`/`.bashrc`, offers `chsh` |

### Interactive prompts

**Shell** — defaults to your current login shell
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

Added to your shell rc file inside a marked block:

```bash
# >>> terminal_tweaker >>>
...
# <<< terminal_tweaker <<<
```

Delete the block to undo; re-running the installer rewrites it.

| Alias | Command | Description |
|---|---|---|
| `ls` | `eza --icons --group-directories-first` | Standard listing with icons |
| `ll` | `eza -lh --icons --group-directories-first --git` | Detailed list with git status |
| `lt` | `eza --tree --level=2 --icons --git` | Tree view, 2 levels deep |
| `la` | `eza -lah --icons --group-directories-first --git` | All files including hidden |

---

## Troubleshooting

### A step failed

Every command's output is in the log file printed at startup
(default `$TMPDIR/terminal_tweaker.log`). Re-run just that step:

```bash
./install.sh --only eza --verbose
```

### Ghostty could not be installed

Some distros have no package yet. Install it manually from
[ghostty.org/docs/install/binary](https://ghostty.org/docs/install/binary), then:

```bash
./install.sh --only ghostty   # writes the config
```

### `nvim` is still the old version

`~/.local/bin` must come before `/usr/bin` in `PATH`. The managed shell block does this —
restart your terminal, then check `command -v nvim`.

### Starship / aliases not active

```bash
exec $SHELL
grep -A3 'terminal_tweaker >>>' ~/.zshrc
```

### Font glyphs not rendering

```bash
grep font-family ~/.config/ghostty/config
fc-cache -f   # Linux only — rebuild font cache
```

---

## Roadmap

- Fish shell support
- Python workflow module (Ruff in LazyVim)
- tmux configuration module
- WezTerm as an alternative to Ghostty

---

## Contributing

One concern per PR. ShellCheck must pass and the scripts must stay bash 3.2 compatible
(macOS). To add a tool, create `modules/<tool>.sh` with a `step_<tool>` function and add
it to `ALL_STEPS` in `install.sh`.

```bash
shellcheck -x install.sh lib/*.sh modules/*.sh tests/*.sh
./install.sh --dry-run
tests/docker-test.sh ubuntu:22.04     # any image from the CI matrix
```

---

## References

- [Ghostty](https://ghostty.org/)
- [Starship](https://starship.rs/)
- [eza](https://eza.rocks/)
- [LazyVim](https://www.lazyvim.org/)
- [Neovim](https://neovim.io/)
- [Nerd Fonts](https://www.nerdfonts.com/)

---

## Acknowledgements

- [Starship](https://starship.rs/) for the preset system
- [LazyVim](https://www.lazyvim.org/) for the Neovim starter template
- [eza community](https://github.com/eza-community/eza) for maintaining the fork
