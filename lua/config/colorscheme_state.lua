-- Last colorscheme picked in <leader>uC, remembered across restarts.
--
-- Before this, the startup scheme was the hardcoded string in plugins/theme.lua
-- (LazyVim opts.colorscheme), so every pick in the picker was thrown away on
-- quit and you landed back on storm. The picker now writes here on close and
-- theme.lua reads here at startup, falling back to the hardcoded default when
-- the file is missing or names a scheme that no longer loads.
--
-- Deliberately in stdpath("state"), not the config dir: it is session residue,
-- not configuration, and it must not show up as a dirty file in the repo.

local M = {}

M.path = vim.fn.stdpath("state") .. "/last-colorscheme.txt"

function M.read()
  local ok, lines = pcall(vim.fn.readfile, M.path)
  if not ok or type(lines) ~= "table" then
    return nil
  end
  local name = vim.trim(lines[1] or "")
  return name ~= "" and name or nil
end

-- The scheme that was current BEFORE the one in M.path, so :ThemeBack can swap
-- straight back to it. Written only when the current name actually changes, so
-- a picker close that kept the same theme never destroys the swap target.
M.prev_path = vim.fn.stdpath("state") .. "/prev-colorscheme.txt"

function M.previous()
  local ok, lines = pcall(vim.fn.readfile, M.prev_path)
  if not ok or type(lines) ~= "table" then
    return nil
  end
  local name = vim.trim(lines[1] or "")
  return name ~= "" and name or nil
end

function M.write(name)
  if type(name) ~= "string" or name == "" then
    return
  end
  local current = M.read()
  if current == name then
    return -- avoid a write on every picker close
  end
  if current then
    pcall(vim.fn.writefile, { current }, M.prev_path)
  end
  pcall(vim.fn.writefile, { name }, M.path)
end

-- :ThemeRawLock persistence: a marker file whose existence means "boot with
-- vim.g.theme_raw = true". Same stdpath("state") reasoning as above — session
-- residue, never a dirty repo file. Content is irrelevant, only existence.
M.raw_lock_path = vim.fn.stdpath("state") .. "/theme-raw-lock"

function M.raw_locked()
  return vim.uv.fs_stat(M.raw_lock_path) ~= nil
end

function M.write_raw_lock(on)
  if on then
    pcall(vim.fn.writefile, {}, M.raw_lock_path)
  else
    pcall(vim.fn.delete, M.raw_lock_path)
  end
end

-- Knob-lock persistence: one file per lock, content is the locked value. Unlike
-- the session-only locks, a persisted lock survives a restart — needed for
-- :BgTransparencyLock, where booting unlocked means the first theme switch
-- slams an opaque bg behind a transparent terminal.
function M.knob_lock_path(name)
  return vim.fn.stdpath("state") .. "/theme-knob-lock-" .. name
end

function M.read_knob_lock(name)
  local ok, lines = pcall(vim.fn.readfile, M.knob_lock_path(name))
  if not ok or type(lines) ~= "table" then
    return nil
  end
  local v = vim.trim(lines[1] or "")
  return v ~= "" and v or nil
end

function M.write_knob_lock(name, value)
  if value then
    pcall(vim.fn.writefile, { value }, M.knob_lock_path(name))
  else
    pcall(vim.fn.delete, M.knob_lock_path(name))
  end
end

-- The scheme to boot with. `default` is theme.lua's hardcoded fallback; a saved
-- name only wins if it is still installed, so uninstalling a plugin can never
-- leave nvim starting on a scheme that errors out.
function M.startup(default)
  local saved = M.read()
  if not saved then
    return default
  end
  for _, name in ipairs(vim.fn.getcompletion("", "color")) do
    if name == saved then
      return saved
    end
  end
  -- Not in the rtp yet — lazy.nvim resolves unloaded plugins' colors/ dirs on
  -- :colorscheme, so trust the name if any installed plugin ships it.
  local ok, lazy = pcall(require, "lazy.core.util")
  if ok and lazy.get_unloaded_rtp then
    local paths = table.concat(lazy.get_unloaded_rtp(""), ",")
    for _, f in ipairs(vim.fn.globpath(paths, "colors/*", true, true)) do
      if vim.fn.fnamemodify(f, ":t:r") == saved then
        return saved
      end
    end
  end
  return default
end

return M
