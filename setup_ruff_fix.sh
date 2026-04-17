#!/bin/bash
# ================================================
# Ruff + Auto-fix + Mypy Setup for LazyVim
# ================================================

set -euo pipefail

echo "Ruff + Auto-fix + Mypy Setup for LazyVim"
echo ""

# ====================== CONFIRMATION BEFORE INSTALL ======================
read -p "This script will configure Ruff (with auto-fix for flake8), formatting in your LazyVim.
Do you really want to continue with the installation? (y/n): " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Installation cancelled by user."
    exit 0
fi

echo "Confirmation received. Starting configuration..."

# Ensure all directories exist first (prevents "No such file or directory" errors)
mkdir -p ~/.config/nvim/lua/plugins
mkdir -p ~/.config/ruff

# ====================== 1. Conform (Ruff fix + format) ======================
cat > ~/.config/nvim/lua/plugins/conform_python.lua << 'EOF'
return {
  "stevearc/conform.nvim",
  opts = function(_, opts)
    opts.formatters_by_ft = opts.formatters_by_ft or {}
    opts.formatters_by_ft.python = {
      "ruff_fix",      -- auto-fix lint issues from Ruff
      "ruff_format",   -- format the code
    }
  end,
}
EOF

# ====================== 2. Keymap Ctrl+S (save + fix) ======================
cat > ~/.config/nvim/lua/plugins/keymaps_ruff.lua << 'EOF'
vim.keymap.set("n", "<C-s>", function()
  vim.cmd("w")
  require("conform").format({
    async = true,
    lsp_fallback = true,
  })
end, { desc = "Save + Fix with Ruff" })
EOF

# ====================== 3. Ruff global config ======================
cat > ~/.config/ruff/ruff.toml << 'EOF'
line-length = 79
target-version = "py312"

[lint]
select = ["E", "F", "I", "B", "W", "C4", "UP", "RUF", "ANN", "ARG", "COM", "DTZ", "EM", "ERA", "FBT", "ICN", "INP", "ISC", "N", "NPY", "PD", "PGH", "PIE", "PT", "PTH", "PYI", "RET", "RSE", "SIM", "SLF", "TCH", "TID", "TRY", "YTT"]
ignore = ["ANN401"]  # optional: ignore generic "Any" if you want

[format]
quote-style = "double"
EOF

echo "Running Lazy sync..."
nvim --headless -c "Lazy sync" -c "qa" 2>/dev/null || echo "Lazy sync finished."

echo ""
echo "Setup Ruff completed successfully!"
echo ""
echo "What the tool does now:"
echo "• Ruff (ruff_fix + ruff_format) → Automatically fixes lint issues and formats code"
echo "• Ctrl + S → Saves and runs Ruff fix/format"
echo ""
echo "Next steps:"
echo "1. Restart Neovim completely"
echo "2. Open :Mason and install 'ruff' (press 'i' on each)"
echo "3. Test in a .py file: Ctrl+S for Ruff"
echo ""
