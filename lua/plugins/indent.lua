return {
  {
    "folke/snacks.nvim",
    opts = {
      indent = {
        animate = { enabled = false },
        -- The dim guides (SnacksIndent) are OFF. They were the ladder's
        -- background -- every level drawn faintly, all the time -- but the only
        -- guide worth seeing is the enclosing one, and indent-ladder.lua draws
        -- that on its own. The SnacksIndent highlight GROUP is still defined by
        -- theme.lua, so the ladder's fade-up ramp (which samples it as the
        -- colour rows emerge from) keeps working with nothing painted under it.
        indent = { enabled = false },
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
