return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      {
        "<leader>E",
        "<cmd>Neotree filesystem reveal left<CR>",
        desc = "Reveal current file in Neo-tree",
      },
    },
    opts = {
      filesystem = {
        follow_current_file = {
          enabled = false,
        },
        -- LazyVim's neo-tree extra hijacks netrw, so `nvim .` (or `nvim <dir>`)
        -- opens the tree on startup. The tree is a toggle here, not a permanent
        -- sidebar -- launching into it just costs a `<leader>e` to reclaim the
        -- width. Directory args are handled by the VimEnter autocmd instead.
        hijack_netrw_behavior = "disabled",
      },
      window = {
        mappings = {
          -- Disable dangerous basename rename key
          ["b"] = "none",

          -- Tree expansion/collapse
          ["E"] = "expand_all_nodes",
          ["L"] = "expand_all_subnodes",
          ["z"] = "close_all_nodes",
        },
      },
    },
  },
}
