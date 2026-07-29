-- stormv2 — verbatim copy of base16-tokyo-night-terminal-storm, ready to be
-- retuned. Palette is identical; nothing changed yet.
--
-- A copy of this theme is NOT just the palette. Storm is the most hand-tuned
-- scheme in this config, and three other things are keyed to its NAME:
--   1. the ["base16-tokyo-night-terminal-storm"] table in theme_baseline.lua
--      (the whole yaml range) -- duplicated there as ["stormv2"];
--   2. six branches in plugins/theme.lua (punct overlay, {{ }} brackets, the
--      cyan indent scope, dim indent guides, the yaml startup pass, the URL
--      reset) -- those now test is_storm_family(), which accepts both names;
--   3. the colorscheme_defaults knob block in theme.lua -- also duplicated.
-- Change any of those for stormv2 and the original is unaffected.

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.o.termguicolors = true

require("base16-colorscheme").setup({
  base00 = "#24283b", -- bg
  base01 = "#1a1b26",
  base02 = "#343a52",
  base03 = "#444b6a",
  base04 = "#787c99",
  base05 = "#787c99", -- fg
  base06 = "#cbccd1",
  base07 = "#d5d6db",
  base08 = "#f7768e",
  base09 = "#ff9e64",
  base0A = "#e0af68",
  base0B = "#41a6b5",
  base0C = "#7dcfff",
  base0D = "#7aa2f7",
  base0E = "#bb9af7",
  base0F = "#d18616",
})

vim.g.colors_name = "stormv2"
