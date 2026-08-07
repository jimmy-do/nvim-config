-- headless: for every installed colorscheme, record the facets the picker groups by
-- and write lua/config/theme_facets.lua directly (no scoring step -- unlike the
-- glow tiers there is no shader formula to transcribe here).
--
--   nvim --headless -c "lua vim.defer_fn(function() dofile(vim.fn.expand('~/.config/nvim/dotfiles/tools/theme-facets-measure.lua')) end, 3000)"
--
-- Two things make this slow and neither is optional:
--
--   * theme.lua DERIVES the yaml key colour per theme (derive_yaml_baseline ->
--     apply_yaml_key_ramp) on deferred passes out to ~900ms after ColorScheme.
--     Reading @amlKeyD2 any earlier gets the previous theme's key,
--     or nothing. So each theme gets a full settle wait.
--   * 'background' has to be set to match the theme before loading it, same as
--     the picker's apply_scheme, or half the base16 family resolves against the
--     wrong variant and the measured bg is a lie.
--
-- ~1s x ~320 themes, so budget five minutes.

local settle_ms = 950

local light_markers = { "light", "day", "dawn", "latte", "morning", "lotus", "white" }

local function name_looks_light(name)
  local n = name:lower()
  for _, marker in ipairs(light_markers) do
    if n:find(marker, 1, true) then
      return true
    end
  end
  return false
end

local function hex(n)
  return n and string.format("#%06x", n) or nil
end

local function fg_of(...)
  for _, group in ipairs({ ... }) do
    local ok, h = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
    if ok and type(h) == "table" and h.fg then
      return hex(h.fg)
    end
  end
  return nil
end

local function bg_of(...)
  for _, group in ipairs({ ... }) do
    local ok, h = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
    if ok and type(h) == "table" and h.bg then
      return hex(h.bg)
    end
  end
  return nil
end

local function rgb(h)
  return tonumber(h:sub(2, 3), 16) / 255, tonumber(h:sub(4, 5), 16) / 255, tonumber(h:sub(6, 7), 16) / 255
end

-- Perceptual-ish luminance, good enough to split light from dark backgrounds.
local function luma(h)
  local r, g, b = rgb(h)
  return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

-- HSV saturation on the same (max-min)/max basis the glow scorer uses, so
-- "colourless" here means the same thing it means there.
local function sat(h)
  local r, g, b = rgb(h)
  local mx, mn = math.max(r, g, b), math.min(r, g, b)
  return mx <= 0 and 0 or (mx - mn) / mx
end

local function hue_deg(h)
  local r, g, b = rgb(h)
  local mx, mn = math.max(r, g, b), math.min(r, g, b)
  local d = mx - mn
  if d < 1e-6 then
    return 0
  end
  local x
  if mx == r then
    x = ((g - b) / d) % 6
  elseif mx == g then
    x = (b - r) / d + 2
  else
    x = (r - g) / d + 4
  end
  return (x * 60) % 360
end

-- Hue families, named the way the eye names them rather than by even 45° slices.
local families = {
  { "red", 345, 15 },
  { "orange", 15, 45 },
  { "yellow", 45, 70 },
  { "green", 70, 165 },
  { "cyan", 165, 200 },
  { "blue", 200, 255 },
  { "purple", 255, 290 },
  { "magenta", 290, 345 },
}

local function family(h)
  local deg = hue_deg(h)
  for _, f in ipairs(families) do
    local lo, hi = f[2], f[3]
    if lo > hi then -- red wraps 345..15
      if deg >= lo or deg < hi then
        return f[1]
      end
    elseif deg >= lo and deg < hi then
      return f[1]
    end
  end
  return "red"
end

-- The question is "are the yaml keys just white". Two ways a key reads as
-- colourless: it has almost no saturation of its own, or it is simply the
-- normal foreground with nothing done to it.
local function key_class(key, normal_fg)
  if not key then
    return "unknown"
  end
  local s = sat(key)
  if s < 0.10 then
    return luma(key) > 0.72 and "white" or "grey"
  end
  if s < 0.20 then
    return "tinted"
  end
  if normal_fg and key:lower() == normal_fg:lower() then
    return "white"
  end
  return family(key)
end

local colors = vim.fn.getcompletion("", "color")
local lazy = package.loaded["lazy.core.util"]
if lazy and lazy.get_unloaded_rtp then
  local paths = lazy.get_unloaded_rtp("")
  for _, f in ipairs(vim.fn.globpath(table.concat(paths, ","), "colors/*", true, true)) do
    table.insert(colors, vim.fn.fnamemodify(f, ":t:r"))
  end
end

local seen, queue = {}, {}
for _, name in ipairs(colors) do
  if not seen[name] then
    seen[name] = true
    table.insert(queue, name)
  end
end
table.sort(queue)

local out = {}
local index = 0

local function write_file()
  -- Write to a temp file and move it into place at the very end. The sweep takes
  -- ~10 minutes, and for that whole window an interactive nvim is still reading
  -- theme_facets.lua: deleting or truncating it first leaves every theme's key
  -- class "unknown", which made the picker's coloured-keys filter hide all 538
  -- entries mid-session (2026-07-29). Regeneration must be invisible to a running
  -- editor -- never remove the old file before the new one exists.
  local path = vim.fn.expand("~/.config/nvim/lua/config/theme_facets.lua")
  local tmp = path .. ".new"
  local f = assert(io.open(tmp, "w"))
  f:write([[-- GENERATED by dotfiles/tools/theme-facets-measure.lua. Do not hand-edit.
--
-- One row per installed colorscheme, holding the facets <leader>uC's grouping
-- menu sorts by. Everything here is MEASURED from a real load of the theme with
-- theme.lua's full pipeline settled -- not guessed from the name:
--
--   light  true when the Normal background is actually light. Beats the old
--          name-marker guess: several base16 "-light" names are dark and some
--          light schemes say nothing in their name at all.
--   bg     the measured Normal background hex.
--   key    the yaml KEY colour theme.lua derives for this theme
--          (YamlKeyD2, i.e. the second rung of the eight-rung key ramp).
--   class  what that key reads as: white / grey / tinted, or a hue family
--          (red orange yellow green cyan blue purple magenta). "white" and
--          "grey" are the answer to "are the keys just white".
--
-- Regenerate after any change to derive_yaml_baseline / apply_yaml_key_ramp in
-- theme.lua, or after installing colorschemes:
--   nvim --headless -c "lua vim.defer_fn(function() dofile(vim.fn.expand('~/.config/nvim/dotfiles/tools/theme-facets-measure.lua')) end, 3000)"

return {
]])
  for _, name in ipairs(queue) do
    local e = out[name]
    if e then
      f:write(
        string.format(
          "  [%s] = { light = %s, bg = %s, key = %s, class = %q },\n",
          string.format("%q", name),
          e.light and "true" or "false",
          e.bg and string.format("%q", e.bg) or "nil",
          e.key and string.format("%q", e.key) or "nil",
          e.class
        )
      )
    end
  end
  f:write("}\n")
  f:close()
  assert(vim.uv.fs_rename(tmp, path))
  io.stderr:write(string.format("%d colorschemes -> %s\n", vim.tbl_count(out), path))
end

local function step()
  index = index + 1
  local name = queue[index]
  if not name then
    write_file()
    vim.cmd("qa!")
    return
  end

  -- Same background dance as the picker's apply_scheme: set it from the name
  -- first (that is all we know pre-load), measure the truth afterwards.
  local want = name_looks_light(name) and "light" or "dark"
  if vim.o.background ~= want then
    pcall(vim.cmd, "noautocmd set background=" .. want)
  end
  -- TWO loads per theme, in this order, and both are needed.
  --
  -- The ordinary load first: it fires the ColorScheme pipeline that derives the
  -- yaml key colour, and it is also what makes lazy.nvim put the theme's plugin on
  -- the rtp in the first place.
  if not pcall(vim.cmd.colorscheme, name) then
    return step()
  end

  vim.defer_fn(function()
    local normal_fg = fg_of("Normal")
    local key = fg_of("YamlKeyD2", "@property.yaml", "@property", "@variable.member", "Identifier")

    -- Then a `noautocmd` reload for the NATIVE background. theme.lua pins Normal
    -- bg to Jimmy's own colour synchronously inside its ColorScheme handler, so
    -- there is no window after a normal load in which the theme's own bg is still
    -- readable -- measuring it that way returned #0f0f0f for all 558 themes.
    -- Suppressing the event is the only way to see it, and it has to happen AFTER
    -- the normal load or lazy-loaded schemes (ayu-light, tokyonight-day) simply
    -- fail to load at all.
    local bg = nil
    if pcall(vim.cmd, "noautocmd colorscheme " .. vim.fn.fnameescape(name)) then
      bg = bg_of("Normal", "NormalFloat")
    end

    out[name] = {
      -- Measured bg wins; only a theme that never set Normal bg falls back to
      -- what the name marker made us load it under.
      light = bg ~= nil and luma(bg) > 0.5 or (bg == nil and vim.o.background == "light"),
      bg = bg,
      key = key,
      class = key_class(key, normal_fg),
    }
    io.stderr:write(string.format("%d/%d %s\n", index, #queue, name))
    step()
  end, settle_ms)
end

step()
