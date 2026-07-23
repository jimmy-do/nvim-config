-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.clipboard = "unnamedplus"

-- The BLOCK cursor never blinks. A thick block is already unmissable, and blinking
-- it just reads as flicker -- especially against Ghostty's cursor trail shader.
-- The thin/underline shapes (insert, replace) still blink, since a 25%-wide bar is
-- easy to lose on a busy line; that is what the blink is actually for.
--
-- Ghostty has its own `cursor-style-blink = true` in config.ghostty. Neovim's
-- guicursor WINS while nvim is focused, so a shape with no blink flag here stays
-- solid regardless of the Ghostty setting.
vim.opt.guicursor = {
  "n-v-c-sm:block", -- normal/visual/command: solid block, no blink
  "i-ci-ve:ver25-blinkwait500-blinkon500-blinkoff500",
  "r-cr-o:hor20-blinkwait500-blinkon500-blinkoff500",
  "t:block-TermCursor", -- terminal: solid block too
}

-- Use fzf-lua as LazyVim's main picker
vim.g.lazyvim_picker = "fzf"

-- Prefer project markers over LSP workspace roots for pickers.
-- Some language servers report $HOME as their root, which makes fzf scan the whole account.
vim.g.root_spec = { { ".git", "lua" }, "cwd" }
