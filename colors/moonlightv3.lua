-- moonlightv3 — base16-moonlight with three flat accents nudged over the glow
-- gate. Everything else is byte-for-byte stock.
--
-- ---------------------------------------------------------------------------
-- SCOPE
-- ---------------------------------------------------------------------------
-- base16-moonlight IS the original Moonlight (atomiks). Its palette is not an
-- approximation of anything and does not need "correcting":
--
--   base00 #212337  base01 #403c64  base02 #596399  base03 #748cd6
--   base04 #a1abe0  base05 #a3ace1  base06 #b4a4f4  base07 #ef43fa
--   base08 #ff5370  base09 #f67f81  base0A #ffc777  base0B #2df4c0
--   base0C #04d1f9  base0D #40ffff  base0E #b994f1  base0F #ecb2f0
--
-- 13 of those 16 slots are reproduced here unchanged. Hue is not touched on
-- any slot. Value is not touched on any slot. Three saturations move.
--
-- ---------------------------------------------------------------------------
-- WHAT MOVES, AND WHY ONLY THREE
-- ---------------------------------------------------------------------------
-- The ghostty bloom shader lights a cell once HSV saturation clears ~0.55, and
-- skips greens in the 90-162 hue band. Moonlight's signature accents already
-- clear it comfortably, so they are left completely alone:
--
--   base0C #04d1f9  0.98      base0B #2df4c0  0.82  (h=164, just clear)
--   base0D #40ffff  0.75      base07 #ef43fa  0.73
--   base08 #ff5370  0.67
--
-- Three slots sat below the gate. They are BRIGHTENED (scaled to the channel
-- ceiling), never re-mixed -- hue and channel ratios are preserved exactly:
--
--   base09 #f67f81 -> #ff8486   hue 359, unchanged
--   base0A #ffc777 -> #ffc777   already at ceiling, hue 41.6, unchanged
--   base0E #b994f1 -> #c49dff   hue 264, unchanged
--
-- CORRECTED 2026-07-27. The previous set (#f6676a / #ffc26b / #a16bf2) raised
-- SATURATION by hand instead, which drags hue: base0A went 41.6 -> 35.3, i.e.
-- Moonlight's gold turned into an orange. That orange paints @type.yaml.enum
-- and the YamlExpr contexts (github, env, inputs), so it landed right next to
-- the mint values and read as two different themes on one screen. Saturation
-- nudging is what broke this. Scale to the ceiling; do not re-mix by eye.
--
-- ---------------------------------------------------------------------------
-- WHAT IS DELIBERATELY LEFT ALONE
-- ---------------------------------------------------------------------------
-- base03/base04/base05/base06 -- the fg ramp. An earlier version of this file
-- saturated base03 and base04 to force YAML (which base16 paints almost
-- entirely out of the ramp) over the gate. Measuring the live pane showed why
-- that was a mistake: it produced four near-identical blues stacked on top of
-- each other --
--
--   #a3ace1 fg x81   #4c6ac7 comments x38   #6378eb keys x19   #5c77cc x13
--
-- all at hue 225-231, all mid-saturation, none readable against the others.
-- Glow needs something NOT glowing to sit against, and the ramp is that
-- something. It stays stock.
--
-- base0F #ecb2f0 sits at 0.26. Reaching the gate from there means a pale pink
-- turning into hot magenta -- that is a different colour, not a brighter one,
-- so it stays stock too.
--
-- base00/base01/base02 are the background, cursorline and selection. Untouched.

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

vim.g.colors_name = "moonlightv3"
