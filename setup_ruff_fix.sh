#!/bin/bash

set -euo pipefail

read -p "Install LazyVim starter configuration? (y/n): " install_lazy
if [[ "$install_lazy" =~ ^[Yy]$ ]]; then
   echo "Installing LazyVim..."
   mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null || true
   mv ~/.local/share/nvim ~/.local/share/nvim.bak 2>/dev/null || true
   mv ~/.local/state/nvim ~/.local/state/nvim.bak 2>/dev/null || true
   mv ~/.cache/nvim ~/.cache/nvim.bak 2>/dev/null || true
   
   git clone https://github.com/LazyVim/starter ~/.config/nvim
   rm -rf ~/.config/nvim/.git
fi

echo "Installing Ruff binary manually..."
mkdir -p ~/.local/bin
curl -LsSf https://github.com/astral-sh/ruff/releases/latest/download/ruff-x86_64-unknown-linux-gnu.tar.gz | tar -xz -C ~/.local/bin --strip-components=1 ruff-x86_64-unknown-linux-gnu/ruff
chmod +x ~/.local/bin/ruff

mkdir -p ~/.config/nvim/lua/plugins
mkdir -p ~/.config/ruff

cat >~/.config/nvim/lua/plugins/lsp.lua <<'EOF'
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

cat >~/.config/nvim/lua/plugins/conform_python.lua <<'EOF'
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

cat >~/.config/nvim/lua/plugins/keymaps_ruff.lua <<'EOF'
vim.keymap.set("n", "<C-s>", function()
  vim.cmd("w")
  require("conform").format({
    async = true,
    lsp_fallback = true,
  })
end, { desc = "Save + Fix with Ruff" })

return {}
EOF

cat >~/.config/ruff/ruff.toml <<'EOF'
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
]

[format]
quote-style = "double"
indent-style = "space"
skip-magic-trailing-comma = false
line-ending = "lf"
EOF

rm -rf ~/.local/share/nvim/mason/packages/ruff 2>/dev/null || true
nvim --headless -c "Lazy sync" -c "qa" 2>/dev/null || true

echo "----------------------------------------------------"
echo "LazyVim and Ruff manual setup completed successfully!"
echo "----------------------------------------------------"
