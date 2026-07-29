-- Seamless navigation between nvim splits and tmux panes.
-- Ctrl+h/j/k/l moves across nvim splits; at the edge it falls through
-- into the neighboring tmux pane. Ctrl+\ jumps to the previous pane/split.
return {
  "christoomey/vim-tmux-navigator",
  init = function()
    -- At a window edge the plugin's `tmux select-pane` wraps to the opposite
    -- side (or reselects a full-width pane onto itself), and the focus
    -- out/in round-trip strobes nvim's focus handlers + tmux divider hooks —
    -- the C-l flicker in the rightmost pane. tmux.conf carries the matching
    -- pane_at_* guards for presses that land on the tmux side (no-wrap
    -- 2026-07-26 block).
    vim.g.tmux_navigator_no_wrap = 1
  end,
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
    "TmuxNavigatePrevious",
  },
  keys = {
    { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Nav left (split/pane)" },
    { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Nav down (split/pane)" },
    { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Nav up (split/pane)" },
    { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Nav right (split/pane)" },
    { "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Nav to previous (split/pane)" },
  },
}
