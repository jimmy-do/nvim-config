-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.clipboard = "unnamedplus"

-- Keep every Neovim cursor shape blinking. Neovim's defaults only blink the
-- terminal-mode cursor, which looks like a frozen cursor with Ghostty's trail.
vim.opt.guicursor = {
  "n-v-c-sm:block-blinkwait500-blinkon500-blinkoff500",
  "i-ci-ve:ver25-blinkwait500-blinkon500-blinkoff500",
  "r-cr-o:hor20-blinkwait500-blinkon500-blinkoff500",
  "t:block-blinkwait500-blinkon500-blinkoff500-TermCursor",
}

-- Use fzf-lua as LazyVim's main picker
vim.g.lazyvim_picker = "fzf"

-- Prefer project markers over LSP workspace roots for pickers.
-- Some language servers report $HOME as their root, which makes fzf scan the whole account.
vim.g.root_spec = { { ".git", "lua" }, "cwd" }
