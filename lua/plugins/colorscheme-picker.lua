-- <leader>uC / <leader>th — colorscheme picker. Scroll the list; typing jumps,
-- never filters.
--
-- LazyVim's fzf extra binds this to `FzfLua.colorschemes`, which is a fuzzy
-- filter: typing throws away every non-matching row, so there is nothing left to
-- scroll and it is useless when you don't yet know what you want. This is a plain
-- scratch buffer holding every scheme, always. Nothing is ever hidden by typing —
-- a search just moves the cursor, and the rest of the list is still there to keep
-- scrolling through.
--
--   j / k / <C-d> / <C-u> / gg / G   scroll, theme previews live as you go
--   <C-j> / <C-k>                    5 rows at a time. These are window
--                                    navigation everywhere else, and a stray one
--                                    used to move focus out of the float, which
--                                    closed the picker — in here they just scroll.
--   s                                incremental FUZZY jump. Type "ever li med"
--                                    and the cursor lands on
--                                    base16-everforest-light-medium as you type.
--                                    <Tab>/<S-Tab> cycle matches, <CR> stays put
--                                    with the whole list still under you.
--   /name <CR>, n, N                 plain vim search, same jump-not-filter deal
--   f                                toggle favorite — rewrites the list below,
--                                    so it sticks across restarts. Outside the
--                                    picker, :ThemeFav / :ThemeUnfav do the same
--                                    for the theme you are currently in.
--   m                                the CATEGORIES menu (also advertised in the
--                                    float's footer). Picks what the list is
--                                    GROUPED by — yaml-value glow / light vs dark
--                                    / base16 vs not / yaml KEY colour / flat A-Z
--                                    — and flips four FILTERS that all stack:
--                                    light-vs-dark, base16, coloured yaml keys,
--                                    and yaml-value glow. "dark only + keys with
--                                    a colour + values that burn" is three of them
--                                    at once, which is the point.
--                                    j/k + <CR>, or press the digit / letter shown
--                                    on the row. None of those letters is j or k.
--                                    Grouping and filters PERSIST across restarts
--                                    (lua/config/picker_view_state.lua).
--   T                                jump straight back and forth between the
--                                    current grouping and flat A-Z.
--   <CR> / q / <Esc> / :q            keep the theme under the cursor and close
--   <C-c>                            cancel: restore the theme active on open
--
-- The title is the position readout: `colorscheme  12/318`.

-- Order here is the order they appear at the top of the list. `f` in the picker
-- and :ThemeFav / :ThemeUnfav add/remove single lines here, so hand-edits and
-- comments survive a toggle.
--
-- Emptied 2026-07-28 at Jimmy's request. Kept as a two-line block rather than
-- `{}`: persist_favorite() below finds this block by matching `local favorites =
-- {` on its own line and a bare `}`, so collapsing it breaks every toggle.
local favorites = {
  "base16-hardhacker",
  "moonlightv3",
  "moonlightv4",
}

-- This file's own path, captured at load time so `f` can rewrite the block above.
local self_path = debug.getinfo(1, "S").source:sub(2)

-- Applying a scheme kicks off theme.lua's pipeline (deferred passes out to
-- 800ms), so previewing on every cursor step while scrolling would pile up.
-- Only fire once the cursor has been still this long.
local preview_debounce_ms = 120

-- Vim's shipped-since-1995 colorschemes: never going to be picked, and they pad
-- the list by ~25 entries. retrobox is deliberately absent — it is a builtin, but
-- it is one that gets used (theme.lua carries retrobox-specific tuning).
local builtin_junk = {
  blue = true,
  darkblue = true,
  default = true,
  delek = true,
  desert = true,
  elflord = true,
  evening = true,
  habamax = true,
  industry = true,
  koehler = true,
  lunaperche = true,
  morning = true,
  murphy = true,
  pablo = true,
  peachpuff = true,
  quiet = true,
  ron = true,
  shine = true,
  slate = true,
  sorbet = true,
  torte = true,
  unokai = true,
  vim = true,
  wildcharm = true,
  zaibatsu = true,
  zellner = true,
}

-- Name markers, the ONLY thing known about a theme before it is loaded, so
-- apply_scheme uses them to choose 'background'. For deciding whether a theme is
-- actually light, is_light_theme() below prefers the measured facets instead.
local light_markers = { "light", "day", "dawn", "latte", "morning", "lotus", "white" }

local function is_light(name)
  local n = name:lower()
  for _, marker in ipairs(light_markers) do
    if n:find(marker, 1, true) then
      return true
    end
  end
  return false
end

-- Score `name` against a fuzzy query. Query is split on spaces/dashes/underscores
-- and every token must appear, in order — so "ever li med" finds
-- base16-everforest-light-medium but not base16-everforest-dark-medium. Lower is
-- better: earlier matches and shorter names win.
local function fuzzy_score(name, query)
  local haystack = name:lower()
  local pos, score = 1, 0
  for token in query:lower():gmatch("[^%s%-_]+") do
    local from, to = haystack:find(token, pos, true)
    if not from then
      return nil
    end
    score = score + from
    pos = to + 1
  end
  return score + #name * 0.01
end

-- Border footer, so the menu is findable without having read this file.
local footer_hint = " m categories · s jump · f fav "

local favorites_header = "── favorites ──"
local others_header = "── all colorschemes ──"

-- Glow tiers. Every scheme is pre-scored by how hard its YAML VALUES (strings,
-- numbers, booleans, enums, images, urls -- NOT the field/property names) glow
-- under the ghostty neon bloom, so the list can be walked by "how loud do values
-- burn" instead of alphabetically. See lua/config/glow_tiers.lua for the formula
-- and dotfiles/tools/glow-tiers-*.{lua,py} to regenerate after a shader retune.
local glow_tiers = (function()
  local ok, t = pcall(require, "config.glow_tiers")
  return ok and t or {}
end)()

-- Order is the order the groups appear in the list: loudest first.
local glow_order = {
  { key = "neon", label = "── glow: NEON  (values burn) ──" },
  { key = "bright", label = "── glow: bright ──" },
  { key = "soft", label = "── glow: soft ──" },
  { key = "faint", label = "── glow: faint ──" },
  { key = "flat", label = "── glow: flat  (values do not bloom) ──" },
  { key = "unknown", label = "── glow: unmeasured ──" },
}

local function glow_tier(name)
  local entry = glow_tiers[name]
  return entry and entry[1] or "unknown"
end

-- MEASURED per-theme facets: real background luminance and the yaml KEY colour
-- theme.lua derives for each theme. See lua/config/theme_facets.lua and
-- dotfiles/tools/theme-facets-measure.lua to regenerate.
--
-- Deliberately NOT used by apply_scheme: that has to choose 'background' before
-- the theme is loaded, and the name marker is the only thing known at that point.
-- Changing which bg a theme loads under would change how it looks, which is not
-- what a grouping menu is for. Facets group and filter the list, nothing else.
local facets = (function()
  local ok, t = pcall(require, "config.theme_facets")
  return ok and t or {}
end)()

-- Whether the measured data is there AT ALL. If it is not (file missing, or being
-- regenerated), every theme's key class is "unknown", and a saved "coloured keys
-- only" filter would then hide all 538 entries and show an empty picker with no
-- explanation. A filter with no data behind it does not get to filter: it is
-- skipped and the title says so. Never silently empty the list.
local have_facets = next(facets) ~= nil

-- Measured light beats the name marker (some base16 "-light" entries are dark,
-- and a few light schemes say nothing in their name); fall back to the marker
-- for anything unmeasured.
local function is_light_theme(name)
  local f = facets[name]
  if f ~= nil then
    return f.light
  end
  return is_light(name)
end

local function is_base16(name)
  local n = name:lower()
  return n:find("^base16%-") ~= nil or n:find("^base24%-") ~= nil or n:find("^tinted%-") ~= nil
end

-- What the yaml keys read as for this theme: "white" / "grey" / "tinted", or a
-- hue family. Unmeasured themes land in "unknown" rather than being guessed at.
local function key_class(name)
  local f = facets[name]
  return f and f.class or "unknown"
end

local colorless_key = { white = true, grey = true, unknown = true }

-- Grouping modes. `groups` is the order the buckets print in; `of` maps a scheme
-- to a bucket key. A scheme whose bucket is not listed is dropped into the last
-- entry, so a new hue family from a regenerated facets file can never vanish.
local group_modes = {
  {
    key = "glow",
    label = "yaml VALUE glow",
    groups = glow_order,
    of = glow_tier,
  },
  {
    key = "bg",
    label = "light / dark",
    groups = {
      { key = "dark", label = "── dark ──" },
      { key = "light", label = "── light ──" },
    },
    of = function(name)
      return is_light_theme(name) and "light" or "dark"
    end,
  },
  {
    key = "base16",
    label = "base16 / not base16",
    groups = {
      { key = "other", label = "── standalone themes  (not base16) ──" },
      { key = "base16", label = "── base16 family ──" },
    },
    of = function(name)
      return is_base16(name) and "base16" or "other"
    end,
  },
  {
    -- The list Jimmy actually opens this for: which themes give yaml keys a
    -- colour of their own, and which just leave them white. Coloured families
    -- print first, white/grey last.
    key = "keys",
    label = "yaml KEY colour",
    groups = {
      { key = "magenta", label = "── keys: magenta ──" },
      { key = "purple", label = "── keys: purple ──" },
      { key = "blue", label = "── keys: blue ──" },
      { key = "cyan", label = "── keys: cyan ──" },
      { key = "green", label = "── keys: green ──" },
      { key = "yellow", label = "── keys: yellow ──" },
      { key = "orange", label = "── keys: orange ──" },
      { key = "red", label = "── keys: red ──" },
      { key = "tinted", label = "── keys: barely tinted ──" },
      { key = "grey", label = "── keys: grey ──" },
      { key = "white", label = "── keys: WHITE  (no colour of their own) ──" },
      { key = "unknown", label = "── keys: unmeasured ──" },
    },
    of = key_class,
  },
  {
    key = "flat",
    label = "nothing — one flat A-Z run",
    groups = nil,
  },
}

local function group_mode_by_key(key)
  for _, mode in ipairs(group_modes) do
    if mode.key == key then
      return mode
    end
  end
  return group_modes[1]
end

-- The cursor row used to borrow each theme's Visual, which the live preview
-- swaps out 300 different ways — plenty of them white-on-bright and unreadable.
-- Pin it to fixed colours instead, and re-stamp them after every preview, since
-- `:colorscheme` runs `hi clear` and wipes the group.
-- The float's OWN colours, fixed, for the same reason as the cursor row: the theme
-- under the cursor changes 300 different ways around it. Borrowing `Normal` broke
-- on every light theme -- theme.lua pins the background dark, the light theme
-- supplies a near-black fg to go with its own white bg, and the float rendered
-- dark-on-dark and could not be read at all. Same for the headers, which used to
-- borrow `Comment`. These are the picker chrome, not theme colours.
local function define_cursor_highlight()
  vim.api.nvim_set_hl(0, "ColorschemePickerCursor", { fg = "#ffffff", bg = "#005f87", bold = true })
  vim.api.nvim_set_hl(0, "ColorschemePickerMarker", { fg = "#ffffff", bg = "#005f87", bold = true })
  vim.api.nvim_set_hl(0, "ColorschemePickerNormal", { fg = "#d6d9de", bg = "#0f0f0f" })
  vim.api.nvim_set_hl(0, "ColorschemePickerBorder", { fg = "#6a7280", bg = "#0f0f0f" })
  vim.api.nvim_set_hl(0, "ColorschemePickerHeader", { fg = "#8b94a5", bg = "#0f0f0f", bold = true })
end

-- Both floats wear it.
local picker_winhighlight = table.concat({
  "Normal:ColorschemePickerNormal",
  "NormalFloat:ColorschemePickerNormal",
  "FloatBorder:ColorschemePickerBorder",
  "FloatTitle:ColorschemePickerBorder",
  "FloatFooter:ColorschemePickerBorder",
  "CursorLine:ColorschemePickerCursor",
}, ",")

-- Where the cursor was when the picker last closed, so reopening resumes there.
local last_selected = nil

-- Menu state, module-level so it survives closing and reopening the picker within
-- a session: having to re-pick the grouping every time defeats the point.
-- Grouping is one choice; the filters below are independent of it and of each
-- other, so any combination holds at once ("dark only" + "keys have a colour" +
-- "values burn" is three filters and one grouping).
--
-- All of it PERSISTS: loaded from stdpath("state") here and saved on every change,
-- so a session starts on whatever you were last browsing with instead of resetting
-- to grouped-by-glow-and-no-filters.
local view_state = (function()
  local ok, m = pcall(require, "config.picker_view_state")
  return ok and m or nil
end)()

local saved_view = view_state and view_state.read() or {}

local group_mode_key = saved_view.group_mode or "glow"
local bg_filter = saved_view.bg_filter or "all" -- all | dark | light
local base16_filter = saved_view.base16_filter or "all" -- all | only | never
local colored_keys_only = saved_view.colored_keys_only or false
local glow_filter = saved_view.glow_filter or "all" -- all | loud (neon+bright) | neon

local function save_view()
  if view_state then
    view_state.write({
      group_mode = group_mode_key,
      bg_filter = bg_filter,
      base16_filter = base16_filter,
      colored_keys_only = colored_keys_only,
      glow_filter = glow_filter,
    })
  end
end

local loud_glow = { neon = true, bright = true }

-- Every scheme load goes through here so 'background' always matches the theme
-- being applied. Without this, previewing a light theme left background=light
-- behind, and scrolling back onto a dark scheme loaded its light variant (or
-- half-resolved against light fallback groups) — gruvbox, everforest, sonokai,
-- retrobox and the base16 family all key off &background. `noautocmd` matters:
-- a bare `set background=` makes Vim re-source the CURRENT scheme first, which
-- would fire theme.lua's full deferred pipeline a second time per preview step.
local function apply_scheme(name)
  local bg = is_light(name) and "light" or "dark"
  if vim.o.background ~= bg then
    pcall(vim.cmd, "noautocmd set background=" .. bg)
  end
  pcall(vim.cmd.colorscheme, name)
end

-- kanagawa.nvim sets colors_name = "kanagawa" for every variant; resolve the
-- real one so cancel doesn't silently drop you back to wave.
local function current_colorscheme()
  local name = vim.g.colors_name or ""
  if name == "kanagawa" then
    local ok, kanagawa = pcall(require, "kanagawa")
    if ok and kanagawa.config and kanagawa.config.theme then
      return "kanagawa-" .. kanagawa.config.theme
    end
  end
  return name
end

local function installed_colors()
  local all = vim.fn.getcompletion("", "color")

  local lazy = package.loaded["lazy.core.util"]
  if lazy and lazy.get_unloaded_rtp then
    local paths = lazy.get_unloaded_rtp("")
    for _, f in ipairs(vim.fn.globpath(table.concat(paths, ","), "colors/*", true, true)) do
      table.insert(all, vim.fn.fnamemodify(f, ":t:r"))
    end
  end

  local seen, out = {}, {}
  for _, c in ipairs(all) do
    if not seen[c] and not builtin_junk[c] then
      seen[c] = true
      table.insert(out, c)
    end
  end
  table.sort(out)
  return out, seen
end

-- Add or remove a single line in the `favorites` block above, rather than
-- regenerating it — the block carries hand-written comments that a regenerate
-- would silently eat.
local function persist_favorite(name, removing)
  local ok, lines = pcall(vim.fn.readfile, self_path)
  if not ok then
    return false
  end

  local first, last
  for i, line in ipairs(lines) do
    if not first and line:match("^local favorites = {%s*$") then
      first = i
    elseif first and line:match("^}%s*$") then
      last = i
      break
    end
  end
  if not first or not last then
    return false
  end

  local entry = string.format("%q,", name)
  if removing then
    for i = last - 1, first + 1, -1 do
      if lines[i]:match("^%s*(.-)%s*$") == entry then
        table.remove(lines, i)
        break
      end
    end
  else
    table.insert(lines, last, "  " .. entry)
  end

  return pcall(vim.fn.writefile, lines, self_path)
end

local function pick_colorscheme()
  local all_colors, available = installed_colors()
  if #all_colors == 0 then
    vim.notify("No colorschemes found", vim.log.levels.WARN)
    return
  end

  local original = current_colorscheme()
  local original_background = vim.o.background
  -- Whatever grouping the menu was last left on, restored from disk; glow tier on
  -- a first-ever run. Nothing is filtered unless the menu says so.
  -- `T` flips to flat A-Z and back, `m` opens the full menu.
  local last_group_mode = group_mode_key ~= "flat" and group_mode_key or "glow"

  -- No terminal cursor for the whole life of the picker: every j/k here is a
  -- cursor move, and Ghostty's trail/boom shaders restart on each one, so a held
  -- j rakes a column of half-finished smears through the float. The `▶` marker
  -- and the cursorline already show the selection. Released in close().
  local hidden_cursor = require("config.hidden_cursor")
  hidden_cursor.acquire()

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "colorschemepicker"
  -- snacks.scroll animates the viewport toward its target over ~450ms. In here
  -- the cursor is also being moved outright (fuzzy jumps, header skips, <C-d>),
  -- and the two fight: the animation is still gliding to the old target while the
  -- cursor is already somewhere else, which is the trail. snacks checks this
  -- buffer-local flag (scroll.lua:41), so the picker just opts out.
  vim.b[buf].snacks_scroll = false
  vim.b[buf].snacks_animate = false

  local height = math.min(#all_colors, math.floor(vim.o.lines * 0.7))
  local width = 46
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " colorscheme ",
    title_pos = "center",
    -- The discoverability tip, in the border rather than in the list: a hint row
    -- inside the buffer would either be selectable (and preview a theme) or need
    -- another special case in every cursor-stepping path.
    footer = footer_hint,
    footer_pos = "center",
  })

  vim.wo[win].cursorline = true
  vim.wo[win].wrap = false
  -- The float has to stay legible while the scheme under the cursor changes
  -- around it, so pin it to Normal rather than NormalFloat.
  vim.wo[win].winhighlight = picker_winhighlight
  define_cursor_highlight()

  local ns = vim.api.nvim_create_namespace("jimmy_colorscheme_picker")
  local marker_ns = vim.api.nvim_create_namespace("jimmy_colorscheme_picker_marker")

  -- entries[i] mirrors buffer line i: { name = "gruvbox" } or { header = true }.
  local entries = {}
  local timer = vim.uv.new_timer()
  local closing = false
  local last_row = 1
  -- True only while the `m` categories float has focus, so the WinLeave guard
  -- below can tell "focus moved to my own menu" from "focus left the picker".
  local menu_open = false

  local function stop_timer()
    if timer and not timer:is_closing() then
      timer:stop()
      timer:close()
    end
    timer = nil
  end

  local function favorite_index(name)
    for i, c in ipairs(favorites) do
      if c == name then
        return i
      end
    end
    return nil
  end

  local function selected()
    if not vim.api.nvim_win_is_valid(win) then
      return nil
    end
    local entry = entries[vim.api.nvim_win_get_cursor(win)[1]]
    return entry and entry.name or nil
  end

  -- A `▶` in the left margin of the cursor row, so the selection is findable even
  -- on a theme whose colours fight the cursorline.
  local function draw_marker()
    if closing or not vim.api.nvim_win_is_valid(win) then
      return
    end
    vim.api.nvim_buf_clear_namespace(buf, marker_ns, 0, -1)
    local row = vim.api.nvim_win_get_cursor(win)[1]
    if entries[row] and entries[row].name then
      vim.api.nvim_buf_set_extmark(buf, marker_ns, row - 1, 0, {
        virt_text = { { "▶", "ColorschemePickerMarker" } },
        virt_text_pos = "overlay",
      })
    end
  end

  -- Title doubles as the position readout: which scheme out of how many, so
  -- "how far into this list am I" is answerable without a scrollbar. The fuzzy
  -- prompt borrows the same title bar and restores this on exit.
  local function base_title()
    -- Every active filter has to be visible somewhere permanent: a shortened list
    -- with nothing saying why is how a theme goes "missing".
    local flags = {}
    if bg_filter ~= "all" then
      table.insert(flags, bg_filter .. " only")
    end
    if base16_filter == "only" then
      table.insert(flags, "base16 only")
    elseif base16_filter == "never" then
      table.insert(flags, "no base16")
    end
    if colored_keys_only then
      table.insert(flags, have_facets and "coloured keys" or "coloured keys: NO DATA")
    end
    if glow_filter == "neon" then
      table.insert(flags, "neon glow")
    elseif glow_filter == "loud" then
      table.insert(flags, "loud glow")
    end
    local suffix = #flags > 0 and ("  [" .. table.concat(flags, ", ") .. "]") or ""
    if not vim.api.nvim_win_is_valid(win) then
      return " colorscheme" .. suffix .. " "
    end
    local row = vim.api.nvim_win_get_cursor(win)[1]
    local index, total = 0, 0
    for i, entry in ipairs(entries) do
      if entry.name then
        total = total + 1
        if i <= row then
          index = total
        end
      end
    end
    -- Tier of the scheme under the cursor, so it stays readable after a fuzzy
    -- jump has thrown you into the middle of a group whose header is offscreen.
    local name = entries[row] and entries[row].name
    -- Facet of the scheme under the cursor, matching whatever the list is grouped
    -- by, so it stays readable after a fuzzy jump has thrown you into the middle
    -- of a group whose header is offscreen.
    local facet = ""
    if name then
      if group_mode_key == "keys" then
        facet = string.format("  keys:%s", key_class(name))
      elseif group_mode_key == "bg" then
        facet = is_light_theme(name) and "  light" or "  dark"
      elseif group_mode_key == "base16" then
        facet = is_base16(name) and "  base16" or ""
      elseif glow_tiers[name] then
        facet = string.format("  glow:%s", glow_tiers[name][1])
      end
    end
    return string.format(" colorscheme  %d/%d%s%s ", index, total, facet, suffix)
  end

  -- The footer is re-sent with every title update: a partial win_set_config on a
  -- float drops the fields it does not mention, which silently ate the hint.
  local function update_title()
    if vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_set_config, win, {
        title = base_title(),
        title_pos = "center",
        footer = footer_hint,
        footer_pos = "center",
      })
    end
  end

  local function preview()
    local name = selected()
    draw_marker()
    if not name or name == current_colorscheme() or not timer then
      return
    end
    timer:stop()
    timer:start(
      preview_debounce_ms,
      0,
      vim.schedule_wrap(function()
        if not closing and vim.api.nvim_win_is_valid(win) then
          apply_scheme(name)
        end
      end)
    )
  end

  -- Rebuild the buffer. `focus` is the scheme to leave the cursor on, so toggling
  -- a favorite or unhiding light variants doesn't lose your place.
  local function render(focus)
    entries = {}
    local lines = {}

    local function add(text, entry)
      table.insert(lines, text)
      table.insert(entries, entry)
    end

    add(favorites_header, { header = true })
    for _, name in ipairs(favorites) do
      if available[name] then
        add("  " .. name, { name = name })
      end
    end

    -- The header carries the hidden-light count: a footer would sit at the bottom
    -- of a 300-line buffer where it would never be read, and a silently shortened
    -- list is exactly how a scheme goes missing.
    local others, hidden = {}, 0
    for _, name in ipairs(all_colors) do
      if not favorite_index(name) then
        -- Every filter is a separate AND: they stack in any combination.
        local shown = (bg_filter == "all" or (bg_filter == "light") == is_light_theme(name))
          and (base16_filter == "all" or (base16_filter == "only") == is_base16(name))
          and (not colored_keys_only or not have_facets or not colorless_key[key_class(name)])
          and (
            glow_filter == "all"
            or (glow_filter == "neon" and glow_tier(name) == "neon")
            or (glow_filter == "loud" and loud_glow[glow_tier(name)])
          )
        if shown then
          table.insert(others, name)
        else
          hidden = hidden + 1
        end
      end
    end

    add(hidden > 0 and string.format("%s  (%d hidden — m)", others_header, hidden) or others_header, {
      header = true,
    })

    local mode = group_mode_by_key(group_mode_key)
    if mode.groups then
      -- One sub-header per bucket, in the mode's own order; each bucket stays A-Z
      -- inside itself because `others` is already sorted. Empty buckets print
      -- nothing, and an unlisted bucket key falls into the mode's last group so a
      -- regenerated facets file can never make a theme disappear.
      local by_bucket, fallback = {}, mode.groups[#mode.groups].key
      local known = {}
      for _, g in ipairs(mode.groups) do
        known[g.key] = true
      end
      for _, name in ipairs(others) do
        local bucket = mode.of(name)
        if not known[bucket] then
          bucket = fallback
        end
        by_bucket[bucket] = by_bucket[bucket] or {}
        table.insert(by_bucket[bucket], name)
      end
      for _, group in ipairs(mode.groups) do
        local names = by_bucket[group.key]
        if names and #names > 0 then
          add(string.format("%s  (%d)", group.label, #names), { header = true })
          for _, name in ipairs(names) do
            add("  " .. name, { name = name })
          end
        end
      end
    else
      for _, name in ipairs(others) do
        add("  " .. name, { name = name })
      end
    end

    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false

    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    for i, entry in ipairs(entries) do
      if entry.header then
        vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, { end_col = #lines[i], hl_group = "ColorschemePickerHeader" })
      end
    end

    -- Land on `focus` if it survived the filters; otherwise on the first real
    -- theme rather than on a header. Turning a filter on routinely hides the
    -- scheme you were sitting on, and leaving the cursor parked on a divider made
    -- the position readout say 0/403 until something moved it.
    local row
    local first_name
    for i, entry in ipairs(entries) do
      if entry.name then
        first_name = first_name or i
        if entry.name == focus then
          row = i
          break
        end
      end
    end
    row = math.min(row or first_name or 1, #entries)
    pcall(vim.api.nvim_win_set_cursor, win, { row, 0 })
    last_row = row

    update_title()
  end

  -- `keep` decides what you're left with; only <C-c> reverts. Quitting by any
  -- other route keeps whatever you were previewing, which is the whole point of
  -- scrolling until something looks right.
  local function close(keep)
    if closing then
      return
    end
    closing = true
    stop_timer()
    hidden_cursor.release()

    local name = keep and selected() or nil
    last_selected = name or last_selected

    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end

    if keep then
      if name and name ~= current_colorscheme() then
        apply_scheme(name)
      end
    elseif original ~= "" then
      -- Same noautocmd dance as apply_scheme: restoring background with plain
      -- vim.o.background re-sources the previewed theme under the wrong bg
      -- before `original` even loads.
      if vim.o.background ~= original_background then
        pcall(vim.cmd, "noautocmd set background=" .. original_background)
      end
      pcall(vim.cmd.colorscheme, original)
    end

    -- Remember whatever we actually ended on — including the <C-c> restore, so
    -- cancelling never leaves the saved name pointing at a theme you rejected.
    local ok_state, state = pcall(require, "config.colorscheme_state")
    if ok_state then
      state.write(current_colorscheme())
    end
  end

  local group = vim.api.nvim_create_augroup("jimmy_colorscheme_picker", { clear = true })

  -- Headers are not selectable: step over them in whichever direction the cursor
  -- was already travelling, so j/k/<C-d> never stall on a divider.
  vim.api.nvim_create_autocmd("CursorMoved", {
    group = group,
    buffer = buf,
    callback = function()
      if closing or not vim.api.nvim_win_is_valid(win) then
        return
      end
      local row = vim.api.nvim_win_get_cursor(win)[1]
      if entries[row] and entries[row].header then
        local step = row >= last_row and 1 or -1
        local target = row + step
        if target < 1 or target > #entries then
          target = row - step
        end
        pcall(vim.api.nvim_win_set_cursor, win, { target, 0 })
        row = target
      end
      last_row = row
      update_title()
      preview()
    end,
  })

  -- `:colorscheme` runs `hi clear`, and theme.lua's pipeline then re-stamps groups
  -- on deferred passes out to 800ms — both wipe our fixed cursor colours. Put them
  -- back immediately and again past the end of that window.
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      if closing then
        return
      end
      define_cursor_highlight()
      draw_marker()
        vim.defer_fn(function()
        if not closing and vim.api.nvim_win_is_valid(win) then
          define_cursor_highlight()
              draw_marker()
              end
      end, 900)
    end,
  })

  -- The float used to be strandable: anything that moved focus back to the editor
  -- left it sitting there with no way to close it short of quitting nvim. Losing
  -- focus now closes it, keeping whatever was previewing.
  vim.api.nvim_create_autocmd("WinLeave", {
    group = group,
    buffer = buf,
    callback = function()
      -- The categories menu is part of the picker, not somewhere else.
      if menu_open then
        return
      end
      close(true)
    end,
  })
  -- `:q` in a float would otherwise fall through to quitting nvim when the float
  -- is the only real window. Intercept it and just close the picker.
  vim.api.nvim_create_autocmd("QuitPre", {
    group = group,
    buffer = buf,
    callback = function()
      close(true)
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    buffer = buf,
    callback = function()
      -- Also the leak guard: if the buffer is wiped without close() ever running,
      -- this is the only place left that can give the cursor back. Releasing
      -- twice is a no-op (the refcount floors at zero), so the ordinary
      -- close()-then-wipe path is unaffected.
      closing = true
      stop_timer()
      hidden_cursor.release()
    end,
  })

  local function map(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true, silent = true })
  end

  map("<CR>", function()
    close(true)
  end)
  map("q", function()
    close(true)
  end)
  map("<Esc>", function()
    close(true)
  end)
  map("<C-c>", function()
    close(false)
  end)

  -- Window commands would move focus out from under the picker. WinLeave catches
  -- that now, but there is no reason to allow it in the first place.
  map("<C-w>", "<Nop>")

  -- <C-d>/<C-u> are inert in the float (its 'scroll' never gets a usable value),
  -- so move the cursor half a window at a time by hand. gg/G are native already.
  local function half_page(direction)
    return function()
      if not vim.api.nvim_win_is_valid(win) then
        return
      end
      local step = math.max(1, math.floor(vim.api.nvim_win_get_height(win) / 2))
      local row = vim.api.nvim_win_get_cursor(win)[1] + direction * step
      row = math.max(1, math.min(#entries, row))
      vim.api.nvim_win_set_cursor(win, { row, 0 })
    end
  end
  map("<C-d>", half_page(1))
  map("<C-u>", half_page(-1))

  -- <C-j>/<C-k> are window navigation everywhere else in this config, so a stray
  -- one in here moved focus out of the float and WinLeave closed the picker
  -- mid-browse. Bound to a 5-row step instead: same fingers, nothing lost.
  local function step_rows(count)
    return function()
      if not vim.api.nvim_win_is_valid(win) then
        return
      end
      local row = vim.api.nvim_win_get_cursor(win)[1] + count
      row = math.max(1, math.min(#entries, row))
      vim.api.nvim_win_set_cursor(win, { row, 0 })
    end
  end
  map("<C-j>", step_rows(5))
  map("<C-k>", step_rows(-5))
  -- scroll.lua rebinds bare u/d to page scroll, but it feeds <C-u>/<C-d> with
  -- noremap, so they never reach the buffer-local maps above and did nothing in
  -- here. Same muscle memory, wired directly.
  map("d", half_page(1))
  map("u", half_page(-1))

  -- No `L`: light variants used to be a special case with its own key, which meant
  -- two ways to filter by background that disagreed about what "on" meant. The
  -- light/dark filter in the `m` menu is the only one now.

  map("T", function()
    if group_mode_key == "flat" then
      group_mode_key = last_group_mode
    else
      last_group_mode = group_mode_key
      group_mode_key = "flat"
    end
    save_view()
    render(selected())
  end)

  -- The categories menu. Its own float rather than a getcharstr() prompt in the
  -- title bar: there are eight rows of state here and they have to be readable at
  -- once, including which mode and filters are already on.
  --
  -- Opening it moves focus off the picker, which WinLeave would read as "close and
  -- keep" — hence menu_open, checked by that autocmd.
  map("m", function()
    local rows = {}
    for i, mode in ipairs(group_modes) do
      table.insert(rows, {
        digit = tostring(i),
        text = string.format(
          " %d %s group by: %s",
          i,
          group_mode_key == mode.key and "●" or "○",
          mode.label
        ),
        act = function()
          if mode.key ~= "flat" then
            last_group_mode = mode.key
          end
          group_mode_key = mode.key
        end,
      })
    end
    table.insert(rows, { separator = true, text = "" })
    -- FILTERS. Each is independent of the grouping above and of the others, so
    -- they stack: leave three of them on and you get the intersection.
    --
    -- Shortcut letters here are deliberately NOT j or k -- those are the menu's
    -- own movement keys, so a filter bound to `k` was unreachable without the
    -- cursor jumping first.
    table.insert(rows, { separator = true, text = " filters (stack, any combination)" })
    table.insert(rows, {
      digit = "d",
      text = string.format(
        " d %s light/dark: %s",
        bg_filter == "all" and "○" or "●",
        bg_filter == "all" and "both" or (bg_filter == "dark" and "dark only" or "light only")
      ),
      act = function()
        bg_filter = bg_filter == "all" and "dark" or (bg_filter == "dark" and "light" or "all")
      end,
    })
    table.insert(rows, {
      digit = "b",
      text = string.format(
        " b %s base16: %s",
        base16_filter == "all" and "○" or "●",
        base16_filter == "all" and "all themes" or (base16_filter == "only" and "base16 only" or "excluded")
      ),
      act = function()
        base16_filter = base16_filter == "all" and "only" or (base16_filter == "only" and "never" or "all")
      end,
    })
    table.insert(rows, {
      digit = "c",
      text = string.format(
        " c %s yaml keys: %s",
        colored_keys_only and "●" or "○",
        not have_facets and "no measured data — filter inert" or (colored_keys_only and "have a colour" or "any")
      ),
      act = function()
        colored_keys_only = not colored_keys_only
      end,
    })
    table.insert(rows, {
      digit = "g",
      text = string.format(
        " g %s yaml value glow: %s",
        glow_filter == "all" and "○" or "●",
        glow_filter == "all" and "any" or (glow_filter == "loud" and "neon + bright" or "neon only")
      ),
      act = function()
        glow_filter = glow_filter == "all" and "loud" or (glow_filter == "loud" and "neon" or "all")
      end,
    })

    local lines = {}
    for _, row in ipairs(rows) do
      table.insert(lines, row.text)
    end

    local mbuf = vim.api.nvim_create_buf(false, true)
    vim.bo[mbuf].bufhidden = "wipe"
    vim.b[mbuf].snacks_scroll = false
    vim.b[mbuf].snacks_animate = false
    vim.api.nvim_buf_set_lines(mbuf, 0, -1, false, lines)
    vim.bo[mbuf].modifiable = false

    -- Set BEFORE opening the float: nvim_open_win with focus fires the picker's
    -- WinLeave synchronously, and that handler closes the picker unless this flag
    -- is already up.
    menu_open = true

    local mwidth = 52
    local mwin = vim.api.nvim_open_win(mbuf, true, {
      relative = "editor",
      width = mwidth,
      height = #lines,
      row = math.floor((vim.o.lines - #lines) / 2) - 1,
      col = math.floor((vim.o.columns - mwidth) / 2),
      style = "minimal",
      border = "rounded",
      title = " categories ",
      title_pos = "center",
    })
    vim.wo[mwin].cursorline = true
    vim.wo[mwin].winhighlight = picker_winhighlight

    local mclosing = false

    -- Every exit path runs this, so menu_open can never be left true — that would
    -- strand the picker as unclosable-on-focus-loss.
    local function mclose(row)
      if mclosing then
        return
      end
      mclosing = true
      menu_open = false
      if vim.api.nvim_win_is_valid(mwin) then
        vim.api.nvim_win_close(mwin, true)
      end
      if row and row.act then
        row.act()
        -- Persist on every change, not on close: the picker can also disappear via
        -- WinLeave or a buffer wipe, and a setting that survives only a tidy exit
        -- is the same annoyance as not persisting at all.
        save_view()
      end
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_set_current_win(win)
        -- Re-render either way: the picker's own title carries the filter flags.
        render(selected())
        preview()
      end
    end

    local function mmap(lhs, fn)
      vim.keymap.set("n", lhs, fn, { buffer = mbuf, nowait = true, silent = true })
    end

    -- Skip separators in whichever direction you were heading — a run of them, not
    -- just one: the blank line and the "filters" caption sit next to each other.
    local function mstep(direction)
      return function()
        local cur = vim.api.nvim_win_get_cursor(mwin)[1]
        local target = cur + direction
        while rows[target] and rows[target].separator do
          target = target + direction
        end
        if rows[target] then
          vim.api.nvim_win_set_cursor(mwin, { target, 0 })
        end
      end
    end
    mmap("j", mstep(1))
    mmap("k", mstep(-1))
    mmap("<Down>", mstep(1))
    mmap("<Up>", mstep(-1))
    -- Same trap as the picker: an accidental <C-j> here is window navigation, which
    -- would drop the menu AND the picker. The menu is eleven rows, so a 5-row jump
    -- would just slam into the ends — one row is the useful behaviour.
    mmap("<C-j>", mstep(1))
    mmap("<C-k>", mstep(-1))

    mmap("<CR>", function()
      mclose(rows[vim.api.nvim_win_get_cursor(mwin)[1]])
    end)
    for _, row in ipairs(rows) do
      if row.digit then
        mmap(row.digit, function()
          mclose(row)
        end)
      end
    end
    mmap("q", function()
      mclose(nil)
    end)
    mmap("<Esc>", function()
      mclose(nil)
    end)
    mmap("m", function()
      mclose(nil)
    end)
    mmap("<C-c>", function()
      mclose(nil)
    end)

    -- Anything that pulls focus elsewhere (or wipes the buffer) closes the menu
    -- rather than leaving a second float floating.
    vim.api.nvim_create_autocmd({ "WinLeave", "BufWipeout" }, {
      buffer = mbuf,
      once = true,
      callback = function()
        if not mclosing then
          menu_open = false
          mclosing = true
          if vim.api.nvim_win_is_valid(mwin) then
            pcall(vim.api.nvim_win_close, mwin, true)
          end
        end
      end,
    })

    -- Start on the row for the active grouping mode.
    for i, mode in ipairs(group_modes) do
      if mode.key == group_mode_key then
        pcall(vim.api.nvim_win_set_cursor, mwin, { i, 0 })
        break
      end
    end
  end)

  -- Incremental fuzzy JUMP. Scores against every installed scheme, including any
  -- the filters are currently hiding — landing on one of those clears the filters,
  -- so a filtered-out theme is never unreachable by name. The list is never
  -- reduced: this only moves the cursor, and <CR> leaves you free to keep
  -- scrolling from there.
  local function move_to(name)
    local row
    for i, entry in ipairs(entries) do
      if entry.name == name then
        row = i
        break
      end
    end
    if not row then
      -- The match exists but a filter is hiding it. Drop the filters rather than
      -- refuse the jump, and say so: silently landing on a row while the title
      -- still claimed "dark only" would be a lie about what the list contains.
      bg_filter, base16_filter, glow_filter, colored_keys_only = "all", "all", "all", false
      save_view()
      render(name)
      draw_marker()
      vim.notify("filters cleared to reach " .. name)
      return
    end
    vim.api.nvim_win_set_cursor(win, { row, 0 })
    -- CursorMoved doesn't fire while getcharstr() has the loop, so the marker
    -- has to be repainted by hand for the jump to be visible as you type.
    draw_marker()
  end

  local function set_title(text)
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_set_config(win, {
        title = text,
        title_pos = "center",
        footer = footer_hint,
        footer_pos = "center",
      })
    end
  end

  map("s", function()
    local start_name = selected()
    local query, index, matches = "", 1, {}

    local function recompute()
      matches = {}
      if query ~= "" then
        for _, name in ipairs(all_colors) do
          local score = fuzzy_score(name, query)
          if score then
            table.insert(matches, { name = name, score = score })
          end
        end
        table.sort(matches, function(a, b)
          return a.score < b.score
        end)
      end
      index = 1
      if matches[1] then
        move_to(matches[1].name)
      end
    end

    while true do
      local count = #matches
      set_title(
        string.format(
          " fuzzy: %s▏ %s ",
          query,
          query == "" and "(type to jump)" or (count == 0 and "no match" or string.format("%d/%d", index, count))
        )
      )
      vim.cmd("redraw")

      local ok, char = pcall(vim.fn.getcharstr)
      if not ok then
        break
      end

      if char == "\27" then -- <Esc>: back where you started
        if start_name then
          move_to(start_name)
        end
        break
      elseif char == "\r" or char == "\n" then -- <CR>: keep the jump, resume scrolling
        break
      elseif char == "\b" or char == "\128kb" or char == vim.keycode("<BS>") then
        query = query:sub(1, -2)
        recompute()
      elseif char == "\t" or char == vim.keycode("<C-n>") then
        if count > 0 then
          index = index % count + 1
          move_to(matches[index].name)
        end
      elseif char == vim.keycode("<S-Tab>") or char == vim.keycode("<C-p>") then
        if count > 0 then
          index = (index - 2) % count + 1
          move_to(matches[index].name)
        end
      elseif #char == 1 and char:byte() >= 32 then
        query = query .. char
        recompute()
      end
    end

    update_title()
    preview()
  end)

  map("f", function()
    local name = selected()
    if not name then
      return
    end
    local index = favorite_index(name)
    if index then
      table.remove(favorites, index)
    else
      table.insert(favorites, name)
    end
    render(name)
    if persist_favorite(name, index ~= nil) then
      vim.notify((index and "unfavorited " or "favorited ") .. name)
    else
      vim.notify("favorite not written to " .. self_path, vim.log.levels.WARN)
    end
  end)

  render(last_selected or original)
  preview()
end

vim.api.nvim_create_user_command("ColorschemePicker", pick_colorscheme, {})

-- :ThemeBack / <leader>tp — swap straight back to the theme you were on before
-- the current one, no picker, no scrolling. The pair is what colorscheme_state
-- already tracks (current + previous), and because the swap itself goes through
-- state.write(), the two names just trade places: pressing it again returns you
-- to where you started. Same apply_scheme() as the picker, so 'background' is
-- set correctly before the scheme loads.
local function swap_previous()
  local ok, state = pcall(require, "config.colorscheme_state")
  if not ok then
    vim.notify("ThemeBack: config.colorscheme_state failed to load", vim.log.levels.ERROR)
    return
  end
  local prev = state.previous()
  if not prev then
    vim.notify("ThemeBack: no previous colorscheme recorded yet", vim.log.levels.WARN)
    return
  end
  if prev == current_colorscheme() then
    vim.notify("ThemeBack: already on " .. prev)
    return
  end
  apply_scheme(prev)
  -- Only record the swap if it actually landed — a theme that errors out would
  -- otherwise poison both slots with a name that cannot load.
  local now = current_colorscheme()
  if now == prev then
    state.write(prev)
    vim.notify("theme: " .. prev)
  else
    vim.notify("ThemeBack: " .. prev .. " failed to load", vim.log.levels.WARN)
  end
end

vim.api.nvim_create_user_command("ThemeBack", swap_previous, {
  desc = "Swap back to the previously used colorscheme",
})

-- Favorite the theme you are ALREADY IN, without opening the picker — the picker's
-- `f` needs you to scroll to the row first, which is backwards when you have just
-- landed on something you like. Both take an optional name argument.
--
--   :ThemeFav                 favorite the live colorscheme
--   :ThemeUnfav               remove the live colorscheme
--   :ThemeFav gruvbox         favorite a named one
--
-- Same persist_favorite() writer the picker uses, so hand-written comments in the
-- block above survive, and the in-memory `favorites` table stays in sync for a
-- picker opened later in this same session.
local function favorite_position(name)
  for i, c in ipairs(favorites) do
    if c == name then
      return i
    end
  end
end

local function toggle_favorite(name, removing)
  name = name ~= "" and name or current_colorscheme()
  if not name or name == "" then
    vim.notify("no colorscheme active", vim.log.levels.WARN)
    return
  end
  local index = favorite_position(name)
  if removing and not index then
    vim.notify(name .. " is not a favorite")
    return
  end
  if not removing and index then
    vim.notify(name .. " is already a favorite")
    return
  end
  if removing then
    table.remove(favorites, index)
  else
    table.insert(favorites, name)
  end
  if persist_favorite(name, removing) then
    vim.notify((removing and "unfavorited " or "favorited ") .. name)
  else
    vim.notify("favorite not written to " .. self_path, vim.log.levels.WARN)
  end
end

-- Completion offers installed colorschemes for :ThemeFav, and only the current
-- favorites for :ThemeUnfav — nothing else can be removed.
local function complete_installed(lead)
  local out = {}
  for _, c in ipairs(installed_colors()) do
    if c:find(lead, 1, true) == 1 then
      table.insert(out, c)
    end
  end
  return out
end

vim.api.nvim_create_user_command("ThemeFav", function(opts)
  toggle_favorite(opts.args, false)
end, { nargs = "?", complete = complete_installed, desc = "Add a colorscheme to picker favorites" })

vim.api.nvim_create_user_command("ThemeUnfav", function(opts)
  toggle_favorite(opts.args, true)
end, {
  nargs = "?",
  complete = function(lead)
    local out = {}
    for _, c in ipairs(favorites) do
      if c:find(lead, 1, true) == 1 then
        table.insert(out, c)
      end
    end
    return out
  end,
  desc = "Remove a colorscheme from picker favorites",
})

-- LazyVim's fzf extra declares <leader>uC inside fzf-lua's own spec, so setting
-- the mapping at startup is not enough: when fzf-lua loads (first use of any fzf
-- picker) lazy.nvim installs that spec's keys and clobbers ours. Declare it on
-- the same spec instead — lazy merges `keys` across specs and the later entry for
-- a given lhs wins, so this survives fzf-lua loading.
return {
  {
    "ibhagwan/fzf-lua",
    keys = {
      { "<leader>uC", pick_colorscheme, desc = "Colorscheme" },
      -- <leader>th used to open telescope's colorscheme list (telescope removed
      -- 2026-07-26); same muscle memory, better picker.
      { "<leader>th", pick_colorscheme, desc = "Pick colorscheme" },
      -- <leader>tt is the terminal (config/keymaps.lua), so the quick swap gets
      -- `tp` — previous theme.
      { "<leader>tp", swap_previous, desc = "Swap to previous colorscheme" },
    },
  },
}
