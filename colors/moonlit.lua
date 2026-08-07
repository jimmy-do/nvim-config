-- moonlit — a private copy of base16-moonlight. Recreated stock 2026-08-02.
--
-- WHY THIS EXISTS
-- ---------------------------------------------------------------------------
-- base16-moonlight is a PLUGIN file
-- (lazy/base16-nvim/colors/base16-moonlight.vim). Anything keyed to that name
-- is keyed to something Jimmy does not own: the plugin can update, and the
-- name is shared with upstream. Every per-theme thing in this config is keyed
-- by colorscheme name -- :HlColorSave overrides in config/theme_baseline_saved.lua,
-- knob defaults in colorscheme_defaults (plugins/theme.lua), :ThemeConfigSave
-- entries -- so the name IS the identity. Owning the name means the tuning
-- cannot be pulled out from under him.
--
-- Same rule as the evergarden seasons: ours live in colors/, upstream stays
-- untouched.
--
-- THE PALETTE IS BYTE-FOR-BYTE STOCK, and so is everything else: the 07-31
-- copy's ten :HlColorSave overrides and its bg_transparency entry were deleted
-- on 2026-08-02, so this theme now renders exactly as base16-moonlight does.
-- Retune from here if wanted.
--
-- `vim.g.colors_name` is stamped LAST, after setup(). base16-colorscheme.setup()
-- writes its own colors_name, so setting it earlier gets silently overwritten
-- and the theme reports as base16-moonlight -- which would defeat the whole
-- point of the copy and send every keyed lookup back to the plugin's name.

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
  base07 = "#ef43fa", -- stock
  base08 = "#ff5370", -- stock
  base09 = "#f67f81", -- stock
  base0A = "#ffc777", -- stock
  base0B = "#2df4c0", -- stock
  base0C = "#04d1f9", -- stock
  base0D = "#40ffff", -- stock
  base0E = "#b994f1", -- stock
  base0F = "#ecb2f0", -- stock
})

vim.g.colors_name = "moonlit"
