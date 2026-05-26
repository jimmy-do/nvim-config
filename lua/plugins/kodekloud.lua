if os.getenv("KODEKLOUD_PLAYGROUND") ~= "1" then
  return {}
end

return {
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {},
    },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {},
      automatic_installation = false,
    },
  },
}
