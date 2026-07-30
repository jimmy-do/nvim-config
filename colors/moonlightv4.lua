-- moonlightv4 — same palette as moonlightv3, different ASSIGNMENT LOGIC.
--
-- ---------------------------------------------------------------------------
-- WHY A V4 AT ALL
-- ---------------------------------------------------------------------------
-- The palette was never the problem. v3's 16 slots are Moonlight's own (three
-- scaled to the channel ceiling) and this file reproduces them byte-for-byte.
-- What changes is WHAT EACH COLOUR MEANS, and that lives in the moonlightv4
-- table in lua/config/theme_baseline.lua -- read that file, not this one, to see
-- the actual difference.
--
-- The short version, measured against gruvbox (Jimmy's gold standard) on
-- 2026-07-29:
--
--   gruvbox colours by ROLE     -- "what kind of thing is this": literal, type,
--                                  constant, structure. One colour per role, the
--                                  same one in every language, forever. Its yaml
--                                  image/url/path are all #d3869b; its quoted and
--                                  unquoted strings are the same green.
--   v3 colours by SHAPE         -- url, path, version, image, quantity, enum,
--                                  condition each got their own colour: 9 value
--                                  colours doing 13 jobs.
--
-- Shape-colouring produced pairs the eye cannot resolve and, worse, collisions
-- ACROSS roles. Measured in v3:
--
--   number = quantity = bracket = `---`   all #40ffff  (a literal painted as
--                                         structure -- nothing separates data
--                                         from punctuation)
--   path #00ffff / number #40ffff /       four cyans inside 10 degrees, the same
--   colon #29cccc / boolean #04d6ff       failure v3's own file documents for the
--                                         blue fg ramp
--   quoted #0dffc0 vs string #2fffc9      a shade pair at one hue -- "shade pairs
--                                         read as lazy", per moonlightv2
--   env = string, both #2fffc9            a constant painted as a string, so the
--                                         class is invisible
--   identifier = statement = dash =       four unrelated roles on one colour
--   anchor = merge, all #ff5370
--
-- v4 collapses those to SIX value families and one structure family, which is
-- the count gruvbox runs. Nothing is invented: every hex is a Moonlight slot.
--
-- ---------------------------------------------------------------------------
-- THE ONE THING TO LOOK AT FIRST
-- ---------------------------------------------------------------------------
-- 2026-07-29, three requests applied to the baseline table:
--
--   1. The green key ramp is GONE. Keys are v3's Moonlight blues again.
--   2. `-` and `:` are copied from v3 verbatim: dash base08 red #ff5370, colon
--      aqua #29cccc. NOT one shared colour -- an intermediate pass put both on
--      base08 red and that was rejected as too much orange/red. The dim slate
--      colon an even earlier v4 used is also dead; do not reinstate either.
--   3. EVERY value family clears the shader glow gate. gold, purple, pink and the
--      null/~ periwinkle all measured under HSV sat 0.55 and could not bloom, so
--      each was re-cut at its exact hue with a lower black point.
--
-- Consequence for THIS file: the base16 slots below are what v3 shipped and are
-- deliberately left alone -- they feed the UI and non-yaml syntax. The yaml value
-- hexes that actually glow live in the moonlightv4 table in theme_baseline.lua,
-- and several of them are now BRIGHTER than the corresponding slot here. That is
-- intentional, not drift.
--
-- ---------------------------------------------------------------------------
-- PALETTE (identical to v3, which is base16-moonlight with three sats scaled)
-- ---------------------------------------------------------------------------
-- base16-moonlight IS the original Moonlight (atomiks) and does not need
-- correcting. 13 of 16 slots are stock. Three are scaled to the channel ceiling
-- -- hue and channel ratios preserved exactly, never re-mixed by eye:
--
--   base09 #f67f81 -> #ff8486   hue 359, unchanged
--   base0A #ffc777 -> #ffc777   already at ceiling, hue 41.6, unchanged
--   base0E #b994f1 -> #c49dff   hue 264, unchanged
--
-- The fg ramp (base03-base06) stays stock: it is the non-glowing mass the glow
-- reads against. Saturating it produced four competing blues, which is why v3
-- stopped doing that and v4 does not revisit it.

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.o.termguicolors = true

require("base16-colorscheme").setup({
  base00 = "#212337", -- stock
  base01 = "#403c64", -- stock
  base02 = "#596399", -- stock
  base03 = "#748cd6", -- stock
  base04 = "#a1abe0", -- stock
  base05 = "#a3ace1", -- stock
  base06 = "#b4a4f4", -- stock
  base07 = "#ef43fa", -- stock, s0.73 already glows
  base08 = "#ff5370", -- stock, s0.67 already glows
  base09 = "#ff8486", -- base09 #f67f81 brightened to ceiling, hue kept at 359
  base0A = "#ffc777", -- base0A stock: already at ceiling, hue 41.6
  base0B = "#2df4c0", -- stock, s0.82 already glows (h=164, clear of 90-162)
  base0C = "#04d1f9", -- stock, s0.98 already glows
  base0D = "#40ffff", -- stock, s0.75 already glows
  base0E = "#c49dff", -- base0E #b994f1 brightened to ceiling, hue kept at 264
  base0F = "#ecb2f0", -- stock
})

vim.g.colors_name = "moonlightv4"
