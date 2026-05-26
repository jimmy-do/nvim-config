if os.getenv("KODEKLOUD_PLAYGROUND") ~= "1" then
  return {}
end

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
}
