if os.getenv("KODEKLOUD_PLAYGROUND") ~= "1" then
  return {}
end

-- KodeKloud/browser terminal clipboard bridge.
-- This uses terminal OSC52 escape sequences instead of xclip/xsel/wl-copy.
vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
    ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
  },
  paste = {
    ["+"] = function()
      return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
    end,
    ["*"] = function()
      return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
    end,
  },
}

-- Optional: silence provider warnings you do not need in KodeKloud.
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {},
    },
  },
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {},
      automatic_enable = false,
      automatic_installation = false,
    },
  },
  {
    "folke/snacks.nvim",
    opts = {
      scroll = {
        enabled = false,
      },
    },
  },
}
