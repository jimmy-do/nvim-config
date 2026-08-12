-- acidwave — acid_teal + synthwave, with azure and amber. Created 2026-08-09.
--
-- THE SQUAD
-- ---------------------------------------------------------------------------
-- Four colours, taken verbatim from Jimmy's starship palette so nvim, tmux and
-- the prompt agree on what these names mean:
--
--   acid_teal  #00ffc8   pill_acid_teal      the hero. Values.
--   azure      #73d0ff   pill_azure          structure. Keys.
--   synthwave  #ffb3ec   pill_synthwave      THE pink. Jimmy named this hex.
--   amber      #ffbf80   pill_amber          the soft pastel orange
--
-- There is deliberately NO red and NO orange-red anywhere in this theme. The
-- warm slot is amber and only amber.
--
-- ASSIGNED BY ROLE, NOT BY SHAPE
-- ---------------------------------------------------------------------------
-- This follows the standard documented in the moonlightv4 header of
-- theme_baseline.lua: "gruvbox gives one colour per ROLE and reuses it
-- everywhere -- its yaml image/url/path are all #d3869b". Assigning per SHAPE
-- instead produces nine value colours, several pairs the eye cannot separate,
-- and literals sharing hexes with punctuation. The first draft of this theme
-- made exactly that mistake and was rebuilt.
--
--   acid_teal  167   DATA       strings, quoted or not
--   azure      202   TYPE       enums, bare selectors, ${{ }} props
--   amber       30   LOCATOR    urls, paths, images
--   synthwave  315   SCALAR     numbers, quantities, booleans, versions, env
--   #999999    n/a   STRUCTURE  all punctuation (achromatic, no hue)
--
-- Minimum hue gap 33 degrees, so no two families read as a shade pair. Only ONE
-- synthwave is used: the hot #ff33cc variant is 2 degrees from #ffb3ec and
-- using both would be a shade pair with itself. STRUCTURE is achromatic, so it
-- is exempt from the rule entirely.
--
-- The full per-group assignment lives in theme_baseline_saved.lua under
-- ["acidwave"], pinned so the palette census cannot drift it.
--
-- WHY THE KNOBS ARE ALL NEUTRAL
-- ---------------------------------------------------------------------------
-- theme_config_saved.lua carries sepia_amount 0 / fg_lightness 50 /
-- fg_saturation 50 for this theme, and theme_pin_reference.lua carries the SAME
-- three. That is not laziness, it is the whole design:
--
--   * neutral knobs mean the hexes below render VERBATIM. Measured 08-09: under
--     a non-neutral sepia the pipeline supersaturates accents before the palette
--     is read, and palette edits become decorative.
--   * the pin reference MUST match the config. It is the frozen origin that
--     pinned hexes move relative to; a mismatch turns the difference into a
--     delta and drags hue (a stale 0-vs--99 dragged pins ~20 degrees on 08-09).
--
-- So: to retune this theme, edit THESE HEXES. Do not reach for sepia/fg knobs --
-- they will fight the palette and drag hue. If a knob ever does change, change
-- theme_pin_reference.lua to match in the same commit.
--
-- Chroma note: acid_teal is 100% chroma at L50, the maximum a colour can carry.
-- Raising lightness spends chroma 1:1 and reads as WASHED OUT, not brighter.
-- Punch here comes from hue separation and from bold weight on keys, not from
-- turning any brightness dial up.
--
-- BgTransparencyLock is armed at 100, so base00-02 are discarded before they
-- reach a cell. They are set coherently anyway so the theme is correct if it is
-- ever viewed opaque.
--
-- `vim.g.colors_name` is stamped LAST, after setup(). base16-colorscheme.setup()
-- writes its own colors_name, so setting it earlier gets silently overwritten
-- and every name-keyed lookup -- knobs, pins, the pin reference -- would miss.

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.o.termguicolors = true

require("base16-colorscheme").setup({
  base00 = "#10141c", -- bg (discarded under transparency)
  base01 = "#19202c", -- darker bg / cursorline
  base02 = "#28334a", -- selection
  base03 = "#5f7391", -- comments -- quiet blue-grey, still legible over video
  base04 = "#8fa3bd", -- dim text / line numbers
  base05 = "#c9d6e8", -- body text -- cool white, no lavender cast
  base06 = "#e0e8f5", -- bright text
  base07 = "#f5f9ff", -- brightest
  -- STRICTLY the four squad colours below -- no lifts, no dim variants. Earlier
  -- drafts used #ffd199 (amber lift) and #9fe0ff (azure lift); both are shade
  -- pairs of a colour already present, which theme_baseline.lua forbids
  -- outright: "NO dim variants of other classes -- shade pairs read as lazy".
  -- A base16 slot repeating a squad colour is correct; a slot holding a near-miss
  -- of one is not.
  base08 = "#ffb3ec", -- SYNTHWAVE  -- variables, booleans (SCALAR role)
  base09 = "#ffbf80", -- AMBER      -- numbers, constants (LOCATOR role)
  base0A = "#ffbf80", -- AMBER      -- types / classes, same family
  base0B = "#00ffc8", -- ACID TEAL  -- strings. The hero. (DATA role)
  base0C = "#73d0ff", -- AZURE      -- escapes, support (TYPE role)
  base0D = "#73d0ff", -- AZURE      -- functions
  base0E = "#ffb3ec", -- SYNTHWAVE  -- keywords
  base0F = "#ffbf80", -- AMBER      -- rare slot
})

vim.g.colors_name = "acidwave"
