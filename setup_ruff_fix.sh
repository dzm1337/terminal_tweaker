#!/bin/bash

set -euo pipefail

read -p "Install LazyVim starter? (y/n): " install_lazy
if [[ "$install_lazy" =~ ^[Yy]$ ]]; then
   mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak" 2>/dev/null || true
   mv "$HOME/.local/share/nvim" "$HOME/.local/share/nvim.bak" 2>/dev/null || true
   git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
   rm -rf "$HOME/.config/nvim/.git"
fi

mkdir -p "$HOME/.local/bin"
curl -LsSf https://github.com/astral-sh/ruff/releases/latest/download/ruff-x86_64-unknown-linux-gnu.tar.gz | tar -xz -C "$HOME/.local/bin" --strip-components=1 ruff-x86_64-unknown-linux-gnu/ruff
chmod +x "$HOME/.local/bin/ruff"

mkdir -p "$HOME/.config/nvim/lua/plugins"
mkdir -p "$HOME/.config/ruff"

cat >"$HOME/.config/nvim/lua/plugins/lsp.lua" <<'EOF'
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ruff = {
          cmd = { vim.fn.expand("$HOME") .. "/.local/bin/ruff", "server" },
        },
      },
      setup = {
        ruff = function(_, opts)
          require("lspconfig").ruff.setup(opts)
          return true
        end,
      },
    },
  },
}
EOF

cat >"$HOME/.config/nvim/lua/plugins/conform_python.lua" <<'EOF'
return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
    },
  },
}
EOF

cat >"$HOME/.config/nvim/lua/plugins/keymaps_ruff.lua" <<'EOF'
vim.keymap.set("n", "<C-s>", function()
  vim.cmd("w")
  require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Save + Fix with Ruff" })
return {}
EOF

cat >"$HOME/.config/ruff/ruff.toml" <<'EOF'
line-length = 79
target-version = "py310"

[lint]
select = ["E", "F", "I", "W", "UP", "RUF", "ANN"]
ignore = [
    "PTH123",
    "TRY003",
    "EM101",
    "E501",
    "UP015",
    "I001",
]

[format]
quote-style = "double"
indent-style = "space"
EOF

rm -rf "$HOME/.local/share/nvim/mason/packages/ruff" 2>/dev/null || true
nvim --headless -c "Lazy sync" -c "qa" 2>/dev/null || true

echo "LazyVim and Ruff manual installation finished successfully."
