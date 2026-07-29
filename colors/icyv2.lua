-- icyv2 — byte-identical copy of base16-icy. All 16 slots are stock; nothing
-- here is tuned. The point of this file is only to give the copy its own NAME,
-- so theme_baseline.lua can carry a values-only glow table for it without
-- touching the original base16-icy.
--
-- The yaml VALUE colours (glow pink / cyan / #00ffcb mint / light blue /
-- orange) live in lua/config/theme_baseline.lua under ["icyv2"] — keys,
-- punctuation and comments stay derived from this stock palette.

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.o.termguicolors = true

require("base16-colorscheme").setup({
  base00 = "#021012", -- stock
  base01 = "#031619", -- stock
  base02 = "#041f23", -- stock
  base03 = "#052e34", -- stock
  base04 = "#064048", -- stock
  base05 = "#095b67", -- stock
  base06 = "#0c7c8c", -- stock
  base07 = "#109cb0", -- stock
  base08 = "#16c1d9", -- stock
  base09 = "#b3ebf2", -- stock
  base0A = "#80deea", -- stock
  base0B = "#4dd0e1", -- stock
  base0C = "#26c6da", -- stock
  base0D = "#00bcd4", -- stock
  base0E = "#00acc1", -- stock
  base0F = "#0097a7", -- stock
})

vim.g.colors_name = "icyv2"
