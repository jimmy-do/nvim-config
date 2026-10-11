-- Tag the cursor while it sits in a floating window (or the cmdline popup).
--
-- WHY: Ghostty's cursor_tail shader trails every cursor jump, and a float
-- opening is a jump from wherever the cursor happened to be -- the comet flies
-- in from an arbitrary spot. The shader cannot see windows, but it CAN see the
-- cursor colour, so floats tag it: #c4fff4 inside a float, an invisible 4/255
-- off Ghostty's cursor-color (#c8fff4). The shader drops the trail on any jump
-- whose colour changed, i.e. one that crossed a float boundary. The tmux float
-- does the same with cursor-colour (dotfiles/tmux/floax-toggle).
--
-- HOW: every guicursor entry in options.lua names the FloatTrailCursor group.
-- `reverse` makes Neovim's TUI reset the cursor to the terminal's own colour;
-- a real bg makes it send that colour. So only the group changes, never
-- guicursor itself -- hidden_cursor.lua owns that and refcounts it.

local M = {}

local GROUP = "FloatTrailCursor"
local TAGGED = { bg = "#c4fff4", fg = "#151515" }
local PLAIN = { reverse = true }

local tagged = nil

local function in_float()
  if vim.fn.mode():sub(1, 1) == "c" then
    return true
  end
  local ok, cfg = pcall(vim.api.nvim_win_get_config, 0)
  return ok and cfg.relative ~= nil and cfg.relative ~= ""
end

local function sync(force)
  local want = in_float()
  if want == tagged and not force then
    return
  end
  tagged = want
  vim.api.nvim_set_hl(0, GROUP, want and TAGGED or PLAIN)
end

function M.setup()
  sync(true)
  local group = vim.api.nvim_create_augroup("jimmy_float_cursor", { clear = true })
  -- Wide net on purpose: plenty of floats open with noautocmd, so WinEnter
  -- alone misses them. sync() is one mode() + one win_get_config when idle.
  vim.api.nvim_create_autocmd({
    "WinEnter",
    "WinLeave",
    "WinClosed",
    "BufEnter",
    "CursorMoved",
    "CursorMovedI",
    "ModeChanged",
    "CmdlineEnter",
    "CmdlineLeave",
    "TermEnter",
  }, {
    group = group,
    callback = function()
      sync(false)
    end,
  })
  -- A colorscheme clears the group; an empty group would make the TUI send a
  -- junk colour, so restamp it straight away.
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      sync(true)
    end,
  })
end

return M
