-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.clipboard = "unnamedplus"

-- How long nvim waits mid-chord to see if more keys are coming. LazyVim's
-- default 300ms is what makes ambiguous leader maps feel laggy; 150ms is still
-- plenty to finish a chord.
vim.opt.timeoutlen = 150

-- Keep 8 lines of context between the cursor and the top/bottom of the window.
-- LazyVim's default is 4, which still lets you land close enough to an edge that
-- you cannot see what is coming. This applies to EVERY movement -- <C-d>, search
-- hits, }, G -- so it covers what a <C-d>zz mapping would, without the forced
-- recenter (and without the pointless redraw at the file edges, where zz is a no-op).
-- Bump to 999 if you decide you want the cursor permanently pinned mid-screen.
vim.opt.scrolloff = 8

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

-- Picker menus hide the terminal cursor entirely, so Ghostty's trail/boom
-- shaders have nothing to smear while j/k walks a list. Lives here rather than
-- in autocmds.lua for two reasons: it belongs next to the guicursor block it
-- overrides, and autocmds.lua opens with a nvim_del_augroup_by_name that throws
-- if LazyVim's group is not up yet — anything appended there is hostage to it.
require("config.hidden_cursor").setup()

-- Use fzf-lua as LazyVim's main picker
vim.g.lazyvim_picker = "fzf"

-- Prefer project markers over LSP workspace roots for pickers.
-- Some language servers report $HOME as their root, which makes fzf scan the whole account.
vim.g.root_spec = { { ".git", "lua" }, "cwd" }

-- Remote-plugin providers, all off.
--
-- These are the legacy python/ruby/perl/node RPC hosts, needed only by plugins
-- that ship a :python3 or ruby script -- nothing in lazy-lock.json does. Left
-- enabled, nvim shells out to find an interpreter the first time a matching
-- ftplugin loads: opening a .py file spent 45ms of a 140ms startup inside
-- provider/python3.vim alone, purely to discover a host it then never used.
--
-- Symptom if one is ever actually needed: "E319: No 'python3' provider" (or the
-- equivalent) from a plugin command -- flip that single line back to re-enable.
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0
