-- Override LazyVim's default noice.nvim message handling.
-- Goals:
--   * Never silently drop a repeated message (:Inspect / :hi twice in a row).
--   * Send long / hex-carrying messages to a scrollable, yankable popup
--     instead of the tiny bottom-right "mini" bubble that crops + times out.
return {
  "folke/noice.nvim",
  opts = function(_, opts)
    opts.messages = opts.messages or {}

    -- Give the mini bubble more breathing room and time.
    opts.views = opts.views or {}
    opts.views.mini = vim.tbl_deep_extend("force", opts.views.mini or {}, {
      timeout = 10000, -- ms; was ~5000
    })

    -- Measured 2026-08-01: the popup was stealing focus and never closing, which
    -- is why :Inspect "stops working" after the first one. The cursor ends up in
    -- the popup's own buffer, so the next :Inspect inspects THAT — it has no
    -- captures, so you get "No items found at position 1,0 in buffer 6" in the
    -- mini bubble and the stale popup just sits there. enter=false keeps the
    -- cursor in the real buffer; closing on CursorMoved means the next :Inspect
    -- starts from a clean slate.
    opts.views.popup = vim.tbl_deep_extend("force", opts.views.popup or {}, {
      enter = false,
      close = { keys = { "q", "<esc>" } },
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
  config = function(_, opts)
    require("noice").setup(opts)

    -- Because the popup is enter=false, it never receives a BufLeave or
    -- CursorMoved of its own, so noice's own `close.events` can never fire and
    -- every :Inspect stacks another float on the pile. Drive it from the buffer
    -- the cursor is actually in instead.
    --
    -- Scoped to the popup view ONLY — :Noice dismiss is global and would also
    -- wipe the mini bubble mid-read, which is not what was asked for. This
    -- cannot self-trigger: dismissing a view moves no cursor, so it emits no
    -- CursorMoved, and noice buffers are skipped outright.
    -- Leaving the cmdline fires a CursorMoved at the position the cursor was
    -- already on, which raced the popup :Inspect had just created and swallowed
    -- it intermittently. Only a real change of position counts as "moved on".
    local last = {}
    vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter" }, {
      group = vim.api.nvim_create_augroup("noice_popup_autoclose", { clear = true }),
      callback = function(ev)
        if vim.bo[ev.buf].filetype == "noice" then
          return
        end
        local pos = vim.api.nvim_win_get_cursor(0)
        if ev.event == "CursorMoved" and last[1] == pos[1] and last[2] == pos[2] then
          return
        end
        last = pos
        pcall(function()
          -- noice/ui/state.lua drops any msg_show byte-identical to the one
          -- before it (State.skip -> is_equal). Two different yaml keys both
          -- report "@string.yaml + @property.yaml", so the second :Inspect
          -- produced a message that never even reached the manager. This is
          -- upstream of every view, so forgetting the last msg_show is the only
          -- place it can be fixed. (opts.messages.skip_dupes, which this file
          -- used to set, is not a real noice option — it never did anything.)
          require("noice.ui.state").clear("msg_show")

          local router = require("noice.message.router")
          local manager = require("noice.message.manager")
          for view in pairs(router.get_views()) do
            if (view._view_opts or {}).view == "popup" then
              -- view:dismiss() only empties the VIEW; the message stays in the
              -- manager, and the next :Inspect with byte-identical output (two
              -- yaml keys both give @string.yaml + @property.yaml) is treated as
              -- a dupe of it and never renders. Evict the messages too — one by
              -- one, so the mini bubble's messages are untouched.
              for _, msg in ipairs(view._messages or {}) do
                manager.remove(msg)
              end
              view:dismiss()
              view:display()
            end
          end
        end)
      end,
    })
  end,
}
