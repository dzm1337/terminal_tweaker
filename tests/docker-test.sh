#!/usr/bin/env bash
# ============================================================
# tests/docker-test.sh — run the installer inside a distro container
# ============================================================
# Usage: tests/docker-test.sh <image> [extra install.sh args]
#   tests/docker-test.sh ubuntu:22.04
#   tests/docker-test.sh archlinux:latest --skip font
#
# Ghostty is skipped by default (GUI app, large dependency tree).

set -euo pipefail

image="${1:?usage: $0 <image> [install.sh args]}"
shift
repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Minimal images lack bash; install it with whatever package manager exists.
prepare='
if ! command -v bash >/dev/null 2>&1; then
  if command -v apk >/dev/null; then apk add --no-cache bash
  elif command -v xbps-install >/dev/null; then xbps-install -Sy bash
  fi
fi'

# shellcheck disable=SC2016 # expanded inside the container
verify='
set -e
export PATH="$HOME/.local/bin:$PATH"
echo "--- verify ---"
starship --version | head -n1
eza --version | sed -n 2p
nvim --version | head -n1
nvim --clean --headless -c "lua if vim.fn.has(\"nvim-0.11.2\") == 0 then os.exit(1) end" -c q
test -f "$HOME/.config/nvim/init.lua"
test -f "$HOME/.config/starship.toml"
test "$(grep -c "terminal_tweaker >>>" "$HOME/.zshrc")" = 1
zsh -ic "alias ll" >/dev/null
echo "VERIFY_OK"'

docker run --rm -v "$repo_dir:/src:ro" -e TERM=dumb -e SHELL=/bin/zsh "$image" sh -c "
  $prepare
  cp -r /src /tmp/tt && cd /tmp/tt
  bash ./install.sh --yes --skip ghostty $* && bash -c '$verify'
"
