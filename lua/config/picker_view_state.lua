-- <leader>uC's grouping + filters, remembered across restarts.
--
-- Same reasoning as colorscheme_state.lua next door: session residue, not
-- configuration, so it lives in stdpath("state") and never shows up as a dirty
-- file in the repo. Written on every change (there are only ever ~5 keys here, so
-- the write is trivial) rather than on close, because the picker can also go away
-- via WinLeave or a buffer wipe.
--
-- Unknown or corrupt values are dropped rather than repaired: a bad file must not
-- be able to filter the list down to nothing with no way to see why.

local M = {}

M.path = vim.fn.stdpath("state") .. "/uC-picker-view.json"

-- The allowed values for each key, so nothing here can survive a rename in the
-- picker and silently hide half the list.
local schema = {
  group_mode = { glow = true, bg = true, base16 = true, keys = true, flat = true },
  bg_filter = { all = true, dark = true, light = true },
  base16_filter = { all = true, only = true, never = true },
  glow_filter = { all = true, loud = true, neon = true },
  colored_keys_only = "boolean",
  favorites_only = "boolean",
}

function M.read()
  local ok, lines = pcall(vim.fn.readfile, M.path)
  if not ok or type(lines) ~= "table" or #lines == 0 then
    return {}
  end
  local decoded_ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not decoded_ok or type(decoded) ~= "table" then
    return {}
  end

  local out = {}
  for key, allowed in pairs(schema) do
    local value = decoded[key]
    if allowed == "boolean" then
      if type(value) == "boolean" then
        out[key] = value
      end
    elseif type(value) == "string" and allowed[value] then
      out[key] = value
    end
  end
  return out
end

function M.write(state)
  local out = {}
  for key, allowed in pairs(schema) do
    local value = state[key]
    if allowed == "boolean" then
      if type(value) == "boolean" then
        out[key] = value
      end
    elseif type(value) == "string" and allowed[value] then
      out[key] = value
    end
  end
  local ok, encoded = pcall(vim.json.encode, out)
  if ok then
    pcall(vim.fn.writefile, { encoded }, M.path)
  end
end

return M
