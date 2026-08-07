-- palenightv2 — byte-identical copy of base16-material-palenight. All 16 slots
-- are stock; nothing here is tuned. The point of this file is only to give the
-- copy its own NAME, so theme_baseline.lua can carry a values-only glow table
-- for it without touching the original base16-material-palenight.
--
-- Source: lazy/base16-nvim/lua/colors/material-palenight.lua

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.o.termguicolors = true

require("base16-colorscheme").setup({
  base00 = "#292d3e", -- stock
  base01 = "#444267", -- stock
  base02 = "#32374d", -- stock
  base03 = "#676e95", -- stock
  base04 = "#8796b0", -- stock
  base05 = "#959dcb", -- stock
  base06 = "#959dcb", -- stock
  base07 = "#ffffff", -- stock
  base08 = "#f07178", -- stock
  base09 = "#f78c6c", -- stock
  base0A = "#ffcb6b", -- stock
  base0B = "#c3e88d", -- stock
  base0C = "#89ddff", -- stock
  base0D = "#82aaff", -- stock
  base0E = "#c792ea", -- stock
  base0F = "#ff5370", -- stock
})

vim.g.colors_name = "palenightv2"
