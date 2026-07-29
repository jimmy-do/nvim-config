-- Telescope REMOVED 2026-07-26. It was pinned to tag 0.1.8 (2-year-old) and
-- kept alive for exactly one keybinding: <leader>th -> :Telescope colorscheme.
-- fzf-lua is the picker (vim.g.lazyvim_picker = "fzf" in options.lua), and
-- <leader>th now opens the custom scroll-preview picker instead — see
-- colorscheme-picker.lua. `enabled = false` (not file deletion) so any extra
-- that lists telescope as a dependency gets a hard no instead of re-installing.
return {
  { "nvim-telescope/telescope.nvim", enabled = false },
}
