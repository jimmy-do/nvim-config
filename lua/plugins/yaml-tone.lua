-- SCRATCH / TESTING ONLY.
--
-- Nothing here fires on its own: no autocmds, no ThemeAdjusted listener, no
-- re-apply loop -- until you run :YamlTone once. Edit the hexes below, save,
-- then run :YamlTone to see them. That is the whole edit/see cycle.
--
-- When a set of values is good, tell me and I copy them into
-- theme_baseline_colors["base16-tokyo-night-terminal-storm"] in theme.lua,
-- which is what makes them the theme's real defaults (and keeps :FgAdjust,
-- :Sepia and the bg knobs working on them). Running :YamlTone stamps over
-- those knobs until the next :ThemeReload -- that is expected for testing.

-- Which theme to test the palette on. Type any colorscheme you currently have
-- installed here (`:colorscheme <Tab>` lists them). On :YamlTone this theme is
-- loaded FIRST, then the palette below is stamped on top of it -- so you can
-- see these exact colors across whatever theme you want to test against.
-- Leave it as "" (empty) to just stamp onto the theme you already have loaded.
local target_theme = ""

local colors = {
  -- keys / fields
  ["@property.yaml"] = "#00ffff", -- fields (keys)

  -- punctuation
  ["@punctuation.delimiter.yaml"] = "#ff8c1a", -- colons, commas
  ["@punctuation.special.yaml"] = "#ff9c1a", -- list dashes, anchors, aliases
  ["@punctuation.bracket"] = "#ff8c1a", -- [] {}
  ["@punctuation.delimiter"] = "#00ffff", -- periods/dots and other delimiters

  -- string values
  ["@string.yaml"] = "#95ff00", -- quoted + plain string values
  ["@string.escape.yaml"] = "#00ffff", -- \n \t etc. inside quoted strings

  -- NON-string scalar values (numbers, bools, null, dates, timestamps).
  -- Many YAML parsers tag these as plain scalars, so several groups are listed
  -- to cover whichever one your treesitter build actually emits.
  ["@number.yaml"] = "#ff9c1a", -- 42, 3.14
  ["@number"] = "#ff9c1a",
  ["@float.yaml"] = "#ff9c1a", -- 3.14 (some grammars split floats out)
  ["@boolean.yaml"] = "#ff9c1a", -- true / false / yes / no
  ["@boolean"] = "#ff9c1a",
  ["@constant.builtin.yaml"] = "#ff9c1a", -- null / ~
  ["@constant.yaml"] = "#ff9c1a",
  ["@type.yaml"] = "#ff9c1a", -- tags like !!str, !Ref

  -- comments
  ["@comment"] = "#243745",
  ["Comment"] = "#243745",
}

-- Not a highlight group -- the indent scope ("guidelines") line is drawn by its
-- own plugin, so it is set separately below.
--
-- Put ANY hex here. It is force-boosted to its maximum-contrast / maximum-
-- brightness form before it is applied (see max_contrast below), so the guide
-- line is always the brightest possible version of whatever hue you type.
local scope_color = "#00ffff"

-- Take a #rrggbb hex and return its maximum-brightness version: scale every
-- channel up until the brightest one hits 255, preserving the hue and relative
-- channel ratios. This is what makes the guide immune to :Sepia / :FgAdjust /
-- dimming -- those effects only ever *darken or tint* a color, and re-running
-- :YamlTone (or the autocmd below) re-stamps the maxed value on top, so the
-- guide can never end up dimmer than full brightness for its hue.
--   #008080 -> #00ffff   (teal   -> full cyan)
--   #806000 -> #ffbf00   (dim amber -> full amber)
--   #000000 -> #ffffff   (black has no hue, so max contrast = white)
local function max_contrast(hex)
  local r, g, b = hex:match("^#(%x%x)(%x%x)(%x%x)$")
  if not r then
    return hex -- not a 6-digit hex; leave it for the pcall to surface
  end
  r, g, b = tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
  local m = math.max(r, g, b)
  if m == 0 then
    return "#ffffff" -- pure black carries no hue; max contrast is white
  end
  local scale = 255 / m
  local function up(c)
    return math.min(255, math.floor(c * scale + 0.5))
  end
  return string.format("#%02x%02x%02x", up(r), up(g), up(b))
end

local scope_groups = {
  "SnacksIndentScope",
  "SnacksIndentChunk",
  "IblScope",
  "IndentBlanklineContextChar",
  "IndentBlanklineContextStart",
  "MiniIndentscopeSymbol",
  "BlinkIndentScope",
}

local function stamp_scope_guides()
  local maxed = max_contrast(scope_color)
  for _, group in ipairs(scope_groups) do
    -- nocombine so no blend/dim pass can average the guide toward the bg.
    pcall(vim.api.nvim_set_hl, 0, group, { fg = maxed, sp = maxed, nocombine = true })
  end
  return maxed
end

local guides_pinned = false

vim.api.nvim_create_user_command("YamlTone", function()
  -- Load the requested theme first so the palette below is stamped ON TOP of
  -- it. Wrapped in pcall so a typo'd/uninstalled name reports instead of erroring
  -- the whole command; the palette still applies to the current theme.
  if target_theme ~= "" and target_theme ~= (vim.g.colors_name or "") then
    local ok, err = pcall(vim.cmd.colorscheme, target_theme)
    if not ok then
      vim.notify(("YamlTone: colorscheme %s -> %s"):format(target_theme, err), vim.log.levels.ERROR)
    end
  end

  for group, fg in pairs(colors) do
    local ok, err = pcall(vim.api.nvim_set_hl, 0, group, { fg = fg })
    if not ok then
      -- Surfaced rather than swallowed: a bad hex (5 digits, missing #) is
      -- otherwise a silent no-op that looks like "the change didn't work".
      vim.notify(("YamlTone: %s = %s -> %s"):format(group, fg, err), vim.log.levels.ERROR)
    end
  end

  local maxed = stamp_scope_guides()

  -- Immunity: after any :Sepia / :FgAdjust / dim pass mutates the guide groups,
  -- the next common editor event re-pins them to the maxed value. Registered
  -- once, guarded so repeated :YamlTone runs do not stack duplicate autocmds.
  if not guides_pinned then
    guides_pinned = true
    vim.api.nvim_create_autocmd(
      { "ColorScheme", "WinEnter", "BufWinEnter", "CursorHold", "CursorHoldI" },
      { callback = stamp_scope_guides, desc = "Re-pin YamlTone guide line at max contrast" }
    )
  end

  vim.notify(("YamlTone applied (guide pinned to %s, run :ThemeReload to reset)"):format(maxed))
end, { desc = "Apply the scratch yaml tone palette once" })

return {}
