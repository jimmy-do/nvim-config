-- nvim-gruvbox — Jimmy's tuned gruvbox forest, made self-contained.
--
-- This started as base16-gruvbox-dark-medium-forest run at sepia_amount = -90,
-- fg_lightness = 60, fg_saturation = 99. That look is his; the knobs that
-- produced it were the problem. Under a chain that heavy every hex saved by
-- :HlColor went into the pipeline as an INPUT and came out somewhere else --
-- #9cff29 drew as #61ed00, #ff6329 as #ff4511 -- so saved yaml colours never
-- rendered as typed and each :HlColorSave looked like it had silently failed.
--
-- So the chain is applied here ONCE, by hand, and then switched off. Each slot
-- below is the stock forest hex already pushed through it:
--   base04-base0F  sepia(-0.90) then adjust_fg_hsl(60, 99)   -- the fg chain
--   base00-base03  sepia(-0.90) only                          -- the bg chain
-- The `-- was` comment on every line is the stock value it came from, so the
-- original palette is recoverable from this file alone.
--
-- The knobs are then neutral -- fg_lightness 50, fg_saturation 50, sepia 0, in
-- lua/config/theme_config_saved.lua under ["nvim-gruvbox"]. Same look as before,
-- but nothing transforms a fg any more, which is the whole point: the yaml hexes
-- in theme_baseline_saved.lua now land EXACTLY as typed.
--
-- Turning a knob here moves things from this baked starting point rather than
-- from stock gruvbox. That is intended -- this is its own theme now, and the
-- upstream base16-gruvbox-dark-medium-forest is back to factory.

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.o.termguicolors = true

require("base16-colorscheme").setup({
  base00 = "#1b212a", -- was #282828
  base01 = "#2d2d37", -- was #3c3836
  base02 = "#3d3a44", -- was #504945
  base03 = "#504a49", -- was #665c50
  base04 = "#ffba3c", -- was #bdae93
  base05 = "#ffd75e", -- was #d5c4a1
  base06 = "#fff19a", -- was #ebdbb2
  base07 = "#f8ffd9", -- was #fbf1c7
  base08 = "#ff2d26", -- was #fb4934
  base09 = "#f26600", -- was #fe8019
  base0A = "#eba800", -- was #fabd2f
  base0B = "#9fb300", -- was #b8bb26
  base0C = "#6f9f00", -- was #5f6c1f
  base0D = "#9fb300", -- was #b8bb26
  base0E = "#20ffe9", -- was #96bda2
  base0F = "#f05700", -- was #d65d0e
})

-- LAST, always: base16-colorscheme.setup() sets colors_name itself, so stamping
-- ours before it would be silently overwritten and every per-theme lookup
-- (baseline colours, saved knobs, glow tier) would resolve to the wrong theme.
vim.g.colors_name = "nvim-gruvbox"
