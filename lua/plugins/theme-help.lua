-- theme-help.lua — :ThemeHelp, the reference for the theme command surface.
--
-- ---------------------------------------------------------------------------
-- WHY THIS EXISTS
-- ---------------------------------------------------------------------------
-- There are ~60 theme commands. <leader>sC (fzf-lua Commands) lists them with
-- their `desc`, which is one line and, for every knob declared through
-- define_numeric_knob, a GENERATED line -- "<Name> (no argument reports the
-- current value)". That tells you the command exists and nothing else: not the
-- range, not the units, not what 50 means, not which of the three yaml key
-- knobs you actually want.
--
-- All of that is written down -- as comments in plugins/theme.lua, next to the
-- code. Which is the right place for it and the wrong place to read it from
-- while you are tuning a theme.
--
-- So this is the cheat sheet: what the knob moves, what its neutral value is,
-- and which ones write to disk. It is HAND-WRITTEN on purpose -- a reflection
-- dump over nvim_get_commands is what <leader>sC already gives you.
--
-- The staleness guard is the last section: every theme-family command that is
-- NOT documented here is listed automatically with its raw desc. A command
-- added later shows up there instead of silently going missing, so the file
-- being out of date is visible in the file itself.
--
-- Not a plugin spec -- returns {} like the other pure-config files under
-- plugins/. It only needs to run once at startup to define the command.

-- Sections render in this order. Text is deliberately terse: this is read while
-- you are mid-tune with the buffer open beside a yaml file.
local SECTIONS = {
  {
    title = "YAML KEY DEPTH LADDER",
    blurb = "Keys get their own colour per nesting level. Depth comes from counting"
      .. " block_mapping_pair ancestors (plugins/yaml-key-depth.lua), which is why"
      .. " list items cost a level exactly like the eye reads them. 8 rungs, deeper clamps to 8.",
    items = {
      { "YamlKeyDepth [on|off|toggle]", "Master switch. off = all 8 rungs on one colour (pre-ladder look). Bare reports the full ladder -- and so does every other yaml key tuning, after it applies." },
      { "YamlKeyDepthStep <0-100>", "ABSOLUTE lightness points between all 8 rungs. 1 = default (the ladder leans on sat + hue, not lightness). USABLE RANGE IS THEME-BOUND: a theme only has so much room between its key colour and its background, and past that the step compresses. Bare :YamlKeyDepth reports what it actually got. On a dark theme with a mid-lightness key colour the ceiling is around 7." },
      { "YamlKeyDepthSat <0-100>", "Saturation added per rung as depth grows. 100 = default, 0 = OFF (lightness-only). Multiplicative, so a grey theme stays grey. On a desaturated theme this is the knob with real range left -- lightness runs out of headroom long before saturation does. Try 20-30 before concluding the ladder is weak." },
      { "YamlKeyDepthHue <-60..60>", "Signed degrees of hue walk per rung. -15 = default, 0 = OFF. Positive walks one way round the wheel, negative the other. Composes with step/sat: hue never touches S or L. Try 12-18 for a subtle spiral, 25+ for a loud one. Depth 1 NEVER rotates -- the theme's key colour stays the anchor." },
      { "YamlKeyDepthHueMode [spiral|anchor|crest|plunge|pendulum]", "How the degrees are spent. spiral = linear walk round the wheel. anchor = depth 1 native + ONE fixed jump for everything deeper (try hue 40-60). crest = same total sweep as spiral but spent at depths 2-3 where files actually live, tapering deeper -- the fix for 'the spiral only shows deep down'. plunge (default) = the mirror: calm until depth 4, then accelerates. pendulum = rungs alternate opposite sides of the wheel, growing per level -- hardest adjacent-level separation, but hue stops meaning 'deeper' (try 10-15, it doubles the visual gap)." },
      { "YamlKeyDepthFit [on|off|toggle]", "Stretch the 8 rungs across the depth THIS file actually reaches, so a 3-deep file uses the whole ladder instead of its top third. Off by default: it makes colour a RELATIVE signal, so the same key is a different colour in two files. Bare reports the current buffer's measured depth." },
      { "", "Rung spacing is perceptual (equal Lab dE), not equal HSL lightness -- equal L steps do not look equal, which is why the deep end used to go mushy while the top looked fine." },
    },
  },
  {
    title = "YAML KEY LOOK (what keys are, not how depth is shown)",
    items = {
      { "YamlKeyColor <#hex | r g b | native>", "Replace the ramp's BASE colour. The depth rungs still apply on top. Theme-scoped: it is discarded if you switch themes." },
      { "YamlKeyBrightness <0-100>", "HSL L of the rungs, applied AFTER the ramp. 50 = ramp output as-is. Hue and saturation pinned." },
      { "YamlKeyBold [on|none|default]", "default = toplevel rung only. The rungs are nocombine, so this is the only thing that decides key weight." },
    },
  },
  {
    title = "YAML VALUES / PUNCTUATION",
    items = {
      { "YamlValueBold [on|off|toggle]", "Bold every value, never the keys. Survives theme switches." },
      { "YamlValueBrightness <0-100>", "HSL L of values only. 50 = pipeline output as-is." },
      { "YamlDelimColor <#hex|native>", "The colons." },
      { "YamlDashColor <#hex|native>", "The list dashes." },
      { "YamlGuide", "Alias for :IndentColor (guide colour, exact hex, persists)." },
      { "YamlPeriods", "Colour every yaml period except in comments." },
      { "YamlExprRefresh", "Re-apply ${{ }} expression highlighting." },
      { "YamlTone", "Apply the scratch yaml tone palette once." },
    },
  },
  {
    title = "GLOBAL KNOBS (all 0-100, 50 = neutral, unless noted)",
    items = {
      { "Sepia <-100..100>", "Bipolar warm/cool. 0 = off, positive = warm, negative = cools past neutral." },
      { "FgLightness / FgSaturation <0-100>", "Foreground HSL. Comments are immune by design." },
      { "FgAdjust <L> <S>", "Both at once." },
      { "CommentBrightness <0-100>", "Comments' dedicated dial -- the one knob allowed to touch them." },
      { "BgBase <#hex|r g b>", "The owned background base colour." },
      { "BgBrightness / BgContrast / BgTransparency / NormalizeBackground <0-100>", "Background pipeline. NormalizeBackground pulls bg hue toward neutral grey." },
      { "ChromeDarken <0-100>", "0 = black, 50 = theme default, 100 = transparent." },
      {
        "GruvboxRed/Orange/Yellow/Green/Fg1",
        "gruvbox only. DragonBracketLightness = kanagawa-dragon only. RetroboxStringLightness = retrobox only.",
        covers = { "GruvboxRed", "GruvboxOrange", "GruvboxYellow", "GruvboxGreen", "GruvboxFg1" },
      },
    },
  },
  {
    title = "SINGLE GROUPS (:HlColor family)",
    items = {
      { "HlColor <#hex|native>", "Recolour the group under the cursor. Live session only." },
      { "HlColorGroup <group> <#hex|native>", "Same, named explicitly." },
      { "HlColorList / HlColorClear", "Live overrides: show / drop." },
      { "HlColorSave", "WRITES theme_baseline_saved.lua -- colours only." },
      { "HlColorSaved / HlColorForget <group|all>", "On-disk colours: show / remove." },
      { "HlColorRewind [n]", "Restore the nth-last save of the colour file (1 = before last save)." },
    },
  },
  {
    title = "SAVING (the two files that make a theme survive a restart)",
    blurb = "Colours and knobs are stored separately and merge back in different places."
      .. " :ThemeConfigSave writes BOTH, so it is the one command that makes the whole look permanent.",
    items = {
      { "ThemeConfigSave", "WRITES both files for the current theme: every knob -> theme_config_saved.lua, plus every live :HlColor override -> theme_baseline_saved.lua. Refuses while :ThemeRaw is on, because the knobs are not live then and what you would save is not what you are looking at." },
      { "ThemeConfigSaved", "The saved knobs, with anything that has drifted since flagged against the live value." },
      { "ThemeConfigForget", "Drop this theme's saved knobs. Colours are left alone -- :HlColorForget owns that side." },
      { "", "Restore order, in apply_knob_defaults: global defaults -> per-theme defaults -> saved config. Merged before the first pipeline pass, so nothing races it." },
    },
  },
  {
    title = "LOCKS (session-only, nothing is written to disk)",
    blurb = "A lock re-applies its knob 900ms after every ColorScheme -- after the 700ms"
      .. " deferred passes and the 800ms yaml startup stamp, or the re-apply is overwritten"
      .. " and reads as 'the lock did not work'. For something permanent use :ThemeConfigSave instead.",
    items = {
      {
        "<Knob>Lock <value> | off | (bare)",
        "Sepia, FgAdjust, CommentBrightness, BgTransparency, BgBase, BgBaseDefault, YamlKeyBrightness, YamlKeyColor, YamlKeyBold, YamlValueBrightness.",
        covers = {
          "SepiaLock",
          "FgAdjustLock",
          "CommentBrightnessLock",
          "BgTransparencyLock",
          "BgBaseLock",
          "BgBaseDefaultLock",
          "YamlKeyBrightnessLock",
          "YamlKeyColorLock",
          "YamlKeyBoldLock",
          "YamlValueBrightnessLock",
        },
      },
      { "ThemeRawLock", "One of the two exceptions: this one DOES persist across restarts until unlocked." },
      {
        "BgTransparencyLock",
        "The other exception: also persisted (stdpath state), because booting unlocked under a transparent terminal flashes an opaque bg on every theme switch.",
      },
    },
  },
  {
    title = "PIPELINE / PICKER",
    items = {
      { "ThemeAdjust", "Re-run the pipeline now." },
      { "ThemeReload", "Reload the colorscheme and recapture the pristine base. The escape hatch when a session's cache has drifted." },
      { "ThemeRaw [on|off|toggle]", "Bypass the ENTIRE pipeline: every theme renders bone-stock. Only the yaml capture wiring still runs." },
      { "ThemeFav / ThemeUnfav / ThemeBack", "Picker favourites; ThemeBack swaps to the previous colorscheme." },
    },
  },
}

-- Commands starting with one of these are considered part of the theme surface
-- for the undocumented-command sweep below.
local PREFIXES = {
  "Yaml",
  "Theme",
  "Hl",
  "Bg",
  "Fg",
  "Sepia",
  "Comment",
  "Gruvbox",
  "Dragon",
  "Retrobox",
  "Normalize",
  "Chrome",
}

local function is_theme_command(name)
  for _, p in ipairs(PREFIXES) do
    if name:sub(1, #p) == p then
      return true
    end
  end
  return false
end

-- A command counts as documented if its name appears in the section text, or if
-- an item claims it via `covers`. The claim list is what makes the grouped
-- entries honest: ":GruvboxRed/Orange/Yellow" and ":<Knob>Lock" document nine
-- and five real commands whose full names appear nowhere in the text, and
-- without `covers` the staleness sweep would list every one of them as missing
-- -- noise that trains you to ignore the section that is supposed to catch a
-- genuinely undocumented command.
--
-- ThemeHelp documents itself by definition; excluding it here keeps it from
-- being its own first complaint.
local function documented_names()
  local blob = { "ThemeHelp" }
  for _, section in ipairs(SECTIONS) do
    for _, item in ipairs(section.items) do
      table.insert(blob, item[1])
      table.insert(blob, item[2])
      for _, name in ipairs(item.covers or {}) do
        table.insert(blob, name)
      end
    end
  end
  return table.concat(blob, " ")
end

local function build_lines(filter)
  local lines = {}
  local function add(s)
    table.insert(lines, s)
  end

  add("# Theme commands")
  add("")
  add("Every knob reports its current value when called with no argument.")
  if filter and filter ~= "" then
    add("")
    add("Filtered by: " .. filter)
  end

  local needle = filter and filter ~= "" and filter:lower() or nil

  for _, section in ipairs(SECTIONS) do
    local matched = {}
    for _, item in ipairs(section.items) do
      if not needle or (item[1] .. " " .. item[2]):lower():find(needle, 1, true) then
        table.insert(matched, item)
      end
    end
    if #matched > 0 then
      add("")
      add("## " .. section.title)
      if section.blurb then
        add("")
        add(section.blurb)
      end
      add("")
      for _, item in ipairs(matched) do
        if item[1] == "" then
          add("  " .. item[2])
        else
          add("  :" .. item[1])
          add("      " .. item[2])
        end
      end
    end
  end

  -- Staleness guard: anything in the theme families that this file does not
  -- mention, straight from the command table with whatever desc it declared.
  local blob = documented_names()
  local missing = {}
  for name, def in pairs(vim.api.nvim_get_commands({})) do
    if is_theme_command(name) and not blob:find(name, 1, true) then
      if not needle or name:lower():find(needle, 1, true) then
        table.insert(missing, { name, def.definition or "" })
      end
    end
  end
  if #missing > 0 then
    table.sort(missing, function(a, b)
      return a[1] < b[1]
    end)
    add("")
    add("## NOT DOCUMENTED ABOVE (raw desc)")
    add("")
    for _, m in ipairs(missing) do
      add("  :" .. m[1])
      add("      " .. m[2])
    end
  end

  add("")
  return lines
end

vim.api.nvim_create_user_command("ThemeHelp", function(opts)
  local lines = build_lines(vim.trim(opts.args))

  -- Scratch buffer in a split, not a floating window: this is read side by side
  -- with the yaml file you are tuning against, and a float would cover it.
  vim.cmd("botright vsplit")
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "markdown"
  vim.wo.wrap = true
  vim.wo.linebreak = true
  vim.api.nvim_win_set_width(0, math.min(90, math.floor(vim.o.columns * 0.5)))
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, nowait = true })
end, {
  nargs = "?",
  desc = "Theme command reference (optional filter, e.g. :ThemeHelp yamlkey). q closes.",
})

return {}
