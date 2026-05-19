return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    cmd = "Telescope",
    keys = {
      {
        "<leader>th",
        "<cmd>Telescope colorscheme enable_preview=false<CR>",
        desc = "Pick colorscheme",
      },
    },
    opts = {
      defaults = {
        preview = {
          treesitter = false,
        },
      },
    },
  },
}
