-- moonlightv7 — v6's colours, re-paired one-colour-per-role.
--
-- ---------------------------------------------------------------------------
-- WHY A V7
-- ---------------------------------------------------------------------------
-- v6 is a SNAPSHOT of a live poking session and is deliberately preserved as
-- one. The cost of that is that its colours were moved token by token, not
-- family by family, so in v6 a single hue can mean three unrelated things
-- (cyan = strings AND bare words AND paths) and one family can be spread over
-- three hues (url green, path cyan, image lilac). That is why recolouring a
-- group with :HlColor in v6 hits a different slice of a manifest than the same
-- recolour does in any other theme here — the group boundaries do not line up
-- with the role boundaries.
--
-- v7 fixes exactly that and changes nothing else. Same palette, same look on
-- the tokens Jimmy named as keepers, every family collapsed onto ONE colour:
--
--   role        colour     what it paints
--   DATA        #00e676    strings, quoted or not                (kept: tron green)
--   LOCATOR     #d98cff    urls, paths, images                   (was 3 colours)
--   SCALAR      #40ffff    numbers, quantities                   (kept: the cyan)
--   BOOLEAN     #ff6a00    true / false / yes / no               (kept: orange)
--   EXTERNAL    #ff527d    versions, conditions, env vars        (rose)
--   TYPE        #ffc777    enums, bare selector words            (gold)
--   STRUCTURE   #ff5370    dashes, doc markers, anchors, COLONS  (kept: the red)
--
-- THE COLON IS RED HERE, NOT CYAN. Requested 2026-07-29: the `:` takes the dash
-- mark's colour. v6 keeps its cyan #00d5ff colon; this is the one place the two
-- themes deliberately differ on a token Jimmy called a keeper.
--
-- WHY LILAC GOT THE LOCATORS. The alternative was rose #ff527d, which is four
-- degrees of hue off the dash red — dashes and urls would have read as the same
-- colour. Lilac sits 60+ degrees clear of everything structural. Rose is still
-- in the theme, on EXTERNAL, where it never shares a line with a dash.
--
-- ABOUT THE DOUBLED `.yaml` ROWS in the baseline table: treesitter resolves the
-- language-suffixed group first, and those groups are global highlight state
-- that SURVIVES a colorscheme switch. v6 defines eight of them. If v7 set only
-- the bare names, switching v6 -> v7 would leave v6's suffixed hexes winning and
-- v7 would render as a half-merged hybrid. So v7 sets both rows for every class
-- v6 suffixes. Do not delete one half of a pair.
--
-- ---------------------------------------------------------------------------
-- PALETTE (identical to v3/v4/v5/v6 = base16-moonlight with three sats scaled)
-- ---------------------------------------------------------------------------

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

vim.g.colors_name = "moonlightv7"
