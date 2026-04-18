#!/bin/bash

set -euo pipefail

read -p "Configure Ruff + Auto-fix + Mypy for LazyVim? (y/n): " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  exit 0
fi

mkdir -p ~/.config/nvim/lua/plugins
mkdir -p ~/.config/ruff

cat >~/.config/nvim/lua/plugins/conform_python.lua <<'EOF'
return {
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
EOF

cat >~/.config/ruff/ruff.toml <<'EOF'
line-length = 79
target-version = "py312"

[lint]
select = ["E", "F", "I", "B", "W", "C4", "UP", "RUF", "ANN", "ARG", "COM", "DTZ", "EM", "ERA", "FBT", "ICN", "INP", "ISC", "N", "NPY", "PD", "PGH", "PIE", "PT", "PTH", "PYI", "RET", "RSE", "SIM", "SLF", "TCH", "TID", "TRY", "YTT"]
ignore = ["ANN401"]

[format]
quote-style = "double"
indent-style = "space"
skip-magic-trailing-comma = false
line-ending = "lf"
EOF

nvim --headless -c "Lazy sync" -c "qa" 2>/dev/null || true

echo "Setup completed successfully."
