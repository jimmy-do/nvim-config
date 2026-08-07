-- moonlightv5 — v4's palette and structure, re-paired around a cyan leader.
--
-- ---------------------------------------------------------------------------
-- WHY A V5
-- ---------------------------------------------------------------------------
-- v4 got the ROLE logic right (six value families, one structure family) but
-- the family colours themselves were picked to stay inside Moonlight's slots.
-- The 2026-07-29 request is the other way round: pick the colours first, from a
-- named shortlist, and hang the same six roles off them.
--
--   #00ffff  cyan     THE LEADER — the colour the file is supposed to read as
--   #ffc777  gold     kept verbatim, by name (Moonlight base0A, untouched)
--   blue              "your standard blue"
--   red               "your standard red" — already the structure colour
--   pink              "a soft nice pink"
--
-- Everything else in this file is v4 byte-for-byte. The base16 slots below feed
-- the UI and non-yaml syntax and are deliberately unchanged from v3/v4; the yaml
-- value hexes that actually glow live in the moonlightv5 table in
-- lua/config/theme_baseline.lua. Read that file for the pairing.
--
-- WHAT IS FROZEN (per request):
--   * the `-` dash colour  (base08 red #ff5370)
--   * the `:` colon colour (v3's aqua #29cccc)
--   * the whole yaml KEY ramp (v3's Moonlight blues)
-- Only the value families moved.
--
-- ---------------------------------------------------------------------------
-- PALETTE (identical to v3/v4 = base16-moonlight with three sats scaled)
-- ---------------------------------------------------------------------------
-- base16-moonlight IS the original Moonlight (atomiks). 13 of 16 slots stock;
-- three scaled to the channel ceiling with hue and channel ratios preserved.

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

vim.g.colors_name = "moonlightv5"
