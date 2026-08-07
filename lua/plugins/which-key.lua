-- which-key waits `delay` ms before drawing the menu for a prefix key.
-- LazyVim ships 200ms; 0 makes <leader>w (and every other group) paint the
-- moment the prefix lands. This is which-key's own timer, independent of
-- timeoutlen (400 in options.lua), which only governs mapping ambiguity.
return {
  "folke/which-key.nvim",
  opts = {
    delay = 0,
  },
}
