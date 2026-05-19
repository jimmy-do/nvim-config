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
