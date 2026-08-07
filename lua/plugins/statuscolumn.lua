-- snacks.statuscolumn is LazyVim's default `statuscolumn`, and its stock
-- `left = { "mark", "sign" }` renders any vim mark as its bare letter in the
-- far-left column (statuscolumn.lua:71 / :170-176). A stray `mk` therefore
-- parks a lone "k" next to the line numbers forever -- it looks like a plugin
-- glyph, but it is just the mark. Marks are not part of the workflow here, so
-- drop them from the column and leave real signs (git, diagnostics) alone.
return {
  "folke/snacks.nvim",
  opts = {
    statuscolumn = {
      left = { "sign" },
    },
  },
}
