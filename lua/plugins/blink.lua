-- blink.cmp overrides. Cmdline completion only — the in-buffer completion is
-- LazyVim's default and is deliberately left alone.
--
-- WHY THIS FILE EXISTS: blink's `cmdline` keymap preset drives the completion
-- list with <Tab> / <S-Tab> and nothing else that lands under the home row.
-- Tab is fine for accepting, but it is a stretch for WALKING a list, and every
-- other list in this setup (fzf, telescope, the theme picker) moves on C-j/C-k.
--
-- <C-j> / <C-k> reach nvim in cmdline mode because tmux.conf forwards them
-- whenever the pane is running vim (the `is_vim` if-shell block, ~line 485) --
-- vim-tmux-navigator only claims them in NORMAL mode, so there is no conflict.
return {
  "saghen/blink.cmp",
  opts = {
    cmdline = {
      keymap = {
        -- preset = 'cmdline' is blink's default and is NOT overridden here:
        -- these two merge on top of it, so <Tab> / <S-Tab> keep working exactly
        -- as before for anyone (including muscle memory) still reaching for them.
        --
        -- 'fallback' matters: with no completion menu open, <C-j>/<C-k> pass
        -- through to whatever else is mapped instead of being swallowed.
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },
      },
    },
  },
}
