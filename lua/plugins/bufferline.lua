-- Carry the cyan split divider up through the bufferline row.
--
-- WinSeparator only paints inside the window grid, so the divider stopped dead
-- at the tab bar and picked up again below it. The tabline itself spans the
-- full width, and the only thing bufferline draws at that column is the offset
-- region (the slab reserved above Neo-tree) -- which renders no edge glyph at
-- all unless `separator` is set. See bufferline/offset.lua:
--
--     if not offset.separator then return str end
--
-- LazyVim's default offsets (neo-tree, snacks_layout_box) omit the key, hence
-- the break. Mutate the inherited list rather than redeclaring it so new
-- LazyVim offsets keep working.
--
-- The colour needs no help here: BufferLineOffsetSeparator derives its fg from
-- WinSeparator, which theme.lua pins to WIN_DIVIDER (#2ff5ff).
return {
  {
    "akinsho/bufferline.nvim",
    opts = function(_, opts)
      for _, offset in ipairs(vim.tbl_get(opts, "options", "offsets") or {}) do
        offset.separator = true
      end
    end,
  },
}
