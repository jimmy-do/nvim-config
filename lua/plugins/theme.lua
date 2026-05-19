-- ~/.config/nvim/lua/plugins/theme.lua
-- Kanagawa Dragon for LazyVim

return {
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      theme = "dragon",
      transparent = false,
      background = {
        dark = "dragon",
        light = "lotus",
      },
    },
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "kanagawa-dragon",
    },
  },
}
