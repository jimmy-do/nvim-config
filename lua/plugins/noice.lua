-- Override LazyVim's default noice.nvim message handling.
-- Goals:
--   * Never silently drop a repeated message (:Inspect / :hi twice in a row).
--   * Send long / hex-carrying messages to a scrollable, yankable popup
--     instead of the tiny bottom-right "mini" bubble that crops + times out.
return {
  "folke/noice.nvim",
  opts = function(_, opts)
    opts.messages = opts.messages or {}
    -- Don't collapse an identical message shown back-to-back.
    opts.messages.skip_dupes = false

    -- Give the mini bubble more breathing room and time.
    opts.views = opts.views or {}
    opts.views.mini = vim.tbl_deep_extend("force", opts.views.mini or {}, {
      timeout = 10000, -- ms; was ~5000
    })

    -- Route the noisy, copy-worthy commands to a full popup instead of mini.
    opts.routes = opts.routes or {}
    table.insert(opts.routes, {
      view = "popup",
      filter = {
        any = {
          { event = "msg_show", find = "^Treesitter" }, -- :Inspect output
          { event = "msg_show", find = "#%x%x%x%x%x%x" }, -- anything with a hex colour
          { event = "msg_show", find = "xxx" }, -- :hi group dumps
          { event = "msg_show", find = "guifg" },
          { event = "msg_show", find = "guibg" },
        },
      },
    })
  end,
}
