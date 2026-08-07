-- Single enclosing indent guide.
--
-- The rule: exactly ONE guide is lit at any time -- the vertical line
-- immediately enclosing the cursor (the guide just left of the block you are
-- in). When the cursor sits in the shallowest nested block, the furthest-left
-- guide (col 0) lights; go one level deeper and the next guide to the right
-- lights instead; never more than one.
--
-- Why this exists instead of snacks' own scope highlight: snacks lit the guide
-- at the *inside* column of the block (scope.indent) and drew nothing on leaf
-- `key: value` lines, so it was consistently one level too deep and usually
-- invisible. Snacks' scope rendering is therefore disabled in indent.lua; snacks
-- still paints all the DIM guides (SnacksIndent) and this overlay recolours just
-- the single enclosing column on top of them.
--
-- The lit colour is whatever SnacksIndentScope resolves to (theme.lua pins it to
-- maxed cyan #00ffff on the storm theme), so the theme stays the source of truth
-- for the guide colour.

local enabled = true
if not enabled then
  pcall(function()
    local ns = vim.api.nvim_create_namespace("indent_ladder")
    pcall(vim.api.nvim_create_augroup, "IndentLadder", { clear = true })
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      pcall(vim.api.nvim_buf_clear_namespace, buf, ns, 0, -1)
    end
  end)
  return {}
end

local config = {
  char = "│", -- matches snacks' DEFAULT indent char (indent.lua never overrides it)
  hl = "SnacksIndentScope", -- theme.lua pins this to the maxed cyan on storm
  priority = 250, -- above snacks' dim guides (priority 1) so our colour wins
}

-- Guide animation.
--
-- Snacks' own `animate` is not in play here -- indent.lua disables snacks' scope
-- rendering entirely, so this overlay has to do its own. When the enclosing guide
-- CHANGES (different column, or a different block at the same column) the line
-- grows out from the cursor row toward both ends of the block instead of snapping
-- in at full length.
--
-- Moving around WITHIN the same block does not restart it, and neither does
-- scrolling: the animation key is built from the block's raw (unclamped) extent,
-- while only the drawing is clamped to the visible window. Without that, every
-- CursorMoved/WinScrolled would retrigger the grow and the guide would strobe.
local anim = {
  enabled = true, -- set false for the old instant-snap behaviour
  duration = 450, -- ms for the guide to reach the block's full extent
  -- 120 is affordable now that the ramp is precomputed: a frame costs 4 set_hl
  -- calls plus extmark updates for the handful of rows whose group changed. The
  -- old build-33-groups-per-frame version could not even keep 60.
  fps = 120,
  -- The fill lasts 450ms; the breathe runs FOREVER while the cursor sits in a
  -- scope. Holding 120fps for that endless tail is what cooked the laptop: every
  -- distinct colour is a set_hl and therefore a full screen redraw, so an idle
  -- editor was doing 120 redraws/sec indefinitely. The fill genuinely needs the
  -- frames (fast motion, short window); the breathe is a 2.6s cycle where 20fps
  -- is visually identical. The timer drops to this rate the moment t hits 1.
  breathe_fps = 20,
  -- Once the guide is FULLY filled it breathes: a slow, endless fade up toward
  -- white and back down to the resting colour, for as long as the cursor stays in
  -- the scope. Deliberately NOT a one-shot flash during the fill -- that read as
  -- an ugly strobe, and the rows that lit last never got to flash at all.
  -- The two ends of the breathe, on a brightness axis where 0 is the DIM ladder
  -- colour (the guide fades until it is indistinguishable from every other guide,
  -- i.e. reads as fully dark/off), 1 is the resting lit colour, and >1 pushes on
  -- past it toward white. So 0 -> 1 is a full dark-to-max swing.
  breathe = true, -- false disables the breathe; the guide just rests when filled
  -- 0.0 is CORRECT and deliberate: the swing must go from max contrast all the
  -- way down to nothing. Do NOT raise this to "soften" the fade -- tried 0.55
  -- on 2026-07-31 and it was immediately rejected ("how the fuck is it fading
  -- like halfway only now"). A partial swing is the bug, not the fix.
  breathe_min = 0.0,
  breathe_max = 1.0,
  -- ms for one full bright -> dark -> bright cycle.
  --
  -- 2026-07-31: tried 1400 (rejected, frantic) and a cosine->triangle waveform
  -- blend to cut the dwell at black (rejected, caused horizontal flicker: the
  -- linear ramp produces a distinct colour nearly every frame, and every
  -- distinct colour is a set_hl and therefore a FULL SCREEN REDRAW -- the
  -- cosine's dwell was actually load-bearing, it lets most frames dedupe out).
  -- Everything is back to the original values. Do not retune this without
  -- Jimmy watching it live.
  breathe_period = 2600,
  -- HOLD AT FULL BRIGHTNESS BEFORE THE FIRST DIP (2026-08-02).
  --
  -- The breathe used to start at exactly t=1, and t=1 is the instant the fill's
  -- trailing gradient FINALLY reaches the last row (edge_down hits to+trail at
  -- p=1). So the bottom of the guide arrived at full brightness in the same
  -- frame the down-swing began: the tail crossed max on its way down and never
  -- rested there. Jimmy: "I want the flashing to start AFTER the line has
  -- finished filling up ... it doesn't start going dim while it's still filling
  -- up resulting in some weird dim ass shit."
  --
  -- During the hold the animation sits at p=1 / level=1, which draws the WHOLE
  -- block fully lit -- so what you see is the completed guide, held, and only
  -- then does it breathe. 0 restores the old back-to-back behaviour.
  breathe_delay = 400,
  -- TRANSPARENT (gday) MODE: cycle hue instead of fading (2026-08-05).
  --
  -- Fading to nothing is impossible under transparency -- see the long block in
  -- animate(). Jimmy's call once that was established: "keep the hue change,
  -- make it go through the 3 gruvbox colors I've set ... the fading in and out
  -- wont work during daytime." These three are his own, from starship.toml:
  -- seg_os (#aaff00), seg_dir (#2ff5ff), seg_time (#ffc21e). #2ff5ff is also
  -- what the guide already rests at, so the cycle starts on the colour the fill
  -- lands on and there is no jump into it.
  --
  -- Brightness never changes, so the guide never approaches the backdrop and the
  -- dim bar cannot occur. That is the POINT of this shape, not a side effect --
  -- do not add a brightness component to it.
  --
  -- 2026-08-06: these three are now only the FALLBACK. By default the cycle is
  -- derived from the colorscheme itself (`cycle_from_theme`), so gday on gruvbox
  -- cycles gruvbox's own hues instead of the starship trio. The starship colours
  -- stay here because they are still the right answer when a theme has nothing
  -- saturated enough to sample (see derive_cycle).
  cycle_colors = { "#2ff5ff", "#aaff00", "#ffc21e" },
  -- Sample the live colorscheme for the cycle instead of using cycle_colors.
  -- Set false to pin cycle_colors for every theme.
  cycle_from_theme = true,
  -- How many hues in the loop. 3 is the shape everything was tuned against; 4+
  -- shortens each leg (each leg gets CYCLE_STEPS/n frames).
  cycle_count = 3,
  -- A sampled colour is only a candidate above these. Below them a theme's
  -- greys and muted comment colours get picked and the "cycle" turns into a
  -- brightness wobble -- which is the one thing this shape must never do.
  cycle_min_sat = 0.30,
  cycle_min_val = 0.35,
  -- Per-colorscheme overrides: cycle_overrides["gruvbox"] = { "#...", ... }.
  -- Set at runtime with :IndentCycle (persisted) or edited here. Beats
  -- derivation; loses to nothing except :IndentColor pinning the FIRST entry.
  cycle_overrides = {},
  -- Milliseconds for one full trip through all three and back to the first.
  cycle_period = 7800,
  -- How many breathe cycles before the guide settles at its resting colour and
  -- the timer SHUTS DOWN. An endless breathe means a parked editor never stops
  -- waking the CPU and repainting -- on battery that is the whole cost of this
  -- plugin. After this many cycles the guide is drawn once, plain, and there is
  -- literally zero ongoing work until the cursor enters a new scope. Set to nil
  -- for the old forever-breathe.
  -- 3 is correct. Tried 1 on 2026-07-31 and it read as STATIC: the animation
  -- only re-triggers on ENTERING a new scope, so a single slow swing is one
  -- barely-perceptible dip and then nothing forever. It takes repeats to read
  -- as breathing at all. Do not lower this to shorten the animation.
  breathe_cycles = 3,

  -- Rows in the soft leading-edge gradient. Geometry lands on whole lines, so the
  -- only smoothness available is in the colour channel: a 6-row trail reads far
  -- better than the old single softened row (which was just a staircase with one
  -- rounded corner).
  trail = 6,
}

local uv = vim.uv or vim.loop

-- The animation needs its OWN highlight groups: writing animated colours onto
-- SnacksIndentScope would fight theme.lua (which pins that group) and would leave
-- the guide stuck at whatever mid-animation colour the last frame wrote. These are
-- used only while animating; the settled guide is drawn with config.hl, so the
-- theme stays the source of truth for the resting colour.
--
-- FADE_STEPS groups form a brightness ramp used for the LEADING EDGE. Geometry is
-- quantised to whole lines -- an 8-line block can only ever be 8 distinct lengths --
-- so a longer duration spreads those few steps over more time and reads as chop.
-- Fading each row in as the edge crosses it puts the smoothness in the COLOUR
-- channel, which is continuous, so the motion stays smooth at any duration.
-- Two kinds of group, and the split is the whole performance fix.
--
-- FADE_* is the trail ramp, dim -> resting colour. It never changes during an
-- animation, so it is built ONCE and reused every frame.
-- GLOW is the single group every FULLY lit row shares. It is the only thing
-- rewritten per frame, so a frame costs exactly ONE nvim_set_hl -- and during
-- the breathe, zero extmark churn, because every row already points at it.
--
-- The old version rebuilt all 33 groups every frame (~2000 set_hl/sec). Each one
-- invalidates highlight state and forces a redraw, which starved the loop badly
-- enough that only a few frames ever landed: that is what made the fill look like
-- a slideshow.
local FADE_PREFIX = "IndentLadderFade" -- static trail ramp: dim -> base
local FADE_STEPS = 48 -- ramp resolution; higher = smoother trail
local GLOW = "IndentLadderGlow" -- per-frame: the breathing lit colour
-- Static ramp for the UPWARD pulse (base -> white), the transparent-mode
-- breathe. It has to be a precomputed ramp for the same reason the fade one
-- does: recolouring a single group that appears only inside extmark virt_text
-- dirties no line, so the frames are computed and never painted. Walking real
-- group names per row is what actually delivers them.
local LIFT_PREFIX = "IndentLadderLift"
-- Static ramp for the transparent-mode HUE CYCLE: a closed loop through
-- anim.cycle_colors at full brightness. Precomputed for the same reason as the
-- other two ramps -- recolouring one group that lives only in extmark virt_text
-- paints nothing, so each frame has to be a real group change on the extmark.
-- The guide's RESTING group. Every static draw (settle, unfocused repaint,
-- same-scope repaint) goes through this instead of config.hl, so the guide can
-- never come to rest on the colorscheme's own scope colour -- which on his
-- gruvbox is #5f6c1f, i.e. the dim bar. Set from `base` at the start of every
-- animation; falls back to config.hl until then.
local REST = "IndentLadderRest"
local resting_hl = nil
local CYCLE_PREFIX = "IndentLadderCycle"
-- Steps around the whole loop. This must be >= the number of FRAMES in one
-- cycle, or the step and the frame beat against each other and the cycle stalls
-- and jumps: at 96 steps over cycle_period 7800ms a step lands every 81ms while
-- breathe_fps 20 paints every 50ms, so most frames repainted the same colour and
-- then lurched. Measured max per-step jump on gruvbox's derived colours: 28/765
-- at 96 steps, 16 at 192. 7800/50 = 156 frames, so 192 leaves headroom if
-- breathe_fps or cycle_period is retuned. Keep it above 1000/breathe_fps worth.
local CYCLE_STEPS = 192

local WHITE = { 255, 255, 255 }

-- How close (per RGB channel) the faded guide has to be to the backdrop before
-- its marks are REMOVED rather than painted (transparency only -- see the block
-- in animate()). This used to be a `level` threshold, which broke the moment the
-- level->colour curve changed; the distance to the backdrop is what actually
-- decides whether pulling the mark is visible, so that is what is measured.
-- 2 is a channel step you cannot see; larger values start to pop.
local CLEAR_EPSILON = 2

-- Ghostty's `background` value. Only used when Normal has no bg (transparency):
-- it is what the guide fades INTO so that "off" actually reads as off. Keep in
-- sync with `background = ...` in the Ghostty config.
local TERMINAL_BG = "#111113"

local function unpack_rgb(int)
  return math.floor(int / 0x10000) % 0x100, math.floor(int / 0x100) % 0x100, int % 0x100
end

-- Blend in LINEAR LIGHT, not in sRGB bytes: a=0 yields c1, a=1 yields c2.
--
-- 2026-08-02. Blending the raw bytes is blending an encoded signal. sRGB is
-- roughly a 2.2 gamma, so byte-halfway between the backdrop and the lit colour
-- is about 73% of the PERCEIVED brightness -- the bottom half of the swing
-- lives in bytes 0..60, where nothing is distinguishable from the backdrop,
-- especially under transparency where those bytes are competing with the
-- wallpaper. The ramp was mathematically smooth and measurably 25 steps
-- (verified live), but most of those steps were perceptually the same "dark",
-- so what you SAW was bright -> gone. Decode to linear, blend, re-encode: the
-- steps are then evenly spaced in perceived brightness, which is what the
-- cosine was always meant to be modulating.
local function srgb_to_linear(v)
  v = v / 255
  if v <= 0.04045 then
    return v / 12.92
  end
  return ((v + 0.055) / 1.055) ^ 2.4
end

local function linear_to_srgb(v)
  if v <= 0.0031308 then
    v = v * 12.92
  else
    v = 1.055 * v ^ (1 / 2.4) - 0.055
  end
  return math.max(0, math.min(255, math.floor(v * 255 + 0.5)))
end

local function blend(c1, c2, a)
  local function ch(i)
    local l1, l2 = srgb_to_linear(c1[i]), srgb_to_linear(c2[i])
    return linear_to_srgb(l1 + (l2 - l1) * a)
  end
  return { ch(1), ch(2), ch(3) }
end

local function hex(c)
  return string.format("#%02x%02x%02x", c[1], c[2], c[3])
end

-- Built once per (dim, base) pair. `:colorscheme` runs `hi clear`, which wipes
-- these, so the ColorScheme autocmd below drops the key to force a rebuild.
local ramp_key = nil

-- HSV, used by BOTH the hue cycle's interpolation (below) and the theme
-- derivation (further down). Defined here because build_cycle needs it.
local function rgb_to_hsv(c)
  local r, g, b = c[1] / 255, c[2] / 255, c[3] / 255
  local mx, mn = math.max(r, g, b), math.min(r, g, b)
  local d = mx - mn
  local h = 0
  if d > 0 then
    if mx == r then
      h = ((g - b) / d) % 6
    elseif mx == g then
      h = (b - r) / d + 2
    else
      h = (r - g) / d + 4
    end
    h = h * 60
  end
  return h, (mx > 0 and d / mx or 0), mx
end

local function hsv_to_rgb(h, s, v)
  local c = v * s
  local x = c * (1 - math.abs((h / 60) % 2 - 1))
  local m = v - c
  local r, g, b = 0, 0, 0
  local seg = math.floor(h / 60) % 6
  if seg == 0 then
    r, g, b = c, x, 0
  elseif seg == 1 then
    r, g, b = x, c, 0
  elseif seg == 2 then
    r, g, b = 0, c, x
  elseif seg == 3 then
    r, g, b = 0, x, c
  elseif seg == 4 then
    r, g, b = x, 0, c
  else
    r, g, b = c, 0, x
  end
  local function q(f)
    return math.max(0, math.min(255, math.floor((f + m) * 255 + 0.5)))
  end
  return { q(r), q(g), q(b) }
end

local function build_ramp(dim, base)
  local key = table.concat(dim, ",") .. "|" .. table.concat(base, ",")
  if key == ramp_key then
    return
  end
  for i = 0, FADE_STEPS do
    pcall(vim.api.nvim_set_hl, 0, FADE_PREFIX .. i, { fg = hex(blend(dim, base, i / FADE_STEPS)) })
    -- and the upward half: base -> white, for the transparent-mode pulse.
    pcall(vim.api.nvim_set_hl, 0, LIFT_PREFIX .. i, { fg = hex(blend(base, WHITE, i / FADE_STEPS)) })
  end
  ramp_key = key
end

-- The hue cycle's own ramp, keyed separately: it depends on cycle_colors, not on
-- the theme's dim/base pair, so it must not be rebuilt (or skipped) with them.
local cycle_key = nil

local function build_cycle(colors)
  local key = table.concat(colors, ",")
  if key == cycle_key then
    return
  end
  local n = #colors
  local hsv = {}
  for i, c in ipairs(colors) do
    local h, s, v = rgb_to_hsv({ unpack_rgb(tonumber(c:sub(2), 16)) })
    hsv[i] = { h, s, v }
  end

  -- INTERPOLATE THE HUE AROUND THE WHEEL, not the RGB channels.
  --
  -- This is why the cyan -> red-orange leg teleported. Two near-complementary
  -- colours blended in RGB (linear or not) pass through GREY: the midpoint of
  -- cyan->red is a washed pale nothing, there is no intermediate hue anywhere
  -- on the leg, so what you see is a crossfade between two colours rather than
  -- a colour changing. The eye reads a crossfade through grey as a cut.
  -- Sweeping the hue instead passes cyan -> blue -> magenta -> red, every step
  -- a real colour. It is also the only interpolation that KEEPS the constant
  -- brightness this shape depends on -- s and v are carried across unchanged
  -- when the endpoints share them, which the derived colours always do.
  --
  -- Always travel in the increasing-hue direction, so a closed loop goes one
  -- way around the wheel and the legs sum to exactly 360 degrees. Taking the
  -- shortest arc per leg independently would reverse direction on one of them
  -- and the cycle would visibly rock back and forth.

  -- Steps are allocated to each leg by its LENGTH, not evenly.
  --
  -- Giving every leg CYCLE_STEPS/n was the other half of the "slideshow on
  -- gruvbox, smooth on habamax" report: a 3-colour loop always has one long leg
  -- and two short ones, and with an even split the long leg has to cover ~3x
  -- the colour distance in the same number of frames. So the cycle crawls, then
  -- lurches. Themes whose sampled colours happen to sit close together (habamax)
  -- never showed it; saturated themes always did. Distance-proportional
  -- allocation makes the perceived SPEED constant on every leg -- measured max
  -- per-step jump on gruvbox 16 -> 12, starship 35 -> 21. In hue terms the leg
  -- length IS the arc it has to cover, so this now literally means "degrees per
  -- frame is the same on every leg".
  local legs, total = {}, 0
  for i = 1, n do
    local d = (hsv[i % n + 1][1] - hsv[i][1]) % 360
    if d < 1e-6 then
      d = 360 / n -- identical hues: give the leg a share rather than stalling
    end
    legs[i] = d
    total = total + d
  end

  for i = 0, CYCLE_STEPS - 1 do
    -- Arc travelled around a CLOSED loop: the last colour sweeps back into the
    -- first, so the cycle has no seam and no direction change.
    local t = i / CYCLE_STEPS * total
    local leg, frac, acc = n, 1, 0
    for k = 1, n do
      if t <= acc + legs[k] or k == n then
        leg = k
        frac = math.min(1, (t - acc) / math.max(legs[k], 1e-6))
        break
      end
      acc = acc + legs[k]
    end
    local a, b = hsv[leg], hsv[leg % n + 1]
    local h = (a[1] + legs[leg] * frac) % 360
    local s = a[2] + (b[2] - a[2]) * frac
    local v = a[3] + (b[3] - a[3]) * frac
    pcall(vim.api.nvim_set_hl, 0, CYCLE_PREFIX .. i, { fg = hex(hsv_to_rgb(h, s, v)) })
  end
  cycle_key = key
end

local function invalidate_ramp()
  ramp_key = nil
  cycle_key = nil
  -- `hi clear` wipes REST along with the ramps, and a cleared group renders with
  -- no highlight at all. Drop the pointer so static draws fall back to config.hl
  -- until the next animation re-pins it.
  resting_hl = nil
end

-- Resting colour of the guide, read live from the theme group each time an
-- animation starts, so retuning the theme needs no change here.
local function group_fg(name)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  if ok and type(hl) == "table" and hl.fg then
    return { unpack_rgb(hl.fg) }
  end
  return nil
end

-- ---- theme-derived hue cycle (2026-08-06) -----------------------------------
--
-- The cycle used to be three hardcoded starship colours. On a warm theme like
-- gruvbox that meant day mode lit up in colours the rest of the screen does not
-- contain. These sample the colorscheme instead.
--
-- The whole point of the cycle is CONSTANT BRIGHTNESS -- that immunity is why
-- the dim-bar failure mode is structurally impossible under transparency. So
-- sampled colours are taken for their HUE only: saturation and value are
-- flattened onto the anchor's before the ramp is built. Never let a sampled
-- value through unnormalised.

-- Sampled in this order; treesitter captures first because they are what the
-- buffer actually renders, with the classic groups as the fallback for themes
-- that only define those. Deliberately NOT sampling Comment/LineNr/NonText --
-- those are the theme's greys and would fail the saturation gate anyway.
local CYCLE_SOURCES = {
  "@function",
  "@keyword",
  "@string",
  "@constant",
  "@type",
  "@variable.member",
  "@number",
  "@operator",
  "Function",
  "Keyword",
  "String",
  "Type",
  "Constant",
  "Identifier",
  "Special",
  "Statement",
}

local function hue_dist(a, b)
  local d = math.abs(a - b) % 360
  return d > 180 and 360 - d or d
end

-- Pick `count` maximally hue-separated colours out of the theme, anchored at
-- `anchor` (the guide's resting colour, so rest == cycle start and there is no
-- jump into the cycle -- the same invariant cycle_colors[1] used to carry).
-- Returns nil when the theme has fewer than `count` usable hues, which is the
-- signal to fall back to anim.cycle_colors.
local function derive_cycle(anchor, count)
  count = math.max(2, count or 3)
  local ah = rgb_to_hsv(anchor)

  local seen, cands = {}, {}
  local sum_s, sum_v, n = 0, 0, 0
  for _, g in ipairs(CYCLE_SOURCES) do
    local c = group_fg(g)
    if c then
      local h, s, v = rgb_to_hsv(c)
      if s >= (anim.cycle_min_sat or 0.30) and v >= (anim.cycle_min_val or 0.35) then
        sum_s, sum_v, n = sum_s + s, sum_v + v, n + 1
        local bucket = math.floor(h / 12) -- collapse near-identical hues
        if not seen[bucket] then
          seen[bucket] = true
          cands[#cands + 1] = h
        end
      end
    end
  end
  if #cands < count - 1 or n == 0 then
    return nil
  end

  -- Saturation and value come from the THEME's own average, not from the
  -- anchor. Taking them from the anchor was the first cut and it produced
  -- #00ffff / #ff1b00 on gruvbox -- neon hues that share nothing with the rest
  -- of the screen, which is the exact complaint this change exists to fix.
  -- The floors keep the guide reading as a highlight (it must sit above body
  -- text) without letting it go fluorescent.
  local as = math.max(0.45, math.min(0.92, sum_s / n))
  local av = math.max(0.72, math.min(0.98, sum_v / n * 1.15))

  -- Greedy farthest-point: each pick is the candidate furthest (in hue) from
  -- everything already chosen. Three colours a few degrees apart would make the
  -- cycle read as static, which is worse than the hardcoded trio.
  local picked = { ah }
  while #picked < count and #cands > 0 do
    local best, best_i, best_d = nil, nil, -1
    for i, h in ipairs(cands) do
      local d = math.huge
      for _, p in ipairs(picked) do
        d = math.min(d, hue_dist(h, p))
      end
      if d > best_d then
        best, best_i, best_d = h, i, d
      end
    end
    if best_d < 25 then
      break -- nothing left that is visibly a different hue
    end
    picked[#picked + 1] = best
    table.remove(cands, best_i)
  end
  if #picked < count then
    return nil
  end

  -- Walk the wheel in one direction from the anchor, so the loop has no
  -- direction change. (One long leg is unavoidable on any closed 3-colour loop;
  -- do not try to fix that by reordering.)
  local rest = {}
  for i = 2, #picked do
    rest[#rest + 1] = picked[i]
  end
  table.sort(rest, function(a, b)
    return (a - ah) % 360 < (b - ah) % 360
  end)

  local out = { hex(hsv_to_rgb(ah, as, av)) }
  for _, h in ipairs(rest) do
    out[#out + 1] = hex(hsv_to_rgb(h, as, av))
  end
  return out
end

-- Order of authority for the cycle:
--   1. a per-colorscheme override (:IndentCycle / anim.cycle_overrides)
--   2. colours derived from the live colorscheme  <- the default
--   3. anim.cycle_colors, the starship trio, as the fallback
-- An explicit :IndentColor always wins entry 1 whichever path runs, because
-- entry 1 is ALSO the guide's resting colour (rest == cycle start, so the fill
-- lands on the colour the cycle returns to and there is no jump into it).
--
-- `explicit` is vim.g.indent_scope_color or nil; `theme_base` is the raw
-- config.hl colour. theme_base is only ever used as a HUE here -- on gruvbox it
-- is #5f6c1f dark olive, and resting the guide on that raw is the historical
-- "fills in and stays dim" bug. derive_cycle lifts it.
local function resolve_cycle(explicit, theme_base)
  local function with_explicit(list)
    local out = {}
    for i, c in ipairs(list) do
      out[i] = (i == 1 and explicit) or c
    end
    return out
  end
  local over = anim.cycle_overrides and anim.cycle_overrides[vim.g.colors_name or "default"]
  if type(over) == "table" and #over > 1 then
    return with_explicit(over)
  end
  if anim.cycle_from_theme ~= false and theme_base then
    local anchor = theme_base
    if explicit then
      anchor = { unpack_rgb(tonumber(explicit:sub(2), 16)) }
    end
    local derived = derive_cycle(anchor, anim.cycle_count)
    if derived then
      -- derive_cycle lifts the anchor's saturation/value; an explicit
      -- :IndentColor is a deliberate choice and must be returned verbatim.
      return with_explicit(derived)
    end
  end
  return with_explicit(anim.cycle_colors or {})
end

local ns = vim.api.nvim_create_namespace("indent_ladder")

-- ---- indent scanning --------------------------------------------------------

local function is_blank(lnum)
  return vim.fn.getline(lnum):match("^%s*$") ~= nil
end

-- How deep the DIM ladder is drawn on this line -- i.e. snacks draws a guide at
-- column c on line l exactly when c < guide_indent(l).
--
-- This mirrors snacks/indent.lua verbatim: "Indent for a blank line is the
-- minimum of the previous and next non-blank line. If the previous and next
-- non-blank lines have different indents, add shiftwidth." Replicating it is the
-- whole point -- the lit guide must cover exactly the rows the dim guide covers,
-- no more and no less. Treating every blank line as lit (the old behaviour) ran
-- the lit bar PAST the end of the dim bar into empty space, and treating none of
-- them as lit stopped it one row short. Both were the same bug from opposite
-- sides, and both showed up only on blank lines.
local function guide_indent(lnum)
  if not is_blank(lnum) then
    return vim.fn.indent(lnum)
  end
  local prev, next = vim.fn.prevnonblank(lnum), vim.fn.nextnonblank(lnum)
  if prev == 0 or next == 0 then
    return 0 -- blank run at the very top or bottom of the file: no guides
  end
  local pi, ni = vim.fn.indent(prev), vim.fn.indent(next)
  local ind = math.min(pi, ni)
  if pi ~= ni and ind > 0 then
    local sw = vim.fn.shiftwidth()
    ind = ind + (sw == 0 and vim.bo.tabstop or sw)
  end
  return ind
end

-- Effective indent of a line, or nil when the line is blank.
local function indent_of(lnum)
  if is_blank(lnum) then
    return nil
  end
  return vim.fn.indent(lnum)
end

-- Cursor's contextual indent. On a blank line, use the deeper of its nearest
-- non-blank neighbours so an empty line inside a block still lights the guide.
local function cursor_indent(cur, last)
  local ci = indent_of(cur)
  if ci then
    return ci
  end
  local up, down
  for l = cur - 1, 1, -1 do
    up = indent_of(l)
    if up then
      break
    end
  end
  for l = cur + 1, last do
    down = indent_of(l)
    if down then
      break
    end
  end
  return math.max(up or 0, down or 0)
end

-- Indent a line CONTRIBUTES to the block structure, which is not always the
-- indent of its first character. A YAML list item --
--
--     targets:
--       - name: alpha      <- indent() says 4
--         port: 1          <- indent() says 6
--       - name: beta
--
-- puts the dash at the shallower indent but its CONTENT one level deeper. Taken
-- literally every `- ` line reads as a dedent, so the block scan below stopped at
-- the very first one: the lit guide covered a single list entry and died at the
-- next dash instead of running the length of the list.
--
-- Only the SCAN uses this. Drawing still uses the real indent, so the dash rows
-- themselves stay unpainted -- exactly where snacks' dim ladder also breaks --
-- rather than stamping a guide on top of the dash character.
local function struct_indent(lnum)
  local dash = vim.fn.getline(lnum):match("^%s*(%-%s+)")
  return vim.fn.indent(lnum) + (dash and #dash or 0)
end

-- A list item's CONTENT should light the same guide as its dash, not a deeper
-- one of its own. Given:
--
--     steps:              indent 0
--       - name: X         indent 2   -> guide col 0
--         uses: Y         indent 4   -> guide col 2   (WRONG: its own column)
--
-- the raw rule ("guide immediately left of the cursor indent") puts the cursor
-- on col 0 while it sits on a dash row and col 2 while it sits on the rows just
-- under that dash. So jk-ing down a list made the lit guide flip columns on
-- every dash -- Jimmy: "everytime i jk onto a - mark it'll pop back out
-- anyways, its useless". The dash row's answer is the useful one (it spans the
-- WHOLE list, not one entry), so content rows are pulled back to it.
--
-- Only rows whose indent is exactly the dash's content indent are pulled back;
-- anything deeper (a nested `with:` block) keeps its own guide, so real nesting
-- still reads normally.
local function delist_indent(cur, ci)
  if ci <= 0 or vim.fn.getline(cur):match("^%s*%-%s") then
    return ci -- top level, or already sitting on the dash row itself
  end
  for l = cur - 1, math.max(1, cur - 500), -1 do
    if not is_blank(l) then
      local ind = vim.fn.indent(l)
      if ind < ci then
        -- First shallower row above us. If it is the dash that owns this
        -- content, adopt its indent; otherwise we are in an ordinary block.
        if vim.fn.getline(l):match("^%s*%-%s") and struct_indent(l) == ci then
          return ind
        end
        return ci
      end
    end
  end
  return ci
end

-- Pattern matching this filetype's line comments, or nil if unknown.
local function comment_pattern()
  local lead = (vim.bo.commentstring or ""):match("^%s*(.-)%s*%%s")
  if lead and lead ~= "" then
    return "^%s*" .. vim.pesc(lead)
  end
  return nil
end

-- Vertical extent of the block whose guide sits at column x, around the cursor.
-- Blank lines continue the block; the first non-blank line at indent <= x ends
-- it. Returns from,to (1-based, inclusive).
local function block_range(cur, x, last)
  local from, to = cur, cur

  -- A line that neither belongs to the block nor ends it. Blank lines, and --
  -- crucially -- comments sitting at a SHALLOWER indent than the block: the
  -- `# ===== SECTION =====` banners YAML files are full of. Such a comment is an
  -- interruption, not a dedent. Treating it as a dedent truncated the lit guide
  -- dead at the banner while snacks' dim guide merely gapped that one row and
  -- carried on, which is exactly the "the second guide is always short" symptom.
  --
  -- These lines stay UNPAINTED regardless: draw() tests the real indent, so the
  -- lit bar gaps in precisely the same rows the dim one does.
  local cpat = comment_pattern()
  local function transparent(l)
    if is_blank(l) then
      return true
    end
    return cpat ~= nil and vim.fn.getline(l):find(cpat) ~= nil
  end

  for l = cur - 1, 1, -1 do
    if struct_indent(l) > x then
      from = l
    elseif transparent(l) then
      -- provisional: only kept if a qualifying line is found further up
    else
      break
    end
  end
  for l = cur + 1, last do
    if struct_indent(l) > x then
      to = l
    elseif transparent(l) then
      -- provisional
    else
      break
    end
  end

  -- Run the guide THROUGH blank lines at the block's edges, rather than stopping
  -- at the last line that happens to have text on it. The scan above treats a
  -- blank as provisional, so a block ending in an empty row (the blank before the
  -- next top-level key, which basically every YAML file has) stopped one row
  -- short -- a visible gap at the bottom of an otherwise continuous line, which
  -- reads as the guide failing to fill. Deeper guides with content on both sides
  -- of the blank never showed this, which is why only the outer one looked broken.
  while to < last and is_blank(to + 1) and guide_indent(to + 1) > x do
    to = to + 1
  end
  while from > 1 and is_blank(from - 1) and guide_indent(from - 1) > x do
    from = from - 1
  end
  return from, to
end

-- ---- render -----------------------------------------------------------------

-- Paint the guide at `col` over rows lo..hi, clamped to the visible window.
-- `hl_for` is an optional function(line) -> highlight group, used by the animation
-- to give each row its own leading-edge brightness; nil means the theme group.
-- Pure drawing: no scope detection, so the timer can call it every frame.
-- Live extmarks, keyed by line -> { id, hl }. Reused across frames.
--
-- The previous version cleared the whole namespace and recreated every extmark on
-- each of the ~33 frames. That churn is what made the fill look choppy and made the
-- cursor flicker: deleting and re-adding marks under the cursor forces a full
-- redraw every frame. Now a row whose group name is unchanged is LEFT ALONE, and
-- the colour ramp is animated by redefining the highlight groups instead -- Neovim
-- repaints colours without touching the extmarks at all.
local active = {}
local active_buf = nil

local function clear_marks(buf)
  if active_buf and vim.api.nvim_buf_is_valid(active_buf) then
    vim.api.nvim_buf_clear_namespace(active_buf, ns, 0, -1)
  end
  if buf and buf ~= active_buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  end
  active = {}
  active_buf = buf
end

-- `cache` (optional) memoises the "does this row carry a guide at all" test for
-- the life of one animation. Without it every frame re-runs two vim.fn calls per
-- visible row; at 120fps over a 30-row block that is ~7000 vimscript round-trips
-- a second, which is real budget spent re-deriving an answer that cannot change
-- mid-animation (a text edit starts a new one).
local function draw(buf, col, lo, hi, hl_for, cache)
  if buf ~= active_buf then
    clear_marks(buf)
  end
  lo = math.max(lo, vim.fn.line("w0"))
  hi = math.min(hi, vim.fn.line("w$"))

  local want = {}
  for l = lo, hi do
    -- Only draw where the column falls inside the line's indentation
    -- whitespace (or on a blank continuation line) -- never over real text.
    local ok = cache and cache[l]
    if ok == nil then
      ok = guide_indent(l) > col
      if cache then
        cache[l] = ok
      end
    end
    if ok then
      local hl = hl_for and hl_for(l) or resting_hl or config.hl
      if hl then
        want[l] = hl
      end
    end
  end

  -- Retire rows that should no longer carry a guide.
  for l, m in pairs(active) do
    if not want[l] then
      pcall(vim.api.nvim_buf_del_extmark, buf, ns, m.id)
      active[l] = nil
    end
  end

  -- Add new rows, and update only those whose GROUP actually changed.
  for l, hl in pairs(want) do
    local m = active[l]
    if not (m and m.hl == hl) then
      local ok, id = pcall(vim.api.nvim_buf_set_extmark, buf, ns, l - 1, 0, {
        id = m and m.id or nil, -- reuse the id so this is an update, not a churn
        virt_text = { { config.char, hl } },
        virt_text_win_col = col,
        virt_text_pos = "overlay",
        -- "replace", not "combine": combine composites our colour with the dim
        -- SnacksIndent guide already painted at that cell, which muted the flash
        -- -- the pulse never got near white because it was being averaged with a
        -- near-background colour every frame.
        hl_mode = "replace",
        priority = config.priority,
        ephemeral = false,
      })
      if ok then
        active[l] = { id = id, hl = hl }
      end
    end
  end
end

local timer = nil
-- The scope each buffer was last painted with, buf -> key.
--
-- PER BUFFER, not one global (2026-08-05, the C-h/C-l swap lag). A single
-- global key was overwritten the moment the OTHER window's repaint() ran, so
-- swapping back never matched and re-ran the full ~5s animation (450ms fill at
-- anim.fps, then breathe_delay, then breathe_cycles) on EVERY press. Bouncing
-- h/l tore that down and restarted it each time -- the lag and the half-drawn
-- guide. Keyed per buffer, a swap-back lands in repaint()'s "same scope"
-- branch and costs one static draw. Same verdict as the FocusGained note
-- below: "0 need for it to reanimate".
local painted = {}
local function key_of(buf)
  return painted[buf]
end
local function set_key(buf, key)
  painted[buf] = key
end
-- Focus gate. When the terminal pane / GUI window loses focus, nothing here is
-- being looked at, so the breathe is pure churn: it keeps redefining highlight
-- groups every frame, which forces a full redraw of an unfocused pane and reads
-- as flashing (and burns CPU). While unfocused the guide is drawn ONCE, static,
-- at full extent; the timer stays dead until focus comes back. MUST be declared
-- above `animate` -- the timer callback closes over it as an upvalue, and a
-- later declaration would silently read a nil global instead.
local focused = true
-- Mirrored to a g: var purely so the state is observable from OUTSIDE the
-- process (nvim --remote-expr) -- `focused` is an upvalue and unreachable
-- otherwise. Stamped here at load as well as in the handlers, so the variable
-- existing at all is also a reliable "this file has been reloaded" signal.
vim.g.indent_ladder_focused = true
-- Set when something outside the timer (a scroll, a resize) means the current
-- frame must be redrawn even though the colour has not changed. Without it the
-- breathe's skip-unchanged-frames optimisation would leave newly scrolled-in rows
-- unpainted until the colour happened to tick over.
local anim_dirty = false
-- True from the first WinScrolled until the scroll has been quiet for
-- scroll_quiet_ms. Declared up here for the same reason as `focused` above:
-- repaint() closes over it, and a later declaration would read a nil global.
local scrolling = false

-- What the live timer is animating, so stopping it can leave a finished guide
-- instead of an abandoned half-fill. Set by animate(), consumed by stop_timer().
local anim_ctx = nil

local function stop_timer()
  if timer then
    pcall(function()
      timer:stop()
      timer:close()
    end)
    timer = nil
  end
  -- FINALIZE AN ABANDONED ANIMATION (2026-08-01, the "stopped midway" bug).
  --
  -- A live animation dies two ways while its buffer is NOT current: its own
  -- tick notices the buffer changed and bails, or another window's repaint()
  -- starts a new animation whose stop_timer() kills it externally (a split
  -- switch fires both, in a race). Either way the fill's half-painted rows
  -- stayed exactly as they were, last_key stayed set so nothing re-animated,
  -- and since repaint() only serves the current buffer, a guide in the OTHER
  -- split froze that way indefinitely.
  --
  -- So: whenever a timer is stopped while its buffer is not the current one,
  -- leave the same thing the unfocused branch leaves -- the complete static
  -- resting guide. draw() reads the current window's w0/w$ and the current
  -- buffer's indents, so it must run inside a window showing that buffer
  -- (nvim_win_call). No window any more -> wipe the half-fill and drop
  -- last_key so re-entering the scope animates fresh. Same-buffer stops
  -- (scope settle, clear(), the unfocused repaint) skip this entirely: their
  -- callers already draw or wipe, and finalizing would double up.
  local ctx = anim_ctx
  anim_ctx = nil
  --
  -- 2026-08-02: the finalize used to draw the COMPLETE static guide into the
  -- other window when that buffer was still visible. Measured live (tmux
  -- capture-pane, devops:2.1): three guide colours on screen at once and static
  -- across every frame -- the lit cyan #2ff5ff in the active window, and a dull
  -- #7e816c bar in the other split, which is that finalized guide after
  -- tint.nvim's inactive-window dim. That is the dim bar Jimmy keeps seeing, and
  -- it sits there permanently because nothing ever repaints an inactive window.
  -- ONE guide on screen, in the window being looked at ([[no-guide-lines]]).
  -- Wiping still fixes the original "stopped midway" bug -- a cleared guide is
  -- not a frozen half-fill -- and dropping last_key means re-entering the scope
  -- animates fresh from nothing.
  --
  -- 2026-08-05: the key is now KEPT (it used to be dropped here, which is what
  -- made every C-h/C-l swap-back re-run the whole animation -- see `painted`).
  -- Wiping the marks still fixes the original "stopped midway" bug: coming back
  -- to a kept key hits repaint()'s same-scope branch, which draws the COMPLETE
  -- static guide. A wiped guide plus a static redraw is never a frozen half-fill.
  if ctx and vim.api.nvim_buf_is_valid(ctx.buf) and vim.api.nvim_get_current_buf() ~= ctx.buf then
    clear_marks(ctx.buf)
  end
end

-- Grow the guide from `origin` out to from..to over anim.duration.
local function animate(buf, col, from, to, origin)
  stop_timer()
  if not uv then
    draw(buf, col, from, to)
    return
  end
  timer = uv.new_timer()
  if not timer then
    draw(buf, col, from, to)
    return
  end
  anim_ctx = { buf = buf, col = col, from = from, to = to }
  local start = uv.now()
  local interval = math.max(1, math.floor(1000 / anim.fps))
  local breathe_interval = math.max(1, math.floor(1000 / (anim.breathe_fps or anim.fps)))
  local slowed = false

  -- Transparency changes what "faded to nothing" MEANS.
  --
  -- The breathe fades the guide down to `dim`, and that only ever read as
  -- "gone" because dim IS the window background -- this theme paints
  -- SnacksIndent at exactly Normal.bg (measured 2026-07-31: both #13130f, which
  -- is also why Jimmy says "the dimmed version is non existent" -- correct, it
  -- is deliberately invisible). Under :BgTransparency 100 there is no Normal.bg
  -- at all, the derived dim lands on #181616, and the bottom of every swing
  -- paints an OPAQUE grey stripe over the wallpaper instead of disappearing.
  -- A foreground colour cannot be transparent, so the only honest "nothing" is
  -- to remove the marks and put them back on the way up.
  local ok_n, n_hl = pcall(vim.api.nvim_get_hl, 0, { name = "Normal", link = false })
  local transparent = not (ok_n and n_hl and n_hl.bg)
  -- Colours sampled once per animation. `base` is the guide's resting colour and
  -- `dim` is the colour rows fade UP from -- the dim ladder snacks already draws
  -- underneath, so a row emerges out of the existing guide rather than out of
  -- nowhere. Missing either one just disables the fade and we draw plain.
  -- THE RESTING COLOUR IS NOT THE THEME'S (2026-08-05). This is the actual
  -- "fills in and STAYS DIM" bug, and it was never the fade or transparency.
  --
  -- `base` used to be SnacksIndentScope, whatever the colorscheme happened to
  -- put there. Measured in an isolated repro on his live config: he is on
  -- base16-gruvbox-dark-medium-forest, whose SnacksIndentScope is #5f6c1f -- a
  -- DARK OLIVE. So the fill climbed to dark olive, the cycle looked right for
  -- 7.8s, and then the settle painted that olive and left it there forever.
  -- Every "dim bar" complaint on a dark theme is this.
  --
  -- Order of authority: an explicit :IndentColor wins (it is the documented
  -- owner, persisted in vim.g.indent_scope_color), then the first cycle colour
  -- (his own, and the one the cycle returns to, so rest == cycle start), and the
  -- theme group only as a last resort when neither is configured.
  --
  -- 2026-08-06: the cycle (and therefore the resting colour) is now resolved
  -- per COLORSCHEME -- see resolve_cycle. The order of authority is unchanged;
  -- what changed is that the middle rung derives from the live theme instead of
  -- always being the hardcoded starship trio.
  local base = group_fg(config.hl)
  local explicit = vim.g.indent_scope_color
  if type(explicit) ~= "string" or not explicit:match("^#%x%x%x%x%x%x$") then
    explicit = nil
  end
  local cycle = resolve_cycle(explicit, base)
  local chosen = cycle[1]
  if type(chosen) == "string" and chosen:match("^#%x%x%x%x%x%x$") then
    base = { unpack_rgb(tonumber(chosen:sub(2), 16)) }
  end
  -- Under transparency this is overwritten with TERMINAL_BG a few lines down, so
  -- don't pay for the two highlight lookups -- which on his config (bg_transparency
  -- pinned to 100) is EVERY animation, in both gday and gnight.
  local dim = not transparent and (group_fg("SnacksIndent") or group_fg("NonText")) or nil

  -- WHAT "FADED TO NOTHING" MEANS UNDER TRANSPARENCY (fixed 2026-08-01).
  --
  -- The breathe fades base -> dim, and that only ever read as "gone" because dim
  -- IS the window background: this theme paints SnacksIndent at exactly
  -- Normal.bg. Under :BgTransparency 100 there is no Normal.bg, the derived dim
  -- lands on #181616, and #181616 over a see-through window is an OPAQUE GREY
  -- LINE -- so the guide never vanished, it just went grey.
  --
  -- The first attempt at this cleared the extmarks below a 0.10 threshold. That
  -- removed the grey line but replaced it with a hard on/off: measured, the
  -- guide was CLEARED for 533ms of every 2600ms cycle, which is exactly what
  -- Jimmy saw -- "flash statically ... a slideshow". A pop is not a fade.
  --
  -- What actually works: fade toward what is REALLY behind the text. Ghostty
  -- paints `background` at `background-opacity`, and at 0.94 that backdrop is
  -- ~94% TERMINAL_BG and only ~6% wallpaper -- so fading to TERMINAL_BG reads as
  -- invisible while staying a continuous 52-step colour ramp. No threshold, no
  -- clear, no pop.
  --
  -- ⚠️ TERMINAL_BG must match `background` in the Ghostty config. If that value
  -- changes, change this. At much lower opacity the wallpaper dominates and the
  -- trough will start to show again -- that is inherent: a foreground colour
  -- cannot be transparent, so there is no exact answer, only this good one.
  if transparent then
    dim = { unpack_rgb(tonumber(TERMINAL_BG:sub(2), 16)) }
  end
  if base and dim then
    build_ramp(dim, base)
    -- Pin the resting group to the SAME colour the fill climbs to, so the
    -- handover from animation to rest is invisible instead of a drop to the
    -- theme's dim scope colour.
    pcall(vim.api.nvim_set_hl, 0, REST, { fg = hex(base) })
    resting_hl = REST
  end
  -- Day mode (transparent) cycles hue; night mode (opaque) keeps the tonal
  -- fade-to-nothing. Nothing else in the animation differs between them.
  local cycling = transparent and anim.breathe and #cycle > 1
  if cycling then
    build_cycle(cycle)
  end
  local elig = {} -- per-animation row-eligibility memo (see draw)
  local trail = math.max(1, anim.trail)
  local last_glow = nil -- dedupe: skip the frame entirely if the colour is unchanged
  -- True while the marks are pulled for the bottom of the swing (see CLEAR_EPSILON).
  local blanked = false
  timer:start(
    0,
    interval,
    vim.schedule_wrap(function()
      -- Bail if the buffer went away or the user moved to a different one --
      -- otherwise the timer keeps drawing into a buffer that is no longer shown.
      if not focused then
        -- Focus went away mid-animation. This USED to just stop and rely on the
        -- FocusLost handler's repaint -- but if focus was lost while the swing
        -- was at the bottom, the marks are CLEARED (see the transparency block
        -- below) and stopping here leaves them cleared: the guide is simply GONE
        -- until the cursor enters a different scope. Switching apps during the
        -- dark half of a breathe is the most ordinary thing in the world, which
        -- is why this looked like "it does not even light up" with every other
        -- piece of state (marks, ramp, colours) measuring perfectly healthy.
        -- Restore the static guide here rather than trusting the handler to have
        -- got there first.
        stop_timer()
        if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_get_current_buf() == buf then
          draw(buf, col, from, to)
        end
        return
      end
      if not vim.api.nvim_buf_is_valid(buf) or vim.api.nvim_get_current_buf() ~= buf then
        -- stop_timer() finalizes the abandoned guide (see anim_ctx there) --
        -- this bail must not draw anything itself or the two would double up.
        stop_timer()
        return
      end
      if not (base and dim) then
        -- No colours to work with: plain guide, nothing to animate.
        draw(buf, col, from, to)
        stop_timer()
        return
      end

      local e = uv.now() - start
      local t = math.min(1, e / anim.duration)
      -- Smoothstep, not ease-out cubic. Ease-out spent most of the duration barely
      -- moving, so the tail of the fill crawled a line at a time and read as chop.
      -- Smoothstep eases in AND out, keeping the middle -- where most of the travel
      -- happens -- at a steady rate.
      local p = t * t * (3 - 2 * t)

      -- Breathe: starts only once the fill is COMPLETE (t=1), then runs forever
      -- while the cursor stays in this scope.
      --
      -- (1+cos)/2 starts at exactly 1 -- i.e. at the resting colour the fill just
      -- landed on -- so the breathe eases out of the fill with no jump, dips to
      -- breathe_min, and comes back. Cosine (not a sawtooth) is what makes both
      -- turning points ease rather than snap.
      -- Fill is done: slow the timer down for the endless breathe tail. set_repeat
      -- alone only takes effect after the NEXT expiry, so `again` is needed to
      -- restart the timer at the new interval right now. Guarded so it happens
      -- once, not on every breathe frame.
      if t >= 1 and not slowed then
        slowed = true
        pcall(function()
          timer:set_repeat(breathe_interval)
          timer:again()
        end)
      end

      local level = 1
      -- The hold: fill is geometrically complete, but leave it parked at full
      -- brightness for breathe_delay ms before the first dip (see the knob).
      local breathe_start = anim.duration + (anim.breathe_delay or 0)
      if e >= breathe_start and anim.breathe then
        local phase = (e - breathe_start) / anim.breathe_period
        if anim.breathe_cycles and phase >= anim.breathe_cycles then
          -- Breathe budget spent: settle on the resting colour, drop the marks
          -- back onto the plain theme group, and stop. Nothing runs after this
          -- until the cursor moves into a different scope.
          pcall(vim.api.nvim_set_hl, 0, GLOW, { fg = hex(base) })
          draw(buf, col, from, to)
          stop_timer()
          return
        end
        local osc = (1 + math.cos(phase * 2 * math.pi)) / 2
        level = anim.breathe_min + (anim.breathe_max - anim.breathe_min) * osc
      end

      -- PULSE UP, NEVER DOWN (2026-08-05, second attempt). The fix for "gday
      -- makes it buggy".
      --
      -- theme.lua sets bg_transparency = 100 permanently, so Normal.bg is nil in
      -- BOTH day and night -- this branch has always been the live one. Night
      -- only LOOKS smooth because ghostty-mode.sh turns the phosphor shaders on
      -- and they paint over the damage; day drops them and exposes it.
      --
      -- Under transparency no foreground colour means "invisible", so a tonal
      -- fade cannot end at nothing. Both previous attempts failed in opposite
      -- directions: fading to TERMINAL_BG left an OPAQUE #111113 bar over the
      -- wallpaper ("dim guidelines that aren't supposed to be there"), and
      -- clearing at a threshold dropped every row in one frame ("a slideshow").
      --
      -- A SPATIAL fade was tried first and rejected on sight -- "ITS A SLIDESHOW
      -- BRUH". It erased rows from the ends inward, which is chunky BY
      -- CONSTRUCTION: its resolution is the scope's ROW COUNT, so a 40-row scope
      -- gets ~20 steps and an 8-row scope gets four. The colour ramp has 48 steps
      -- at any height. Never animate on a spatial axis that short.
      --
      -- A PULSE UP toward white, never dimming -- also rejected. It dodged the
      -- dim bar by never approaching the backdrop, but the brightness swing read
      -- as a hue change he did not want in that form.
      --
      -- LIVE SHAPE: cycle the HUE through his three colours at constant
      -- brightness. Same immunity as the pulse (the guide never goes near the
      -- backdrop, so nothing can fail to disappear) but it is a deliberate
      -- colour walk rather than a washed-out brightness swing. His words:
      -- "keep the hue change, make it go through the 3 gruvbox colors I've set
      -- ... the fading in and out wont work during daytime."
      --
      -- Opaque mode is untouched: there the theme paints SnacksIndent at exactly
      -- Normal.bg, so level 0 really is invisible and the tonal fade is right.
      -- Night keeps the fade-to-nothing; only day cycles.
      local cycle_step = nil
      if cycling and e >= breathe_start then
        local pos = ((e - breathe_start) / anim.cycle_period) % 1
        cycle_step = math.floor(pos * CYCLE_STEPS) % CYCLE_STEPS
        level = 1 -- brightness is constant here; hue carries the animation
      end

      -- BOTTOM OF THE SWING = ACTUALLY NOTHING (2026-08-01).
      --
      -- With no window bg there is no foreground colour that means "invisible":
      -- fading to TERMINAL_BG still paints an OPAQUE #111113 line over the
      -- wallpaper, so the guide never vanished, it just went dark grey. Measured
      -- live: Normal.bg = nil, so this branch is the one that runs.
      --
      -- The first attempt at this cleared the marks at level <= 0.10, and that
      -- POPPED -- at 0.10 the colour is still ~#12232f, clearly brighter than the
      -- backdrop, so the mark vanished while it was plainly still visible.
      -- The threshold was the bug, not the clearing: the clear has to happen only
      -- once the ramp has ALREADY arrived at the backdrop, so pulling the mark is
      -- imperceptible and what you see is a continuous fade that ends in real
      -- nothingness -- it is the FADE that gets you there, not a cut.
      --
      -- 2026-08-02: this is now measured against the COLOUR, not against `level`.
      -- A level threshold silently depends on the level->colour mapping, so the
      -- move to a linear-light blend (see blend()) turned 0.03 back into a visible
      -- pop -- at that level the guide was still ~#233324. Comparing the rendered
      -- colour to the backdrop is mapping-independent: whatever the curve, the
      -- clear lands exactly when the fade has nothing left to show.
      --
      -- Only under transparency. Opaque windows already work: the theme paints
      -- SnacksIndent at exactly Normal.bg, so level 0 is genuinely invisible.
      --
      -- 2026-08-06: `and not cycling`. While the hue cycle runs, `level` is
      -- pinned to 1 (brightness is constant -- that IS the shape), so `faded`
      -- is always exactly `base` and `at_backdrop` can never be true. This whole
      -- block was three linear-light blends per frame, forever, to reach a
      -- branch that cannot be taken. It stays reachable for the transparent
      -- NON-cycling case (cycle of one colour, or breathe off), which is the
      -- configuration it was written for.
      if transparent and not cycling then
        local faded = level <= 1 and blend(dim, base, level) or nil
        local at_backdrop = faded ~= nil
          and math.abs(faded[1] - dim[1]) <= CLEAR_EPSILON
          and math.abs(faded[2] - dim[2]) <= CLEAR_EPSILON
          and math.abs(faded[3] - dim[3]) <= CLEAR_EPSILON
        if at_backdrop then
          if not blanked then
            blanked = true
            clear_marks(buf)
            last_glow = nil -- the dedupe must not skip the repaint on the way up
          end
          return
        elseif blanked then
          -- Coming back up: marks were wiped, so `active` and the row memo are
          -- both stale and every row has to be re-laid.
          blanked = false
          elig = {}
          last_glow = nil
        end
      end

      -- The ONE per-frame highlight write. If the rounded colour has not changed
      -- since last frame there is nothing to repaint, so skip the whole frame --
      -- no set_hl, no extmark touch, no redraw. During the slow breathe that idles
      -- most frames out and leaves exactly one redraw per visually distinct colour.
      -- Brightness axis: 0..1 walks dim -> resting colour, and anything above 1
      -- carries on past it toward white, so breathe_max can overshoot the theme
      -- colour without the resting colour itself stopping coming from the theme.
      local glow = hex(level <= 1 and blend(dim, base, level) or blend(base, WHITE, level - 1))

      -- The dedupe must key on the cycle step too. During the hue cycle the
      -- BRIGHTNESS is constant, so `glow` never changes and a glow-only
      -- comparison would skip every frame -- the guide would sit on one colour
      -- forever, which is the same class of bug as the recoloured-group breathe
      -- that never reached the screen.
      local frame_key = cycle_step and (glow .. "@" .. cycle_step) or glow
      if frame_key == last_glow and t >= 1 and not anim_dirty then
        return
      end
      last_glow = frame_key
      if anim_dirty then
        -- A scroll or an edit got us here; the row-eligibility memo may be stale.
        elig = {}
        anim_dirty = false
      end
      -- Skipped while cycling: `glow` is blend(dim, base, 1) == base every frame
      -- there, and lit_group is a CYCLE_* group, so this was rewriting GLOW to
      -- the identical colour ~192 times per cycle for a group nothing was using.
      -- GLOW is still the fill's group (cycle_step is nil until the fill ends)
      -- and still the settle colour at line ~1155, so it must keep being written
      -- on every non-cycling frame.
      if not cycle_step then
        pcall(vim.api.nvim_set_hl, 0, GLOW, { fg = glow })
      end

      -- THE BREATHE'S FRAMES WERE NEVER REACHING THE SCREEN (2026-08-02). This
      -- is the bug behind "it lights up once and then it is just static".
      --
      -- The design above assumed a set_hl "is therefore a FULL SCREEN REDRAW".
      -- It is not -- not on 0.12, and not for a group that appears ONLY inside
      -- extmark virt_text. Redefining such a group dirties no line, so no redraw
      -- is scheduled and the terminal keeps showing the last frame that happened
      -- to get flushed. The FILL never exposed it: the fill hands every row a
      -- different FADE_* group each frame, and changing an extmark's group DOES
      -- dirty its line. The BREATHE gives every row the same GLOW group forever
      -- and only recolours the group -- which was the entire performance win --
      -- so from t=1 onward it wrote colour after colour that nothing ever
      -- painted.
      --
      -- Measured against a REAL attached tmux client: the fill delivered 6
      -- frames, then the guide sat frozen on one mid-fill colour for the whole
      -- ~8s breathe and only snapped to the resting colour when an unrelated
      -- redraw (a keypress, <C-l>) came along. The extmarks and GLOW both read
      -- perfectly healthy the entire time -- the marks said bright while the
      -- screen said dim. That is why this survived so long: every measurement of
      -- the STATE agreed with the design, and only the pixels disagreed.
      --
      -- nvim__redraw({valid=false}) was tried first and did NOT deliver the
      -- frames either. What works is to stop relying on a recoloured group at
      -- all: walk the rows along the PRECOMPUTED ramp instead, so each frame is
      -- a real group change on the extmark, which dirties the line the same way
      -- the fill's frames do. The ramp already exists (FADE_STEPS+1 groups, dim
      -- -> resting colour) and is rebuilt only when the theme changes, so this
      -- costs one extmark update per visibly distinct step -- not per frame,
      -- because the dedupe above still drops the rest.
      --
      -- GLOW stays the group for the fill's fully-lit rows and for any overshoot
      -- past the resting colour (level > 1), which the ramp cannot express.
      local lit_group = GLOW
      if cycle_step then
        -- Hue cycle (day mode): a real group per step, for the same reason the
        -- fade ramp is one. Checked FIRST -- it owns the colour outright here,
        -- and the brightness ramps below would only fight it.
        lit_group = CYCLE_PREFIX .. cycle_step
      elseif t >= 1 and level <= 1 then
        local step = math.floor(level * FADE_STEPS + 0.5)
        lit_group = FADE_PREFIX .. math.max(0, math.min(FADE_STEPS, step))
      elseif t >= 1 then
        -- Overshoot past the resting colour (the transparent-mode pulse). This
        -- used to fall through to GLOW, a recoloured group -- which is exactly
        -- the "computed but never painted" bug described above, and it would
        -- have made the pulse invisible. Walk the lift ramp instead.
        local step = math.floor((level - 1) * FADE_STEPS + 0.5)
        lit_group = LIFT_PREFIX .. math.max(0, math.min(FADE_STEPS, step))
      end

      -- Continuous edge positions. Geometry lands on whole lines, but each row's
      -- brightness is driven by how far the edge has travelled PAST it, which varies
      -- smoothly -- that is what removes the chop.
      --
      -- The edges travel `trail` rows BEYOND the block's ends. Without that overshoot
      -- the trail is still mid-gradient when it reaches the last row, so the ends of
      -- the block never brighten to full -- they'd settle at 1/trail.
      local edge_up = origin - (origin - (from - trail)) * p
      local edge_down = origin + ((to + trail) - origin) * p

      -- Clamp to the block. The gradient trails BEHIND the edge, so widening the
      -- drawn range to make room for it is exactly wrong: it lights rows outside the
      -- block entirely, running the guide past the end of the nested chunk.
      local lo = math.max(from, math.floor(edge_up))
      local hi = math.min(to, math.ceil(edge_down))

      draw(buf, col, lo, hi, function(l)
        -- How far the edge has swept past this row, in rows, spread over `trail`
        -- rows instead of one. A single-row edge meant every row behind it snapped
        -- straight to full: a staircase with one soft corner. A multi-row gradient
        -- is what actually reads as a soft fill.
        local d = (l >= origin) and (edge_down - l) or (l - edge_up)
        local a = math.max(0, math.min(1, (d + 1) / trail))
        if a <= 0 then
          return nil -- edge has not reached this row yet: draw nothing
        end
        if a >= 1 then
          -- Fully lit rows share ONE group. During the fill that is GLOW (one
          -- set_hl per frame, and the per-row group changes already force the
          -- redraw). During the breathe it is the ramp step for this frame --
          -- see lit_group above: sharing a recoloured group there meant the
          -- frames were computed and never drawn.
          return lit_group
        end
        return FADE_PREFIX .. math.floor(a * FADE_STEPS + 0.5)
      end, elig)
    end)
  )
end

local function repaint()
  local buf = vim.api.nvim_get_current_buf()

  local function clear()
    stop_timer()
    set_key(buf, nil)
    clear_marks(buf) -- keeps `active` in sync with the wiped namespace
  end

  if vim.bo.buftype ~= "" then
    return clear()
  end

  -- Mid-scroll: do NOT recompute the scope.
  --
  -- u/d glide the view a row at a time and drag the cursor with it, so repaint()
  -- runs ~20 times during one press, each time landing on a different intermediate
  -- line. Recomputing there meant every scope the cursor swept THROUGH got painted
  -- flat for a frame -- that is the "it blinks the level I came from, then animates
  -- the right one" flash. The landing scope is not knowable at scroll start (snacks
  -- owns the cursor for the whole glide), so the fix is to stop guessing: hold the
  -- scope that was lit when the scroll began and keep drawing exactly that.
  --
  -- Extmarks are line-anchored, so the guide already on screen slides with its own
  -- text without anyone touching it -- that block really is moving up the screen.
  -- So the whole scroll path is: do NOTHING. No scope scan, no draw.
  --
  -- Redrawing here (to paint rows scrolling INTO view) is what made the glide
  -- choppy: snacks fires WinScrolled once per animated row, ~20 per press at 15ms
  -- apart, and each draw() re-ran guide_indent() over every visible row -- dozens
  -- of vimscript round-trips wedged between the animation's own frames. The
  -- animation path memoises that test for exactly this reason; this path competing
  -- with the scroll for the main loop is not worth a few rows of guide arriving
  -- 120ms early. They get painted when scroll_settled() drops last_key and the
  -- landing scope animates, once.
  -- Do NOT stop the timer here: killing the fill on every WinScrolled (and k/j
  -- near the window edge scrolls one row PER PRESS) chopped the animation into a
  -- stop/restart slideshow. The extmarks are line-anchored and slide with the
  -- text; the fill just keeps running, and the dirty flag repaints rows that
  -- scrolled into view.
  if scrolling then
    if timer then
      anim_dirty = true
    end
    return
  end

  local sw = vim.fn.shiftwidth()
  if sw == 0 then
    sw = vim.bo.tabstop
  end
  if sw == 0 then
    return clear()
  end

  local last = vim.fn.line("$")
  local cur = vim.fn.line(".")
  local ci = delist_indent(cur, cursor_indent(cur, last))
  if ci <= 0 then
    return clear() -- top level: no enclosing guide to light
  end

  -- The enclosing guide is the guide column immediately to the left of the
  -- cursor's own indent: the largest guide column strictly less than ci.
  local col = math.floor((ci - 1) / sw) * sw

  -- RAW extent (not window-clamped) -- this is what identifies the scope. Using
  -- the clamped range here would change the key on every scroll and restart the
  -- animation constantly.
  local from, to = block_range(cur, col, last)

  local key = table.concat({ buf, col, from, to }, ":")
  if not focused then
    -- Unfocused: kill any live animation and paint the resting guide once.
    --
    -- 2026-07-31: this used to also clear `last_key`, deliberately, so that
    -- regaining focus replayed the grow animation from scratch. In practice
    -- FocusLost/FocusGained fire on every tmux WINDOW SWAP, so simply cycling
    -- away and back re-animated a scope Jimmy never left -- his verdict: "0
    -- need for it to reanimate". Keeping the key means refocus lands in the
    -- "same scope, nothing to do" branch below and the guide is just repainted
    -- at full extent. A genuinely new scope still animates, because the key
    -- changes on its own.
    stop_timer()
    draw(buf, col, from, to)
    return
  end
  if key == key_of(buf) or not anim.enabled then
    -- Same scope (or animation off): just repaint at full extent, no regrow.
    -- EXCEPT while a timer is live: CursorMoved fires on the same tick that a
    -- scope is entered, so this branch would immediately redraw the guide at full
    -- extent in the plain resting colour and stomp frame 1 of the animation. The
    -- two then fought for the rest of the run. The timer owns the pixels while it
    -- lives; just flag it to redraw in case this was a scroll.
    --
    -- The timer only owns the pixels of the buffer it is animating. With keys
    -- kept per buffer a swap-back can land here while the OTHER window's
    -- animation is still live -- deferring to it would leave this buffer's
    -- guide wiped (stop_timer clears the marks) until that run finished.
    if anim.enabled and timer and anim_ctx and anim_ctx.buf == buf then
      anim_dirty = true
    else
      draw(buf, col, from, to)
    end
    return
  end
  set_key(buf, key)

  -- New scope: grow out from the cursor row, clamped into the block.
  animate(buf, col, from, to, math.min(math.max(cur, from), to))
end

-- Debounce: CursorMoved fires in bursts; coalesce to one repaint per tick.
local scheduled = false
-- A repaint that throws is swallowed (it must be -- this runs on every
-- CursorMoved and an error loop through noice melts the session, see the
-- statuscolumn rule). But swallowing it SILENTLY is how the guide freezes with
-- no trace: clear() never runs, the last-painted marks sit there forever, and
-- :messages shows nothing. Report the first failure once, then stay quiet.
local repaint_error_reported = false
local function schedule()
  if scheduled then
    return
  end
  scheduled = true
  vim.schedule(function()
    scheduled = false
    local ok, err = pcall(repaint)
    if not ok then
      vim.g.indent_ladder_last_error = tostring(err)
      if not repaint_error_reported then
        repaint_error_reported = true
        vim.notify("indent-ladder: repaint failed (guide may freeze): " .. tostring(err), vim.log.levels.WARN)
      end
    end
  end)
end

-- snacks' scroll animation runs ~450ms and fires WinScrolled once per animated
-- row, so the quiet window has to outlast a single glide before we call the
-- scroll finished and let the guide animate again.
local scroll_quiet_ms = 120
local scroll_timer = nil

local function note_scroll()
  scrolling = true
  if not scroll_timer then
    scroll_timer = vim.uv.new_timer()
  end
  scroll_timer:stop()
  scroll_timer:start(
    scroll_quiet_ms,
    0,
    vim.schedule_wrap(function()
      scrolling = false
      -- last_key is deliberately KEPT: dropping it here re-grew the guide from
      -- scratch after every 120ms scroll lull, so holding k re-triggered the
      -- whole animation over and over (the slideshow). If the scroll landed in a
      -- DIFFERENT scope the key comparison in repaint() catches it and animates;
      -- same scope just gets a full-extent repaint, which is all it needs.
      schedule()
    end)
  )
end

-- scroll_timer is created lazily and reused for the life of the process, so it
-- is one handle rather than a leak -- but it is still an OPEN handle at exit,
-- and a handle that outlives the loop is exactly what makes uv_loop_close spin.
-- Give it, and the animation timer, an explicit teardown.
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("IndentLadderTeardown", { clear = true }),
  callback = function()
    stop_timer()
    if scroll_timer and not scroll_timer:is_closing() then
      scroll_timer:stop()
      scroll_timer:close()
    end
    scroll_timer = nil
  end,
})

local group = vim.api.nvim_create_augroup("IndentLadder", { clear = true })
vim.api.nvim_create_autocmd(
  { "CursorMoved", "CursorMovedI", "BufWinEnter", "TextChanged", "TextChangedI", "ColorScheme" },
  { group = group, callback = schedule }
)
vim.api.nvim_create_autocmd("WinScrolled", {
  group = group,
  callback = function()
    note_scroll()
    schedule()
  end,
})

-- FocusLost/FocusGained fire for the terminal pane (tmux, and any terminal with
-- focus reporting) as well as GUI windows. Losing focus stops the loop
-- immediately instead of waiting for the next repaint tick.
vim.api.nvim_create_autocmd("FocusLost", {
  group = group,
  callback = function()
    focused = false
    vim.g.indent_ladder_focused = false
    -- Only repaint if we just KILLED a live animation -- that is the one case
    -- where the marks on screen are a half-fill that needs finishing. With no
    -- timer running the guide is already sitting at its resting state and
    -- redrawing it is a full guide_indent() scan of every visible row for
    -- literally no pixel change. See the FocusGained note below.
    local had_timer = timer ~= nil
    stop_timer()
    if had_timer then
      schedule()
    end
  end,
})

vim.api.nvim_create_autocmd("FocusGained", {
  group = group,
  callback = function()
    focused = true
    vim.g.indent_ladder_focused = true
    -- THE SWAP LAG (2026-08-02). FocusLost AND FocusGained both fire on every
    -- tmux WINDOW swap, and both used to schedule() unconditionally -- so each
    -- swap cost two full repaints, and repaint()'s same-scope branch calls
    -- draw(), which re-runs guide_indent() over every visible row (see the
    -- scroll note: "dozens of vimscript round-trips"). Nothing about the guide
    -- changed while we were away: extmarks are line-anchored, the text did not
    -- move, and the scope is the same one we left. Worse, the swap's own redraw
    -- can fire WinScrolled, which parks repaint() behind scroll_quiet_ms -- so
    -- the wasted work landed as a visible dead beat right at the start.
    --
    -- With a guide already painted (last_key set) there is nothing to do but
    -- flip the flag. A guide that is genuinely absent still gets drawn, and any
    -- real cursor move repaints through the normal path.
    if not key_of(vim.api.nvim_get_current_buf()) then
      schedule()
    end
  end,
})

-- SELF-HEAL (2026-08-02). `focused` gates the ENTIRE animation: a false value
-- makes animate()'s first tick stop the timer and repaint() paint the static
-- guide, so the guide simply never moves again. That is a latch -- one missed
-- FocusGained and the animation is dead for the rest of the session, silently,
-- with everything else (marks, colours, the ramp) still looking perfectly
-- healthy. FocusLost/FocusGained arrive over terminal focus reporting through
-- tmux, across app switches, tmux window swaps and floats; anything that eats
-- one of them leaves the latch stuck.
--
-- Keystrokes are proof of focus: input cannot reach a terminal that does not
-- have it. So any cursor movement clears the latch. Costs a boolean compare on
-- CursorMoved and only ever schedules when it actually just repaired itself.
vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "ModeChanged" }, {
  group = group,
  callback = function()
    if not focused then
      focused = true
      vim.g.indent_ladder_focused = true
      schedule()
    end
  end,
})

-- `:colorscheme` runs `hi clear`, wiping the precomputed ramp groups, and the
-- resting colour it fades up to has probably changed anyway. Drop the cache key
-- so the next animation rebuilds from the new theme.
vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = invalidate_ramp })

-- `painted` is keyed by buffer number and buffer numbers are recycled, so a
-- stale entry could make a brand new buffer look already-painted and skip its
-- first animation. Drop the entry with the buffer.
vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
  group = group,
  callback = function(ev)
    painted[ev.buf] = nil
  end,
})

-- ---- :IndentColor -----------------------------------------------------------
--
-- Pick the lit guide's colour from the cmdline.
--
--   :IndentColor            open a picker over the presets below
--   :IndentColor magenta    set by preset name (tab-completes)
--   :IndentColor #ff00aa    set any hex
--   :IndentColor!           clear the override, back to whatever the theme picks
--
-- The colour is written to vim.g.indent_scope_color, which theme.lua's
-- apply_active_indent_scope_highlights() reads as its LAST word -- setting the
-- highlight group directly from here would be undone by the theme's own deferred
-- re-pins (0/50/200/330/655ms after any colorscheme). Setting the group here too
-- is just so the change lands on this frame rather than the next theme pass.
--
-- Only fg/sp are touched. Nothing here goes near the background.
local COLOR_FILE = vim.fn.stdpath("data") .. "/indent-scope-color.txt"

-- Deliberately maxed/neon rather than tasteful midtones: this guide is a single
-- thin column that has to read against the dim ladder behind it.
local presets = {
  cyan = "#00ffff",
  aqua = "#5ffbf1",
  mint = "#4bffb3",
  green = "#39ff14",
  yellow = "#ffe45c",
  amber = "#ffb000",
  orange = "#ff8c42",
  red = "#ff4d5a",
  magenta = "#ff2fd6",
  pink = "#ff8ad8",
  purple = "#bd93f9",
  blue = "#5aa2ff",
  white = "#ffffff",
  gray = "#6b7394",
}

local function preset_names()
  local names = {}
  for name in pairs(presets) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

-- Re-light the guide immediately: the ramp is built from the OLD resting colour
-- and cached, and last_key would otherwise dismiss this as "same scope, nothing
-- to do" and leave the guide sitting at the previous colour until you moved.
local function refresh_guide()
  invalidate_ramp()
  painted = {}
  stop_timer()
  schedule()
end

local function set_color(hex_str, persist)
  vim.g.indent_scope_color = hex_str
  for _, g in ipairs({ "SnacksIndentScope", "SnacksIndentChunk" }) do
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = g, link = false })
    local adj = {}
    if ok and type(hl) == "table" then
      for k, v in pairs(hl) do
        adj[k] = v
      end
    end
    adj.fg, adj.sp = hex_str, hex_str
    pcall(vim.api.nvim_set_hl, 0, g, adj)
  end
  if persist then
    pcall(vim.fn.writefile, { hex_str }, COLOR_FILE)
  end
  refresh_guide()
end

local function clear_color()
  vim.g.indent_scope_color = nil
  pcall(vim.fn.delete, COLOR_FILE)
  -- Cheapest honest way back to the theme's own value: re-run the colorscheme so
  -- apply_active_indent_scope_highlights() recomputes it. Recomputing it here
  -- would mean duplicating theme.lua's base16/storm logic, which would then rot.
  local name = vim.g.colors_name
  if name and name ~= "" then
    pcall(vim.cmd.colorscheme, name)
  end
  refresh_guide()
end

-- Accepts a preset name or #rrggbb (the # is optional).
local function resolve(arg)
  arg = vim.trim(arg or "")
  if arg == "" then
    return nil
  end
  if presets[arg:lower()] then
    return presets[arg:lower()]
  end
  local hex_body = arg:match("^#?(%x%x%x%x%x%x)$")
  if hex_body then
    return "#" .. hex_body:lower()
  end
  return nil
end

vim.api.nvim_create_user_command("IndentColor", function(opts)
  if opts.bang then
    clear_color()
    vim.notify("IndentColor: override cleared, back to the theme's colour", vim.log.levels.INFO)
    return
  end

  if vim.trim(opts.args) == "" then
    local names = preset_names()
    local items = vim.list_extend({ "<clear override>" }, names)
    vim.ui.select(items, {
      prompt = "Indent guide colour",
      format_item = function(item)
        if item == "<clear override>" then
          return item
        end
        return string.format("%-8s %s", item, presets[item])
      end,
    }, function(choice)
      if not choice then
        return
      end
      if choice == "<clear override>" then
        return clear_color()
      end
      set_color(presets[choice], true)
      vim.notify("IndentColor: " .. choice .. " " .. presets[choice], vim.log.levels.INFO)
    end)
    return
  end

  local hex_str = resolve(opts.args)
  if not hex_str then
    vim.notify(
      "IndentColor: not a preset or #rrggbb -- " .. opts.args .. "\npresets: " .. table.concat(preset_names(), ", "),
      vim.log.levels.ERROR
    )
    return
  end
  set_color(hex_str, true)
  vim.notify("IndentColor: " .. hex_str, vim.log.levels.INFO)
end, {
  nargs = "?",
  bang = true,
  complete = function(lead)
    return vim.tbl_filter(function(n)
      return n:find(lead, 1, true) == 1
    end, preset_names())
  end,
  desc = "Set the lit indent guide colour (preset name, #rrggbb, or ! to clear)",
})

-- Restore a previously chosen colour. Only the g: variable matters -- theme.lua
-- reads it on every pass -- so this is safe to run before the theme has loaded.
do
  local ok, lines = pcall(vim.fn.readfile, COLOR_FILE)
  if ok and type(lines) == "table" and lines[1] then
    local hex_str = resolve(lines[1])
    if hex_str then
      vim.g.indent_scope_color = hex_str
    end
  end
end

-- ---- :IndentCycle ------------------------------------------------------------
--
-- Override the day-mode hue cycle FOR THE CURRENT COLORSCHEME. Without one the
-- cycle is derived from the theme (resolve_cycle), which is what you want
-- almost always -- this exists for the theme where the derivation picks hues
-- you do not like.
--
--   :IndentCycle                       show what the cycle resolves to right now
--   :IndentCycle #2ff5ff #aaff00 #ffc21e   pin these for this theme (persisted)
--   :IndentCycle!                      drop the override, back to derived
--
-- From Lua: require nothing -- set anim.cycle_overrides in this file, or call
--   vim.fn.IndentCycleSet({ "#...", "#..." })     -- current theme
-- Entry 1 is overridden by :IndentColor if one is set; the rest are used as-is.
local CYCLE_FILE = vim.fn.stdpath("data") .. "/indent-cycle-overrides.json"

local function save_cycles()
  local ok, txt = pcall(vim.json.encode, anim.cycle_overrides or {})
  if ok then
    pcall(vim.fn.writefile, { txt }, CYCLE_FILE)
  end
end

-- The public override hook. `colors` is a list of #rrggbb (2+ entries), or nil
-- to clear. `theme` defaults to the live colorscheme.
local function set_cycle(colors, theme)
  theme = theme or vim.g.colors_name or "default"
  anim.cycle_overrides = anim.cycle_overrides or {}
  anim.cycle_overrides[theme] = colors
  save_cycles()
  invalidate_ramp()
  refresh_guide()
end

_G.IndentCycleSet = set_cycle

do
  local ok, lines = pcall(vim.fn.readfile, CYCLE_FILE)
  if ok and type(lines) == "table" and lines[1] then
    local ok2, tbl = pcall(vim.json.decode, lines[1])
    if ok2 and type(tbl) == "table" then
      anim.cycle_overrides = anim.cycle_overrides or {}
      for k, v in pairs(tbl) do
        anim.cycle_overrides[k] = v
      end
    end
  end
end

vim.api.nvim_create_user_command("IndentCycle", function(opts)
  local theme = vim.g.colors_name or "default"
  if opts.bang then
    set_cycle(nil, theme)
    vim.notify("IndentCycle: override cleared for " .. theme .. ", back to theme-derived", vim.log.levels.INFO)
    return
  end
  local args = vim.split(vim.trim(opts.args), "%s+", { trimempty = true })
  if #args == 0 then
    local base = group_fg(config.hl)
    local explicit = vim.g.indent_scope_color
    if type(explicit) ~= "string" or not explicit:match("^#%x%x%x%x%x%x$") then
      explicit = nil
    end
    local resolved = resolve_cycle(explicit, base)
    local src = (anim.cycle_overrides or {})[theme] and "override"
      or (anim.cycle_from_theme ~= false and "derived from theme" or "anim.cycle_colors")
    vim.notify(
      "IndentCycle [" .. theme .. "] (" .. src .. "): " .. table.concat(resolved, "  "),
      vim.log.levels.INFO
    )
    return
  end
  for _, a in ipairs(args) do
    if not a:match("^#%x%x%x%x%x%x$") then
      vim.notify("IndentCycle: not a #rrggbb -- " .. a, vim.log.levels.ERROR)
      return
    end
  end
  if #args < 2 then
    vim.notify("IndentCycle: need at least 2 colours (a 1-colour cycle is static)", vim.log.levels.ERROR)
    return
  end
  set_cycle(args, theme)
  vim.notify("IndentCycle [" .. theme .. "]: " .. table.concat(args, "  "), vim.log.levels.INFO)
end, {
  nargs = "*",
  bang = true,
  desc = "Override the day-mode indent hue cycle for the current colorscheme (! to clear)",
})

-- :IndentLadderDebug -- why does the lit guide end where it ends?
--
-- Put the cursor on a line where the guide looks too short and run this. It
-- reports the chosen guide column, the block extent, and crucially the exact
-- lines that TERMINATED the scan in each direction, with their indents -- which
-- is the thing that decides how far the guide reaches.
vim.api.nvim_create_user_command("IndentLadderDebug", function()
  local last = vim.fn.line("$")
  local cur = vim.fn.line(".")
  local sw = vim.fn.shiftwidth()
  if sw == 0 then
    sw = vim.bo.tabstop
  end
  local ci = delist_indent(cur, cursor_indent(cur, last))
  local col = math.floor((ci - 1) / sw) * sw
  local from, to = block_range(cur, col, last)

  local function stopper(dir)
    local l = dir < 0 and from - 1 or to + 1
    while l >= 1 and l <= last and is_blank(l) do
      l = l + dir
    end
    if l < 1 or l > last then
      return "(edge of file)"
    end
    return string.format("line %d indent=%d struct=%d  %q", l, vim.fn.indent(l), struct_indent(l), vim.fn.getline(l):sub(1, 48))
  end

  -- How far snacks' per-line guide runs at this same column, ignoring block
  -- structure -- i.e. how long the DIM line looks. A big gap between this and
  -- to..from is exactly the "lit bar is shorter than the dim bar" symptom.
  local vlo, vhi = from, to
  while vlo > 1 and (is_blank(vlo - 1) or vim.fn.indent(vlo - 1) > col) do
    vlo = vlo - 1
  end
  while vhi < last and (is_blank(vhi + 1) or vim.fn.indent(vhi + 1) > col) do
    vhi = vhi + 1
  end

  local drawn = 0
  for _ in pairs(active) do
    drawn = drawn + 1
  end

  local msg = {
    string.format("cursor line %d, indent %d, shiftwidth %d", cur, ci, sw),
    string.format("guide column %d  (guide #%d from the left)", col, col / sw + 1),
    string.format("block extent  %d..%d  (%d lines)", from, to, to - from + 1),
    string.format("visual run    %d..%d  <- how far the dim guide reaches", vlo, vhi),
    string.format("stopped going UP at:   %s", stopper(-1)),
    string.format("stopped going DOWN at: %s", stopper(1)),
    string.format("window shows %d..%d, extmarks currently drawn: %d", vim.fn.line("w0"), vim.fn.line("w$"), drawn),
  }
  vim.notify(table.concat(msg, "\n"), vim.log.levels.INFO, { title = "IndentLadder" })
  print(table.concat(msg, "\n"))
end, { desc = "Diagnose where the lit indent guide stops and why" })

return {}
