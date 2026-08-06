-- focus-fx.lua -- "which window am I in" cues, ported from the tmux setup.
--
-- Four independent features, all toggleable via :FocusFx <name>:
--   ring    -- WinSeparator lines touching the active window light up bright,
--              everything else stays dim. Port of tmux @active_col: a neighbour
--              lights only when the separator it owns lies ENTIRELY against the
--              active window (its span is contained in the active window's);
--              partial overlaps defer to dim, so nothing over-lights. (A lit
--              neighbour brightens all of its own separators -- same blind spot
--              the tmux fix has.)
--   dim     -- inactive windows' text fg pulled toward grey via tint.nvim
--              (per-window hl namespaces: fg only, nothing global, no ratchet)
--   stripe  -- 1-cell vertical mode-coloured stripe hugging the active
--              window's left edge (a tmux pane chip rotated 90 degrees).
--              Colours are the tmux identity set: phosphor green normal,
--              #FF8500 insert, teal visual, red replace.
--   numbers -- active window's line numbers brighten toward Normal fg with a
--              glowing current line; inactive windows' numbers fade into the
--              background. Derived from the live theme, so it survives switches.
--   jump    -- the beacon pulse for cursor teleports WITHIN a window (n, }, G,
--              gg, <C-o>, <C-d>), not just on window change. Fires only past
--              JUMP_MIN_LINES so ordinary j/k motion never strobes.
--   modenum -- the current line NUMBER takes the mode colour (same identity
--              palette as the stripe). Normal mode keeps the theme colour.
--
-- All theme-derived groups are re-stamped on ColorScheme (same idiom as
-- punct-split.lua), so :ThemeReload and the picker keep everything intact.
-- winhighlight is MERGED per window: keys owned by other plugins are preserved,
-- only FocusFx* targets are added/removed.

-- NO BACKGROUND FEATURES. A per-file bg tint was built here once (07-30) and
-- ratcheted brighter on every window swap: the theme pipeline recaptures
-- Normal from the live window, so it adopted the tint as the new baseline and
-- the next tint compounded on top. Backgrounds belong to the theme. fg only.

local M = { active = 0, sc_orig_expr = nil }
_G.FocusFx = M

-- state ----------------------------------------------------------------------
local enabled = {
  ring = true, stripe = true, numbers = true, dim = true, names = true, beacon = false,
  jump = false, modenum = true,
}
-- beacon/jump are OFF and stay off (2026-08-05). The pulse mapped CursorLine to
-- an underline, i.e. a cyan bar across the whole current line for 180ms on every
-- window swap and every >=15 line jump. Jimmy: "i never wanted that beacon shit
-- i can clearly see my thick ass cursor already". No horizontal bars in nvim
-- ([[no-more-horizontal-bars-in-nvim]]) -- do not re-enable either flag, and do
-- not reintroduce the cue in another form.
for k, v in pairs(vim.g.focusfx or {}) do
  if enabled[k] ~= nil then enabled[k] = v end
end

-- colour helpers -------------------------------------------------------------
local function hl(name)
  local ok, h = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  return ok and h or {}
end

local function to_rgb(n)
  return math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256
end

local function to_hex(r, g, b)
  return string.format("#%02x%02x%02x", r, g, b)
end

-- mix a toward b by t (0..1)
local function blend(a, b, t)
  if not a or not b then return nil end
  local ar, ag, ab = to_rgb(a)
  local br, bg, bb = to_rgb(b)
  return to_hex(ar + (br - ar) * t, ag + (bg - ag) * t, ab + (bb - ab) * t)
end

-- theme-derived groups, re-stamped on every ColorScheme -----------------------
local colorscheme_generation = 0

local function stamp_highlights()
  local normal = hl("Normal")
  local bg, fg = normal.bg, normal.fg
  local sep = hl("WinSeparator").fg or fg
  local linenr = hl("LineNr").fg or fg
  local curnr = hl("CursorLineNr").fg or fg

  -- ring: bright = theme accent pushed toward white; dim = separator sunk to bg
  local accent = hl("Function").fg or hl("Special").fg or 0x66fff2
  -- active must clear the STOCK look, not just the dimmed one: on some themes
  -- (his) stock LineNr == Normal fg and stock WinSeparator is already bright,
  -- so "brighten toward fg" derivations land on colours he already sees
  M.ring_base = blend(accent, 0xffffff, 0.55)
  vim.api.nvim_set_hl(0, "FocusFxRingOn", { fg = M.ring_base, bold = true })
  -- `bg or 0x000000` is load-bearing, do not shorten back to `bg and ... or sep`.
  -- Transparency nils Normal's bg (^Normal$ is in theme.lua's
  -- transparent_bg_groups), so the old form skipped the blend and handed the dim
  -- state the RAW separator colour -- RingOff == RingOn, every separator painted
  -- lit, and the ring looked dead no matter what the geometry decided
  -- (measured 2026-07-31: both groups resolved to #c0e9ff). With no window bg to
  -- sink toward, sink toward the terminal's black, which is what transparency
  -- actually shows through to.
  vim.api.nvim_set_hl(0, "FocusFxRingOff", { fg = blend(sep, bg or 0x000000, 0.62) or sep })
  -- beacon: underline pulse on landing; no backgrounds, underline + sp only
  vim.api.nvim_set_hl(0, "FocusFxBeacon", { underline = true, sp = "#66fff2" })
  vim.api.nvim_set_hl(0, "FocusFxBeaconNr", { fg = "#66fff2", bold = true })

  -- numbers
  -- Same transparency trap as the ring above: gating on `bg` meant that under a
  -- transparent Normal these groups were never defined at all, so the
  -- LineNr:FocusFxNumOff mapping pointed at nothing. Sink toward terminal black.
  local sink = bg or 0x000000
  if fg then
    vim.api.nvim_set_hl(0, "FocusFxNumOn", { fg = blend(linenr, 0xffffff, 0.30) })
    -- Remembered so set_stripe_mode can hand the current-line number back to the
    -- theme when you return to normal mode. Derive it ONCE here, never from the
    -- live group: FocusFxCurNumOn is what CursorLineNr points at, so re-reading
    -- it would feed a mode colour back into the next blend and ratchet.
    M.curnum_base = blend(curnr, 0xffffff, 0.45)
    vim.api.nvim_set_hl(0, "FocusFxCurNumOn", { fg = M.curnum_base, bold = true })
    vim.api.nvim_set_hl(0, "FocusFxNumOff", { fg = blend(linenr, sink, 0.72) })
  end

  -- stripe off-state matches the window background (terminal black when the
  -- theme is transparent -- a nil fg here left the off-stripe undrawn)
  vim.api.nvim_set_hl(0, "FocusFxStripeOff", { fg = to_hex(to_rgb(bg or 0x000000)), bg = "NONE" })
  M.set_stripe_mode(vim.api.nvim_get_mode().mode)
end

-- ring geometry: does neighbour n fully span the active window's shared edge? -
local function lit_by_ring(win, active)
  if win == active then return true end
  local ok, cfg = pcall(vim.api.nvim_win_get_config, active)
  if not ok or cfg.relative ~= "" then return false end
  local ar, ac = unpack(vim.api.nvim_win_get_position(active))
  local aw, ah = vim.api.nvim_win_get_width(active), vim.api.nvim_win_get_height(active)
  local nr, nc = unpack(vim.api.nvim_win_get_position(win))
  local nw, nh = vim.api.nvim_win_get_width(win), vim.api.nvim_win_get_height(win)
  -- tmux @active_col rule, ported: nvim can only light a separator in FULL (one
  -- hl group per window), so a neighbour may light only when the entire
  -- separator it owns sits against the active window -- i.e. the neighbour's
  -- span is CONTAINED in the active window's span. Partial overlap (a
  -- full-height window beside a half-height active one) stays dim; lighting it
  -- would run the bright line past the active window, top to bottom.
  if nc + nw + 1 == ac and nr >= ar and nr + nh <= ar + ah then return true end
  if nr + nh + 1 == ar and nc >= ac and nc + nw <= ac + aw then return true end
  return false
end

-- winhighlight merge: strip anything pointing at a FocusFx group, keep the
-- rest of the window's entries untouched, then re-add ours
local function apply_winhl(win)
  local map, order = {}, {}
  for pair in (vim.wo[win].winhighlight or ""):gmatch("[^,]+") do
    local from, to = pair:match("^(.-):(.*)$")
    if from and not to:match("^FocusFx") then
      if not map[from] then order[#order + 1] = from end
      map[from] = to
    end
  end
  local function set(from, to)
    if to and not map[from] then order[#order + 1] = from end
    if to or map[from] then map[from] = to end
  end

  local is_active = win == M.active
  local is_float = vim.api.nvim_win_get_config(win).relative ~= ""

  if enabled.ring and not is_float then
    set("WinSeparator", lit_by_ring(win, M.active) and "FocusFxRingOn" or "FocusFxRingOff")
  end
  if enabled.numbers and not is_float then
    set("LineNr", is_active and "FocusFxNumOn" or "FocusFxNumOff")
    if is_active then set("CursorLineNr", "FocusFxCurNumOn") end
  end

  -- keep an in-flight beacon pulse alive across rebuilds (scheduled
  -- apply_alls otherwise strip it mid-pulse)
  if M.beacon_win == win then
    set("CursorLine", "FocusFxBeacon")
    set("CursorLineNr", "FocusFxBeaconNr")
  end

  local parts = {}
  for _, from in ipairs(order) do
    if map[from] then parts[#parts + 1] = from .. ":" .. map[from] end
  end
  vim.wo[win].winhighlight = table.concat(parts, ",")
end

local function apply_all()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    pcall(apply_winhl, win)
  end
end

-- stripe ----------------------------------------------------------------------
local MODE_COLOR = {
  n = "#00b012", i = "#FF8500", v = "#be73ff", V = "#be73ff", ["\22"] = "#be73ff",
  R = "#ff4444", c = "#e8d44d", t = "#FF8500",
}
-- chip/ring accents per mode; normal falls back to the identity teal / the
-- theme-derived ring colour. #be73ff is the live tmux @copy_mode_color.
local MODE_ACCENT = {
  i = "#FF8500", v = "#be73ff", V = "#be73ff", ["\22"] = "#be73ff", R = "#ff4444",
}

function M.mode_accent()
  return MODE_ACCENT[vim.api.nvim_get_mode().mode:sub(1, 1)]
end

function M.set_stripe_mode(mode)
  local key = mode:sub(1, 1)
  vim.api.nvim_set_hl(0, "FocusFxStripe", { fg = MODE_COLOR[key] or MODE_COLOR.n, bg = "NONE" })
  -- ring follows mode too (tmux copy-mode tint, frame-wide)
  vim.api.nvim_set_hl(0, "FocusFxRingOn", { fg = MODE_ACCENT[key] or M.ring_base or "#66fff2", bold = true })
  -- ...and so does the current line NUMBER. The stripe already carries mode, but
  -- it sits on the window's far left edge and your eyes are on the cursor. Same
  -- identity palette, read where you are actually looking.
  --
  -- MODE_ACCENT has no `n` entry on purpose: normal mode falls back to the
  -- theme-derived colour, so the resting look is byte-identical to before this
  -- existed and only insert/visual/replace tint.
  if enabled.modenum and M.curnum_base then
    vim.api.nvim_set_hl(0, "FocusFxCurNumOn", { fg = MODE_ACCENT[key] or M.curnum_base, bold = true })
  end
  pcall(function() require("incline").refresh() end)
  -- bufferline: the active tab's neon underline follows mode too (same
  -- identity palette as stripe/ring/chip). Only the sp (underline colour) is
  -- rewritten -- no derivation from live values, so it cannot ratchet; groups
  -- without underline (theme swaps, user overrides) are left alone.
  -- enumerated live, not a static list: bufferline mints per-filetype icon
  -- groups (BufferLineDevIconYamlSelected, ...) that also carry the underline
  local sp = MODE_ACCENT[key] or "#66fff2"
  local groups = vim.fn.getcompletion("BufferLine", "highlight")
  for _, g in ipairs(type(groups) == "table" and groups or {}) do
    if g:find("Selected$") then
      local ok, h = pcall(vim.api.nvim_get_hl, 0, { name = g, link = false })
      if ok and h.underline then
        h.sp = sp
        -- bufferline registers these with default=true; passing that back
        -- makes set_hl a no-op against the existing group, so the stamp
        -- never lands
        h.default = nil
        pcall(vim.api.nvim_set_hl, 0, g, h)
      end
    end
  end
end

-- stripe fragment for one window. MUST NEVER THROW: this runs inside the
-- redraw path, and an error here gets routed through noice, whose popup
-- redraw re-evaluates the statuscolumn -- an instant self-feeding error loop
-- (nui border windows hand us winids that are already invalid by eval time).
local function stripe_for(win)
  if not enabled.stripe or type(win) ~= "number" or not vim.api.nvim_win_is_valid(win) then
    return ""
  end
  if vim.api.nvim_win_get_config(win).relative ~= "" then return "" end
  local buf = vim.api.nvim_win_get_buf(win)
  if vim.bo[buf].buftype ~= "" then return "" end
  return win == M.active and "%#FocusFxStripe#▎%*" or "%#FocusFxStripeOff# %*"
end

local FALLBACK = "%s%C%=%{v:virtnum > 0 ? '' : (&number ? (&relativenumber && v:relnum ? v:relnum : v:lnum) : '')} "

-- Resolve a "v:lua.Foo.bar()" expr to the lua function itself. nvim REJECTS
-- re-entrant VimL eval inside statuscolumn drawing (nvim_eval here kills the
-- whole item and the gutter draws BLANK), so the original must be called as
-- lua, never through nvim_eval.
local function orig_fn()
  if M.sc_fn ~= nil then return M.sc_fn or nil end
  local path = (M.sc_orig_expr or ""):match("^v:lua%.([%w_%.]+)%(%)$")
  local fn = _G
  for part in (path or ""):gmatch("[^%.]+") do
    fn = type(fn) == "table" and fn[part] or nil
  end
  M.sc_fn = type(fn) == "function" and fn or false
  return M.sc_fn or nil
end

-- statuscolumn entry point: stripe char, then whatever was there before
function M.statuscolumn()
  local ok, stripe = pcall(stripe_for, vim.g.statusline_winid)
  if not ok then stripe = "" end
  local rest = FALLBACK
  local fn = orig_fn()
  if fn then
    local ok2, out = pcall(fn)
    if ok2 and type(out) == "string" then rest = out end
  end
  return stripe .. rest
end

local function hook_statuscolumn()
  local orig = vim.o.statuscolumn
  if orig:find("FocusFx", 1, true) then return end
  local expr = orig:match("^%%!(.*)$")
  if expr then
    M.sc_orig_expr = expr
  elseif orig ~= "" then
    -- plain statusline-style value: keep it verbatim after the stripe
    vim.o.statuscolumn = "%{%v:lua.FocusFx.statuscolumn_prefix()%}" .. orig
    return
  end
  vim.o.statuscolumn = "%{%v:lua.FocusFx.statuscolumn()%}"
end

-- prefix-only variant used when the original value was a plain format string
function M.statuscolumn_prefix()
  local ok, stripe = pcall(stripe_for, vim.g.statusline_winid)
  return ok and stripe or ""
end

-- wiring ----------------------------------------------------------------------
local group = vim.api.nvim_create_augroup("FocusFx", { clear = true })

-- beacon: ~180ms underline pulse on the landed line; restored by re-running
-- the normal winhl merge, so it can never leave residue.
--
-- The token exists because the jump beacon can re-pulse the same window before
-- the previous pulse's timer fires (n n n through a file lands three jumps in
-- under 180ms). Without it the FIRST timer clears M.beacon_win and strips the
-- SECOND pulse early, so a fast sequence flickers instead of pulsing.
local beacon_token = 0
local function beacon(win)
  if not enabled.beacon or not vim.api.nvim_win_is_valid(win) then return end
  if vim.api.nvim_win_get_config(win).relative ~= "" then return end
  beacon_token = beacon_token + 1
  local token = beacon_token
  M.beacon_win = win
  pcall(apply_winhl, win)
  vim.defer_fn(function()
    if token ~= beacon_token then return end
    if M.beacon_win == win then M.beacon_win = nil end
    if vim.api.nvim_win_is_valid(win) then pcall(apply_winhl, win) end
  end, 180)
end

-- jump beacon: the same pulse for cursor teleports WITHIN a window -- n, }, G,
-- gg, <C-o>, <C-d>. Those are where "which line am I on now" actually bites;
-- WinEnter only covers changing window.
--
-- Only a jump, never a walk: j/k/w/b move a line or two and pulsing on those
-- would strobe the whole file. Anything under the threshold just updates the
-- remembered row silently.
local JUMP_MIN_LINES = 15
local last_row = {}

local function jump_beacon()
  if not enabled.jump then return end
  local win = vim.api.nvim_get_current_win()
  if win ~= M.active then return end
  if vim.api.nvim_win_get_config(win).relative ~= "" then return end
  local buf = vim.api.nvim_win_get_buf(win)
  if vim.bo[buf].buftype ~= "" then return end

  local row = vim.api.nvim_win_get_cursor(win)[1]
  local prev = last_row[win]
  last_row[win] = { buf = buf, row = row }
  -- A new buffer in this window is not a jump: the cursor did not travel, the
  -- ground moved under it. BufWinEnter/WinEnter own that cue.
  if not prev or prev.buf ~= buf then return end
  if math.abs(row - prev.row) >= JUMP_MIN_LINES then
    beacon(win)
  end
end

vim.api.nvim_create_autocmd({ "WinEnter", "VimEnter" }, {
  group = group,
  callback = function()
    local prev = M.active
    M.active = vim.api.nvim_get_current_win()
    if prev and prev > 0 and prev ~= M.active and vim.api.nvim_win_is_valid(prev) then M.last = prev end
    apply_all()
    if prev ~= M.active then beacon(M.active) end
  end,
})
vim.api.nvim_create_autocmd({ "WinResized", "WinNew", "WinClosed", "BufWinEnter" }, {
  group = group,
  callback = function()
    vim.schedule(apply_all)
  end,
})
vim.api.nvim_create_autocmd("CursorMoved", {
  group = group,
  callback = jump_beacon,
})
vim.api.nvim_create_autocmd("WinClosed", {
  group = group,
  callback = function(ev)
    last_row[tonumber(ev.match)] = nil
  end,
})
vim.api.nvim_create_autocmd("ColorScheme", {
  group = group,
  callback = function()
    stamp_highlights()
    apply_all()
    -- the theme pipeline re-stamps knobs in deferred passes up to 900ms after
    -- ColorScheme; re-derive once more after they have all landed.
    --
    -- Generation-guarded: stamp_highlights DERIVES from the live LineNr /
    -- WinSeparator / accent and blends them toward white, so running it twice
    -- over one theme ratchets. <leader>uC previews on a 120ms debounce, so a
    -- normal scroll leaves three or four of these queued and they all fire
    -- against whichever theme you stopped on — measured as four successive
    -- brightening steps (nord LineNr e3e7ef -> f8f8fa) versus one on a settled
    -- load. Only the newest switch's re-derive may run.
    colorscheme_generation = colorscheme_generation + 1
    local gen = colorscheme_generation
    vim.defer_fn(function()
      if gen ~= colorscheme_generation then
        return
      end
      pcall(stamp_highlights)
      pcall(apply_all)
    end, 1100)
  end,
})
vim.api.nvim_create_autocmd("ModeChanged", {
  group = group,
  callback = function()
    -- modenum rides the same handler, so it must survive `:FocusFx stripe` off
    if enabled.stripe or enabled.modenum then
      M.set_stripe_mode(vim.api.nvim_get_mode().mode)
      -- never redraw synchronously from ModeChanged: noice's cmdline lives in
      -- this event's dispatch and a forced redraw here can recurse into it
      vim.schedule(function() pcall(vim.cmd, "redraw") end)
    end
  end,
})
vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  callback = function()
    stamp_highlights()
    hook_statuscolumn()
  end,
})

-- zoom: <C-w>z, tmux prefix-z in nvim. Tab-split trick: the zoomed buffer
-- opens in its own tab; closing the tab restores the split layout untouched.
function M.zoom_toggle()
  if vim.t.focusfx_zoom then
    vim.cmd("tabclose")
  elseif #vim.api.nvim_tabpage_list_wins(0) > 1 then
    vim.cmd("tab split")
    vim.t.focusfx_zoom = true
  else
    vim.notify("FocusFx: nothing to zoom (single window)")
  end
end
vim.keymap.set("n", "<C-w>z", M.zoom_toggle, { desc = "Zoom window (tmux prefix-z)" })

-- <leader>;: back to the previous window (the ↩ chip) -- mirrors tmux prefix-;
vim.keymap.set("n", "<leader>;", function()
  vim.cmd("wincmd p")
end, { desc = "Go to last window (↩)" })

-- numeric jump: <leader>N goes to the window whose chip shows N
for i = 1, 9 do
  vim.keymap.set("n", "<leader>" .. i, function()
    vim.cmd(i .. "wincmd w")
  end, { desc = "Go to window " .. i })
end

vim.api.nvim_create_user_command("FocusFx", function(opts)
  local what = opts.fargs[1]
  if what == "all" then
    for k in pairs(enabled) do enabled[k] = true end
  elseif what == "off" then
    for k in pairs(enabled) do enabled[k] = false end
  elseif enabled[what] ~= nil then
    enabled[what] = not enabled[what]
  else
    local state = {}
    for k, v in pairs(enabled) do state[#state + 1] = k .. "=" .. (v and "on" or "off") end
    table.sort(state)
    vim.notify("FocusFx: " .. table.concat(state, "  "))
    return
  end
  vim.g.focusfx = enabled
  local ok, tint = pcall(require, "tint")
  if ok then
    if enabled.dim then pcall(tint.enable) else pcall(tint.disable) end
  end
  local ok2, incline = pcall(require, "incline")
  if ok2 then
    if enabled.names then pcall(incline.enable) else pcall(incline.disable) end
  end
  apply_all()
  vim.cmd("redraw!")
end, {
  nargs = "?",
  complete = function() return { "ring", "dim", "names", "stripe", "numbers", "beacon", "all", "off" } end,
})

-- dim: inactive windows' TEXT fg pulled toward grey -- the tmux
-- window-style/window-active-style move (#006009 vs #00b012), in nvim.
-- tint.nvim uses per-window highlight NAMESPACES: nothing global is mutated,
-- nvim_get_hl(0) never sees the dimmed values, so the theme pipeline's
-- recapture cannot ratchet. fg only; backgrounds stay untouched.
return {
  {
    "levouh/tint.nvim",
    event = "VeryLazy",
    opts = {
      tint = -20,
      saturation = 0.55,
      tint_background_colors = false,
      highlight_ignore_patterns = { "WinSeparator", "Status.*", "FocusFx.*" },
      window_ignore_function = function(winid)
        return vim.api.nvim_win_get_config(winid).relative ~= ""
          or vim.wo[winid].diff
      end,
    },
    config = function(_, opts)
      require("tint").setup(opts)
      if not enabled.dim then pcall(require("tint").disable) end
    end,
  },
  -- names: per-window chip in the top-right corner, styled after the tmux
  -- pane-border-format chips (index block + name block). A floating chip
  -- pinned to its window, NOT a winbar -- no full-width bar, draws only the
  -- chip cells. Colours are the tmux chip identity: active #66fff2 on dark,
  -- inactive #307a74. Our own hl, never the theme's.
  {
    "b0o/incline.nvim",
    event = "VeryLazy",
    opts = {
      window = {
        margin = { vertical = 0, horizontal = 0 },
        placement = { vertical = "top", horizontal = "right" },
        zindex = 30,
        -- 2026-07-31: incline default padding is 1, drawn as `padding_char`
        -- (a space) on the FLOAT's own Normal -- i.e. an opaque cell sitting
        -- outside the pill caps. Under transparency that is visible black
        -- filler. The caps already shape the chip; no padding needed.
        padding = 0,
      },
      -- The chip's own float background. incline defaults InclineNormal and
      -- InclineNormalNC to the `NormalFloat` GROUP, which is opaque -- so a
      -- transparent `guibg` on the rendered parts just falls through to this
      -- and the chip still reads as a black rectangle. This is the layer that
      -- actually had to change; the render-side fix alone did nothing.
      highlight = {
        groups = {
          InclineNormal = { guibg = "NONE" },
          InclineNormalNC = { guibg = "NONE" },
        },
      },
      -- only_win=false: the chip must survive into the zoom tab (single
      -- window) to carry the ZOOM tag, like the tmux ZOOMED banner
      hide = { cursorline = false, focused_win = false, only_win = false },
      render = function(props)
        local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
        if name == "" then name = "[scratch]" end
        if vim.bo[props.buf].modified then name = name .. " ●" end
        local idx = vim.api.nvim_win_get_number(props.win)
        local parts
        -- pill caps (U+E0B6 left / U+E0B4 right, as byte escapes: the raw glyphs: each cap is a single-colour glyph on a
        -- get eaten by some editors; single-colour glyph on default bg renders sharp
        -- under the shader -- see starship-chevron-bleed memory)
        -- 2026-07-31: the name block used to sit on an opaque "#101410". Same
        -- trap as bufferline.lua's CHIP_BG -- under ghostty background-opacity
        -- that slab is the only thing in the chip that does NOT see through, so
        -- it read as a black box hanging off the accent index block. NONE lets
        -- the terminal show; the accent index block still carries the identity.
        local CHIP_BG = "NONE"
        -- 2026-08-03: cap/interior alpha match. Measured off a screenshot, the
        -- cap rendered at alpha 1.0 while the accent index block (a cell
        -- BACKGROUND) took ghostty's background-opacity 0.9 -- a 9% brighter
        -- edge. `dim` makes ghostty draw the glyph at faint-opacity, which is
        -- kept equal to background-opacity, so the two match by construction
        -- (same trick as the tmux pills; see config.ghostty's header comment).
        --
        -- It MUST go through nvim_set_hl + `group`: incline renders styles as
        -- `:highlight ... gui=<val>`, and vim's gui= attr-list has no `dim`
        -- (bold/italic/underline/reverse/... only). `gui = "dim"` silently does
        -- nothing. nvim_set_hl DOES take dim=true, and incline's `group` key
        -- links to it, so the attribute survives.
        local function cap_hl(name, fg)
          vim.api.nvim_set_hl(0, name, { fg = fg, dim = true })
          return name
        end
        if props.focused then
          -- chip follows mode, like the stripe/ring (insert orange, visual
          -- #be73ff = tmux @copy_mode_color); normal keeps the identity teal
          local accent = (_G.FocusFx and _G.FocusFx.mode_accent and _G.FocusFx.mode_accent()) or "#66fff2"
          parts = {
            { "\238\130\182", group = cap_hl("InclineCapFocus", accent) },
            { idx .. " ", guifg = "#080808", guibg = accent, gui = "bold" },
            { " " .. name .. " ", guifg = accent, guibg = CHIP_BG },
          }
        else
          parts = {
            { "\238\130\182", group = cap_hl("InclineCapNC", "#307a74") },
            { idx .. " ", guifg = "#080808", guibg = "#307a74" },
            { " " .. name .. " ", guifg = "#307a74", guibg = CHIP_BG },
          }
        end
        -- pane_last dash port: mark where <C-w>p snaps back to
        if _G.FocusFx and props.win == _G.FocusFx.last and not props.focused then
          table.insert(parts, { "↩ ", guifg = "#66fff2", guibg = CHIP_BG })
        end
        -- tmux ZOOMED banner port
        if vim.t.focusfx_zoom then
          table.insert(parts, { " ZOOM ", guifg = "#080808", guibg = "#00ffc8", gui = "bold" })
        end
        -- closing cap takes the colour of whatever block ends the chip. If that
        -- block is transparent there is no slab left to cap, and a cap glyph
        -- drawn in "NONE" is not a colour -- so emit it only for a real bg
        -- (the ZOOM banner's #00ffc8 still gets its cap).
        local tail_bg = parts[#parts].guibg
        if tail_bg and tail_bg ~= "NONE" then
          table.insert(parts, { "\238\130\180", group = cap_hl("InclineCapTail", tail_bg) })
        end
        return parts
      end,
    },
    config = function(_, opts)
      require("incline").setup(opts)
      if not enabled.names then pcall(require("incline").disable) end
    end,
  },
}
