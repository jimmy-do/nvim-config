-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.clipboard = "unnamedplus"
-- Use fzf-lua as LazyVim's main picker
vim.g.lazyvim_picker = "fzf"

-- Prefer project markers over LSP workspace roots for pickers.
-- Some language servers report $HOME as their root, which makes fzf scan the whole account.
vim.g.root_spec = { { ".git", "lua" }, "cwd" }
