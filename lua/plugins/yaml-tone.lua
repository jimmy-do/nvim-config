-- SCRATCH / TESTING ONLY.
--
-- One autocmd IS live at import time: a BufLeave handler (YamlToneRevert group,
-- ~line 114) that runs ThemeReload when leaving a yaml buffer — but only after
-- a tone command has marked the session dirty; it no-ops otherwise. Everything
-- else is inert until you run a command. Edit the hexes below, save, then run
-- :YamlTone to see them. That is the whole edit/see cycle.
--
-- ---------------------------------------------------------------------------
-- ONE-OFF TESTING (no file edit, no command -- just type it in nvim):
--
-- Recolour a single group live, right now, from the command line:
--   :hi @punctuation.delimiter.yaml guifg=#00e676   -- foreground (text)
--   :hi @string.yaml guibg=#1a1a1a                   -- background
--   :hi Comment guifg=#243745 gui=italic             -- fg + style
--
-- Lualine pills work the same way (see the section list further down):
--   :hi lualine_a_normal guifg=#080808 guibg=#00ff9f gui=bold  -- left mode pill
--   :hi lualine_z_normal guifg=#080808 guibg=#ff8c1a gui=bold  -- right pill
--
-- Colour ALL periods (fields, values, lists) except those in # comments, in
-- one shot, across every open yaml window:
--   :YamlPeriods            -- uses period_color below
--   :YamlPeriods #00e676    -- or pass a hex to override it live
--
-- Recolour the indent GUIDE LINE. The hue is yours; brightness/saturation are
-- always forced to max, so a dim hex still comes out fully lit:
--   :YamlGuide              -- uses scope_color below
--   :YamlGuide #ff0055      -- override the hue live
--
-- Inspect what a group is currently set to (no args = print it):
--   :hi @string.yaml
--
-- Find out which group is under the cursor (so you know what to :hi):
--   :Inspect            -- shows the highlight groups at the cursor
--
-- These live edits vanish on the next :ThemeReload or nvim restart -- same as
-- the :YamlTone / :LualineTone scratch commands below.
-- ---------------------------------------------------------------------------
--
-- When a set of values is good, tell me and I copy them into
-- theme_baseline_colors["base16-tokyo-night-terminal-storm"] in theme.lua,
-- which is what makes them the theme's real defaults (and keeps :FgAdjust,
-- :Sepia and the bg knobs working on them). Running :YamlTone stamps over
-- those knobs until the next :ThemeReload -- that is expected for testing.

local colors = {
  ["@property.yaml"] = "#49638f", -- nested fields (keys)
  ["YamlKeyD1"] = "#7aa2f7", -- document-root keys only
  ["@punctuation.delimiter.yaml"] = "#ff8c1a", -- colons, commas, periods
  ["@punctuation.special.yaml"] = "#ff8c1a", -- list dashes, anchors
  ["@punctuation.bracket"] = "#f7ff00", -- [] {}
  ["@string.yaml"] = "#00ffff", -- plain values (the catch-all)
  ["@comment"] = "#243745",
  ["Comment"] = "#243745",

  -- Value SHAPES. These are separate captures, defined in
  -- after/queries/yaml/highlights.scm -- a value only reaches one of these if
  -- its text matches that rule, otherwise it stays @string.yaml above. So if a
  -- hex here appears to do nothing, the value is not matching the pattern; run
  -- :Inspect on it to see which capture it actually got.
  ["@type.yaml"] = "#e0af68", -- Deployment, RollingUpdate, ClusterIP
  ["@constant.macro.yaml"] = "#f7768e", -- LOG_LEVEL, POSTGRES_HOST
  ["@string.special.image.yaml"] = "#bb9af7", -- registry.io/api:1.2.3
  ["@string.special.version.yaml"] = "#9ece6a", -- apps/v1, 1.2.3
  ["@string.special.url.yaml"] = "#73daca", -- https://, oci://
  ["@string.special.path.yaml"] = "#a9b1d6", -- /healthz, values.yaml
  -- Quantities (512Mi, 30s) deliberately have no entry: they inherit @number,
  -- so they track the number colour instead of being tunable separately.
}

-- Not a highlight group -- the indent scope line ("guide line") is drawn by its
-- own plugin, so it is set separately below. This is the single knob for the
-- vertical indent guide colour.
--
-- NOTE: whatever hex you put here is pushed to MAX contrast/brightness before
-- it's applied (see maximize() below), so the guide line is always the most
-- vivid version of the hue -- a dull hex still comes out fully lit. Only the
-- hue you pick matters; brightness/saturation are forced.
local scope_color = "#00ffff"

-- ---------------------------------------------------------------------------
-- Live-preview lifecycle: scratch tones should last only while you are IN a
-- yaml buffer. The tone commands below set GLOBAL highlight groups, so without
-- this they leak into every buffer and persist until :ThemeReload / restart.
--
-- We mark the session "dirty" whenever a tone command runs, and revert to the
-- theme's real defaults on BufLeave of a yaml buffer -- even after :w. Leave the
-- file, it snaps back; come back and re-run :YamlTone to preview again.
local tone_dirty = false

local function mark_dirty()
  tone_dirty = true
end

local function revert_to_theme_defaults()
  if not tone_dirty then
    return
  end
  tone_dirty = false
  -- Drop the window-local period overlay (matchadd) we added, in every window.
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    vim.api.nvim_win_call(win, function()
      for _, m in ipairs(vim.fn.getmatches()) do
        if m.group == "YamlTonePeriod" then
          pcall(vim.fn.matchdelete, m.id)
        end
      end
    end)
  end
  pcall(vim.api.nvim_del_augroup_by_name, "YamlTonePeriod")
  -- Restore the theme's real highlight values (:FgAdjust/:Sepia/bg knobs too).
  pcall(vim.cmd, "silent! ThemeReload")
end

vim.api.nvim_create_augroup("YamlToneRevert", { clear = true })
vim.api.nvim_create_autocmd("BufLeave", {
  group = "YamlToneRevert",
  callback = function()
    if vim.bo.filetype == "yaml" then
      revert_to_theme_defaults()
    end
  end,
})
-- ---------------------------------------------------------------------------

-- Force a hex to maximum brightness + saturation while keeping its hue, so the
-- guide line always reads at full contrast no matter how dim the input was.
-- Works in HSV: keep H, set S=1 and V=1 (the pure, fully-lit version of the
-- hue). #808080-ish greys have no hue, so they collapse toward white -- expected.
local function maximize(hex)
  local r, g, b = hex:match("^#?(%x%x)(%x%x)(%x%x)$")
  if not r then
    return hex -- not a plain 6-digit hex; hand it back untouched
  end
  r, g, b = tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255
  local max, min = math.max(r, g, b), math.min(r, g, b)
  local h
  local d = max - min
  if d == 0 then
    h = 0
  elseif max == r then
    h = ((g - b) / d) % 6
  elseif max == g then
    h = (b - r) / d + 2
  else
    h = (r - g) / d + 4
  end
  h = h * 60 -- hue in degrees
  -- Rebuild at S=1, V=1.
  local c = 1 -- chroma = V * S = 1
  local x = c * (1 - math.abs((h / 60) % 2 - 1))
  local rr, gg, bb = 0, 0, 0
  if h < 60 then
    rr, gg, bb = c, x, 0
  elseif h < 120 then
    rr, gg, bb = x, c, 0
  elseif h < 180 then
    rr, gg, bb = 0, c, x
  elseif h < 240 then
    rr, gg, bb = 0, x, c
  elseif h < 300 then
    rr, gg, bb = x, 0, c
  else
    rr, gg, bb = c, 0, x
  end
  return ("#%02x%02x%02x"):format(
    math.floor(rr * 255 + 0.5),
    math.floor(gg * 255 + 0.5),
    math.floor(bb * 255 + 0.5)
  )
end

-- The indent-guide highlight groups theme.lua drives -- same list so the scratch
-- matches what the real pipeline sets.
local guide_groups = {
  "SnacksIndentScope",
  "SnacksIndentChunk",
  "IblScope",
  "IndentBlanklineContextChar",
  "IndentBlanklineContextStart",
  "MiniIndentscopeSymbol",
  "BlinkIndentScope",
}

-- Apply the guide-line colour (maximized) to every guide group. Shared by
-- :YamlTone and the standalone :YamlGuide.
local function apply_guides(color)
  local lit = maximize(color)
  for _, group in ipairs(guide_groups) do
    pcall(vim.api.nvim_set_hl, 0, group, { fg = lit, nocombine = true })
  end
  return lit
end

-- :YamlGuide -> DELEGATES to :IndentColor, which is the mechanism that actually
-- owns the guide colour (indent-ladder.lua: persists to disk, sets
-- vim.g.indent_scope_color, and refresh_guide() re-derives the animation ramp).
--
-- The old scratch version here stamped SnacksIndentScope & co directly, which
-- lost every race: the ladder samples its colour once per animation (stale
-- until the next scope change), theme.lua re-pins those groups on delayed
-- timers after every theme apply, and this file's own BufLeave revert ran a
-- silent ThemeReload on top. It also force-maximized the hex, so dark colours
-- came out as the pure hue -- ":YamlGuide 000000" rendered RED. Exact hexes now
-- reach the screen, and dark ones are legal.
vim.api.nvim_create_user_command("YamlGuide", function(opts)
  vim.cmd("IndentColor " .. opts.args)
end, { nargs = "?", desc = "Alias for :IndentColor -- the real owner of the guide colour" })

-- Periods (the "." character) are NOT a treesitter node in YAML -- a dot inside
-- 1.2.3 or foo.bar is just part of the plain scalar / string text, so there's
-- no @capture to recolour like colons and commas get. The only way to tint the
-- character itself is a regex overlay (matchadd), which is what the block below
-- does. Set this to the same hex as @punctuation.delimiter.yaml above to make
-- periods match the delimiters. The overlay runs at a priority above
-- treesitter (so it actually shows) and skips periods inside `#` comments;
-- periods in fields, values and lists are coloured.
local period_color = "#ff8c1a"

-- Shared period overlay used by both :YamlTone and the standalone :YamlPeriods.
-- matchadd() is window-local, so we define the highlight group once, drop the
-- match into every yaml window that already exists, and set up an autocmd so
-- yaml windows opened later get it too.
local function apply_periods(color)
  pcall(vim.api.nvim_set_hl, 0, "YamlTonePeriod", { fg = color })

  local function add_period_match(win)
    vim.api.nvim_win_call(win, function()
      if vim.bo.filetype ~= "yaml" then
        return
      end
      -- Clear any YamlTonePeriod match we added before so re-running doesn't
      -- stack duplicates.
      for _, m in ipairs(vim.fn.getmatches()) do
        if m.group == "YamlTonePeriod" then
          pcall(vim.fn.matchdelete, m.id)
        end
      end
      -- Pattern: a period that is NOT preceded by a '#' earlier on the line.
      -- \v = very magic; (#.*)@<! = negative look-behind for a comment start,
      -- so dots inside `# comment text` are left alone while dots in fields,
      -- values and lists still match.
      --
      -- Priority 200 is the important bit: treesitter paints its captures at
      -- priority 100, so anything below that (matchadd defaults to 10) gets
      -- drawn over and appears to do nothing. 200 sits on top of treesitter.
      vim.fn.matchadd("YamlTonePeriod", "\\v(#.*)@<!\\.", 200)
    end)
  end

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    add_period_match(win)
  end

  vim.api.nvim_create_augroup("YamlTonePeriod", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = "YamlTonePeriod",
    pattern = "yaml",
    callback = function()
      add_period_match(vim.api.nvim_get_current_win())
    end,
  })
end

-- :YamlPeriods            -> colour all periods (except comments) with period_color
-- :YamlPeriods #00e676    -> same, but override the colour live for this call
vim.api.nvim_create_user_command("YamlPeriods", function(opts)
  local color = (opts.args ~= "" and opts.args) or period_color
  apply_periods(color)
  mark_dirty()
  vim.notify("YamlPeriods applied (" .. color .. ")")
end, { nargs = "?", desc = "Colour all yaml periods except those in comments" })

-- ---------------------------------------------------------------------------
-- Lualine status bar colours (the bar at the very bottom of nvim).
--
-- Same scratch philosophy as above: edit the hexes, save, run :LualineTone to
-- see them. Nothing fires on its own. :ThemeReload (or restarting nvim) puts
-- the theme's real lualine colours back.
--
-- `bg` is the coloured pill, `fg` is the text on top of it.
--   * mode  -> the far-LEFT pill (section a): NORMAL / INSERT / VISUAL / etc.
--              Each mode gets its own accent; that's the whole point of the pill.
--   * right -> the far-RIGHT pill (section z): location / percentage / clock.
--              One colour used across every mode.
local lualine_tone = {
  mode = {
    normal = { bg = "#00ff9f", fg = "#080808" },
    insert = { bg = "#00ffff", fg = "#080808" },
    visual = { bg = "#ff8c1a", fg = "#080808" },
    replace = { bg = "#ff2e88", fg = "#080808" },
    command = { bg = "#f7ff00", fg = "#080808" },
  },
  right = { bg = "#ff8c1a", fg = "#080808" },
}

vim.api.nvim_create_user_command("LualineTone", function()
  -- lualine names its highlight groups lualine_<section>_<mode>, e.g.
  -- lualine_a_normal, lualine_z_insert. Section a is the left mode pill, z is
  -- the right pill. We drive both here.
  local modes = { "normal", "insert", "visual", "replace", "command" }

  for mode, c in pairs(lualine_tone.mode) do
    local ok, err = pcall(vim.api.nvim_set_hl, 0, "lualine_a_" .. mode, {
      fg = c.fg,
      bg = c.bg,
      bold = true,
    })
    if not ok then
      -- Same reason YamlTone surfaces errors: a bad hex is otherwise a silent
      -- no-op that reads as "the change didn't work".
      vim.notify(("LualineTone: a_%s -> %s"):format(mode, err), vim.log.levels.ERROR)
    end
  end

  -- The right pill is one colour across every mode, so stamp lualine_z_<mode>
  -- for all of them with the single `right` value.
  for _, mode in ipairs(modes) do
    pcall(vim.api.nvim_set_hl, 0, "lualine_z_" .. mode, {
      fg = lualine_tone.right.fg,
      bg = lualine_tone.right.bg,
      bold = true,
    })
  end

  vim.notify("LualineTone applied (run :ThemeReload to get back to theme defaults)")
end, { desc = "Apply the scratch lualine status bar palette once" })

vim.api.nvim_create_user_command("YamlTone", function()
  for group, fg in pairs(colors) do
    local ok, err = pcall(vim.api.nvim_set_hl, 0, group, { fg = fg })
    if not ok then
      -- Surfaced rather than swallowed: a bad hex (5 digits, missing #) is
      -- otherwise a silent no-op that looks like "the change didn't work".
      vim.notify(("YamlTone: %s = %s -> %s"):format(group, fg, err), vim.log.levels.ERROR)
    end
  end

  -- Guide line (same one :YamlGuide runs standalone). Forced to max brightness.
  apply_guides(scope_color)

  -- Period overlay (same one :YamlPeriods runs standalone).
  apply_periods(period_color)

  mark_dirty()
  vim.notify("YamlTone applied (leave the yaml buffer to snap back to defaults)")
end, { desc = "Apply the scratch yaml tone palette once" })

return {}
