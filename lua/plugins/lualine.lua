-- lualine: stop the idle repaint tick.
--
-- WHY THIS FILE EXISTS (2026-08-01)
-- ---------------------------------------------------------------------------
-- tmux `monitor-activity on` lights a window's activity flag on ANY pty output
-- and clears it only when you visit that window. lualine's default config is
--
--     refresh = { statusline = 1000, tabline = 1000, winbar = 1000 }
--
-- i.e. a full statusline repaint every second, forever, whether or not the
-- window is on screen. So every nvim window re-lit its activity bubble within a
-- second of being left -- permanently, by construction. Jimmy's report: "nvim
-- just stays on forever". The indicator was not broken; nvim really was talking
-- once a second and the bubble was telling the truth.
--
-- Nothing in this statusline is time-based -- no clock, no uptime, no ticker --
-- so that timer only ever repainted identical content. lualine ALSO refreshes on
-- events, and that list is what actually keeps the bar correct:
--   WinEnter BufEnter BufWritePost SessionLoadPost FileChangedShellPost
--   VimResized Filetype CursorMoved CursorMovedI ModeChanged
-- Mode, file, position, and (via CursorMoved, which fires constantly while
-- editing) diagnostics all land through those.
--
-- 100000ms is a safety net, not a heartbeat: effectively "only on events", while
-- still leaving one eventual repaint rather than truly never. Raise the numbers
-- if some component ever needs polling; do NOT put them back to 1000 without
-- accepting a permanently-lit activity bubble on every nvim window.
--
-- Deliberately opts-as-function + tbl_deep_extend: LazyVim owns the sections
-- here, and replacing the table wholesale would silently drop its components.
-- This file must ONLY change `refresh`.

return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
        refresh = {
          statusline = 100000,
          tabline = 100000,
          winbar = 100000,
        },
      })
      return opts
    end,
  },
}
