-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Remove LazyVim's wrap+spell group, then re-add wrap-only (no spell checking)
vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = false
  end,
})

-- The `nvim <dir>` handling that used to live here moved to
-- lua/plugins/startup-session.lua, which restores that project's session first
-- and only falls back to the file picker when there is no session. It had to
-- move: the decision is shared with the bare-`nvim` path and with the spec-time
-- dashboard toggle, and all three have to agree.

-- Wiping the startup directory buffer above leaves an empty [No Name] behind:
-- wiping the last buffer makes Vim spawn a fresh empty one. Drop it once a real
-- file gets loaded.
vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("jimmy_kill_startup_scratch", { clear = true }),
  callback = function()
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      if
        vim.bo[b].buflisted
        and vim.api.nvim_buf_get_name(b) == ""
        and not vim.bo[b].modified
        and vim.api.nvim_buf_line_count(b) == 1
        and vim.api.nvim_buf_get_lines(b, 0, 1, false)[1] == ""
      then
        pcall(vim.api.nvim_buf_delete, b, {})
      end
    end
  end,
})

-- Copy-on-select: leaving visual mode yanks the selection to the system
-- clipboard, so highlighting is enough and `y` becomes optional.
--
-- ModeChanged with pattern "[vV\22]*:*" fires on every transition OUT of
-- visual/visual-line/visual-block (\22 is CTRL-V, the blockwise mode char).
-- The mode check inside is belt-and-braces for v -> V style switches, which
-- also match the pattern but are not really an exit.
--
-- `gv"+y` re-selects the range that was just abandoned -- by the time this
-- callback runs the selection is gone, so a bare "+y would yank nothing. The
-- `gv` restores it from the '< '> marks. The final `` `> `` parks the cursor at
-- the end of the selection, matching where vim leaves it after a normal yank.
--
-- Deliberately NOT guarded against operator use: `d`/`c` leave visual mode too,
-- but they exit through the operator, not through this transition, so a cut is
-- unaffected. What this DOES do is clobber the clipboard on throwaway
-- selections -- that is the trade being made here, not a bug.
vim.api.nvim_create_autocmd("ModeChanged", {
  group = vim.api.nvim_create_augroup("jimmy_copy_on_select", { clear = true }),
  pattern = "[vV\22]*:*",
  callback = function()
    if vim.fn.mode():match("^[vV\22]") then
      return
    end
    pcall(vim.cmd, 'normal! gv"+y`>')
  end,
})

-- Bound the exit path: `:qa` once left an nvim spinning at 100% CPU for 36
-- minutes inside libuv's loop teardown. See lua/config/exit_watchdog.lua.
require("config.exit_watchdog")
