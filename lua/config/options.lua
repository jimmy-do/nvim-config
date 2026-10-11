-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.clipboard = "unnamedplus"

-- How long nvim waits mid-chord to see if more keys are coming. 150ms was too
-- tight: any pause mid-chord (or a burst where the keys land in separate reads)
-- aborted the sequence and the leader map silently did nothing. The stall this
-- was originally lowered to dodge is fixed properly in keymaps.lua by deleting
-- the ambiguous <leader>w prefixes, so a roomy value costs nothing.
vim.opt.timeoutlen = 400

-- Keep 8 lines of context between the cursor and the top/bottom of the window.
-- LazyVim's default is 4, which still lets you land close enough to an edge that
-- you cannot see what is coming. This applies to EVERY movement -- <C-d>, search
-- hits, }, G -- so it covers what a <C-d>zz mapping would, without the forced
-- recenter (and without the pointless redraw at the file edges, where zz is a no-op).
-- Bump to 999 if you decide you want the cursor permanently pinned mid-screen.
vim.opt.scrolloff = 8

-- Same idea horizontally: with wrap off, keep 8 columns visible past the
-- cursor when a long terraform/yaml line scrolls sideways, instead of pinning
-- the cursor to the screen edge.
vim.opt.sidescrolloff = 8

-- The BLOCK cursor never blinks. A thick block is already unmissable, and blinking
-- it just reads as flicker -- especially against Ghostty's cursor trail shader.
-- The thin/underline shapes (insert, replace) still blink, since a 25%-wide bar is
-- easy to lose on a busy line; that is what the blink is actually for.
--
-- Ghostty has its own `cursor-style-blink = true` in config.ghostty. Neovim's
-- guicursor WINS while nvim is focused, so a shape with no blink flag here stays
-- solid regardless of the Ghostty setting.
vim.opt.guicursor = {
  -- FloatTrailCursor on every shape: see lua/config/float_cursor.lua.
  "n-v-c-sm:block-FloatTrailCursor", -- normal/visual/command: solid block, no blink
  "i-ci-ve:ver25-blinkwait500-blinkon500-blinkoff500-FloatTrailCursor",
  "r-cr-o:hor20-blinkwait500-blinkon500-blinkoff500-FloatTrailCursor",
  "t:block-FloatTrailCursor", -- terminal: solid block too
}
-- Must run before hidden_cursor.setup() below captures guicursor as its fallback.
require("config.float_cursor").setup()

-- :ThemeRawLock — if the lock file exists, come up in raw mode before the
-- first colorscheme loads, so the pipeline never stamps anything to undo.
-- Options load before lazy startup, which is what makes this the right spot.
if require("config.colorscheme_state").raw_locked() then
  vim.g.theme_raw = true
end

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

-- Stale-swapfile triage. A hard kill (the 2026-08-12 accidental restart) leaves
-- swapfiles behind, and every later open of the same file nags with W325 even
-- though nothing else has it open. swapinfo() tells us whether the owning nvim
-- is still alive and whether the swap holds unsaved edits, so decide silently:
--   owner alive            -> leave v:swapchoice empty: real collision, do prompt
--   owner dead, no edits   -> delete the swap and open normally ("d")
--   owner dead, has edits  -> open anyway ("e") but say so; :recover still works
-- Lives in options.lua, not autocmds.lua: SwapExists must be registered before
-- the first file opens, and autocmds.lua only loads on VeryLazy.
vim.api.nvim_create_autocmd("SwapExists", {
  group = vim.api.nvim_create_augroup("jimmy_swap_triage", { clear = true }),
  callback = function()
    local swapname = vim.v.swapname
    local info = vim.fn.swapinfo(swapname)
    if info.error or (info.pid and info.pid > 0 and vim.uv.kill(info.pid, 0) == 0) then
      return -- unreadable swap or live owner: fall through to the normal prompt
    end
    if info.dirty == 0 then
      vim.v.swapchoice = "d"
    else
      vim.v.swapchoice = "e"
      vim.schedule(function()
        vim.notify("Swap from a dead nvim had unsaved edits (kept): " .. swapname .. " — :recover to inspect", vim.log.levels.WARN)
      end)
    end
  end,
})

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
