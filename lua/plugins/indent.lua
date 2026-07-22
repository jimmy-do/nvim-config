return {
  {
    "folke/snacks.nvim",
    opts = {
      indent = {
        animate = { enabled = false },
        -- Keep the dim indent guides (SnacksIndent) as the ladder background.
        -- Snacks' own scope highlight is turned OFF: it lit the guide at the
        -- *inside* column of the block (scope.indent) and drew nothing on leaf
        -- `key: value` lines, so it was always one level too deep and usually
        -- invisible. The single enclosing guide is drawn by indent-ladder.lua
        -- instead (the vertical line immediately left of the block you're in).
        scope = {
          enabled = false,
          char = "│",
          hl = "SnacksIndentScope",
        },
      },
    },
  },
}
