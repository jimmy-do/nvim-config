-- Seamless navigation between nvim splits and tmux panes.
-- Ctrl+h/j/k/l moves across nvim splits; at the edge it falls through
-- into the neighboring tmux pane. Ctrl+\ jumps to the previous pane/split.
return {
  "christoomey/vim-tmux-navigator",
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
