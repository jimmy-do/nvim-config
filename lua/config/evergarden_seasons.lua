-- evergarden, actually seasonal.
--
-- ---------------------------------------------------------------------------
-- WHY THIS EXISTS
-- ---------------------------------------------------------------------------
-- comfysage/evergarden ships four "variants" — fall, spring, summer, winter —
-- and three of them are the SAME THEME. Measured 2026-07-30 against
-- ~/.local/share/nvim/lazy/evergarden/lua/evergarden/palettes/*.lua: fall,
-- spring and winter are byte-identical on every foreground slot (red #f57f82,
-- blue #b2caed, text #f8f9e8, all twelve accents). The only thing a season
-- changes upstream is `base`/`surface*`/`mantle`/`crust` — i.e. the background
-- shade (fall #232a2e, winter #1e2528, spring #2b3438). Jimmy hardcodes the
-- background (bg_base), so the pipeline overwrites exactly the one channel that
-- differed and the three names render pixel-for-pixel identically. Picking a
-- season was a no-op.
--
-- So the seasons are rebuilt here as real palettes. Summer is deliberately not
-- among them (light variant, unwanted).
--
-- ---------------------------------------------------------------------------
-- THE RULE EVERY COLOUR BELOW OBEYS
-- ---------------------------------------------------------------------------
-- Ghostty's shader
-- (shaders/macbook-m4max-2056-theme-friendly-sharp.glsl, neonBloom 0.30) gates
-- its halo on HSV saturation smoothstep(0.22, 0.55) and scales emission by the
-- PEAK channel. Two consequences drive the whole design:
--
--   * a colour only GLOWS at sat >= ~0.55 with a channel at/near 1.0;
--   * hues 90-162 (the green band around the shader's fgHueRef) never bloom at
--     all, no matter how saturated.
--
-- Evergarden is a forest theme, so that dead band is not a problem to route
-- around — it is the feature. Every season parks its KEY ramp inside the band
-- (fall 105, spring 116, winter 152: moss, leaf, frosted pine) where it reads
-- as calm structural green, and puts every yaml VALUE outside it at sat >= 0.55
-- where it burns. Keys hold the shape of the file, values are the light. That
-- is the seasonal look, and it is the same mechanism in all three.
--
-- NOTE this is NOT the yaml-glow-separation idea that was built and rejected
-- twice (see the memory of the same name): nothing here desaturates or dims a
-- key to quiet it, and no other theme is touched. These three schemes are green
-- ALREADY — the band is where evergarden's keys naturally live.
--
-- The per-token yaml hexes are NOT here; they are hand tables in
-- lua/config/theme_baseline.lua (keys "evergarden-fall" / "-spring" /
-- "-winter"), which is the file that reloads on :ThemeReload. This module owns
-- the base palette — everything that is not yaml (lua, go, markdown, the UI)
-- takes its colour from here.
--
-- ---------------------------------------------------------------------------
-- ONE MECHANICAL THING THAT MATTERS
-- ---------------------------------------------------------------------------
-- evergarden.load() stamps `vim.g.colors_name = 'evergarden'` for EVERY variant
-- (same trap as kanagawa). colors_name is the lookup key for the baseline hand
-- tables, colorscheme_defaults, glow_tiers and theme_facets, so left alone all
-- three seasons would (a) find no table of their own and (b) collide with the
-- stock `evergarden` entry — the one theme Jimmy asked to leave untouched. So
-- load() is stamped over LAST, exactly the way colors/ever-glow.lua does it.
--
-- Related: [[transfer-themes-by-rendering-stock]] (these palettes keep
-- evergarden's own hues and only move temperature), [[yaml-glow-separation-is-a-dead-end]].

local M = {}

-- Backgrounds are listed for completeness only: adjust_all_highlights stamps
-- bg_base over every bg in the theme, so these decide nothing while bg_base is
-- pinned. They exist so a raw load (:ThemeRaw) still looks like the season.
M.seasons = {
  -- =========================================================================
  -- FALL — ember & harvest. Evergarden's warm band pushed to rust and amber,
  -- the greens dried out to moss, the cool half kept as smoke so the warmth has
  -- something to sit against.
  -- =========================================================================
  fall = {
    accent = "orange",
    -- Green-grey, not bark brown. The first cut had every neutral on a warm
    -- axis (comment #4f4437, text #f6ecd9, overlays #8f8a76) and the sum of
    -- that reads as a sepia filter even with sepia_amount pinned at 0. The
    -- warmth belongs to the ACCENTS; the neutrals stay neutral.
    comment = "#47513f",
    colors = {
      red = "#ff7b6b",
      orange = "#ffa45c",
      yellow = "#ffd07a",
      lime = "#e0e07f",
      green = "#c6cf8d", -- moss, not leaf
      aqua = "#a8d9b8",
      skye = "#a9d9d2",
      snow = "#b8cfd6",
      blue = "#a9c0e8",
      purple = "#c8b6e8",
      pink = "#f5b8dc",
      cherry = "#ffe0e8",
      text = "#f2f2e4", -- near-neutral; was a cream that tinted the whole screen
      subtext1 = "#c3c8b8",
      subtext0 = "#a8ae9d",
      overlay2 = "#8b9285",
      overlay1 = "#757c70",
      overlay0 = "#5b625a",
      surface2 = "#474d47",
      surface1 = "#363b37",
      surface0 = "#272b28",
      base = "#20241f",
      mantle = "#1a1d19",
      crust = "#151714",
    },
  },

  -- =========================================================================
  -- SPRING — bloom. The greens go back to leaf and the warm band turns to
  -- blossom: pollen gold, tulip red, magenta. Brightest of the three.
  -- =========================================================================
  spring = {
    accent = "green",
    comment = "#3f5142", -- shaded leaf
    colors = {
      red = "#ff8f9c",
      orange = "#ffb583",
      yellow = "#ffe6a0",
      lime = "#d9f79b",
      green = "#a9f0b4",
      aqua = "#8ff0cf",
      skye = "#93f0e6",
      snow = "#a8dff0",
      blue = "#a6cdff",
      purple = "#d4b6ff",
      pink = "#ffb3e0",
      cherry = "#ffe4f2",
      text = "#f2fbe9",
      subtext1 = "#b9d6bd",
      subtext0 = "#a0c0a6",
      overlay2 = "#87a58e",
      overlay1 = "#6f8a77",
      overlay0 = "#586d5e",
      surface2 = "#46584c",
      surface1 = "#35443a",
      surface0 = "#26332b",
      base = "#1f2a22",
      mantle = "#19211b",
      crust = "#141a16",
    },
  },

  -- =========================================================================
  -- WINTER — ice. Cyan/blue/violet own the palette; the warm slots survive only
  -- as winterberry and lantern amber, which is the one warm thing allowed on
  -- screen and therefore the thing the eye finds first.
  -- =========================================================================
  winter = {
    accent = "skye",
    comment = "#3d4b57", -- deep shadow on snow
    colors = {
      red = "#ff8fa3",
      orange = "#ffb99a",
      yellow = "#ffe6b0",
      lime = "#cdeec4",
      green = "#a8e8c8",
      aqua = "#96ecd8",
      skye = "#8ff2ea",
      snow = "#b9ecff",
      blue = "#9dc4ff",
      purple = "#c4b6ff",
      pink = "#f0b8e8",
      cherry = "#eaf2ff",
      text = "#eaf6ff",
      subtext1 = "#b6cddb",
      subtext0 = "#9db4c4",
      overlay2 = "#7f97a6",
      overlay1 = "#6b8192",
      overlay0 = "#556878",
      surface2 = "#43535f",
      surface1 = "#333f49",
      surface0 = "#242e36",
      base = "#1a2026",
      mantle = "#151a1f",
      crust = "#111519",
    },
  },
}

-- Comment fg per season, read by apply_evergarden_comment_style in theme.lua.
-- Constants, never derived from live state: that pass runs on every pipeline
-- run, so a "read the current fg and darken it" version walks to black.
function M.comment_fg(colors_name)
  local season = M.seasons[(colors_name or ""):match("^evergarden%-(%a+)$") or ""]
  return season and season.comment or nil
end

-- Load a season and claim the name. Called from colors/evergarden-<season>.lua.
function M.load(name)
  local season = M.seasons[name]
  if not season then
    return false
  end

  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end
  vim.o.termguicolors = true

  local ok, evergarden = pcall(require, "evergarden")
  if not ok then
    return false
  end

  -- cache = false deliberately: evergarden's compile cache is keyed on its own
  -- config, and these palettes arrive through load()'s temporary override
  -- rather than setup(), which is exactly the shape a stale cache serves the
  -- wrong colours for.
  local loaded = pcall(evergarden.load, {
    theme = { variant = name, accent = season.accent },
    color_overrides = season.colors,
    cache = false,
  })
  if not loaded then
    return false
  end

  -- LAST, always: load() sets it to plain "evergarden". See the header.
  vim.g.colors_name = "evergarden-" .. name
  return true
end

return M
