-- ever-glow — everforest, with the yaml value families pushed up into glow range.
--
-- ---------------------------------------------------------------------------
-- WHAT THIS IS
-- ---------------------------------------------------------------------------
-- A copy of the live everforest (neanias/everforest-nvim) as it renders through
-- theme.lua's pipeline, with ONE change: every yaml VALUE family is boosted
-- +35% HSV saturation and +6% value. Same hues, same role pairing, same
-- everything else — just sparklier. The per-group hexes are in the ever-glow
-- table in lua/config/theme_baseline.lua; read that for the before/after.
--
-- WHY IT LOADS EVERFOREST INSTEAD OF LISTING A PALETTE
-- moonlightv*.lua can hand base16-colorscheme sixteen hexes because they ARE
-- base16 themes. everforest-nvim is not — it builds its own group table, so the
-- only honest way to copy it is to load it and rename. Which means:
--
--   * NO `background` is set below, on purpose. Whatever variant Jimmy's
--     everforest setup resolves to is what this inherits, so ever-glow always
--     tracks the everforest he actually looks at rather than pinning a variant
--     that then drifts. To pin one, add background = "hard" | "medium" | "soft"
--     to the setup call.
--   * vim.g.colors_name is stamped LAST. It is the baseline table's lookup key
--     (see apply_theme_baseline_colors), so if everforest's own load overwrote
--     it the sparkle table would never be found and this would render as plain
--     everforest.
--
-- WHAT IS DELIBERATELY NOT BOOSTED
--   null / ~        absence recedes; boosting it to #0175e2 made it the
--                   loudest thing in the file, which is backwards
--   comments        same reason
--   the key ramp    lifted, but only to where the boosted values still win
--   the background  untouched
--
-- ONE THING TO KNOW ABOUT GREEN: everforest's strings are green (hue 107), and
-- the ghostty shader's bloom skips hues 90-162 entirely. So the boosted strings
-- read brighter but they will never actually glow the way the cyan enums and
-- pink scalars now do. That is the shader, not this file — moving strings out of
-- the band would mean giving up everforest's whole identity.

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.o.termguicolors = true

local ok, everforest = pcall(require, "everforest")
if ok then
  everforest.load()
else
  -- everforest-nvim missing: fall back to its base16 port so the file still
  -- loads something in the right family rather than leaving the screen on
  -- whatever was there before.
  pcall(vim.cmd.colorscheme, "base16-everforest")
end

vim.g.colors_name = "ever-glow"
